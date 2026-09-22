import type { ScriptFile } from "@/lib/script-files.types"

export type CodeActionsProps = {
  code: string
  filename: string
  scriptSlug: string
  files?: ScriptFile[]
}
