import { useTranslation } from 'react-i18next';
import { Globe } from 'lucide-react';
import { useState, useEffect } from 'react';

export default function LanguageSwitcher() {
  const { i18n, t } = useTranslation();
  const [isOpen, setIsOpen] = useState(false);

  const currentLang = i18n.language;
  const isRTL = currentLang === 'ar';

  useEffect(() => {
    // Update document direction when language changes
    if (typeof document !== 'undefined') {
      document.documentElement.dir = isRTL ? 'rtl' : 'ltr';
      document.documentElement.lang = currentLang;
    }
  }, [currentLang, isRTL]);

  const toggleLanguage = () => {
    const newLang = currentLang === 'en' ? 'ar' : 'en';
    i18n.changeLanguage(newLang);
    setIsOpen(false);
  };

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className={`flex items-center space-x-1 sm:space-x-2 px-2 sm:px-3 py-2 rounded-lg hover:bg-gray-100 active:bg-gray-100 transition-colors touch-manipulation ${
          isRTL ? 'space-x-reverse' : ''
        }`}
        aria-label={t('language.switch')}
      >
        <Globe className="w-4 h-4 sm:w-5 sm:h-5 text-gray-600 flex-shrink-0" />
        <span className="text-xs sm:text-sm font-medium text-gray-700 whitespace-nowrap">
          {currentLang === 'en' ? 'EN' : 'AR'}
        </span>
      </button>

      {isOpen && (
        <>
          <div
            className="fixed inset-0 z-[100]"
            onClick={() => setIsOpen(false)}
          />
          <div
            className={`absolute ${
              isRTL ? 'left-0' : 'right-0'
            } mt-2 w-40 bg-white rounded-lg shadow-lg border border-gray-200 z-[101]`}
          >
            <button
              onClick={toggleLanguage}
              className={`w-full px-4 py-2 hover:bg-gray-50 active:bg-gray-100 transition-colors flex items-center justify-between touch-manipulation ${
                isRTL ? 'text-right' : 'text-left'
              }`}
            >
              <span className="text-sm font-medium text-gray-700">
                {currentLang === 'en' ? t('language.arabic') : t('language.english')}
              </span>
              {currentLang === 'en' ? (
                <span className="text-lg">🇸🇦</span>
              ) : (
                <span className="text-lg">🇬🇧</span>
              )}
            </button>
          </div>
        </>
      )}
    </div>
  );
}

