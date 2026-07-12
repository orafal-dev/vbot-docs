"use client"

import dynamic from "next/dynamic"

import { Skeleton } from "@/components/ui/skeleton"
import type { LuaEditorProps } from "./lua-editor.types"

const DynamicLuaEditor = dynamic(
  () => import("./lua-editor").then((module) => module.LuaEditor),
  {
    ssr: false,
    loading: () => (
      <Skeleton
        className="h-[420px] w-full rounded-xl"
        aria-label="Loading Lua editor"
      />
    ),
  }
)

export const LuaEditorField = (props: LuaEditorProps) => (
  <DynamicLuaEditor {...props} />
)
