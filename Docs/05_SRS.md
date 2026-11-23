# Software Requirements Specification (SRS)
## Govipala — Agricultural Machine Reservation System

**Pilot Region:** Padaviya Divisional Secretariat, Anuradhapura District, Sri Lanka
**Version:** 1.4
**Document Status:** Draft for Development

---

## 1. Introduction

### 1.1 Purpose
This document specifies the functional and non-functional requirements for **Govipala**, a mobile application that connects agricultural machine owners with farmers in the Padaviya Divisional Secretariat area, enabling machine availability publishing and reservation without relying on informal phone-based coordination.

This SRS is intended for the development team (including AI development agents such as those operating in Google Antigravity), and any reviewing stakeholders.

### 1.2 Scope
Govipala allows:
- Machine owners to register, list machines, and publish available date/time slots
- Farmers to search machines by type, location, and date, and reserve available slots
- Both parties to track booking status, receive notifications, and rate each other after service
- Owners to record the brand of each machine they list, and the drive type (2WD or 4WD) for four-wheel tractors
- Administrators to manage all users, machines, availability, bookings, and reviews through a web admin panel

The system is scoped to a single pilot region (Padaviya) for Version 1.0, with Sinhala as the primary interface language.

### 1.3 Intended Audience
- Development team / AI coding agents (Antigravity)
- Project owner (product decisions)
- Future pilot stakeholders (DS office, farmer organizations, if engaged)

### 1.4 Definitions and Abbreviations

| Term | Meaning |
|---|---|
| GN Division | Grama Niladhari Division — smallest administrative unit in Sri Lanka, used here as the location granularity for machine service areas |
| DS Division | Divisional Secretariat Division (Padaviya is one such division in Anuradhapura District) |
| OTP | One-Time Password (used for phone-based login) |
| MVP | Minimum Viable Product |
| FCM | Firebase Cloud Messaging |
| SRS | Software Requirements Specification |
| Admin | Platform administrator with full management rights over both owner and farmer data |

### 1.5 References
- Product Requirements Document (01_PRD.md)
- Technical Architecture Document (02_ARCHITECTURE.md)
- Database Schema (03_DATABASE_SCHEMA.sql)
- API Specification (04_API_SPEC.md)
- UI/UX Guide (06_UI_UX_GUIDE.md)

---

## 2. Overall Description

### 2.1 Product Perspective
Govipala is a new, standalone mobile application (Android-first, built in Flutter). It is not a replacement for any existing system — it formalizes and digitizes a currently informal, phone-call-based booking process used by farmers and machine owners in Padaviya.

### 2.2 Product Functions (Summary)
1. User registration and authentication via phone OTP
2. Machine listing management (owner)
3. Availability calendar management (owner)
4. Machine search and discovery (farmer)
5. Booking request, confirmation, and lifecycle tracking
6. Push and SMS notifications on booking status changes
7. Post-booking ratings and reviews
8. Multi-language support (Sinhala primary, English secondary)
9. Machine brand recorded on each listing, plus drive type (2WD/4WD) for four-wheel tractors
10. Admin web panel: full management of users, machines, slots, bookings, and reviews, with an audit log

### 2.3 User Classes and Characteristics

| User Class | Description | Technical Proficiency |
|---|---|---|
| Machine Owner | Owns/operates tractors, harvesters, water pumps for hire | Basic-to-moderate smartphone use |
| Farmer | Needs machine services for land preparation, harvesting, irrigation | Basic smartphone use, may have limited data connectivity |
| System Admin | Manages all users, machines, slots, bookings, and reviews; helps users who phone in | Moderate-to-high; uses a laptop/tablet web panel |

### 2.4 Operating Environment
- Android smartphones, including low-spec devices (2GB RAM target minimum)
- Intermittent mobile data connectivity typical of rural Padaviya
- Backend hosted on cloud infrastructure (Node.js/Express + PostgreSQL), reachable via HTTPS

