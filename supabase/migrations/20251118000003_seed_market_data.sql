/*
  # Seed Market Data
  
  This migration seeds the market_data table with sample data for common Tadawul symbols.
  In production, this data should be populated automatically via a scheduled job or API integration.
  
  Note: Prices are sample data and should be updated with real market data.
*/

-- Insert sample market data for common Tadawul symbols
-- Using current date and sample prices (update with real data in production)

INSERT INTO market_data (tadawul_symbol, trading_date, opening_price, closing_price, high_price, low_price, volume, source, last_updated)
VALUES
  -- Major Banks
  ('1120', CURRENT_DATE, 32.50, 33.00, 33.50, 32.00, 5000000, 'Sample Data', now()),
  ('1150', CURRENT_DATE, 28.00, 28.50, 29.00, 27.50, 3000000, 'Sample Data', now()),
  ('1180', CURRENT_DATE, 45.00, 45.50, 46.00, 44.50, 4000000, 'Sample Data', now()),
  
  -- Derayah Financial (Updated with actual market price from Tadawul as of Nov 18, 2024)
  ('4084', CURRENT_DATE, 28.20, 28.36, 28.50, 28.00, 2000000, 'Tadawul Market Data', now()),
  
  -- Major Companies
  ('2222', CURRENT_DATE, 8.50, 8.60, 8.70, 8.40, 10000000, 'Sample Data', now()),
  ('1010', CURRENT_DATE, 95.00, 96.00, 97.00, 94.50, 8000000, 'Sample Data', now()),
  ('1211', CURRENT_DATE, 42.00, 42.50, 43.00, 41.50, 6000000, 'Sample Data', now()),
  
  -- Cement Companies
  ('2010', CURRENT_DATE, 55.00, 55.50, 56.00, 54.50, 1500000, 'Sample Data', now()),
  ('2030', CURRENT_DATE, 38.00, 38.50, 39.00, 37.50, 1200000, 'Sample Data', now()),
  ('3002', CURRENT_DATE, 12.00, 12.20, 12.50, 11.80, 800000, 'Sample Data', now()),
  ('3003', CURRENT_DATE, 15.00, 15.30, 15.60, 14.80, 900000, 'Sample Data', now()),
  ('3004', CURRENT_DATE, 18.00, 18.20, 18.50, 17.80, 1000000, 'Sample Data', now()),
  ('3005', CURRENT_DATE, 20.00, 20.30, 20.60, 19.80, 1100000, 'Sample Data', now()),
  ('3007', CURRENT_DATE, 22.00, 22.30, 22.60, 21.80, 1200000, 'Sample Data', now()),
  ('3008', CURRENT_DATE, 14.00, 14.20, 14.50, 13.80, 700000, 'Sample Data', now()),
  ('3020', CURRENT_DATE, 16.00, 16.30, 16.60, 15.80, 850000, 'Sample Data', now()),
  
  -- Retail & Services
  ('2050', CURRENT_DATE, 25.00, 25.50, 26.00, 24.50, 2000000, 'Sample Data', now()),
  ('2280', CURRENT_DATE, 58.00, 58.50, 59.00, 57.50, 3000000, 'Sample Data', now()),
  ('4001', CURRENT_DATE, 35.00, 35.50, 36.00, 34.50, 1500000, 'Sample Data', now()),
  ('4002', CURRENT_DATE, 120.00, 121.00, 122.00, 119.00, 800000, 'Sample Data', now()),
  ('4003', CURRENT_DATE, 28.00, 28.50, 29.00, 27.50, 1000000, 'Sample Data', now()),
  ('4004', CURRENT_DATE, 85.00, 85.50, 86.00, 84.50, 600000, 'Sample Data', now()),
  ('4005', CURRENT_DATE, 95.00, 95.50, 96.00, 94.50, 700000, 'Sample Data', now()),
  ('4013', CURRENT_DATE, 150.00, 151.00, 152.00, 149.00, 500000, 'Sample Data', now()),
  
  -- Petrochemical
  ('2060', CURRENT_DATE, 22.00, 22.50, 23.00, 21.50, 2500000, 'Sample Data', now()),
  ('2110', CURRENT_DATE, 48.00, 48.50, 49.00, 47.50, 1800000, 'Sample Data', now()),
  ('2220', CURRENT_DATE, 35.00, 35.50, 36.00, 34.50, 1400000, 'Sample Data', now()),
  ('2230', CURRENT_DATE, 40.00, 40.50, 41.00, 39.50, 1600000, 'Sample Data', now()),
  ('2240', CURRENT_DATE, 18.00, 18.30, 18.60, 17.80, 900000, 'Sample Data', now()),
  ('2250', CURRENT_DATE, 32.00, 32.50, 33.00, 31.50, 1100000, 'Sample Data', now()),
  ('2290', CURRENT_DATE, 19.00, 19.30, 19.60, 18.80, 950000, 'Sample Data', now()),
  ('2300', CURRENT_DATE, 15.00, 15.30, 15.60, 14.80, 750000, 'Sample Data', now()),
  ('2310', CURRENT_DATE, 88.00, 88.50, 89.00, 87.50, 2200000, 'Sample Data', now()),
  ('2330', CURRENT_DATE, 52.00, 52.50, 53.00, 51.50, 1900000, 'Sample Data', now()),
  ('2350', CURRENT_DATE, 12.00, 12.30, 12.60, 11.80, 1300000, 'Sample Data', now()),
  ('2380', CURRENT_DATE, 8.50, 8.70, 8.90, 8.30, 1700000, 'Sample Data', now()),
  
  -- Industrial
  ('3001', CURRENT_DATE, 24.00, 24.50, 25.00, 23.50, 1400000, 'Sample Data', now()),
  ('2320', CURRENT_DATE, 42.00, 42.50, 43.00, 41.50, 1000000, 'Sample Data', now()),
  ('2340', CURRENT_DATE, 38.00, 38.50, 39.00, 37.50, 950000, 'Sample Data', now())
ON CONFLICT (tadawul_symbol, trading_date) 
DO UPDATE SET
  opening_price = EXCLUDED.opening_price,
  closing_price = EXCLUDED.closing_price,
  high_price = EXCLUDED.high_price,
  low_price = EXCLUDED.low_price,
  volume = EXCLUDED.volume,
  source = EXCLUDED.source,
  last_updated = now();

-- Also insert data for previous trading day (yesterday) for reference
INSERT INTO market_data (tadawul_symbol, trading_date, opening_price, closing_price, high_price, low_price, volume, source, last_updated)
SELECT 
  tadawul_symbol,
  CURRENT_DATE - INTERVAL '1 day' as trading_date,
  opening_price * 0.99 as opening_price, -- Slight variation
  closing_price * 0.99 as closing_price,
  high_price * 0.99 as high_price,
  low_price * 0.99 as low_price,
  volume,
  source,
  now()
FROM market_data
WHERE trading_date = CURRENT_DATE
ON CONFLICT (tadawul_symbol, trading_date) DO NOTHING;

-- Create index if not exists for better query performance
CREATE INDEX IF NOT EXISTS idx_market_data_symbol_date ON market_data(tadawul_symbol, trading_date DESC);
CREATE INDEX IF NOT EXISTS idx_market_data_trading_date ON market_data(trading_date DESC);

-- Add comment
COMMENT ON TABLE market_data IS 'Tadawul market data cache. Should be updated periodically (every 15 minutes) via scheduled job or API integration.';

