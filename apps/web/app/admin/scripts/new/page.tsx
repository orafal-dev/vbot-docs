import type { Metadata } from "next"

import { createScript } from "@/app/admin/actions"
import { ScriptForm } from "@/components/script-form"

export const metadata: Metadata = { title: "New script" }

export default async function NewScriptPage({ searchParams }: { searchParams: Promise<{ error?: string }> }) {
  const { error } = await searchParams
  return (
    <section className="mx-auto max-w-4xl">
      <div className="mb-6"><h2 className="text-2xl font-semibold">Create script</h2><p className="text-sm text-muted-foreground">Add a reviewed Lua script to the library.</p></div>
      <ScriptForm action={createScript} mode="create" error={error} />
    </section>
  )
}
