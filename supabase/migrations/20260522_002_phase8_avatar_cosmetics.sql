-- Phase 8 — XP cosmetics: 20 avatar items (4 chars × 5 power-up tiers) +
-- user_profiles.equipped_avatar column. Mirrors the existing equipped_frame
-- + equipped_title pattern from 20260312_gamification_economy.sql.
--
-- See MyPocketCoach-Brain/11-Roadmap/phase-8-xp-cosmetics.md for the
-- character × tier matrix, price ladder rationale, and Pro+ gating policy.
-- All purchases are XP-spend at the route layer; required_level is enforced
-- client-side via the catalog `preview_data.required_level` field since the
-- xp_store_items table has no required_level column today.

BEGIN;

-- 1. Add equipped_avatar to user_profiles. Mirrors equipped_frame/title.
ALTER TABLE user_profiles ADD COLUMN IF NOT EXISTS equipped_avatar TEXT; -- key from xp_store_items

-- 2. Seed 20 avatar items. Price ladder: 500 / 2500 / 7500 / 15000 / 30000
-- per tier — assumes ~50-150 XP/day for active users, so diamond is a
-- ~5-6 month grind. Tune later if the economy feels off.
--
-- preview_data carries:
--   - tier:      'bronze' | 'silver' | 'gold' | 'platinum' | 'diamond'
--   - character: 'striker' | 'titan' | 'phoenix' | 'sentinel'
--   - required_level: 1 / 20 / 40 / 60 / 80 — surfaced as a level-gate chip
--     in the client even though the buy endpoint doesn't enforce it.
INSERT INTO xp_store_items (key, name, description, category, price, icon, preview_data, rarity, max_quantity, sort_order, is_active)
VALUES
  -- STRIKER (lean fighter)
  ('avatar_striker_bronze',   'Striker — Awakening',    'A determined fighter taking their first steps.',  'avatar',   500, 'avatar', '{"tier":"bronze",  "character":"striker",  "required_level":1}'::jsonb,  'common',    1, 10, true),
  ('avatar_striker_silver',   'Striker — Disciplined',  'Disciplined and visibly gaining ground.',         'avatar',  2500, 'avatar', '{"tier":"silver",  "character":"striker",  "required_level":20}'::jsonb, 'rare',      1, 11, true),
  ('avatar_striker_gold',     'Striker — Forged',       'Forged through repetition — no wasted motion.',   'avatar',  7500, 'avatar', '{"tier":"gold",    "character":"striker",  "required_level":40}'::jsonb, 'epic',      1, 12, true),
  ('avatar_striker_platinum', 'Striker — Ascended',     'Ascended beyond human limits.',                   'avatar', 15000, 'avatar', '{"tier":"platinum","character":"striker",  "required_level":60}'::jsonb, 'legendary', 1, 13, true),
  ('avatar_striker_diamond',  'Striker — Transcended',  'Transcended. Pure motion, pure intent.',          'avatar', 30000, 'avatar', '{"tier":"diamond", "character":"striker",  "required_level":80}'::jsonb, 'legendary', 1, 14, true),

  -- TITAN (mass-monster)
  ('avatar_titan_bronze',   'Titan — Awakening',    'A heavy frame learning to move with intent.', 'avatar',   500, 'avatar', '{"tier":"bronze",  "character":"titan",    "required_level":1}'::jsonb,  'common',    1, 20, true),
  ('avatar_titan_silver',   'Titan — Disciplined',  'Mass with control. Strength with restraint.', 'avatar',  2500, 'avatar', '{"tier":"silver",  "character":"titan",    "required_level":20}'::jsonb, 'rare',      1, 21, true),
  ('avatar_titan_gold',     'Titan — Forged',       'Built to last. Built to win.',                'avatar',  7500, 'avatar', '{"tier":"gold",    "character":"titan",    "required_level":40}'::jsonb, 'epic',      1, 22, true),
  ('avatar_titan_platinum', 'Titan — Ascended',     'A walking earthquake.',                       'avatar', 15000, 'avatar', '{"tier":"platinum","character":"titan",    "required_level":60}'::jsonb, 'legendary', 1, 23, true),
  ('avatar_titan_diamond',  'Titan — Transcended',  'Mythic. The mountain learned to fight.',      'avatar', 30000, 'avatar', '{"tier":"diamond", "character":"titan",    "required_level":80}'::jsonb, 'legendary', 1, 24, true),

  -- PHOENIX (agile / flame)
  ('avatar_phoenix_bronze',   'Phoenix — Awakening',    'The first spark.',              'avatar',   500, 'avatar', '{"tier":"bronze",  "character":"phoenix",  "required_level":1}'::jsonb,  'common',    1, 30, true),
  ('avatar_phoenix_silver',   'Phoenix — Disciplined',  'Burning steady.',               'avatar',  2500, 'avatar', '{"tier":"silver",  "character":"phoenix",  "required_level":20}'::jsonb, 'rare',      1, 31, true),
  ('avatar_phoenix_gold',     'Phoenix — Forged',       'A flame that won''t go out.',   'avatar',  7500, 'avatar', '{"tier":"gold",    "character":"phoenix",  "required_level":40}'::jsonb, 'epic',      1, 32, true),
  ('avatar_phoenix_platinum', 'Phoenix — Ascended',     'Reborn in fire.',               'avatar', 15000, 'avatar', '{"tier":"platinum","character":"phoenix",  "required_level":60}'::jsonb, 'legendary', 1, 33, true),
  ('avatar_phoenix_diamond',  'Phoenix — Transcended',  'The sun has a rival.',          'avatar', 30000, 'avatar', '{"tier":"diamond", "character":"phoenix",  "required_level":80}'::jsonb, 'legendary', 1, 34, true),

  -- SENTINEL (grounded / disciplined)
  ('avatar_sentinel_bronze',   'Sentinel — Awakening',   'Watching, learning, beginning.',                  'avatar',   500, 'avatar', '{"tier":"bronze",  "character":"sentinel", "required_level":1}'::jsonb,  'common',    1, 40, true),
  ('avatar_sentinel_silver',   'Sentinel — Disciplined', 'Calm under load.',                                'avatar',  2500, 'avatar', '{"tier":"silver",  "character":"sentinel", "required_level":20}'::jsonb, 'rare',      1, 41, true),
  ('avatar_sentinel_gold',     'Sentinel — Forged',      'Steady. Immovable. Aware.',                       'avatar',  7500, 'avatar', '{"tier":"gold",    "character":"sentinel", "required_level":40}'::jsonb, 'epic',      1, 42, true),
  ('avatar_sentinel_platinum', 'Sentinel — Ascended',    'The wall the world breaks against.',              'avatar', 15000, 'avatar', '{"tier":"platinum","character":"sentinel", "required_level":60}'::jsonb, 'legendary', 1, 43, true),
  ('avatar_sentinel_diamond',  'Sentinel — Transcended', 'Beyond defense. Beyond attack. Beyond.',          'avatar', 30000, 'avatar', '{"tier":"diamond", "character":"sentinel", "required_level":80}'::jsonb, 'legendary', 1, 44, true)
ON CONFLICT (key) DO NOTHING;

-- 3. Helpful index for the catalog filter-by-category query.
CREATE INDEX IF NOT EXISTS idx_xp_store_items_category_active
  ON xp_store_items(category, is_active);

COMMIT;
