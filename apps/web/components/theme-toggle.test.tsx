import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { beforeEach, describe, expect, it, vi } from "vitest"

const { setThemeMock, useThemeMock } = vi.hoisted(() => {
  const setThemeMock = vi.fn()
  const useThemeMock = vi.fn(() => ({
    resolvedTheme: "light",
    setTheme: setThemeMock,
  }))

  return { setThemeMock, useThemeMock }
})

vi.mock("next-themes", () => ({
  useTheme: useThemeMock,
}))

import { ThemeToggle } from "./theme-toggle"

describe("ThemeToggle", () => {
  beforeEach(() => {
    setThemeMock.mockClear()
    useThemeMock.mockReturnValue({
      resolvedTheme: "light",
      setTheme: setThemeMock,
    })
  })

  it("toggles from light to dark", async () => {
    const user = userEvent.setup()

    render(<ThemeToggle />)

    await user.click(
      screen.getByRole("button", { name: "Switch from light to dark theme" })
    )

    expect(setThemeMock).toHaveBeenCalledWith("dark")
  })

  it("toggles from dark to light", async () => {
    useThemeMock.mockReturnValue({
      resolvedTheme: "dark",
      setTheme: setThemeMock,
    })
    const user = userEvent.setup()

    render(<ThemeToggle />)

    await user.click(
      screen.getByRole("button", { name: "Switch from dark to light theme" })
    )

    expect(setThemeMock).toHaveBeenCalledWith("light")
  })
})
