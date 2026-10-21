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

/// Whether [expression] is a numeric literal, and so names a dimension
/// directly rather than deferring to a sizing convention.
///
/// `16.h` parses as a property access and `AppSpacing.md` as a static field
/// reference, so both fall outside this check structurally, with no
/// special-casing needed. Variables and arithmetic are likewise out of scope.
bool isNumericLiteral(Object? expression) =>
    expression is IntegerLiteral || expression is DoubleLiteral;
