export type ScriptFile = {
  name: string
  code: string
}

export type ScriptFilesInput = {
  code: string
  files?: ScriptFile[] | null
  slug?: string
}
