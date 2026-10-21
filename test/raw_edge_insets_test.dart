// Test method names follow test_reflective_loader's `test_` convention.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:dimension_lint/src/rules/raw_edge_insets.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RawEdgeInsetsTest);
  });
}

@reflectiveTest
class RawEdgeInsetsTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = RawEdgeInsets();
    super.setUp();
  }

  Future<void> test_all_intLiteral() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
EdgeInsets f() => const EdgeInsets.all(16);
''',
      [lint(79, 2)],
    );
  }

  Future<void> test_symmetric_vertical() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
EdgeInsets f() => const EdgeInsets.symmetric(vertical: 16);
''',
      [lint(95, 2)],
    );
  }

  Future<void> test_only_left() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
EdgeInsets f() => const EdgeInsets.only(left: 8);
''',
      [lint(86, 1)],
    );
  }

  Future<void> test_fromLTRB_reportsEachDimension() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/painting.dart';
EdgeInsets f() => const EdgeInsets.fromLTRB(8, 16, 4, 2);
''',
      [lint(84, 1), lint(87, 2), lint(91, 1), lint(94, 1)],
    );
  }

  Future<void> test_all_designToken_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
class AppSpacing {
  static const double md = 16;
}
EdgeInsets f() => const EdgeInsets.all(AppSpacing.md);
''');
  }

  Future<void> test_nonFlutterEdgeInsets_isNotReported() async {
    await assertNoDiagnostics(r'''
class EdgeInsets {
  const EdgeInsets.all(this.value);
  final double value;
}
EdgeInsets f() => const EdgeInsets.all(16);
''');
  }
}
