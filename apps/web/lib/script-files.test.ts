import { describe, expect, it } from "vitest"

import {
  DEFAULT_SCRIPT_FILENAME,
  getPrimaryScriptCode,
  normalizeScriptFiles,
  toScriptFilename,
} from "./script-files"

describe("toScriptFilename", () => {
  it("falls back to main.lua when slug is missing", () => {
    expect(toScriptFilename()).toBe(DEFAULT_SCRIPT_FILENAME)
    expect(toScriptFilename("")).toBe(DEFAULT_SCRIPT_FILENAME)
  })

  it("appends .lua when needed", () => {
    expect(toScriptFilename("heal-bot")).toBe("heal-bot.lua")
    expect(toScriptFilename("heal-bot.lua")).toBe("heal-bot.lua")
  })
})

describe("normalizeScriptFiles", () => {
  it("uses the files array when present", () => {
    expect(
      normalizeScriptFiles({
        code: "print('legacy')",
        files: [
          { name: "main.lua", code: "print('main')" },
          { name: "helpers.lua", code: "print('helpers')" },
        ],
      })
    ).toEqual([
      { name: "main.lua", code: "print('main')" },
      { name: "helpers.lua", code: "print('helpers')" },
    ])
  })

  it("falls back to code with a slug-based filename for legacy scripts", () => {
    expect(
      normalizeScriptFiles({
        code: "print('legacy')",
        files: [],
        slug: "low-health-alert",
      })
    ).toEqual([{ name: "low-health-alert.lua", code: "print('legacy')" }])
  })
})

describe("getPrimaryScriptCode", () => {
  it("returns the first file code", () => {
    expect(
      getPrimaryScriptCode([
        { name: "a.lua", code: "print(1)" },
        { name: "b.lua", code: "print(2)" },
      ])
    ).toBe("print(1)")
  })

  it("returns the fallback when empty", () => {
    expect(getPrimaryScriptCode([], "fallback")).toBe("fallback")
  })
})
