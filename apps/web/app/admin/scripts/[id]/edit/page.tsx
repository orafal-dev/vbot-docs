import type { Metadata } from "next"
import { notFound } from "next/navigation"

import { updateScript } from "@/app/admin/actions"
import { ScriptForm } from "@/components/script-form"
import { getScriptForAdmin } from "@/lib/scripts"

export const metadata: Metadata = { title: "Edit script" }

export default async function EditScriptPage({
  params,
  searchParams,
}: {
  params: Promise<{ id: string }>
  searchParams: Promise<{ error?: string }>
}) {
  const [{ id }, { error }] = await Promise.all([params, searchParams])
  const script = await getScriptForAdmin(id)
  if (!script) notFound()
  return (
    <section className="mx-auto max-w-4xl">
      <div className="mb-6"><h2 className="text-2xl font-semibold">Edit script</h2><p className="text-sm text-muted-foreground">Changes to published scripts appear immediately.</p></div>
      <ScriptForm action={updateScript.bind(null, id)} mode="edit" script={script} error={error} />
    </section>
  )
}