### 2.5 Design and Implementation Constraints
- Must function acceptably on low-end Android hardware
- Must tolerate low/no connectivity gracefully (local caching, queued actions)
- SMS must be available as a notification fallback, not solely push notifications
- The admin interface is a web panel (Flutter Web) and the mobile app serves owners and farmers only in v1.0
- Firebase used strictly for auth/notifications/storage; PostgreSQL is the system of record for all business data (see Architecture doc)

### 2.6 Assumptions and Dependencies
- Farmers and owners have access to an Android smartphone and a registered mobile number
- A working Firebase project and PostgreSQL instance are provisioned before development begins
- An SMS gateway (Twilio, Dialog, or Mobitel) is available for status-update messages
- GN division names within Padaviya are confirmed against the local DS office for accuracy before data seeding

---

## 3. System Features (Functional Requirements)

Each feature includes a unique ID for traceability. Priority: **H**igh (MVP-critical), **M**edium, **L**ow (future phase).

### 3.1 User Registration & Authentication
| ID | Requirement | Priority |
|---|---|---|
| FR-1.1 | System shall allow a user to register using their phone number via OTP verification (Firebase Phone Auth). | H |
| FR-1.2 | System shall require the user to select a role: Owner, Farmer, or Both. | H |
| FR-1.3 | System shall require the user to select their GN division during registration. | H |
| FR-1.4 | System shall allow the user to select a preferred language (Sinhala default, English optional). | H |
| FR-1.5 | System shall persist login sessions so users are not required to re-authenticate on every app open. | M |
| FR-1.6 | System shall reject any public registration attempt that requests the admin role. | H |
| FR-1.7 | System shall block suspended or deleted users from all actions and show a clear account-suspended message. | H |

### 3.2 Machine Listing (Owner)
| ID | Requirement | Priority |
|---|---|---|
| FR-2.1 | Owner shall be able to create a machine listing specifying type, brand, model name, rate, and rate unit (hour/day/acre). | H |
| FR-2.2 | Owner shall be able to upload a photo of the machine. | M |
| FR-2.3 | Owner shall specify one or more GN divisions the machine services. | H |
| FR-2.4 | Owner shall be able to edit or deactivate a machine listing. | M |
| FR-2.5 | System shall restrict machine type to a fixed list for MVP: four-wheel tractor, two-wheel tractor, combine harvester, water pump. | H |
| FR-2.6 | Owner shall enter the machine's brand as text (required, 1–80 characters) when listing a machine; the brand shall be shown on machine cards and detail pages. | H |
| FR-2.7 | Owner shall be able to edit the brand later. | M |
| FR-2.8 | For a four-wheel tractor, owner shall choose the drive type (2WD or 4WD) from a dropdown; the field is required for four-wheel tractors and shall not appear for other machine types. | H |
| FR-2.9 | System shall reject a drive type on any machine that is not a four-wheel tractor, and reject a four-wheel tractor listing without one. | H |

### 3.3 Availability Management (Owner)
| ID | Requirement | Priority |
|---|---|---|
| FR-3.1 | Owner shall be able to publish one or more available date/time slots per machine. | H |
| FR-3.2 | Owner shall be able to remove an unbooked ("open") slot. | M |
| FR-3.3 | System shall prevent removal of a slot that is pending or booked. | H |
| FR-3.4 | Owner shall be able to view a calendar of all slots for a given machine, with status indicated (open/pending/booked). | H |

### 3.4 Machine Search & Discovery (Farmer)
| ID | Requirement | Priority |
|---|---|---|
| FR-4.1 | Farmer shall be able to search machines filtered by type, GN division, and date. | H |
| FR-4.2 | System shall display only machines with at least one open slot matching the search criteria (or show full calendar if no date specified). | H |
| FR-4.3 | Farmer shall be able to view full machine details including owner name, rate, and average rating. | M |
| FR-4.4 | System shall show the brand, and the drive type for four-wheel tractors, on every machine card and detail page. | H |

