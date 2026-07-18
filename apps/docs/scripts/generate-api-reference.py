#!/usr/bin/env python3
"""Generate Fumadocs API reference pages from the Lua scripting spec appendix."""

from __future__ import annotations

import json
import os
import re
from collections import OrderedDict
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SPEC_PATH = ROOT / "scripts" / "lua-llm-scripting-spec.md"
DEFAULT_CORE_DIR = ROOT / "scripts" / "core"
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
    "http.lua": "http",
    "hud_wrapper.lua": "hud",
    "inventory.lua": "inventory",
    "item.lua": "item",
    "json.lua": "json",
    "lua_consts.lua": "constants",
    "map.lua": "map",
    "minimap.lua": "minimap",
    "module.lua": "module",
    "npc_trade_storage.lua": "npc-trade",
    "position.lua": "position",
    "self.lua": "self",
    "sound.lua": "sound",
    "spells.lua": "spells",
    "storage.lua": "storage",
    "vip.lua": "vip",
    "websocket.lua": "websocket",
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
    "http.lua": "Http",
    "hud_wrapper.lua": "HUD",
    "inventory.lua": "Inventory",
    "item.lua": "Item",
    "json.lua": "Json",
    "lua_consts.lua": "Constants",
    "map.lua": "Map",
    "minimap.lua": "Minimap",
    "module.lua": "Module",
    "npc_trade_storage.lua": "NpcTradeStorage",
    "position.lua": "Position",
    "self.lua": "Self",
    "sound.lua": "Sound",
    "spells.lua": "Spells",
    "storage.lua": "Storage",
    "vip.lua": "VIP",
    "websocket.lua": "WebSocket",
}

FUNCTION_DEF = re.compile(r"^function\s+([\w.:]+)\s*\(")
DOC_LINE = re.compile(r"^---(.*)$")
PARAM_TAG = re.compile(r"^@param\s+([\w]+)(\?)?\s+(\S+)(?:\s+(.*))?$")
RETURN_TAG = re.compile(r"^@return\s+(.+)$")
USAGE_TAG = re.compile(r"^@usage\s+(.+)$")
CLASS_OR_FIELD_TAG = re.compile(r"^@(class|field)\b")

APPENDIX_ENTRY = re.compile(r"^- `(.+)`\s*$")
CONSTANT_ENTRY = re.compile(r"^([\w]+(?:\.[\w]+)*)\s*=\s*(.+)$")
FUNCTION_ENTRY = re.compile(
    r"^([\w]+(?:[:.][\w]+)*)\s*\((.*)\)(?:\s*->\s*(.+))?$"
)
PARAM_SPLIT = re.compile(r",(?![^[]*\])")

def split_return_types(raw: str) -> list[str]:
    """Split multi-return type lists like 'table|nil, string|nil' into separate types."""
    raw = raw.strip()
    if not raw:
        return []
    segments = [part.strip() for part in raw.split(",") if part.strip()]
    if len(segments) > 1 and all(" " not in segment for segment in segments):
        return segments
    return [raw]




@dataclass
class ParamDoc:
    name: str
    optional: bool
    type: str
    description: str = ""


@dataclass
class ReturnDoc:
    raw: str


@dataclass
class FunctionDoc:
    summary: list[str] = field(default_factory=list)
    params: list[ParamDoc] = field(default_factory=list)
    returns: list[ReturnDoc] = field(default_factory=list)
    usage: list[str] = field(default_factory=list)

    @property
    def has_content(self) -> bool:
        return bool(self.summary or self.params or self.returns or self.usage)


@dataclass
class ParsedAppendixEntry:
    kind: str  # "function" | "constant" | "note"
    signature: str = ""
    name: str = ""
    display_signature: str = ""
    params: list[ParamDoc] = field(default_factory=list)
    returns: list[str] = field(default_factory=list)
    constant_name: str = ""
    constant_value: str = ""
    note: str = ""


