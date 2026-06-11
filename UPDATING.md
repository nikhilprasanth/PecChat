# Updating Petrocil Chat from Upstream LibreChat

This document is written for an LLM assistant (Claude Code or similar) performing
an upstream merge. Follow it exactly. Every section is actionable — no guessing.

---

## 1. What Makes This Fork Different

This is a **thin white-label fork** of LibreChat. The upstream repo is
`https://github.com/danny-avila/LibreChat`. All Petrocil customisations are
isolated to a small set of frontend files plus config files that upstream does
not own. The backend (`/api`, `/packages/*`) is **not modified** and should
merge cleanly every time.

Petrocil-owned files that upstream will never touch (safe to keep as-is):

```
librechat.yaml
.env
docker-compose.override.yml
prepare.bat
scripts/deploy-template.bat
scripts/stop-template.bat
scripts/restart-template.bat
scripts/deploy-override.yml
client/public/assets/logo.png
client/public/assets/favicon-32x32.png
client/public/assets/favicon-16x16.png
client/public/assets/apple-touch-icon-180x180.png
```

Files **modified from upstream** that may conflict on merge:

| File | What Petrocil changed |
|---|---|
| `client/index.html` | `<title>` and `<meta name="description">` |
| `client/src/routes/Layouts/Startup.tsx` | Fallback string in `document.title` assignment |
| `client/src/components/Auth/AuthLayout.tsx` | `src="assets/logo.svg"` → `logo.png`; alt fallback string |
| `client/src/components/Chat/Footer.tsx` | Default footer string literal |
| `client/src/components/Nav/SettingsTabs/About/About.tsx` | `"LibreChat version:"` label string |
| `client/src/components/Agents/Marketplace.tsx` | Page title string |
| `client/src/locales/en/translation.json` | Value of `com_agents_mcp_trust_subtext` |

---

## 2. Pre-Merge Checklist

Before pulling upstream, record the current state of the seven conflict-prone files:

```bat
git diff HEAD -- client/index.html
git diff HEAD -- client/src/routes/Layouts/Startup.tsx
git diff HEAD -- client/src/components/Auth/AuthLayout.tsx
git diff HEAD -- client/src/components/Chat/Footer.tsx
git diff HEAD -- client/src/components/Nav/SettingsTabs/About/About.tsx
git diff HEAD -- client/src/components/Agents/Marketplace.tsx
git diff HEAD -- client/src/locales/en/translation.json
```

You don't need to act on these — just confirm the Petrocil changes are present
before starting, so you have a reference if conflicts arise.

---

## 3. Fetch and Merge Upstream

```bat
REM Add upstream remote if not already present
git remote add upstream https://github.com/danny-avila/LibreChat.git

REM Fetch latest
git fetch upstream

REM Check the upstream changelog before merging
REM  → https://www.librechat.ai/changelog
REM  → look for any breaking changes in the sections below

REM Merge into main
git merge upstream/main
```

If you prefer rebase (cleaner history):

```bat
git rebase upstream/main
```

---

## 4. Resolving Conflicts

Conflicts will only occur in the seven files listed in Section 1. For each
conflict, the rule is the same: **keep upstream's structural changes, restore
Petrocil's string values**.

Work through conflicts one file at a time.

---

### `client/index.html`

Accept upstream's changes. Then verify these two lines match exactly:

```html
<meta name="description" content="Petrocil Chat - AI Assistant" />
<title>Petrocil Chat</title>
```

If upstream changed the surrounding HTML structure, adapt the exact text but
keep the values `Petrocil Chat - AI Assistant` and `Petrocil Chat`.

---

### `client/src/routes/Layouts/Startup.tsx`

Accept upstream's changes. Find the `document.title` assignment and ensure the
fallback string is `'Petrocil Chat'`:

```ts
document.title = startupConfig?.appTitle || 'Petrocil Chat';
```

---

### `client/src/components/Auth/AuthLayout.tsx`

Accept upstream's changes. Find the logo `<img>` tag and ensure:

```tsx
src="assets/logo.png"
```

and the alt fallback reads `'Petrocil Chat'` (not `'LibreChat'`):

```tsx
alt={localize('com_ui_logo', { 0: startupConfig?.appTitle ?? 'Petrocil Chat' })}
```

---

### `client/src/components/Chat/Footer.tsx`

Accept upstream's changes. Find the default footer expression. It will look
something like:

```ts
: '[LibreChat ' + Constants.VERSION + '](https://librechat.ai) - ' + localize(...)
```

Replace the entire ternary branch (the non-`customFooter` side) with:

```ts
: 'Petrocil Chat'
```

The result should be:

```ts
const mainContentParts = (
  typeof config?.customFooter === 'string'
    ? config.customFooter
    : 'Petrocil Chat'
).split('|');
```

