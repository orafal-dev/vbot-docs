import Link from "next/link"
import { desc } from "drizzle-orm"
import { IconEdit, IconPlus } from "@tabler/icons-react"

import { createInvitation } from "./actions"
import { DeleteScriptButton } from "@/components/delete-script-button"
import { PendingSubmitButton } from "@/components/pending-submit-button"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table"
import { requireDb } from "@/lib/db"
import { adminInvitations } from "@/lib/db/schema"
import { getAllScriptsForAdmin } from "@/lib/scripts"

export default async function AdminPage({ searchParams }: { searchParams: Promise<{ error?: string; invited?: string }> }) {
  const database = requireDb()
  const [{ error, invited }, scripts, invitations] = await Promise.all([
    searchParams,
    getAllScriptsForAdmin(),
    database
      .select()
      .from(adminInvitations)
      .orderBy(desc(adminInvitations.createdAt)),
  ])
  return (
    <div className="grid gap-8">
      {error ? <p role="alert" className="rounded-lg border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive">{error}</p> : null}
      {invited ? <p role="status" className="rounded-lg border border-primary/30 bg-primary/10 p-3 text-sm">Invitation created.</p> : null}
      <section>
        <div className="mb-4 flex items-center justify-between"><div><h2 className="text-xl font-semibold">Scripts</h2><p className="text-sm text-muted-foreground">{scripts.length} total scripts</p></div><Button render={<Link href="/admin/scripts/new" />}><IconPlus /> New script</Button></div>
        <Card className="overflow-hidden p-0"><Table><TableHeader><TableRow><TableHead>Script</TableHead><TableHead>Status</TableHead><TableHead>Updated</TableHead><TableHead className="text-right">Actions</TableHead></TableRow></TableHeader><TableBody>{scripts.map((script) => <TableRow key={script.id}><TableCell><p className="font-medium">{script.title}</p><p className="text-xs text-muted-foreground">/{script.slug}</p></TableCell><TableCell><Badge variant={script.published ? "default" : "secondary"}>{script.published ? "Published" : "Draft"}</Badge></TableCell><TableCell className="text-muted-foreground">{script.updatedAt.toLocaleDateString()}</TableCell><TableCell><div className="flex justify-end gap-1"><Button variant="ghost" size="icon" render={<Link href={`/admin/scripts/${script.id}/edit`} aria-label={`Edit ${script.title}`} />}><IconEdit /></Button><DeleteScriptButton id={script.id} title={script.title} /></div></TableCell></TableRow>)}</TableBody></Table></Card>
      </section>
      <Card><CardHeader><CardTitle>Admin invitations</CardTitle><CardDescription>Only a verified Discord email on this allowlist can create an account.</CardDescription></CardHeader><CardContent className="grid gap-6">
        <form action={createInvitation} className="flex flex-col gap-3 sm:flex-row sm:items-end"><div className="grid flex-1 gap-2"><Label htmlFor="email">Verified email</Label><Input id="email" name="email" type="email" required placeholder="admin@example.com" /></div><PendingSubmitButton idleLabel="Create invitation" pendingLabel="Inviting…" /></form>
        <div className="overflow-hidden rounded-lg border"><Table><TableHeader><TableRow><TableHead>Email</TableHead><TableHead>Status</TableHead><TableHead>Created</TableHead></TableRow></TableHeader><TableBody>{invitations.map((invitation) => <TableRow key={invitation.id}><TableCell>{invitation.email}</TableCell><TableCell><Badge variant={invitation.acceptedAt ? "secondary" : "outline"}>{invitation.acceptedAt ? "Accepted" : "Pending"}</Badge></TableCell><TableCell className="text-muted-foreground">{invitation.createdAt.toLocaleDateString()}</TableCell></TableRow>)}</TableBody></Table></div>
      </CardContent></Card>
    </div>
  )
}
