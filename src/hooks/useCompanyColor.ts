import { useEffect, useState } from 'react';
import { supabase } from '../lib/supabase';
import { useAuth } from '../contexts/AuthContext';
import { getShadeColor, getColorWithOpacity, hexToRgb } from '../utils/colorUtils';

const DEFAULT_COLOR = '#2563EB'; // Default blue color (Tailwind blue-600)

export function useCompanyColor() {
  const { getCurrentCompanyId } = useAuth();
  const [brandColor, setBrandColor] = useState<string>(DEFAULT_COLOR);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const loadCompanyColor = async () => {
      const companyId = getCurrentCompanyId();
      if (!companyId) {
        setBrandColor(DEFAULT_COLOR);
        setLoading(false);
        return;
      }

      try {
        const { data, error } = await supabase
          .from('companies')
          .select('brand_color')
          .eq('id', companyId)
          .maybeSingle();

        if (error) throw error;

        // Validate and set color, fallback to default if invalid
        const color = data?.brand_color;
        if (color && /^#[0-9A-F]{6}$/i.test(color)) {
          setBrandColor(color);
        } else {
          setBrandColor(DEFAULT_COLOR);
        }
      } catch (error) {
        console.error('Error loading company color:', error);
        setBrandColor(DEFAULT_COLOR);
      } finally {
        setLoading(false);
      }
    };

    loadCompanyColor();

    // Listen for company changes
    const channel = supabase
      .channel('company-color-changes')
      .on(
        'postgres_changes',
        {
          event: 'UPDATE',
          schema: 'public',
          table: 'companies',
          filter: `id=eq.${getCurrentCompanyId()}`,
        },
        (payload) => {
          const newColor = (payload.new as any)?.brand_color;
          if (newColor && /^#[0-9A-F]{6}$/i.test(newColor)) {
            setBrandColor(newColor);
          }
        }
      )
      .subscribe();

    return () => {
      supabase.removeChannel(channel);
    };
  }, [getCurrentCompanyId]);

  // Helper to get background color with opacity
  const getBgColor = (
    shade: '50' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900' = '600'
  ) => {
    return getShadeColor(brandColor, shade);
  };

  // Helper to get text color
  const getTextColor = (
    shade: '50' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900' = '600'
  ) => {
    return getShadeColor(brandColor, shade);
  };

  // Helper to get border color
  const getBorderColor = (
    shade: '50' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900' = '600'
  ) => {
    return getShadeColor(brandColor, shade);
  };

  return {
    brandColor,
    loading,
    getBgColor,
    getTextColor,
    getBorderColor,
    hexToRgb: () => hexToRgb(brandColor),
    getColorWithOpacity: (opacity: number) => getColorWithOpacity(brandColor, opacity),
  };
}