---

### `client/src/components/Nav/SettingsTabs/About/About.tsx`

Accept upstream's changes. Find `buildDiagnosticsBlob` and ensure the first
line of the `lines` array reads:

```ts
`Petrocil Chat version: ${version}`,
```

---

### `client/src/components/Agents/Marketplace.tsx`

Accept upstream's changes. Find `useDocumentTitle(...)` and ensure the string
ends with `| Petrocil Chat`:

```ts
useDocumentTitle(`${localize('com_agents_marketplace')} | Petrocil Chat`);
```

---

### `client/src/locales/en/translation.json`

Accept upstream's changes (they may add new keys). Find the key
`com_agents_mcp_trust_subtext` and ensure its value is:

```json
"com_agents_mcp_trust_subtext": "Custom connectors are not verified by Petrocil Chat",
```

Do **not** touch any other translation keys — other languages are managed
externally by the upstream project.

---

## 5. Post-Merge Verification

Run these greps after the merge to confirm every Petrocil string is in place.
A missing match means a customisation was lost and needs to be reapplied.

```bat
REM All seven should produce at least one match:
findstr /s "Petrocil Chat"       client\index.html
findstr /s "Petrocil Chat"       client\src\routes\Layouts\Startup.tsx
findstr /s "logo.png"            client\src\components\Auth\AuthLayout.tsx
findstr /s "Petrocil Chat"       client\src\components\Chat\Footer.tsx
findstr /s "Petrocil Chat"       client\src\components\Nav\SettingsTabs\About\About.tsx
findstr /s "Petrocil Chat"       client\src\components\Agents\Marketplace.tsx
findstr /s "Petrocil Chat"       client\src\locales\en\translation.json

REM Confirm no stray LibreChat strings remain in user-facing files:
findstr /s "LibreChat" client\index.html
findstr /s "'LibreChat'" client\src\routes\Layouts\Startup.tsx
findstr /s "LibreChat" client\src\components\Chat\Footer.tsx
```

The last three `findstr` calls should return **no output**. If they do, a
rebase conflict resolver accepted the upstream default — reapply the fix.

---

## 6. Breaking-Change Watch List

Check the [LibreChat changelog](https://www.librechat.ai/changelog) before every
merge. These upstream areas directly affect Petrocil's setup:

| Upstream area | Why it matters for Petrocil |
|---|---|
| `docker-compose.yml` changes | May change service names, volume paths, or image tags — update `prepare.bat` image list and `scripts/deploy-override.yml` if needed |
| `librechat.example.yaml` — `endpoints.custom` schema | May add required fields or rename keys — compare against `librechat.yaml` |
| `.env.example` new required variables | Add missing vars to `.env` |
| `AuthLayout.tsx` logo rendering | If upstream restructures the logo section, reapply `logo.png` path |
| `Footer.tsx` structure | If upstream refactors the footer split logic, reapply the `'Petrocil Chat'` literal |
| `client/index.html` new `<meta>` or manifest tags | Accept upstream additions; preserve Petrocil title/description |
| MeiliSearch or MongoDB version bumps in `docker-compose.yml` | Update volume directory names in `prepare.bat` (e.g. `meili_data_v1.35.1`) |

---

## 7. After a Successful Merge

1. **Rebuild the frontend** if you changed any `.tsx` or `.json` files:

   ```bat
   npm run build
   ```

2. **Recreate the Docker container** to pick up any compose changes:

   ```bat
   docker compose up -d
   ```

3. **Verify the logo** — open http://localhost:9090/login and confirm the
   Petrocil globe logo appears, not the LibreChat icon.

4. **Rebuild the deploy package** if this will be pushed to air-gapped machines:

   ```bat
   prepare.bat
   ```

5. **Commit** with a message referencing the upstream version:

   ```bat
   git log upstream/main -1 --format="%H %s"
   REM use the hash in your commit message:
   git commit -m "chore: merge upstream LibreChat <version/hash>"
   ```

---

## 8. Quick Reference — Petrocil String Map

Copy-paste ready. These are the exact strings that must appear after every merge.

| File | Must contain |
|---|---|
| `client/index.html` | `<title>Petrocil Chat</title>` |
| `client/index.html` | `content="Petrocil Chat - AI Assistant"` |
| `Startup.tsx` | `\|\| 'Petrocil Chat'` |
| `AuthLayout.tsx` | `src="assets/logo.png"` |
| `AuthLayout.tsx` | `'Petrocil Chat'` (alt fallback) |
| `Footer.tsx` | `: 'Petrocil Chat'` |
| `About.tsx` | `` `Petrocil Chat version: ${version}` `` |
| `Marketplace.tsx` | `\| Petrocil Chat\`` |
| `translation.json` | `"...not verified by Petrocil Chat"` |
