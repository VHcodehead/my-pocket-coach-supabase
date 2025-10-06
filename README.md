# My Pocket Coach - Supabase Setup

Supabase configuration for My Pocket Coach app - handles recipes, user authentication, and image storage.

## Architecture

- **Recipes**: PostgreSQL table with 76 high-protein recipes
- **User Profiles**: Extends Supabase Auth with custom user data
- **Storage**: Recipe images hosted in Supabase Storage CDN
- **Authentication**: OAuth (Google, Apple) + email/password

## Setup Instructions

### 1. Run Database Migrations

Go to your Supabase dashboard → SQL Editor and run these migrations in order:

1. `supabase/migrations/20250106_001_create_recipes.sql` - Creates recipes table
2. `supabase/migrations/20250106_002_create_user_profiles.sql` - Creates user profiles table

### 2. Install Dependencies

```bash
cd my-pocket-coach-supabase
npm install
```

### 3. Import Recipes Data

This will import all 76 recipes from the CSV into your Supabase database:

```bash
npm run import-recipes
```

### 4. Upload Recipe Images

This will upload all 76 recipe images to Supabase Storage:

```bash
npm run upload-images
```

The images will be accessible at:
```
https://tomoqkmbozuxpdqfrsrf.supabase.co/storage/v1/object/public/recipe-images/<filename>
```

### 5. Update Recipe Image URLs

After uploading images, you'll need to update the `image_url` column in the recipes table to point to Supabase Storage. Run this SQL in Supabase SQL Editor:

```sql
-- Update image URLs to point to Supabase Storage
UPDATE recipes
SET image_url = 'https://tomoqkmbozuxpdqfrsrf.supabase.co/storage/v1/object/public/recipe-images/' || slug || '.JPG'
WHERE image_url IS NULL OR image_url = '';
```

### 6. Enable Authentication Providers

In Supabase Dashboard → Authentication → Providers:

1. **Enable Google OAuth**:
   - Go to Google Cloud Console
   - Create OAuth 2.0 credentials
   - Add redirect URL: `https://tomoqkmbozuxpdqfrsrf.supabase.co/auth/v1/callback`
   - Copy Client ID and Secret to Supabase

2. **Enable Apple OAuth**:
   - Go to Apple Developer
   - Create Sign in with Apple service
   - Add redirect URL: `https://tomoqkmbozuxpdqfrsrf.supabase.co/auth/v1/callback`
   - Copy credentials to Supabase

## Environment Variables

The `.env` file contains:

```
SUPABASE_URL=https://tomoqkmbozuxpdqfrsrf.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
SUPABASE_SERVICE_ROLE_KEY=<your-service-role-key>
```

**⚠️ Security**: Never commit the service role key to GitHub. It's already in `.gitignore`.

## Database Schema

### `recipes` Table
- `id` - Primary key
- `title` - Recipe name
- `slug` - URL-friendly identifier
- `servings` - Number of servings
- `calories` - Calories per serving
- `protein_g` - Protein grams per serving
- `carbs_g` - Carbs grams per serving
- `fat_g` - Fat grams per serving
- `image_url` - URL to recipe image
- `source_pdf` - Source PDF filename
- `pages` - Page number in PDF

### `user_profiles` Table
- `id` - UUID (references auth.users)
- `email` - User email
- `full_name` - User's full name
- `avatar_url` - Profile picture URL
- `created_at` - Account creation timestamp
- `updated_at` - Last update timestamp

## Row Level Security (RLS)

- **Recipes**: Public read access, no write access
- **User Profiles**: Users can only read/write their own profile

## Next Steps

1. ✅ Run database migrations in Supabase SQL Editor
2. ✅ Run `npm run import-recipes`
3. ✅ Run `npm run upload-images`
4. ✅ Update recipe image URLs with SQL command above
5. ✅ Enable Google/Apple OAuth in Supabase dashboard
6. ⏳ Connect frontend app to Supabase using the anon key
