import 'package:jaspr/dom.dart' show div;
import 'package:jaspr/server.dart' hide Document;

/// A passive reader rooted in the original registry build and actual mount.
abstract interface class CurrentSsrBoxSource {
  void recordBuild(Component result, div capture);
  Map<String, Object?> observe(Element root);
}

List<Element> _children(Element element) {
  final children = <Element>[];
  element.visitChildren(children.add);
  return children;
}

/// The sole already built child, never an ordered raw-slot traversal.
Element soleCurrentSsrChild(Element element) {
  final children = _children(element);
  if (children.length != 1) {
    throw StateError('SSR_CURRENT_CHILD_COUNT_CHANGED');
  }
  return children.single;
}

/// Finds one mounted occurrence of this exact original component object.
Element currentSsrIdentityElement(Element root, Component component) {
  final matches = <Element>[];
  void visit(Element element) {
    if (identical(element.component, component)) matches.add(element);
    element.visitChildren(visit);
  }

  visit(root);
  if (matches.length != 1) {
    throw StateError('SSR_CURRENT_IDENTITY_NOT_UNIQUE');
  }
  return matches.single;
}

// Jaspr's typed div is a StatelessComponent. Its single built DomComponent
// carries the exact declared children; both public hops must be retained.
Element currentSsrGeneratedDiv(Element element, div declared) {
  if (!identical(element.component, declared)) {
    throw StateError('SSR_TYPED_DIV_COMPONENT_CHANGED');
  }
  final domElement = soleCurrentSsrChild(element);
  final dom = domElement.component;
  if (dom is! DomComponent ||
      dom.tag != 'div' ||
      dom.children == null ||
      dom.children!.length != declared.children.length ||
      List.generate(
        declared.children.length,
        (index) => identical(dom.children![index], declared.children[index]),
      ).any((same) => !same)) {
    throw StateError('SSR_GENERATED_DIV_CHANGED');
  }
  return domElement;
}
