import { PHASE_PRODUCTION_BUILD } from "next/constants"

import type { AuthEnvironment } from "./env.types"

export const isProductionBuild =
  process.env.NEXT_PHASE === PHASE_PRODUCTION_BUILD

export const canUseDemoData =
  isProductionBuild ||
  (process.env.NODE_ENV === "development" &&
    process.env.VBOT_ALLOW_DEMO_DATA === "true")

const requireEnvironmentValue = (name: string) => {
  const value = process.env[name]?.trim()

  if (!value) {
    throw new Error(
      `${name} is required at runtime. Build-only fallback values are never used by the production server.`
    )
  }

  return value
}

const toOrigin = (value: string) => {
  try {
    return new URL(value).origin
  } catch {
    return null
  }
}

const getTrustedOrigins = (baseURL: string) => {
  const origins = new Set<string>()
  const baseOrigin = toOrigin(baseURL)

  if (baseOrigin) {
    origins.add(baseOrigin)
  }

  const extraOrigins = process.env.BETTER_AUTH_TRUSTED_ORIGINS
  if (extraOrigins) {
    for (const origin of extraOrigins.split(",")) {
      const parsedOrigin = toOrigin(origin.trim())
      if (parsedOrigin) {
        origins.add(parsedOrigin)
      }
    }
  }

  if (process.env.NODE_ENV === "development") {
    origins.add("http://localhost:3000")
    origins.add("http://localhost:3024")
  }

  return [...origins]
}

export const getAuthEnvironment = (): AuthEnvironment => {
  const baseURL = requireEnvironmentValue("BETTER_AUTH_URL")

  return {
    baseURL,
    secret: requireEnvironmentValue("BETTER_AUTH_SECRET"),
    discordClientId: requireEnvironmentValue("DISCORD_CLIENT_ID"),
    discordClientSecret: requireEnvironmentValue("DISCORD_CLIENT_SECRET"),
    trustedOrigins: getTrustedOrigins(baseURL),
  }
}
