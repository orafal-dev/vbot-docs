import { fireEvent, render, screen, waitFor } from "@testing-library/react"
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest"

const { trackScriptStatMock, emitScriptStatUpdateMock } = vi.hoisted(() => ({
  trackScriptStatMock: vi.fn(),
  emitScriptStatUpdateMock: vi.fn(),
}))

vi.mock("@/lib/track-script-stat", () => ({
  trackScriptStat: trackScriptStatMock,
}))

vi.mock("@/lib/script-stat-events", () => ({
  emitScriptStatUpdate: emitScriptStatUpdateMock,
}))

import { CodeActions } from "./code-actions"

describe("CodeActions", () => {
  let writeTextSpy: ReturnType<typeof vi.spyOn>
  let createObjectURLSpy: ReturnType<typeof vi.spyOn>
  let revokeObjectURLSpy: ReturnType<typeof vi.spyOn>

  beforeEach(() => {
    trackScriptStatMock.mockResolvedValue({
      viewCount: 1,
      copyCount: 2,
      downloadCount: 3,
    })
    emitScriptStatUpdateMock.mockClear()

    if (!navigator.clipboard) {
      Object.defineProperty(navigator, "clipboard", {
        configurable: true,
        value: {
          writeText: async () => undefined,
        },
      })
    }

    writeTextSpy = vi
      .spyOn(navigator.clipboard, "writeText")
      .mockResolvedValue(undefined)
    createObjectURLSpy = vi
      .spyOn(URL, "createObjectURL")
      .mockReturnValue("blob:mock-url")
    revokeObjectURLSpy = vi
      .spyOn(URL, "revokeObjectURL")
      .mockImplementation(() => undefined)
  })

  afterEach(() => {
    writeTextSpy.mockRestore()
    createObjectURLSpy.mockRestore()
    revokeObjectURLSpy.mockRestore()
  })

  it("copies code and tracks the copy event", async () => {
    render(
      <CodeActions
        code="print('hello')"
        filename="heal-bot.lua"
        scriptSlug="heal-bot"
      />
    )

    fireEvent.click(screen.getByRole("button", { name: /^copy$/i }))

    await waitFor(() => {
      expect(writeTextSpy).toHaveBeenCalledWith("print('hello')")
    })
    expect(await screen.findByRole("button", { name: /^copied$/i })).toBeInTheDocument()
    await waitFor(() => {
      expect(trackScriptStatMock).toHaveBeenCalledWith("heal-bot", "copy")
      expect(emitScriptStatUpdateMock).toHaveBeenCalled()
    })
  })

  it("downloads code and tracks the download event", async () => {
    const clickSpy = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(() => undefined)

    render(
      <CodeActions
        code="print('hello')"
        filename="heal-bot.lua"
        scriptSlug="heal-bot"
      />
    )

    fireEvent.click(screen.getByRole("button", { name: /^download$/i }))

    expect(createObjectURLSpy).toHaveBeenCalled()
    expect(clickSpy).toHaveBeenCalled()
    await waitFor(() => {
      expect(trackScriptStatMock).toHaveBeenCalledWith("heal-bot", "download")
    })

    clickSpy.mockRestore()
  })

  it("shows an alert when clipboard access fails", async () => {
    writeTextSpy.mockRejectedValueOnce(new Error("denied"))

    render(
      <CodeActions
        code="print('hello')"
        filename="heal-bot.lua"
        scriptSlug="heal-bot"
      />
    )

    fireEvent.click(screen.getByRole("button", { name: /^copy$/i }))

    expect(await screen.findByRole("alert")).toHaveTextContent(
      /clipboard access failed/i
    )
  })
})
