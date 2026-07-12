import { drizzleAdapter } from "@better-auth/drizzle-adapter"
import { and, eq, isNull } from "drizzle-orm"
import { headers } from "next/headers"
import { betterAuth } from "better-auth"

import { requireDb } from "@/lib/db"
import * as schema from "@/lib/db/schema"
import { getAuthEnvironment } from "@/lib/env"
import type { AdminSessionUser } from "./auth.types"

const normalizeEmail = (email: string) => email.trim().toLowerCase()

const createAuth = () => {
  const authEnvironment = getAuthEnvironment()
  const database = requireDb()

  return betterAuth({
    appName: "ValidusBot Script Library",
    baseURL: authEnvironment.baseURL,
    secret: authEnvironment.secret,
    database: drizzleAdapter(database, { provider: "pg", schema }),
    emailAndPassword: { enabled: false },
    user: {
      additionalFields: {
        role: {
          type: "string",
          required: true,
          defaultValue: "user",
          input: false,
        },
      },
    },
    socialProviders: {
      discord: {
        clientId: authEnvironment.discordClientId,
        clientSecret: authEnvironment.discordClientSecret,
        disableImplicitSignUp: true,
      },
    },
    databaseHooks: {
      user: {
        create: {
          before: async (newUser) => {
            if (!newUser.email || newUser.emailVerified !== true) {
              throw new Error("Discord must provide a verified email address.")
            }
            const email = normalizeEmail(newUser.email)
            const [invitation] = await database
              .select({ id: schema.adminInvitations.id })
              .from(schema.adminInvitations)
              .where(
                and(
                  eq(schema.adminInvitations.email, email),
                  isNull(schema.adminInvitations.acceptedAt)
                )
              )
              .limit(1)
            if (!invitation) {
              throw new Error(
                "This verified Discord email has not been invited."
              )
            }
            return {
              data: {
                ...newUser,
                email,
                role: "admin",
              },
            }
          },
          after: async (createdUser) => {
            await database
              .update(schema.adminInvitations)
              .set({ acceptedAt: new Date(), acceptedBy: createdUser.id })
              .where(
                and(
                  eq(
                    schema.adminInvitations.email,
                    normalizeEmail(createdUser.email)
                  ),
                  isNull(schema.adminInvitations.acceptedAt)
                )
              )
          },
        },
      },
    },
  })
}

let authInstance: ReturnType<typeof createAuth> | undefined

export const getAuth = () => {
  authInstance ??= createAuth()
  return authInstance
}

export const getAdminUser = async (): Promise<AdminSessionUser | null> => {
  const requestHeaders = await headers()
  const currentSession = await getAuth().api.getSession({
    headers: requestHeaders,
  })
  const currentUser = currentSession?.user as AdminSessionUser | undefined
  return currentUser?.role === "admin" ? currentUser : null
}
