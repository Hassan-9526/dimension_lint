# dimension_lint

An analyzer plugin that flags raw numeric literals used as layout dimensions in
Flutter widget constructors, so a project can enforce its own sizing
convention.

This is a **convention-consistency** linter, not a correctness linter.
Hardcoded sizing is not inherently wrong in Flutter — logical pixels already
normalize for density, and Material's 8pt grid is specified in logical pixels.
Every rule is therefore off by default and must be opted into.

## Requirements

Dart 3.11+ (Flutter 3.41+), because analyzer plugins require the
`analysis_server_plugin` framework. Dart 3.11 is the lowest possible: both
analyzer 13 and 14 require it, and `analysis_server_plugin` has never supported
an SDK below 3.9.

On Dart 3.11 and 3.12 pub resolves `analysis_server_plugin` 0.3.24; on 3.13 and
later it resolves 0.3.25. CI runs the rule tests on both ends, and loads the
plugin into a real Flutter app at each end too.

One difference at the low end: dot shorthands for `EdgeInsets` (below) rely on
redirecting factories that Flutter added to `EdgeInsetsGeometry` in a later
release, so on older Flutter that syntax does not compile in the first place.

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

### Dot shorthands

Since Dart 3.10 a constructor can be written as a shorthand, letting the context
type supply the class. Both forms are reported identically:

```dart
padding: const EdgeInsets.all(16),  // reported
padding: .all(16),                  // reported
```

This needs more than matching the shorthand's name. `Padding.padding` is typed
`EdgeInsetsGeometry`, so `.all(16)` resolves to the redirecting factory
`EdgeInsetsGeometry.all` that Flutter declares for exactly this purpose, not to
`EdgeInsets.all`. The rules follow the redirect to the constructor actually
invoked.

## Not covered yet

Only the types listed above are inspected. These are recognized sizing APIs
that no rule currently matches, so a raw literal in one is **not** reported:

| Not reported | |
| --- | --- |
| `Positioned(top: 12)` | and `left`, `right`, `bottom` |
| `SizedBox.square(dimension: 48)` | and `SizedBox.fromSize` |
| `EdgeInsetsDirectional.only(start: 16)` | and `EdgeInsetsDirectional.fromSTEB` |
| `BorderRadius.circular(12)` | and the other radius constructors |
| `Icon(size: 32)` | |
| `Container(constraints: ...)` | `BoxConstraints` dimensions |

These are gaps rather than deliberate exclusions — unlike the cases in the
tables above, which are wrong to report. Open an issue if one of them is
blocking you.

## Configuration

There is deliberately very little. `analysis_server_plugin` cannot pass
arguments to a rule — a rule's entry in `analysis_options.yaml` can only set
whether it is enabled and at what severity — so this package does not pretend
to offer tunable options that would have nowhere to live.

What you get instead:

**Severity.** Promote a rule to a build-breaking error:

```yaml
plugins:
  dimension_lint:
    version: ^0.1.0
    diagnostics:
      raw_box_dimension: error
```

**`0` and `1` are never reported.** They are structural rather than design
values: `EdgeInsets.only(left: 0)` carries no scaling intent, and a hairline of
`1` must not scale.

**Excluding files** uses the analyzer's own mechanism, which applies to plugin
diagnostics too. Theme files that define your tokens should be excluded — the
raw numbers there are the single source of truth and are correct:

```yaml
analyzer:
  exclude:
    - lib/core/theme/**
```

**Suppressing one case** uses a namespaced ignore comment:

```dart
// ignore: dimension_lint/raw_box_dimension
const SizedBox(width: 42);

// ignore_for_file: dimension_lint/raw_font_size
```

### No `mode` setting

The rules inspect **numeric literals only**, which makes a
`screenutil`-versus-`tokens` mode unnecessary: `16.h` is a property access and
`AppSpacing.md` a static field reference, so both are structurally "not a
literal" and pass under either convention. A mode setting would change nothing.

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
