#!/usr/bin/env python3
"""Generate Fumadocs API reference pages from the Lua scripting spec appendix."""

from __future__ import annotations

import json
import re
from collections import OrderedDict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "scripts" / "lua-llm-scripting-spec.md"
OUT_DIR = ROOT / "content" / "docs" / "api-reference"

MODULE_SLUGS = {
    "cavebot.lua": "cavebot",
    "cavebot_actions.lua": "cavebot-actions",
    "chat_channel.lua": "chat-channel",
    "chat_channel_storage.lua": "chat-channel-storage",
    "container.lua": "container",
    "cooldowns.lua": "cooldowns",
    "creature.lua": "creature",
    "creature_iterators.lua": "creatures",
    "engine.lua": "engine",
    "event_proxies.lua": "event-proxies",
    "features.lua": "features",
    "game.lua": "game",
    "hotkeys.lua": "hotkeys",
    "hud_wrapper.lua": "hud",
    "inventory.lua": "inventory",
    "item.lua": "item",
    "lua_consts.lua": "constants",
    "map.lua": "map",
    "minimap.lua": "minimap",
    "module.lua": "module",
    "npc_trade_storage.lua": "npc-trade",
    "position.lua": "position",
    "self.lua": "self",
    "sound.lua": "sound",
    "spells.lua": "spells",
    "vip.lua": "vip",
    "zz_api_surface.lua": "api-surface",
}

MODULE_TITLES = {
    "cavebot.lua": "Cavebot",
    "cavebot_actions.lua": "Cavebot Actions",
    "chat_channel.lua": "ChatChannel",
    "chat_channel_storage.lua": "ChatChannelStorage",
    "container.lua": "Container",
    "cooldowns.lua": "Cooldowns",
    "creature.lua": "Creature",
    "creature_iterators.lua": "Creatures",
    "engine.lua": "Engine",
    "event_proxies.lua": "Event Proxies",
    "features.lua": "Features",
    "game.lua": "Game",
    "hotkeys.lua": "Hotkeys",
    "hud_wrapper.lua": "HUD",
    "inventory.lua": "Inventory",
    "item.lua": "Item",
    "lua_consts.lua": "Constants",
    "map.lua": "Map",
    "minimap.lua": "Minimap",
    "module.lua": "Module",
    "npc_trade_storage.lua": "NpcTradeStorage",
    "position.lua": "Position",
    "self.lua": "Self",
    "sound.lua": "Sound",
    "spells.lua": "Spells",
    "vip.lua": "VIP",
    "zz_api_surface.lua": "API Surface",
}

# Valid public API signatures only (excludes prose notes accidentally listed in the spec).
FUNCTION_SIGNATURE = re.compile(r"^[\w]+(?:[:.][\w]+)*\([^)]*\)$")


def parse_appendix(text: str) -> list[dict]:
    start = text.find("## Appendix A:")
    if start == -1:
        raise SystemExit("Appendix A not found in spec")

    appendix = text[start:]
    sections = re.split(r"\n### ([^\n]+\.lua)\s*\n", appendix)[1:]

    modules: list[dict] = []
    for i in range(0, len(sections), 2):
        filename = sections[i].strip()
        body = sections[i + 1]
        exported: list[str] = []
        functions: list[str] = []
        notes: list[str] = []
        internal: list[str] = []
        current = None

        for raw_line in body.splitlines():
            line = raw_line.strip()
            if line.startswith("Exported tables/constants:"):
                current = "exported"
                continue
            if line.startswith("Functions:"):
                current = "functions"
                continue
            if line.startswith("Internal local helpers, not public API:"):
                current = "internal"
                continue
            if not line.startswith("- "):
                continue
            entry = line[2:].strip()
            if current == "exported":
                exported.append(entry)
            elif current == "functions":
                if FUNCTION_SIGNATURE.match(entry):
                    functions.append(entry)
                else:
                    notes.append(entry)
            elif current == "internal":
                internal.append(entry)

        modules.append(
            {
                "filename": filename,
                "exported": exported,
                "functions": functions,
                "notes": notes,
                "internal": internal,
            }
        )

    return modules


def get_function_group(signature: str) -> str:
    if ":" in signature:
        return signature.split(":", 1)[0]
    if "." in signature:
        return signature.rsplit(".", 1)[0]
    return "General"


