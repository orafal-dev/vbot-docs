import { afterEach, describe, expect, it, vi } from "vitest"

describe("env helpers", () => {
  afterEach(() => {
    vi.resetModules()
    vi.unstubAllEnvs()
  })

  it("enables demo data during production builds", async () => {
    vi.stubEnv("NEXT_PHASE", "phase-production-build")
    vi.stubEnv("NODE_ENV", "production")

    const { canUseDemoData, isProductionBuild } = await import("./env")

    expect(isProductionBuild).toBe(true)
    expect(canUseDemoData).toBe(true)
  })

  it("enables demo data in development when explicitly allowed", async () => {
    vi.stubEnv("NEXT_PHASE", "")
    vi.stubEnv("NODE_ENV", "development")
    vi.stubEnv("VBOT_ALLOW_DEMO_DATA", "true")

    const { canUseDemoData } = await import("./env")

    expect(canUseDemoData).toBe(true)
  })

  it("requires auth environment values at runtime", async () => {
    vi.stubEnv("BETTER_AUTH_URL", "https://example.test")
    vi.stubEnv("BETTER_AUTH_SECRET", "secret")
    vi.stubEnv("DISCORD_CLIENT_ID", "discord-id")
    vi.stubEnv("DISCORD_CLIENT_SECRET", "discord-secret")

    const { getAuthEnvironment } = await import("./env")

    expect(getAuthEnvironment()).toEqual({
      baseURL: "https://example.test",
      secret: "secret",
      discordClientId: "discord-id",
      discordClientSecret: "discord-secret",
    })
  })

  it("throws when an auth environment value is missing", async () => {
    vi.stubEnv("BETTER_AUTH_URL", "")
    vi.stubEnv("BETTER_AUTH_SECRET", "secret")
    vi.stubEnv("DISCORD_CLIENT_ID", "discord-id")
    vi.stubEnv("DISCORD_CLIENT_SECRET", "discord-secret")

    const { getAuthEnvironment } = await import("./env")

    expect(() => getAuthEnvironment()).toThrow(/BETTER_AUTH_URL/)
  })
})
