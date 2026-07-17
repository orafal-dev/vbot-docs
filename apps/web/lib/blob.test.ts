import { describe, expect, it } from "vitest"

import { getScreenshotServeUrl, normalizeScreenshotRef } from "./blob"

describe("normalizeScreenshotRef", () => {
  it("returns null for empty or invalid values", () => {
    expect(normalizeScreenshotRef("")).toBeNull()
    expect(normalizeScreenshotRef("   ")).toBeNull()
    expect(normalizeScreenshotRef("not-a-path.jpg")).toBeNull()
    expect(normalizeScreenshotRef("scripts/demo/shot.gif")).toBeNull()
  })

  it("accepts valid screenshot pathnames", () => {
    expect(normalizeScreenshotRef("scripts/demo/shot.png")).toBe(
      "scripts/demo/shot.png"
    )
    expect(normalizeScreenshotRef("scripts/ab/cd/file.webp")).toBe(
      "scripts/ab/cd/file.webp"
    )
  })

  it("extracts pathnames from Vercel Blob URLs", () => {
    expect(
      normalizeScreenshotRef(
        "https://abc123.public.blob.vercel-storage.com/scripts/demo/shot.png"
      )
    ).toBe("scripts/demo/shot.png")
  })
})

describe("getScreenshotServeUrl", () => {
  it("returns null for invalid refs", () => {
    expect(getScreenshotServeUrl("bad")).toBeNull()
  })

  it("builds an encoded API serve URL", () => {
    expect(getScreenshotServeUrl("scripts/demo/shot.png")).toBe(
      "/api/screenshots/scripts/demo/shot.png"
    )
  })
})
