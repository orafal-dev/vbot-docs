import { IconArrowRight, IconSearch, IconShieldCheck, IconSparkles } from "@tabler/icons-react"
import Link from "next/link"

import { Badge } from "@/components/ui/badge"
import { Card, CardContent, CardDescription, CardFooter, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { getPublishedScripts } from "@/lib/scripts"

export default async function Page({ searchParams }: { searchParams: Promise<{ q?: string }> }) {
  const { q } = await searchParams
  const scripts = await getPublishedScripts({ query: q })
  return (
    <main>
      <section className="border-b bg-muted/30">
        <div className="mx-auto grid max-w-7xl gap-10 px-4 py-20 sm:px-6 lg:grid-cols-[1.15fr_.85fr] lg:py-28">
          <div className="max-w-3xl">
            <Badge variant="outline" className="mb-5"><IconSparkles /> Community Lua library</Badge>
            <h1 className="text-4xl font-semibold tracking-tight sm:text-6xl">Readable scripts for <span className="text-primary">ValidusBot</span></h1>
            <p className="mt-6 max-w-2xl text-lg leading-8 text-muted-foreground">Discover readable, defensive Tibia automation built against the canonical ValidusBot Lua API.</p>
          </div>
          <Card className="self-end">
            <CardHeader><CardTitle as="h2" className="flex items-center gap-2"><IconShieldCheck className="text-primary" /> Built for inspection</CardTitle><CardDescription>Scripts from a trusted administrator, ready for you to review before use.</CardDescription></CardHeader>
            <CardContent className="grid gap-3 text-sm text-muted-foreground"><p>PascalCase core wrappers only</p><p>Nil-safe and non-blocking patterns</p><p>Readable Lua you can inspect and adapt</p></CardContent>
          </Card>
        </div>
      </section>
      <section className="mx-auto max-w-7xl px-4 py-14 sm:px-6">
        <div className="mb-8 flex flex-col gap-5 sm:flex-row sm:items-end sm:justify-between">
          <div><p className="text-sm font-medium text-primary">Script library</p><h2 className="mt-1 text-3xl font-semibold tracking-tight">Find your next automation</h2></div>
          <form className="relative w-full sm:max-w-sm" role="search">
            <label htmlFor="script-search" className="sr-only">Search scripts</label>
            <IconSearch className="pointer-events-none absolute top-1/2 left-3 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input id="script-search" name="q" defaultValue={q} placeholder="Search scripts…" maxLength={100} className="pl-9" />
          </form>
        </div>
        {scripts.length ? <div className="grid gap-5 md:grid-cols-2 lg:grid-cols-3">{scripts.map((script) => (
          <Card key={script.id} className="transition-shadow hover:shadow-md">
            <CardHeader><div className="mb-2 flex items-center justify-between"><Badge>Lua</Badge>{script.demo ? <Badge variant="outline">Demo data</Badge> : null}</div><CardTitle>{script.title}</CardTitle><CardDescription className="line-clamp-3">{script.description}</CardDescription></CardHeader>
            <CardContent className="text-xs text-muted-foreground">Updated {script.updatedAt.toLocaleDateString("en-US", { dateStyle: "medium" })}</CardContent>
            <CardFooter><Link href={`/scripts/${script.slug}`} className="inline-flex items-center gap-1 text-sm font-medium text-primary hover:underline">View script <IconArrowRight className="size-4" /></Link></CardFooter>
          </Card>
        ))}</div> : (
          <Card className="border-dashed py-14 text-center"><CardHeader><CardTitle>No scripts found</CardTitle><CardDescription>Try a broader search or clear the current query.</CardDescription></CardHeader><CardFooter className="justify-center"><Link href="/" className="text-sm font-medium text-primary hover:underline">Clear search</Link></CardFooter></Card>
        )}
      </section>
    </main>
  )
}
