-- Add manual FMV support and tracking for companies
ALTER TABLE companies
  ADD COLUMN IF NOT EXISTS current_fmv numeric(15,4),
  ADD COLUMN IF NOT EXISTS fmv_source text CHECK (fmv_source IN ('manual', 'tadawul')) DEFAULT 'tadawul';

COMMENT ON COLUMN companies.current_fmv IS 'Latest fair market value recorded for the company''s shares';
COMMENT ON COLUMN companies.fmv_source IS 'Indicates whether the FMV is manually set or pulled from Tadawul';

