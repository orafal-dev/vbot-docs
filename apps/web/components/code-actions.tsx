"use client"

import { useState } from "react"
import { IconCheck, IconCopy, IconDownload } from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import type { CodeActionsProps } from "./code-actions.types"

export const CodeActions = ({ code, filename }: CodeActionsProps) => {
  const [copyStatus, setCopyStatus] = useState<"idle" | "copied" | "error">(
    "idle"
  )

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code)
      setCopyStatus("copied")
      window.setTimeout(() => setCopyStatus("idle"), 1500)
    } catch {
      setCopyStatus("error")
    }
  }

  const handleDownload = () => {
    const url = URL.createObjectURL(
      new Blob([code], { type: "text/x-lua;charset=utf-8" })
    )
    const anchor = document.createElement("a")
    anchor.href = url
    anchor.download = filename
    anchor.click()
    URL.revokeObjectURL(url)
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
      </div>
      {copyStatus === "error" ? (
        <p role="alert" className="text-sm text-destructive">
          Clipboard access failed. Select and copy the code manually.
        </p>
      ) : null}
    </div>
  )
}
