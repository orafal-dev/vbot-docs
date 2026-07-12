import type { ScriptRecord } from "@/lib/scripts.types"

export type ScriptFormProps = {
  action: (formData: FormData) => Promise<void>
  script?: ScriptRecord | null
  error?: string
  mode: "create" | "edit"
}
