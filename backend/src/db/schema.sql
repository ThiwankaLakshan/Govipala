-- Govipala Database Schema (v1.4)
-- PostgreSQL
-- Pilot region: Padaviya DS Division, Anuradhapura District

CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    phone_number    VARCHAR(15) UNIQUE,              -- E.164, e.g. +94771234567. Nullable: admins may sign in by email
    email           VARCHAR(255) UNIQUE,             -- used by admins (Firebase email/password)
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    role            VARCHAR(10) NOT NULL CHECK (role IN ('owner', 'farmer', 'both', 'admin')),
    gn_division     VARCHAR(100),                    -- required for everyone except admins
    preferred_lang  VARCHAR(5) NOT NULL DEFAULT 'si', -- 'si' | 'en' | 'ta'
    status          VARCHAR(10) NOT NULL DEFAULT 'active'
                        CHECK (status IN ('active', 'suspended', 'deleted')),  -- 'deleted' = soft delete
    created_by      UUID REFERENCES users(id),       -- set when an admin creates the account
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT contact_required CHECK (phone_number IS NOT NULL OR email IS NOT NULL),
    CONSTRAINT gn_required CHECK (role = 'admin' OR gn_division IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_users_gn_division ON users(gn_division);
CREATE INDEX IF NOT EXISTS idx_users_role_status ON users(role, status);

-- ============================================
-- MACHINES
-- ============================================
CREATE TABLE IF NOT EXISTS machines (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    owner_id        UUID NOT NULL REFERENCES users(id),
    machine_type    VARCHAR(30) NOT NULL CHECK (
                        machine_type IN ('four_wheel_tractor', 'two_wheel_tractor',
                                          'combine_harvester', 'water_pump')
                    ),
    brand           VARCHAR(80) NOT NULL CHECK (length(trim(brand)) > 0),  -- typed by the owner
    drive_type      VARCHAR(3) CHECK (drive_type IN ('2wd', '4wd')),       -- four-wheel tractors only
    model_name      VARCHAR(100),
    rate_amount     NUMERIC(10,2) NOT NULL,
    rate_unit       VARCHAR(10) NOT NULL CHECK (rate_unit IN ('hour', 'day', 'acre')),
    photo_url       TEXT,
    service_gn_divisions TEXT[] NOT NULL,           -- array of GN divisions owner will travel to
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    CONSTRAINT drive_type_rules CHECK (
        (machine_type = 'four_wheel_tractor' AND drive_type IS NOT NULL)
        OR (machine_type <> 'four_wheel_tractor' AND drive_type IS NULL)
    )
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
    status          VARCHAR(15) NOT NULL DEFAULT 'requested' CHECK (
                        status IN ('requested', 'confirmed', 'rejected',
                                   'in_progress', 'completed', 'cancelled')
                    ),
    created_by_admin UUID REFERENCES users(id),      -- set when an admin books on behalf of a farmer
    requested_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    responded_at    TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    cancellation_reason TEXT,

    UNIQUE(slot_id)  -- one booking per slot, enforced at DB level
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
    is_hidden       BOOLEAN NOT NULL DEFAULT false,       -- admin moderation
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_reviews_reviewee ON reviews(reviewee_id);

-- ============================================
-- NOTIFICATIONS LOG
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
-- ADMIN AUDIT LOG
-- ============================================
CREATE TABLE IF NOT EXISTS admin_audit_log (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id        UUID NOT NULL REFERENCES users(id),
    action          VARCHAR(50) NOT NULL,
    target_table    VARCHAR(30) NOT NULL,
    target_id       UUID,
    before_data     JSONB,
    after_data      JSONB,
    reason          TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_audit_admin ON admin_audit_log(admin_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_target ON admin_audit_log(target_table, target_id);

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
