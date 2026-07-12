import { get } from "@vercel/blob"
import { NextResponse } from "next/server"

import { normalizeScreenshotRef } from "@/lib/blob"

export const GET = async (
  _request: Request,
  { params }: { params: Promise<{ path: string[] }> }
) => {
  const { path } = await params
  const pathname = normalizeScreenshotRef(path.join("/"))

  if (!pathname) {
    return NextResponse.json({ error: "Invalid screenshot path." }, { status: 400 })
  }

  const result = await get(pathname, { access: "private" })

  if (!result || result.statusCode !== 200 || !result.stream) {
    return new NextResponse("Not found", { status: 404 })
  }

  return new NextResponse(result.stream, {
    headers: {
      "Content-Type": result.blob.contentType ?? "application/octet-stream",
      "Cache-Control": "public, max-age=31536000, immutable",
      "X-Content-Type-Options": "nosniff",
    },
  })
}
