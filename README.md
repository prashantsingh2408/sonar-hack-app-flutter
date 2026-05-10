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

## Run with **no manual** `--dart-define` (uses `sonar-hack-app/.env.local`)

The app needs **`GOOGLE_SERVER_CLIENT_ID`** = the **same Web OAuth client id** as Next’s **`AUTH_GOOGLE_ID`**. The helper scripts read it from the Next app env file.

### 1) Pull env from Vercel (from your laptop; requires `vercel login` once)

```bash
cd ../sonar-hack-app
npm run env:pull
```

That writes **`../sonar-hack-app/.env.local`**. If **`AUTH_GOOGLE_ID`** is missing there (some pulls omit secrets), run production pull:

```bash
cd ../sonar-hack-app
npm run vercel:env-pull-production
```

Then run `./tool/run_with_nextjs_env.sh` — it reads **`.env.local` first**, then **`.env.vercel.production.local`** until it finds **`AUTH_GOOGLE_ID`**.

Flutter shortcut (same effect):

```bash
cd sonar-hack-app-flutter
./tool/pull_vercel_env.sh
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
