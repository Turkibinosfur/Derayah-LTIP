import { useEffect, useState } from 'react';
import { useTranslation } from 'react-i18next';
import { supabase } from '../lib/supabase';
import { TrendingUp, Plus, Edit, Trash2, DollarSign, Users, Target, MoreVertical } from 'lucide-react';
import { createPortal } from 'react-dom';
import { useCompanyColor } from '../hooks/useCompanyColor';

interface LinkedGrant {
  id: string;
  grant_number: string;
  employee_name: string;
  plan_name_en: string | null;
  plan_code: string | null;
}

interface PerformanceMetric {
  id: string;
  company_id: string;
  name: string;
  description: string | null;
  metric_type: 'financial' | 'operational' | 'personal';
  unit_of_measure: string;
  created_at: string;
  linkedGrants: LinkedGrant[];
}

export default function PerformanceMetrics() {
  const { t, i18n } = useTranslation();
  const isRTL = i18n.language === 'ar';
  const { brandColor } = useCompanyColor();
  const [metrics, setMetrics] = useState<PerformanceMetric[]>([]);
  const [loading, setLoading] = useState(true);
  const [showMetricModal, setShowMetricModal] = useState(false);
  const [showDeleteConfirm, setShowDeleteConfirm] = useState<string | null>(null);
  const [modalMode, setModalMode] = useState<'create' | 'edit'>('create');
  const [editingMetricId, setEditingMetricId] = useState<string | null>(null);
  const [openMenuId, setOpenMenuId] = useState<string | null>(null);
  const [menuPosition, setMenuPosition] = useState<{ top: number; left: number } | null>(null);

  const [metricForm, setMetricForm] = useState({
    name: '',
    description: '',
    metric_type: 'operational' as 'financial' | 'operational' | 'personal',
    unit_of_measure: '',
  });

  useEffect(() => {
    loadMetrics();
  }, []);

  useEffect(() => {
    if (!openMenuId) return;

    const handleInteraction = (event: MouseEvent | TouchEvent | KeyboardEvent) => {
      if (event instanceof KeyboardEvent) {
        if (event.key === 'Escape') {
          setOpenMenuId(null);
          setMenuPosition(null);
        }
        return;
      }
      setOpenMenuId(null);
      setMenuPosition(null);
    };

    document.addEventListener('click', handleInteraction);
    document.addEventListener('touchstart', handleInteraction);
    document.addEventListener('keydown', handleInteraction);
    window.addEventListener('resize', handleInteraction as any);
    window.addEventListener('scroll', handleInteraction as any, true);

    return () => {
      document.removeEventListener('click', handleInteraction);
      document.removeEventListener('touchstart', handleInteraction);
      document.removeEventListener('keydown', handleInteraction);
      window.removeEventListener('resize', handleInteraction as any);
      window.removeEventListener('scroll', handleInteraction as any, true);
    };
  }, [openMenuId]);

  const loadMetrics = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      const { data } = await supabase
        .from('performance_metrics')
        .select(`
          *,
          grant_performance_metrics (
            grant_id,
            grants (
              id,
              grant_number,
              incentive_plans (plan_name_en, plan_code),
              employees (first_name_en, last_name_en)
            )
          )
        `)
        .eq('company_id', companyUser.company_id)
        .order('created_at', { ascending: false });

      if (data) {
        const formatted = (data as any[]).map(metric => ({
          id: metric.id,
          company_id: metric.company_id,
          name: metric.name,
          description: metric.description,
          metric_type: metric.metric_type,
          unit_of_measure: metric.unit_of_measure,
          created_at: metric.created_at,
          linkedGrants: (metric.grant_performance_metrics || []).map((link: any) => ({
            id: link.grants?.id,
            grant_number: link.grants?.grant_number || 'Grant',
            employee_name: link.grants?.employees
              ? `${link.grants.employees.first_name_en} ${link.grants.employees.last_name_en}`
              : 'Employee',
            plan_name_en: link.grants?.incentive_plans?.plan_name_en || null,
            plan_code: link.grants?.incentive_plans?.plan_code || null,
          })),
        }));
        setMetrics(formatted);
      }
    } catch (error) {
      console.error('Error loading metrics:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleSaveMetric = async () => {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: companyUser } = await supabase
        .from('company_users')
        .select('company_id')
        .eq('user_id', user.id)
        .single();

      if (!companyUser) return;

      let metricId = editingMetricId;

      if (modalMode === 'create') {
        const { data: created, error: createError } = await supabase
          .from('performance_metrics')
          .insert({
            company_id: companyUser.company_id,
            name: metricForm.name,
            description: metricForm.description,
            metric_type: metricForm.metric_type,
            unit_of_measure: metricForm.unit_of_measure,
          })
          .select()
          .single();

        if (createError) throw createError;
        metricId = created?.id || null;
      } else if (metricId) {
        const { error: updateError } = await supabase
          .from('performance_metrics')
          .update({
            name: metricForm.name,
            description: metricForm.description,
            metric_type: metricForm.metric_type,
            unit_of_measure: metricForm.unit_of_measure,
          })
          .eq('id', metricId)
          .eq('company_id', companyUser.company_id);

        if (updateError) throw updateError;
      }

      if (!metricId) {
        throw new Error('Failed to determine performance metric ID');
      }

      setShowMetricModal(false);
      resetForm();
      setEditingMetricId(null);
      loadMetrics();
    } catch (error) {
      console.error('Error saving performance metric:', error);
      alert('Failed to save performance metric');
    }
  };

  const handleDeleteMetric = async (id: string) => {
    try {
      const { error } = await supabase
        .from('performance_metrics')
        .delete()
        .eq('id', id);

      if (error) throw error;

      setShowDeleteConfirm(null);
      if (editingMetricId === id) {
        setEditingMetricId(null);
      }
      loadMetrics();
    } catch (error) {
      console.error('Error deleting metric:', error);
      alert('Failed to delete performance metric');
    }
  };

  const resetForm = () => {
    setMetricForm({
      name: '',
      description: '',
      metric_type: 'operational',
      unit_of_measure: '',
    });
  };

  const getMetricIcon = (type: string) => {
    switch (type) {
      case 'financial': return <DollarSign className="w-5 h-5" />;
      case 'operational': return <TrendingUp className="w-5 h-5" />;
      case 'personal': return <Users className="w-5 h-5" />;
      default: return <Target className="w-5 h-5" />;
    }
  };

  const getMetricColor = (type: string) => {
    switch (type) {
      case 'financial': return 'bg-green-100 text-green-800';
      case 'operational': return 'bg-blue-100 text-blue-800';
      case 'personal': return 'bg-purple-100 text-purple-800';
      default: return 'bg-gray-100 text-gray-800';
    }
  };

  const openCreateModal = () => {
    setModalMode('create');
    setEditingMetricId(null);
    resetForm();
    setShowMetricModal(true);
  };

  const openEditModal = (metric: PerformanceMetric) => {
    setModalMode('edit');
    setEditingMetricId(metric.id);
    setMetricForm({
      name: metric.name,
      description: metric.description || '',
      metric_type: metric.metric_type,
      unit_of_measure: metric.unit_of_measure,
    });
    setShowMetricModal(true);
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center h-64">
        <div className="text-gray-500">Loading performance metrics...</div>
      </div>
    );
  }

  return (
    <div className={`space-y-6 ${isRTL ? 'text-right' : 'text-left'}`} dir={isRTL ? 'rtl' : 'ltr'}>
      <div className="flex items-center justify-between">
        <div className={isRTL ? 'text-right' : ''}>
          <h1 className={`text-2xl font-bold text-gray-900 flex items-center gap-3 ${isRTL ? 'flex-row-reverse justify-end' : ''}`}>
            {t('performanceMetrics.title')}
            <span 
              className="inline-flex items-center justify-center w-10 h-10 rounded-full text-white text-lg font-semibold"
              style={{ backgroundColor: brandColor }}
            >
              {metrics.length}
            </span>
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Define metrics for performance-based vesting
          </p>
        </div>
        <button
          onClick={openCreateModal}
          className={`flex items-center space-x-2 px-4 py-2 text-white rounded-lg transition ${isRTL ? 'space-x-reverse' : ''}`}
          style={{ backgroundColor: brandColor }}
          onMouseEnter={(e) => {
            const rgb = parseInt(brandColor.slice(1, 3), 16) * 0.9;
            const gg = parseInt(brandColor.slice(3, 5), 16) * 0.9;
            const bb = parseInt(brandColor.slice(5, 7), 16) * 0.9;
            e.currentTarget.style.backgroundColor = `rgb(${Math.round(rgb)}, ${Math.round(gg)}, ${Math.round(bb)})`;
          }}
          onMouseLeave={(e) => {
            e.currentTarget.style.backgroundColor = brandColor;
          }}
        >
          <Plus className="w-4 h-4" />
          <span>{t('performanceMetrics.addMetric')}</span>
        </button>
      </div>

      {metrics.length === 0 ? (
        <div className="bg-white rounded-lg border border-gray-200 p-12 text-center">
          <Target className="w-16 h-16 text-gray-400 mx-auto mb-4" />
          <h3 className="text-lg font-semibold text-gray-900 mb-2">{t('performanceMetrics.noMetricsYet')}</h3>
          <p className="text-gray-600 mb-6">{t('performanceMetrics.createFirstMetric')}</p>
          <button
            onClick={openCreateModal}
            className="inline-flex items-center space-x-2 px-4 py-2 text-white rounded-lg transition"
            style={{ backgroundColor: brandColor }}
            onMouseEnter={(e) => {
              const rgb = parseInt(brandColor.slice(1, 3), 16) * 0.9;
              const gg = parseInt(brandColor.slice(3, 5), 16) * 0.9;
              const bb = parseInt(brandColor.slice(5, 7), 16) * 0.9;
              e.currentTarget.style.backgroundColor = `rgb(${Math.round(rgb)}, ${Math.round(gg)}, ${Math.round(bb)})`;
            }}
            onMouseLeave={(e) => {
              e.currentTarget.style.backgroundColor = brandColor;
            }}
          >
            <Plus className="w-4 h-4" />
            <span>{t('performanceMetrics.addMetric')}</span>
          </button>
        </div>
      ) : (
        <div className="bg-white rounded-lg border border-gray-200 shadow-sm">
          <div className="overflow-x-auto">
            <table className="min-w-full divide-y divide-gray-200">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.metric')}</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.type')}</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.unit')}</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.descriptionLabel')}</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.linkedGrants')}</th>
                  <th className="px-6 py-3 text-left text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.created')}</th>
                  <th className="px-6 py-3 text-right text-xs font-semibold text-gray-500 uppercase tracking-wide">{t('performanceMetrics.actions')}</th>
                </tr>
              </thead>
              <tbody className="bg-white divide-y divide-gray-200">
                {metrics.map(metric => (
                  <tr key={metric.id} className="hover:bg-gray-50 transition">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className={`p-2 rounded-lg ${getMetricColor(metric.metric_type)}`}>
                          {getMetricIcon(metric.metric_type)}
                        </div>
                        <div>
                          <div className="text-sm font-semibold text-gray-900">{metric.name}</div>
                          <div className="text-xs text-gray-500">ID: {metric.id.slice(0, 8)}...</div>
                        </div>
                      </div>
                    </td>
                    <td className="px-6 py-4">
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${getMetricColor(metric.metric_type)}`}>
                        {metric.metric_type}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm font-medium text-gray-900">{metric.unit_of_measure}</td>
                    <td className="px-6 py-4 text-sm text-gray-600">
                      {metric.description ? (
                        <span className="block max-w-md break-words">{metric.description}</span>
                      ) : (
                        <span className="text-xs text-gray-400">{t('performanceMetrics.noDescription')}</span>
                      )}
                    </td>
                    <td className="px-6 py-4">
                      {metric.linkedGrants.length > 0 ? (
                        <div className="flex flex-wrap gap-2">
                          {metric.linkedGrants.map(grant => (
                            <span
                              key={`${metric.id}-${grant.id || grant.grant_number}`}
                              className="inline-flex items-center px-3 py-1 rounded-full bg-blue-50 text-blue-700 text-xs font-medium"
                              title={`${grant.employee_name}${grant.plan_name_en ? ` • ${grant.plan_name_en}` : ''}`}
                            >
                              {grant.grant_number}
                            </span>
                          ))}
                        </div>
                      ) : (
                        <span className="text-xs text-gray-400">{t('performanceMetrics.none')}</span>
                      )}
                    </td>
                    <td className="px-6 py-4 text-sm text-gray-500">
                      {new Date(metric.created_at).toLocaleDateString()}
                    </td>
                    <td className="px-6 py-4 text-right">
                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          const rect = (e.currentTarget as HTMLButtonElement).getBoundingClientRect();
                          const menuWidth = 176;
                          const menuHeight = 112;
                          let top = rect.bottom + 8;
                          let left = rect.right - menuWidth;

                          if (top + menuHeight > window.innerHeight) {
                            top = rect.top - menuHeight - 8;
                          }
                          if (top < 8) {
                            top = 8;
                          }
                          if (left + menuWidth > window.innerWidth) {
                            left = window.innerWidth - menuWidth - 8;
                          }
                          if (left < 8) {
                            left = 8;
                          }

                          setMenuPosition({ top, left });
                          setOpenMenuId((prev) => (prev === metric.id ? null : metric.id));
                        }}
                        onTouchStart={(e) => e.stopPropagation()}
                        className="p-2 rounded-full hover:bg-gray-100 text-gray-500 hover:text-gray-700 transition"
                        aria-haspopup="true"
                        aria-expanded={openMenuId === metric.id}
                        aria-label="Metric actions"
                      >
                        <MoreVertical className="w-5 h-5" />
                      </button>
                      {openMenuId === metric.id && menuPosition &&
                        createPortal(
                          <div
                            className="fixed z-50 w-44 origin-top-right rounded-lg border border-gray-200 bg-white shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none"
                            role="menu"
                            aria-orientation="vertical"
                            style={{ top: menuPosition.top, left: menuPosition.left }}
                            onClick={(event) => {
                              event.stopPropagation();
                            }}
                            onTouchStart={(event) => event.stopPropagation()}
                          >
                            <button
                              onClick={() => {
                                setOpenMenuId(null);
                                setMenuPosition(null);
                                openEditModal(metric);
                              }}
                              className="w-full px-4 py-2 text-left text-sm text-gray-700 hover:bg-gray-100 flex items-center gap-2 transition"
                              role="menuitem"
                            >
                              <Edit className="w-4 h-4 text-blue-500" />
                              Edit metric
                            </button>
                            <button
                              onClick={() => {
                                setOpenMenuId(null);
                                setMenuPosition(null);
                                setShowDeleteConfirm(metric.id);
                              }}
                              className="w-full px-4 py-2 text-left text-sm text-red-600 hover:bg-red-50 flex items-center gap-2 transition"
                              role="menuitem"
                            >
                              <Trash2 className="w-4 h-4" />
                              Delete metric
                            </button>
                          </div>,
                          document.body
                        )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      )}

      {showMetricModal && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-2xl w-full">
            <div className="p-6 border-b border-gray-200">
              <h2 className="text-xl font-bold text-gray-900">
                {modalMode === 'create' ? t('performanceMetrics.addPerformanceMetric') : t('performanceMetrics.editPerformanceMetric')}
              </h2>
            </div>

            <div className="p-6 space-y-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Metric Name
                </label>
                <input
                  type="text"
                  value={metricForm.name}
                  onChange={(e) => setMetricForm({ ...metricForm, name: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  placeholder="e.g., Annual Revenue Target"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Description
                </label>
                <textarea
                  value={metricForm.description}
                  onChange={(e) => setMetricForm({ ...metricForm, description: e.target.value })}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  rows={3}
                  placeholder={t('performanceMetrics.descriptionPlaceholder')}
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Metric Type
                  </label>
                  <select
                    value={metricForm.metric_type}
                    onChange={(e) => setMetricForm({ ...metricForm, metric_type: e.target.value as any })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                  >
                    <option value="financial">{t('performanceMetrics.financial')}</option>
                    <option value="operational">{t('performanceMetrics.operational')}</option>
                    <option value="personal">{t('performanceMetrics.personal')}</option>
                  </select>
                </div>

                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Unit of Measure
                  </label>
                  <input
                    type="text"
                    value={metricForm.unit_of_measure}
                    onChange={(e) => setMetricForm({ ...metricForm, unit_of_measure: e.target.value })}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-transparent"
                    placeholder="e.g., SAR, users, %"
                  />
                </div>
              </div>

              <div className="p-4 bg-gray-50 border border-gray-200 rounded-lg text-sm text-gray-600">
                Grant linkage for performance metrics is now managed from the Grants page when issuing or editing a grant.
              </div>
            </div>

            <div className="p-6 border-t border-gray-200 flex items-center justify-end space-x-3">
              <button
                onClick={() => {
                  setShowMetricModal(false);
                  resetForm();
                  setEditingMetricId(null);
                }}
                className="px-6 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={handleSaveMetric}
                disabled={!metricForm.name || !metricForm.unit_of_measure}
                className="px-6 py-2 text-white rounded-lg transition disabled:opacity-50 disabled:cursor-not-allowed"
                style={{ backgroundColor: brandColor }}
                onMouseEnter={(e) => {
                  if (!e.currentTarget.disabled) {
                    const rgb = parseInt(brandColor.slice(1, 3), 16) * 0.9;
                    const gg = parseInt(brandColor.slice(3, 5), 16) * 0.9;
                    const bb = parseInt(brandColor.slice(5, 7), 16) * 0.9;
                    e.currentTarget.style.backgroundColor = `rgb(${Math.round(rgb)}, ${Math.round(gg)}, ${Math.round(bb)})`;
                  }
                }}
                onMouseLeave={(e) => {
                  e.currentTarget.style.backgroundColor = brandColor;
                }}
              >
                {modalMode === 'create' ? t('performanceMetrics.addMetric') : t('performanceMetrics.saveChanges')}
              </button>
            </div>
          </div>
        </div>
      )}

      {showDeleteConfirm && (
        <div className="fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-lg max-w-md w-full p-6">
            <h3 className="text-lg font-semibold text-gray-900 mb-2">{t('performanceMetrics.deletePerformanceMetric')}</h3>
            <p className="text-gray-600 mb-6">
              Are you sure you want to delete this metric? This action cannot be undone.
            </p>
            <div className="flex items-center justify-end space-x-3">
              <button
                onClick={() => setShowDeleteConfirm(null)}
                className="px-4 py-2 border border-gray-300 text-gray-700 rounded-lg hover:bg-gray-50 transition"
              >
                Cancel
              </button>
              <button
                onClick={() => handleDeleteMetric(showDeleteConfirm)}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition"
              >
                Delete
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
