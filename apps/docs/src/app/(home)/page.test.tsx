import { render, screen } from "@testing-library/react"
import { describe, expect, it, vi } from "vitest"

vi.mock("next/link", () => ({
  default: ({
    href,
    children,
    ...props
  }: {
    href: string
    children: React.ReactNode
    className?: string
  }) => (
    <a href={href} {...props}>
      {children}
    </a>
  ),
}))

import HomePage from "./page"

describe("HomePage", () => {
  it("renders the docs hero and primary navigation links", () => {
    render(<HomePage />)

    expect(
      screen.getByRole("heading", { name: "ValidusBot Scripting Docs" })
    ).toBeInTheDocument()
    expect(
      screen.getByText(/comprehensive documentation for writing lua scripts/i)
    ).toBeInTheDocument()

    const getStarted = screen.getByRole("link", { name: "Get started" })
    const apiReference = screen.getByRole("link", { name: "API Reference" })

    expect(getStarted).toHaveAttribute("href", "/docs")
    expect(apiReference).toHaveAttribute("href", "/docs/api-reference")
  })
})
