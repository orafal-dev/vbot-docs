import { cache } from "react"
import { and, desc, eq, ilike, or, sql } from "drizzle-orm"

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
    tags: ["alerts"],
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
    tags: ["utility"],
    viewCount: 256,
    copyCount: 87,
    downloadCount: 31,
    demo: true,
  },
  {
    id: "demo-stamina-waypoint",
    slug: "cavebot-stamina-label-check",
    title: "Cavebot stamina label check",
    description:
      "Cavebot script waypoint that jumps to a refill or train label when stamina is below or above a minute threshold.",
    code: `local MIN_STAMINA_MINUTES = 16 * 60
local MAX_STAMINA_MINUTES = nil
local LOW_STAMINA_LABEL = "refill"
local HIGH_STAMINA_LABEL = "train"

local stamina = Self.GetStamina()
if type(stamina) ~= "number" then
  Cavebot.Walker.Resume()
  return
end

if stamina < MIN_STAMINA_MINUTES then
  Cavebot.GoTo(LOW_STAMINA_LABEL)
  Cavebot.Walker.Resume()
  return
end

if type(MAX_STAMINA_MINUTES) == "number" and type(HIGH_STAMINA_LABEL) == "string" and stamina > MAX_STAMINA_MINUTES then
  Cavebot.GoTo(HIGH_STAMINA_LABEL)
  Cavebot.Walker.Resume()
  return
end

Cavebot.Walker.Resume()`,
    status: "published", published: true, authorId: "demo", authorName: "ValidusBot",
    createdAt: new Date("2026-03-12T12:00:00.000Z"),
    updatedAt: new Date("2026-08-16T12:00:00.000Z"),
    publishedAt: new Date("2026-08-16T12:00:00.000Z"),
    screenshots: [],
    tags: ["cavebot-snippet"],
    viewCount: 64,
    copyCount: 21,
    downloadCount: 11,
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
  tags: scripts.tags,
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
  tags: scripts.tags,
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
  tags: script.tags,
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
  tag,
}: ScriptSearch = {}): Promise<ScriptSummary[]> => {
  const parsedSearch = publicScriptSearchSchema.safeParse({ query, tag })

  if (!parsedSearch.success) {
    return []
  }

  const normalizedQuery = parsedSearch.data.query?.toLowerCase()
  const selectedTag = parsedSearch.data.tag

  if (!hasDatabase) {
    if (!canUseDemoData) {
      requireDb()
    }

    return demoScripts
      .map(toScriptSummary)
      .filter((script) => {
        const matchesQuery = normalizedQuery
          ? `${script.title} ${script.description}`
              .toLowerCase()
              .includes(normalizedQuery)
          : true
        const matchesTag = selectedTag ? script.tags.includes(selectedTag) : true
        return matchesQuery && matchesTag
      })
  }

  const escapedQuery = normalizedQuery
    ? escapeLikePattern(normalizedQuery)
    : undefined

  return requireDb()
    .select(scriptSummarySelection)
    .from(scripts)
    .innerJoin(user, eq(scripts.authorId, user.id))
    .where(
      and(
        eq(scripts.published, true),
        selectedTag
          ? sql`${scripts.tags} @> ARRAY[${selectedTag}]::text[]`
          : undefined,
        escapedQuery
          ? or(
              ilike(scripts.title, `%${escapedQuery}%`),
              ilike(scripts.description, `%${escapedQuery}%`)
            )
          : undefined
      )
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
