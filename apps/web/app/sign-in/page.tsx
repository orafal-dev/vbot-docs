import type { Metadata } from "next"
import { redirect } from "next/navigation"

import { DiscordSignInButton } from "@/components/discord-sign-in-button"
import { Card, CardContent, CardDescription, CardHeader } from "@/components/ui/card"
import { getAdminUser } from "@/lib/auth"

export const metadata: Metadata = { title: "Admin sign in" }

export default async function SignInPage() {
  if (await getAdminUser()) redirect("/admin")
  return (
    <main className="grid min-h-[calc(100svh-8rem)] place-items-center px-4 py-12">
      <Card className="w-full max-w-md">
        <CardHeader className="text-center">
          <h1 className="font-heading text-2xl font-medium">Admin access</h1>
          <CardDescription>Sign in with the invited, verified Discord email. There is no public registration.</CardDescription>
        </CardHeader>
        <CardContent><DiscordSignInButton /></CardContent>
      </Card>
    </main>
  )
}
