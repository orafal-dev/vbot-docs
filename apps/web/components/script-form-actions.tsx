import Link from "next/link"

import { PendingSubmitButton } from "@/components/pending-submit-button"
import { Button } from "@/components/ui/button"
import type { ScriptFormActionsProps } from "./script-form-actions.types"

export const ScriptFormActions = ({ mode }: ScriptFormActionsProps) => (
  <div className="pointer-events-none fixed inset-x-0 bottom-6 z-50 flex justify-center px-4 pb-[env(safe-area-inset-bottom)]">
    <div
      role="toolbar"
      aria-label="Script form actions"
      className="pointer-events-auto flex w-full max-w-md items-center justify-between gap-3 rounded-full border border-primary bg-[oklch(0.23_0.055_155)] px-4 py-2 shadow-lg shadow-primary/25 sm:max-w-lg"
    >
      <Button
        variant="ghost"
        size="lg"
        className="rounded-full text-white hover:bg-white/10 hover:text-white"
        render={<Link href="/admin" />}
        aria-label="Cancel and return to the admin dashboard"
      >
        Cancel
      </Button>
      <PendingSubmitButton
        size="lg"
        className="rounded-full"
        idleLabel={mode === "create" ? "Create" : "Save"}
        pendingLabel={mode === "create" ? "Creating…" : "Saving…"}
      />
    </div>
  </div>
)
