import path from "node:path"
import react from "@vitejs/plugin-react"
import { defineConfig } from "vitest/config"

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
  test: {
    name: "docs",
    environment: "happy-dom",
    setupFiles: ["./vitest.setup.ts"],
    include: ["src/**/*.{test,spec}.{ts,tsx}"],
    exclude: ["node_modules", ".next", "out"],
    css: false,
    clearMocks: true,
    restoreMocks: true,
  },
})
