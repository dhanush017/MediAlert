-- MediAlert initial schema (Day 1).
-- Requires PostgreSQL 13+ (gen_random_uuid is built in).

-- Accounts. A user can be a patient, a caregiver, or both.
CREATE TABLE users (
  id                uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  email             text UNIQUE,
  password_hash     text,
  role              text NOT NULL CHECK (role IN ('patient', 'caregiver', 'both')),
  timezone          text NOT NULL DEFAULT 'Asia/Kolkata',
  telegram_chat_id  bigint UNIQUE,            -- NULL until the Telegram link is completed
  created_at        timestamptz NOT NULL DEFAULT now(),
  deleted_at        timestamptz               -- soft-delete marker for account deletion (Day 6)
);

-- Consent records, one row per consent given (type and version).
CREATE TABLE consents (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       uuid NOT NULL REFERENCES users(id),
  consent_type  text NOT NULL,
  version       text NOT NULL,
  given_at      timestamptz NOT NULL DEFAULT now()
);

-- Caregiver links, approved by the patient and revocable at any time.
CREATE TABLE caregiver_links (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id    uuid NOT NULL REFERENCES users(id),
  caregiver_id  uuid NOT NULL REFERENCES users(id),
  status        text NOT NULL CHECK (status IN ('pending', 'active', 'revoked')),
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now(),
  CHECK (patient_id <> caregiver_id)
);

CREATE TABLE medicines (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id  uuid NOT NULL REFERENCES users(id),
  name        text NOT NULL,
  dosage      text,
  notes       text,
  created_at  timestamptz NOT NULL DEFAULT now(),
  deleted_at  timestamptz
);

CREATE TABLE schedules (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  medicine_id  uuid NOT NULL REFERENCES medicines(id),
  times_local  text[] NOT NULL,              -- e.g. {'08:00','20:00'} in the patient's timezone
  frequency    text NOT NULL,                -- e.g. 'daily', 'twice_daily'
  starts_on    date NOT NULL,
  ends_on      date,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- One row per scheduled dose. The unique constraint makes scheduling idempotent (Day 3).
CREATE TABLE dose_events (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  schedule_id     uuid NOT NULL REFERENCES schedules(id),
  scheduled_time  timestamptz NOT NULL,
  status          text NOT NULL DEFAULT 'scheduled'
                  CHECK (status IN ('scheduled', 'reminded', 'taken', 'skipped', 'missed')),
  reminded_at     timestamptz,
  resolved_at     timestamptz,
  UNIQUE (schedule_id, scheduled_time)
);

-- Raw Telegram updates, stored before processing so every message is recorded.
CREATE TABLE inbound_messages (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  telegram_update_id  bigint UNIQUE NOT NULL,   -- dedupes repeated webhook deliveries
  chat_id       bigint NOT NULL,
  payload       jsonb NOT NULL,
  received_at   timestamptz NOT NULL DEFAULT now(),
  processed_at  timestamptz
);

-- Alerts sent to caregivers. Only one open alert per patient and medicine.
CREATE TABLE alerts (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  patient_id   uuid NOT NULL REFERENCES users(id),
  medicine_id  uuid NOT NULL REFERENCES medicines(id),
  kind         text NOT NULL CHECK (kind IN ('missed_streak')),
  opened_at    timestamptz NOT NULL DEFAULT now(),
  closed_at    timestamptz
);

CREATE UNIQUE INDEX alerts_one_open_per_medicine
  ON alerts (patient_id, medicine_id, kind)
  WHERE closed_at IS NULL;

-- Append-only audit trail. Every change to schedules, medicines, or caregiver links is logged here.
CREATE TABLE audit_logs (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  actor_user_id   uuid REFERENCES users(id),
  action          text NOT NULL,
  target_table    text NOT NULL,
  target_id       uuid,
  previous_state  jsonb,
  new_state       jsonb,
  source          text NOT NULL CHECK (source IN ('web', 'telegram', 'system')),
  created_at      timestamptz NOT NULL DEFAULT now()
);

-- Block UPDATE and DELETE on audit_logs. This works for any role that does not own the table.
-- The app database role should also be granted only INSERT and SELECT (see docs/ and the Day 1 test).
CREATE FUNCTION forbid_audit_log_changes() RETURNS trigger AS $$
BEGIN
  RAISE EXCEPTION 'audit_logs is append-only';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER audit_logs_no_update
  BEFORE UPDATE OR DELETE ON audit_logs
  FOR EACH ROW EXECUTE FUNCTION forbid_audit_log_changes();

CREATE TRIGGER audit_logs_no_truncate
  BEFORE TRUNCATE ON audit_logs
  FOR EACH STATEMENT EXECUTE FUNCTION forbid_audit_log_changes();
