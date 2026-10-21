<p align="center"><img src="https://raw.githubusercontent.com/sanket-manohar/jugnu/main/brand/banner.png" alt="jugnu" width="100%"></p>

# jugnu

Small, focused helpers for apps built on [go_router](https://pub.dev/packages/go_router).

jugnu fills the gaps you hit once an app grows past a few screens: getting a
typed value back from a page, guards that can be async and never loop, params
that survive a web refresh, tab bars that behave, deep links you can generate
instead of hand-write, and tests that read like what they check.

It adds no dependencies beyond Flutter and go_router.

New here? The [Package Guide](https://sanketmanohar.com/jugnu/package-guide.pdf) walks through setup step by step.

## Install

```sh
flutter pub add jugnu
```

```dart
import 'package:jugnu/jugnu.dart';
```

## Results from pages

```dart
final color = await context.pushForResult<Color>('/pick-color');
```

```dart
// On the picker page.
context.popWithResult(Colors.teal, fallback: '/');
```

`pushForResult` completes with null if the page closes without a value or with
a value of another type, instead of throwing. `popWithResult` goes to
`fallback` when there is nothing to pop, which is what happens after a web
refresh or when the page was opened from a deep link.

## Route guards

```dart
final router = GoRouter(
  refreshListenable: auth,
  redirect: guards([
    (context, state) => auth.signedIn ? null : '/login',
    (context, state) async => await flags.isDown() ? '/maintenance' : null,
  ]),
  routes: [...],
);
```

Guards run in order and the first one to return a location wins. Return null
to continue, which also makes a guard handy as middleware for logging or
analytics.

Loops are handled for you. A redirect to the page already being shown is
ignored, so the sign-in guard above is safe on `/login` itself. If guards
bounce between pages, as in `/a → /b → /a`, the chain stops and a warning is
printed in debug builds.

`guards()` works for `GoRoute.redirect` too.

## Typed params

`extra` is lost on a web refresh and can't come from a deep link. Keep values
in the URL instead and read them with types:

```dart
final userId = RouteParam.integer('id');
final tab = RouteParam.enumeration('tab', Tab.values, defaultValue: Tab.posts);

GoRoute(
  path: '/users/:id',
  name: 'user',
  builder: (context, state) => UserPage(
    id: userId.read(state),
    tab: tab.read(state),
  ),
);

context.goNamed(
  'user',
  pathParameters: {userId.name: userId.encode(42)},
  queryParameters: {tab.name: tab.encode(Tab.likes)},
);
```

Built in: `string`, `integer`, `decimal`, `boolean`, `dateTime` and
`enumeration`. For anything else, pass your own `parse` and `encode`.
`read` falls back to `defaultValue` when a value is missing or malformed, and
`readOrNull` never throws.

## Tabs

```dart
NavigationBar(
  selectedIndex: shell.currentIndex,
  onDestinationSelected: shell.switchTab,
  destinations: [...],
)
```

Each tab keeps its own stack. Tapping the tab you're on takes it back to its
first page. `shell.resetTab()` does the same from code.

## Deep links

Build links from your real route tree, by name or by path:

```dart
final links = router.deepLinks(scheme: 'https', host: 'example.com');

links.build('user', pathParameters: {'id': 42}, queryParameters: {'tab': 'posts'});
// https://example.com/users/42?tab=posts
```

Leave out `scheme` to get a plain location for `context.go`. Missing path
params throw an `ArgumentError` that names the param.

### From the command line

The `deeplink` command reads the `GoRoute` and `TypedGoRoute` definitions in
your `lib/` folder. Run it from your app's root:

```sh
dart run jugnu:deeplink
```

```
/                         home
/users/:id                user
/users/:id/posts/:postId  post
```

```sh
dart run jugnu:deeplink post id=4 postId=9 ref=mail --scheme myapp --host open
# myapp://open/users/4/posts/9?ref=mail
```

Values that match a path param fill it. The rest go in the query string, or
use `-q name=value` to force one there. Add `--open android` or `--open ios`
to open the link on a running emulator or simulator, and `--json` for output
that tools can read. `--help` lists everything.

The command reads source code, so routes need string literal paths. Routes
built from variables in another file are listed without their parent path.

## Testing

```dart
import 'package:jugnu/testing.dart';
```

Check where a real router ends up:

```dart
testWidgets('settings needs a sign-in', (tester) async {
  await pumpRouter(tester, router);

  await expectRedirect(tester, router, from: '/settings', to: '/login');
  await expectDeepLink(tester, router, 'myapp://open/users/42', opens: '/users/42');
  expect(router, isAt('/users/42'));
});
```

`openDeepLink` delivers the link through the same platform channel the
operating system uses, so it exercises your real deep link handling.

For fast widget tests that only need to know a navigation happened, use
`MockGoRouter`:

```dart
final router = MockGoRouter(routes: {'user': '/users/:id'})
  ..stubResult('/pick-color', Colors.teal);

await tester.pumpWidget(
  MaterialApp(home: MockGoRouterProvider(router: router, child: const ProfileCard())),
);
await tester.tap(find.text('Open'));

expect(router.location, '/users/42');
expect(router.calls.last.kind, NavigationKind.push);
```

## Debug hook

```dart
void main() {
  JugnuDebug.attach(router);
  runApp(MaterialApp.router(routerConfig: router));
}
```

In debug and profile builds this shares the live navigation stack over the
Dart VM service, for tools such as the Jugnu extension for VS Code. It does
nothing in release builds. See the `JugnuDebug` docs for the protocol.

## Links

- Website and guides: [sanketmanohar.com](https://sanketmanohar.com)
- Editor extension: [Jugnu for go_router](https://marketplace.visualstudio.com/items?itemName=sanket-manohar.jugnu)
- Guides: [Package Guide](https://sanketmanohar.com/jugnu/package-guide.pdf) and [Extension Guide](https://sanketmanohar.com/jugnu/extension-guide.pdf)

## Disclaimer

jugnu is an independent project. Product and project names mentioned here,
including go_router, Flutter and Dart, belong to their owners and are used
only to describe compatibility. Their use does not imply any affiliation with,
sponsorship by or endorsement from those owners. The software is provided
"as is", without warranty of any kind, as set out in the license.

## About

jugnu is designed and developed in India by Sanket Santosh Vidya Manohar.

Released under the BSD 3-Clause License.