### 3.5 Booking Management
| ID | Requirement | Priority |
|---|---|---|
| FR-5.1 | Farmer shall be able to request a booking on a specific open slot, including land location details. | H |
| FR-5.2 | System shall lock the slot atomically upon a booking request, preventing any other farmer from booking the same slot simultaneously. | **H — Critical** |
| FR-5.3 | Owner shall be able to confirm or reject a pending booking request. | H |
| FR-5.4 | System shall auto-release a pending slot back to "open" if the owner does not respond within a configurable timeout (default 2 hours). | M |
| FR-5.5 | Owner or farmer shall be able to update booking status through its lifecycle: confirmed → in_progress → completed, or cancel with a reason. | H |
| FR-5.6 | Farmer shall be able to view all their past and upcoming bookings. | H |
| FR-5.7 | Owner shall be able to view all incoming booking requests and confirmed jobs. | H |

### 3.6 Notifications
| ID | Requirement | Priority |
|---|---|---|
| FR-6.1 | System shall send a push notification (FCM) to the owner when a new booking request is made. | H |
| FR-6.2 | System shall send a push notification to the farmer when a booking is confirmed or rejected. | H |
| FR-6.3 | System shall send an SMS as a fallback for any critical status notification if push delivery cannot be confirmed. | M |
| FR-6.4 | System shall log all sent notifications (channel, timestamp, recipient) for audit purposes. | L |

### 3.7 Ratings & Reviews
| ID | Requirement | Priority |
|---|---|---|
| FR-7.1 | Either party shall be able to submit a 1–5 star rating and optional comment after a booking is marked completed. | M |
| FR-7.2 | System shall display a user's average rating on their public profile/machine listing. | M |
| FR-7.3 | System shall allow only one review per booking per reviewer. | M |
| FR-7.4 | Reviews hidden by an admin shall be excluded from all averages and public displays. | M |

### 3.8 Offline Behavior
| ID | Requirement | Priority |
|---|---|---|
| FR-8.1 | System shall cache the most recently viewed machine list and availability calendar locally on-device. | M |
| FR-8.2 | System shall queue booking requests submitted while offline and sync automatically upon reconnection. | M |
| FR-8.3 | System shall clearly display connection state (online/offline/syncing) to the user at all times. | M |

### 3.9 Admin Management
Admin capabilities apply to both sides (owners and farmers). Every admin write action is subject to FR-9.12 and FR-9.13.

| ID | Requirement | Priority |
|---|---|---|
| FR-9.1 | Admin accounts shall be created only by a one-time seed or by an existing admin, never through public registration. | H |
| FR-9.2 | Admins shall authenticate with email and password and be authorized by the admin role in the system database. | H |
| FR-9.3 | Admin shall be able to search, filter, view, create, edit, suspend, reactivate, and soft-delete any user (farmer, owner, both, or admin). | H |
| FR-9.4 | When suspending or deleting a user with upcoming bookings, system shall show the affected bookings so the admin can decide what to cancel. | M |
| FR-9.5 | Admin shall be able to view, edit (including the brand), and deactivate any machine listing on behalf of the owner. | H |
| FR-9.6 | Admin shall be able to add, edit, block, and delete availability slots for any machine. Changing or deleting a pending or booked slot shall cancel the linked booking with a recorded reason and notify both parties. | H |
| FR-9.7 | Admin shall be able to view and filter all bookings by status, date, farmer, owner, and machine. | H |
| FR-9.8 | Admin shall be able to override a booking's status (confirm, reject, in progress, complete, cancel) with a recorded reason. | H |
| FR-9.9 | Admin shall be able to create a booking on behalf of a farmer (for example, one who phoned in); the booking shall record that it was created by an admin. | M |
| FR-9.10 | Admin shall be able to hide reviews that break the rules, with a reason. | M |
| FR-9.11 | Admin dashboard shall show counts of users by role, machines, and bookings by status. | M |
| FR-9.12 | Every admin write action shall be recorded in an audit log with the admin, action, target, before/after values, reason, and time. The log shall be read-only in the panel. | H |
| FR-9.13 | Admin changes to slots and bookings shall run inside the same atomic, locked database transactions as user actions, so admin power never causes double-booking. | H |

