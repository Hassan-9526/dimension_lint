## 0.1.0

- `raw_box_dimension`: flags numeric literals passed as `width`/`height` on
  Flutter's `SizedBox` and `Container`.
- `raw_edge_insets`: flags numeric literals passed to `EdgeInsets.all`,
  `symmetric`, `only` and `fromLTRB`.
- `raw_font_size`: flags numeric literals passed as `TextStyle.fontSize`.

Each rule matches both an ordinary constructor invocation and a Dart 3.10 dot
shorthand, following redirecting factory constructors so that `padding:
.all(16)` -- which resolves to `EdgeInsetsGeometry.all` rather than
`EdgeInsets.all` -- is reported like the long form.

Requires Dart 3.11 or later (Flutter 3.41+). Pub resolves
`analysis_server_plugin` 0.3.24 on Dart 3.11 and 3.12, and 0.3.25 on 3.13 and
later.

All rules are lint rules, so they are off by default and must be enabled under
the `diagnostics` key in `analysis_options.yaml`. The literal values `0` and `1`
are never reported. Excluding files uses the analyzer's own `exclude`, and
single cases are suppressed with `// ignore: dimension_lint/<rule>`.
