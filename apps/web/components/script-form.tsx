import { ScriptFilesEditor } from "@/components/script-files-editor"
import { ScriptFormActions } from "@/components/script-form-actions"
import { ScriptScreenshotUploader } from "@/components/script-screenshot-uploader"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Switch } from "@/components/ui/switch"
import { Textarea } from "@/components/ui/textarea"
import { normalizeScriptFiles, toScriptFilename } from "@/lib/script-files"
import { SCRIPT_TAG_CATALOG } from "@/lib/script-tags"
import type { ScriptFormProps } from "./script-form.types"

export const ScriptForm = ({ action, script, error, mode }: ScriptFormProps) => {
  const initialFiles = script
    ? normalizeScriptFiles({
        code: script.code,
        files: script.files,
        slug: script.slug,
      })
    : undefined

  return (
    <form action={action} className="grid gap-6 pb-28">
      {error ? (
        <p
          role="alert"
          className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive"
        >
          {error}
        </p>
      ) : null}
      <Card>
        <CardHeader>
          <CardTitle>Script details</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-5">
          <div className="grid gap-2">
            <Label htmlFor="title">Title</Label>
            <Input
              id="title"
              name="title"
              defaultValue={script?.title}
              required
              minLength={3}
              maxLength={120}
            />
          </div>
          <div className="grid gap-2">
            <Label htmlFor="slug">Slug</Label>
            <Input
              id="slug"
              name="slug"
              defaultValue={script?.slug}
              placeholder="Generated from title when empty"
              maxLength={80}
              pattern="[a-z0-9]+(?:-[a-z0-9]+)*"
            />
            <p className="text-xs text-muted-foreground">
              Lowercase letters, numbers, and hyphens.
            </p>
          </div>
          <div className="grid gap-2">
            <Label htmlFor="description">Description</Label>
            <Textarea
              id="description"
              name="description"
              defaultValue={script?.description}
              required
              minLength={20}
              maxLength={1000}
              rows={5}
            />
          </div>
          <fieldset className="grid gap-3 rounded-lg border p-4">
            <legend className="px-1 text-sm font-medium">Tags</legend>
            <p className="text-xs text-muted-foreground">
              Use Cavebot snippet for waypoint script nodes. Other tags stay in the
              same library and can be filtered on the public list.
            </p>
            <div className="grid gap-3">
              {SCRIPT_TAG_CATALOG.map((tag) => {
                const checkboxId = `tag-${tag.id}`

                return (
                  <label
                    key={tag.id}
                    htmlFor={checkboxId}
                    className="flex cursor-pointer items-start gap-3 rounded-lg border p-3 has-checked:border-primary/40 has-checked:bg-primary/5"
                  >
                    <input
                      id={checkboxId}
                      name="tags"
                      type="checkbox"
                      value={tag.id}
                      defaultChecked={script?.tags.includes(tag.id)}
                      className="mt-1 size-4 accent-primary"
                      aria-describedby={`${checkboxId}-description`}
                    />
                    <span>
                      <span className="block text-sm font-medium">{tag.label}</span>
                      <span
                        id={`${checkboxId}-description`}
                        className="block text-xs text-muted-foreground"
                      >
                        {tag.description}
                      </span>
                    </span>
                  </label>
                )
              })}
            </div>
          </fieldset>
          <div className="flex items-center justify-between gap-4 rounded-lg border p-4">
            <div>
              <Label htmlFor="published">Published</Label>
              <p className="text-xs text-muted-foreground">
                Only published scripts are visible publicly.
              </p>
            </div>
            <Switch
              id="published"
              name="published"
              defaultChecked={script?.published}
            />
          </div>
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle>Preview screenshots</CardTitle>
        </CardHeader>
        <CardContent>
          <ScriptScreenshotUploader
            initialScreenshots={script?.screenshots ?? []}
            scriptId={script?.id}
          />
        </CardContent>
      </Card>
      <Card>
        <CardHeader>
          <CardTitle>Lua files</CardTitle>
        </CardHeader>
        <CardContent className="grid gap-3">
          <p className="text-xs text-muted-foreground">
            Cavebot snippets should stay short, jump with{" "}
            <code>Cavebot.GoTo</code>, and call{" "}
            <code>Cavebot.Walker.Resume()</code> on every exit path. Multi-file
            scripts can ship helpers alongside the entry file.
          </p>
          <ScriptFilesEditor
            initialFiles={initialFiles}
            defaultFilename={toScriptFilename(script?.slug)}
          />
        </CardContent>
      </Card>
      <ScriptFormActions mode={mode} />
    </form>
  )
}
