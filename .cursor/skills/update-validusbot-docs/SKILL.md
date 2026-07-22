---
name: update-validusbot-docs
description: >-
  Sync and update ValidusBot Lua docs from the upstream lua-llm-scripting-spec.md
  and the local ValidusBot Scripts/core library. Use when the user asks to update
  docs, refresh the API reference, sync core Lua libraries, pull the newest
  ValidusBot scripting spec, or regenerate Fumadocs pages from core sources.
---

# Update ValidusBot Docs

Refresh `apps/docs` from two sources of truth:

1. **Upstream LLM spec** — https://github.com/petkoGH/validusbot-lua/blob/main/lua-llm-scripting-spec.md  
   Raw URL: `https://raw.githubusercontent.com/petkoGH/validusbot-lua/main/lua-llm-scripting-spec.md`
2. **Installed core library** — Windows  
   `C:\Users\olsza\AppData\Local\ValidusBot\Products\tibia\UserData\Scripts\core`  
   WSL path: `/mnt/c/Users/olsza/AppData/Local/ValidusBot/Products/tibia/UserData/Scripts/core`

Do **not** invent APIs. Spec + core annotations win over existing prose.

## Workflow checklist

Copy and track:

```
Docs update progress:
- [ ] 1. Sync sources (spec + core)
- [ ] 2. Diff what changed
- [ ] 3. Regenerate API reference
- [ ] 4. Update narrative docs (guides / getting-started / examples)
- [ ] 5. Fix generator module maps if new .lua files appeared
- [ ] 6. Validate build
- [ ] 7. Summarize changes for the user
```

### 1. Sync sources

From repo root:

```bash
bash apps/docs/scripts/sync-sources.sh
```

Overrides:

- `CORE_SCRIPTS_DIR=/path/to/Scripts/core` — alternate core location
- `SPEC_URL=...` — alternate raw spec URL

This writes:

- `apps/docs/scripts/lua-llm-scripting-spec.md`
- `apps/docs/scripts/core/*.lua` (mirrors install; deletes removed files)

If the sync script is missing, fetch/copy manually to those same destinations.

### 2. Diff what changed

```bash
cd /home/olsza/dev/vbot-docs
git status --short apps/docs/scripts apps/docs/content/docs
git diff --stat apps/docs/scripts/lua-llm-scripting-spec.md apps/docs/scripts/core
```

Focus review on:

- New/removed/renamed `*.lua` in core
- Spec sections: Hard Rules, Known Constraints, Core Libraries Overview, Practical Examples, Engine feature-control API, Appendix A
- Behavior notes that guides must mirror (nil rules, Engine snapshot semantics, HTTP/WS limits, hotkey alt rules, etc.)

### 3. Regenerate API reference

```bash
cd apps/docs && bun run generate:api-reference
# or: python3 scripts/generate-api-reference.py
```

Generator reads:

- Spec appendix → function/constant index
- Core `---` Lua annotations → params/returns/descriptions

Outputs under `apps/docs/content/docs/api-reference/` (`*.mdx`, `index.mdx`, `meta.json`). Treat these as generated — do not hand-edit unless fixing the generator.

### 4. Update narrative docs

API pages are generated. **Hand-written** pages must still track the spec:

| Spec area | Docs to update |
| --- | --- |
| Runtime Model / Public Module Naming | `getting-started/overview.mdx`, `runtime.mdx`, `content/docs/index.mdx` |
| Hard Rules / Safety Checklist / Template | `getting-started/safety.mdx`, `template.mdx` |
| Practical Script Examples | `content/docs/examples.mdx` |
| Core Libraries Overview (per module) | Matching guide in `content/docs/guides/` |
| Engine feature-control API | `guides/engine-features.mdx` |
| Known Constraints / Critical Constants | `guides/constants.mdx`, relevant guides (`hotkeys`, `networking`, …) |

Page ↔ module map: [page-map.md](page-map.md)

Rules for narrative edits:

- Prefer tables + short examples in the existing Fumadocs style
- Prefer `Engine.*` for new feature-control guidance; note legacy globals only as compatibility
- Keep PascalCase; never document removed aliases as supported
- When a rule changes (e.g. `os.exit`, hotkey alt), update safety + any guide that repeats it
- Add a new guide only when a major new module has no home and `meta.json` needs a page

### 5. Generator module maps

If core gained a new public `.lua` file that should appear in API docs, update in `apps/docs/scripts/generate-api-reference.py`:

- `MODULE_SLUGS`
- `MODULE_TITLES`

Skip bootstrap-only files such as `zz_api_surface.lua` unless the spec appendix lists them as public.

### 6. Validate

```bash
cd /home/olsza/dev/vbot-docs
npm run build
```

If this is docs-only and monorepo build is heavy, at minimum:

```bash
cd apps/docs && bun run types:check && bun run build
```

Fix failures before finishing.

### 7. Summarize for the user

Report:

- Spec commit/source refreshed (yes/no) and core sync path used
- New/changed/removed modules or notable APIs
- Which narrative pages were edited
- Build result

Do **not** commit unless the user asks.

## Source priority

1. Upstream `lua-llm-scripting-spec.md` (behavior, constraints, examples, appendix inventory)
2. Local `Scripts/core/*.lua` annotations (params, returns, descriptions)
3. Existing docs prose (style only — never override 1 or 2)

## Anti-patterns

- Hand-editing generated `api-reference/*.mdx` instead of regenerating
- Documenting undocumented/raw globals as public API
- Skipping core sync and regenerating from stale `scripts/core`
- Leaving guides claiming old rules after the spec changed them
