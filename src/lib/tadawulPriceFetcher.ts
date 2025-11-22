/**
 * Tadawul Price Fetcher
 * 
 * Fetches share prices from Tadawul (Saudi Stock Exchange)
 * Supports both Main Market and NOMU Market
 * 
 * Note: Due to CORS restrictions, this may need to be implemented
 * via a backend proxy in production. For now, we'll use market_data table
 * which should be updated periodically.
 */

import { supabase } from './supabase';

export interface TadawulPriceData {
  symbol: string;
  price: number;
  change: number;
  changePercent: number;
  volume: number;
  lastUpdate: string;
  market: 'main' | 'nomu';
}

/**
 * Fetch current share price from Tadawul via market_data table
 * The market_data table should be updated periodically (every 15 minutes)
 * 
 * @param symbol - Tadawul symbol (e.g., '4084')
 * @param market - Market type: 'main' or 'nomu'
 * @returns Price data or null if not found
 */
export async function fetchTadawulPrice(
  symbol: string,
  market: 'main' | 'nomu' = 'main'
): Promise<TadawulPriceData | null> {
  try {
    // First, try to get from market_data table (should be updated periodically)
    const { data: marketData, error } = await supabase
      .from('market_data')
      .select('tadawul_symbol, closing_price, trading_date, volume')
      .eq('tadawul_symbol', symbol)
      .order('trading_date', { ascending: false })
      .limit(1)
      .maybeSingle();

    if (error) {
      console.error('Error fetching from market_data:', error);
      return null;
    }

    if (marketData && marketData.closing_price) {
      return {
        symbol,
        price: Number(marketData.closing_price),
        change: 0, // Would need previous day's price to calculate
        changePercent: 0,
        volume: Number(marketData.volume || 0),
        lastUpdate: marketData.trading_date || new Date().toISOString(),
        market,
      };
    }

    // If not found in market_data, return null
    // In production, you might want to:
    // 1. Call a backend API that proxies Tadawul API
    // 2. Use a third-party service
    // 3. Implement web scraping (with proper rate limiting)
    
    console.warn(`Price not found for symbol ${symbol} in market_data table`);
    return null;
  } catch (error) {
    console.error('Error fetching Tadawul price:', error);
    return null;
  }
}

/**
 * Fetch price from Tadawul public API (direct)
 * Note: This may have CORS issues and should be done via backend proxy
 * 
 * @param symbol - Tadawul symbol
 * @param market - Market type
 */
export async function fetchTadawulPriceDirect(
  symbol: string,
  market: 'main' | 'nomu' = 'main'
): Promise<TadawulPriceData | null> {
  try {
    // Tadawul API endpoint (example - actual endpoint may differ)
    const marketPath = market === 'main' ? 'main-board' : 'nomu';
    const url = `https://dataportal.saudiexchange.sa/wps/portal/tadawul/markets/equities/${marketPath}/${symbol}`;
    
    // Note: This will likely fail due to CORS
    // In production, implement via backend proxy
    const response = await fetch(url, {
      method: 'GET',
      headers: {
        'Accept': 'application/json',
      },
    });

    if (!response.ok) {
      throw new Error(`HTTP error! status: ${response.status}`);
    }

    const data = await response.json();
    
    // Parse response based on actual Tadawul API structure
    // This is a placeholder - adjust based on actual API response
    return {
      symbol,
      price: data.closingPrice || data.price || 0,
      change: data.change || 0,
      changePercent: data.changePercent || 0,
      volume: data.volume || 0,
      lastUpdate: new Date().toISOString(),
      market,
    };
  } catch (error) {
    console.error('Error fetching Tadawul price directly:', error);
    // Fallback to market_data table
    return fetchTadawulPrice(symbol, market);
  }
}

/**
 * Fetch price from Tadawul website via Edge Function
 * 
 * @param symbol - Tadawul symbol
 * @param market - Market type
 */
