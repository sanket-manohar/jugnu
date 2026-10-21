# jugnu example

A small shop app that uses every part of jugnu: typed results, guards,
typed params, shell tabs, the debug hook and deep links.

Only `lib/` and `test/` are checked in. To run it, add the platforms you
want first:

```sh
flutter create . --platforms=android,ios,web
flutter run
```

Try the deep link generator from this folder:

```sh
dart run jugnu:deeplink
dart run jugnu:deeplink product id=3 color=blue --scheme https --host shop.example.com
```