def group_functions(functions: list[str]) -> OrderedDict[str, list[str]]:
    grouped: OrderedDict[str, list[str]] = OrderedDict()
    for fn in sorted(functions, key=lambda s: (get_function_group(s), s)):
        group = get_function_group(fn)
        grouped.setdefault(group, []).append(fn)
    return grouped


def escape_mdx(text: str) -> str:
    """Prevent MDX from treating `{` ... `}` as JSX expressions."""
    return text.replace("{", "\\{").replace("}", "\\}")


def format_note(note: str) -> str:
    """Render a spec note line as safe MDX (no nested backticks or JSX)."""
    note = note.replace("`", "'")

    match = re.match(
        r"^([\w]+(?::[\w]+)?(?:\([^)]*\))?)\s+(.*)$",
        note,
    )
    if match:
        api, body = match.group(1), match.group(2).strip()
        if (":" in api or api.endswith(")")) and body:
            line = f"- **{api}** — {body}" if not body.startswith("—") else f"- **{api}** {body}"
            return escape_mdx(line)

    return escape_mdx(f"- {note}")


def render_function_groups(functions: list[str]) -> list[str]:
    lines: list[str] = []
    grouped = group_functions(functions)
    multi_group = len(grouped) > 1

    for group, items in grouped.items():
        if multi_group:
            lines.extend([f"### {group}", ""])
        for fn in items:
            lines.append(f"- `{fn}`")
        lines.append("")

    return lines


def render_module_page(module: dict) -> str:
    filename = module["filename"]
    title = MODULE_TITLES.get(filename, filename.replace(".lua", "").replace("_", " ").title())
    exported = module["exported"]
    functions = module["functions"]
    notes = module.get("notes", [])

    lines = [
        "---",
        f"title: {title}",
        f"description: API reference for {title} ({filename})",
        "---",
        "",
        f"Core library: `{filename}`",
        "",
    ]

    if exported:
        lines.extend(["## Exported tables", ""])
        for item in exported:
            lines.append(f"- `{item}`")
        lines.append("")

    if functions:
        lines.extend(["## Functions", ""])
        lines.extend(render_function_groups(functions))

    if notes:
        lines.extend(["## Usage notes", ""])
        for note in notes:
            lines.append(format_note(note))
        lines.append("")

    lines.extend(
        [
            "## Notes",
            "",
            "Internal helper functions in the core library are not part of the public scripting API.",
            "Use only the functions listed above when writing user scripts.",
            "",
        ]
    )

    return "\n".join(lines)


def main() -> None:
    text = SPEC_PATH.read_text(encoding="utf-8")
    modules = parse_appendix(text)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    pages: list[str] = ["index"]
    index_lines = [
        "---",
        "title: API Reference",
        "description: Complete function index for ValidusBot core Lua libraries",
        "---",
        "",
        "Auto-generated index of every public function exported by ValidusBot core libraries.",
        "Each page corresponds to one core library file loaded from the bot's `Scripts/core` directory.",
        "",
        "## Modules",
        "",
    ]

    for module in modules:
        filename = module["filename"]
        slug = MODULE_SLUGS.get(filename, filename.replace(".lua", ""))
        title = MODULE_TITLES.get(filename, slug)
        page_path = OUT_DIR / f"{slug}.mdx"
        page_path.write_text(render_module_page(module), encoding="utf-8")
        fn_count = len(module["functions"])
        index_lines.append(f"- [{title}](/docs/api-reference/{slug}) — `{filename}` ({fn_count} functions)")
        pages.append(slug)

    index_lines.extend(
        [
            "",
            "## Conventions",
            "",
            "- All modules use **PascalCase** names (`Self`, `Map`, `Cavebot`, etc.).",
            "- Undocumented or internal helpers are unavailable to user scripts.",
            "- Some APIs return `nil` when game state or bindings are unavailable — always guard calls.",
            "",
        ]
    )

    (OUT_DIR / "index.mdx").write_text("\n".join(index_lines), encoding="utf-8")

    meta = {"title": "API Reference", "pages": pages}
    (OUT_DIR / "meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")

    print(f"Generated {len(modules)} API reference pages in {OUT_DIR}")


if __name__ == "__main__":
    main()
