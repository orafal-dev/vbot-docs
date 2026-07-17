import { render, screen, waitFor } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

const { trackScriptStatMock } = vi.hoisted(() => ({
  trackScriptStatMock: vi.fn(),
}))

vi.mock("@/lib/track-script-stat", () => ({
  trackScriptStat: trackScriptStatMock,
}))

import { SCRIPT_STAT_UPDATED_EVENT } from "@/lib/script-stat-events"

import { ScriptStats } from "./script-stats"

describe("ScriptStats", () => {
  beforeEach(() => {
    trackScriptStatMock.mockResolvedValue({
      viewCount: 12,
      copyCount: 4,
      downloadCount: 2,
    })

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => ({
          viewCount: 10,
          copyCount: 3,
          downloadCount: 1,
        }),
      })
    )
  })

  it("loads stats, tracks a view, and renders counts", async () => {
    render(<ScriptStats scriptSlug="heal-bot" />)

    expect(document.querySelector("[aria-hidden='true']")).toBeInTheDocument()

    expect(
      await screen.findByLabelText("Script usage statistics")
    ).toBeInTheDocument()
    expect(screen.getByText("12 views")).toBeInTheDocument()
    expect(screen.getByText("4 copies")).toBeInTheDocument()
    expect(screen.getByText("2 downloads")).toBeInTheDocument()
    expect(trackScriptStatMock).toHaveBeenCalledWith("heal-bot", "view")
  })

  it("updates when a matching script-stat event is dispatched", async () => {
    render(<ScriptStats scriptSlug="heal-bot" />)

    await screen.findByLabelText("Script usage statistics")

    window.dispatchEvent(
      new CustomEvent(SCRIPT_STAT_UPDATED_EVENT, {
        detail: {
          slug: "heal-bot",
          stats: {
            viewCount: 99,
            copyCount: 8,
            downloadCount: 7,
          },
        },
      })
    )

    await waitFor(() => {
      expect(screen.getByText("99 views")).toBeInTheDocument()
      expect(screen.getByText("8 copies")).toBeInTheDocument()
      expect(screen.getByText("7 downloads")).toBeInTheDocument()
    })
  })
})
