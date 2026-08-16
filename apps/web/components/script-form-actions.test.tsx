import { render, screen } from "@testing-library/react"
import { beforeEach, describe, expect, it, vi } from "vitest"

const { useFormStatusMock } = vi.hoisted(() => ({
  useFormStatusMock: vi.fn(() => ({ pending: false })),
}))

vi.mock("react-dom", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react-dom")>()

  return {
    ...actual,
    useFormStatus: useFormStatusMock,
  }
})

import { ScriptFormActions } from "./script-form-actions"

const renderActions = (mode: "create" | "edit") =>
  render(
    <form>
      <ScriptFormActions mode={mode} />
    </form>
  )

describe("ScriptFormActions", () => {
  beforeEach(() => {
    useFormStatusMock.mockReturnValue({ pending: false })
  })

  it("shows Create and Cancel when adding a script", () => {
    renderActions("create")

    expect(
      screen.getByRole("toolbar", { name: "Script form actions" })
    ).toBeInTheDocument()
    expect(screen.getByRole("button", { name: "Create" })).toBeEnabled()
    expect(
      screen.getByRole("link", { name: "Cancel and return to the admin dashboard" })
    ).toHaveAttribute("href", "/admin")
  })

  it("shows Save and Cancel when editing a script", () => {
    renderActions("edit")

    expect(screen.getByRole("button", { name: "Save" })).toBeEnabled()
    expect(
      screen.getByRole("link", { name: "Cancel and return to the admin dashboard" })
    ).toBeInTheDocument()
  })

  it("disables Save and shows the pending label while submitting", () => {
    useFormStatusMock.mockReturnValue({ pending: true })

    renderActions("edit")

    const button = screen.getByRole("button", { name: "Saving…" })
    expect(button).toBeDisabled()
    expect(button).toHaveAttribute("aria-disabled", "true")
  })
})
