import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

import { trackScriptStat } from "./track-script-stat"

describe("trackScriptStat", () => {
  beforeEach(() => {
    sessionStorage.clear()
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          viewCount: 1,
          copyCount: 0,
          downloadCount: 0,
        }),
      })
    )
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it("posts an event and returns stats", async () => {
    const stats = await trackScriptStat("heal-bot", "copy")

    expect(fetch).toHaveBeenCalledWith("/api/scripts/heal-bot/events", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ type: "copy" }),
    })
    expect(stats).toEqual({
      viewCount: 1,
      copyCount: 0,
      downloadCount: 0,
    })
  })

  it("deduplicates view events within a session", async () => {
    await trackScriptStat("heal-bot", "view")
    const second = await trackScriptStat("heal-bot", "view")

    expect(fetch).toHaveBeenCalledTimes(1)
    expect(second).toBeNull()
  })

  it("returns null when the API rejects the event", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
      })
    )

    await expect(trackScriptStat("heal-bot", "download")).resolves.toBeNull()
  })
})