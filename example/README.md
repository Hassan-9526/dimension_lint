# dimension_lint example

A small app wired up to the plugin, so you can see the diagnostics for
yourself.

## Running it

```sh
flutter pub get
dart analyze
```

`lib/main.dart` deliberately mixes reported and accepted sizing, and each case
is commented with which it is and why. Four diagnostics are expected:

```
info - lib\main.dart:27:37 - Raw numeric literal used for 'value' on 'EdgeInsets.all'. - raw_edge_insets
info - lib\main.dart:31:34 - Raw numeric literal used for 'height' on 'SizedBox'. - raw_box_dimension
info - lib\main.dart:42:46 - Raw numeric literal used for 'fontSize' on 'TextStyle'. - raw_font_size
info - lib\main.dart:63:39 - Raw numeric literal used for 'value' on 'EdgeInsets.all'. - raw_edge_insets
```

The last one is a dot shorthand. It is here rather than in the unit tests
because the mock Flutter package those run against does not declare the
redirecting factories that make the shorthand resolve.

Use `dart analyze`, not `flutter analyze` — see the root README for why.

`lib/theme/tokens.dart` is excluded, because a theme file's raw numbers are the
tokens themselves.
