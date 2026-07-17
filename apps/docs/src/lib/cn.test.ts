import { describe, expect, it } from "vitest"

import { cn } from "./cn"

describe("cn", () => {
  it("merges class names through cnfast", () => {
    expect(cn("px-2", "py-1")).toContain("px-2")
    expect(cn("px-2", "py-1")).toContain("py-1")
  })

  it("handles conditional class values", () => {
    expect(cn("text-sm", false && "hidden", "font-medium")).toContain("text-sm")
    expect(cn("text-sm", false && "hidden", "font-medium")).toContain(
      "font-medium"
    )
  })
})
