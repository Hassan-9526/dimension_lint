import 'dart:io';

import 'package:dimension_lint/src/install.dart';
import 'package:test/test.dart';
import 'package:yaml/yaml.dart';

void main() {
  group('configurePlugins', () {
    test('appends the block to an empty file', () {
      var result = configurePlugins('');
      expect(result.outcome, InstallOutcome.configured);
      expect(result.contents, pluginBlock);
    });

    test('keeps existing content and its comments', () {
      var result = configurePlugins('''
# Our house style.
include: package:lints/recommended.yaml
''');
      expect(result.outcome, InstallOutcome.configured);
      expect(result.contents, contains('# Our house style.'));
      expect(result.contents, contains('include: package:lints/recommended'));
      expect(result.contents, contains('raw_box_dimension: true'));
    });

    test('produces valid YAML with the plugin enabled', () {
      var result = configurePlugins('analyzer:\n  exclude:\n    - build/**\n');
      var parsed = loadYaml(result.contents!) as YamlMap;
      var plugin = (parsed['plugins'] as YamlMap)['dimension_lint'] as YamlMap;
      expect(plugin['version'], pluginVersionConstraint);
      expect((plugin['diagnostics'] as YamlMap).keys, [
        'raw_box_dimension',
        'raw_edge_insets',
        'raw_font_size',
      ]);
      // The pre-existing key has to survive the append.
      expect(parsed['analyzer'], isA<YamlMap>());
    });

    test('is idempotent', () {
      var once = configurePlugins('').contents!;
      var twice = configurePlugins(once);
      expect(twice.outcome, InstallOutcome.alreadyConfigured);
      expect(twice.contents, isNull);
    });

    test('declines to merge into another plugin block', () {
      var result = configurePlugins('''
plugins:
  some_other_plugin:
    version: ^1.0.0
''');
      expect(result.outcome, InstallOutcome.otherPluginsPresent);
      expect(result.contents, isNull);
    });

    test('reports malformed YAML rather than appending to it', () {
      var result = configurePlugins('analyzer:\n  exclude:\n - "unclosed\n');
      expect(result.outcome, InstallOutcome.malformed);
      expect(result.contents, isNull);
    });
  });

  test('the advertised constraint matches the package version', () {
    // A release that configures an older plugin than itself would silently
    // hand users the previous version.
    var pubspec = loadYaml(File('pubspec.yaml').readAsStringSync()) as YamlMap;
    var version = pubspec['version'] as String;
    expect(pluginVersionConstraint, '^$version');
  });
}
