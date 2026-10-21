/// The entry point for the `dimension_lint` analyzer plugin.
///
/// The Dart Analysis Server generates code that imports this exact file and
/// references the top-level [plugin] variable, so neither the path
/// (`lib/main.dart`) nor the variable name may change.
library;

import 'package:analysis_server_plugin/plugin.dart';
import 'package:analysis_server_plugin/registry.dart';
import 'package:dimension_lint/src/rules/raw_box_dimension.dart';
import 'package:dimension_lint/src/rules/raw_edge_insets.dart';
import 'package:dimension_lint/src/rules/raw_font_size.dart';

/// The plugin instance discovered by the analysis server.
final plugin = DimensionLintPlugin();

/// Registers the `dimension_lint` analysis rules.
///
/// Every rule this plugin defines is a lint rule, which means it is disabled by
/// default and must be opted into under the `diagnostics` key in a consuming
/// project's `analysis_options.yaml`.
class DimensionLintPlugin extends Plugin {
  @override
  String get name => 'dimension_lint';

  @override
  void register(PluginRegistry registry) {
    // Registered as a lint rule, so it stays off until a consuming project
    // opts in under `diagnostics`.
    registry.registerLintRule(RawBoxDimension());
    registry.registerLintRule(RawEdgeInsets());
    registry.registerLintRule(RawFontSize());
  }
}
