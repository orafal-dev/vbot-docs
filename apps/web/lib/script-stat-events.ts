import type { ScriptStats } from "@/lib/script-stats.types"

export const SCRIPT_STAT_UPDATED_EVENT = "vbot:script-stat-updated"

export type ScriptStatUpdatedDetail = {
  slug: string
  stats: ScriptStats
}

export const emitScriptStatUpdate = (slug: string, stats: ScriptStats) => {
  if (typeof window === "undefined") {
    return
  }

  window.dispatchEvent(
    new CustomEvent<ScriptStatUpdatedDetail>(SCRIPT_STAT_UPDATED_EVENT, {
      detail: { slug, stats },
    })
  )
}
