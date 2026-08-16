export const SCRIPT_TAG_IDS = [
  "cavebot-snippet",
  "alerts",
  "hud",
  "utility",
] as const

export type ScriptTagId = (typeof SCRIPT_TAG_IDS)[number]

export type ScriptTagDefinition = {
  id: ScriptTagId
  label: string
  description: string
}

export type ScriptLibraryHrefInput = {
  query?: string
  tag?: string
}
