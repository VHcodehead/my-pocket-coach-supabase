// Import recipes from CSV to Supabase
import { createClient } from '@supabase/supabase-js';
import { parse } from 'csv-parse/sync';
import { readFileSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Supabase client with service role key (bypasses RLS)
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

async function importRecipes() {
  console.log('🍳 Starting recipe import to Supabase...\n');

  // Read CSV file
  const csvPath = join(__dirname, '../../my-coach-backend/csv/recipes_dashboard_with_pages_FIXED.csv');
  console.log(`📄 Reading CSV from: ${csvPath}`);

  const csvContent = readFileSync(csvPath, 'utf-8');
  const records = parse(csvContent, {
    columns: true,
    skip_empty_lines: true,
    trim: true
  });

  console.log(`📦 Found ${records.length} recipes in CSV\n`);

  // Transform records for Supabase
  const recipes = records.map(record => ({
    title: record.title,
    slug: record.slug,
    servings: parseInt(record.servings),
    calories: parseInt(record.calories),
    protein_g: parseFloat(record.protein_g),
    carbs_g: parseFloat(record.carbs_g),
    fat_g: parseFloat(record.fat_g),
    image_url: record.image_url || null,
    source_pdf: record.source_pdf || null,
    pages: record.pages ? parseFloat(record.pages) : null
  }));

  // Insert recipes in batches of 10
  const batchSize = 10;
  let imported = 0;
  let errors = 0;

  for (let i = 0; i < recipes.length; i += batchSize) {
    const batch = recipes.slice(i, i + batchSize);

    const { data, error } = await supabase
      .from('recipes')
      .insert(batch)
      .select();

    if (error) {
      console.error(`❌ Error importing batch ${i / batchSize + 1}:`, error.message);
      errors += batch.length;
    } else {
      imported += data.length;
      console.log(`✅ Imported batch ${i / batchSize + 1}: ${data.length} recipes`);
    }
  }

  console.log('\n📊 Import Summary:');
  console.log(`   ✅ Successfully imported: ${imported} recipes`);
  console.log(`   ❌ Failed: ${errors} recipes`);

  if (imported === recipes.length) {
    console.log('\n🎉 All recipes imported successfully!\n');
  }
}

importRecipes().catch(console.error);
