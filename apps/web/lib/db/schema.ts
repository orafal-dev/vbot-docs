import { relations } from "drizzle-orm"
import {
  boolean,
  index,
  integer,
  jsonb,
  pgTable,
  text,
  timestamp,
  uniqueIndex,
} from "drizzle-orm/pg-core"

import type { ScriptStatus } from "./schema.types"

const timestamps = {
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  updatedAt: timestamp("updated_at", { withTimezone: true })
    .defaultNow()
    .$onUpdate(() => new Date())
    .notNull(),
}

export const user = pgTable("user", {
  id: text("id").primaryKey(),
  name: text("name").notNull(),
  email: text("email").notNull().unique(),
  emailVerified: boolean("email_verified").default(false).notNull(),
  image: text("image"),
  role: text("role").default("user").notNull(),
  // Retained for backward-compatible migrations after removing generic admin endpoints.
  banned: boolean("banned").default(false),
  banReason: text("ban_reason"),
  banExpires: timestamp("ban_expires", { withTimezone: true }),
  ...timestamps,
})

export const session = pgTable("session", {
  id: text("id").primaryKey(),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  token: text("token").notNull().unique(),
  ipAddress: text("ip_address"),
  userAgent: text("user_agent"),
  userId: text("user_id").notNull().references(() => user.id, { onDelete: "cascade" }),
  // Retained as a nullable compatibility column; impersonation is not exposed.
  impersonatedBy: text("impersonated_by"),
  ...timestamps,
}, (table) => [index("session_user_id_idx").on(table.userId)])

export const account = pgTable("account", {
  id: text("id").primaryKey(),
  accountId: text("account_id").notNull(),
  providerId: text("provider_id").notNull(),
  userId: text("user_id").notNull().references(() => user.id, { onDelete: "cascade" }),
  accessToken: text("access_token"),
  refreshToken: text("refresh_token"),
  idToken: text("id_token"),
  accessTokenExpiresAt: timestamp("access_token_expires_at", { withTimezone: true }),
  refreshTokenExpiresAt: timestamp("refresh_token_expires_at", { withTimezone: true }),
  scope: text("scope"),
  password: text("password"),
  ...timestamps,
}, (table) => [
  index("account_user_id_idx").on(table.userId),
  uniqueIndex("account_provider_account_idx").on(table.providerId, table.accountId),
])

export const verification = pgTable("verification", {
  id: text("id").primaryKey(),
  identifier: text("identifier").notNull(),
  value: text("value").notNull(),
  expiresAt: timestamp("expires_at", { withTimezone: true }).notNull(),
  ...timestamps,
}, (table) => [index("verification_identifier_idx").on(table.identifier)])

export const scripts = pgTable("scripts", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  slug: text("slug").notNull(),
  title: text("title").notNull(),
  description: text("description").notNull(),
  code: text("code").notNull(),
  screenshots: jsonb("screenshots").$type<string[]>().default([]).notNull(),
  status: text("status").$type<ScriptStatus>().default("draft").notNull(),
  published: boolean("published").default(false).notNull(),
  authorId: text("author_id").notNull().references(() => user.id, { onDelete: "restrict" }),
  createdAt: timestamps.createdAt,
  updatedAt: timestamps.updatedAt,
  publishedAt: timestamp("published_at", { withTimezone: true }),
  viewCount: integer("view_count").default(0).notNull(),
  copyCount: integer("copy_count").default(0).notNull(),
  downloadCount: integer("download_count").default(0).notNull(),
}, (table) => [
  uniqueIndex("scripts_slug_idx").on(table.slug),
  index("scripts_author_id_idx").on(table.authorId),
  index("scripts_published_idx").on(table.published, table.publishedAt),
])

export const adminInvitations = pgTable("admin_invitations", {
  id: text("id").primaryKey().$defaultFn(() => crypto.randomUUID()),
  email: text("email").notNull(),
  createdAt: timestamp("created_at", { withTimezone: true }).defaultNow().notNull(),
  acceptedAt: timestamp("accepted_at", { withTimezone: true }),
  acceptedBy: text("accepted_by").references(() => user.id, { onDelete: "set null" }),
}, (table) => [uniqueIndex("admin_invitations_email_idx").on(table.email)])

export const userRelations = relations(user, ({ many }) => ({
  sessions: many(session), accounts: many(account), scripts: many(scripts),
}))
export const sessionRelations = relations(session, ({ one }) => ({
  user: one(user, { fields: [session.userId], references: [user.id] }),
}))
export const accountRelations = relations(account, ({ one }) => ({
  user: one(user, { fields: [account.userId], references: [user.id] }),
}))
export const scriptRelations = relations(scripts, ({ one }) => ({
  author: one(user, { fields: [scripts.authorId], references: [user.id] }),
}))
