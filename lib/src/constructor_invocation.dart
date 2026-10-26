import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:dimension_lint/src/flutter_element.dart';

/// A Flutter constructor invocation, reduced to the parts the rules match on.
class FlutterConstructorInvocation {
  /// The name of the type being constructed, such as `SizedBox`.
  final String typeName;

  /// The name of the named constructor -- `all` for `EdgeInsets.all` -- or
  /// `null` when the unnamed constructor was invoked.
  final String? constructorName;

  /// The arguments the constructor was given.
  final ArgumentList argumentList;

  /// Creates the invocation.
  const FlutterConstructorInvocation({
    required this.typeName,
    required this.constructorName,
    required this.argumentList,
  });
}

/// Reduces [node] to the parts the rules match on, or returns `null` if it is
/// not a constructor invocation on a type declared in the `flutter` package.
///
/// This normalizes over the two AST shapes a constructor call can take. Since
/// Dart 3.10, dot shorthands let the same constructor be written two ways that
/// parse to different nodes: `EdgeInsets.all(16)` is an
/// [InstanceCreationExpression], while `padding: .all(16)` -- where the context
/// type supplies `EdgeInsets` -- is a [DotShorthandConstructorInvocation].
/// Matching on only the first would silently miss the shorthand, so every rule
/// registers both node types and matches on this instead.
FlutterConstructorInvocation? resolveFlutterConstructor(AstNode node) =>
    switch (node) {
      InstanceCreationExpression() => _resolve(
        node.constructorName.type.element,
        node.constructorName.name?.name,
        node.argumentList,
      ),
      DotShorthandConstructorInvocation() => _resolve(
        _target(node.element)?.enclosingElement,
        // `.new(...)` invokes the unnamed constructor, which the other shape
        // reports as `null`.
        node.constructorName.name == 'new' ? null : node.constructorName.name,
        node.argumentList,
      ),
      _ => null,
    };

FlutterConstructorInvocation? _resolve(
  Element? type,
  String? constructorName,
  ArgumentList argumentList,
) {
  var typeName = type?.name;
  // A project may well declare its own `SizedBox`; only Flutter's counts.
  if (typeName == null || !isFromFlutterPackage(type)) return null;
  return FlutterConstructorInvocation(
    typeName: typeName,
    constructorName: constructorName,
    argumentList: argumentList,
  );
}

/// Follows redirecting factory constructors to the one actually invoked.
///
/// A dot shorthand resolves against its context type, and Flutter declares
/// redirecting factories on the abstract base classes so that the shorthand
/// works at all: `const factory EdgeInsetsGeometry.all(double) =
/// EdgeInsets.all;`. So `padding: .all(16)` resolves to a constructor on
/// `EdgeInsetsGeometry`, and a rule matching `EdgeInsets` would miss it unless
/// the redirect is followed.
///
/// The chain is bounded rather than followed to a fixed point, because a cyclic
/// redirect is a compile-time error the analyzer reports separately but still
/// hands to a rule.
ConstructorElement? _target(ConstructorElement? constructor) {
  var current = constructor;
  for (var hops = 0; hops < 8; hops++) {
    var redirected = current?.redirectedConstructor;
    if (redirected == null) return current;
    current = redirected;
  }
  return current;
}
