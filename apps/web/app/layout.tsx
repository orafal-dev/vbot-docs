import type { Metadata } from "next"
import { Figtree, Geist_Mono } from "next/font/google"
import Link from "next/link"
import { IconBook2, IconCode } from "@tabler/icons-react"

import "./globals.css"
import { ThemeToggle } from "@/components/theme-toggle"
import { ThemeProvider } from "@/components/theme-provider"

const figtree = Figtree({ subsets: ["latin"], variable: "--font-figtree" })

const fontMono = Geist_Mono({
  subsets: ["latin"],
  variable: "--font-mono",
})

export const metadata: Metadata = {
  metadataBase: new URL(process.env.BETTER_AUTH_URL ?? "http://localhost:3000"),
  title: { default: "ValidusBot Scripts", template: "%s | ValidusBot" },
  description: "Readable Lua scripts for the ValidusBot runtime.",
  openGraph: {
    title: "ValidusBot Script Library",
    description: "Discover Lua automation written for inspection and adaptation.",
    type: "website",
  },
}

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode
}>) {
  return (
    <html
      lang="en"
      suppressHydrationWarning
      className={`${figtree.variable} ${fontMono.variable}`}
    >
      <body className="min-h-svh antialiased">
        <ThemeProvider>
          <header className="sticky top-0 z-40 border-b bg-background/90 backdrop-blur">
            <div className="mx-auto flex h-16 max-w-7xl items-center justify-between px-4 sm:px-6">
              <Link href="/" className="flex items-center gap-2 font-semibold" aria-label="ValidusBot home">
                <span className="grid size-9 place-items-center rounded-lg bg-primary text-primary-foreground">
                  <IconCode className="size-5" />
                </span>
                <span>ValidusBot</span>
              </Link>
              <nav className="flex items-center gap-1" aria-label="Primary navigation">
                <a href="/docs" className="inline-flex h-8 items-center gap-1.5 rounded-lg px-2.5 text-sm font-medium hover:bg-muted">
                  <IconBook2 className="size-4" /> Docs
                </a>
                <ThemeToggle />
              </nav>
            </div>
          </header>
          {children}
          <footer className="border-t">
            <div className="mx-auto flex max-w-7xl flex-col gap-2 px-4 py-8 text-sm text-muted-foreground sm:flex-row sm:justify-between sm:px-6">
              <p>ValidusBot Script Library</p>
              <p>Review code before running it.</p>
            </div>
          </footer>
        </ThemeProvider>
      </body>
    </html>
  )
}
