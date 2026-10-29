import 'package:yaml/yaml.dart';

/// The constraint written into a project's `analysis_options.yaml`.
///
/// Kept in step with the package's own version by a test, so that a release
/// cannot ship an installer that configures an older plugin than itself.
const String pluginVersionConstraint = '^0.2.0';

/// The block [configurePlugins] appends when a project has no `plugins:` key.
const String pluginBlock =
    '''
plugins:
  dimension_lint:
    version: $pluginVersionConstraint
    diagnostics:
      raw_box_dimension: true
      raw_edge_insets: true
      raw_font_size: true
''';

/// What [configurePlugins] did, or why it declined to do anything.
enum InstallOutcome {
  /// The `plugins:` block was appended.
  configured,

  /// `dimension_lint` was already listed under `plugins:`; nothing changed.
  alreadyConfigured,

  /// A `plugins:` key exists for other plugins. Merging into it would have to
  /// rewrite a structure the project owns, so the caller is told to edit by
  /// hand instead.
  otherPluginsPresent,

  /// The file is not valid YAML, so appending to it would compound an error
  /// the project has to fix first.
  malformed,
}

/// The result of inspecting a project's `analysis_options.yaml`.
class InstallResult {
  /// What happened.
  final InstallOutcome outcome;

  /// The file's new contents, or `null` when nothing should be written.
  final String? contents;

  /// Creates a result.
  const InstallResult(this.outcome, [this.contents]);
}

/// Adds the `dimension_lint` plugin block to [contents].
///
/// Appends rather than editing in place: `analysis_options.yaml` is a file
/// projects comment heavily, and re-emitting parsed YAML would discard those
/// comments along with the author's formatting.
InstallResult configurePlugins(String contents) {
  Object? parsed;
  try {
    parsed = loadYaml(contents);
  } on YamlException {
    return const InstallResult(InstallOutcome.malformed);
  }

  if (parsed is YamlMap) {
    var plugins = parsed['plugins'];
    if (plugins is YamlMap) {
      if (plugins.containsKey('dimension_lint')) {
        return const InstallResult(InstallOutcome.alreadyConfigured);
      }
      return const InstallResult(InstallOutcome.otherPluginsPresent);
    }
  }

  // An empty or whitespace-only file parses to null; start it cleanly rather
  // than leading with a blank line.
  var trimmed = contents.trimRight();
  var updated = trimmed.isEmpty ? pluginBlock : '$trimmed\n\n$pluginBlock';
  return InstallResult(InstallOutcome.configured, updated);
}
