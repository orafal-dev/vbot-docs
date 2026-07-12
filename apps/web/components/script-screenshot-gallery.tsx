"use client"

import Image from "next/image"
import { useCallback, useEffect, useState } from "react"
import { createPortal } from "react-dom"
import {
  IconChevronLeft,
  IconChevronRight,
  IconX,
} from "@tabler/icons-react"

import { Button } from "@/components/ui/button"
import { cn } from "@/lib/utils"
import type { ScriptScreenshotGalleryProps } from "./script-screenshot-gallery.types"

export const ScriptScreenshotGallery = ({
  screenshots,
  scriptTitle,
}: ScriptScreenshotGalleryProps) => {
  const [activeIndex, setActiveIndex] = useState<number | null>(null)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  const closeLightbox = useCallback(() => {
    setActiveIndex(null)
  }, [])

  const showPrevious = useCallback(() => {
    setActiveIndex((currentIndex) => {
      if (currentIndex === null) {
        return currentIndex
      }

      return (currentIndex - 1 + screenshots.length) % screenshots.length
    })
  }, [screenshots.length])

  const showNext = useCallback(() => {
    setActiveIndex((currentIndex) => {
      if (currentIndex === null) {
        return currentIndex
      }

      return (currentIndex + 1) % screenshots.length
    })
  }, [screenshots.length])

  useEffect(() => {
    if (activeIndex === null) {
      return
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key === "Escape") {
        closeLightbox()
      }

      if (event.key === "ArrowLeft") {
        showPrevious()
      }

      if (event.key === "ArrowRight") {
        showNext()
      }
    }

    window.addEventListener("keydown", handleKeyDown)
    return () => window.removeEventListener("keydown", handleKeyDown)
  }, [activeIndex, closeLightbox, showNext, showPrevious])

  if (screenshots.length === 0) {
    return null
  }

  const activeScreenshot =
    activeIndex === null ? null : screenshots[activeIndex]

  return (
    <>
      <section aria-label="Script preview screenshots" className="mb-8">
        <h2 className="mb-3 text-sm font-medium text-muted-foreground">
          Preview screenshots
        </h2>
        <div className="flex gap-3 overflow-x-auto pb-1">
          {screenshots.map((url, index) => (
            <button
              key={url}
              type="button"
              aria-label={`Open screenshot ${index + 1} of ${screenshots.length} for ${scriptTitle}`}
              className={cn(
                "relative h-24 w-40 shrink-0 overflow-hidden rounded-lg border bg-muted/40 transition-shadow",
                "hover:shadow-md focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
              )}
              onClick={() => setActiveIndex(index)}
            >
              <Image
                src={url}
                alt={`${scriptTitle} preview ${index + 1}`}
                fill
                sizes="160px"
                className="object-cover"
              />
            </button>
          ))}
        </div>
      </section>

      {mounted && activeScreenshot && activeIndex !== null
        ? createPortal(
            <div
              role="dialog"
              aria-modal="true"
              aria-label={`${scriptTitle} screenshot viewer`}
              className="fixed inset-0 z-50 flex items-center justify-center p-4"
            >
              <button
                type="button"
                aria-label="Close screenshot viewer"
                className="absolute inset-0 bg-black/85"
                onClick={closeLightbox}
              />
              <div className="relative z-10 flex w-full max-w-6xl flex-col items-center gap-4">
                <div className="relative aspect-video w-full max-h-[80vh] overflow-hidden rounded-xl bg-black/40">
                  <Image
                    src={activeScreenshot}
                    alt={`${scriptTitle} screenshot ${activeIndex + 1}`}
                    fill
                    sizes="(max-width: 768px) 100vw, 80vw"
                    className="object-contain"
                    priority
                  />
                </div>
                <div className="flex items-center gap-3">
                  {screenshots.length > 1 ? (
                    <>
                      <Button
                        type="button"
                        variant="outline"
                        size="icon"
                        aria-label="Previous screenshot"
                        onClick={showPrevious}
                      >
                        <IconChevronLeft className="size-5" />
                      </Button>
                      <p className="min-w-16 text-center text-sm text-white">
                        {activeIndex + 1} / {screenshots.length}
                      </p>
                      <Button
                        type="button"
                        variant="outline"
                        size="icon"
                        aria-label="Next screenshot"
                        onClick={showNext}
                      >
                        <IconChevronRight className="size-5" />
                      </Button>
                    </>
                  ) : null}
                  <Button
                    type="button"
                    variant="outline"
                    size="icon"
                    aria-label="Close screenshot viewer"
                    onClick={closeLightbox}
                  >
                    <IconX className="size-5" />
                  </Button>
                </div>
              </div>
            </div>,
            document.body
          )
        : null}
    </>
  )
}
