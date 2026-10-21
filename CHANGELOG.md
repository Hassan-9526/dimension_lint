## 0.1.0

- `raw_box_dimension`: flags numeric literals passed as `width`/`height` on
  Flutter's `SizedBox` and `Container`.
- `raw_edge_insets`: flags numeric literals passed to `EdgeInsets.all`,
  `symmetric`, `only` and `fromLTRB`.
- `raw_font_size`: flags numeric literals passed as `TextStyle.fontSize`.

All rules are lint rules, so they are off by default and must be enabled under
the `diagnostics` key in `analysis_options.yaml`. The literal values `0` and `1`
are never reported. Excluding files uses the analyzer's own `exclude`, and
single cases are suppressed with `// ignore: dimension_lint/<rule>`.
