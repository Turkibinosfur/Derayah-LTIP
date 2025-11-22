-- Create translations table to store all translation keys and values
CREATE TABLE IF NOT EXISTS translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  translation_key TEXT NOT NULL,
  language_code TEXT NOT NULL CHECK (language_code IN ('en', 'ar')),
  translation_value TEXT NOT NULL,
  namespace TEXT DEFAULT 'translation',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(translation_key, language_code, namespace)
);

-- Create index for faster lookups
CREATE INDEX IF NOT EXISTS idx_translations_key_lang ON translations(translation_key, language_code, namespace);

-- Enable RLS
ALTER TABLE translations ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to allow re-running the migration)
DROP POLICY IF EXISTS "Translations are viewable by everyone" ON translations;
DROP POLICY IF EXISTS "Only super_admin can manage translations" ON translations;

-- Policy: Everyone can read translations
CREATE POLICY "Translations are viewable by everyone"
  ON translations FOR SELECT
  USING (true);

-- Policy: Only super_admin can insert/update/delete translations
CREATE POLICY "Only super_admin can manage translations"
  ON translations FOR ALL
  USING (
    EXISTS (
      SELECT 1 FROM company_users cu
      WHERE cu.user_id = auth.uid()
      AND cu.role = 'super_admin'
      AND cu.company_id IS NULL
    )
  );

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_translations_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
DROP TRIGGER IF EXISTS update_translations_updated_at ON translations;
CREATE TRIGGER update_translations_updated_at
  BEFORE UPDATE ON translations
  FOR EACH ROW
  EXECUTE FUNCTION update_translations_updated_at();

-- Insert default English and Arabic translations (only if they don't exist)
-- This uses INSERT ... ON CONFLICT DO NOTHING to avoid duplicates
INSERT INTO translations (translation_key, language_code, translation_value, namespace) 
VALUES
('common.dashboard', 'en', 'Dashboard', 'translation'),
('common.dashboard', 'ar', 'لوحة التحكم', 'translation'),
('dashboard.title', 'en', 'Dashboard Overview', 'translation'),
('dashboard.title', 'ar', 'نظرة عامة على لوحة التحكم', 'translation')
ON CONFLICT (translation_key, language_code, namespace) DO NOTHING;
