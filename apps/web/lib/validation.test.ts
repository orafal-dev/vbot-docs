import { describe, expect, it } from "vitest"

import {
  generateSlug,
  invitationFormSchema,
  publicScriptSearchSchema,
  scriptFormSchema,
  scriptSlugParamSchema,
  scriptStatEventSchema,
} from "./validation"

describe("generateSlug", () => {
  it("normalizes titles into URL-safe slugs", () => {
    expect(generateSlug("  Heal Bot Pro  ")).toBe("heal-bot-pro")
    expect(generateSlug("Café Autómata")).toBe("cafe-automata")
    expect(generateSlug("A!!!B___C")).toBe("a-b-c")
  })

  it("trims length to 80 characters", () => {
    expect(generateSlug("a".repeat(100))).toHaveLength(80)
  })
})

describe("scriptFormSchema", () => {
  const validInput = {
    title: "Heal Bot",
    slug: "Heal Bot",
    description: "A reliable healing helper for everyday hunting sessions.",
    code: "Module.Every('heal', function() end, 200)",
    screenshots: JSON.stringify(["scripts/demo/shot.png"]),
    published: true,
  }

  it("accepts valid script form data and normalizes the slug", () => {
    const result = scriptFormSchema.safeParse(validInput)

    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.slug).toBe("heal-bot")
      expect(result.data.screenshots).toEqual(["scripts/demo/shot.png"])
      expect(result.data.tags).toEqual([])
    }
  })

  it("rejects short descriptions and invalid screenshots", () => {
    const result = scriptFormSchema.safeParse({
      ...validInput,
      description: "too short",
      screenshots: JSON.stringify(["https://example.com/x.png"]),
    })

    expect(result.success).toBe(false)
  })

  it("accepts catalog tags and rejects unknown tags", () => {
    const accepted = scriptFormSchema.safeParse({
      ...validInput,
      tags: ["cavebot-snippet", "alerts"],
    })
    const rejected = scriptFormSchema.safeParse({
      ...validInput,
      tags: ["unknown"],
    })

    expect(accepted.success).toBe(true)
    if (accepted.success) {
      expect(accepted.data.tags).toEqual(["cavebot-snippet", "alerts"])
    }
    expect(rejected.success).toBe(false)
  })
})

describe("invitationFormSchema", () => {
  it("lowercases and validates emails", () => {
    const result = invitationFormSchema.safeParse({ email: "  Admin@Example.COM " })

    expect(result.success).toBe(true)
    if (result.success) {
      expect(result.data.email).toBe("admin@example.com")
    }
  })

  it("rejects invalid emails", () => {
    expect(invitationFormSchema.safeParse({ email: "not-an-email" }).success).toBe(
      false
    )
  })
})

describe("publicScriptSearchSchema", () => {
  it("allows optional trimmed queries", () => {
    expect(publicScriptSearchSchema.safeParse({}).success).toBe(true)
    expect(publicScriptSearchSchema.safeParse({ query: "  heal  " }).success).toBe(
      true
    )
    expect(
      publicScriptSearchSchema.safeParse({ tag: "cavebot-snippet" }).success
    ).toBe(true)
  })

  it("rejects overly long queries", () => {
    expect(
      publicScriptSearchSchema.safeParse({ query: "x".repeat(101) }).success
    ).toBe(false)
    expect(
      publicScriptSearchSchema.safeParse({ tag: "not-a-catalog-tag" }).success
    ).toBe(false)
  })
})

describe("scriptSlugParamSchema", () => {
  it("accepts valid slugs", () => {
    expect(scriptSlugParamSchema.safeParse({ slug: "heal-bot" }).success).toBe(
      true
    )
  })

  it("rejects invalid slugs", () => {
    expect(scriptSlugParamSchema.safeParse({ slug: "AB" }).success).toBe(false)
    expect(scriptSlugParamSchema.safeParse({ slug: "Bad_Slug" }).success).toBe(
      false
    )
  })
})

describe("scriptStatEventSchema", () => {
  it("accepts known event types", () => {
    expect(scriptStatEventSchema.safeParse({ type: "view" }).success).toBe(true)
    expect(scriptStatEventSchema.safeParse({ type: "copy" }).success).toBe(true)
    expect(scriptStatEventSchema.safeParse({ type: "download" }).success).toBe(
      true
    )
  })

  it("rejects unknown event types", () => {
    expect(scriptStatEventSchema.safeParse({ type: "share" }).success).toBe(false)
  })
})
