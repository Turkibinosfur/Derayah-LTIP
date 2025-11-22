import { useState, useEffect } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { Save, Search, Globe, AlertCircle, CheckCircle } from 'lucide-react';
import { reloadTranslations } from '../lib/i18n';

interface Translation {
  id: string;
  translation_key: string;
  language_code: 'en' | 'ar';
  translation_value: string;
  namespace: string;
}

export default function Translations() {
  const { t, i18n } = useTranslation();
  const { isSuperAdmin } = useAuth();
  const [translations, setTranslations] = useState<Translation[]>([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [languageFilter, setLanguageFilter] = useState<'all' | 'en' | 'ar'>('all');
  const [editingKey, setEditingKey] = useState<string | null>(null);
  const [editValues, setEditValues] = useState<{ en: string; ar: string }>({ en: '', ar: '' });
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null);
  const isRTL = i18n.language === 'ar';

  useEffect(() => {
    if (!isSuperAdmin()) {
      return;
    }
    loadTranslations();
  }, [isSuperAdmin]);

  const loadTranslations = async () => {
    try {
      setLoading(true);
      const { data, error } = await supabase
        .from('translations')
        .select('*')
        .order('translation_key', { ascending: true });

      if (error) throw error;

      setTranslations(data || []);
    } catch (error) {
      console.error('Error loading translations:', error);
      setMessage({ type: 'error', text: t('translations.error') });
    } finally {
      setLoading(false);
    }
  };

  const groupedTranslations = translations.reduce((acc, trans) => {
    if (!acc[trans.translation_key]) {
      acc[trans.translation_key] = { en: '', ar: '' };
    }
    acc[trans.translation_key][trans.language_code] = trans.translation_value;
    return acc;
  }, {} as Record<string, { en: string; ar: string }>);

  const filteredKeys = Object.keys(groupedTranslations).filter((key) => {
    const matchesSearch = key.toLowerCase().includes(searchTerm.toLowerCase()) ||
      groupedTranslations[key].en.toLowerCase().includes(searchTerm.toLowerCase()) ||
      groupedTranslations[key].ar.includes(searchTerm);
    
    if (languageFilter === 'all') return matchesSearch;
    if (languageFilter === 'en') {
      return matchesSearch && groupedTranslations[key].en.toLowerCase().includes(searchTerm.toLowerCase());
    }
    return matchesSearch && groupedTranslations[key].ar.includes(searchTerm);
  });

  const startEdit = (key: string) => {
    setEditingKey(key);
    setEditValues({
      en: groupedTranslations[key].en || '',
      ar: groupedTranslations[key].ar || '',
    });
  };

  const cancelEdit = () => {
    setEditingKey(null);
    setEditValues({ en: '', ar: '' });
  };

  const saveTranslation = async (key: string) => {
    try {
      setSaving(true);
      setMessage(null);

      // Update or insert English translation
      const { error: enError } = await supabase
        .from('translations')
        .upsert({
          translation_key: key,
          language_code: 'en',
          translation_value: editValues.en,
          namespace: 'translation',
        }, {
          onConflict: 'translation_key,language_code,namespace',
        });

      if (enError) throw enError;

      // Update or insert Arabic translation
      const { error: arError } = await supabase
        .from('translations')
        .upsert({
          translation_key: key,
          language_code: 'ar',
          translation_value: editValues.ar,
          namespace: 'translation',
        }, {
          onConflict: 'translation_key,language_code,namespace',
        });

      if (arError) throw arError;

      // Reload translations in i18n
      await reloadTranslations('en');
      await reloadTranslations('ar');

      // Reload from database
      await loadTranslations();

      setEditingKey(null);
      setEditValues({ en: '', ar: '' });
      setMessage({ type: 'success', text: t('translations.saved') });
      
      setTimeout(() => setMessage(null), 3000);
    } catch (error) {
      console.error('Error saving translation:', error);
      setMessage({ type: 'error', text: t('translations.error') });
    } finally {
      setSaving(false);
    }
  };

  if (!isSuperAdmin()) {
    return (
      <div className="bg-white rounded-xl p-12 border border-gray-200 text-center">
        <AlertCircle className="w-12 h-12 text-red-400 mx-auto mb-4" />
        <h3 className="text-lg font-bold text-gray-900 mb-2">Access Denied</h3>
        <p className="text-gray-600">Only super administrators can access this page.</p>
      </div>
    );
  }

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600"></div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className={`flex items-center justify-between ${isRTL ? 'flex-row-reverse' : ''}`}>
        <div>
          <h1 className="text-3xl font-bold text-gray-900">{t('translations.title')}</h1>
          <p className="text-gray-600 mt-1">{t('translations.description')}</p>
        </div>
        <Globe className="w-8 h-8 text-blue-600" />
      </div>

      {message && (
        <div
          className={`p-4 rounded-lg border flex items-center space-x-2 ${
            isRTL ? 'space-x-reverse' : ''
          } ${
            message.type === 'success'
              ? 'bg-green-50 border-green-200 text-green-800'
              : 'bg-red-50 border-red-200 text-red-800'
          }`}
        >
          {message.type === 'success' ? (
            <CheckCircle className="w-5 h-5" />
          ) : (
            <AlertCircle className="w-5 h-5" />
          )}
          <span className="font-medium">{message.text}</span>
        </div>
      )}

      <div className={`bg-white rounded-xl border border-gray-200 p-6 ${isRTL ? 'text-right' : 'text-left'}`}>
        <div className={`flex gap-4 mb-6 ${isRTL ? 'flex-row-reverse' : ''}`}>
          <div className="flex-1 relative">
            <Search className={`absolute top-1/2 transform -translate-y-1/2 w-5 h-5 text-gray-400 ${
              isRTL ? 'right-3' : 'left-3'
            }`} />
            <input
              type="text"
              placeholder={t('translations.search')}
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className={`w-full pl-10 pr-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
                isRTL ? 'text-right pr-10 pl-4' : 'text-left'
              }`}
            />
          </div>
          <select
            value={languageFilter}
            onChange={(e) => setLanguageFilter(e.target.value as 'all' | 'en' | 'ar')}
            className={`px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 ${
              isRTL ? 'text-right' : 'text-left'
            }`}
          >
            <option value="all">{t('translations.all')}</option>
            <option value="en">{t('translations.english')}</option>
            <option value="ar">{t('translations.arabic')}</option>
          </select>
        </div>

        <div className="space-y-4 max-h-[600px] overflow-y-auto">
          {filteredKeys.map((key) => (
            <div
              key={key}
              className="border border-gray-200 rounded-lg p-4 hover:bg-gray-50 transition-colors"
            >
              {editingKey === key ? (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-1">
                      {key}
                    </label>
                  </div>
                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        {t('translations.english')}
                      </label>
                      <input
                        type="text"
                        value={editValues.en}
                        onChange={(e) => setEditValues({ ...editValues, en: e.target.value })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-left"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        {t('translations.arabic')}
                      </label>
                      <input
                        type="text"
                        value={editValues.ar}
                        onChange={(e) => setEditValues({ ...editValues, ar: e.target.value })}
                        className="w-full px-3 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 text-right"
                        dir="rtl"
                      />
                    </div>
                  </div>
                  <div className={`flex gap-2 ${isRTL ? 'flex-row-reverse' : ''}`}>
                    <button
                      onClick={() => saveTranslation(key)}
                      disabled={saving}
                      className={`flex items-center space-x-2 px-4 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed ${
                        isRTL ? 'space-x-reverse' : ''
                      }`}
                    >
                      <Save className="w-4 h-4" />
                      <span>{t('common.save')}</span>
                    </button>
                    <button
                      onClick={cancelEdit}
                      className="px-4 py-2 border border-gray-300 rounded-lg hover:bg-gray-50"
                    >
                      {t('common.cancel')}
                    </button>
                  </div>
                </div>
              ) : (
                <div className={`flex items-center justify-between ${isRTL ? 'flex-row-reverse' : ''}`}>
                  <div className="flex-1">
                    <div className="font-medium text-gray-900 mb-2">{key}</div>
                    <div className="grid grid-cols-2 gap-4 text-sm">
                      <div>
                        <span className="text-gray-500">{t('translations.english')}:</span>
                        <div className="text-gray-900 mt-1">{groupedTranslations[key].en || '-'}</div>
                      </div>
                      <div className={isRTL ? 'text-right' : 'text-left'}>
                        <span className="text-gray-500">{t('translations.arabic')}:</span>
                        <div className="text-gray-900 mt-1" dir="rtl">{groupedTranslations[key].ar || '-'}</div>
                      </div>
                    </div>
                  </div>
                  <button
                    onClick={() => startEdit(key)}
                    className={`px-3 py-1 text-sm text-blue-600 hover:bg-blue-50 rounded-lg ${
                      isRTL ? 'mr-4' : 'ml-4'
                    }`}
                  >
                    {t('common.edit')}
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

