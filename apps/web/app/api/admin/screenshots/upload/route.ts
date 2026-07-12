import { put } from "@vercel/blob"
import { NextResponse } from "next/server"

import { getAdminUser } from "@/lib/auth"
import { MAX_SCRIPT_SCREENSHOTS } from "@/lib/validation"

const MAX_FILE_SIZE_BYTES = 4 * 1024 * 1024

const allowedContentTypes = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
])

const extensionByContentType: Record<string, string> = {
  "image/jpeg": "jpg",
  "image/png": "png",
  "image/webp": "webp",
}

export const POST = async (request: Request) => {
  const adminUser = await getAdminUser()
  if (!adminUser) {
    return NextResponse.json({ error: "Unauthorized." }, { status: 401 })
  }

  const formData = await request.formData()
  const file = formData.get("file")
  const scriptId = formData.get("scriptId")

  if (!(file instanceof File)) {
    return NextResponse.json({ error: "A screenshot file is required." }, { status: 400 })
  }

  if (!allowedContentTypes.has(file.type)) {
    return NextResponse.json(
      { error: "Only JPEG, PNG, and WebP images are supported." },
      { status: 400 }
    )
  }

  if (file.size > MAX_FILE_SIZE_BYTES) {
    return NextResponse.json(
      { error: "Screenshot must be 4 MB or smaller." },
      { status: 400 }
    )
  }

  const folder =
    typeof scriptId === "string" && scriptId.trim()
      ? `scripts/${scriptId.trim()}`
      : "scripts/temp"

  const extension = extensionByContentType[file.type] ?? "png"
  const pathname = `${folder}/${crypto.randomUUID()}.${extension}`

  const blob = await put(pathname, file, {
    access: "public",
    addRandomSuffix: false,
    contentType: file.type,
  })

  return NextResponse.json({
    url: blob.url,
    maxScreenshots: MAX_SCRIPT_SCREENSHOTS,
  })
}
