-- ============================================================
-- HOSPITAL MANAGEMENT DATABASE SCHEMA
-- Domain: Hospital/clinic administration (patients, doctors,
--         appointments, medical records, billing)
-- PostgreSQL 15+
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- ENUM TYPES
-- ────────────────────────────────────────────────────────────

CREATE TYPE gender_type AS ENUM ('male', 'female', 'other');

CREATE TYPE appointment_status AS ENUM (
    'scheduled', 'checked_in', 'in_progress',
    'completed', 'cancelled', 'no_show'
);

CREATE TYPE room_type AS ENUM (
    'general', 'private', 'icu', 'operation_theatre', 'emergency'
);

CREATE TYPE room_status AS ENUM ('available', 'occupied', 'maintenance');

CREATE TYPE billing_status AS ENUM (
    'pending', 'partially_paid', 'paid', 'overdue', 'waived'
);

-- ────────────────────────────────────────────────────────────
-- 1. DEPARTMENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE departments (
    department_id  SERIAL        PRIMARY KEY,
    name           VARCHAR(100)  NOT NULL UNIQUE,
    description    TEXT,
    floor_number   SMALLINT,
    phone_ext      VARCHAR(10),
    created_at     TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE departments IS 'Hospital departments (Cardiology, Neurology, etc.)';

-- ────────────────────────────────────────────────────────────
-- 2. DOCTORS
-- ────────────────────────────────────────────────────────────
CREATE TABLE doctors (
    doctor_id       SERIAL         PRIMARY KEY,
    first_name      VARCHAR(50)    NOT NULL,
    last_name       VARCHAR(50)    NOT NULL,
    email           VARCHAR(100)   NOT NULL UNIQUE,
    phone           VARCHAR(20)    NOT NULL,
    specialization  VARCHAR(100)   NOT NULL,
    license_number  VARCHAR(50)    NOT NULL UNIQUE,
    department_id   INT            NOT NULL
                                   REFERENCES departments(department_id)
                                   ON DELETE RESTRICT,
    hire_date       DATE           NOT NULL DEFAULT CURRENT_DATE,
    is_active       BOOLEAN        NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE doctors IS 'Physicians and specialists on staff';

CREATE INDEX idx_doctors_department     ON doctors (department_id);
CREATE INDEX idx_doctors_specialization ON doctors (specialization);
CREATE INDEX idx_doctors_name           ON doctors (last_name, first_name);

-- ────────────────────────────────────────────────────────────
-- 3. PATIENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE patients (
    patient_id      SERIAL         PRIMARY KEY,
    first_name      VARCHAR(50)    NOT NULL,
    last_name       VARCHAR(50)    NOT NULL,
    date_of_birth   DATE           NOT NULL,
    gender          gender_type    NOT NULL,
    email           VARCHAR(100)   UNIQUE,
    phone           VARCHAR(20)    NOT NULL,
    address         TEXT,
    blood_group     VARCHAR(5),
    emergency_contact_name  VARCHAR(100),
    emergency_contact_phone VARCHAR(20),
    insurance_id    VARCHAR(50),
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE patients IS 'Registered patients with personal and insurance info';

CREATE INDEX idx_patients_name    ON patients (last_name, first_name);
CREATE INDEX idx_patients_dob     ON patients (date_of_birth);
CREATE INDEX idx_patients_phone   ON patients (phone);

-- ────────────────────────────────────────────────────────────
-- 4. ROOMS
-- ────────────────────────────────────────────────────────────
CREATE TABLE rooms (
    room_id         SERIAL         PRIMARY KEY,
    room_number     VARCHAR(10)    NOT NULL UNIQUE,
    department_id   INT            NOT NULL
                                   REFERENCES departments(department_id)
                                   ON DELETE RESTRICT,
    type            room_type      NOT NULL DEFAULT 'general',
    status          room_status    NOT NULL DEFAULT 'available',
    bed_count       SMALLINT       NOT NULL DEFAULT 1
                                   CHECK (bed_count > 0),
    daily_rate      NUMERIC(10, 2) NOT NULL CHECK (daily_rate >= 0),
    floor_number    SMALLINT,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE rooms IS 'Hospital rooms with type, capacity, and availability';

CREATE INDEX idx_rooms_department ON rooms (department_id);
CREATE INDEX idx_rooms_status     ON rooms (status);
CREATE INDEX idx_rooms_type       ON rooms (type);

-- ────────────────────────────────────────────────────────────
-- 5. APPOINTMENTS
-- ────────────────────────────────────────────────────────────
CREATE TABLE appointments (
    appointment_id   SERIAL              PRIMARY KEY,
    patient_id       INT                 NOT NULL
                                         REFERENCES patients(patient_id)
                                         ON DELETE CASCADE,
    doctor_id        INT                 NOT NULL
                                         REFERENCES doctors(doctor_id)
                                         ON DELETE RESTRICT,
    appointment_date DATE                NOT NULL,
    start_time       TIME                NOT NULL,
    end_time         TIME                NOT NULL,
    status           appointment_status  NOT NULL DEFAULT 'scheduled',
    reason           TEXT,
    notes            TEXT,
    created_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ         NOT NULL DEFAULT NOW(),

    CONSTRAINT chk_time_range CHECK (end_time > start_time)
);

COMMENT ON TABLE appointments IS 'Scheduled and completed patient-doctor appointments';

CREATE INDEX idx_appt_patient    ON appointments (patient_id);
CREATE INDEX idx_appt_doctor     ON appointments (doctor_id);
CREATE INDEX idx_appt_date       ON appointments (appointment_date);
CREATE INDEX idx_appt_status     ON appointments (status);

-- Prevent double-booking a doctor at the same date/time
CREATE UNIQUE INDEX uq_doctor_slot
    ON appointments (doctor_id, appointment_date, start_time)
    WHERE status NOT IN ('cancelled', 'no_show');

-- ────────────────────────────────────────────────────────────
-- 6. MEDICAL RECORDS
-- ────────────────────────────────────────────────────────────
CREATE TABLE medical_records (
    record_id       SERIAL         PRIMARY KEY,
    patient_id      INT            NOT NULL
                                   REFERENCES patients(patient_id)
                                   ON DELETE CASCADE,
    doctor_id       INT            NOT NULL
                                   REFERENCES doctors(doctor_id)
                                   ON DELETE RESTRICT,
    appointment_id  INT            REFERENCES appointments(appointment_id)
                                   ON DELETE SET NULL,
    diagnosis       TEXT           NOT NULL,
    symptoms        TEXT,
    treatment       TEXT,
    notes           TEXT,
    record_date     DATE           NOT NULL DEFAULT CURRENT_DATE,
    created_at      TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE medical_records IS 'Patient diagnosis and treatment history';

CREATE INDEX idx_medrec_patient     ON medical_records (patient_id);
CREATE INDEX idx_medrec_doctor      ON medical_records (doctor_id);
CREATE INDEX idx_medrec_date        ON medical_records (record_date DESC);

-- ────────────────────────────────────────────────────────────
-- 7. PRESCRIPTIONS
-- ────────────────────────────────────────────────────────────
CREATE TABLE prescriptions (
    prescription_id  SERIAL         PRIMARY KEY,
    record_id        INT            NOT NULL
                                    REFERENCES medical_records(record_id)
                                    ON DELETE CASCADE,
    patient_id       INT            NOT NULL
                                    REFERENCES patients(patient_id)
                                    ON DELETE CASCADE,
    doctor_id        INT            NOT NULL
                                    REFERENCES doctors(doctor_id)
                                    ON DELETE RESTRICT,
    medication_name  VARCHAR(200)   NOT NULL,
    dosage           VARCHAR(100)   NOT NULL,
    frequency        VARCHAR(100)   NOT NULL,
    duration_days    INT            CHECK (duration_days > 0),
    instructions     TEXT,
    prescribed_date  DATE           NOT NULL DEFAULT CURRENT_DATE,
    created_at       TIMESTAMPTZ    NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE prescriptions IS 'Medications prescribed during a medical visit';

CREATE INDEX idx_rx_record    ON prescriptions (record_id);
CREATE INDEX idx_rx_patient   ON prescriptions (patient_id);
CREATE INDEX idx_rx_doctor    ON prescriptions (doctor_id);
CREATE INDEX idx_rx_med       ON prescriptions (medication_name);

-- ────────────────────────────────────────────────────────────
-- 8. BILLING
-- ────────────────────────────────────────────────────────────
CREATE TABLE billing (
    bill_id          SERIAL           PRIMARY KEY,
    patient_id       INT              NOT NULL
                                      REFERENCES patients(patient_id)
                                      ON DELETE CASCADE,
    appointment_id   INT              REFERENCES appointments(appointment_id)
                                      ON DELETE SET NULL,
    room_id          INT              REFERENCES rooms(room_id)
                                      ON DELETE SET NULL,
    total_amount     NUMERIC(12, 2)   NOT NULL CHECK (total_amount >= 0),
    discount         NUMERIC(12, 2)   NOT NULL DEFAULT 0
                                      CHECK (discount >= 0),
    tax              NUMERIC(12, 2)   NOT NULL DEFAULT 0
                                      CHECK (tax >= 0),
    net_amount       NUMERIC(12, 2)   GENERATED ALWAYS AS (
                         total_amount - discount + tax
                     ) STORED,
    status           billing_status   NOT NULL DEFAULT 'pending',
    insurance_claim  BOOLEAN          NOT NULL DEFAULT FALSE,
    due_date         DATE,
    paid_at          TIMESTAMPTZ,
    created_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ      NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE billing IS 'Patient billing with insurance and payment tracking';

CREATE INDEX idx_billing_patient   ON billing (patient_id);
CREATE INDEX idx_billing_status    ON billing (status);
CREATE INDEX idx_billing_due       ON billing (due_date)
    WHERE status IN ('pending', 'partially_paid', 'overdue');

-- ============================================================
-- KEY TAKEAWAYS
-- ============================================================
-- 1. Partial unique index on appointments prevents double-booking
--    while allowing cancelled/no-show slots to be reused
-- 2. GENERATED ALWAYS AS computes net_amount automatically
-- 3. gender_type ENUM keeps data clean at the database level
-- 4. ON DELETE RESTRICT on doctors prevents removing a doctor
--    who has existing appointments or records
-- 5. Separate prescriptions table (not JSONB) keeps medications
--    query-friendly and individually indexable
-- ============================================================
