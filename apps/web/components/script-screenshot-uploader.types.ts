export type ScriptScreenshotUploaderProps = {
  initialScreenshots?: string[]
  scriptId?: string
}

export type ScreenshotUploadState = {
  ref: string
  previewUrl: string
  uploading?: boolean
}