def resolve_core_scripts_dir() -> Path:
    env_path = os.environ.get("CORE_SCRIPTS_DIR")
    if env_path:
        path = Path(env_path)
        if path.is_dir():
            return path
        raise SystemExit(f"CORE_SCRIPTS_DIR is not a directory: {path}")

    if DEFAULT_CORE_DIR.is_dir():
        return DEFAULT_CORE_DIR

    wsl_fallback = Path(
        "/mnt/c/Users/olsza/AppData/Local/ValidusBot/Products/tibia/UserData/Scripts/core"
    )
    if wsl_fallback.is_dir():
        return wsl_fallback

    raise SystemExit(
        "Core Lua scripts directory not found. "
        f"Expected {DEFAULT_CORE_DIR} or set CORE_SCRIPTS_DIR."
    )


def parse_doc_block(lines: list[str], function_index: int) -> list[str]:
    doc_lines: list[str] = []
    index = function_index - 1

    while index >= 0 and not lines[index].strip():
        index -= 1

    while index >= 0:
        match = DOC_LINE.match(lines[index].strip())
        if not match:
            break

        content = match.group(1).strip()
        if CLASS_OR_FIELD_TAG.match(content):
            break

        doc_lines.insert(0, content)
        index -= 1

    return doc_lines


def parse_function_doc(doc_lines: list[str]) -> FunctionDoc:
    doc = FunctionDoc()

    for line in doc_lines:
        if not line:
            continue

        if line.startswith("@"):
            param_match = PARAM_TAG.match(line)
            if param_match:
                name, optional_flag, type_name, description = param_match.groups()
                doc.params.append(
                    ParamDoc(
                        name=name,
                        optional=bool(optional_flag),
                        type=type_name,
                        description=(description or "").strip(),
                    )
                )
                continue

            return_match = RETURN_TAG.match(line)
            if return_match:
                for ret_type in split_return_types(return_match.group(1).strip()):
                    doc.returns.append(ReturnDoc(raw=ret_type))
                continue

            usage_match = USAGE_TAG.match(line)
            if usage_match:
                doc.usage.append(usage_match.group(1).strip())
                continue

            continue

        doc.summary.append(line)

    return doc


def parse_lua_docs(lua_path: Path) -> dict[str, FunctionDoc]:
    if not lua_path.is_file():
        return {}

    lines = lua_path.read_text(encoding="utf-8", errors="replace").splitlines()
    docs: dict[str, FunctionDoc] = {}

    for index, line in enumerate(lines):
        match = FUNCTION_DEF.match(line.strip())
        if not match:
            continue

        function_name = match.group(1)
        doc_lines = parse_doc_block(lines, index)
        if not doc_lines:
            continue

        parsed = parse_function_doc(doc_lines)
        if parsed.has_content:
            docs[function_name] = parsed

    return docs


def parse_param_list(raw_params: str) -> tuple[list[ParamDoc], list[str]]:
    """Parse typed appendix params into ParamDoc + clean display names."""
    raw_params = raw_params.strip()
    if not raw_params:
        return [], []

    params: list[ParamDoc] = []
    display_names: list[str] = []

    for part in PARAM_SPLIT.split(raw_params):
        part = part.strip()
        if not part:
            continue

        optional = False
        name = part
        type_name = ""

        if ":" in part:
            name_part, type_part = part.split(":", 1)
            name = name_part.strip()
            type_name = type_part.strip()
            if name.endswith("?"):
                optional = True
                name = name[:-1].strip()
        else:
            if name.endswith("?"):
                optional = True
                name = name[:-1].strip()

        display_names.append(name)
        params.append(
            ParamDoc(
                name=name,
                optional=optional,
                type=type_name,
                description="",
            )
        )

    return params, display_names


