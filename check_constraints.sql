-- Check Constraints on company_users table
-- Run this to verify the unique constraint exists

SELECT 
  '=== COMPANY_USERS CONSTRAINTS ===' as info;

SELECT 
  conname as constraint_name,
  contype as constraint_type,
  pg_get_constraintdef(oid) as constraint_definition
FROM pg_constraint 
WHERE conrelid = 'company_users'::regclass
AND contype = 'u'; -- unique constraints

-- Check if the table exists and has the expected structure
SELECT 
  '=== TABLE STRUCTURE ===' as info;

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'company_users'
ORDER BY ordinal_position;
