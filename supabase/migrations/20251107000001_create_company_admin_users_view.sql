-- View to expose auth users (id, email) to the public schema for admin listings
CREATE OR REPLACE VIEW company_admin_users_view AS
SELECT
  id,
  email
FROM auth.users;

GRANT SELECT ON company_admin_users_view TO authenticated;

