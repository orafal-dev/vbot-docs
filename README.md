# ValidusBot

Bun and Turborepo monorepo for the ValidusBot Lua script library.

## Applications

- `apps/web` — public script library and invitation-only administration
- `apps/docs` — Fumadocs Lua API documentation

The web app owns `vbot.orafal.dev`. Vercel Microfrontends routes `/docs` and
`/docs/**` to the docs project.

## Development

```bash
bun install
bun run dev
```

The web app runs on port 3000 and docs on port 3001 when started individually.
See `apps/web/README.md` for Neon, Discord OAuth, migration, and first-admin
setup.

## Validation

```bash
npm run build
bun run lint
bun run types:check
```
