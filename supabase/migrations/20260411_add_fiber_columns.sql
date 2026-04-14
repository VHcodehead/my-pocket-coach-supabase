-- Add fiber column to food_logs (nullable, defaults 0 for existing rows)
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS fiber REAL DEFAULT 0;

-- Add target_fiber to user_profiles (nullable, computed from sex on read)
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS target_fiber REAL;
