"use client"

import { IconTrash } from "@tabler/icons-react"

import { deleteScript } from "@/app/admin/actions"
import { PendingSubmitButton } from "@/components/pending-submit-button"
import {
  AlertDialog,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
  AlertDialogTrigger,
} from "@/components/ui/alert-dialog"
import { Button } from "@/components/ui/button"
import type { DeleteScriptButtonProps } from "./delete-script-button.types"

export const DeleteScriptButton = ({
  id,
  title,
}: DeleteScriptButtonProps) => (
  <AlertDialog>
    <AlertDialogTrigger
      render={
        <Button
          type="button"
          variant="ghost"
          size="icon"
          aria-label={`Delete ${title}`}
        />
      }
    >
      <IconTrash />
    </AlertDialogTrigger>
    <AlertDialogContent>
      <AlertDialogHeader>
        <AlertDialogTitle>Delete “{title}”?</AlertDialogTitle>
        <AlertDialogDescription>
          This permanently removes the script from the library.
        </AlertDialogDescription>
      </AlertDialogHeader>
      <AlertDialogFooter>
        <AlertDialogCancel>Cancel</AlertDialogCancel>
        <form action={deleteScript.bind(null, id)}>
          <PendingSubmitButton
            variant="destructive"
            idleLabel="Delete script"
            pendingLabel="Deleting…"
          />
        </form>
      </AlertDialogFooter>
    </AlertDialogContent>
  </AlertDialog>
)
