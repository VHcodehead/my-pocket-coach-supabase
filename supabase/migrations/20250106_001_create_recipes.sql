-- Create recipes table
CREATE TABLE recipes (
  id BIGSERIAL PRIMARY KEY,
  title TEXT NOT NULL,
  slug TEXT UNIQUE NOT NULL,
  servings INTEGER NOT NULL,
  calories INTEGER NOT NULL,
  protein_g DECIMAL(5,1) NOT NULL,
  carbs_g DECIMAL(5,1) NOT NULL,
  fat_g DECIMAL(5,1) NOT NULL,
  image_url TEXT,
  source_pdf TEXT,
  pages DECIMAL(5,1),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Create index on slug for fast lookups
CREATE INDEX idx_recipes_slug ON recipes(slug);

-- Enable Row Level Security (RLS)
ALTER TABLE recipes ENABLE ROW LEVEL SECURITY;

-- Create policy to allow public read access
CREATE POLICY "Allow public read access to recipes"
ON recipes FOR SELECT
TO public
USING (true);