def parse_appendix_entry(entry: str) -> ParsedAppendixEntry:
    constant_match = CONSTANT_ENTRY.match(entry)
    if constant_match:
        return ParsedAppendixEntry(
            kind="constant",
            constant_name=constant_match.group(1).strip(),
            constant_value=constant_match.group(2).strip(),
            signature=entry,
        )

    function_match = FUNCTION_ENTRY.match(entry)
    if function_match:
        name = function_match.group(1).strip()
        raw_params = function_match.group(2) or ""
        raw_returns = (function_match.group(3) or "").strip()
        params, display_names = parse_param_list(raw_params)
        display_signature = f"{name}({', '.join(display_names)})"
        returns = split_return_types(raw_returns) if raw_returns else []
        return ParsedAppendixEntry(
            kind="function",
            name=name,
            signature=entry,
            display_signature=display_signature,
            params=params,
            returns=returns,
        )

    return ParsedAppendixEntry(kind="note", note=entry, signature=entry)


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
        functions: list[ParsedAppendixEntry] = []
        constants: list[ParsedAppendixEntry] = []
        notes: list[str] = []
        exported: list[str] = []

        # Legacy format support
        current = None
        for raw_line in body.splitlines():
            line = raw_line.strip()
            if not line:
                continue

            if line.startswith("Exported tables/constants:"):
                current = "exported"
                continue
            if line.startswith("Functions:"):
                current = "functions"
                continue
            if line.startswith("Internal local helpers, not public API:"):
                current = "internal"
                continue

            entry_match = APPENDIX_ENTRY.match(line)
            if entry_match:
                parsed = parse_appendix_entry(entry_match.group(1).strip())
                if parsed.kind == "function":
                    functions.append(parsed)
                elif parsed.kind == "constant":
                    constants.append(parsed)
                else:
                    notes.append(parsed.note)
                continue

            if not line.startswith("- "):
                continue

            entry = line[2:].strip().strip("`")
            if current == "exported":
                exported.append(entry)
            elif current == "functions":
                parsed = parse_appendix_entry(entry)
                if parsed.kind == "function":
                    functions.append(parsed)
                else:
                    notes.append(entry)
            elif current == "internal":
                continue
            else:
                parsed = parse_appendix_entry(entry)
                if parsed.kind == "function":
                    functions.append(parsed)
                elif parsed.kind == "constant":
                    constants.append(parsed)
                else:
                    notes.append(entry)

        if not exported and (functions or constants):
            roots: OrderedDict[str, None] = OrderedDict()
            for fn in functions:
                root = fn.name.split(":", 1)[0].split(".", 1)[0]
                roots[root] = None
            for const in constants:
                root = const.constant_name.split(".", 1)[0]
                roots[root] = None
            exported = list(roots.keys())

        modules.append(
            {
                "filename": filename,
                "exported": exported,
                "functions": functions,
                "constants": constants,
                "notes": notes,
            }
        )

    return modules


def get_function_group(name: str) -> str:
    if ":" in name:
        return name.split(":", 1)[0]
    if "." in name:
        return name.rsplit(".", 1)[0]
    return "General"


def group_functions(functions: list[ParsedAppendixEntry]) -> OrderedDict[str, list[ParsedAppendixEntry]]:
    grouped: OrderedDict[str, list[ParsedAppendixEntry]] = OrderedDict()
    for fn in sorted(functions, key=lambda item: (get_function_group(item.name), item.name)):
        group = get_function_group(fn.name)
        grouped.setdefault(group, []).append(fn)
    return grouped


def group_constants(constants: list[ParsedAppendixEntry]) -> OrderedDict[str, list[ParsedAppendixEntry]]:
    grouped: OrderedDict[str, list[ParsedAppendixEntry]] = OrderedDict()
    for const in constants:
        table = const.constant_name.split(".", 1)[0]
        grouped.setdefault(table, []).append(const)
    return grouped


def escape_mdx(text: str) -> str:
    return text.replace("{", "\\{").replace("}", "\\}")


def escape_table_cell(text: str) -> str:
    if not text:
        return ""
    return escape_mdx(text).replace("|", "&#124;")


def format_inline_code(text: str) -> str:
    """Render inline code in markdown table cells, escaping union-type pipes."""
    if not text:
        return ""
    safe = escape_mdx(text).replace("|", "\\|")
    return f"`{safe}`"



def split_return_raw(raw: str) -> tuple[str, str]:
    raw = raw.strip()
    parts = raw.split(None, 1)
    if len(parts) == 1:
        return parts[0], ""
    return parts[0], parts[1]



def alternate_lua_names(name: str) -> list[str]:
    """Map appendix public names to implementation function names in core Lua."""
    names = [name]

    if name.startswith("Features."):
        method = name.split(".", 1)[1]
        names.append(f"features{method}")

    if name.startswith("WebSocketConnection:"):
        method = name.split(":", 1)[1]
        names.append(f"Connection:{method}")

    return names


