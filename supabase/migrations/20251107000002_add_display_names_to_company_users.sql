-- Add display name columns for company users
ALTER TABLE company_users
  ADD COLUMN IF NOT EXISTS display_name_en text,
  ADD COLUMN IF NOT EXISTS display_name_ar text;

