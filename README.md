# CHS CRM

Electron + React + TypeScript rebuild of Community Home Solutions' CRM —
foreclosure/title file management, documents stored in Google Drive instead
of locally or in Firebase Storage.

Reimagined from `title-crm` (the Ohio/Texas parcel-management app it was
modeled on) but with a different data model (kept from the original Flutter
chs-crm — richer foreclosure-specific fields), no auction crawler/scraper,
no LTC/COT package builder, and documents live in Drive instead of on local
disk.

This folder is intentionally **not tracked by title-crm's git repo** — it's
listed in `../title-crm/.gitignore` and should get its own separate git
history if you want version control on it (`git init` inside this folder).
That keeps your personal/business project out of your employer's repository.

## Build status

Feature-complete for v1: project skeleton, data model, theme, login/pending-
approval flow, property list with search, the full tabbed property detail
view (Overview, Contacts, Deeds, Mortgages, Judgments, Easements, Vesting,
Notes, Auctions, Documents), Google Drive integration (OAuth, folder
resolution, upload/download), the unified Document Reader (category-driven
AI extraction with per-county template overrides), profile avatars stored
in Drive, and the live Google Sheet export.

Not yet done: an actual `npm install` + build hasn't been run against this
code yet — do that first thing to catch anything version-related before
relying on it for real files. See "Setup" below.

## Using Google Drive once it's set up

Go to Settings → **Connect Google Drive** and sign in once with your
Workspace account (a browser tab opens for the Google consent screen, then
you can close it). After that, the Documents tab on any property lets you
upload files — each upload lands in
`<Shared Drive>/State/County/TaxAccountNo-or-FileNumber/Category/`,
creating any folder in that chain that doesn't exist yet. Set State, County,
and a Tax Account No. (or File Number) on the Overview tab before uploading
— that's what the folder path is built from.

## Document Reader & Live Sheet

Document Reader (sidebar) reads tax cards, deeds, and other documents with AI
and files the results automatically — pick a category, optionally add a
county-specific field template in Settings → Extraction Templates (different
counties format things differently), add a file or a whole folder, hit Run.
Tax Card extractions auto-create a new file keyed by tax account number if
nothing matches; everything else needs an existing file to attach to (it'll
try to match by address, and ask you to pick one manually if it can't).

Live Sheet (Settings → Live Google Sheet → Create Live Sheet) is a single
shared spreadsheet that updates automatically every time anyone saves a
property in the app — no scheduled job, no manual export. Use "Full Resync"
after creating it to backfill existing files, or any time the sheet and the
app seem to have drifted apart.

## Setup

### 1. Install dependencies

```
npm install
```

### 2. Google Cloud / Workspace setup (needed for Drive, the Document Reader, and the live Sheet — everything except basic property/Firestore data entry)

1. Create or pick a Google Cloud project under the Community Home Solutions Workspace.
2. Enable the **Google Drive API** and **Google Sheets API** for that project.
3. Create an OAuth 2.0 Client ID (Credentials → Create Credentials → OAuth client ID → **Desktop app**).
4. Set the OAuth consent screen's User Type to **Internal** — this skips Google's app-verification review since it's restricted to your Workspace domain.
5. Create a Shared Drive (not a personal folder) — e.g. "CHS CRM Documents" — and add your brother (and later, other team members) as a member with Content Manager access.
6. Copy `.env.example` to `.env` and fill in the Client ID, Client Secret, and the Shared Drive's ID.

### 3. Firebase — starting fresh within the existing `chs-crm` project

`src/firebase.ts` already points at the existing `chs-crm` Firebase project (same one the Flutter version used), so no new Firebase project setup is needed.

To clear out the old Flutter-era data before you start entering real files:

1. Firebase Console → Project Settings → Service Accounts → Generate new private key. Save it as `scripts/firebase-admin-key.json` (already gitignored).
2. `cd scripts && npm install`
3. `node reset-firestore.js` (dry run — shows what it would do)
4. `node reset-firestore.js --confirm` (actually deletes the old `properties` and `users` collections; leaves the new `documentCategories` collection alone)

### 4. Run it

```
npm run electron-dev
```

## First-admin note

New sign-ups land unapproved (`approved: false`) — that's the pending-approval
gate. The very first account needs to be promoted to `role: "admin", approved:
true` by hand, directly in the Firestore console, since there's no admin yet
to approve it from inside the app. After that, admins can approve new
sign-ups from the app itself.
