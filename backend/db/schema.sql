-- AgriMachine Database Schema
-- PostgreSQL
-- Pilot region: Padaviya DS Division, Anuradhapura District

-- ============================================
-- USERS
-- ============================================
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(15) UNIQUE NOT NULL,   -- E.164 format, e.g. +94771234567
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    role            VARCHAR(10) NOT NULL CHECK (role IN ('owner', 'farmer', 'both')),
    gn_division     VARCHAR(100) NOT NULL,          -- e.g. "Padaviya Town", "Sripura"
    preferred_lang  VARCHAR(5) NOT NULL DEFAULT 'en', -- 'en' primary (English first), 'si' | 'ta'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_users_gn_division ON users(gn_division);

-- ============================================
-- MACHINES
-- ============================================
CREATE TABLE IF NOT EXISTS machines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    machine_type    VARCHAR(40) NOT NULL CHECK (
                        machine_type IN ('four_wheel_tractor', 'four_wheel_tractor_with_trailer',
                                          'two_wheel_tractor', 'two_wheel_tractor_with_trailer',
                                          'combine_harvester')
                    ),
    model_name      VARCHAR(100),
    paddy_type      VARCHAR(10) CHECK (paddy_type IN ('mud', 'dry')),
    rate_amount     NUMERIC(10,2) NOT NULL,
    rate_unit       VARCHAR(10) NOT NULL CHECK (rate_unit IN ('hour', 'day', 'acre')),
    photo_url       TEXT,
    service_gn_divisions TEXT[] NOT NULL,           -- array of GN divisions owner will travel to
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_machines_owner ON machines(owner_id);
CREATE INDEX IF NOT EXISTS idx_machines_type ON machines(machine_type);
CREATE INDEX IF NOT EXISTS idx_machines_gn_divisions ON machines USING GIN (service_gn_divisions);

-- ============================================
-- AVAILABILITY SLOTS
-- ============================================
CREATE TABLE IF NOT EXISTS availability_slots (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    machine_id      UUID NOT NULL REFERENCES machines(id) ON DELETE CASCADE,
    slot_date       DATE NOT NULL,
    start_time      TIME NOT NULL,
    end_time        TIME NOT NULL,
    status          VARCHAR(10) NOT NULL DEFAULT 'open' CHECK (
                        status IN ('open', 'pending', 'booked', 'blocked')
                    ),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

CREATE INDEX IF NOT EXISTS idx_slots_machine_date ON availability_slots(machine_id, slot_date);
CREATE INDEX IF NOT EXISTS idx_slots_status ON availability_slots(status);

-- ============================================
-- BOOKINGS
-- ============================================
CREATE TABLE IF NOT EXISTS bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slot_id         UUID NOT NULL REFERENCES availability_slots(id),
    farmer_id       UUID NOT NULL REFERENCES users(id),
    land_location   TEXT,                            -- free-text description or GN division + notes
    land_size_acres NUMERIC(6,2) NOT NULL CHECK (land_size_acres > 0),
    status          VARCHAR(15) NOT NULL DEFAULT 'requested' CHECK (
                        status IN ('requested', 'confirmed', 'rejected',
                                   'in_progress', 'completed', 'cancelled')
                    ),
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at    TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    cancellation_reason TEXT,

    UNIQUE(slot_id)  -- one booking per slot, enforced at DB level as a second safety net
);

CREATE INDEX IF NOT EXISTS idx_bookings_farmer ON bookings(farmer_id);
CREATE INDEX IF NOT EXISTS idx_bookings_status ON bookings(status);

-- ============================================
-- REVIEWS
-- ============================================
CREATE TABLE IF NOT EXISTS reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id     UUID NOT NULL REFERENCES users(id),   -- who left the review
    reviewee_id     UUID NOT NULL REFERENCES users(id),   -- who is being reviewed
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);

-- ============================================
-- NOTIFICATIONS LOG (for SMS/push audit trail)
-- ============================================
CREATE TABLE IF NOT EXISTS notifications_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    booking_id      UUID REFERENCES bookings(id),
    channel         VARCHAR(10) NOT NULL CHECK (channel IN ('push', 'sms')),
    message         TEXT NOT NULL,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT now(),
    delivery_status VARCHAR(10) DEFAULT 'sent'
);

-- ============================================
-- TRIGGER: auto-update updated_at columns
-- ============================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_users_updated_at ON users;
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_machines_updated_at ON machines;
CREATE TRIGGER trg_machines_updated_at BEFORE UPDATE ON machines
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

DROP TRIGGER IF EXISTS trg_slots_updated_at ON availability_slots;
CREATE TRIGGER trg_slots_updated_at BEFORE UPDATE ON availability_slots
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
