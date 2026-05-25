-- 20260525_003_add_training_time.sql
-- Adds the forgotten user_profiles.training_time column. Backend whitelists this
-- field at authRoutes.ts:631 and reads it in foodPreferenceLearner.ts + V3 meal
-- plan generation, but the column was never created — first production signups
-- post-launch hit "Could not find the 'training_time' column" on PUT /auth/profile.
--
-- Matches the pattern of cuisine_preferences + prep_complexity (added in
-- 20260313_001_v9_milestone_consolidated.sql).

ALTER TABLE user_profiles
  ADD COLUMN IF NOT EXISTS training_time TEXT DEFAULT 'morning';

DO $$ BEGIN
  ALTER TABLE user_profiles ADD CONSTRAINT user_profiles_training_time_check
    CHECK (training_time IN ('morning', 'midday', 'evening'));
EXCEPTION WHEN duplicate_object THEN NULL;
END $$;
