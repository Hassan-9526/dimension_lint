// Test method names follow test_reflective_loader's `test_` convention.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:dimension_lint/src/rules/raw_font_size.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RawFontSizeTest);
  });
}

@reflectiveTest
class RawFontSizeTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = RawFontSize();
    super.setUp();
  }

  Future<void> test_textStyle_fontSizeLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
TextStyle f() => const TextStyle(fontSize: 14);
''',
      [lint(83, 2)],
    );
  }

  Future<void> test_height_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
TextStyle f() => const TextStyle(height: 1.2);
''');
  }

  Future<void> test_fontSize_designToken_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
class AppText {
  static const double body = 14;
}
TextStyle f() => const TextStyle(fontSize: AppText.body);
''');
  }
}
