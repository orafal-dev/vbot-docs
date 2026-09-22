import type { ScriptFile, ScriptFilesInput } from "./script-files.types"

export const MAX_SCRIPT_FILES = 12

export const DEFAULT_SCRIPT_FILENAME = "main.lua"

export const toScriptFilename = (slug?: string) => {
  if (!slug?.trim()) {
    return DEFAULT_SCRIPT_FILENAME
  }

  return slug.endsWith(".lua") ? slug : `${slug}.lua`
}

export const normalizeScriptFiles = ({
  code,
  files,
  slug,
}: ScriptFilesInput): ScriptFile[] => {
  if (Array.isArray(files) && files.length > 0) {
    return files.map((file) => ({
      name: file.name.trim(),
      code: file.code,
    }))
  }

  return [
    {
      name: toScriptFilename(slug),
      code,
    },
  ]
}

export const getPrimaryScriptCode = (files: ScriptFile[], fallback = "") =>
  files[0]?.code ?? fallback
