"use client"

import { useState } from "react"
import { StreamLanguage } from "@codemirror/language"
import { lua } from "@codemirror/legacy-modes/mode/lua"
import { oneDark } from "@codemirror/theme-one-dark"
import CodeMirror from "@uiw/react-codemirror"
import { useTheme } from "next-themes"

import type { LuaEditorProps } from "./lua-editor.types"

const luaLanguage = StreamLanguage.define(lua)

export const LuaEditor = ({ name, value, onChange }: LuaEditorProps) => {
  const { resolvedTheme } = useTheme()
  const [code, setCode] = useState(value)

  const handleChange = (nextCode: string) => {
    setCode(nextCode)
    onChange?.(nextCode)
  }

  return (
    <div className="overflow-hidden rounded-xl border bg-card">
      <CodeMirror
        value={code}
        height="420px"
        extensions={[luaLanguage]}
        theme={resolvedTheme === "dark" ? oneDark : "light"}
        onChange={handleChange}
        basicSetup={{ lineNumbers: true, foldGutter: true }}
        aria-label="Lua script code editor"
      />
      <textarea name={name} value={code} readOnly hidden aria-hidden="true" />
    </div>
  )
}
