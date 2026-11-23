# Technical Architecture Document
## Govipala App (v1.4)

## 1. Stack Overview

| Layer | Choice | Reason |
|---|---|---|
| Mobile app | Flutter (Android first) | Single codebase, lighter APK, good offline caching support |
| Auth / OTP | Firebase Authentication (Phone) | 10 free SMS OTPs/day even on Blaze plan; reliable carrier reach |
| Push notifications | Firebase Cloud Messaging (FCM) | Free, integrates directly with Flutter |
| Primary database | PostgreSQL | Relational integrity for bookings; prevents double-booking via row locking/transactions |
| Backend API | Node.js + Express (or NestJS) | Sits between Flutter app, Postgres, and Firebase; owns all business logic |
| File storage | Firebase Cloud Storage | Machine photos; free tier sufficient for pilot scale |
| SMS notifications (status updates, not OTP) | Dialog/Mobitel local SMS gateway or Twilio | For booking confirmations when push fails |
| Admin panel | Flutter Web, same backend API | Admins manage lots of data, so a laptop/tablet web panel beats a phone screen; reuses Flutter models and API client |
| Admin auth | Firebase Authentication (email/password) + `role = admin` check in Postgres | No SMS cost for admins, stronger than OTP-only, no public admin sign-up |
| Hosting (Postgres + API) | Railway, Render, or a small VPS | Free/cheap tiers sufficient for pilot traffic |

**Key architectural decision:** Firebase is used ONLY for auth (OTP), push notifications, and photo storage. It does NOT hold booking/business data. PostgreSQL, accessed through your own backend API, is the single source of truth for users, machines, availability, and bookings. This avoids Firestore's eventual-consistency issues for double-booking-sensitive data.

## 2. System Diagram (text form)

```
[Flutter App]
   |-- Firebase SDK -----> [Firebase Auth (OTP)] 
   |-- Firebase SDK -----> [FCM Push Notifications]
   |-- Firebase SDK -----> [Cloud Storage (machine photos)]
   |-- HTTPS REST calls -> [Backend API (Node/Express)]
                                |
                                |-- reads/writes --> [PostgreSQL DB]
                                |-- triggers ------> [SMS Gateway] (status updates)
                                |-- verifies token -> [Firebase Admin SDK] (validates OTP-issued JWT)
```

**Auth flow:** Flutter app authenticates with Firebase directly (client SDK). Firebase issues an ID token. The Flutter app sends this token with every request to your backend API. Backend verifies the token using Firebase Admin SDK, then maps the verified phone number to a `users` row in Postgres (creating one on first login). All subsequent authorization is handled by your backend against Postgres roles, not Firebase.

**Admin auth:** Admins sign in with Firebase email/password. The same token verification applies, then the backend requires `users.role = 'admin'` and `users.status = 'active'` for every `/admin/*` route. The public `POST /users/register` endpoint must reject `role = admin`. The first admin is created once by hand (see the end of `03_DATABASE_SCHEMA.sql`); after that, admins create other admins from the panel. Users with status `suspended` or `deleted` get `403 account_suspended` on every endpoint.

## 3. Booking Conflict Prevention (critical logic)
This is the single most important piece of backend logic. Implement as follows:

1. Farmer requests a slot → backend opens a DB transaction
2. `SELECT ... FOR UPDATE` locks the target `availability_slots` row
3. Check slot status is still `open`
4. If open: set status to `pending`, create a `bookings` row, commit transaction
5. If not open: reject immediately with a clear "slot no longer available" response
6. A background job auto-releases `pending` slots back to `open` if the owner hasn't responded within a configurable timeout (recommend 2 hours for pilot, given slower response times expected)

Never allow slot status changes outside a transaction. This is the #1 source of double-booking bugs in reservation systems.

**Admin actions use the same rules.** When an admin edits or deletes a pending/booked slot, overrides a booking, or books on a farmer's behalf, the backend opens the same transaction with `SELECT ... FOR UPDATE` on the slot, writes the change, writes the `admin_audit_log` row, and commits, all in one transaction. Admin power does not bypass the locking.

## 4. Suggested Backend Folder Structure
```
/backend
  /src
    /routes        (machines.js, bookings.js, users.js, availability.js)
      /admin       (users.js, machines.js, availability.js, bookings.js, reviews.js, audit.js, stats.js)
    /controllers
    /models         (Postgres query logic, e.g. via Prisma or raw SQL + pg library)
    /middleware     (verifyFirebaseToken.js, roleCheck.js, requireAdmin.js, blockSuspended.js)
    /services       (smsService.js, notificationService.js, auditService.js)
    /jobs           (releaseExpiredPendingSlots.js — cron)
  /prisma or /db    (schema.sql / prisma schema, migrations)
  server.js
```

## 5. Suggested Flutter App Structure
```
/lib
  /screens
    /auth           (phone_entry.dart, otp_verify.dart)
    /owner          (add_machine.dart, availability_calendar.dart, booking_requests.dart)
    /farmer         (browse_machines.dart, machine_detail.dart, my_bookings.dart)
    /shared         (rating_screen.dart, profile.dart)
  /models           (machine.dart, booking.dart, user.dart, availability_slot.dart)
  /services         (auth_service.dart, api_service.dart, notification_service.dart, cache_service.dart)
  /theme            (colors.dart, text_styles.dart, spacing.dart, app_theme.dart — all colours, sizes, fonts live here)
  /widgets          (reusable UI components)
  /localization     (sinhala + english strings)
  main.dart
```

## 5b. Suggested Admin Panel Structure (Flutter Web)
```
/admin_panel
  /lib
    /screens
      dashboard.dart          (counts: users by role, machines, today's bookings)
      users_list.dart / user_detail.dart
      machines_list.dart / machine_detail.dart   (edit / deactivate)
      availability_editor.dart
      bookings_list.dart / booking_detail.dart   (override status, create on behalf of a farmer)
      reviews_moderation.dart
      audit_log.dart
    /services  (admin_api_service.dart, auth_service.dart)
  main.dart
```
Share models and the API client with the mobile app (e.g. a local Dart package) so the two never drift apart.


## 6. Offline Behavior Requirements
- Cache the last-fetched machine list + availability calendar locally (e.g. via `sqflite` or `hive` in Flutter)
- Queue booking requests made while offline; sync when connectivity returns; show clear "pending sync" state to the user
- Never let the app silently fail on a submit — always show explicit online/offline/syncing state

## 7. Environment Variables Needed (backend)
```
DATABASE_URL=postgresql://...
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=
SMS_GATEWAY_API_KEY=
SMS_GATEWAY_SENDER_ID=
PORT=3000
FIRST_ADMIN_EMAIL=   # optional, used by the one-time admin seed script
```

## 8. Notes for Antigravity Agents
- Treat `03_DATABASE_SCHEMA.sql` as authoritative — do not redesign tables without checking against the PRD's booking conflict requirements
- Treat `04_API_SPEC.md` as the contract between Flutter and backend — implement endpoints exactly as named
- Prioritize the booking-conflict transaction logic (Section 3 above) as a first-class concern, not an afterthought
- Default all user-facing strings to Sinhala with English as a secondary locale from day one — do not hardcode English-only strings
- Every `/admin/*` write must go through `auditService` (admin, action, before/after, reason) inside the same DB transaction as the change
- Follow `06_UI_UX_GUIDE.md`: build the theme and reusable widgets first, bundle the Sinhala font, compress photos on the phone before upload, and treat its performance rules (section 6) as hard rules
