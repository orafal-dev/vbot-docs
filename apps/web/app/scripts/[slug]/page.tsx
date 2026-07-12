import type { Metadata } from "next"
import Link from "next/link"
import { notFound } from "next/navigation"
import { IconArrowLeft, IconCalendar, IconUser } from "@tabler/icons-react"

import { CodeActions } from "@/components/code-actions"
import { ScriptInstallNotice } from "@/components/script-install-notice"
import { ScriptStats } from "@/components/script-stats"
import { ScriptScreenshotGallery } from "@/components/script-screenshot-gallery"
import { Badge } from "@/components/ui/badge"
import { Card, CardContent } from "@/components/ui/card"
import { Separator } from "@/components/ui/separator"
import { highlightLuaCode } from "@/lib/highlight"
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

export const generateMetadata = async ({ params }: { params: Promise<{ slug: string }> }): Promise<Metadata> => {
  const { slug } = await params
  const script = await getPublishedScriptBySlug(slug)
  return script ? { title: script.title, description: script.description } : { title: "Script not found" }
}

export default async function ScriptDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params
  const script = await getPublishedScriptBySlug(slug)
  if (!script) notFound()
  const highlightedCode = await highlightLuaCode(script.code)
  return (
    <main className="mx-auto max-w-5xl px-4 py-12 sm:px-6">
      <Link href="/" className="mb-8 inline-flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground"><IconArrowLeft className="size-4" /> Back to library</Link>
      <div className="flex flex-col gap-6 sm:flex-row sm:items-end sm:justify-between">
        <div className="max-w-3xl"><Badge className="mb-4">Lua script</Badge><h1 className="text-4xl font-semibold tracking-tight">{script.title}</h1><p className="mt-4 text-lg leading-8 text-muted-foreground">{script.description}</p></div>
        <CodeActions code={script.code} filename={`${script.slug}.lua`} scriptSlug={script.slug} />
      </div>
      <div className="my-8 flex flex-wrap gap-5 text-sm text-muted-foreground">
        <span className="flex items-center gap-1.5"><IconUser className="size-4" /> {script.authorName}</span>
        <span className="flex items-center gap-1.5"><IconCalendar className="size-4" /> Updated {script.updatedAt.toLocaleDateString("en-US", { dateStyle: "long" })}</span>
        <ScriptStats scriptSlug={script.slug} />
      </div>
      <Separator className="mb-8" />
      <ScriptScreenshotGallery
        screenshots={script.screenshots}
        scriptTitle={script.title}
      />
      <ScriptInstallNotice />
      <Card className="overflow-hidden p-0"><CardContent className="overflow-x-auto p-0"><div className="shiki-dual min-w-max text-sm leading-6 [&_pre]:p-5" dangerouslySetInnerHTML={{ __html: highlightedCode }} /></CardContent></Card>
    </main>
  )
}
