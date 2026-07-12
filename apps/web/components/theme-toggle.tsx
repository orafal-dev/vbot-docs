"use client"

import { IconMoon, IconSun } from "@tabler/icons-react"
import { useTheme } from "next-themes"

import { Button } from "@/components/ui/button"

export const ThemeToggle = () => {
  const { resolvedTheme, setTheme } = useTheme()
  const currentTheme = resolvedTheme === "dark" ? "dark" : "light"
  const targetTheme = currentTheme === "dark" ? "light" : "dark"
  const handleToggleTheme = () => setTheme(targetTheme)

  return (
    <Button
      type="button"
      variant="ghost"
      size="icon"
      onClick={handleToggleTheme}
      aria-label={`Switch from ${currentTheme} to ${targetTheme} theme`}
      title={`Current theme: ${currentTheme}. Switch to ${targetTheme}.`}
    >
      <IconSun className="hidden size-4 dark:block" />
      <IconMoon className="size-4 dark:hidden" />
      <span className="sr-only">
        Current theme: {currentTheme}; target theme: {targetTheme}
      </span>
    </Button>
  )
}
