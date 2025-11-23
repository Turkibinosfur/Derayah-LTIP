-- Add brand_color column to companies table
-- This allows each company to customize their primary brand color throughout the portal

ALTER TABLE companies 
ADD COLUMN IF NOT EXISTS brand_color text DEFAULT '#2563EB';

-- Add comment
COMMENT ON COLUMN companies.brand_color IS 'Primary brand color for the company (hex format, e.g., #2563EB). Used for UI theming throughout the portal.';

-- Update existing companies to have the default blue color if they don't have one
UPDATE companies 
SET brand_color = '#2563EB' 
WHERE brand_color IS NULL;

