import Link from "next/link"
import { redirect } from "next/navigation"

import { Badge } from "@/components/ui/badge"
import { getAdminUser } from "@/lib/auth"

export default async function AdminLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  const adminUser = await getAdminUser()
  if (!adminUser) redirect("/sign-in")
  return (
    <main className="mx-auto min-h-[calc(100svh-8rem)] max-w-7xl px-4 py-10 sm:px-6">
      <div className="mb-10 flex flex-col gap-4 border-b pb-6 sm:flex-row sm:items-center sm:justify-between">
        <div><div className="flex items-center gap-2"><h1 className="text-2xl font-semibold">Script administration</h1><Badge>Admin</Badge></div><p className="mt-1 text-sm text-muted-foreground">Signed in as {adminUser.email}</p></div>
        <nav className="flex gap-4 text-sm font-medium" aria-label="Admin navigation"><Link href="/admin" className="hover:text-primary">Dashboard</Link><Link href="/admin/scripts/new" className="hover:text-primary">New script</Link></nav>
      </div>
      {children}
    </main>
  )
}
