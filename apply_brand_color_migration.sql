-- =====================================================
-- Apply Brand Color Feature Migrations
-- =====================================================
-- Run this SQL in your Supabase SQL Editor
-- This combines both migrations needed for the brand color feature
-- =====================================================

-- Step 1: Add brand_color column to companies table
-- =====================================================
ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS brand_color text DEFAULT '#2563EB';

-- Add comment
COMMENT ON COLUMN companies.brand_color IS 'Primary brand color for the company (hex format, e.g., #2563EB). Used for UI theming throughout the portal.';

-- Update existing companies to have the default blue color if they don't have one
UPDATE companies 
SET brand_color = '#2563EB' 
WHERE brand_color IS NULL;

-- =====================================================
-- Step 2: Fix companies UPDATE policy to allow all admin roles
-- =====================================================
DROP POLICY IF EXISTS "Company admins can update own company" ON companies;

CREATE POLICY "Company admins can update own company"
  ON companies FOR UPDATE TO authenticated
  USING (
    id IN (
      SELECT company_id FROM company_users
      WHERE user_id = auth.uid() 
      AND is_active = true
      AND role IN ('super_admin', 'finance_admin', 'hr_admin', 'legal_admin', 'company_admin')
    )
  );

-- =====================================================
-- Verification
-- =====================================================
-- Verify the column was added
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'companies' 
    AND column_name = 'brand_color'
  ) THEN
    RAISE NOTICE '✅ brand_color column added successfully';
  ELSE
    RAISE EXCEPTION '❌ brand_color column was not added';
  END IF;
END $$;

-- Show current companies with their brand colors
SELECT 
  id,
  company_name_en,
  brand_color,
  updated_at
FROM companies
ORDER BY company_name_en;

-- Final verification message
DO $$
BEGIN
  RAISE NOTICE '✅ Migrations applied successfully!';
  RAISE NOTICE 'You can now use the brand color feature in Settings.';
END $$;

