# API Specification
## AgriMachine Backend REST API

Base URL (dev): `http://localhost:3000/api/v1`

All endpoints except `/auth/*` require header:
`Authorization: Bearer <firebase_id_token>`

Backend verifies the Firebase token, resolves it to a `users.id`, and uses that for all authorization checks.

---

## Auth & Users

### `POST /users/register`
Creates a user record after first successful Firebase phone auth.
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
  "model_name": "Massey Ferguson 240",
  "rate_amount": 3500,
  "rate_unit": "day",
  "photo_url": "https://...",
  "service_gn_divisions": ["Padaviya Town", "Sripura"]
}
Response: 201 { "id": "uuid", ... }
```

### `GET /machines`
Farmer browses machines. Query params:
`?machine_type=four_wheel_tractor&gn_division=Padaviya+Town&date=2026-08-10`

Returns machines matching type + service area, with an `available_slots` array for the given date if provided.

### `GET /machines/:id`
Full machine detail including owner name, rating average, upcoming availability.

### `PATCH /machines/:id`
Owner updates their machine listing (rate, active status, etc).

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
Public reviews for a given user (owner or farmer), with average rating.

---

## Notifications (internal, not called by Flutter directly)
Backend triggers push (FCM) + SMS fallback automatically on:
- Booking requested → notify owner
- Booking confirmed/rejected → notify farmer
- Booking status changed to completed → notify farmer (prompt for review)

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
