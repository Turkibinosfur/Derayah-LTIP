-- Check company_users table constraints
-- This will show exactly what constraints exist

-- 1. Check table structure
SELECT 
  '=== TABLE STRUCTURE ===' as info,
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns 
WHERE table_name = 'company_users' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. Check constraints
SELECT 
  '=== CONSTRAINTS ===' as info,
  constraint_name,
  constraint_type,
  table_name
FROM information_schema.table_constraints 
WHERE table_name = 'company_users' 
  AND table_schema = 'public';

-- 3. Check unique constraints specifically
SELECT 
  '=== UNIQUE CONSTRAINTS ===' as info,
  tc.constraint_name,
  kcu.column_name,
  tc.constraint_type
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu 
  ON tc.constraint_name = kcu.constraint_name
WHERE tc.table_name = 'company_users' 
  AND tc.table_schema = 'public'
  AND tc.constraint_type IN ('UNIQUE', 'PRIMARY KEY');

-- 4. Check indexes
SELECT 
  '=== INDEXES ===' as info,
  indexname,
  indexdef
FROM pg_indexes 
WHERE tablename = 'company_users' 
  AND schemaname = 'public';

-- 5. Check if there are any existing records
SELECT 
  '=== EXISTING RECORDS ===' as info,
  COUNT(*) as total_records,
  COUNT(DISTINCT user_id) as unique_users,
  COUNT(DISTINCT company_id) as unique_companies
FROM company_users;
