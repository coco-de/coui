// The class that carries a `Document.html` declaration is private to jaspr,
// so its fields can only be read by name — every such read is a dynamic call.
// ignore_for_file: avoid_dynamic_calls
import 'package:jaspr/server.dart' show Document;
import 'package:jaspr_test/jaspr_test.dart';

/// The attributes the app has declared on `<html>`, merged the way a page
/// merges them: a later declaration overrides an earlier one of the same name.
///
/// A component test never reaches the server adapter that would merge them
/// into a page, so the tree is where they are read. The component that
/// carries them is found by what it implements and its fields are read by
/// name.
Map<String, String> declaredHtmlAttributes(ComponentTester tester) {
  final merged = <String, String>{};
  for (final element
      in find.byComponentPredicate((c) => c is Document).evaluate()) {
    final component = element.component;
    if (component.runtimeType.toString() != '_AttachDocument') continue;
    final dynamic declaration = component;
    if (declaration.target != 'html') continue;
    final attributes = declaration.attributes as Map<String, String>?;
    if (attributes != null) merged.addAll(attributes);
  }

  return merged;
}
