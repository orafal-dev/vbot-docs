"use client"

import { useState } from "react"
import { IconCheck, IconCopy, IconDownload } from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import { emitScriptStatUpdate } from "@/lib/script-stat-events"
import { trackScriptStat } from "@/lib/track-script-stat"
import type { CodeActionsProps } from "./code-actions.types"

const downloadTextFile = (code: string, filename: string) => {
  const url = URL.createObjectURL(
    new Blob([code], { type: "text/x-lua;charset=utf-8" })
  )
  const anchor = document.createElement("a")
  anchor.href = url
  anchor.download = filename
  anchor.click()
  URL.revokeObjectURL(url)
}

export const CodeActions = ({
  code,
  filename,
  scriptSlug,
  files,
}: CodeActionsProps) => {
  const [copyStatus, setCopyStatus] = useState<"idle" | "copied" | "error">(
    "idle"
  )
  const hasMultipleFiles = Boolean(files && files.length > 1)

  const handleTrackStat = async (type: "copy" | "download") => {
    const stats = await trackScriptStat(scriptSlug, type)

    if (stats) {
      emitScriptStatUpdate(scriptSlug, stats)
    }
  }

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setCopyStatus("copied")
      window.setTimeout(() => setCopyStatus("idle"), 1500)
      void handleTrackStat("copy")
    } catch {
      setCopyStatus("error")
    }
  }

  const handleDownload = () => {
    downloadTextFile(code, filename)
    void handleTrackStat("download")
  }

  const handleDownloadAll = async () => {
    if (!files || files.length === 0) {
      handleDownload()
      return
    }

    for (const [index, file] of files.entries()) {
      downloadTextFile(file.code, file.name)

      if (index < files.length - 1) {
        await new Promise((resolve) => window.setTimeout(resolve, 150))
      }
    }

    void handleTrackStat("download")
  }

  return (
    <div className="grid gap-2">
      <div className="flex flex-wrap gap-2">
        <Button type="button" variant="outline" onClick={handleCopy}>
          {copyStatus === "copied" ? <IconCheck /> : <IconCopy />}
          {copyStatus === "copied" ? "Copied" : "Copy"}
        </Button>
        <Button type="button" variant="outline" onClick={handleDownload}>
          <IconDownload /> Download
        </Button>
        {hasMultipleFiles ? (
          <Button
            type="button"
            variant="outline"
            onClick={() => {
              void handleDownloadAll()
            }}
            aria-label="Download all Lua files"
          >
            <IconDownload /> Download all
          </Button>
        ) : null}
      </div>
      {copyStatus === "error" ? (
        <p role="alert" className="text-sm text-destructive">
          Clipboard access failed. Select and copy the code manually.
        </p>
      ) : null}
    </div>
  )
}
