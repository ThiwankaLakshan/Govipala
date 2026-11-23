# Product Requirements Document (PRD)
## Govipala — Agricultural Machine Reservation App (v1.4)
### Pilot Region: Padaviya Divisional Secretariat, Anuradhapura District, Sri Lanka

---

## 1. Problem Statement
Farmers in Padaviya rely on shared agricultural machinery (tractors, combine harvesters, water pumps) that they don't personally own. Today, booking a machine happens through phone calls and word-of-mouth, which causes:
- Double-bookings and scheduling conflicts during peak cultivation season
- Machine owners losing idle time between jobs they could otherwise fill
- Farmers unable to plan land preparation because they can't see real availability
- No record of reliability (which owners show up, which farmers pay/behave well)

## 2. Goal
Build a simple, low-bandwidth-friendly mobile app where machine owners publish availability and farmers reserve slots directly — removing the phone-tag coordination problem.

## 3. Target Users

### Primary: Machine Owners
- Own tractors, hand tractors (2-wheel), combine harvesters, or water pumps
- Want to fill idle time between jobs and reduce no-show risk
- Often have basic Android phones, moderate literacy with apps, limited mobile data

### Primary: Farmers
- Need machines for land preparation, harvesting, or irrigation on a schedule tied to paddy cultivation cycles (Maha/Yala seasons)
- Want to see real availability before showing up or calling
- May have intermittent connectivity in remote GN divisions within Padaviya

### Primary: Administrator
- Runs the platform for the pilot (initially the project owner)
- Needs to see and manage everything on both sides: users, machines, availability, bookings, reviews
- Can edit or deactivate any machine listing
- Often needs to help low-literacy farmers or owners who phone in instead of using the app
- Works from a laptop or tablet through a web admin panel

## 4. Scope — MVP (Phase 1: Padaviya Pilot)

### In scope
- Phone number (OTP) registration/login for both user types
- Owner: list a machine (type, **brand**, drive type for four-wheel tractors (2WD/4WD), model, rate, photo, service area by GN division)
- Owner: publish available date/time slots on a calendar
- Farmer: browse machines by type + GN division + date needed
- Farmer: request a booking for a specific slot
- Owner: accept/reject booking requests
- Booking status lifecycle: Requested → Confirmed → In Progress → Completed → (or Cancelled)
- SMS/push notification on booking status change
- Post-completion rating (1–5 stars + optional comment)
- Sinhala-first UI (English secondary)
- Basic offline caching of last-viewed machine list/calendar
- Admin web panel with full management of users, machines, availability slots, bookings, and reviews
- Admin audit log of every admin action
- Simple, attractive, Sinhala-first interface that stays light on old phones (see 06_UI_UX_GUIDE.md)

### Out of scope for MVP (defer to Phase 2+)
- In-app payments (cash-on-service for pilot; add payment gateway later)
- Tamil language support (add when expanding beyond Padaviya)
- Multi-district expansion
- Machine owner analytics/earnings dashboards
- Formal dispute resolution / support ticketing system (admins can override bookings manually in the meantime)
- GPS live tracking of machine location

## 5. Core User Flows

**Owner flow:**
1. Register with phone number → OTP verify
2. Add machine profile (type, brand typed by the owner, drive type dropdown 2WD/4WD if it is a four-wheel tractor, model, rate/hour or /day, photo, GN divisions served)
3. Open calendar → mark available date/time blocks
4. Receive booking request notification → Accept or Reject
5. Mark job "Completed" after service
6. See rating left by farmer

**Farmer flow:**
1. Register with phone number → OTP verify
2. Select GN division + machine type + date needed
3. Browse matching machines with availability shown
4. Tap a slot → submit booking request (include land location/notes)
5. Get notified when owner accepts/rejects
6. After job, rate the owner/machine

**Admin flow:**
1. Log in to the web admin panel (email + password, no public sign-up)
2. Manage machine listings: view, edit (including brand), deactivate
3. Manage users: search, edit, suspend/reactivate, remove
4. Manage slots and bookings for either side, including creating a booking for a farmer who phoned in
5. Hide inappropriate reviews
6. Check the audit log and dashboard counts

## 6. Machine Categories (Padaviya-relevant, v1)
1. Four-wheel tractor
2. Two-wheel hand tractor
3. Combine harvester
4. Water pump

(Expand list only after pilot validates demand — don't over-build categories nobody in Padaviya requests.)

Each machine listing also has a **brand**, typed by the owner (for example the make shown on the machine). It is shown on the machine card and detail page. Four-wheel tractors also have a **drive type**, chosen from a dropdown (2WD or 4WD); the field is required for four-wheel tractors and does not appear for other machine types. There is no brand catalog and no brand-specific matching in this version.

## 7. Non-Functional Requirements
- App must remain usable on 2GB RAM Android devices (common in rural areas)
- Interface must look clean and friendly, not like a plain default template, while staying light: no blur, heavy shadows, video, or big animations (full rules in 06_UI_UX_GUIDE.md)
- Must degrade gracefully with no/weak signal — cache last data, queue actions
- SMS notification fallback for users without reliable push notification delivery
- All booking-critical actions (slot locking, confirmation) must be atomic — no double-booking under any circumstance

## 8. Success Metrics (Pilot, first 3 months)
- 15+ machine owners onboarded in Padaviya
- 100+ farmers registered
- 50+ completed bookings
- <5% booking conflict/cancellation-due-to-error rate
- Average owner response time to booking requests under 4 hours
- Admin can resolve a phone-in booking request in under 3 minutes

## 9. Risks
- **Cold start problem**: both sides need supply and demand simultaneously — mitigate via manual owner onboarding before public farmer launch
- **Low digital literacy**: mitigate with large tap targets, icon-first UI, Sinhala voice-over option (future)
- **Admin account misuse**: admins can change anything — mitigate with email/password + role check, no public admin sign-up, and a full audit log
- **Connectivity gaps**: mitigate with aggressive local caching and SMS as the notification backbone, not just push