export async function fetchTadawulPriceFromWebsite(
  symbol: string,
  market: 'main' | 'nomu' = 'main'
): Promise<{ success: boolean; price?: number; error?: string; source?: string }> {
  try {
    const supabaseUrl = import.meta.env.VITE_SUPABASE_URL;
    if (!supabaseUrl) {
      return {
        success: false,
        error: 'Supabase URL not configured',
      };
    }

    // Call the Edge Function
    const { data, error } = await supabase.functions.invoke('fetch-tadawul-price', {
      body: { symbol, market },
    });

    if (error) {
      console.error('Edge Function error:', error);
      // If function doesn't exist or isn't deployed, fall back to market_data
      if (error.message?.includes('Function not found') || error.message?.includes('404')) {
        console.log('Edge Function not deployed, falling back to market_data table');
        const priceData = await fetchTadawulPrice(symbol, market);
        if (priceData) {
          return {
            success: true,
            price: priceData.price,
            source: 'market_data_table',
          };
        }
        return {
          success: false,
          error: 'Edge Function not deployed. Please deploy it or enter price manually.',
        };
      }
      return {
        success: false,
        error: error.message || 'Failed to fetch price from Tadawul',
      };
    }

    if (data?.success && data?.price) {
      return {
        success: true,
        price: data.price,
        source: data.source || 'tadawul_website',
      };
    }

    return {
      success: false,
      error: data?.error || 'Failed to fetch price from Tadawul',
    };
  } catch (error: any) {
    console.error('Error calling fetch-tadawul-price function:', error);
    
    // Fallback to market_data table if Edge Function fails
    try {
      const priceData = await fetchTadawulPrice(symbol, market);
      if (priceData) {
        return {
          success: true,
          price: priceData.price,
          source: 'market_data_table',
        };
      }
    } catch (fallbackError) {
      console.error('Fallback also failed:', fallbackError);
    }
    
    return {
      success: false,
      error: error?.message || 'Unknown error occurred. Please enter price manually.',
    };
  }
}

/**
 * Update company's share price from Tadawul
 * 
 * @param companyId - Company ID
 * @param symbol - Tadawul symbol
 * @param market - Market type
 */
export async function updateCompanyPriceFromTadawul(
  companyId: string,
  symbol: string,
  market: 'main' | 'nomu' = 'main'
): Promise<{ success: boolean; price?: number; error?: string; warning?: string }> {
  try {
    // First, try to fetch from Tadawul website via Edge Function
    const websiteResult = await fetchTadawulPriceFromWebsite(symbol, market);
    
    if (websiteResult.success && websiteResult.price !== undefined) {
      // Update company's current_fmv and fmv_source
      const { error: updateError } = await supabase
        .from('companies')
        .update({
          current_fmv: websiteResult.price,
          fmv_source: 'tadawul',
          updated_at: new Date().toISOString(),
        })
        .eq('id', companyId);

      if (updateError) {
        return {
          success: false,
          error: updateError.message,
        };
      }

      return {
        success: true,
        price: websiteResult.price,
      };
    }

    // Fallback: Try to get from market_data table
    const priceData = await fetchTadawulPrice(symbol, market);
    
    if (!priceData) {
      // Check if company already has a manual price set
      const { data: companyData } = await supabase
        .from('companies')
        .select('current_fmv, fmv_source')
        .eq('id', companyId)
        .maybeSingle();

      if (companyData?.current_fmv && companyData.fmv_source === 'manual') {
        return {
          success: false,
          error: `Price not found for symbol ${symbol}. Please enter the price manually in the "Current Share Price" field above.`,
          warning: 'Using existing manual price',
        };
      }

      return {
        success: false,
        error: websiteResult.error || `Price not found for symbol ${symbol}. Please enter the price manually in the "Current Share Price" field above.`,
      };
    }

    // Update company's current_fmv and fmv_source
    const { error: updateError } = await supabase
      .from('companies')
      .update({
        current_fmv: priceData.price,
        fmv_source: 'tadawul',
        updated_at: new Date().toISOString(),
      })
      .eq('id', companyId);

    if (updateError) {
      return {
        success: false,
        error: updateError.message,
      };
    }

    return {
      success: true,
      price: priceData.price,
    };
  } catch (error: any) {
    return {
      success: false,
      error: error?.message || 'Unknown error occurred',
    };
  }
}

