import { NextResponse } from "next/server"

import { incrementScriptStat } from "@/lib/script-stats"
import { scriptStatEventSchema, scriptSlugParamSchema } from "@/lib/validation"

export const POST = async (
  request: Request,
  { params }: { params: Promise<{ slug: string }> }
) => {
  const slugResult = scriptSlugParamSchema.safeParse(await params)

  if (!slugResult.success) {
    return NextResponse.json({ error: "Invalid script slug." }, { status: 400 })
  }

  let body: unknown

  try {
    body = await request.json()
  } catch {
    return NextResponse.json({ error: "Invalid JSON body." }, { status: 400 })
  }

  const eventResult = scriptStatEventSchema.safeParse(body)

  if (!eventResult.success) {
    return NextResponse.json({ error: "Invalid event type." }, { status: 400 })
  }

  const stats = await incrementScriptStat(
    slugResult.data.slug,
    eventResult.data.type
  )

  if (!stats) {
    return NextResponse.json({ error: "Script not found." }, { status: 404 })
  }

  return NextResponse.json(stats)
}
