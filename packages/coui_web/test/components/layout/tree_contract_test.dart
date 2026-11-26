// The node builders are part of `CoreTreeContract<W>`: the platform `Tree`
// exposes them through the contract, so a builder renamed or re-shaped on one
// platform stops compiling instead of drifting from its twin. The contract
// states the build context as `Never`, so a builder written against the
// platform's own `BuildContext` is still one of the contract's.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

Component _leading(
  BuildContext context,
  CoreTreeNode node, {
  required bool expanded,
}) => const Component.text('');

Component _trailing(
  BuildContext context,
  CoreTreeNode node, {
  required bool expanded,
}) => const Component.text('M');

Component _loading(BuildContext context, CoreTreeNode node) =>
    const Component.text('');

Component _error(BuildContext context, CoreTreeNode node, Object error) =>
    const Component.text('');

void main() {
  test(
    'Tree exposes its node builders through CoreTreeContract<Component>',
    () {
      const CoreTreeContract<Component> tree = Tree(
        nodes: [],
        leadingBuilder: _leading,
        trailingBuilder: _trailing,
        loadingBuilder: _loading,
        errorBuilder: _error,
      );

      expect(tree.leadingBuilder, _leading);
      expect(tree.trailingBuilder, _trailing);
      expect(tree.loadingBuilder, _loading);
      expect(tree.errorBuilder, _error);
    },
  );

  test('unset builders read null through the contract', () {
    const CoreTreeContract<Component> tree = Tree(nodes: []);

    expect(tree.leadingBuilder, isNull);
    expect(tree.trailingBuilder, isNull);
    expect(tree.loadingBuilder, isNull);
    expect(tree.errorBuilder, isNull);
  });

  test("a platform builder is one of the contract's", () {
    expect(_trailing, isA<TreeNodeBuilder>());
    expect(_trailing, isA<CoreTreeNodeBuilder<Component>>());
    expect(_error, isA<TreeLoadErrorBuilder>());
    expect(_error, isA<CoreTreeLoadErrorBuilder<Component>>());
    expect(_loading, isA<CoreTreeLoadingBuilder<Component>>());
  });
}
