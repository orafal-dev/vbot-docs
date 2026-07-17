import { describe, expect, it } from "vitest"

import { formatStatCount } from "./format-stat-count"

describe("formatStatCount", () => {
  it("returns 0 for non-finite or negative values", () => {
    expect(formatStatCount(Number.NaN)).toBe("0")
    expect(formatStatCount(Number.POSITIVE_INFINITY)).toBe("0")
    expect(formatStatCount(-1)).toBe("0")
  })

  it("formats small counts with locale separators", () => {
    expect(formatStatCount(0)).toBe("0")
    expect(formatStatCount(999)).toBe("999")
  })

  it("formats thousands with a k suffix", () => {
    expect(formatStatCount(1000)).toBe("1k")
    expect(formatStatCount(1500)).toBe("1.5k")
    expect(formatStatCount(10_000)).toBe("10k")
  })

  it("formats millions with an M suffix", () => {
    expect(formatStatCount(1_000_000)).toBe("1M")
    expect(formatStatCount(2_500_000)).toBe("2.5M")
    expect(formatStatCount(12_000_000)).toBe("12M")
  })
})
