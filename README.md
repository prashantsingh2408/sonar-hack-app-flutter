# HackLens Flutter (`sonar-hack-app-flutter`)

Mobile client that mirrors **[sonar-hack-app](../sonar-hack-app)** (HackLens web): same **Next.js `/api/*` BFF** — primarily **`GET /api/hackathons`** for browse.

## One icon language

All chrome uses **Material rounded** icons via `lib/src/widgets/app_icons.dart` so navigation matches the soft M3 feel of the web header.

## Bootstrap (first time)

You need the Flutter SDK on your machine, then generate platform runners once:

```bash
cd sonar-hack-app-flutter
flutter create .
flutter pub get
flutter run
```

`flutter create .` adds `android/`, `ios/`, `web/`, etc., next to the existing `lib/` and `pubspec.yaml`.

## API origin

| Method | Value |
|--------|--------|
| Default | `https://hacklens.vercel.app` (compile-time `String.fromEnvironment`) |
| Runtime | **Settings** screen saves to `shared_preferences` |
| CLI | `flutter run --dart-define=API_ORIGIN=https://your-deployment.vercel.app` |

No trailing slash.

## Screens vs web

| Tab | Flutter | Web route | Notes |
|-----|---------|-----------|--------|
| Browse | Home — list + search | `/` | Uses paginated JSON from `/api/hackathons` |
| Wishlist | Placeholder + open web | `/wishlist` | Add `/api/me/wishlist` when auth exists |
| Collections | Placeholder + open web | `/collections` | Same |
| Alerts | Placeholder + open web | `/notifications` | Same |
| Settings | Origin + theme + links | `/settings`, `/profile` | |

## Next steps for full parity

- OAuth/session compatible with NextAuth (deep link or token storage).
- Mirror filter sidebar query params on `HackathonApi.listHackathons`.
- Hero / Netflix rails if you expose compact endpoints or reuse BFF payloads.