---

## 4. External Interface Requirements

### 4.1 User Interfaces
- Mobile-first UI, optimized for small/low-resolution Android screens
- Simple, modern, and friendly visual design (warm colours, rounded cards, large machine-type icons) as specified in 06_UI_UX_GUIDE.md
- Bottom navigation with at most 4 tabs; one main action per screen
- Sinhala-first labeling and iconography; large tap targets for low digital-literacy users
- Calendar view for availability (owner) and slot browsing (farmer)
- Machine cards show the brand next to the machine type, plus the drive type (2WD/4WD) for four-wheel tractors
- The Add Machine form shows a drive type dropdown (2WD / 4WD) only when "four-wheel tractor" is selected
- Admin web panel (Flutter Web): responsive for laptop and tablet, with tables, search, filters, and a pending-items dashboard

### 4.2 Hardware Interfaces
- Standard Android device sensors/hardware only (no specialized hardware required for MVP)

### 4.3 Software Interfaces
- Firebase Authentication (Phone/OTP)
- Firebase Cloud Messaging (push notifications)
- Firebase Cloud Storage (machine photos)
- PostgreSQL database (via backend API)
- SMS Gateway API (Twilio, Dialog, or Mobitel) for status-update SMS

### 4.4 Communication Interfaces
- HTTPS REST API between Flutter app and backend (see 04_API_SPEC.md for full contract)
- All API requests authenticated via Firebase-issued ID token in `Authorization: Bearer` header

---

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | App shall remain usable (no more than 2s UI response) on Android devices with 2GB RAM. |
| NFR-2 | Reliability | Booking slot-locking logic shall guarantee zero double-bookings under concurrent requests. |
| NFR-3 | Availability | Backend API shall target 99% uptime during pilot phase. |
| NFR-4 | Usability | All core user flows (registration, listing, booking) shall be completable without external instruction by a first-time smartphone user. |
| NFR-5 | Localization | All user-facing text shall be available in Sinhala at MVP launch; architecture shall support adding Tamil in a future phase without redesign. |
| NFR-6 | Security | All API endpoints shall require valid Firebase-issued authentication tokens; no booking or personal data shall be accessible without authentication. |
| NFR-7 | Data Integrity | All state-changing booking operations shall occur within database transactions. |
| NFR-8 | Scalability | System shall be architected to extend beyond Padaviya to additional DS divisions without schema changes (GN division is already a flexible field, not a hardcoded enum). |
| NFR-9 | Maintainability | Codebase shall follow the folder structure defined in 02_ARCHITECTURE.md to support parallel agent-based development in Antigravity. |
| NFR-10 | Security | All `/admin/*` endpoints shall require an active admin account; admin authentication shall not rely on SMS OTP only. |
| NFR-11 | Auditability | No admin write shall complete without a matching audit log entry committed in the same transaction. |
| NFR-12 | Visual design | The UI shall use a single design system (colour, type, spacing tokens defined in one theme) and the look and screen layouts defined in 06_UI_UX_GUIDE.md; it shall not be a plain default template. |
| NFR-13 | UI performance | The UI shall avoid blur, heavy shadows, video, and large animations. Cold start to the first usable screen shall be about 3 seconds or less, and list scrolling shall be smooth, on a real 2GB RAM Android phone. |
| NFR-14 | App size and images | The APK shall be 25 MB or less per device architecture. Machine photos shall be compressed on the phone to about 200 KB or less before upload, with a small thumbnail used in lists. |
| NFR-15 | Accessibility | Tap targets shall be at least 48 × 48 dp; text shall stay at least 14sp and the layout shall survive a 1.3× system font size; status shall never be shown by colour alone; every action shall have an icon and a Sinhala label; Sinhala font shall be bundled in the app. |

---

