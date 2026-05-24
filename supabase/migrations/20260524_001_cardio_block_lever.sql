-- Cardio block lever — floating-frequency LISS prescription separate from
-- step targets. Spec at MyPocketCoach-Brain/11-Roadmap/app-smart-cardio-prescription-spec.md
--
-- Tables:
--   cardio_prescriptions  — active recipe (incl. tier tracking + coach override)
--   cardio_completions    — each tap-to-log session, week-bucketed
--
-- Plus one column on user_profiles for the equipment question (drives modality
-- choice). Nullable: derivation handles null with a sane default.
--
-- Autonomous engine (cardioPrescriptionService) evaluates at weekly check-in,
-- writes new prescription rows when tier changes, respects manual_override.
-- Coach dashboard writes through PUT /coach/clients/:id/cardio-prescription
-- with audit-log + manual_override semantics.
--
-- Backend uses SUPABASE_SERVICE_ROLE_KEY (bypasses RLS); policies are kept
-- as belt-and-suspenders against any future direct-from-client access.

BEGIN;

-- 1. user_profiles.cardio_equipment — from onboarding (or coach settable later)
ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS cardio_equipment TEXT
    CHECK (cardio_equipment IN ('stairmaster', 'treadmill_incline', 'outdoor_only'));

-- 2. cardio_prescriptions — active recipe per user (one row at a time via
-- active_until partial index). New rows on tier change; old rows get
-- active_until=today so history is preserved for the coach view.
CREATE TABLE IF NOT EXISTS cardio_prescriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Prescription content
  frequency_per_week INT NOT NULL CHECK (frequency_per_week BETWEEN 1 AND 7),
  modality TEXT NOT NULL CHECK (modality IN ('stairs', 'incline_treadmill', 'walking', 'mixed')),
  duration_minutes INT NOT NULL CHECK (duration_minutes BETWEEN 5 AND 90),

  -- Tier tracking (autonomous engine state)
  escalation_tier INT NOT NULL DEFAULT 0 CHECK (escalation_tier BETWEEN 0 AND 3),
  last_bumped_at TIMESTAMPTZ,
  bump_history JSONB NOT NULL DEFAULT '[]'::jsonb,
  -- Shape: [{at: ISO, from_tier: 0..3, to_tier: 0..3, reason: 'off_track'|'on_track'|'manual'|'init', context: {...}}]

  -- Coach manual override — when true, autonomous engine holds and does not bump
  manual_override BOOLEAN NOT NULL DEFAULT FALSE,
  override_set_by UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  override_set_at TIMESTAMPTZ,
  coach_note TEXT,
  coach_note_visible_to_client BOOLEAN NOT NULL DEFAULT FALSE,

  -- Lifecycle
  rationale TEXT,
  active_from DATE NOT NULL DEFAULT CURRENT_DATE,
  active_until DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- One active prescription per user — partial index enforces uniqueness on the
-- "active right now" row. New tier writes superscede by setting active_until on
-- the prior row before inserting.
CREATE UNIQUE INDEX IF NOT EXISTS idx_cardio_prescriptions_user_active_unique
  ON cardio_prescriptions(user_id)
  WHERE active_until IS NULL;

CREATE INDEX IF NOT EXISTS idx_cardio_prescriptions_user_history
  ON cardio_prescriptions(user_id, active_from DESC);

-- 3. cardio_completions — append-only log
CREATE TABLE IF NOT EXISTS cardio_completions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  completed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  week_starting DATE NOT NULL,
  prescription_id UUID REFERENCES cardio_prescriptions(id) ON DELETE SET NULL,
  duration_minutes INT,
  modality TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cardio_completions_user_week
  ON cardio_completions(user_id, week_starting DESC);

-- 4. RLS
ALTER TABLE cardio_prescriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE cardio_completions   ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own cardio prescriptions"
  ON cardio_prescriptions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "Users insert own cardio prescriptions"
  ON cardio_prescriptions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Users update own cardio prescriptions"
  ON cardio_prescriptions FOR UPDATE TO authenticated
  USING (auth.uid() = user_id);

CREATE POLICY "Users read own cardio completions"
  ON cardio_completions FOR SELECT TO authenticated
  USING (auth.uid() = user_id);
CREATE POLICY "Users insert own cardio completions"
  ON cardio_completions FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = user_id);

COMMIT;
