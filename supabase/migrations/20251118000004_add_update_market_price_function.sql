/*
  # Add Function to Update Market Price
  
  This migration creates a function to manually update market prices in the market_data table.
  This can be used by admins to update prices when they need to match Tadawul closing prices.
*/

-- Function to update or insert market price for a symbol
-- Note: Parameters with defaults must come after required parameters
CREATE OR REPLACE FUNCTION update_market_price(
  p_symbol text,
  p_closing_price numeric,
  p_trading_date date DEFAULT CURRENT_DATE,
  p_opening_price numeric DEFAULT NULL,
  p_high_price numeric DEFAULT NULL,
  p_low_price numeric DEFAULT NULL,
  p_volume bigint DEFAULT NULL,
  p_source text DEFAULT 'Manual Update'
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO market_data (
    tadawul_symbol,
    trading_date,
    opening_price,
    closing_price,
    high_price,
    low_price,
    volume,
    source,
    last_updated
  )
  VALUES (
    p_symbol,
    p_trading_date,
    COALESCE(p_opening_price, p_closing_price),
    p_closing_price,
    COALESCE(p_high_price, p_closing_price),
    COALESCE(p_low_price, p_closing_price),
    p_volume,
    p_source,
    now()
  )
  ON CONFLICT (tadawul_symbol, trading_date)
  DO UPDATE SET
    opening_price = COALESCE(EXCLUDED.opening_price, market_data.opening_price),
    closing_price = EXCLUDED.closing_price,
    high_price = COALESCE(EXCLUDED.high_price, market_data.high_price),
    low_price = COALESCE(EXCLUDED.low_price, market_data.low_price),
    volume = COALESCE(EXCLUDED.volume, market_data.volume),
    source = EXCLUDED.source,
    last_updated = now();
END;
$$;

-- Grant execute permission to authenticated users
GRANT EXECUTE ON FUNCTION update_market_price TO authenticated;

-- Add comment
COMMENT ON FUNCTION update_market_price IS 'Updates or inserts market price data for a given Tadawul symbol. Can be used to manually update prices to match Tadawul closing prices.';