## 6. Data Requirements
Full schema defined in `03_DATABASE_SCHEMA.sql`. Core entities:
- **users** — phone-verified accounts with role and GN division
- **machines** — owner-listed equipment with type, brand, drive type (four-wheel tractors only), model, rate, and service area
- **admin_audit_log** — record of every admin write action
- **availability_slots** — date/time blocks per machine with status (open/pending/booked/blocked)
- **bookings** — farmer requests against slots, with full lifecycle status (and a record of the admin when an admin booked on a farmer's behalf)
- **reviews** — post-completion ratings between owner and farmer
- **notifications_log** — audit trail of push/SMS notifications sent

---

## 7. Use Case Summaries

### UC-1: Owner Lists a Machine
**Actor:** Machine Owner
**Precondition:** Owner is registered and logged in
**Flow:** Owner opens "Add Machine" → selects type → types the brand → (four-wheel tractors only) selects 2WD or 4WD from a dropdown → enters model, rate, service GN divisions → uploads photo → submits → machine appears in farmer search results
**Postcondition:** New machine record created, visible in search

### UC-2: Farmer Books a Machine
**Actor:** Farmer
**Precondition:** Farmer is registered and logged in; at least one machine has an open slot matching search
**Flow:** Farmer searches by type/division/date → selects machine → selects open slot → enters land location → submits request → system locks slot → owner notified
**Postcondition:** Booking created with status "requested"; slot status "pending"

### UC-3: Owner Responds to Booking Request
**Actor:** Machine Owner
**Precondition:** A booking exists with status "requested" for owner's machine
**Flow:** Owner views request → accepts or rejects → farmer notified
**Postcondition:** Booking status updated to "confirmed" or "rejected"; slot released if rejected

### UC-4: Post-Service Review
**Actor:** Owner or Farmer
**Precondition:** Booking status is "completed"
**Flow:** User opens completed booking → submits rating (1–5) and optional comment
**Postcondition:** Review recorded; reviewee's average rating updated

### UC-5: Admin Manages Users and Bookings
**Actor:** Admin
**Precondition:** Admin is logged in to the web panel
**Flow:** Admin searches a user → edits details or suspends the user → reviews that user's upcoming bookings → cancels or overrides bookings with a reason → both parties notified
**Postcondition:** Changes applied in a locked transaction; audit log entries written

### UC-6: Admin Books on Behalf of a Farmer
**Actor:** Admin
**Precondition:** A farmer contacts the admin by phone; the farmer has an account (or the admin creates one)
**Flow:** Admin finds the machine and an open slot → enters the farmer's land location → submits
**Postcondition:** Booking created with "created by admin" recorded; owner and farmer notified

---

## 8. Appendix

### 8.1 Machine Types (MVP)
1. Four-wheel tractor
2. Two-wheel hand tractor
3. Combine harvester
4. Water pump

Each machine also has a brand, typed by the owner. Four-wheel tractors also have a drive type: 2WD or 4WD.

### 8.2 Out of Scope for Version 1.0
- In-app payments
- Tamil language interface
- Expansion beyond Padaviya DS Division
- Owner earnings/analytics dashboard
- Formal dispute resolution workflow (admins override bookings manually)
- Brand catalog, other machine specifications (horsepower, wheel/track type), field-condition suitability matching, and admin verification of listings
- Live GPS tracking of machines

### 8.3 Document Revision History
| Version | Date | Change |
|---|---|---|
| 1.0 | Initial draft | First complete SRS covering MVP scope for Padaviya pilot |
| 1.1 | Update | Added admin role and web admin panel (FR-9.x), machine brand catalog and specs, field-condition suitability and warnings, admin verification of listings, audit log |
| 1.2 | Update | Simplified: brand is a plain text field typed by the owner. Removed brand catalog, machine specs, field-condition suitability, and listing verification. Admin role and audit log kept. |
| 1.3 | Update | Drive type (2WD/4WD) dropdown restored for four-wheel tractors only; not used for other machine types. |
| 1.4 | Update | Added UI requirements (NFR-12 to NFR-15) and the UI/UX guide: simple, attractive, lightweight design for old phones. |
