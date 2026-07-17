import { afterEach, describe, expect, it, vi } from "vitest"

import {
  SCRIPT_STAT_UPDATED_EVENT,
  emitScriptStatUpdate,
} from "./script-stat-events"

describe("emitScriptStatUpdate", () => {
  afterEach(() => {
    vi.restoreAllMocks()
  })

  it("dispatches a typed custom event with slug and stats", () => {
    const dispatchSpy = vi.spyOn(window, "dispatchEvent")

    emitScriptStatUpdate("heal-bot", {
      viewCount: 3,
      copyCount: 1,
      downloadCount: 2,
    })

    expect(dispatchSpy).toHaveBeenCalledTimes(1)
    const event = dispatchSpy.mock.calls[0]?.[0] as CustomEvent
    expect(event.type).toBe(SCRIPT_STAT_UPDATED_EVENT)
    expect(event.detail).toEqual({
      slug: "heal-bot",
      stats: {
        viewCount: 3,
        copyCount: 1,
        downloadCount: 2,
      },
    })
  })
})
