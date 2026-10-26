# floor_check

A minimal app that confirms the plugin still loads and reports on the oldest
Dart SDK `dimension_lint` supports (3.11, which ships with Flutter 3.41).

The `example` app cannot serve this purpose: it includes a dot shorthand whose
resolution depends on redirecting factories that Flutter added to
`EdgeInsetsGeometry` later, so it does not compile on Flutter 3.41 at all.

Three diagnostics are expected, one per rule. CI runs this; to run it yourself:

```sh
flutter pub get
dart analyze
```
