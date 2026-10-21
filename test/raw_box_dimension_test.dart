// Test method names follow test_reflective_loader's `test_` convention.
// ignore_for_file: non_constant_identifier_names

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:dimension_lint/src/rules/raw_box_dimension.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(RawBoxDimensionTest);
  });
}

@reflectiveTest
class RawBoxDimensionTest extends AnalysisRuleTest {
  @override
  bool get addFlutterPackageDep => true;

  @override
  void setUp() {
    rule = RawBoxDimension();
    super.setUp();
  }

  Future<void> test_sizedBox_intLiteralWidth() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() => SizedBox(width: 42);
''',
      [lint(69, 2)],
    );
  }

  Future<void> test_sizedBox_doubleLiteralHeight() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() => SizedBox(height: 12.5);
''',
      [lint(70, 4)],
    );
  }

  Future<void> test_container_intLiteralHeight() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() => Container(height: 16);
''',
      [lint(71, 2)],
    );
  }

  /// `const` constructions are reported, even though no fix is offered.
  Future<void> test_constSizedBox_isReported() async {
    await assertDiagnostics(
      r'''
import 'package:flutter/widgets.dart';
Widget f() => const SizedBox(width: 42);
''',
      [lint(75, 2)],
    );
  }

  /// `height` on `TextStyle` is a line-height multiplier, not a pixel value.
  /// This is the case that makes a parameter-name blacklist unusable.
  Future<void> test_textStyleHeight_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
TextStyle f() => const TextStyle(height: 1.2);
''');
  }

  /// Hairlines must not be scaled.
  Future<void> test_borderSideWidth_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/painting.dart';
BorderSide f() => const BorderSide(width: 1.6);
''');
  }

  Future<void> test_screenUtilExtension_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
extension on num {
  double get h => toDouble();
}
Widget f() => SizedBox(height: 16.h);
''');
  }

  Future<void> test_designToken_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
class AppSpacing {
  static const double md = 16;
}
Widget f() => SizedBox(height: AppSpacing.md);
''');
  }

  Future<void> test_variable_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
const double spacing = 24;
Widget f() => SizedBox(height: spacing);
''');
  }

  Future<void> test_arithmetic_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => SizedBox(height: 8 * 2);
''');
  }

  /// A type that merely shares Flutter's name must not be matched.
  Future<void> test_nonFlutterSizedBox_isNotReported() async {
    await assertNoDiagnostics(r'''
class SizedBox {
  const SizedBox({this.width});
  final double? width;
}
SizedBox f() => const SizedBox(width: 42);
''');
  }

  /// Parameters that are not dimensions are ignored on a matched type.
  Future<void> test_unrelatedParameter_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => SizedBox(key: null, child: null);
''');
  }

  Future<void> test_zero_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => const SizedBox(width: 0);
''');
  }

  Future<void> test_one_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => const SizedBox(height: 1);
''');
  }

  Future<void> test_zeroPointZero_isNotReported() async {
    await assertNoDiagnostics(r'''
import 'package:flutter/widgets.dart';
Widget f() => const SizedBox(width: 0.0);
''');
  }
}
