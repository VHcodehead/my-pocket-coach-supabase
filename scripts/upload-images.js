// Upload recipe images to Supabase Storage
import { createClient } from '@supabase/supabase-js';
import { readFileSync, readdirSync } from 'fs';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import dotenv from 'dotenv';

// Load environment variables
dotenv.config();

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

// Initialize Supabase client with service role key
const supabase = createClient(
  process.env.SUPABASE_URL,
  process.env.SUPABASE_SERVICE_ROLE_KEY
);

const BUCKET_NAME = 'recipe-images';

async function createBucket() {
  console.log(`📦 Creating storage bucket: ${BUCKET_NAME}...`);

  const { data: buckets, error: listError } = await supabase.storage.listBuckets();

  if (listError) {
    console.error('❌ Error listing buckets:', listError.message);
    return false;
  }

  const bucketExists = buckets.some(b => b.name === BUCKET_NAME);

  if (bucketExists) {
    console.log('✅ Bucket already exists\n');
    return true;
  }

  const { error } = await supabase.storage.createBucket(BUCKET_NAME, {
    public: true,
    fileSizeLimit: 5242880 // 5MB limit
  });

  if (error) {
    console.error('❌ Error creating bucket:', error.message);
    return false;
  }

  console.log('✅ Bucket created successfully\n');
  return true;
}

async function uploadImages() {
  console.log('🖼️  Starting recipe image upload to Supabase Storage...\n');

  // Create bucket if it doesn't exist
  const bucketReady = await createBucket();
  if (!bucketReady) {
    console.error('❌ Failed to create/verify bucket. Exiting.');
    return;
  }

  // Read all images from my-coach-backend/public/images
  const imagesPath = join(__dirname, '../../my-coach-backend/public/images');
  console.log(`📂 Reading images from: ${imagesPath}\n`);

  const files = readdirSync(imagesPath).filter(f => f.endsWith('.JPG') || f.endsWith('.jpg'));
  console.log(`📦 Found ${files.length} image files\n`);

  let uploaded = 0;
  let skipped = 0;
  let errors = 0;

  for (const filename of files) {
    const filePath = join(imagesPath, filename);
    const fileBuffer = readFileSync(filePath);

    // Upload to Supabase Storage
    const { data, error } = await supabase.storage
      .from(BUCKET_NAME)
      .upload(filename, fileBuffer, {
        contentType: 'image/jpeg',
        upsert: false // Don't overwrite existing files
      });

    if (error) {
      if (error.message.includes('already exists')) {
        console.log(`⏭️  Skipped (already exists): ${filename}`);
        skipped++;
      } else {
        console.error(`❌ Error uploading ${filename}:`, error.message);
        errors++;
      }
    } else {
      console.log(`✅ Uploaded: ${filename}`);
      uploaded++;
    }
  }

  console.log('\n📊 Upload Summary:');
  console.log(`   ✅ Successfully uploaded: ${uploaded} images`);
  console.log(`   ⏭️  Skipped (already exist): ${skipped} images`);
  console.log(`   ❌ Failed: ${errors} images`);

  if (uploaded + skipped === files.length) {
    console.log('\n🎉 All images are now in Supabase Storage!');
    console.log(`\n🔗 Access images at: ${process.env.SUPABASE_URL}/storage/v1/object/public/${BUCKET_NAME}/<filename>\n`);
  }
}

uploadImages().catch(console.error);
