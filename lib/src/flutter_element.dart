import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';

/// Whether [element] is declared in the `flutter` package.
///
/// Matches on the owning package rather than the declaring file, because
/// Flutter moves classes between `src/` files across releases and a path
/// comparison would silently stop matching. A project is free to declare its
/// own `SizedBox` or `EdgeInsets`; only Flutter's count.
bool isFromFlutterPackage(Element? element) {
  var uri = element?.library?.uri;
  if (uri == null || uri.scheme != 'package') return false;
  var segments = uri.pathSegments;
  return segments.isNotEmpty && segments.first == 'flutter';
}

/// Values that are never reported, whatever the sizing convention.
///
/// `0` and `1` are structural rather than design values: `EdgeInsets.only(left:
/// 0)` and `SizedBox(height: 1)` carry no scaling intent, and a hairline of `1`
/// must not scale. Flagging them produces noise that teaches people to disable
/// the rule.
///
/// This is deliberately not configurable. `analysis_server_plugin` has no
/// mechanism for passing arguments to a rule -- a rule's configuration in
/// `analysis_options.yaml` can only set its severity -- so a tunable list has
/// nowhere to live. Use `// ignore:` comments or `analyzer: exclude:` for
/// anything these defaults get wrong.
bool _isExempt(num value) => value == 0 || value == 1;

/// Whether [expression] is a numeric literal that should be reported.
///
/// `16.h` parses as a property access and `AppSpacing.md` as a static field
/// reference, so both fall outside this check structurally, with no
/// special-casing needed. Variables and arithmetic are likewise out of scope.
/// This is also why the rules need no `mode` setting: a ScreenUtil extension
/// and a design token are both simply "not a literal".
bool isReportableNumericLiteral(Object? expression) => switch (expression) {
  IntegerLiteral(:var value?) => !_isExempt(value),
  DoubleLiteral(:var value) => !_isExempt(value),
  _ => false,
};
