# dimension_lint

An analyzer plugin that flags raw numeric literals used as layout dimensions in
Flutter widget constructors, so a project can enforce its own sizing
convention.

This is a **convention-consistency** linter, not a correctness linter.
Hardcoded sizing is not inherently wrong in Flutter — logical pixels already
normalize for density, and Material's 8pt grid is specified in logical pixels.
Every rule is therefore off by default and must be opted into.

## Requirements

Dart 3.13+ (Flutter 3.47+), because analyzer plugins require the
`analysis_server_plugin` framework.

## Usage

Add the plugin under the **top-level** `plugins:` key of
`analysis_options.yaml`, and enable the rules you want:

```yaml
plugins:
  dimension_lint:
    version: ^0.1.0
    diagnostics:
      raw_box_dimension: true
      raw_edge_insets: true
      raw_font_size: true
```

Restart the Dart Analysis Server after changing this section.

## Rules

### `raw_box_dimension`

Flags numeric literals passed as `width` or `height` to Flutter's `SizedBox`
and `Container`:

```
info - lib\home_view.dart:17:47 - Raw numeric literal used for 'width' on
'SizedBox'. Use the sizing convention this project has configured instead of a
raw value. - raw_box_dimension
```

What it does **not** flag, by design:

| Code | Why |
| --- | --- |
| `TextStyle(height: 1.2)` | A line-height multiplier, not a pixel value |
| `BorderSide(width: 1.6)` | A hairline, which must not scale |
| `Divider(thickness: 1)` | A hairline |
| `SizedBox(height: 16.h)` | Already follows a sizing convention |
| `SizedBox(height: AppSpacing.md)` | A design token |
| `SizedBox(height: spacing)` | Not a literal; out of scope |
| `SizedBox(height: 8 * 2)` | Not a literal; out of scope |

The rule whitelists **constructor types**, never parameter names. `height` on
`SizedBox` is a pixel measurement while `height` on `TextStyle` is a multiplier,
and only resolved type information distinguishes them — which is why this is an
analyzer plugin and not a regular expression.

### `raw_edge_insets`

Flags numeric literals passed to `EdgeInsets.all`, `EdgeInsets.symmetric`,
`EdgeInsets.only` and `EdgeInsets.fromLTRB`. `fromLTRB` reports one diagnostic
per raw dimension, naming each position:

```
info - lib\home_view.dart:44:56 - Raw numeric literal used for 'left' on
'EdgeInsets.fromLTRB'. - raw_edge_insets
info - lib\home_view.dart:44:59 - Raw numeric literal used for 'top' on
'EdgeInsets.fromLTRB'. - raw_edge_insets
```

### `raw_font_size`

Flags numeric literals passed as `TextStyle.fontSize`. `TextStyle.height` is a
line-height multiplier and is never reported, so the two parameters on the same
type behave differently — which is only possible with resolved type
information.

## Running in CI

Use `dart analyze`, **not** `flutter analyze`:

```sh
dart analyze --fatal-infos
```

Two reasons:

1. `flutter analyze` currently drops analyzer plugin diagnostics and reports
   "No issues found!" even when violations exist
   ([flutter/flutter#193203][], root cause [dart-lang/sdk#63787][]).
2. Plugin lints report at `info` severity, so `dart analyze` exits `0` without
   `--fatal-infos` and CI would pass silently.

[flutter/flutter#193203]: https://github.com/flutter/flutter/issues/193203
[dart-lang/sdk#63787]: https://github.com/dart-lang/sdk/issues/63787

## Quick fixes

None, deliberately. `.w` vs `.h` vs `.r` is a semantic choice rather than a
mechanical one — many teams use `.w` on both axes to avoid tablet distortion, so
auto-appending `.h` can be actively wrong. `16.h` is also not a constant
expression, so "fixing" it inside `const SizedBox(...)` would break
compilation.

## License

MIT
