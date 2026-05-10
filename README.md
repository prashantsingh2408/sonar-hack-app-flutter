# HackLens Flutter (`sonar-hack-app-flutter`)

Mobile client for **[sonar-hack-app](../sonar-hack-app)** (HackLens web): same Next.js **`/api/*` BFF** (e.g. **`GET /api/hackathons`**, **`/api/me/*`** with Bearer after Google sign-in).

## One icon language

Material rounded icons live in `lib/src/widgets/app_icons.dart` to stay close to the web header.

---

## First-time setup

```bash
cd sonar-hack-app-flutter
flutter create .    # if android/ios/web folders are missing
flutter pub get
```

---

## Run with **no manual** `--dart-define` (reads Next env files)

Flutter does **not** store OAuth secrets in-repo. Scripts read **`sonar-hack-app`** env files and pass **`--dart-define`** at run/build time.

**Env keys (Vercel / `.env*` → Flutter)**

| Key in Next `.env.local` or `.env.vercel.production.local` | Flutter `--dart-define` |
|------------------------------------------------------------|-------------------------|
| **`AUTH_GOOGLE_ID`** (Web OAuth client id, same as Next) | **`GOOGLE_SERVER_CLIENT_ID`** |
| **`GOOGLE_CLIENT_ID`** | Same fallback if **`AUTH_GOOGLE_ID`** is empty after **`vercel env pull`** (Vercel sometimes omits the duplicate). |
| **`NEXT_PUBLIC_APP_URL`** or **`VERCEL_URL`** (optional) | **`API_ORIGIN`** (falls back to `https://hacklens.vercel.app`) |

Resolution order: **`.env.local`**, **`.env.preview.local`**, **`.env.vercel.production.local`** — for OAuth id, **`AUTH_GOOGLE_ID`** first, then **`GOOGLE_CLIENT_ID`** if the former is empty.

### 1) Pull from Vercel (requires `vercel link` in `sonar-hack-app` and `vercel login` once)

**Recommended — one command** (runs `env:pull`, then production pull if **`AUTH_GOOGLE_ID`** is still missing):

```bash
cd sonar-hack-app-flutter
chmod +x tool/pull_vercel_env.sh   # once
./tool/pull_vercel_env.sh
```

To refresh env in **every** Vercel-linked repo under the same workspace (Next app + Python APIs + LLM), run from **`sonar-hack-app`**:

```bash
cd ../sonar-hack-app
npm run env:pull:all
```

Then run **`./tool/pull_vercel_env.sh`** here so Flutter picks up **`AUTH_GOOGLE_ID`** from the Next `.env*` files.

To see **which Vercel environments** host **`AUTH_GOOGLE_ID`** / **`AUTH_GOOGLE_SECRET`** on each linked project (same as Dashboard → Environment Variables):

```bash
cd ../sonar-hack-app
npm run vercel:env-check-keys
```

**Equivalent manual commands** (from **`sonar-hack-app`**):

```bash
cd ../sonar-hack-app
npm run env:pull
# If AUTH_GOOGLE_ID is still missing:
npm run vercel:env-pull-production
```

Raw **`vercel`** CLI (same behavior):

```bash
cd ../sonar-hack-app
vercel env pull .env.local -y
vercel env pull .env.vercel.production.local --environment production -y
```

### 2) Run Flutter with IDs wired automatically

```bash
cd sonar-hack-app-flutter
./tool/run_with_nextjs_env.sh
```

This passes:

- `--dart-define=GOOGLE_SERVER_CLIENT_ID=<AUTH_GOOGLE_ID from .env.local>`
- `--dart-define=API_ORIGIN=<NEXT_PUBLIC_APP_URL or VERCEL_URL or hacklens.vercel.app>`

Web only:

```bash
./tool/run_web_with_nextjs_env.sh
```

**Android:** if **`JAVA_HOME`** is unset, the script tries common JDK 17 paths (including `/home/neosoft/jdk-17.0.13+11`). Install JDK 17 if Gradle still fails.

### USB install (release APK on a physical device)

1. On the phone: **Developer options** → **USB debugging** on; plug in USB and accept the RSA fingerprint on first connect.
2. **`adb`** must be on your **`PATH`** (Android SDK platform-tools).
3. From **`sonar-hack-app-flutter`**:

```bash
chmod +x tool/build_android_apk.sh tool/connect_install_android.sh
./tool/build_android_apk.sh          # outputs build/app/outputs/flutter-apk/app-release.apk
./tool/connect_install_android.sh    # build + adb install -r to one connected device
```

Google Sign-In on Android still requires an OAuth client that matches **app id + signing SHA-1** in Google Cloud Console (debug keystore for local builds unless you configure release signing).

---

## If you cannot use Vercel CLI

Copy **`AUTH_GOOGLE_ID`** from the Google Cloud OAuth client (same value as in Vercel → Settings → Environment Variables) into **`sonar-hack-app/.env.local`** manually, then run `./tool/run_with_nextjs_env.sh` again.

---

## API origin in the app

| Source | Value |
|--------|--------|
| Default build | `API_ORIGIN` from run script, else `https://hacklens.vercel.app` |
| Settings screen | Saved in `shared_preferences` |

---

## Screens vs web (current)

| Tab | Flutter | Web |
|-----|---------|-----|
| Browse | Home — rails + filters + grid/table/schedule | `/` |
| Wishlist | `/api/me/wishlist` with Bearer | `/wishlist` |
| Collections | `/api/me/collections` | `/collections` |
| Alerts | `/api/me/hackathon-notification-prefs` | `/notifications` |
| Settings | Origin, theme, account | `/settings` |
