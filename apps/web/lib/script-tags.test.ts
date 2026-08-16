import { describe, expect, it } from "vitest"

import {
  buildScriptLibraryHref,
  getScriptTagLabel,
  hasCavebotSnippetTag,
  isScriptTagId,
} from "./script-tags"

describe("isScriptTagId", () => {
  it("accepts catalog tags", () => {
    expect(isScriptTagId("cavebot-snippet")).toBe(true)
    expect(isScriptTagId("alerts")).toBe(true)
  })

  it("rejects unknown tags", () => {
    expect(isScriptTagId("unknown")).toBe(false)
  })
})

describe("getScriptTagLabel", () => {
  it("returns catalog labels and falls back to the raw id", () => {
    expect(getScriptTagLabel("cavebot-snippet")).toBe("Cavebot snippet")
    expect(getScriptTagLabel("custom")).toBe("custom")
  })
})

describe("hasCavebotSnippetTag", () => {
  it("detects the cavebot snippet tag", () => {
    expect(hasCavebotSnippetTag(["alerts", "cavebot-snippet"])).toBe(true)
    expect(hasCavebotSnippetTag(["hud"])).toBe(false)
  })
})

describe("buildScriptLibraryHref", () => {
  it("builds library URLs with optional query and tag", () => {
    expect(buildScriptLibraryHref({})).toBe("/")
    expect(buildScriptLibraryHref({ query: "stamina" })).toBe("/?q=stamina")
    expect(buildScriptLibraryHref({ tag: "cavebot-snippet" })).toBe(
      "/?tag=cavebot-snippet"
    )
    expect(
      buildScriptLibraryHref({ query: "stamina", tag: "cavebot-snippet" })
    ).toBe("/?q=stamina&tag=cavebot-snippet")
  })
})
