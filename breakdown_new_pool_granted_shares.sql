-- Breakdown of granted shares for "New pool"
-- This query shows which grants, plans, and employees contribute to the 70,900 total

WITH pool_info AS (
  SELECT id as pool_id, pool_name_en, pool_code
  FROM ltip_pools
  WHERE pool_name_en ILIKE '%New pool%' OR pool_code ILIKE '%new%'
  LIMIT 1
),
grants_breakdown AS (
  SELECT 
    g.id as grant_id,
    g.grant_number,
    g.total_shares,
    g.status as grant_status,
    g.grant_date,
    ip.id as plan_id,
    ip.plan_name_en,
    ip.plan_code,
    ip.plan_type,
    e.id as employee_id,
    e.first_name_en || ' ' || e.last_name_en as employee_name,
    e.employee_number,
    pool.pool_id,
    pool.pool_name_en,
    pool.pool_code
  FROM grants g
  INNER JOIN incentive_plans ip ON g.plan_id = ip.id
  INNER JOIN employees e ON g.employee_id = e.id
  CROSS JOIN pool_info pool
  WHERE ip.ltip_pool_id = pool.pool_id
)
SELECT 
  pool_name_en as "Pool Name",
  pool_code as "Pool Code",
  plan_code as "Plan Code",
  plan_name_en as "Plan Name",
  plan_type as "Plan Type",
  grant_number as "Grant Number",
  employee_name as "Employee Name",
  employee_number as "Employee Number",
  total_shares as "Grant Shares",
  grant_status as "Grant Status",
  grant_date as "Grant Date"
FROM grants_breakdown
ORDER BY plan_code, employee_name, grant_date;

-- Summary by Plan
SELECT 
  plan_code as "Plan Code",
  plan_name_en as "Plan Name",
  plan_type as "Plan Type",
  COUNT(DISTINCT grant_id) as "Number of Grants",
  SUM(total_shares) as "Total Shares"
FROM (
  SELECT 
    g.id as grant_id,
    g.total_shares,
    ip.plan_code,
    ip.plan_name_en,
    ip.plan_type,
    pool.pool_id
  FROM grants g
  INNER JOIN incentive_plans ip ON g.plan_id = ip.id
  CROSS JOIN (SELECT id as pool_id FROM ltip_pools WHERE pool_name_en ILIKE '%New pool%' LIMIT 1) pool
  WHERE ip.ltip_pool_id = pool.pool_id
) breakdown
GROUP BY plan_code, plan_name_en, plan_type
ORDER BY "Total Shares" DESC;

-- Summary by Employee
SELECT 
  employee_number as "Employee Number",
  employee_name as "Employee Name",
  COUNT(DISTINCT grant_id) as "Number of Grants",
  SUM(total_shares) as "Total Shares"
FROM (
  SELECT 
    g.id as grant_id,
    g.total_shares,
    e.first_name_en || ' ' || e.last_name_en as employee_name,
    e.employee_number,
    pool.pool_id
  FROM grants g
  INNER JOIN incentive_plans ip ON g.plan_id = ip.id
  INNER JOIN employees e ON g.employee_id = e.id
  CROSS JOIN (SELECT id as pool_id FROM ltip_pools WHERE pool_name_en ILIKE '%New pool%' LIMIT 1) pool
  WHERE ip.ltip_pool_id = pool.pool_id
) breakdown
GROUP BY employee_number, employee_name
ORDER BY "Total Shares" DESC;

-- Grand Total Verification
SELECT 
  pool.pool_name_en as "Pool Name",
  COUNT(DISTINCT(idx)) as "Total Grants",
  SUM(total_shares) as "Total Granted Shares"
FROM (
  SELECT 
    g.id as idx,
    g.total_shares,
    pool.pool_id
  FROM grants g
  INNER JOIN incentive_plans ip ON g.plan_id = ip.id
  CROSS JOIN (SELECT id as pool_id, pool_name_en FROM ltip_pools WHERE pool_name_en ILIKE '%New pool%' LIMIT 1) pool
  WHERE ip.ltip_pool_id = pool.pool_id
) breakdown
CROSS JOIN (SELECT pool_name_en FROM ltip_pools WHERE pool_name_en ILIKE '%New pool%' LIMIT 1) pool
GROUP BY pool.pool_name_en;

