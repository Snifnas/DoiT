# DoiT

A private, cooperative real-life RPG built as a mobile-first installable web app.

**Production:** https://doit-flame.vercel.app

## Features
- One easy, one medium and one hard quest shared by each private group every day (Europe/Lisbon midnight).
- Users select one main quest; all three remain completable for full XP and a once-a-day 20% completion bonus.
- Upload photographic proof, automatically accepted without AI verification.
- 192 active playful quests across 32 specific skills and 8 categories, with 256 older tasks retired rather than deleted.
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

**Dedicated infrastructure:** DoiT uses its own Supabase project (`plnlufbydxhgehwmoezi`) in London, with independent authentication, tables, RLS and private photo storage. All starter and replacement quests are seeded there. The 256 original tasks have been deactivated; 192 redesigned quests are active. Vercel production, preview and development settings target this project. For email confirmation links, verify that `https://doit-flame.vercel.app` is configured as the Supabase Auth site URL and allowed redirect. New accounts must be created inside this project; existing accounts from unrelated Supabase projects are not migrated.

## Privacy and verification
Photo proof is trust-based. Uploads are re-encoded to JPEG without original EXIF metadata. Supabase RLS restricts group content; server-side logic awards XP and prevents same-day duplicate XP for the same quest. Signed image links are short-lived.

## Current limitations
- Email confirmation links require the dedicated project's Auth site URL and redirect allowlist to include the production domain.
- No offline submission queue or push notifications.
- Self-service account deletion is not implemented yet.
- End-to-end UI testing requires a real signed-in browser session.
