# API Specification
## Govipala Backend REST API (v1.4)

Base URL (dev): `http://localhost:3000/api/v1`

All endpoints except `/auth/*` require header:
`Authorization: Bearer <firebase_id_token>`

Backend verifies the Firebase token, resolves it to a `users.id`, and uses that for all authorization checks.
Users with status `suspended` or `deleted` receive `403 { "error": "account_suspended" }` on every endpoint.
All `/admin/*` endpoints require `role = admin`; otherwise `403 { "error": "admin_only" }`.

---

## Auth & Users

### `POST /users/register`
Creates a user record after first successful Firebase phone auth. `role` may be `owner`, `farmer`, or `both`; `admin` is rejected with `403`.
```json
Request:
{
  "full_name": "Sunil Perera",
  "role": "owner",           // "owner" | "farmer" | "both"
  "gn_division": "Padaviya Town",
  "preferred_lang": "si"
}
Response: 201
{ "id": "uuid", "full_name": "...", "role": "owner", ... }
```

### `GET /users/me`
Returns the logged-in user's profile.

### `PATCH /users/me`
Update profile fields (name, gn_division, preferred_lang).

---

## Machines

### `POST /machines`
Owner creates a machine listing.
```json
Request:
{
  "machine_type": "four_wheel_tractor",
  "brand": "Massey Ferguson",            // free text typed by the owner, required, 1-80 characters
  "drive_type": "4wd",                   // "2wd" | "4wd"; required for four_wheel_tractor, must be omitted for other types
  "model_name": "240",
  "rate_amount": 3500,
  "rate_unit": "day",
  "photo_url": "https://...",
  "service_gn_divisions": ["Padaviya Town", "Sripura"]
}
Response: 201 { "id": "uuid", ... }
```
The brand (and the drive type, for four-wheel tractors) is shown on the machine card and detail page.
Validation errors: `400 drive_type_required` (four-wheel tractor without a drive type) and `400 drive_type_not_allowed` (drive type sent for any other machine type).

### `GET /machines`
Farmer browses machines. Query params:
`?machine_type=four_wheel_tractor&gn_division=Padaviya+Town&date=2026-08-10`

Returns active machines matching type + service area, with an `available_slots` array for the given date if provided. Each machine includes its brand, and its drive type if it is a four-wheel tractor.

### `GET /machines/:id`
Full machine detail including owner name, rating average, upcoming availability.

### `PATCH /machines/:id`
Owner updates their machine listing (brand, drive type, rate, active status, etc). Drive type must stay consistent with the machine type.

### `DELETE /machines/:id`
Owner deactivates (soft-delete via `is_active = false`) a machine.

---

## Availability Slots

### `POST /machines/:id/availability`
Owner adds one or more open slots.
```json
Request:
{
  "slots": [
    { "slot_date": "2026-08-10", "start_time": "07:00", "end_time": "12:00" },
    { "slot_date": "2026-08-10", "start_time": "13:00", "end_time": "17:00" }
  ]
}
Response: 201 { "created": 2 }
```

### `GET /machines/:id/availability?from=2026-08-01&to=2026-08-31`
Returns all slots for a machine in a date range, with status.

### `DELETE /availability/:slotId`
Owner removes an `open` slot (cannot delete `pending`/`booked` slots).

---

## Bookings

### `POST /bookings`
Farmer requests a booking on an open slot. **This is the critical transactional endpoint** — see Architecture doc Section 3 for required locking behavior.
```json
Request:
{
  "slot_id": "uuid",
  "land_location": "Near Padaviya tank, 2 acres, paddy field"
}
Response: 201 { "id": "uuid", "status": "requested" }
Response: 409 { "error": "slot_no_longer_available" }  // if lock/check fails
```

### `GET /bookings/mine`
Returns bookings for the logged-in user (as farmer or owner, filtered by role in query: `?as=farmer` or `?as=owner`).

### `PATCH /bookings/:id/respond`
Owner accepts or rejects a requested booking.
```json
Request: { "action": "confirm" }   // or "reject"
Response: 200 { "id": "uuid", "status": "confirmed" }
```

### `PATCH /bookings/:id/status`
Update lifecycle status (in_progress, completed, cancelled).
```json
Request: { "status": "completed" }
```

---

## Reviews

### `POST /bookings/:id/review`
Either party leaves a review after a booking is `completed`.
```json
Request:
{
  "rating": 5,
  "comment": "Arrived on time, good work"
}
```

### `GET /users/:id/reviews`
Public reviews for a given user (owner or farmer), with average rating. Reviews hidden by an admin are excluded.

---

---

## Admin (all require `role = admin`)

Every write below is recorded in `admin_audit_log` (admin, action, target, before/after, optional `reason`) in the same transaction as the change.

### Dashboard
- `GET /admin/stats` — counts: users by role, machines, bookings by status, bookings today

### Users (both sides)
- `GET /admin/users?role=&status=&gn_division=&q=` — search/filter, paginated
- `GET /admin/users/:id` — full profile with their machines/bookings summary
- `POST /admin/users` — create a user on someone's behalf (including another admin)
- `PATCH /admin/users/:id` — edit name, role, GN division, language, contact
- `PATCH /admin/users/:id/status` — `{ "status": "suspended" | "active" | "deleted", "reason": "..." }`.
  Response lists any future confirmed/pending bookings affected, so the admin can cancel them explicitly.

### Machines
- `GET /admin/machines?owner_id=&machine_type=&q=`
- `PATCH /admin/machines/:id` — edit any field (including brand) on the owner's behalf
- `DELETE /admin/machines/:id` — deactivate (`is_active = false`)

### Availability slots
- `POST /admin/machines/:id/availability` — add slots for any machine
- `PATCH /admin/availability/:slotId` — change time or status (including `blocked`)
- `DELETE /admin/availability/:slotId` — if the slot is `pending` or `booked`, the linked booking is cancelled with a required `reason` and both parties are notified

### Bookings
- `GET /admin/bookings?status=&farmer_id=&owner_id=&machine_id=&from=&to=`
- `POST /admin/bookings` — book on behalf of a farmer (`farmer_id`, `slot_id`, `land_location`); stored with `created_by_admin`
- `PATCH /admin/bookings/:id` — override status (`confirmed`, `rejected`, `in_progress`, `completed`, `cancelled`) with a `reason`; slot status is kept consistent in the same transaction

### Reviews
- `PATCH /admin/reviews/:id/hide` — `{ "is_hidden": true, "reason": "..." }`

### Audit log
- `GET /admin/audit-log?admin_id=&target_table=&target_id=&from=&to=` — read-only

---

## Notifications (internal, not called by Flutter directly)
Backend triggers push (FCM) + SMS fallback automatically on:
- Booking requested → notify owner
- Booking confirmed/rejected → notify farmer
- Booking status changed to completed → notify farmer (prompt for review)
- Admin cancels or overrides a booking, or deletes a booked slot → notify both farmer and owner

---

## Error Response Format (consistent across all endpoints)
```json
{
  "error": "error_code_string",
  "message": "Human-readable message (localized based on Accept-Language header)"
}
```

## Standard HTTP Status Codes Used
- `200` OK, `201` Created
- `400` Validation error
- `401` Missing/invalid auth token
- `403` Authenticated but not authorized for this action
- `404` Resource not found
- `409` Conflict (e.g. slot already booked)
- `500` Server error
