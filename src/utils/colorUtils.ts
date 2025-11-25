/**
 * Color utility functions for working with hex colors and generating shades
 */

export function hexToRgb(hex: string) {
  const result = /^#?([a-f\d]{2})([a-f\d]{2})([a-f\d]{2})$/i.exec(hex);
  return result
    ? {
        r: parseInt(result[1], 16),
        g: parseInt(result[2], 16),
        b: parseInt(result[3], 16),
      }
    : null;
}

export function getColorWithOpacity(hex: string, opacity: number) {
  const rgb = hexToRgb(hex);
  if (!rgb) return hex;
  return `rgba(${rgb.r}, ${rgb.g}, ${rgb.b}, ${opacity})`;
}

export function getShadeColor(
  hex: string,
  shade: '50' | '100' | '200' | '300' | '400' | '500' | '600' | '700' | '800' | '900'
) {
  const opacityMap: Record<string, number> = {
    '50': 0.05,
    '100': 0.1,
    '200': 0.2,
    '300': 0.3,
    '400': 0.4,
    '500': 0.5,
    '600': 1,
    '700': 0.9,
    '800': 0.8,
    '900': 0.7,
  };

  return getColorWithOpacity(hex, opacityMap[shade] || 1);
}

export function isValidHexColor(hex: string): boolean {
  return /^#[0-9A-F]{6}$/i.test(hex);
}

