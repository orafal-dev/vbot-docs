import type { ComponentProps } from "react"

import type { Button } from "@/components/ui/button"

export type PendingSubmitButtonProps = ComponentProps<typeof Button> & {
  idleLabel: string
  pendingLabel?: string
}
