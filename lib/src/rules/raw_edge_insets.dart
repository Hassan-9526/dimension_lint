import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';
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
    registry.addInstanceCreationExpression(this, _Visitor(this));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  final AnalysisRule rule;

  _Visitor(this.rule);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var element = node.constructorName.type.element;
    if (element?.name != 'EdgeInsets') return;
    if (!isFromFlutterPackage(element)) return;

    var constructor = node.constructorName.name?.name;
    if (constructor == null) return;

    var positions = _positionalConstructors[constructor];
    if (positions != null) {
      _reportPositional(node, constructor, positions);
      return;
    }

    var parameters = _namedConstructors[constructor];
    if (parameters != null) {
      _reportNamed(node, constructor, parameters);
    }
  }

  void _reportPositional(
    InstanceCreationExpression node,
    String constructor,
    List<String> positions,
  ) {
    var index = 0;
    for (var argument in node.argumentList.arguments) {
      // Named arguments do not consume a position.
      if (argument is NamedArgument) continue;
      if (index < positions.length && isNumericLiteral(argument)) {
        rule.reportAtNode(
          argument as Expression,
          arguments: [positions[index], constructor],
        );
      }
      index++;
    }
  }

  void _reportNamed(
    InstanceCreationExpression node,
    String constructor,
    Set<String> parameters,
  ) {
    for (var argument in node.argumentList.arguments) {
      if (argument is! NamedArgument) continue;
      var parameterName = argument.name.lexeme;
      if (!parameters.contains(parameterName)) continue;
      if (isNumericLiteral(argument.argumentExpression)) {
        rule.reportAtNode(
          argument.argumentExpression,
          arguments: [parameterName, constructor],
        );
      }
    }
  }
}
