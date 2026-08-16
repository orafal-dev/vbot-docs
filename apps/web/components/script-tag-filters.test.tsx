import { render, screen } from "@testing-library/react"
import { describe, expect, it } from "vitest"

import { ScriptTagFilters } from "./script-tag-filters"

describe("ScriptTagFilters", () => {
  it("marks the selected tag filter as current and preserves search", () => {
    render(<ScriptTagFilters query="stamina" selectedTag="cavebot-snippet" />)

    expect(screen.getByRole("navigation", { name: "Filter scripts by tag" })).toBeInTheDocument()
    expect(screen.getByRole("link", { name: "All" })).toHaveAttribute("href", "/?q=stamina")
    expect(screen.getByRole("link", { name: "Filter by Cavebot snippet" })).toHaveAttribute(
      "aria-current",
      "true"
    )
    expect(screen.getByRole("link", { name: "Filter by Cavebot snippet" })).toHaveAttribute(
      "href",
      "/?q=stamina&tag=cavebot-snippet"
    )
  })
})