def lookup_lua_doc(lua_docs: dict[str, FunctionDoc], name: str) -> FunctionDoc | None:
    for candidate in alternate_lua_names(name):
        doc = lua_docs.get(candidate)
        if doc and doc.has_content:
            return doc
    return None


def merge_docs(appendix_fn: ParsedAppendixEntry, lua_doc: FunctionDoc | None) -> FunctionDoc:
    """Prefer Lua annotation docs; fill gaps from appendix type signatures."""
    doc = FunctionDoc()
    if lua_doc and lua_doc.has_content:
        doc.summary = list(lua_doc.summary)
        doc.params = list(lua_doc.params)
        doc.returns = list(lua_doc.returns)
        doc.usage = list(lua_doc.usage)

    if not doc.params and appendix_fn.params:
        if any(param.type for param in appendix_fn.params):
            doc.params = list(appendix_fn.params)

    if not doc.returns and appendix_fn.returns:
        doc.returns = [ReturnDoc(raw=ret) for ret in appendix_fn.returns]

    return doc


def render_params_table(doc: FunctionDoc) -> list[str]:
    lines = [
        "| Name | Type | Optional | Description |",
        "| :-- | :-- | :--: | :-- |",
    ]

    for param in doc.params:
        name = format_inline_code(param.name)
        type_cell = format_inline_code(param.type) if param.type else ""
        optional = "Yes" if param.optional else ""
        description = escape_table_cell(param.description)
        lines.append(f"| {name} | {type_cell} | {optional} | {description} |")

    lines.append("")
    return lines


def render_returns_table(doc: FunctionDoc) -> list[str]:
    lines = [
        "| Type | Description |",
        "| :-- | :-- |",
    ]

    for ret in doc.returns:
        type_part, description = split_return_raw(ret.raw)
        type_cell = format_inline_code(type_part)
        description_cell = escape_table_cell(description)
        lines.append(f"| {type_cell} | {description_cell} |")

    lines.append("")
    return lines


def render_function_entry(appendix_fn: ParsedAppendixEntry, doc: FunctionDoc) -> list[str]:
    lines = [f"#### `{appendix_fn.display_signature}`", ""]

    if not doc.has_content:
        return lines

    if doc.summary:
        for paragraph in doc.summary:
            lines.append(escape_mdx(paragraph))
        lines.append("")

    if doc.params:
        lines.extend(["**Parameters**", ""])
        lines.extend(render_params_table(doc))

    if doc.returns:
        lines.extend(["**Returns**", ""])
        lines.extend(render_returns_table(doc))

    if doc.usage:
        lines.extend(["**Usage**", ""])
        for example in doc.usage:
            lines.extend(["```lua", example, "```", ""])

    return lines


def render_function_groups(
    functions: list[ParsedAppendixEntry], lua_docs: dict[str, FunctionDoc]
) -> list[str]:
    lines: list[str] = []
    grouped = group_functions(functions)
    multi_group = len(grouped) > 1

    for group, items in grouped.items():
        if multi_group:
            lines.extend([f"### {group}", ""])

        for appendix_fn in items:
            lua_doc = lookup_lua_doc(lua_docs, appendix_fn.name)
            doc = merge_docs(appendix_fn, lua_doc)
            lines.extend(render_function_entry(appendix_fn, doc))

    return lines


def render_constants_section(constants: list[ParsedAppendixEntry]) -> list[str]:
    if not constants:
        return []

    lines = ["## Constants", ""]
    grouped = group_constants(constants)

    for table, items in grouped.items():
        lines.extend([f"### `{table}`", ""])
        lines.extend(
            [
                "| Constant | Value |",
                "| :-- | :-- |",
            ]
        )
        for item in items:
            name = format_inline_code(item.constant_name)
            value = format_inline_code(item.constant_value)
            lines.append(f"| {name} | {value} |")
        lines.append("")

    return lines


