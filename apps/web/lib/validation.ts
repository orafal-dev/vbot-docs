import { z } from "zod"

export const generateSlug = (value: string) =>
  value.trim().toLowerCase().normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80)

const slugSchema = z.string().min(3, "Slug must be at least 3 characters.").max(80)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Use lowercase letters, numbers, and hyphens.")

export const MAX_SCRIPT_SCREENSHOTS = 6

const vercelBlobUrlSchema = z
  .string()
  .url()
  .max(2048)
  .regex(
    /^https:\/\/[a-z0-9-]+\.public\.blob\.vercel-storage\.com\/.+/i,
    "Screenshot URLs must be hosted on Vercel Blob."
  )

export const scriptScreenshotsSchema = z
  .array(vercelBlobUrlSchema)
  .max(MAX_SCRIPT_SCREENSHOTS, `At most ${MAX_SCRIPT_SCREENSHOTS} screenshots are allowed.`)

const parseScreenshotsField = (value: FormDataEntryValue | null) => {
  if (value === null || value === undefined) {
    return []
  }

  if (typeof value !== "string" || !value.trim()) {
    return []
  }

  try {
    const parsed = JSON.parse(value) as unknown
    if (!Array.isArray(parsed)) {
      return []
    }

    return parsed.filter((entry): entry is string => typeof entry === "string")
  } catch {
    return []
  }
}

export const scriptFormSchema = z.object({
  title: z.string().trim().min(3).max(120),
  slug: z.string().trim().transform(generateSlug).pipe(slugSchema),
  description: z.string().trim().min(20).max(1000),
  code: z.string().trim().min(10, "Lua code is required.").max(100_000),
  screenshots: z.preprocess(
    (value) => (Array.isArray(value) ? value : parseScreenshotsField(value as FormDataEntryValue | null)),
    scriptScreenshotsSchema
  ),
  published: z.boolean(),
})

export const invitationFormSchema = z.object({
  email: z
    .string()
    .trim()
    .toLowerCase()
    .pipe(z.email("Enter a valid email address.")),
})

export const publicScriptSearchSchema = z.object({
  query: z.string().trim().max(100, "Search is limited to 100 characters.").optional(),
})
