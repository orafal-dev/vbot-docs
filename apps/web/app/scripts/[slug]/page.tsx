import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import { IconArrowLeft, IconCalendar, IconUser } from "@tabler/icons-react"

import { ScriptCodePanel } from "@/components/script-code-panel"
import { ScriptInstallNotice } from "@/components/script-install-notice"
import { ScriptStats } from "@/components/script-stats"
import { ScriptScreenshotGallery } from "@/components/script-screenshot-gallery"
import { Badge } from "@/components/ui/badge"
import { Separator } from "@/components/ui/separator"
import { getScreenshotServeUrl } from "@/lib/blob"
import { highlightLuaCode } from "@/lib/highlight"
import { normalizeScriptFiles } from "@/lib/script-files"
import { buildScriptLibraryHref, getScriptTagLabel } from "@/lib/script-tags"
import {
  getPublishedScriptBySlug,
  getPublishedScriptSlugs,
} from "@/lib/scripts"

export const revalidate = 3600

export const dynamicParams = true

export const generateStaticParams = async () => {
  const slugs = await getPublishedScriptSlugs()
  return slugs.map((slug) => ({ slug }))
}

const getFirstScreenshotUrl = (screenshots: string[]): string | null => {
  for (const ref of screenshots) {
    const url = getScreenshotServeUrl(ref)
    if (url) {
      return url
    }
  }

  return null
}

export const generateMetadata = async ({
  params,
}: {
  params: Promise<{ slug: string }>
}): Promise<Metadata> => {
  const { slug } = await params
  const script = await getPublishedScriptBySlug(slug)

  if (!script) {
    return { title: "Script not found" }
  }

  const ogImage = getFirstScreenshotUrl(script.screenshots)

  return {
    title: script.title,
    description: script.description,
    openGraph: {
      title: script.title,
      description: script.description,
      type: "article",
      ...(ogImage
        ? {
            images: [
              {
                url: ogImage,
                alt: `${script.title} preview`,
              },
            ],
          }
        : {}),
    },
    ...(ogImage
      ? {
          twitter: {
            card: "summary_large_image",
            title: script.title,
            description: script.description,
            images: [ogImage],
          },
        }
      : {}),
  }
}

export default async function ScriptDetailPage({
  params,
}: {
  params: Promise<{ slug: string }>
}) {
  const { slug } = await params
  const script = await getPublishedScriptBySlug(slug)
  if (!script) notFound()

  const files = normalizeScriptFiles({
    code: script.code,
    files: script.files,
    slug: script.slug,
  })

  const highlightedFiles = await Promise.all(
    files.map(async (file) => ({
      ...file,
      highlightedHtml: await highlightLuaCode(file.code),
    }))
  )

  return (
    <main className="mx-auto max-w-5xl px-4 py-12 sm:px-6">
      <Link
        href="/"
        className="mb-8 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"
      >
        <IconArrowLeft className="size-4" /> Back to library
      </Link>
      <div className="max-w-3xl">
        <div className="mb-4 flex flex-wrap items-center gap-2">
          <Badge>Lua script</Badge>
          {script.tags.map((tag) => (
            <Badge
              key={tag}
              variant="outline"
              render={
                <Link
                  href={buildScriptLibraryHref({ tag })}
                  aria-label={`View ${getScriptTagLabel(tag)} scripts`}
                />
              }
            >
              {getScriptTagLabel(tag)}
            </Badge>
          ))}
        </div>
        <h1 className="text-4xl font-semibold tracking-tight">{script.title}</h1>
        <p className="mt-4 text-lg leading-8 text-muted-foreground">
          {script.description}
        </p>
      </div>
      <div className="my-8 flex flex-wrap gap-5 text-sm text-muted-foreground">
        <span className="flex items-center gap-1.5">
          <IconUser className="size-4" /> {script.authorName}
        </span>
        <span className="flex items-center gap-1.5">
          <IconCalendar className="size-4" /> Updated{" "}
          {script.updatedAt.toLocaleDateString("en-US", { dateStyle: "long" })}
        </span>
        <ScriptStats scriptSlug={script.slug} />
      </div>
      <Separator className="mb-8" />
      <ScriptScreenshotGallery
        screenshots={script.screenshots}
        scriptTitle={script.title}
      />
      <ScriptInstallNotice tags={script.tags} fileCount={files.length} />
      <ScriptCodePanel files={highlightedFiles} scriptSlug={script.slug} />
    </main>
  )
}