def render_module_page(module: dict, lua_docs: dict[str, FunctionDoc]) -> str:
    filename = module["filename"]
    title = MODULE_TITLES.get(filename, filename.replace(".lua", "").replace("_", " ").title())
    exported = module["exported"]
    functions: list[ParsedAppendixEntry] = module["functions"]
    constants: list[ParsedAppendixEntry] = module["constants"]
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
        lines.extend(render_function_groups(functions, lua_docs))

    lines.extend(render_constants_section(constants))

    if notes:
        lines.extend(["## Usage notes", ""])
        for note in notes:
            lines.append(escape_mdx(f"- {note}"))
        lines.append("")

    lines.extend(
        [
            "## Notes",
            "",
            "Internal helper functions in the core library are not part of the public scripting API.",
            "Use only the functions listed above when writing user scripts.",
            "Descriptions, parameters, and return values come from `---` Lua annotation blocks in the core source when available,",
            "and from typed signatures in the public API appendix otherwise.",
            "",
        ]
    )

    return "\n".join(lines)


def main() -> None:
    core_dir = resolve_core_scripts_dir()
    text = SPEC_PATH.read_text(encoding="utf-8")
    modules = parse_appendix(text)
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    known_slugs = {
        MODULE_SLUGS.get(module["filename"], module["filename"].replace(".lua", ""))
        for module in modules
    }
    for existing in OUT_DIR.glob("*.mdx"):
        if existing.stem in {"index"}:
            continue
        if existing.stem not in known_slugs:
            existing.unlink()

    pages: list[str] = ["index"]
    total_functions = 0
    total_documented = 0

    index_lines = [
        "---",
        "title: API Reference",
        "description: Complete function index for ValidusBot core Lua libraries",
        "---",
        "",
        "Auto-generated index of every public function exported by ValidusBot core libraries.",
        "Each page corresponds to one core library file loaded from the bot's `Scripts/core` directory.",
        "Function descriptions, parameters, and return values are extracted from Lua `---` annotation blocks when present,",
        "and from typed signatures in the public API appendix otherwise.",
        "",
        "## Modules",
        "",
    ]

    for module in modules:
        filename = module["filename"]
        slug = MODULE_SLUGS.get(filename, filename.replace(".lua", ""))
        title = MODULE_TITLES.get(filename, slug)
        lua_docs = parse_lua_docs(core_dir / filename)
        page_path = OUT_DIR / f"{slug}.mdx"
        page_path.write_text(render_module_page(module, lua_docs), encoding="utf-8")

        fn_count = len(module["functions"])
        documented_count = sum(
            1
            for appendix_fn in module["functions"]
            if merge_docs(appendix_fn, lookup_lua_doc(lua_docs, appendix_fn.name)).has_content
        )
        total_functions += fn_count
        total_documented += documented_count
        const_count = len(module["constants"])
        suffix = f"{documented_count}/{fn_count} documented"
        if const_count:
            suffix += f", {const_count} constants"
        index_lines.append(
            f"- [{title}](/docs/api-reference/{slug}) — `{filename}` ({suffix})"
        )
        pages.append(slug)

    index_lines.extend(
        [
            "",
            "## Conventions",
            "",
            "- All modules use **PascalCase** names (`Self`, `Map`, `Cavebot`, `Json`, `Http`, etc.).",
            "- Prefer `Engine.*` namespaces for feature configuration; older globals such as `Features` remain for compatibility.",
            "- Undocumented or internal helpers are unavailable to user scripts.",
            "- Some APIs return `nil` when game state or bindings are unavailable — always guard calls.",
            "- HTTP/WebSocket calls must run inside a managed script coroutine and yield cooperatively.",
            "- Parameter and return annotations follow Lua Language Server (`---@param`, `---@return`) conventions from core library source when available.",
            "",
        ]
    )

    (OUT_DIR / "index.mdx").write_text("\n".join(index_lines), encoding="utf-8")

    meta = {"title": "API Reference", "pages": pages}
    (OUT_DIR / "meta.json").write_text(json.dumps(meta, indent=2) + "\n", encoding="utf-8")

    print(f"Generated {len(modules)} API reference pages in {OUT_DIR}")
    print(f"Core source: {core_dir}")
    print(f"Documented functions: {total_documented}/{total_functions}")


if __name__ == "__main__":
    main()
