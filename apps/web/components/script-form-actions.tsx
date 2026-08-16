import Link from "next/link"

import { PendingSubmitButton } from "@/components/pending-submit-button"
import { buttonVariants } from "@/components/ui/button"
import type { ScriptFormActionsProps } from "./script-form-actions.types"
import { cn } from "@/lib/utils"

export const ScriptFormActions = ({ mode }: ScriptFormActionsProps) => (
  <div className="pointer-events-none fixed inset-x-0 bottom-6 z-50 flex justify-center px-4 pb-[env(safe-area-inset-bottom)]">
    <div
      role="toolbar"
      aria-label="Script form actions"
      className="pointer-events-auto flex w-full max-w-md items-center justify-between gap-3 rounded-full border border-border bg-background/30 backdrop-blur-sm px-2 py-2 shadow-lg sm:max-w-lg"
    >
      <Link
        href="/admin"
        className={cn(buttonVariants({ variant: "outline", size: "lg"}), "rounded-full px-6 py-6 text-xl")}
        aria-label="Cancel and return to the admin dashboard"
      >
        Cancel
      </Link>
      <PendingSubmitButton
        size="lg"
        className="rounded-full px-8 py-6 text-xl font-bold"
        idleLabel={mode === "create" ? "Create" : "Save"}
        pendingLabel={mode === "create" ? "Creating…" : "Saving…"}
      />
    </div>
  </div>
)
