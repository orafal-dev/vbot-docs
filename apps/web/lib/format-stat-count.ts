export const formatStatCount = (count: number): string => {
  if (!Number.isFinite(count) || count < 0) {
    return "0"
  }

  if (count < 1000) {
    return count.toLocaleString("en-US")
  }

  if (count < 1_000_000) {
    const value = count / 1000
    return `${value >= 10 ? Math.round(value) : value.toFixed(1).replace(/\.0$/, "")}k`
  }

  const value = count / 1_000_000
  return `${value >= 10 ? Math.round(value) : value.toFixed(1).replace(/\.0$/, "")}M`
}
