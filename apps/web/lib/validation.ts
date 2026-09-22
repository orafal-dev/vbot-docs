import { z } from "zod"

import { normalizeScreenshotRef } from "@/lib/blob"
import {
  DEFAULT_SCRIPT_FILENAME,
  getPrimaryScriptCode,
  MAX_SCRIPT_FILES,
  toScriptFilename,
} from "@/lib/script-files"
import type { ScriptFile } from "@/lib/script-files.types"
import { SCRIPT_TAG_IDS } from "@/lib/script-tags.types"

export const generateSlug = (value: string) =>
  value.trim().toLowerCase().normalize("NFKD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 80)

const slugSchema = z.string().min(3, "Slug must be at least 3 characters.").max(80)
  .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, "Use lowercase letters, numbers, and hyphens.")

export const MAX_SCRIPT_SCREENSHOTS = 6

export { MAX_SCRIPT_FILES }

const scriptScreenshotRefSchema = z
  .string()
  .trim()
  .max(2048)
  .superRefine((value, context) => {
    if (!normalizeScreenshotRef(value)) {
      context.addIssue({
        code: "custom",
        message: "Screenshots must be valid Vercel Blob pathnames.",
      })
    }
  })
  .transform((value) => normalizeScreenshotRef(value)!)

export const scriptScreenshotsSchema = z
  .array(scriptScreenshotRefSchema)
  .max(MAX_SCRIPT_SCREENSHOTS, `At most ${MAX_SCRIPT_SCREENSHOTS} screenshots are allowed.`)

const scriptFilenameSchema = z
  .string()
  .trim()
  .min(5, "File name must end with .lua.")
  .max(120, "File name is limited to 120 characters.")
  .regex(
    /^[a-zA-Z0-9][a-zA-Z0-9._-]*\.lua$/,
    "Use a bare .lua filename with letters, numbers, dots, underscores, or hyphens."
  )

export const scriptFileSchema = z.object({
  name: scriptFilenameSchema,
  code: z.string().trim().min(10, "Lua code is required.").max(100_000),
})

export const scriptFilesSchema = z
  .array(scriptFileSchema)
  .min(1, "At least one Lua file is required.")
  .max(MAX_SCRIPT_FILES, `At most ${MAX_SCRIPT_FILES} files are allowed.`)
  .superRefine((files, context) => {
    const seen = new Set<string>()

    for (const [index, file] of files.entries()) {
      const key = file.name.toLowerCase()
      if (seen.has(key)) {
        context.addIssue({
          code: "custom",
          message: `Duplicate file name: ${file.name}`,
          path: [index, "name"],
        })
        continue
      }

      seen.add(key)
    }
  })

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

const parseFilesField = (value: unknown): ScriptFile[] => {
  if (Array.isArray(value)) {
    return value.filter(
      (entry): entry is ScriptFile =>
        typeof entry === "object" &&
        entry !== null &&
        typeof (entry as ScriptFile).name === "string" &&
        typeof (entry as ScriptFile).code === "string"
    )
  }

  if (typeof value !== "string" || !value.trim()) {
    return []
  }

  try {
    const parsed = JSON.parse(value) as unknown
    if (!Array.isArray(parsed)) {
      return []
    }

    return parsed.filter(
      (entry): entry is ScriptFile =>
        typeof entry === "object" &&
        entry !== null &&
        typeof (entry as ScriptFile).name === "string" &&
        typeof (entry as ScriptFile).code === "string"
    )
  } catch {
    return []
  }
}

const resolveScriptFiles = ({
  code,
  files,
  slug,
}: {
  code: unknown
  files: unknown
  slug: string
}): ScriptFile[] => {
  const parsedFiles = parseFilesField(files)

  if (parsedFiles.length > 0) {
    return parsedFiles
  }

  if (typeof code === "string" && code.trim()) {
    return [
      {
        name: toScriptFilename(slug) || DEFAULT_SCRIPT_FILENAME,
        code,
      },
    ]
  }

  return []
}

export const scriptFormSchema = z
  .object({
    title: z.string().trim().min(3).max(120),
    slug: z.string().trim().transform(generateSlug).pipe(slugSchema),
    description: z.string().trim().min(20).max(1000),
    code: z.string().optional(),
    files: z.unknown().optional(),
    screenshots: z.preprocess(
      (value) =>
        Array.isArray(value)
          ? value
          : parseScreenshotsField(value as FormDataEntryValue | null),
      scriptScreenshotsSchema
    ),
    tags: z.preprocess((value) => {
      if (Array.isArray(value)) {
        return value.filter((entry): entry is string => typeof entry === "string")
      }

      if (typeof value === "string" && value.trim()) {
        return [value]
      }

      return []
    }, z.array(z.enum(SCRIPT_TAG_IDS)).max(SCRIPT_TAG_IDS.length)),
    published: z.boolean(),
  })
  .superRefine((value, context) => {
    const files = resolveScriptFiles({
      code: value.code,
      files: value.files,
      slug: value.slug,
    })
    const parsed = scriptFilesSchema.safeParse(files)

    if (parsed.success) {
      return
    }

    context.addIssue({
      code: "custom",
      message: parsed.error.issues[0]?.message ?? "Invalid script files.",
      path: ["files"],
    })
  })
  .transform((value) => {
    const files = scriptFilesSchema.parse(
      resolveScriptFiles({
        code: value.code,
        files: value.files,
        slug: value.slug,
      })
    )

    return {
      title: value.title,
      slug: value.slug,
      description: value.description,
      screenshots: value.screenshots,
      tags: value.tags,
      published: value.published,
      files,
      code: getPrimaryScriptCode(files),
    }
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
  tag: z
    .string()
    .trim()
    .toLowerCase()
    .pipe(z.enum(SCRIPT_TAG_IDS))
    .optional(),
})

export const scriptSlugParamSchema = z.object({
  slug: z
    .string()
    .trim()
    .min(3)
    .max(80)
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/),
})

export const scriptStatEventSchema = z.object({
  type: z.enum(["view", "copy", "download"]),
})
