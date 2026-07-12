"use client"

import { useFormStatus } from "react-dom"

import { Button } from "@/components/ui/button"
import type { PendingSubmitButtonProps } from "./pending-submit-button.types"

export const PendingSubmitButton = ({
  idleLabel,
  pendingLabel = "Saving…",
  disabled,
  ...props
}: PendingSubmitButtonProps) => {
  const { pending } = useFormStatus()

  return (
    <Button
      type="submit"
      disabled={disabled || pending}
      aria-disabled={disabled || pending}
      {...props}
    >
      {pending ? pendingLabel : idleLabel}
    </Button>
  )
}
