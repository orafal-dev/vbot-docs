import { PHASE_PRODUCTION_BUILD } from "next/constants"

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

export const getAuthEnvironment = () => {
  return {
    baseURL: requireEnvironmentValue("BETTER_AUTH_URL"),
    secret: requireEnvironmentValue("BETTER_AUTH_SECRET"),
    discordClientId: requireEnvironmentValue("DISCORD_CLIENT_ID"),
    discordClientSecret: requireEnvironmentValue("DISCORD_CLIENT_SECRET"),
  }
}
