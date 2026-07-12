"use client"

import { useEffect, useState } from "react"
import { IconCopy, IconDownload, IconEye } from "@tabler/icons-react"

import { formatStatCount } from "@/lib/format-stat-count"
import {
  SCRIPT_STAT_UPDATED_EVENT,
  type ScriptStatUpdatedDetail,
} from "@/lib/script-stat-events"
import type { ScriptStats as ScriptStatsData } from "@/lib/script-stats.types"
import { trackScriptStat } from "@/lib/track-script-stat"
import type { ScriptStatsProps } from "./script-stats.types"

const emptyStats: ScriptStatsData = {
  viewCount: 0,
  copyCount: 0,
  downloadCount: 0,
}

export const ScriptStats = ({ scriptSlug }: ScriptStatsProps) => {
  const [stats, setStats] = useState<ScriptStatsData>(emptyStats)
  const [isLoaded, setIsLoaded] = useState(false)

  useEffect(() => {
    let isMounted = true

    const loadStats = async () => {
      try {
        const response = await fetch(
          `/api/scripts/${encodeURIComponent(scriptSlug)}/stats`
        )

        if (response.ok) {
          const nextStats = (await response.json()) as ScriptStatsData

          if (isMounted) {
            setStats(nextStats)
          }
        }
      } catch {
        // Keep zeroed fallback stats when the API is unavailable.
      } finally {
        if (isMounted) {
          setIsLoaded(true)
        }
      }
    }

    const trackView = async () => {
      const nextStats = await trackScriptStat(scriptSlug, "view")

      if (nextStats && isMounted) {
        setStats(nextStats)
      }
    }

    void loadStats().then(() => trackView())

    const handleStatUpdate = (event: Event) => {
      const { detail } = event as CustomEvent<ScriptStatUpdatedDetail>

      if (detail?.slug === scriptSlug && detail.stats) {
        setStats(detail.stats)
      }
    }

    window.addEventListener(SCRIPT_STAT_UPDATED_EVENT, handleStatUpdate)

    return () => {
      isMounted = false
      window.removeEventListener(SCRIPT_STAT_UPDATED_EVENT, handleStatUpdate)
    }
  }, [scriptSlug])

  if (!isLoaded) {
    return (
      <span
        aria-hidden="true"
        className="inline-flex h-5 w-40 animate-pulse rounded bg-muted"
      />
    )
  }

  return (
    <div
      className="flex flex-wrap items-center gap-4"
      aria-label="Script usage statistics"
    >
      <span className="inline-flex items-center gap-1.5" title="Views">
        <IconEye className="size-4" aria-hidden="true" />
        <span>{formatStatCount(stats.viewCount)} views</span>
      </span>
      <span className="inline-flex items-center gap-1.5" title="Copies">
        <IconCopy className="size-4" aria-hidden="true" />
        <span>{formatStatCount(stats.copyCount)} copies</span>
      </span>
      <span className="inline-flex items-center gap-1.5" title="Downloads">
        <IconDownload className="size-4" aria-hidden="true" />
        <span>{formatStatCount(stats.downloadCount)} downloads</span>
      </span>
    </div>
  )
}
