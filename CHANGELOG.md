## 1.0.0

First release.

- `pushForResult`, `pushNamedForResult` and `popWithResult`, with a fallback
  location when there is nothing to pop.
- `guards()` to chain sync and async route guards, with protection against
  redirect loops.
- `RouteParam` for typed path and query parameters.
- `switchTab` and `resetTab` for `StatefulShellRoute`.
- `DeepLinkGenerator`, `router.deepLinks()` and the `dart run jugnu:deeplink`
  command.
- `JugnuDebug` to share the live navigation stack with developer tools.
- `package:jugnu/testing.dart` with `MockGoRouter`, `isAt`, `expectRoute`,
  `expectRedirect`, `openDeepLink` and `expectDeepLink`.
