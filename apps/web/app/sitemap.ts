import type { MetadataRoute } from "next"

import { getPublishedScripts } from "@/lib/scripts"

export default async function sitemap(): Promise<MetadataRoute.Sitemap> {
  const baseUrl = process.env.BETTER_AUTH_URL ?? "http://localhost:3000"
  const scripts = await getPublishedScripts()
  return [
    { url: baseUrl, changeFrequency: "weekly", priority: 1 },
    ...scripts.map((script) => ({
      url: `${baseUrl}/scripts/${script.slug}`,
      lastModified: script.updatedAt,
      changeFrequency: "monthly" as const,
      priority: 0.7,
    })),
  ]
}
