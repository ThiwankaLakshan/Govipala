-- AgriMachine Database Schema
-- PostgreSQL
-- Pilot region: Padaviya DS Division, Anuradhapura District

-- ============================================
-- USERS
-- ============================================
CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(15) UNIQUE NOT NULL,   -- E.164 format, e.g. +94771234567
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    role            VARCHAR(10) NOT NULL CHECK (role IN ('owner', 'farmer', 'both')),
    gn_division     VARCHAR(100) NOT NULL,          -- e.g. "Padaviya Town", "Sripura"
    preferred_lang  VARCHAR(5) NOT NULL DEFAULT 'si', -- 'si' | 'en' | 'ta'
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_gn_division ON users(gn_division);

-- ============================================
-- MACHINES
-- ============================================
CREATE TABLE machines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    machine_type    VARCHAR(30) NOT NULL CHECK (
                        machine_type IN ('four_wheel_tractor', 'two_wheel_tractor',
                                          'combine_harvester', 'water_pump')
                    ),
    model_name      VARCHAR(100),
    rate_amount     NUMERIC(10,2) NOT NULL,
    rate_unit       VARCHAR(10) NOT NULL CHECK (rate_unit IN ('hour', 'day', 'acre')),
    photo_url       TEXT,
    service_gn_divisions TEXT[] NOT NULL,           -- array of GN divisions owner will travel to
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_machines_owner ON machines(owner_id);
CREATE INDEX idx_machines_type ON machines(machine_type);
CREATE INDEX idx_machines_gn_divisions ON machines USING GIN (service_gn_divisions);

-- ============================================
-- AVAILABILITY SLOTS
-- ============================================
CREATE TABLE availability_slots (
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

CREATE INDEX idx_slots_machine_date ON availability_slots(machine_id, slot_date);
CREATE INDEX idx_slots_status ON availability_slots(status);

-- ============================================
-- BOOKINGS
-- ============================================
CREATE TABLE bookings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    slot_id         UUID NOT NULL REFERENCES availability_slots(id),
    farmer_id       UUID NOT NULL REFERENCES users(id),
    land_location   TEXT,                            -- free-text description or GN division + notes
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

CREATE INDEX idx_bookings_farmer ON bookings(farmer_id);
CREATE INDEX idx_bookings_status ON bookings(status);

-- ============================================
-- REVIEWS
-- ============================================
CREATE TABLE reviews (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id      UUID NOT NULL UNIQUE REFERENCES bookings(id) ON DELETE CASCADE,
    reviewer_id     UUID NOT NULL REFERENCES users(id),   -- who left the review
    reviewee_id     UUID NOT NULL REFERENCES users(id),   -- who is being reviewed
    rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
    comment         TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_reviews_reviewee ON reviews(reviewee_id);

-- ============================================
-- NOTIFICATIONS LOG (for SMS/push audit trail)
-- ============================================
CREATE TABLE notifications_log (
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

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_machines_updated_at BEFORE UPDATE ON machines
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_slots_updated_at BEFORE UPDATE ON availability_slots
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
