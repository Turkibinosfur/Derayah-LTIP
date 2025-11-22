import i18n from 'i18next';
import { initReactI18next } from 'react-i18next';
import LanguageDetector from 'i18next-browser-languagedetector';
import { supabase } from './supabase';

// Default translations (fallback)
const defaultTranslations = {
  en: {
    translation: {
      'common.dashboard': 'Dashboard',
      'common.employees': 'Employees',
      'common.plans': 'Plans',
      'common.grants': 'Grants',
      'common.portfolio': 'Portfolio',
      'common.settings': 'Settings',
      'common.users': 'Users',
      'common.capTable': 'Cap Table',
      'common.ltipPools': 'LTIP Pools',
      'common.vestingSchedules': 'Vesting Schedules',
      'common.vestingEvents': 'Vesting Events',
      'common.transfers': 'Transfers',
      'common.performanceMetrics': 'Performance Metrics',
      'common.documents': 'Documents',
      'common.logout': 'Logout',
      'common.login': 'Login',
      'common.save': 'Save',
      'common.cancel': 'Cancel',
      'common.delete': 'Delete',
      'common.edit': 'Edit',
      'common.create': 'Create',
      'common.search': 'Search',
      'common.loading': 'Loading...',
      'common.noData': 'No data available',
      'common.translations': 'Translations',
      'common.operatorConsole': 'Operator Console',
      'common.overview': 'Overview',
      'common.incentivePlans': 'Incentive Plans',
    },
  },
  ar: {
    translation: {
      'common.dashboard': 'لوحة التحكم',
      'common.employees': 'الموظفون',
      'common.plans': 'الخطط',
      'common.grants': 'المنح',
      'common.portfolio': 'المحفظة',
      'common.settings': 'الإعدادات',
      'common.users': 'المستخدمون',
      'common.capTable': 'جدول رأس المال',
      'common.ltipPools': 'مجمعات LTIP',
      'common.vestingSchedules': 'جداول الاستحقاق',
      'common.vestingEvents': 'أحداث الاستحقاق',
      'common.transfers': 'التحويلات',
      'common.performanceMetrics': 'مقاييس الأداء',
      'common.documents': 'المستندات',
      'common.logout': 'تسجيل الخروج',
      'common.login': 'تسجيل الدخول',
      'common.save': 'حفظ',
      'common.cancel': 'إلغاء',
      'common.delete': 'حذف',
      'common.edit': 'تعديل',
      'common.create': 'إنشاء',
      'common.search': 'بحث',
      'common.loading': 'جاري التحميل...',
      'common.noData': 'لا توجد بيانات متاحة',
      'common.translations': 'الترجمات',
      'common.operatorConsole': 'لوحة المشغل',
      'common.overview': 'نظرة عامة',
      'common.incentivePlans': 'خطط الحوافز',
    },
  },
};

// Load translations from database
async function loadTranslationsFromDB(language: string) {
  try {
    const { data, error } = await supabase
      .from('translations')
      .select('translation_key, translation_value')
      .eq('language_code', language)
      .eq('namespace', 'translation');

    if (error) {
      console.error('Error loading translations:', error);
      return {};
    }

    const translations: Record<string, string> = {};
    data?.forEach((item) => {
      translations[item.translation_key] = item.translation_value;
    });

    return translations;
  } catch (error) {
    console.error('Error loading translations from DB:', error);
    return {};
  }
}

// Initialize i18n
i18n
  .use(LanguageDetector)
  .use(initReactI18next)
  .init({
    resources: defaultTranslations,
    fallbackLng: 'en',
    supportedLngs: ['en', 'ar'],
    defaultNS: 'translation',
    interpolation: {
      escapeValue: false,
    },
    detection: {
      order: ['localStorage', 'navigator'],
      caches: ['localStorage'],
      lookupLocalStorage: 'i18nextLng',
    },
  });

// Load translations from database after initialization
// Use a more robust loading approach that ensures translations are available
(async () => {
  try {
    const currentLang = i18n.language || 'en';
    const translations = await loadTranslationsFromDB(currentLang);
    if (Object.keys(translations).length > 0) {
      i18n.addResourceBundle(currentLang, 'translation', translations, true, true);
      // Force a reload to ensure all components pick up the translations
      i18n.reloadResources(currentLang);
      console.log(`✓ Loaded ${Object.keys(translations).length} translations for ${currentLang}`);
    } else {
      console.warn(`⚠ No translations found in database for ${currentLang}`);
    }
  } catch (error) {
    console.error('Error loading initial translations:', error);
  }
})();

// Listen for language changes and reload translations
i18n.on('languageChanged', async (lng) => {
  try {
    const translations = await loadTranslationsFromDB(lng);
    if (Object.keys(translations).length > 0) {
      i18n.addResourceBundle(lng, 'translation', translations, true, true);
      // Force a reload to ensure all components pick up the translations
      i18n.reloadResources(lng);
      console.log(`✓ Loaded ${Object.keys(translations).length} translations for ${lng}`);
    } else {
      console.warn(`⚠ No translations found in database for ${lng}`);
    }
    
    // Update document direction for RTL
    if (typeof document !== 'undefined') {
      document.documentElement.dir = lng === 'ar' ? 'rtl' : 'ltr';
      document.documentElement.lang = lng;
    }
  } catch (error) {
    console.error('Error loading translations on language change:', error);
  }
});

// Set initial direction
if (typeof window !== 'undefined') {
  document.documentElement.dir = i18n.language === 'ar' ? 'rtl' : 'ltr';
  document.documentElement.lang = i18n.language;
}

// Export function to reload translations
export async function reloadTranslations(language?: string) {
  try {
    const lng = language || i18n.language;
    const translations = await loadTranslationsFromDB(lng);
    if (Object.keys(translations).length > 0) {
      i18n.addResourceBundle(lng, 'translation', translations, true, true);
      i18n.reloadResources(lng);
      console.log(`✓ Reloaded ${Object.keys(translations).length} translations for ${lng}`);
      return true;
    } else {
      console.warn(`⚠ No translations found in database for ${lng}`);
      return false;
    }
  } catch (error) {
    console.error('Error reloading translations:', error);
    return false;
  }
}

export default i18n;

