# DoiT

A private, cooperative real-life RPG built as a mobile-first installable web app.

**Production:** https://doit-flame.vercel.app

## Features
- One easy, one medium and one hard quest shared by each private group every day (Europe/Lisbon midnight).
- Users select one main quest; all three remain completable for full XP and a once-a-day 20% completion bonus.
- Upload photographic proof, automatically accepted without AI verification.
- 256 curated seed quests across 32 specific skills and 8 categories.
- Individual restrictions and earned reroll tokens, separate from shared daily selections.
- Private group invitation links, member-only activity feed, signed photo URLs, reactions and comments.
- Overall level, skill XP, achievements, streaks, streak protection, coins and cosmetic rewards.
- Group-owner admin panel to create, edit and deactivate group-specific quests.

## Tech
Vite, React, TypeScript, Supabase Auth/Postgres/Storage with RLS, Vercel and GitHub.

## Local development
1. Install dependencies with `npm install`.
2. Copy `.env.example` to `.env.local`.
3. Set `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` for your Supabase project.
4. Run `npm run dev`.
5. Run `npm run build` for a production compile.

## Database
Migrations are tracked in `supabase/migrations` and have been applied to the connected Supabase project. DoiT tables are prefixed `doit_`; helper functions are in the `doit_private` schema. The `doit-photos` storage bucket is private.

**Temporary integration note:** The current deployment uses an isolated `doit_` namespace and bucket inside an existing Supabase project because the dedicated $0/month project requires a separate cost-confirmation approval. Auth users are shared with the existing project. Before inviting outside users, allocate a dedicated project, add the app URL to Auth redirect allowlists, apply the DoiT migrations, and update Vercel env variables. Do not delete users from the shared auth project.

## Privacy and verification
Photo proof is trust-based. Uploads are re-encoded to JPEG without original EXIF metadata. Supabase RLS restricts group content; server-side logic awards XP and prevents same-day duplicate XP for the same quest. Signed image links are short-lived.

## Current limitations
- Authentication email confirmation redirects may depend on the shared project's redirect allowlist.
- No offline submission queue or push notifications.
- Account deletion is intentionally not automated while Auth is shared with another app.
- End-to-end UI testing requires a real signed-in browser session.
