import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
import 'package:dimension_lint/src/constructor_invocation.dart';
import 'package:dimension_lint/src/flutter_element.dart';

/// `EdgeInsets` constructors that take their dimensions positionally, mapped
/// to the name of each position for use in the diagnostic message.
const Map<String, List<String>> _positionalConstructors = {
  'all': ['value'],
  'fromLTRB': ['left', 'top', 'right', 'bottom'],
};

/// `EdgeInsets` constructors that take their dimensions as named arguments.
const Map<String, Set<String>> _namedConstructors = {
  'only': {'left', 'top', 'right', 'bottom'},
  'symmetric': {'vertical', 'horizontal'},
};

/// Flags numeric literals passed to Flutter's `EdgeInsets` constructors.
///
/// Covers `all`, `symmetric`, `only` and `fromLTRB`. `fromLTRB` can report up
/// to four diagnostics for a single call, one per raw dimension.
class RawEdgeInsets extends AnalysisRule {
  /// The diagnostic reported by this rule.
  static const LintCode code = LintCode(
    'raw_edge_insets',
    "Raw numeric literal used for '{0}' on 'EdgeInsets.{1}'.",
    correctionMessage:
        'Use the sizing convention this project has configured instead of a '
        'raw value.',
  );

  /// Creates the rule.
  RawEdgeInsets()
    : super(
        name: 'raw_edge_insets',
        description:
            'Numeric literals should not be used as edge insets; use the '
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
    if (invocation.typeName != 'EdgeInsets') return;

    var constructor = invocation.constructorName;
    if (constructor == null) return;

    var arguments = invocation.argumentList;

    var positions = _positionalConstructors[constructor];
    if (positions != null) {
      _reportPositional(arguments, constructor, positions);
      return;
    }

    var parameters = _namedConstructors[constructor];
    if (parameters != null) {
      _reportNamed(arguments, constructor, parameters);
    }
  }

  void _reportPositional(
    ArgumentList argumentList,
    String constructor,
    List<String> positions,
  ) {
    var index = 0;
    for (var argument in argumentList.arguments) {
      // Named arguments do not consume a position.
      if (argument is NamedArgument) continue;
      if (index < positions.length && isReportableNumericLiteral(argument)) {
        rule.reportAtNode(
          argument as Expression,
          arguments: [positions[index], constructor],
        );
      }
      index++;
    }
  }

  void _reportNamed(
    ArgumentList argumentList,
    String constructor,
    Set<String> parameters,
  ) {
    for (var argument in argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      var parameterName = argument.name.lexeme;
      if (!parameters.contains(parameterName)) continue;
      if (isReportableNumericLiteral(argument.argumentExpression)) {
        rule.reportAtNode(
          argument.argumentExpression,
          arguments: [parameterName, constructor],
        );
      }
    }
  }
}
