export type ScriptScreenshotUploaderProps = {
  initialScreenshots?: string[]
  scriptId?: string
}

export type ScreenshotUploadState = {
  url: string
  uploading?: boolean
}
