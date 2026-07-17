import { describe, expect, it } from "vitest"

import {
  appName,
  docsContentRoute,
  docsImageRoute,
  docsRoute,
  gitConfig,
} from "./shared"

describe("shared docs constants", () => {
  it("exposes stable branding and route constants", () => {
    expect(appName).toBe("ValidusBot Docs")
    expect(docsRoute).toBe("/docs")
    expect(docsImageRoute).toBe("/og/docs")
    expect(docsContentRoute).toBe("/llms.mdx/docs")
  })

  it("points github metadata at the docs repository", () => {
    expect(gitConfig).toEqual({
      user: "orafal-dev",
      repo: "vbot-docs",
      branch: "main",
    })
  })
})
