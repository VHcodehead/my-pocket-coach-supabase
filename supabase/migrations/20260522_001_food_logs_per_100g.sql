-- Phase 8.5 — Add per-100g nutrient rates + source provenance to food_logs.
-- See MyPocketCoach-Brain/11-Roadmap/phase-8-5-food-log-per-100g.md for context.
--
-- Why:
--   Edit-mode FoodDetailModal previously had to store the resulting macros
--   per row with no way to recompute when the user changes serving size.
--   Storing per-100g rates as first-class data makes Edit symmetric with
--   Log mode (both compute macros = per_100g * grams / 100) and unlocks
--   downstream coach analytics ("avg protein density per 100g of foods
--   this user eats").
--
-- Source enum lets analytics attribute provenance (barcode vs USDA vs
-- manual entry) without re-routing the edit flow through original lookup
-- screens, which would break for manual entries and mutate history when
-- third-party DBs update.

BEGIN;

-- 1. Add per-100g columns. Nullable so legacy rows survive — Edit mode
-- falls back to snapshot-scale (Approach A) when these are NULL.
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS kcal_per_100g    DECIMAL(8,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS protein_per_100g DECIMAL(8,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS carbs_per_100g   DECIMAL(8,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS fat_per_100g     DECIMAL(8,2);
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS fiber_per_100g   DECIMAL(8,2);

-- 2. Source provenance. NULL for legacy rows where we can't infer.
-- 'manual' is the user-typed path; 'custom' is user-submitted catalog;
-- 'mealplan' is rows logged from an active generated meal plan.
ALTER TABLE food_logs ADD COLUMN IF NOT EXISTS source TEXT
  CHECK (source IS NULL OR source IN (
    'barcode', 'usda', 'edamam', 'fastfood', 'custom', 'manual', 'mealplan', 'ai_vision'
  ));

-- 3. Backfill per-100g for existing rows where we can.
-- serving_unit 'g'  → grams = serving_size
-- serving_unit 'oz' → grams = serving_size * 28.3495
-- serving_unit 'serving' → unknown grams → leave per-100g NULL
--                          (Edit falls back to snapshot-scale for these)
UPDATE food_logs SET
  kcal_per_100g    = ROUND( (calories::numeric * 100.0) / NULLIF(serving_size, 0),                  2),
  protein_per_100g = ROUND( (protein                * 100.0) / NULLIF(serving_size, 0),             2),
  carbs_per_100g   = ROUND( (carbs                  * 100.0) / NULLIF(serving_size, 0),             2),
  fat_per_100g     = ROUND( (fat                    * 100.0) / NULLIF(serving_size, 0),             2)
WHERE kcal_per_100g IS NULL
  AND serving_unit = 'g'
  AND serving_size > 0;

UPDATE food_logs SET
  kcal_per_100g    = ROUND( (calories::numeric * 100.0) / NULLIF(serving_size * 28.3495, 0),  2),
  protein_per_100g = ROUND( (protein                * 100.0) / NULLIF(serving_size * 28.3495, 0),  2),
  carbs_per_100g   = ROUND( (carbs                  * 100.0) / NULLIF(serving_size * 28.3495, 0),  2),
  fat_per_100g     = ROUND( (fat                    * 100.0) / NULLIF(serving_size * 28.3495, 0),  2)
WHERE kcal_per_100g IS NULL
  AND serving_unit = 'oz'
  AND serving_size > 0;

-- 4. Helpful index for source-based analytics (e.g. coach dashboard
-- "what % of this client's foods are scanned vs manual").
CREATE INDEX IF NOT EXISTS idx_food_logs_user_source
  ON food_logs(user_id, source)
  WHERE source IS NOT NULL;

COMMIT;
