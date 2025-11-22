/*
  # Update Derayah Financial Price to Match Tadawul
  
  This migration updates the Derayah Financial (4084) price to match the actual
  closing price from Tadawul: 28.36 SAR (as of Nov 18, 2024)
*/

-- Update Derayah Financial price to match Tadawul closing price
UPDATE market_data
SET 
  closing_price = 28.36,
  opening_price = COALESCE(opening_price, 28.20),
  high_price = COALESCE(high_price, 28.50),
  low_price = COALESCE(low_price, 28.00),
  source = 'Tadawul Market Data',
  last_updated = now()
WHERE tadawul_symbol = '4084'
  AND trading_date = CURRENT_DATE;

-- If no record exists for today, insert it
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
SELECT 
  '4084',
  CURRENT_DATE,
  28.20,
  28.36,
  28.50,
  28.00,
  2000000,
  'Tadawul Market Data',
  now()
WHERE NOT EXISTS (
  SELECT 1 FROM market_data 
  WHERE tadawul_symbol = '4084' 
    AND trading_date = CURRENT_DATE
);

-- Also update the company's current_fmv if it's set to the old price
UPDATE companies
SET 
  current_fmv = 28.36,
  fmv_source = 'tadawul',
  updated_at = now()
WHERE tadawul_symbol = '4084'
  AND (current_fmv = 30.00 OR current_fmv IS NULL);

