import { describe, expect, it } from "vitest"

import { baseOptions } from "./layout.shared"

describe("baseOptions", () => {
  it("builds fumadocs layout options from shared config", () => {
    expect(baseOptions()).toEqual({
      nav: {
        title: "ValidusBot Docs",
      },
      githubUrl: "https://github.com/orafal-dev/vbot-docs",
    })
  })
})
