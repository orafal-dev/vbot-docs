import { del } from "@vercel/blob"

const BLOB_URL_PATTERN =
  /^https:\/\/[a-z0-9-]+\.(?:public|private)\.blob\.vercel-storage\.com\/(.+)$/i

const SCREENSHOT_PATHNAME_PATTERN =
  /^scripts\/[a-zA-Z0-9/_-]+\.(?:jpg|jpeg|png|webp)$/i

export const normalizeScreenshotRef = (value: string): string | null => {
  const trimmed = value.trim()
  if (!trimmed) {
    return null
  }

  const blobMatch = trimmed.match(BLOB_URL_PATTERN)
  if (blobMatch?.[1]) {
    return decodeURIComponent(blobMatch[1])
  }

  if (SCREENSHOT_PATHNAME_PATTERN.test(trimmed)) {
    return trimmed
  }

  return null
}

export const getScreenshotServeUrl = (ref: string): string | null => {
  const pathname = normalizeScreenshotRef(ref)
  if (!pathname) {
    return null
  }

  return `/api/screenshots/${pathname
    .split("/")
    .map((segment) => encodeURIComponent(segment))
    .join("/")}`
}

export const deleteScriptScreenshotUrls = async (refs: string[]) => {
  const pathnames = refs
    .map((ref) => normalizeScreenshotRef(ref))
    .filter((ref): ref is string => ref !== null)

  if (pathnames.length === 0) {
    return
  }

  await Promise.allSettled(pathnames.map((pathname) => del(pathname)))
}
