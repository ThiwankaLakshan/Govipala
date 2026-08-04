# Software Requirements Specification (SRS)
## Govipala — Agricultural Machine Reservation System

**Pilot Region:** Padaviya Divisional Secretariat, Anuradhapura District, Sri Lanka
**Version:** 1.0
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

### 1.5 References
- Product Requirements Document (01_PRD.md)
- Technical Architecture Document (02_ARCHITECTURE.md)
- Database Schema (03_DATABASE_SCHEMA.sql)
- API Specification (04_API_SPEC.md)

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

### 2.3 User Classes and Characteristics

| User Class | Description | Technical Proficiency |
|---|---|---|
| Machine Owner | Owns/operates tractors, harvesters, water pumps for hire | Basic-to-moderate smartphone use |
| Farmer | Needs machine services for land preparation, harvesting, irrigation | Basic smartphone use, may have limited data connectivity |
| System Admin (future) | Manages disputes, verifies listings (not in MVP) | Technical |

### 2.4 Operating Environment
- Android smartphones, including low-spec devices (2GB RAM target minimum)
- Intermittent mobile data connectivity typical of rural Padaviya
- Backend hosted on cloud infrastructure (Node.js/Express + PostgreSQL), reachable via HTTPS

### 2.5 Design and Implementation Constraints
- Must function acceptably on low-end Android hardware
- Must tolerate low/no connectivity gracefully (local caching, queued actions)
- SMS must be available as a notification fallback, not solely push notifications
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

### 3.2 Machine Listing (Owner)
| ID | Requirement | Priority |
|---|---|---|
| FR-2.1 | Owner shall be able to create a machine listing specifying type, model name, rate, and rate unit (hour/day/acre). | H |
| FR-2.2 | Owner shall be able to upload a photo of the machine. | M |
| FR-2.3 | Owner shall specify one or more GN divisions the machine services. | H |
| FR-2.4 | Owner shall be able to edit or deactivate a machine listing. | M |
| FR-2.5 | System shall restrict machine type to a fixed list for MVP: four-wheel tractor, two-wheel tractor, combine harvester, water pump. | H |

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

### 3.8 Offline Behavior
| ID | Requirement | Priority |
|---|---|---|
| FR-8.1 | System shall cache the most recently viewed machine list and availability calendar locally on-device. | M |
| FR-8.2 | System shall queue booking requests submitted while offline and sync automatically upon reconnection. | M |
| FR-8.3 | System shall clearly display connection state (online/offline/syncing) to the user at all times. | M |

---

## 4. External Interface Requirements

### 4.1 User Interfaces
- Mobile-first UI, optimized for small/low-resolution Android screens
- Sinhala-first labeling and iconography; large tap targets for low digital-literacy users
- Calendar view for availability (owner) and slot browsing (farmer)

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

---

## 6. Data Requirements
Full schema defined in `03_DATABASE_SCHEMA.sql`. Core entities:
- **users** — phone-verified accounts with role and GN division
- **machines** — owner-listed equipment with type, rate, and service area
- **availability_slots** — date/time blocks per machine with status (open/pending/booked/blocked)
- **bookings** — farmer requests against slots, with full lifecycle status
- **reviews** — post-completion ratings between owner and farmer
- **notifications_log** — audit trail of push/SMS notifications sent

---

## 7. Use Case Summaries

### UC-1: Owner Lists a Machine
**Actor:** Machine Owner
**Precondition:** Owner is registered and logged in
**Flow:** Owner opens "Add Machine" → selects type → enters rate, model, service GN divisions → uploads photo → submits → machine appears in farmer search results
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

---

## 8. Appendix

### 8.1 Machine Types (MVP)
1. Four-wheel tractor
2. Two-wheel hand tractor
3. Combine harvester
4. Water pump

### 8.2 Out of Scope for Version 1.0
- In-app payments
- Tamil language interface
- Expansion beyond Padaviya DS Division
- Owner earnings/analytics dashboard
- Dispute resolution workflow
- Live GPS tracking of machines

### 8.3 Document Revision History
| Version | Date | Change |
|---|---|---|
| 1.0 | Initial draft | First complete SRS covering MVP scope for Padaviya pilot |
