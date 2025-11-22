export interface TadawulCompany {
  symbol: string;
  name_en: string;
  name_ar: string;
  market: 'main' | 'nomu';
}

/**
 * List of companies listed on Tadawul (Saudi Stock Exchange)
 * Main Market and NOMU Market
 * 
 * Note: This is a curated list. In production, you may want to fetch this
 * from an API or maintain it in a database table.
 */
export const TADAWUL_COMPANIES: TadawulCompany[] = [
  // Main Market - Major Companies
  { symbol: '2222', name_en: 'Saudi Aramco', name_ar: 'أرامكو السعودية', market: 'main' },
  { symbol: '4084', name_en: 'Derayah Financial', name_ar: 'دارة المالية', market: 'main' },
  { symbol: '1010', name_en: 'Saudi Basic Industries Corporation', name_ar: 'الشركة السعودية للصناعات الأساسية', market: 'main' },
  { symbol: '1120', name_en: 'Al Rajhi Bank', name_ar: 'مصرف الراجحي', market: 'main' },
  { symbol: '1150', name_en: 'Alinma Bank', name_ar: 'مصرف الإنماء', market: 'main' },
  { symbol: '1180', name_en: 'Saudi National Bank', name_ar: 'البنك الأهلي السعودي', market: 'main' },
  { symbol: '1211', name_en: 'Saudi Arabian Mining Company', name_ar: 'شركة التعدين العربية السعودية', market: 'main' },
  { symbol: '2010', name_en: 'Saudi Cement Company', name_ar: 'شركة الأسمنت السعودية', market: 'main' },
  { symbol: '2030', name_en: 'Saudi Petrochemical Company', name_ar: 'الشركة السعودية للصناعات البتروكيماوية', market: 'main' },
  { symbol: '2050', name_en: 'Savola Group', name_ar: 'مجموعة صافولا', market: 'main' },
  { symbol: '2060', name_en: 'National Industrialization Company', name_ar: 'الشركة الوطنية للصناعات الأساسية', market: 'main' },
  { symbol: '2110', name_en: 'Saudi Cement', name_ar: 'الأسمنت السعودية', market: 'main' },
  { symbol: '2220', name_en: 'Saudi Chemical Company', name_ar: 'الشركة السعودية للكيماويات', market: 'main' },
  { symbol: '2230', name_en: 'Saudi Chemical', name_ar: 'الكيماويات السعودية', market: 'main' },
  { symbol: '2240', name_en: 'Zamil Industrial Investment', name_ar: 'استثمارات زامل الصناعية', market: 'main' },
  { symbol: '2250', name_en: 'Saudi Ceramic Company', name_ar: 'شركة الخزف السعودي', market: 'main' },
  { symbol: '2280', name_en: 'Almarai Company', name_ar: 'شركة المراعي', market: 'main' },
  { symbol: '2290', name_en: 'Yanbu Cement Company', name_ar: 'شركة أسمنت ينبع', market: 'main' },
  { symbol: '2300', name_en: 'Saudi Steel Pipe Company', name_ar: 'شركة أنابيب الصلب السعودية', market: 'main' },
  { symbol: '2310', name_en: 'Saudi Arabian Fertilizer Company', name_ar: 'الشركة السعودية للصناعات الأساسية', market: 'main' },
  { symbol: '2330', name_en: 'Advanced Petrochemical Company', name_ar: 'الشركة المتقدمة للبتروكيماويات', market: 'main' },
  { symbol: '2350', name_en: 'Saudi Kayan Petrochemical Company', name_ar: 'الشركة السعودية للكيان للبتروكيماويات', market: 'main' },
  { symbol: '2380', name_en: 'Petro Rabigh', name_ar: 'بترو رابغ', market: 'main' },
  { symbol: '3001', name_en: 'Saudi Industrial Investment Group', name_ar: 'مجموعة الاستثمار الصناعي السعودي', market: 'main' },
  { symbol: '3002', name_en: 'Najran Cement Company', name_ar: 'شركة أسمنت نجران', market: 'main' },
  { symbol: '3003', name_en: 'City Cement Company', name_ar: 'شركة أسمنت المدينة', market: 'main' },
  { symbol: '3004', name_en: 'Eastern Province Cement Company', name_ar: 'شركة أسمنت المنطقة الشرقية', market: 'main' },
  { symbol: '3005', name_en: 'Qassim Cement Company', name_ar: 'شركة أسمنت القصيم', market: 'main' },
  { symbol: '3007', name_en: 'Saudi Cement Company', name_ar: 'شركة الأسمنت السعودية', market: 'main' },
  { symbol: '3008', name_en: 'Al Jouf Cement Company', name_ar: 'شركة أسمنت الجوف', market: 'main' },
  { symbol: '3020', name_en: 'Yamama Saudi Cement Company', name_ar: 'شركة أسمنت اليمامة السعودية', market: 'main' },
  { symbol: '4001', name_en: 'Abdullah Al Othaim Markets', name_ar: 'أسواق عبدالله العثيم', market: 'main' },
  { symbol: '4002', name_en: 'Mouwasat Medical Services', name_ar: 'خدمات المواسط الطبية', market: 'main' },
  { symbol: '4003', name_en: 'Extra Co', name_ar: 'إكسترا', market: 'main' },
  { symbol: '4004', name_en: 'Dallah Healthcare', name_ar: 'دلة للرعاية الصحية', market: 'main' },
  { symbol: '4005', name_en: 'National Medical Care', name_ar: 'الرعاية الطبية الوطنية', market: 'main' },
  { symbol: '4013', name_en: 'Dr. Sulaiman Al Habib Medical', name_ar: 'د. سليمان الحبيب الطبية', market: 'main' },
  
  // NOMU Market - Parallel Market (Sample - add more as needed)
  { symbol: '2223', name_en: 'NOMU Company 1', name_ar: 'شركة نمو 1', market: 'nomu' },
  { symbol: '2224', name_en: 'NOMU Company 2', name_ar: 'شركة نمو 2', market: 'nomu' },
  { symbol: '2225', name_en: 'NOMU Company 3', name_ar: 'شركة نمو 3', market: 'nomu' },
];

/**
 * Get companies by market type
 */
export function getCompaniesByMarket(market: 'main' | 'nomu'): TadawulCompany[] {
  return TADAWUL_COMPANIES.filter(company => company.market === market);
}

/**
 * Search companies by symbol or name
 */
export function searchCompanies(query: string): TadawulCompany[] {
  const lowerQuery = query.toLowerCase();
  return TADAWUL_COMPANIES.filter(
    company =>
      company.symbol.toLowerCase().includes(lowerQuery) ||
      company.name_en.toLowerCase().includes(lowerQuery) ||
      company.name_ar.includes(query)
  );
}

/**
 * Get company by symbol
 */
export function getCompanyBySymbol(symbol: string): TadawulCompany | undefined {
  return TADAWUL_COMPANIES.find(company => company.symbol === symbol);
}

