-- Phase 56: Coach Oversight Dashboard for Personal Clients
-- Adds: admin_users, coach_clients, coach_invites, coach_recommendations,
--       coach_audit_log, coach_notes tables + user_profiles.is_coach_managed
--       column + pending_coach_invite_{code,error} columns.
-- Idempotent: all DDL uses IF NOT EXISTS / ADD COLUMN IF NOT EXISTS.

CREATE TABLE IF NOT EXISTS admin_users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT NOT NULL,
  role TEXT NOT NULL DEFAULT 'admin' CHECK (role IN ('admin', 'super_admin')),
  display_name TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_login_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS coach_clients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  status TEXT NOT NULL CHECK (status IN ('active', 'paused', 'unlinked')),
  linked_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  unlinked_at TIMESTAMPTZ,
  unlink_grace_until TIMESTAMPTZ
);
CREATE UNIQUE INDEX IF NOT EXISTS coach_clients_client_active_unique
  ON coach_clients (client_id) WHERE status = 'active';
CREATE INDEX IF NOT EXISTS idx_coach_clients_coach ON coach_clients (coach_id, status);

CREATE TABLE IF NOT EXISTS coach_invites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE,
  coach_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  label TEXT,
  status TEXT NOT NULL CHECK (status IN ('pending', 'claimed', 'expired', 'revoked')),
  expires_at TIMESTAMPTZ NOT NULL,
  claimed_by_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  claimed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_coach_invites_code_status ON coach_invites (code, status);
CREATE INDEX IF NOT EXISTS idx_coach_invites_coach_status ON coach_invites (coach_id, status);

CREATE TABLE IF NOT EXISTS coach_recommendations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  coach_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,  -- attribution; nullable for orphans
  check_in_id UUID,
  domain TEXT NOT NULL CHECK (domain IN ('macros', 'training', 'recovery')),
  ai_proposed_json JSONB NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('pending', 'applied', 'edited', 'skipped', 'superseded')),
  coach_action_json JSONB,
  coach_note TEXT,
  applied_at TIMESTAMPTZ,
  superseded_at TIMESTAMPTZ,
  superseded_by UUID REFERENCES coach_recommendations(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_recs_client_pending ON coach_recommendations (client_id, status, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_recs_check_in ON coach_recommendations (check_in_id);

CREATE TABLE IF NOT EXISTS coach_audit_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID REFERENCES admin_users(id) ON DELETE SET NULL,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  action TEXT NOT NULL,
  before_json JSONB,
  after_json JSONB,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_audit_client_created ON coach_audit_log (client_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_audit_coach_created ON coach_audit_log (coach_id, created_at DESC);

CREATE TABLE IF NOT EXISTS coach_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  coach_id UUID NOT NULL REFERENCES admin_users(id) ON DELETE CASCADE,
  client_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  body_md TEXT NOT NULL,
  visible_to_client BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_notes_client ON coach_notes (client_id, created_at DESC);

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS is_coach_managed BOOLEAN NOT NULL DEFAULT FALSE;
CREATE INDEX IF NOT EXISTS idx_user_profiles_is_coach_managed
  ON user_profiles (is_coach_managed) WHERE is_coach_managed = TRUE;

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS pending_coach_invite_code TEXT;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS pending_coach_invite_error TEXT;
