# Govipala — Starter Document Package (v1.4)

This folder has everything you need to hand to Google Antigravity to start building.

## Files in this package
1. **00_README.md** — this file
2. **01_PRD.md** — what you're building and why (problem, users, MVP scope, success metrics)
3. **02_ARCHITECTURE.md** — tech stack, system design, folder structure, offline strategy
4. **03_DATABASE_SCHEMA.sql** — full Postgres schema, ready to run
5. **04_API_SPEC.md** — REST API contract between the Flutter app and backend
6. **05_SRS.md** — full Software Requirements Specification with traceable requirement IDs
7. **06_UI_UX_GUIDE.md** — look and feel, key screens, and the performance rules for old phones

v1.4 adds a simple, attractive, lightweight UI guide (06_UI_UX_GUIDE.md). v1.3 added: an admin role with a web admin panel, a brand field on each machine listing (typed by the owner), and a 2WD/4WD drive type dropdown for four-wheel tractors.

## How to use this with Antigravity

1. Create a new project folder locally, e.g. `agrimachine/`
2. Drop these 7 files into `agrimachine/docs/`
3. Open the folder in Antigravity
4. In the Manager view, give your first agent task something like:

   > "Read all files in /docs. Set up the initial project structure: a Flutter app in /app following the structure in 02_ARCHITECTURE.md, and a Node.js/Express backend in /backend that implements the schema in 03_DATABASE_SCHEMA.sql and the endpoints in 04_API_SPEC.md. Start with user registration and phone OTP auth end-to-end before building other features. Then build the admin web panel described in 02_ARCHITECTURE.md section 5b. Before building any screen, create the app theme and reusable widgets from 06_UI_UX_GUIDE.md."

5. Let the agent run, review its Artifacts (screenshots, plan, test results) before approving further steps
6. Suggested build order for subsequent agent tasks:
   - Phase 1: Auth (Firebase phone OTP) end-to-end, Flutter ↔ backend ↔ Postgres
   - Phase 2: Machine listing, with the brand typed by the owner and the drive type dropdown for four-wheel tractors (owner side) + browsing (farmer side)
   - Phase 2b: Admin panel: users, machines, slots, bookings, reviews, audit log
   - Phase 3: Availability calendar + booking request flow (the transactional logic in 02_ARCHITECTURE.md Section 3 is the highest-risk piece — ask the agent to write tests specifically for double-booking prevention)
   - Phase 4: Notifications (push + SMS)
   - Phase 5: Reviews/ratings
   - Phase 6: Offline caching polish

## A few things to double check before you start
- Set up a Firebase project and enable Phone Authentication (Blaze plan required for SMS, but first 10/day stay free)
- Set up a free Postgres instance (Neon or Railway both work well for a pilot) and get your `DATABASE_URL`
- Get an SMS gateway account (Dialog/Mobitel local gateway, or Twilio) for status-update SMS — separate from Firebase's OTP SMS
- Enable the Email/Password provider in Firebase Authentication for admin accounts, and create your first admin (instructions at the end of `03_DATABASE_SCHEMA.sql`)
- Have real Padaviya GN division names ready to seed as location options (Padaviya Town, Sripura, and others — confirm the full list with your DS office or GN officers directly, since some sources list variants)

## Reminder on scope discipline
Don't let the agent build Phase 2+ machine categories or Tamil language support in v1 — the PRD deliberately scopes those out so your pilot ships fast and validates real demand in Padaviya first.
