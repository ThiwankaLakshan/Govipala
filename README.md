# 🌾 Govipala (ගොවිපල) - Agricultural Machine Reservation System

> **Pilot Scope:** Padaviya DS Division, Anuradhapura District, North Central Province, Sri Lanka.

Govipala connects paddy and highland farmers with agricultural equipment owners for on-demand tractor, combine harvester, and water pump reservations. Designed with a **Sinhala-first, low-digital-literacy, and 2GB RAM budget** mobile experience, paired with a web administrative panel.

---

## 🏗️ Architecture & Tech Stack

* **Mobile & Web Frontend (`/app`):**
  * Built with Flutter 3.x
  * Bundled `Noto Sans Sinhala` font with 1.4–1.5 line height typography
  * Sinhala-first design system (`GoviColors`, `GoviSpacing`, `GoviTextStyles`)
  * Floating dev mode switcher pill between **🛡️ Admin Panel**, **🌾 Farmer View**, and **🚜 Owner View**
  * Offline-first architecture (`SharedPreferences` caching + offline booking request queue)
* **Backend API (`/backend`):**
  * Node.js, Express, TypeScript
  * PostgreSQL (with zero-config in-memory dev fallback when database is offline)
  * Row-level transaction locking (`SELECT ... FOR UPDATE`) preventing double bookings under high concurrency
  * Multi-channel notification engine (FCM Push + fallback SMS)
  * Comprehensive Jest test suite (47 tests across 5 suites, 100% pass)
* **Pilot Boundaries:**
  * Strict pilot restriction to Padaviya GN divisions
  * Fixed 4 machine categories: Four-Wheel Tractor (with 2WD/4WD badge), Combine Harvester, Two-Wheel Hand Tractor, Water Pump
  * Cash-on-service payments (no in-app payment gateway required for pilot)

---

## 📦 Project Structure

```
.
├── app/                  # Flutter mobile & web application
│   ├── lib/
│   │   ├── models/       # Data models (user, machine, slot, booking, review, notification)
│   │   ├── screens/      # Screens (auth, farmer, owner, admin web panel)
│   │   ├── services/     # API service, offline cache service
│   │   ├── theme/        # Govipala design tokens (colors, spacing, text styles)
│   │   └── widgets/      # Reusable UI components (booking card, slot chip, banner, etc.)
│   └── test/             # Flutter unit tests
├── backend/              # Node.js + TypeScript REST API
│   ├── src/
│   │   ├── controllers/  # Users, machines, availability, bookings, admin, reviews
│   │   ├── db/           # PostgreSQL connection pool & schema
│   │   ├── jobs/         # Auto-release expired pending slots (2-hour timeout)
│   │   ├── middleware/   # Authentication, role verification (admin/farmer/owner)
│   │   ├── models/       # Zod schemas & dev fallback stores
│   │   ├── routes/       # REST API endpoints
│   │   └── services/     # Audit logger, notification dispatcher (Push + SMS)
│   └── src/__tests__/    # Automated integration test suites
└── docs/                 # v1.4 Specification Package (PRD, Architecture, Schema, API, SRS, UI/UX)
```

---

## 🚀 Getting Started

### 1. Backend Setup

```bash
cd backend
npm install
npm run build
npm start
```
* **API Base URL:** `http://localhost:3000/api/v1`
* **Health Check:** `http://localhost:3000/health`
* **Automated Tests:** `npm test` (Runs all 47 tests)

### 2. Frontend Setup (Flutter)

```bash
cd app
flutter pub get
flutter run -d web-server --web-port=8080 --web-hostname=localhost
```
* **Web UI:** Open `http://localhost:8080` in your browser.
* **Test Suite:** `flutter test test/unit_test.dart`

---

## 🧪 Testing Credentials (Dev Mode)

* **Farmer View:** `Bearer dev_farmer_+94775551122` (Anura Kumara, Padaviya East)
* **Owner View:** `Bearer dev_owner_+94771234567` (Sunil Perera, Padaviya Town)
* **Admin Panel:** `Bearer dev_admin` (Govipala Admin)

---

## 📜 Specifications & Documentation

The `/docs` directory contains the complete v1.4 documentation package:
* `01_PRD.md` — Product Requirements Document
* `02_ARCHITECTURE.md` — Architecture & Transaction Locking Engine
* `03_DATABASE_SCHEMA.sql` — PostgreSQL Schema & Constraints
* `04_API_SPEC.md` — REST API Specification
* `05_SRS.md` — Software Requirements Specification
* `06_UI_UX_GUIDE.md` — Sinhala-first UI/UX Design System Guide
