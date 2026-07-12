import { NextResponse } from "next/server"

import { getScriptStatsBySlug } from "@/lib/script-stats"
import { scriptSlugParamSchema } from "@/lib/validation"

export const GET = async (
  _request: Request,
  { params }: { params: Promise<{ slug: string }> }
) => {
  const slugResult = scriptSlugParamSchema.safeParse(await params)

  if (!slugResult.success) {
    return NextResponse.json({ error: "Invalid script slug." }, { status: 400 })
  }

  const stats = await getScriptStatsBySlug(slugResult.data.slug)

  if (!stats) {
    return NextResponse.json({ error: "Script not found." }, { status: 404 })
  }

  return NextResponse.json(stats)
}
