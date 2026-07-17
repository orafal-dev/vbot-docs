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

import { PendingSubmitButton } from "./pending-submit-button"

describe("PendingSubmitButton", () => {
  beforeEach(() => {
    useFormStatusMock.mockReturnValue({ pending: false })
  })

  it("shows the idle label when the form is idle", () => {
    render(<PendingSubmitButton idleLabel="Create script" />)

    expect(screen.getByRole("button", { name: "Create script" })).toBeEnabled()
  })

  it("shows the pending label and disables while submitting", () => {
    useFormStatusMock.mockReturnValue({ pending: true })

    render(
      <PendingSubmitButton idleLabel="Create script" pendingLabel="Creating…" />
    )

    const button = screen.getByRole("button", { name: "Creating…" })
    expect(button).toBeDisabled()
    expect(button).toHaveAttribute("aria-disabled", "true")
  })
})
