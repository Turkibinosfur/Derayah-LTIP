/*
  Enable Employee Portal Access
  
  This migration simply enables portal access for employees without
  trying to access the auth schema.
*/

-- Enable portal access for all employees in Derayah
UPDATE employees
SET portal_access_enabled = true,
    portal_username = COALESCE(portal_username, LOWER(REPLACE(first_name_en, ' ', '.')) || '.' || LOWER(REPLACE(last_name_en, ' ', '.'))),
    portal_password = COALESCE(portal_password, 'TempPass123!')
WHERE company_id = (
  SELECT id FROM companies WHERE company_name_en = 'Derayah Financial'
)
AND portal_access_enabled IS NULL;

-- Show which employees now have portal access
DO $$
DECLARE
  rec RECORD;
BEGIN
  RAISE NOTICE 'Employees with portal access:';
  FOR rec IN 
    SELECT id, first_name_en, last_name_en, email, portal_username, portal_access_enabled
    FROM employees 
    WHERE company_id = (SELECT id FROM companies WHERE company_name_en = 'Derayah Financial')
    AND portal_access_enabled = true
  LOOP
    RAISE NOTICE 'ID: %, Name: % %, Email: %, Username: %', 
      rec.id, rec.first_name_en, rec.last_name_en, rec.email, rec.portal_username;
  END LOOP;
END;
$$;
