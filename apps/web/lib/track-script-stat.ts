import type { ScriptStatType, ScriptStats } from "@/lib/script-stats.types"

const sessionViewKey = (slug: string) => `vbot:script-view:${slug}`

const hasTrackedViewInSession = (slug: string) => {
  if (typeof sessionStorage === "undefined") {
    return false
  }

  return sessionStorage.getItem(sessionViewKey(slug)) === "1"
}

const markViewTrackedInSession = (slug: string) => {
  if (typeof sessionStorage === "undefined") {
    return
  }

  sessionStorage.setItem(sessionViewKey(slug), "1")
}

export const trackScriptStat = async (
  slug: string,
  type: ScriptStatType
): Promise<ScriptStats | null> => {
  if (type === "view" && hasTrackedViewInSession(slug)) {
    return null
  }

  const url = `/api/scripts/${encodeURIComponent(slug)}/events`

  try {
    const response = await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ type }),
    })

    if (!response.ok) {
      return null
    }

    const stats = (await response.json()) as ScriptStats

    if (type === "view") {
      markViewTrackedInSession(slug)
    }

    return stats
  } catch {
    return null
  }
}
