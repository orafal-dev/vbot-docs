import { cache } from "react"
import pierreDark from "@pierre/theme/pierre-dark"
import pierreLight from "@pierre/theme/pierre-light"
import { codeToHtml } from "shiki"
import type { ThemeRegistrationRaw } from "shiki"

export const highlightLuaCode = cache(async (code: string) =>
  codeToHtml(code, {
    lang: "lua",
    themes: {
      light: pierreLight as unknown as ThemeRegistrationRaw,
      dark: pierreDark as unknown as ThemeRegistrationRaw,
    },
    defaultColor: false,
  })
)
