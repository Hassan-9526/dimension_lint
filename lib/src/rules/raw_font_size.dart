import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:dimension_lint/src/constructor_invocation.dart';
import 'package:dimension_lint/src/flutter_element.dart';

/// Flags numeric literals passed as `TextStyle.fontSize`.
///
/// Only `fontSize` is inspected. `TextStyle.height` is a line-height
/// multiplier rather than a pixel measurement and is never reported.
class RawFontSize extends AnalysisRule {
  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'raw_font_size',
    "Raw numeric literal used for 'fontSize' on 'TextStyle'.",
    correctionMessage:
        'Use the sizing convention this project has configured instead of a '
        'raw value.',
  );

  /// Creates the rule.
  RawFontSize()
    : super(
        name: 'raw_font_size',
        description:
            'Numeric literals should not be used as font sizes; use the '
            "project's sizing convention instead.",
      );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    var visitor = _Visitor(this);
    registry.addInstanceCreationExpression(this, visitor);
    registry.addDotShorthandConstructorInvocation(this, visitor);
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) =>
      _check(node);

  @override
  void visitDotShorthandConstructorInvocation(
    DotShorthandConstructorInvocation node,
  ) => _check(node);

  void _check(AstNode node) {
    var invocation = resolveFlutterConstructor(node);
    if (invocation == null) return;
    if (invocation.typeName != 'TextStyle') return;

    for (var argument in invocation.argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      if (argument.name.lexeme != 'fontSize') continue;
      if (isReportableNumericLiteral(argument.argumentExpression)) {
        rule.reportAtNode(argument.argumentExpression);
      }
    }
  }
}
