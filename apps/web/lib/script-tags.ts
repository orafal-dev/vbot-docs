import { SCRIPT_TAG_IDS } from "./script-tags.types"
import type {
  ScriptLibraryHrefInput,
  ScriptTagDefinition,
  ScriptTagId,
} from "./script-tags.types"

export const SCRIPT_TAG_CATALOG: readonly ScriptTagDefinition[] = [
  {
    id: "cavebot-snippet",
    label: "Cavebot snippet",
    description:
      "Paste into a Cavebot script waypoint. Always call Cavebot.Walker.Resume() when done.",
  },
  {
    id: "alerts",
    label: "Alerts",
    description: "Sounds, warnings, and other notifications.",
  },
  {
    id: "hud",
    label: "HUD",
    description: "On-screen overlays, labels, and map markers.",
  },
  {
    id: "utility",
    label: "Utility",
    description: "Standalone helpers that run from the Scripts folder.",
  },
]

const scriptTagIdSet = new Set<string>(SCRIPT_TAG_IDS)

export const isScriptTagId = (value: string): value is ScriptTagId =>
  scriptTagIdSet.has(value)

export const getScriptTagLabel = (tag: string) =>
  SCRIPT_TAG_CATALOG.find((entry) => entry.id === tag)?.label ?? tag

export const hasCavebotSnippetTag = (tags: readonly string[]) =>
  tags.includes("cavebot-snippet")

export const buildScriptLibraryHref = ({
  query,
  tag,
}: ScriptLibraryHrefInput) => {
  const params = new URLSearchParams()

  if (query) {
    params.set("q", query)
  }

  if (tag) {
    params.set("tag", tag)
  }

  const search = params.toString()
  return search ? `/?${search}` : "/"
}
