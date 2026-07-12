import { cache } from "react"
import { and, desc, eq, ilike, or } from "drizzle-orm"

import { hasDatabase, requireDb } from "@/lib/db"
import { scripts, user } from "@/lib/db/schema"
import { canUseDemoData } from "@/lib/env"
import { publicScriptSearchSchema } from "@/lib/validation"
import type {
  ScriptRecord,
  ScriptSearch,
  ScriptSummary,
} from "./scripts.types"

// Build-only fallback: used exclusively when DATABASE_URL is absent.
const demoScripts: ScriptRecord[] = [
  {
    id: "demo-low-health",
    slug: "low-health-sound-alert",
    title: "Low Health Sound Alert",
    description: "Plays a warning sound when your character drops below a safe health threshold.",
    code: `local SCRIPT_ID = "low_health_alert"\n\nModule.Every(SCRIPT_ID .. "_tick", function()\n  if not Self.IsAvailable() then\n    return\n  end\n\n  local hp = Self.GetHealthPercentage()\n  if type(hp) == "number" and hp <= 35 then\n    Sound.Play({ sound_id = BotSoundId.LOW_HEALTH })\n  end\nend, 1000)`,
    status: "published", published: true, authorId: "demo", authorName: "ValidusBot",
    createdAt: new Date("2026-01-10T12:00:00.000Z"),
    updatedAt: new Date("2026-04-18T12:00:00.000Z"),
    publishedAt: new Date("2026-04-18T12:00:00.000Z"),
    screenshots: [],
    viewCount: 128,
    copyCount: 42,
    downloadCount: 19,
    demo: true,
  },
  {
    id: "demo-monster-scan",
    slug: "visible-monster-scanner",
    title: "Visible Monster Scanner",
    description: "Reports visible monsters using canonical creature wrappers.",
    code: `local SCRIPT_ID = "monster_scanner"\n\nModule.Every(SCRIPT_ID .. "_scan", function()\n  local player = Creature.GetLocalPlayer()\n  if not player then\n    return\n  end\n\n  for _, monster in ipairs(Creatures.GetVisibleMonsters(true)) do\n    if monster:IsValid() then\n      print(monster:ToString())\n    end\n  end\nend, 1000)`,
    status: "published", published: true, authorId: "demo", authorName: "ValidusBot",
    createdAt: new Date("2026-02-02T12:00:00.000Z"),
    updatedAt: new Date("2026-05-01T12:00:00.000Z"),
    publishedAt: new Date("2026-05-01T12:00:00.000Z"),
    screenshots: [],
    viewCount: 256,
    copyCount: 87,
    downloadCount: 31,
    demo: true,
  },
]

const scriptSelection = {
  id: scripts.id,
  slug: scripts.slug,
  title: scripts.title,
  description: scripts.description,
  code: scripts.code,
  screenshots: scripts.screenshots,
  status: scripts.status,
  published: scripts.published,
  authorId: scripts.authorId,
  authorName: user.name,
  createdAt: scripts.createdAt,
  updatedAt: scripts.updatedAt,
  publishedAt: scripts.publishedAt,
  viewCount: scripts.viewCount,
  copyCount: scripts.copyCount,
  downloadCount: scripts.downloadCount,
}

const scriptSummarySelection = {
  id: scripts.id,
  slug: scripts.slug,
  title: scripts.title,
  description: scripts.description,
  screenshots: scripts.screenshots,
  published: scripts.published,
  authorId: scripts.authorId,
  authorName: user.name,
  createdAt: scripts.createdAt,
  updatedAt: scripts.updatedAt,
  publishedAt: scripts.publishedAt,
  viewCount: scripts.viewCount,
  copyCount: scripts.copyCount,
  downloadCount: scripts.downloadCount,
}

const toScriptSummary = (script: ScriptRecord): ScriptSummary => ({
  id: script.id,
  slug: script.slug,
  title: script.title,
  description: script.description,
  screenshots: script.screenshots,
  published: script.published,
  authorId: script.authorId,
  authorName: script.authorName,
  createdAt: script.createdAt,
  updatedAt: script.updatedAt,
  publishedAt: script.publishedAt,
  viewCount: script.viewCount,
  copyCount: script.copyCount,
  downloadCount: script.downloadCount,
  demo: script.demo,
})

const escapeLikePattern = (value: string) =>
  value.replace(/[\\%_]/g, (character) => `\\${character}`)

export const getPublishedScripts = async ({
  query,
}: ScriptSearch = {}): Promise<ScriptSummary[]> => {
  const parsedSearch = publicScriptSearchSchema.safeParse({ query })

  if (!parsedSearch.success) {
    return []
  }

  const normalizedQuery = parsedSearch.data.query?.toLowerCase()

  if (!hasDatabase) {
    if (!canUseDemoData) {
      requireDb()
    }

    const summaries = demoScripts.map(toScriptSummary)
    return normalizedQuery
      ? summaries.filter((script) =>
          `${script.title} ${script.description}`
            .toLowerCase()
            .includes(normalizedQuery)
        )
      : summaries
  }

  const escapedQuery = normalizedQuery
    ? escapeLikePattern(normalizedQuery)
    : undefined

  return requireDb()
    .select(scriptSummarySelection)
    .from(scripts)
    .innerJoin(user, eq(scripts.authorId, user.id))
    .where(
      escapedQuery
        ? and(
            eq(scripts.published, true),
            or(
              ilike(scripts.title, `%${escapedQuery}%`),
              ilike(scripts.description, `%${escapedQuery}%`)
            )
          )
        : eq(scripts.published, true)
    )
    .orderBy(desc(scripts.publishedAt), desc(scripts.updatedAt))
    .limit(50)
}

export const getPublishedScriptSlugs = cache(async (): Promise<string[]> => {
  if (!hasDatabase) {
    if (!canUseDemoData) {
      requireDb()
    }

    return demoScripts.map((script) => script.slug)
  }

  const rows = await requireDb()
    .select({ slug: scripts.slug })
    .from(scripts)
    .where(eq(scripts.published, true))

  return rows.map((row) => row.slug)
})

export const getPublishedScriptBySlug = cache(async (slug: string) => {
  if (!hasDatabase) {
    if (!canUseDemoData) {
      requireDb()
    }

    return demoScripts.find((script) => script.slug === slug) ?? null
  }

  const [script] = await requireDb()
    .select(scriptSelection)
    .from(scripts)
    .innerJoin(user, eq(scripts.authorId, user.id))
    .where(and(eq(scripts.slug, slug), eq(scripts.published, true)))
    .limit(1)

  return script ?? null
})

export const getAllScriptsForAdmin = async () =>
  requireDb()
    .select(scriptSelection)
    .from(scripts)
    .innerJoin(user, eq(scripts.authorId, user.id))
    .orderBy(desc(scripts.updatedAt))

export const getScriptForAdmin = async (id: string) => {
  const [script] = await requireDb()
    .select(scriptSelection)
    .from(scripts)
    .innerJoin(user, eq(scripts.authorId, user.id))
    .where(eq(scripts.id, id))
    .limit(1)

  return script ?? null
}
