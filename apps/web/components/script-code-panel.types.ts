import type { ScriptFile } from "@/lib/script-files.types"

export type ScriptFileView = ScriptFile & {
  highlightedHtml: string
}

export type ScriptCodePanelProps = {
  files: ScriptFileView[]
  scriptSlug: string
}
