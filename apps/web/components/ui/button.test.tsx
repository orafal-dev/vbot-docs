import { render, screen } from "@testing-library/react"
import userEvent from "@testing-library/user-event"
import { describe, expect, it, vi } from "vitest"

import { Button } from "./button"

describe("Button", () => {
  it("renders children and handles clicks", async () => {
    const user = userEvent.setup()
    const handleClick = vi.fn()

    render(
      <Button type="button" onClick={handleClick}>
        Save script
      </Button>
    )

    await user.click(screen.getByRole("button", { name: "Save script" }))
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  it("respects the disabled state", async () => {
    const user = userEvent.setup()
    const handleClick = vi.fn()

    render(
      <Button type="button" disabled onClick={handleClick}>
        Save script
      </Button>
    )

    await user.click(screen.getByRole("button", { name: "Save script" }))
    expect(handleClick).not.toHaveBeenCalled()
  })
})
