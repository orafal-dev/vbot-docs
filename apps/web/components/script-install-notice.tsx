import { IconFolder } from "@tabler/icons-react"

const SCRIPT_INSTALL_PATH =
  "%localappdata%\\ValidusBot\\Products\\tibia\\UserData\\Scripts"

export const ScriptInstallNotice = () => {
  return (
    <aside
      aria-label="Script installation instructions"
      className="mb-8 rounded-lg border border-border bg-muted/40 px-4 py-3"
    >
      <div className="flex gap-3">
        <IconFolder
          aria-hidden="true"
          className="mt-0.5 size-5 shrink-0 text-primary"
        />
        <div className="min-w-0 space-y-1">
          <p className="text-sm font-medium">Where to install this script</p>
          <p className="text-sm leading-6 text-muted-foreground">
            Save the downloaded <code className="text-foreground">.lua</code>{" "}
            file to:
          </p>
          <code className="block overflow-x-auto rounded-md bg-background px-3 py-2 text-xs leading-6 text-foreground">
            {SCRIPT_INSTALL_PATH}
          </code>
        </div>
      </div>
    </aside>
  )
}
