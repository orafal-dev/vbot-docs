"use client"

import { useState } from "react"

import { CodeActions } from "@/components/code-actions"
import { Card, CardContent } from "@/components/ui/card"
import { cn } from "@/lib/utils"
import type { ScriptCodePanelProps } from "./script-code-panel.types"

export const ScriptCodePanel = ({ files, scriptSlug }: ScriptCodePanelProps) => {
  const [activeIndex, setActiveIndex] = useState(0)
  const activeFile = files[activeIndex] ?? files[0]
  const hasMultipleFiles = files.length > 1

  if (!activeFile) {
    return null
  }

  const handleSelectFile = (index: number) => {
    setActiveIndex(index)
  }

  return (
    <div className="grid gap-4">
      {hasMultipleFiles ? (
        <div
          role="tablist"
          aria-label="Script files"
          className="flex flex-wrap gap-2"
        >
          {files.map((file, index) => {
            const isActive = index === activeIndex

            return (
              <button
                key={file.name}
                type="button"
                role="tab"
                aria-selected={isActive}
                aria-label={`Show ${file.name}`}
                tabIndex={0}
                onClick={() => handleSelectFile(index)}
                onKeyDown={(event) => {
                  if (event.key === "Enter" || event.key === " ") {
                    event.preventDefault()
                    handleSelectFile(index)
                  }
                }}
                className={cn(
                  "rounded-lg border px-3 py-1.5 text-sm transition-colors",
                  isActive
                    ? "border-primary/40 bg-primary/10 text-foreground"
                    : "border-border bg-background text-muted-foreground hover:text-foreground"
                )}
              >
                {file.name}
              </button>
            )
          })}
        </div>
      ) : null}

      <div className="flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
        <p className="text-sm text-muted-foreground">
          {hasMultipleFiles ? (
            <>
              Viewing <span className="font-medium text-foreground">{activeFile.name}</span>
              {" · "}
              {files.length} files
            </>
          ) : (
            <span className="font-medium text-foreground">{activeFile.name}</span>
          )}
        </p>
        <CodeActions
          code={activeFile.code}
          filename={activeFile.name}
          scriptSlug={scriptSlug}
          files={hasMultipleFiles ? files : undefined}
        />
      </div>

      <Card className="overflow-hidden p-0">
        <CardContent className="overflow-x-auto p-0">
          <div
            className="shiki-dual min-w-max text-sm leading-6 [&_pre]:p-5"
            dangerouslySetInnerHTML={{ __html: activeFile.highlightedHtml }}
          />
        </CardContent>
      </Card>
    </div>
  )
}
