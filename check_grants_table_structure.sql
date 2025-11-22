-- Check the actual structure of the grants table
-- Run this in Supabase SQL Editor to see what columns exist

SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default,
  character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'grants' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Also check for any constraints
SELECT 
  constraint_name,
  constraint_type,
  column_name
FROM information_schema.constraint_column_usage ccu
JOIN information_schema.table_constraints tc ON ccu.constraint_name = tc.constraint_name
WHERE ccu.table_name = 'grants' 
  AND tc.table_schema = 'public'
ORDER BY constraint_type, constraint_name;
