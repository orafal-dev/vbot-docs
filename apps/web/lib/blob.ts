import { del } from "@vercel/blob"

import { scriptScreenshotsSchema } from "@/lib/validation"

export const deleteScriptScreenshotUrls = async (urls: string[]) => {
  const parsed = scriptScreenshotsSchema.safeParse(urls)
  if (!parsed.success || parsed.data.length === 0) {
    return
  }

  await Promise.allSettled(parsed.data.map((url) => del(url)))
}
