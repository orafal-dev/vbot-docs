import { neon } from "@neondatabase/serverless"
import { drizzle } from "drizzle-orm/neon-http"

import * as schema from "./schema"

export const hasDatabase = Boolean(process.env.DATABASE_URL)

export const db = process.env.DATABASE_URL
  ? drizzle(neon(process.env.DATABASE_URL), { schema })
  : null

export const requireDb = () => {
  if (!db) {
    throw new Error("DATABASE_URL is required for this operation.")
  }

  return db
}
