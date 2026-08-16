import Link from "next/link"

import { Badge } from "@/components/ui/badge"
import {
  buildScriptLibraryHref,
  SCRIPT_TAG_CATALOG,
} from "@/lib/script-tags"
import type { ScriptTagFiltersProps } from "./script-tag-filters.types"

export const ScriptTagFilters = ({
  query,
  selectedTag,
}: ScriptTagFiltersProps) => (
  <nav aria-label="Filter scripts by tag" className="flex flex-wrap gap-2">
    <Badge
      variant={selectedTag ? "outline" : "default"}
      render={
        <Link
          href={buildScriptLibraryHref({ query })}
          aria-current={!selectedTag ? "true" : undefined}
        />
      }
    >
      All
    </Badge>
    {SCRIPT_TAG_CATALOG.map((tag) => {
      const isSelected = selectedTag === tag.id

      return (
        <Badge
          key={tag.id}
          variant={isSelected ? "default" : "outline"}
          render={
            <Link
              href={buildScriptLibraryHref({ query, tag: tag.id })}
              aria-current={isSelected ? "true" : undefined}
              aria-label={`Filter by ${tag.label}`}
            />
          }
        >
          {tag.label}
        </Badge>
      )
    })}
  </nav>
)
