-- Add missing currency and number abbreviation translations
-- These translations were added to i18n.ts but were missing from the database

-- English translations
INSERT INTO translations (translation_key, language_code, translation_value, namespace)
VALUES
  ('employeeOverview.sar', 'en', 'SAR', 'translation'),
  ('employeeOverview.thousands', 'en', 'K', 'translation'),
  ('employeeOverview.millions', 'en', 'M', 'translation'),
  ('employeeOverview.billions', 'en', 'B', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO NOTHING;

-- Arabic translations
INSERT INTO translations (translation_key, language_code, translation_value, namespace)
VALUES
  ('employeeOverview.sar', 'ar', 'ريال سعودي', 'translation'),
  ('employeeOverview.thousands', 'ar', 'ألف', 'translation'),
  ('employeeOverview.millions', 'ar', 'مليون', 'translation'),
  ('employeeOverview.billions', 'ar', 'مليار', 'translation')
ON CONFLICT (translation_key, language_code, namespace) 
DO NOTHING;

