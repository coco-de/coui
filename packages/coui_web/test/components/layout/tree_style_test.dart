import 'package:coui_web/coui_web.dart';
// tree_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/layout/tree/tree_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveTree` / `resolveTreeNode` / `resolveTreeRules` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// A raw (token-less) colour — the exact case that used to throw
/// `token!.name` when routed onto a pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

/// A design-system token — the class path that must stay byte-identical.
const _kTokenPrimary = CoreColor.token(CoreColors.primary);

void main() {
  group('Tree node hover — default (class / no-op) path', () {
    testComponents(
      'a token nodeHoverColor keeps the hover:bg-{token} utility class and '
      'emits no scoped rule (output-equivalent to pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTreeStyle(nodeHoverColor: _kTokenPrimary);
        final resolved = resolveTree(context, treeStyle: style);
        final node = resolveTreeNode(
          context: context,
          resolved: resolved,
          depth: 0,
          selected: false,
          isExpanded: false,
          scopeId: 'co-tree-test',
        );
        expect(node.root.className, contains('hover:bg-primary'));
        expect(node.root.className, isNot(contains('co-tree-h-')));

        final rules = resolveTreeRules(
          context,
          scopeId: 'co-tree-test',
          treeStyle: style,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents(
      'no nodeHoverColor override emits neither a hover class nor a rule',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveTree(context);
        final node = resolveTreeNode(
          context: context,
          resolved: resolved,
          depth: 0,
          selected: false,
          isExpanded: false,
          scopeId: 'co-tree-test',
        );
        expect(node.root.className, isNot(contains('hover:bg')));
        expect(node.root.className, isNot(contains('co-tree-h-')));

        final rules = resolveTreeRules(context, scopeId: 'co-tree-test');
        expect(rules.css, isEmpty);
      },
    );
  });

  group('Tree node hover — raw override (scoped-rule) path', () {
    testComponents(
      'a raw nodeHoverColor override no longer throws — the hover:bg class '
      'is dropped, the row carries the shared scope class, and the hover '
      'paints via a scoped .co-tree-h-<id>:hover rule instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreTreeStyle(nodeHoverColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final resolved = resolveTree(context, treeStyle: style);
        final node = resolveTreeNode(
          context: context,
          resolved: resolved,
          depth: 0,
          selected: false,
          isExpanded: false,
          scopeId: 'co-tree-raw',
        );
        // The colour class cannot carry a raw colour, so the hover:bg
        // block is dropped in favour of the shared scope class.
        expect(node.root.className, isNot(contains('hover:bg')));
        expect(node.root.className, contains('co-tree-h-co-tree-raw'));

        final rules = resolveTreeRules(
          context,
          scopeId: 'co-tree-raw',
          treeStyle: style,
        );
        expect(rules.css, contains('.co-tree-h-co-tree-raw:hover'));
        expect(rules.css, contains('background-color'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );
  });
}
