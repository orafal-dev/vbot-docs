import { and, eq, sql } from "drizzle-orm"

import { hasDatabase, requireDb } from "@/lib/db"
import { scripts } from "@/lib/db/schema"
import type { ScriptStatType, ScriptStats } from "@/lib/script-stats.types"

const statsSelection = {
  viewCount: scripts.viewCount,
  copyCount: scripts.copyCount,
  downloadCount: scripts.downloadCount,
}

const incrementByType = {
  view: { viewCount: sql`${scripts.viewCount} + 1` },
  copy: { copyCount: sql`${scripts.copyCount} + 1` },
  download: { downloadCount: sql`${scripts.downloadCount} + 1` },
} as const

export const getScriptStatsBySlug = async (
  slug: string
): Promise<ScriptStats | null> => {
  if (!hasDatabase) {
    return null
  }

  const [row] = await requireDb()
    .select(statsSelection)
    .from(scripts)
    .where(and(eq(scripts.slug, slug), eq(scripts.published, true)))
    .limit(1)

  return row ?? null
}

export const incrementScriptStat = async (
  slug: string,
  type: ScriptStatType
): Promise<ScriptStats | null> => {
  if (!hasDatabase) {
    return null
  }

  const [row] = await requireDb()
    .update(scripts)
    .set(incrementByType[type])
    .where(and(eq(scripts.slug, slug), eq(scripts.published, true)))
    .returning(statsSelection)

  return row ?? null
}
