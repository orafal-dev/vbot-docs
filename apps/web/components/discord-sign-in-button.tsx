"use client"

import { useState } from "react"
import { IconBrandDiscord } from "@tabler/icons-react"
import { createAuthClient } from "better-auth/react"

import { Button } from "@/components/ui/button"

const authClient = createAuthClient()

export const DiscordSignInButton = () => {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState("")

  const handleSignIn = async () => {
    setIsLoading(true)
    setError("")
    let signInStarted = false

    try {
      const result = await authClient.signIn.social({
        provider: "discord",
        callbackURL: "/admin",
        requestSignUp: true,
      })

      if (result.error) {
        throw new Error(result.error.message ?? "Discord sign-in failed.")
      }

      signInStarted = true
    } catch (signInError) {
      setError(
        signInError instanceof Error
          ? signInError.message
          : "Discord sign-in failed."
      )
    } finally {
      if (!signInStarted) {
        setIsLoading(false)
      }
    }
  }

  return (
    <div className="grid gap-3">
      <Button
        type="button"
        size="lg"
        onClick={handleSignIn}
        disabled={isLoading}
        aria-busy={isLoading}
      >
        <IconBrandDiscord className="size-5" />
        {isLoading ? "Connecting…" : "Continue with Discord"}
      </Button>
      {error ? (
        <p role="alert" className="text-sm text-destructive">
          {error}
        </p>
      ) : null}
    </div>
  )
}
