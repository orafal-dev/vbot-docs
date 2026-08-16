import type { scripts } from "@/lib/db/schema"

type ScriptRow = typeof scripts.$inferSelect
type PublicScriptFields = Pick<
  ScriptRow,
  | "id"
  | "slug"
  | "title"
  | "description"
  | "screenshots"
  | "tags"
  | "published"
  | "authorId"
  | "createdAt"
  | "updatedAt"
  | "publishedAt"
  | "viewCount"
  | "copyCount"
  | "downloadCount"
>

export type ScriptRecord = ScriptRow & {
  authorName: string
  demo?: boolean
}

export type ScriptSummary = PublicScriptFields & {
  authorName: string
  demo?: boolean
}

export type ScriptSearch = {
  query?: unknown
  tag?: unknown
}
