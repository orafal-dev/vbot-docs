import type { ScriptFile } from "@/lib/script-files.types"

export type ScriptFilesEditorProps = {
  initialFiles?: ScriptFile[]
  defaultFilename?: string
}
