import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:dimension_lint/src/constructor_invocation.dart';
import 'package:dimension_lint/src/flutter_element.dart';

/// The constructor types this rule inspects, mapped to the named parameters on
/// each that are measured in logical pixels.
///
/// This is a whitelist of *types*, never a blacklist of parameter names:
/// `height` on `SizedBox` is a pixel measurement, while `height` on
/// `TextStyle` is a line-height multiplier. Only resolved type information
/// tells the two apart.
const Map<String, Set<String>> _targets = {
  'SizedBox': {'width', 'height'},
  'Container': {'width', 'height'},
};

/// Flags numeric literals passed as box dimensions, so a project can enforce
/// its own sizing convention.
///
/// Reports on `SizedBox(width: 42)` and `Container(height: 16)`. Expressions
/// that are not numeric literals — `16.h`, `AppSpacing.md`, variables,
/// arithmetic — are structurally outside this rule and are never reported.
class RawBoxDimension extends AnalysisRule {
  /// The diagnostic reported by this rule.
  ///
  /// Declared as a `static const` so that exactly one instance exists;
  /// otherwise the analysis server cannot match the code and `// ignore:`
  /// comments will not suppress it.
  static const LintCode code = LintCode(
    'raw_box_dimension',
    "Raw numeric literal used for '{0}' on '{1}'.",
    correctionMessage:
        'Use the sizing convention this project has configured instead of a '
        'raw value.',
  );

  /// Creates the rule.
  RawBoxDimension()
    : super(
        name: 'raw_box_dimension',
        description:
            'Numeric literals should not be used as box dimensions; use the '
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

    var typeName = invocation.typeName;
    var parameters = _targets[typeName];
    if (parameters == null) return;

    for (var argument in invocation.argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      var parameterName = argument.name.lexeme;
      if (!parameters.contains(parameterName)) continue;

      var value = argument.argumentExpression;
      if (isReportableNumericLiteral(value)) {
        rule.reportAtNode(value, arguments: [parameterName, typeName]);
      }
    }
  }
}
