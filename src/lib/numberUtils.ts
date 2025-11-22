export const formatShares = (value: number): string => {
  const floored = Math.floor(Number(value) || 0);
  return floored.toLocaleString();
};



