"use client"

import { useId, useState } from "react"
import { IconPlus, IconTrash } from "@tabler/icons-react"

import { LuaEditorField } from "@/components/lua-editor-field"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import {
  DEFAULT_SCRIPT_FILENAME,
  MAX_SCRIPT_FILES,
} from "@/lib/script-files"
import type { ScriptFile } from "@/lib/script-files.types"
import { cn } from "@/lib/utils"
import type { ScriptFilesEditorProps } from "./script-files-editor.types"

const starterCode = `local SCRIPT_ID = "my_script"\n\nModule.Every(SCRIPT_ID .. "_tick", function()\n  if not Self.IsAvailable() then\n    return\n  end\n\n  -- Safe, non-blocking logic here.\nend, 1000)`

const createFile = (name: string, code = starterCode): ScriptFile => ({
  name,
  code,
})

const nextHelperFilename = (files: ScriptFile[]) => {
  const used = new Set(files.map((file) => file.name.toLowerCase()))
  let index = files.length + 1

  while (used.has(`part-${index}.lua`)) {
    index += 1
  }

  return `part-${index}.lua`
}

export const ScriptFilesEditor = ({
  initialFiles,
  defaultFilename = DEFAULT_SCRIPT_FILENAME,
}: ScriptFilesEditorProps) => {
  const editorId = useId()
  const [files, setFiles] = useState<ScriptFile[]>(
    initialFiles && initialFiles.length > 0
      ? initialFiles
      : [createFile(defaultFilename)]
  )
  const [activeIndex, setActiveIndex] = useState(0)

  const activeFile = files[activeIndex] ?? files[0]
  const canAddMore = files.length < MAX_SCRIPT_FILES
  const canRemove = files.length > 1

  const handleSelectFile = (index: number) => {
    setActiveIndex(index)
  }

  const handleAddFile = () => {
    if (!canAddMore) {
      return
    }

    const nextFiles = [...files, createFile(nextHelperFilename(files))]
    setFiles(nextFiles)
    setActiveIndex(nextFiles.length - 1)
  }

  const handleRemoveFile = (index: number) => {
    if (!canRemove) {
      return
    }

    const nextFiles = files.filter((_, fileIndex) => fileIndex !== index)
    setFiles(nextFiles)
    setActiveIndex((current) => {
      if (current === index) {
        return Math.max(0, index - 1)
      }

      if (current > index) {
        return current - 1
      }

      return current
    })
  }

  const handleRenameFile = (index: number, name: string) => {
    setFiles((current) =>
      current.map((file, fileIndex) =>
        fileIndex === index ? { ...file, name } : file
      )
    )
  }

  const handleCodeChange = (code: string) => {
    setFiles((current) =>
      current.map((file, fileIndex) =>
        fileIndex === activeIndex ? { ...file, code } : file
      )
    )
  }

  if (!activeFile) {
    return null
  }

  return (
    <div className="grid gap-4">
      <input type="hidden" name="files" value={JSON.stringify(files)} />
      <input type="hidden" name="code" value={files[0]?.code ?? ""} />

      <div className="flex flex-wrap items-center gap-2">
        {files.map((file, index) => {
          const isActive = index === activeIndex
          const tabId = `${editorId}-tab-${index}`

          return (
            <button
              key={tabId}
              id={tabId}
              type="button"
              aria-pressed={isActive}
              aria-label={`Edit ${file.name || `file ${index + 1}`}`}
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
              {file.name || `file-${index + 1}.lua`}
            </button>
          )
        })}
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={handleAddFile}
          disabled={!canAddMore}
          aria-label="Add another Lua file"
        >
          <IconPlus />
          Add file
        </Button>
      </div>

      <div className="grid gap-2 sm:grid-cols-[1fr_auto] sm:items-end">
        <div className="grid gap-2">
          <Label htmlFor={`${editorId}-filename`}>File name</Label>
          <Input
            id={`${editorId}-filename`}
            value={activeFile.name}
            onChange={(event) =>
              handleRenameFile(activeIndex, event.target.value)
            }
            placeholder="main.lua"
            maxLength={120}
            aria-label="Lua file name"
            required
          />
        </div>
        <Button
          type="button"
          variant="outline"
          onClick={() => handleRemoveFile(activeIndex)}
          disabled={!canRemove}
          aria-label={`Remove ${activeFile.name}`}
        >
          <IconTrash />
          Remove
        </Button>
      </div>

      <p className="text-xs text-muted-foreground">
        Bare <code>.lua</code> filenames only. The first file stays the primary
        download for older clients; additional files ship with this script.
      </p>

      <LuaEditorField
        key={`${editorId}-${activeIndex}-${activeFile.name}`}
        value={activeFile.code}
        onChange={handleCodeChange}
      />
    </div>
  )
}
