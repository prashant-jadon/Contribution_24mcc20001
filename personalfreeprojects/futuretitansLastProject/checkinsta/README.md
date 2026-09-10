# checkinsta

A tool to audit any public Instagram influencer for **bot-follower risk** — the "am I being scammed by a paid influencer?" check.

- **Backend**: Node.js + Express, calls Apify actors for Instagram data (no IG login required).
- **Frontend**: Next.js (App Router) + Tailwind, dark premium UI.

## What it does

1. You paste an Instagram username or profile URL and choose a sample size (50–200).
2. Backend calls Apify:
   - Target profile (`apify/instagram-profile-scraper`)
   - Follower sample (`scraping_solutions/instagram-scraper-followers-following-no-cookies`)
   - Recent posts of the target (`apify/instagram-scraper`)
3. For **each sampled follower**, we re-scrape their profile and compute:
   - `username`, `profileUrl`, `status`, `displayName`, `bio`
   - `followers`, `following`, `postsCount`, `isPrivate`, `isVerified`
   - `recentPostsSampled`, `avgLikes`, `avgComments`, `engagementRate`
   - `followerFollowingRatio`, `postFrequencySignals`
   - `botScore` (0–1), `riskLevel` (low/medium/high/unknown), `confidence`
4. Aggregates a bot-follower percentage and a verdict on the influencer.

## Scoring model

`botScore` for a follower is a weighted blend of:
- Username pattern (digits, gibberish tails, no vowels)
- Follower/following ratio (thousands followed, few back = bot-like)
- Profile completeness (no bio / no posts / no display name / no pic)
- Engagement rate on their own posts (dead ratio = shell account)

Influencer verdict is derived from the % of high + half-of-medium risk followers in the sample.

## Setup

```bash
# Backend
cd backend
cp .env.example .env    # fill in APIFY_TOKEN
npm install
npm run dev             # listens on :4000

# Frontend
cd frontend
cp .env.local.example .env.local
npm install
npm run dev             # listens on :3000
```

Open http://localhost:3000, paste an Instagram handle, hit **Run audit**.

## Notes

- Default follower scraper is `scraping_solutions/instagram-scraper-followers-following-no-cookies` (no login / no cookies; free users share the actor's run budget, paid users are billed per result). Swap in any other follower actor by overriding `APIFY_FOLLOWERS_ACTOR` in `.env`; toggle to a "who this user follows" audit with `APIFY_FOLLOWERS_MODE=following`.
- Fetching 100–200 follower profiles takes a minute or two depending on Apify rate limits and the `FOLLOWER_ENRICH_CONCURRENCY` setting.
- Followers that Instagram marks private still count toward the sample; we score them mostly from profile shell signals.
