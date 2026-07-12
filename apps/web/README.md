# ValidusBot Web

Public Lua script library and invitation-only administration for ValidusBot.

## Local setup

1. Copy `.env.example` to `.env.local` and provide Neon, Better Auth, and Discord OAuth values.
2. Create and apply a migration with `bun run db:generate` and `bun run db:migrate`.
3. Create the initial invitation directly in `admin_invitations` using a normalized, verified Discord email.
4. Run `bun run dev`.

There is no public signup. Discord account creation explicitly requests signup through the sign-in button, but the Better Auth user creation hook rejects any missing, unverified, uninvited, or already-used email. Every user admitted through the admin invitation table receives the admin role, including the first user.

## Build fallback

The small demo collection in `lib/scripts.ts` is available only during `next build`. Development can opt in explicitly with `VBOT_ALLOW_DEMO_DATA=true`. Production runtime never uses demo data or build credentials: missing database or auth variables fail with a clear error. If `DATABASE_URL` is configured, database errors are never replaced with demo content. Admin and mutation operations always require a real database.

## Vercel Microfrontends

`microfrontends.json` uses the plausible Vercel project names `vbot-web` and `vbot-docs`. Replace those names and the `vbot-web.vercel.app` fallback with the actual projects before deployment. Package mappings remain `@vbot/web` and `@vbot/docs`; docs owns its `/docs`, search, Open Graph, and LLM text routes.
