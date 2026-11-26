// The node builders are part of `CoreTreeContract<W>`: the platform `Tree`
// exposes them through the contract, so a builder renamed or re-shaped on one
// platform stops compiling instead of drifting from its twin. The contract
// states the build context as `Never`, so a builder written against the
// platform's own `BuildContext` is still one of the contract's.

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _leading(
  BuildContext context,
  CoreTreeNode node, {
  required bool expanded,
}) => const SizedBox();

Widget _trailing(
  BuildContext context,
  CoreTreeNode node, {
  required bool expanded,
}) => const Text('M');

Widget _loading(BuildContext context, CoreTreeNode node) => const SizedBox();

Widget _error(BuildContext context, CoreTreeNode node, Object error) =>
    const SizedBox();

void main() {
  test('Tree exposes its node builders through CoreTreeContract<Widget>', () {
    const CoreTreeContract<Widget> tree = Tree(
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
  });

  test('unset builders read null through the contract', () {
    const CoreTreeContract<Widget> tree = Tree(nodes: []);

    expect(tree.leadingBuilder, isNull);
    expect(tree.trailingBuilder, isNull);
    expect(tree.loadingBuilder, isNull);
    expect(tree.errorBuilder, isNull);
  });

  test("a platform builder is one of the contract's", () {
    expect(_trailing, isA<TreeNodeBuilder>());
    expect(_trailing, isA<CoreTreeNodeBuilder<Widget>>());
    expect(_error, isA<TreeLoadErrorBuilder>());
    expect(_error, isA<CoreTreeLoadErrorBuilder<Widget>>());
    expect(_loading, isA<CoreTreeLoadingBuilder<Widget>>());
  });
}
