import Link from "next/link"

import { LuaEditorField } from "@/components/lua-editor-field"
import { PendingSubmitButton } from "@/components/pending-submit-button"
import { ScriptScreenshotUploader } from "@/components/script-screenshot-uploader"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import type { ScriptFormProps } from "./script-form.types"

const starterCode = `local SCRIPT_ID = "my_script"\n\nModule.Every(SCRIPT_ID .. "_tick", function()\n  if not Self.IsAvailable() then\n    return\n  end\n\n  -- Safe, non-blocking logic here.\nend, 1000)`

export const ScriptForm = ({ action, script, error, mode }: ScriptFormProps) => (
  <form action={action} className="grid gap-6">
    {error ? <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">{error}</p> : null}
    <Card>
      <CardHeader><CardTitle>Script details</CardTitle></CardHeader>
      <CardContent className="grid gap-5">
        <div className="grid gap-2"><Label htmlFor="title">Title</Label><Input id="title" name="title" defaultValue={script?.title} required minLength={3} maxLength={120} /></div>
        <div className="grid gap-2"><Label htmlFor="slug">Slug</Label><Input id="slug" name="slug" defaultValue={script?.slug} placeholder="Generated from title when empty" maxLength={80} pattern="[a-z0-9]+(?:-[a-z0-9]+)*" /><p className="text-xs text-muted-foreground">Lowercase letters, numbers, and hyphens.</p></div>
        <div className="grid gap-2"><Label htmlFor="description">Description</Label><Textarea id="description" name="description" defaultValue={script?.description} required minLength={20} maxLength={1000} rows={5} /></div>
        <div className="flex items-center justify-between gap-4 rounded-lg border p-4"><div><Label htmlFor="published">Published</Label><p className="text-xs text-muted-foreground">Only published scripts are visible publicly.</p></div><Switch id="published" name="published" defaultChecked={script?.published} /></div>
      </CardContent>
    </Card>
    <Card>
      <CardHeader><CardTitle>Preview screenshots</CardTitle></CardHeader>
      <CardContent>
        <ScriptScreenshotUploader
          initialScreenshots={script?.screenshots ?? []}
          scriptId={script?.id}
        />
      </CardContent>
    </Card>
    <Card><CardHeader><CardTitle>Lua code</CardTitle></CardHeader><CardContent><LuaEditorField name="code" value={script?.code ?? starterCode} /></CardContent></Card>
    <div className="flex justify-end gap-3"><Button variant="outline" render={<Link href="/admin" />}>Cancel</Button><PendingSubmitButton idleLabel={mode === "create" ? "Create script" : "Save changes"} pendingLabel={mode === "create" ? "Creating…" : "Saving…"} /></div>
  </form>
)
