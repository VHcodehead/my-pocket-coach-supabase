-- Add onboarding state tracking columns to user_profiles
-- Enables resumable onboarding: frontend sends onboarding_step with each profile update,
-- GET /auth/profile returns it so app can resume from the correct step on relaunch.

ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS onboarding_step INTEGER DEFAULT 0;
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS onboarding_completed BOOLEAN DEFAULT false;
