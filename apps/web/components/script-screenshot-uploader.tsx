"use client"

import Image from "next/image"
import { useCallback, useEffect, useRef, useState } from "react"
import { IconPhoto, IconTrash, IconUpload } from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import { getScreenshotServeUrl } from "@/lib/blob"
import { cn } from "@/lib/utils"
import { MAX_SCRIPT_SCREENSHOTS } from "@/lib/validation"
import type {
  ScriptScreenshotUploaderProps,
  ScreenshotUploadState,
} from "./script-screenshot-uploader.types"

const ALLOWED_IMAGE_TYPES = new Set([
  "image/jpeg",
  "image/png",
  "image/webp",
])

const getImageFiles = (fileList: FileList | File[]) =>
  Array.from(fileList).filter((file) => ALLOWED_IMAGE_TYPES.has(file.type))

const getImageFilesFromClipboard = (clipboardData: DataTransfer) => {
  const fromItems = Array.from(clipboardData.items)
    .filter((item) => item.kind === "file" && ALLOWED_IMAGE_TYPES.has(item.type))
    .map((item) => item.getAsFile())
    .filter((file): file is File => file !== null)

  if (fromItems.length > 0) {
    return fromItems
  }

  return getImageFiles(clipboardData.files)
}

export const ScriptScreenshotUploader = ({
  initialScreenshots = [],
  scriptId,
}: ScriptScreenshotUploaderProps) => {
  const containerRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const screenshotsRef = useRef<ScreenshotUploadState[]>([])
  const [screenshots, setScreenshots] = useState<ScreenshotUploadState[]>(
    initialScreenshots.flatMap((ref) => {
      const previewUrl = getScreenshotServeUrl(ref)
      return previewUrl ? [{ ref, previewUrl }] : []
    })
  )
  const [error, setError] = useState<string | null>(null)
  const [isDragging, setIsDragging] = useState(false)

  screenshotsRef.current = screenshots

  const canAddMore = screenshots.length < MAX_SCRIPT_SCREENSHOTS

  const handleUploadFiles = useCallback(async (files: File[]) => {
    const imageFiles = getImageFiles(files)
    if (imageFiles.length === 0) {
      setError("Only JPEG, PNG, and WebP images are supported.")
      return
    }

    setError(null)

    const remainingSlots = MAX_SCRIPT_SCREENSHOTS - screenshotsRef.current.length
    if (remainingSlots <= 0) {
      setError(`You can upload at most ${MAX_SCRIPT_SCREENSHOTS} screenshots.`)
      return
    }

    const filesToUpload = imageFiles.slice(0, remainingSlots)

    for (const file of filesToUpload) {
      const tempId = crypto.randomUUID()
      setScreenshots((current) => [...current, { ref: tempId, previewUrl: tempId, uploading: true }])

      const formData = new FormData()
      formData.append("file", file)
      if (scriptId) {
        formData.append("scriptId", scriptId)
      }

      try {
        const response = await fetch("/api/admin/screenshots/upload", {
          method: "POST",
          body: formData,
        })

        const payload = (await response.json()) as {
          pathname?: string
          previewUrl?: string
          error?: string
        }

        if (!response.ok || !payload.pathname || !payload.previewUrl) {
          throw new Error(payload.error ?? "Upload failed.")
        }

        setScreenshots((current) =>
          current.map((entry) =>
            entry.ref === tempId
              ? { ref: payload.pathname!, previewUrl: payload.previewUrl! }
              : entry
          )
        )
      } catch (uploadError) {
        setScreenshots((current) => current.filter((entry) => entry.ref !== tempId))
        setError(
          uploadError instanceof Error
            ? uploadError.message
            : "Could not upload screenshot."
        )
      }
    }
  }, [scriptId])

  useEffect(() => {
    if (!canAddMore) {
      return
    }

    const handleDocumentPaste = (event: ClipboardEvent) => {
      if (!containerRef.current?.contains(document.activeElement)) {
        return
      }

      const activeElement = document.activeElement
      if (
        activeElement instanceof HTMLInputElement
        || activeElement instanceof HTMLTextAreaElement
      ) {
        return
      }

      const imageFiles = event.clipboardData
        ? getImageFilesFromClipboard(event.clipboardData)
        : []
      if (imageFiles.length === 0) {
        return
      }

      event.preventDefault()
      void handleUploadFiles(imageFiles)
    }

    document.addEventListener("paste", handleDocumentPaste)
    return () => document.removeEventListener("paste", handleDocumentPaste)
  }, [canAddMore, handleUploadFiles])

  const handleInputChange = async (event: React.ChangeEvent<HTMLInputElement>) => {
    const { files } = event.target
    if (!files) {
      return
    }

    await handleUploadFiles(Array.from(files))
    event.target.value = ""
  }

  const handleRemove = (ref: string) => {
    setScreenshots((current) => current.filter((entry) => entry.ref !== ref))
    setError(null)
  }

  const handleContainerClick = () => {
    containerRef.current?.focus()
  }

  const serializedScreenshots = JSON.stringify(
    screenshots.filter((entry) => !entry.uploading).map((entry) => entry.ref)
  )

  return (
    <div
      ref={containerRef}
      tabIndex={0}
      role="group"
      aria-label="Screenshot upload area"
      onClick={handleContainerClick}
      className={cn(
        "grid gap-4 rounded-lg outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2",
        !canAddMore && "opacity-60"
      )}
    >
      <input type="hidden" name="screenshots" value={serializedScreenshots} readOnly />

      <div
        className={cn(
          "rounded-lg border border-dashed p-6 text-center transition-colors",
          isDragging ? "border-primary bg-primary/5" : "border-border",
          !canAddMore && "pointer-events-none"
        )}
        onDragEnter={(event) => {
          event.preventDefault()
          setIsDragging(true)
        }}
        onDragOver={(event) => {
          event.preventDefault()
          setIsDragging(true)
        }}
        onDragLeave={(event) => {
          event.preventDefault()
          setIsDragging(false)
        }}
        onDrop={async (event) => {
          event.preventDefault()
          event.stopPropagation()
          setIsDragging(false)
          if (!canAddMore) {
            return
          }

          await handleUploadFiles(Array.from(event.dataTransfer.files))
        }}
      >
        <IconPhoto className="mx-auto mb-3 size-8 text-muted-foreground" />
        <p className="text-sm font-medium">Drop or paste screenshots here</p>
        <p className="mt-1 text-xs text-muted-foreground">
          Drag and drop, paste from clipboard (Ctrl+V), or browse. JPEG, PNG, or WebP up to 4 MB. Max {MAX_SCRIPT_SCREENSHOTS}.
        </p>
        <Button
          type="button"
          variant="outline"
          size="sm"
          className="mt-4"
          disabled={!canAddMore}
          onClick={(event) => {
            event.stopPropagation()
            inputRef.current?.click()
          }}
        >
          <IconUpload className="size-4" />
          Upload screenshot
        </Button>
        <input
          ref={inputRef}
          type="file"
          accept="image/jpeg,image/png,image/webp"
          multiple
          className="sr-only"
          onChange={handleInputChange}
        />
      </div>

      {error ? (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      ) : null}

      {screenshots.length > 0 ? (
        <ul className="grid gap-3 sm:grid-cols-2">
          {screenshots.map((screenshot, index) => (
            <li
              key={screenshot.ref}
              className="relative overflow-hidden rounded-lg border bg-muted/20"
            >
              <div className="relative aspect-video">
                {screenshot.uploading ? (
                  <div className="flex h-full items-center justify-center text-sm text-muted-foreground">
                    Uploading…
                  </div>
                ) : (
                  <Image
                    src={screenshot.previewUrl}
                    alt={`Screenshot ${index + 1}`}
                    fill
                    sizes="(max-width: 640px) 100vw, 320px"
                    className="object-cover"
                  />
                )}
              </div>
              {!screenshot.uploading ? (
                <Button
                  type="button"
                  variant="destructive"
                  size="icon-xs"
                  aria-label={`Remove screenshot ${index + 1}`}
                  className="absolute top-2 right-2"
                  onClick={(event) => {
                    event.stopPropagation()
                    handleRemove(screenshot.ref)
                  }}
                >
                  <IconTrash className="size-3.5" />
                </Button>
              ) : null}
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  )
}
