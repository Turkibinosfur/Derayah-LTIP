import { serve } from 'https://deno.land/std@0.168.0/http/server.ts';
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

serve(async (req) => {
  // Handle CORS preflight requests
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    // Get Supabase client
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    // Get symbol from request
    const { symbol, market = 'main' } = await req.json();

    if (!symbol) {
      return new Response(
        JSON.stringify({ error: 'Symbol is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    console.log(`Fetching price for symbol: ${symbol}, market: ${market}`);

    // Try to fetch from Tadawul website
    // The theoretical market watch page shows current prices
    const marketPath = market === 'main' ? 'main-market-watch' : 'nomu-market-watch';
    const url = `https://www.saudiexchange.sa/wps/portal/saudiexchange/ourmarkets/${marketPath}/theoritical-market-watch-today?locale=en`;

    try {
      // Fetch the page
      const response = await fetch(url, {
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const html = await response.text();

      // Try to find the symbol in the HTML and extract the closing price
      // The page structure may vary, so we'll try multiple approaches
      
      let closingPrice: number | null = null;

      // Approach 1: Look for JSON data embedded in the page (most reliable)
      // Try various common patterns for embedded JSON data
      const jsonPatterns = [
        /window\.__INITIAL_STATE__\s*=\s*({.+?});/s,
        /window\.__PRELOADED_STATE__\s*=\s*({.+?});/s,
        /var\s+marketData\s*=\s*({.+?});/s,
        /"marketData":\s*({.+?})/s,
      ];

      for (const pattern of jsonPatterns) {
        const jsonMatch = html.match(pattern);
        if (jsonMatch) {
          try {
            const data = JSON.parse(jsonMatch[1]);
            // Try to find the symbol in the data structure
            // Common structures: data.symbols[symbol], data.marketData[symbol], etc.
            const findPriceInData = (obj: any, searchSymbol: string): number | null => {
              if (typeof obj !== 'object' || obj === null) return null;
              
              // Check if this object has the symbol
              if (obj.symbol === searchSymbol || obj.code === searchSymbol || obj.ticker === searchSymbol) {
                return obj.closingPrice || obj.close || obj.price || obj.lastPrice || null;
              }
              
              // Recursively search in arrays and objects
              if (Array.isArray(obj)) {
                for (const item of obj) {
                  const price = findPriceInData(item, searchSymbol);
                  if (price !== null) return price;
                }
              } else {
                for (const key in obj) {
                  const price = findPriceInData(obj[key], searchSymbol);
                  if (price !== null) return price;
                }
              }
              
              return null;
            };
            
            const foundPrice = findPriceInData(data, symbol);
            if (foundPrice !== null && !isNaN(foundPrice)) {
              closingPrice = foundPrice;
              console.log(`Found price ${closingPrice} in JSON data`);
              break;
            }
          } catch (e) {
            console.log('Could not parse JSON from page:', e);
          }
        }
      }

      // Approach 2: Look for the symbol in a table row (HTML parsing)
      if (!closingPrice) {
        // Look for table rows containing the symbol
        // Pattern: <tr>...symbol...price data...</tr>
        const tableRowRegex = new RegExp(`<tr[^>]*>.*?${symbol}.*?</tr>`, 'is');
        const rowMatch = html.match(tableRowRegex);
        
        if (rowMatch) {
          const row = rowMatch[0];
          // Extract all numbers from the row
          const numberMatches = row.match(/\d+\.?\d*/g);
          if (numberMatches && numberMatches.length > 0) {
            // Try to find the closing price - usually one of the larger numbers
            // Filter out very small numbers (likely percentages or indices)
            const prices = numberMatches
              .map(m => parseFloat(m))
              .filter(n => n > 1 && n < 10000); // Reasonable price range for Saudi stocks
            
            if (prices.length > 0) {
              // The closing price is often the last or second-to-last price in the row
              closingPrice = prices[prices.length - 1];
              console.log(`Found price ${closingPrice} in table row`);
            }
          }
        }
      }

      // Approach 3: Look for data attributes or specific HTML patterns
      if (!closingPrice) {
        // Try to find data-price, data-close, or similar attributes
        const dataPriceRegex = new RegExp(`data-symbol=["']${symbol}["'][^>]*data-close=["']([^"']+)["']`, 'i');
        const dataMatch = html.match(dataPriceRegex);
        if (dataMatch && dataMatch[1]) {
          closingPrice = parseFloat(dataMatch[1]);
          if (!isNaN(closingPrice)) {
            console.log(`Found price ${closingPrice} in data attribute`);
          }
        }
      }

      // Approach 4: Try to find the symbol in a more specific table structure
      // Look for patterns like: <td>4084</td><td>...</td><td>28.36</td>
      if (!closingPrice) {
        // Find the symbol cell, then look for price in nearby cells
        const symbolCellRegex = new RegExp(`<td[^>]*>\\s*${symbol}\\s*</td>`, 'i');
        const symbolMatch = html.match(symbolCellRegex);
        
        if (symbolMatch) {
          const symbolIndex = symbolMatch.index || 0;
          // Get a chunk of HTML around the symbol (next 2000 characters)
          const context = html.substring(symbolIndex, symbolIndex + 2000);
          
          // Look for price patterns in the context
          // Prices are usually in format: XX.XX or XXX.XX
          const pricePattern = /\b(\d{1,3}\.\d{2})\b/g;
          const priceMatches = context.match(pricePattern);
          
          if (priceMatches && priceMatches.length > 0) {
            // Filter reasonable prices (between 1 and 1000 SAR)
            const prices = priceMatches
              .map(m => parseFloat(m))
              .filter(n => n >= 1 && n <= 1000);
            
            if (prices.length > 0) {
              // Usually the closing price is one of the later prices in the row
              closingPrice = prices[prices.length - 1];
              console.log(`Found price ${closingPrice} near symbol in table`);
            }
          }
        }
      }

      // Approach 5: Try alternative API endpoints or data sources
      if (!closingPrice) {
        // Try Tadawul's data portal API (if available)
        const apiEndpoints = [
          `https://dataportal.saudiexchange.sa/api/v1/stocks/${symbol}`,
          `https://www.saudiexchange.sa/api/market-data/${symbol}`,
          `https://www.saudiexchange.sa/wps/portal/saudiexchange/api/stocks/${symbol}`,
        ];

        for (const apiUrl of apiEndpoints) {
          try {
            const apiResponse = await fetch(apiUrl, {
              headers: {
                'User-Agent': 'Mozilla/5.0',
                'Accept': 'application/json',
              },
            });
            
            if (apiResponse.ok) {
              const apiData = await apiResponse.json();
              closingPrice = apiData.closingPrice || apiData.close || apiData.price || apiData.lastPrice || null;
              if (closingPrice && !isNaN(closingPrice)) {
                console.log(`Found price ${closingPrice} from API: ${apiUrl}`);
                break;
              }
            }
          } catch (e) {
            // Continue to next endpoint
            continue;
          }
        }
      }

      // If still no price, return error
      if (!closingPrice || isNaN(closingPrice)) {
        // Fallback: Try to get from market_data table
        const { data: existingData } = await supabase
          .from('market_data')
          .select('closing_price')
          .eq('tadawul_symbol', symbol)
          .order('trading_date', { ascending: false })
          .limit(1)
          .maybeSingle();

        if (existingData?.closing_price) {
          return new Response(
            JSON.stringify({
              success: true,
              price: Number(existingData.closing_price),
              source: 'market_data_table',
              message: 'Price fetched from database (Tadawul website parsing failed)',
            }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
          );
        }

        return new Response(
          JSON.stringify({
            error: 'Could not parse price from Tadawul website. The page structure may have changed or the symbol may not be listed.',
            suggestion: 'Please enter the price manually or check the symbol.',
          }),
          { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      // Update market_data table with the fetched price
      const tradingDate = new Date().toISOString().split('T')[0];
      const { error: updateError } = await supabase
        .from('market_data')
        .upsert({
          tadawul_symbol: symbol,
          trading_date: tradingDate,
          closing_price: closingPrice,
          opening_price: closingPrice, // Use closing as fallback if opening not available
          high_price: closingPrice,
          low_price: closingPrice,
          source: 'Tadawul Website Fetch',
          last_updated: new Date().toISOString(),
        }, {
          onConflict: 'tadawul_symbol,trading_date',
        });

      if (updateError) {
        console.error('Error updating market_data:', updateError);
      }

      return new Response(
        JSON.stringify({
          success: true,
          price: closingPrice,
          source: 'tadawul_website',
          trading_date: tradingDate,
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );

    } catch (fetchError: any) {
      console.error('Error fetching from Tadawul:', fetchError);
      
      // Fallback to market_data table
      const { data: existingData } = await supabase
        .from('market_data')
        .select('closing_price, trading_date')
        .eq('tadawul_symbol', symbol)
        .order('trading_date', { ascending: false })
        .limit(1)
        .maybeSingle();

      if (existingData?.closing_price) {
        return new Response(
          JSON.stringify({
            success: true,
            price: Number(existingData.closing_price),
            source: 'market_data_table',
            trading_date: existingData.trading_date,
            message: 'Fetched from database (Tadawul website unavailable)',
          }),
          { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        );
      }

      return new Response(
        JSON.stringify({
          error: `Failed to fetch price from Tadawul: ${fetchError.message}`,
          suggestion: 'Please enter the price manually or try again later.',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }
  } catch (error: any) {
    console.error('Error in fetch-tadawul-price function:', error);
    return new Response(
      JSON.stringify({ error: error.message || 'Internal server error' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});

