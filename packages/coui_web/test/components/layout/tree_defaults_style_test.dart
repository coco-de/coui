// What a default Web `Tree` row emits, read back as CSS — the twin of the
// Flutter geometry test (`coui_flutter/test/components/layout/
// tree_defaults_test.dart`), which measures the same row. The numbers below
// are written out in both files on purpose: a second source, so a default
// that moves on one platform fails the other platform's test instead of
// taking its own expectation along.
//
// A row's name starts at: node inset (6) + depth × indent (18) + chevron
// slot (12) + chevron ↔ icon gap (6) + icon (14) + icon ↔ name gap (6).

import 'package:coui_web/coui_web.dart';
// tree_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/layout/tree/tree_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedTreeNode _node(
  BuildContext context,
  ResolvedTree resolved, {
  int depth = 0,
  bool selected = false,
  bool isExpanded = false,
  bool hasTrailing = false,
}) => resolveTreeNode(
  context: context,
  resolved: resolved,
  depth: depth,
  selected: selected,
  isExpanded: isExpanded,
  scopeId: 'co-tree-defaults',
  hasTrailing: hasTrailing,
);

String _prop(WebElementChrome chrome, String property) =>
    chrome.inlineStyles!.properties[property]!;

/// Evaluates the lengths the tree resolver emits to px, against the standard
/// density's `--coui-space-*` values: `var(--coui-space-N)`, `Nrem`, and the
/// `calc(a + b * c)` the row's left inset is written as.
double _px(String css) {
  final value = css.trim();
  if (value.startsWith('calc(') && value.endsWith(')')) {
    final inner = value.substring('calc('.length, value.length - 1);
    return inner
        .split(' + ')
        .map(
          (sum) => sum
              .split(' * ')
              .map(_px)
              .reduce((product, factor) => product * factor),
        )
        .reduce((total, term) => total + term);
  }
  final space = RegExp(r'^var\(--coui-space-(\d+)\)$').firstMatch(value);
  if (space != null) return double.parse(space.group(1)!);
  if (value.endsWith('rem')) {
    return double.parse(value.substring(0, value.length - 3)) * kRemDivisor;
  }
  if (value.endsWith('px')) {
    return double.parse(value.substring(0, value.length - 2));
  }

  return double.parse(value);
}

/// Where the name starts, measured from the row's left edge — summed from
/// what the resolver emitted for each part of the row.
double _nameInset(ResolvedTree resolved, ResolvedTreeNode node) =>
    _px(_prop(node.root, 'padding-left')) +
    _px(_prop(resolved.chevronSpacer, 'width')) +
    _px(_prop(resolved.iconGap, 'width')) +
    resolved.iconStyle.size! +
    _px(_prop(resolved.labelGap, 'width'));

void main() {
  group('Tree default row — emitted CSS', () {
    testComponents('padding is 0 on the block axis and 6 on the sides, four '
        'sides stated', (tester) async {
      final context = _themedContext(tester);
      final node = _node(context, resolveTree(context));

      final sides = _prop(node.root, 'padding').split(' ').map(_px).toList();
      expect(sides, [0, 6, 0, 6]);
    });

    testComponents('the row is 28 tall at least, pinned (a literal length '
        'a density does not move)', (tester) async {
      final context = _themedContext(tester);
      final node = _node(context, resolveTree(context));

      expect(_prop(node.root, 'min-height'), '1.75rem');
      expect(_px(_prop(node.root, 'min-height')), 28);
      expect(_prop(node.root, 'min-height'), isNot(contains('var(')));
      // The 21 px label sits in the middle of the 28 px row: the row centres
      // its content on the cross axis.
      expect(node.root.className.split(' '), contains('items-center'));
    });

    testComponents('a nodeMinHeight override moves the pinned min-height', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final node = _node(
        context,
        resolveTree(
          context,
          treeStyle: const CoreTreeStyle(nodeMinHeight: 36),
        ),
      );

      expect(_px(_prop(node.root, 'min-height')), 36);
    });

    testComponents('the label takes the remaining width only while the row '
        'has a trailing widget', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      final bare = _node(context, resolved);
      expect(bare.label.className.split(' '), isNot(contains('flex-1')));
      expect(bare.label.className.split(' '), contains('min-w-0'));

      final withTrailing = _node(context, resolved, hasTrailing: true);
      expect(withTrailing.label.className.split(' '), contains('flex-1'));
      expect(withTrailing.label.className.split(' '), contains('min-w-0'));
    });

    testComponents('the left inset is the node padding PLUS depth × indent, '
        'not depth × indent alone', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      for (final (depth, left) in [(0, 6.0), (1, 24.0), (2, 42.0)]) {
        final node = _node(context, resolved, depth: depth);

        expect(
          _prop(node.root, 'padding-left'),
          'calc(var(--coui-space-6) + $depth * var(--coui-space-18))',
        );
        // Flutter's row: `itemPadding + .only(left: indent * depth)`.
        expect(_px(_prop(node.root, 'padding-left')), left);
      }
    });

    testComponents('a root name starts at 44 and each level adds 18 — the '
        'x the Flutter row measures', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      for (final (depth, inset) in [(0, 44.0), (1, 62.0), (2, 80.0)]) {
        expect(
          _nameInset(resolved, _node(context, resolved, depth: depth)),
          inset,
          reason: 'depth $depth',
        );
      }
    });

    testComponents('the row corner is radius 6', (tester) async {
      final context = _themedContext(tester);
      final node = _node(context, resolveTree(context));

      expect(
        _prop(node.root, 'border-radius'),
        'var(--coui-radius-6) var(--coui-radius-6) '
        'var(--coui-radius-6) var(--coui-radius-6)',
      );
    });

    testComponents('the name is code-sm — onSurfaceVariant at rest, onSurface '
        'when selected', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(
        _node(context, resolved).label.className,
        startsWith('text-code-sm text-on-surface-variant '),
      );
      expect(
        _node(context, resolved, selected: true).label.className,
        startsWith('text-code-sm text-on-surface '),
      );
    });

    testComponents('the selected face is the opaque surfaceContainerHigh, '
        'not a tint of primary', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      final selected = _node(context, resolved, selected: true).root.className;
      expect(selected, contains('bg-surface-container-high'));
      expect(selected, isNot(contains('bg-primary')));
      // An unselected row paints no face.
      expect(
        _node(context, resolved).root.className,
        isNot(contains('bg-surface-container-high')),
      );
    });

    testComponents('the chevron is onSurfaceSubtle in every row state', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      // One colour for every row state — the Flutter twin draws the same.
      for (final selected in [false, true]) {
        final chevron = _node(context, resolved, selected: selected).chevron;
        expect(chevron.className, contains('text-on-surface-subtle'));
        expect(chevron.className, isNot(contains('text-on-surface-variant')));
      }
    });

    testComponents('a folder icon is onSurfaceVariant, a file icon '
        'onSurfaceSubtle', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(resolved.icon.className, contains('text-on-surface-variant'));
      expect(resolved.leafIcon.className, contains('text-on-surface-subtle'));
      expect(
        resolved.leafIcon.className,
        isNot(contains('text-on-surface-variant')),
      );
      expect(resolved.iconStyle.size, 14);
      expect(resolved.leafIconStyle.size, 14);
    });

    testComponents('an iconStyle colour recolours folders and files alike', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.primary)),
        ),
      );

      expect(resolved.icon.className, contains('text-primary'));
      expect(resolved.leafIcon.className, contains('text-primary'));
    });

    testComponents('a leafIconStyle recolours the file icon alone, over an '
        'iconStyle colour', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          iconStyle: CoreIconStyle(color: CoreColor.token(CoreColors.primary)),
          leafIconStyle: CoreIconStyle(
            size: 16,
            color: CoreColor.token(CoreColors.error),
          ),
        ),
      );

      expect(resolved.leafIcon.className, contains('text-error'));
      expect(resolved.leafIcon.className, isNot(contains('text-primary')));
      expect(resolved.leafIconStyle.size, 16);
      // The folder keeps the caller's iconStyle colour and size.
      expect(resolved.icon.className, contains('text-primary'));
      expect(resolved.iconStyle.size, 14);
    });

    testComponents('a chevronIconStyle colour wins over the default', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          chevronIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );
      final node = _node(context, resolved);

      expect(node.chevron.className, contains('text-primary'));
      expect(node.chevron.className, isNot(contains('text-on-surface-subtle')));
      expect(resolved.chevronIconStyle.size, 12);
    });
  });

  group('Tree default glyphs and gaps', () {
    testComponents('the leading glyph is 14 and the chevron its own 12', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(resolved.iconStyle.size, 14);
      expect(resolved.chevronIconStyle.size, 12);
    });

    testComponents("the leaf slot holds the chevron's 12, pinned", (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      // A slot, not spacing: a literal length a density does not move.
      expect(_prop(resolved.chevronSpacer, 'width'), '0.75rem');
    });

    testComponents('both gaps are 6, through the spacing variable', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(_prop(resolved.iconGap, 'width'), 'var(--coui-space-6)');
      expect(_prop(resolved.labelGap, 'width'), 'var(--coui-space-6)');
    });

    testComponents('resizing the leading glyph leaves the chevron at 12 and '
        'the leaf slot with it', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(iconStyle: CoreIconStyle(size: 20)),
      );

      expect(resolved.iconStyle.size, 20);
      expect(resolved.chevronIconStyle.size, 12);
      expect(_prop(resolved.chevronSpacer, 'width'), '0.75rem');
    });

    testComponents('a chevron override resizes the chevron and the leaf slot '
        'follows it', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          chevronIconStyle: CoreIconStyle(size: 16),
        ),
      );

      expect(resolved.chevronIconStyle.size, 16);
      expect(resolved.iconStyle.size, 14);
      expect(_px(_prop(resolved.chevronSpacer, 'width')), 16);
    });
  });

  group('Tree node padding overrides', () {
    testComponents('each side is honoured — an asymmetric inset moves the '
        'left and the right apart', (tester) async {
      final context = _themedContext(tester);
      const style = CoreTreeStyle(
        nodePadding: CoreEdgeInsets.fromLTRB(9, 3, 13, 5),
      );
      final resolved = resolveTree(context, treeStyle: style);
      final node = _node(context, resolved, depth: 1);

      // top right bottom left, the CSS order. 9 / 3 / 13 / 5 are off the
      // spacing steps, so they ride as literal rem.
      final sides = _prop(node.root, 'padding').split(' ').map(_px).toList();
      expect(sides, [3, 13, 5, 9]);
      // The overridden left inset is what the indent adds to.
      expect(_px(_prop(node.root, 'padding-left')), 9 + 18);
    });
  });

  group('Tree rename field', () {
    testComponents('the field the double-click mounts takes the row corner, '
        'the code role and the xs height', (tester) async {
      pumpWithTheme(
        tester,
        const Tree(
          nodes: [CoreTreeNode(id: 'main', label: 'main.dart')],
          onNodeRename: _ignoreRename,
        ),
      );
      await tester.pump();

      tester.dispatchEvent(
        find.byComponentPredicate(
          (component) =>
              component is Clickable && component.id == 'tree-node.main',
          description: 'tree row main',
        ),
        'dblclick',
      );
      await tester.pump();

      final field =
          find.byType(TextField).evaluate().single.component as TextField;
      final style = field.textFieldStyle!;
      expect(
        style.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius6),
      );
      expect(style.baseTextStyle?.token, CoreTextStyles.codeSm);
      expect(style.height, CoreControlSize.heightXs);
    });

    testComponents('while renaming, the trailing still follows a labelGap '
        'span after the field', (tester) async {
      pumpWithTheme(
        tester,
        Tree(
          nodes: const [CoreTreeNode(id: 'main', label: 'main.dart')],
          onNodeRename: _ignoreRename,
          trailingBuilder: (context, node, {required expanded}) =>
              const Text('M'),
        ),
      );
      await tester.pump();
      final before = _emptySpans();

      tester.dispatchEvent(
        find.byComponentPredicate(
          (component) =>
              component is Clickable && component.id == 'tree-node.main',
          description: 'tree row main',
        ),
        'dblclick',
      );
      await tester.pump();

      expect(find.byType(TextField), findsOneComponent);
      expect(find.text('M'), findsOneComponent);
      // The icon-to-name gap and the name-to-trailing gap both stay.
      expect(_emptySpans(), before);
    });

    // Twin of the Flutter test 'row stays 28 while renaming'
    // (tree_defaults_test.dart). The Web row has no layout in this harness,
    // so the height itself is not measured here; the cause is read instead:
    // the field (24, the `xs` control) fits inside the row's pinned 28
    // minimum, so replacing the 21px label with it does not grow the row.
    testComponents('the field fits the pinned row minimum, so the row does '
        'not grow while renaming', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(resolved.renameFieldStyle.height, CoreControlSize.heightXs);
      expect(resolved.renameFieldStyle.height, 24);
      expect(
        _px(_prop(_node(context, resolved).root, 'min-height')),
        greaterThanOrEqualTo(resolved.renameFieldStyle.height!),
      );
    });

    testComponents('the typed text is onSurface — not the dimmer colour the '
        'label rests on', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      // The label rests on onSurfaceVariant…
      expect(
        _node(context, resolved).label.className,
        contains('text-on-surface-variant'),
      );
      // …and the field the double-click mounts states onSurface itself.
      expect(
        resolved.renameFieldStyle.baseTextStyle?.color,
        const CoreColor.token(CoreColors.onSurface),
      );
      expect(
        resolved.renameFieldStyle.baseTextStyle?.token,
        CoreTextStyles.codeSm,
      );
    });

    testComponents('a caller-restyled label colour leaves the typed text '
        'alone', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          nodeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      );

      expect(
        resolved.renameFieldStyle.baseTextStyle?.color,
        const CoreColor.token(CoreColors.onSurface),
      );
    });
  });

  group('Tree drop affordances', () {
    // The drop tint and the insertion line are primary — their own colours,
    // not the selected face. The widgets paint exactly what the resolver
    // emits here, so a selected face that moves must not move them.
    testComponents('the target tint is primary at 10 %, the line a 2px solid '
        'primary', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      expect(
        _prop(resolved.dropTarget, 'background-color'),
        'rgb(var(--coui-primary) / 10%)',
      );
      expect(
        _prop(resolved.dropIndicator, 'border-top'),
        '2px solid rgb(var(--coui-primary))',
      );
    });

    testComponents('a restyled selected face leaves both alone', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          nodeSelectedColor: CoreColor.token(CoreColors.error),
        ),
      );

      // The selected row takes the override…
      expect(
        _node(context, resolved, selected: true).root.className,
        contains('bg-error'),
      );
      // …and the drag states do not.
      expect(
        _prop(resolved.dropTarget, 'background-color'),
        'rgb(var(--coui-primary) / 10%)',
      );
      expect(
        _prop(resolved.dropIndicator, 'border-top'),
        '2px solid rgb(var(--coui-primary))',
      );
    });

    testComponents('their own overrides are honoured', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          dropTargetColor: CoreColor.token(
            CoreColors.success,
            opacity: CoreOpacity.opacity20,
          ),
          dropIndicatorColor: CoreColor.token(CoreColors.success),
        ),
      );

      expect(
        _prop(resolved.dropTarget, 'background-color'),
        'rgb(var(--coui-success) / 20%)',
      );
      expect(
        _prop(resolved.dropIndicator, 'border-top'),
        '2px solid rgb(var(--coui-success))',
      );
    });
  });

  group('Tree drag ghost', () {
    // The ghost lifted off a row is that row: its corner and left inset are
    // the row's own declarations, resolved from the merged `borderRadius`,
    // `nodePadding` and `indent`, not restated by the widget.
    testComponents('takes the row corner and left inset at the default', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(context);

      for (final depth in [0, 1, 3]) {
        final node = _node(context, resolved, depth: depth);

        expect(
          _prop(node.dragGhost, 'padding-left'),
          _prop(node.root, 'padding-left'),
        );
        expect(
          _prop(node.dragGhost, 'padding-left'),
          'calc(var(--coui-space-6) + $depth * var(--coui-space-18))',
        );
        expect(
          _prop(node.dragGhost, 'border-radius'),
          _prop(node.root, 'border-radius'),
        );
      }
      // The corner is radius 6 — not the radius 8 the ghost used to state.
      expect(
        _prop(_node(context, resolved).dragGhost, 'border-radius'),
        'var(--coui-radius-6) var(--coui-radius-6) '
        'var(--coui-radius-6) var(--coui-radius-6)',
      );
    });

    testComponents('follows a merged corner, node padding and indent', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveTree(
        context,
        treeStyle: const CoreTreeStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
          nodePadding: CoreEdgeInsets.fromLTRB(10, 4, 10, 4),
          indent: 24,
        ),
      );
      final node = _node(context, resolved, depth: 2);

      // 10 is off the spacing steps, so the inset rides as literal rem; the
      // 24 indent is a step. Left inset = 10 + 2 × 24, the row's own.
      expect(_px(_prop(node.dragGhost, 'padding-left')), 10 + 2 * 24);
      expect(
        _prop(node.dragGhost, 'padding-left'),
        _prop(node.root, 'padding-left'),
      );
      expect(
        _prop(node.dragGhost, 'border-radius'),
        'var(--coui-radius-12) var(--coui-radius-12) '
        'var(--coui-radius-12) var(--coui-radius-12)',
      );
      expect(
        _prop(node.dragGhost, 'border-radius'),
        _prop(node.root, 'border-radius'),
      );
    });

    testComponents('states only the corner and the inset — the measured size '
        'and the lifted surface stay with the widget', (tester) async {
      final context = _themedContext(tester);
      final ghost = _node(context, resolveTree(context)).dragGhost;

      expect(ghost.inlineStyles!.properties.keys, {
        'padding-left',
        'border-radius',
      });
    });
  });

  _glyphAndTrailingTests();
}

void _ignoreRename(CoreTreeNode node, String label) {}

// Rendered row content — the Web twin of the Flutter glyph and trailing
// assertions: the default glyph per node kind, and the label that fills the
// row only when something trails it.
const _glyphNodes = [
  CoreTreeNode(
    id: 'open',
    label: 'open',
    expanded: true,
    children: [CoreTreeNode(id: 'leaf', label: 'leaf')],
  ),
  CoreTreeNode(
    id: 'closed',
    label: 'closed',
    children: [CoreTreeNode(id: 'hidden', label: 'hidden')],
  ),
];

DomComponent _labelSpan(String label) =>
    find
            .byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  c.tag == 'span' &&
                  (c.children?.whereType<Text>().any((t) => t.data == label) ??
                      false),
              description: 'label span $label',
            )
            .evaluate()
            .single
            .component
        as DomComponent;

int _emptySpans() => find
    .byComponentPredicate(
      (c) =>
          c is DomComponent &&
          c.tag == 'span' &&
          (c.children?.isEmpty ?? false),
      description: 'empty span',
    )
    .evaluate()
    .length;

void _glyphAndTrailingTests() {
  group('Tree rendered row', () {
    testComponents('the default glyph follows the node kind', (tester) async {
      pumpWithTheme(tester, const Tree(nodes: _glyphNodes));
      await tester.pump();

      final icons = find
          .byType(Icon)
          .evaluate()
          .map((e) => (e.component as Icon).icon)
          .toList();
      expect(icons, contains(LucideIcons.folderOpen));
      expect(icons, contains(LucideIcons.folderClosed));
      expect(icons, contains(LucideIcons.file));
      expect(icons, isNot(contains(LucideIcons.folder)));
    });

    testComponents('the wrapper around a file icon is onSurfaceSubtle, the one '
        'around a folder icon onSurfaceVariant', (tester) async {
      pumpWithTheme(tester, const Tree(nodes: _glyphNodes));
      await tester.pump();

      String wrapperClassesOf(IconName icon) {
        final wrapper = find
            .byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  c.tag == 'span' &&
                  (c.children?.whereType<Icon>().any(
                        (glyph) => glyph.icon == icon,
                      ) ??
                      false),
              description: 'wrapper of $icon',
            )
            .evaluate()
            .first
            .component;
        return (wrapper as DomComponent).classes ?? '';
      }

      final file = wrapperClassesOf(LucideIcons.file);
      expect(file, contains('text-on-surface-subtle'));
      expect(file, isNot(contains('text-on-surface-variant')));
      final folder = wrapperClassesOf(LucideIcons.folderOpen);
      expect(folder, contains('text-on-surface-variant'));
      expect(folder, isNot(contains('text-on-surface-subtle')));
    });

    testComponents('a leadingBuilder widget on a file row keeps the folder '
        'wrapper colour, not the file glyph colour', (tester) async {
      pumpWithTheme(
        tester,
        Tree(
          nodes: _glyphNodes,
          leadingBuilder: (context, node, {required expanded}) =>
              const Icon(LucideIcons.star),
        ),
      );
      await tester.pump();

      final wrappers = find
          .byComponentPredicate(
            (c) =>
                c is DomComponent &&
                c.tag == 'span' &&
                (c.children?.whereType<Icon>().any(
                      (glyph) => glyph.icon == LucideIcons.star,
                    ) ??
                    false),
            description: 'leading wrappers',
          )
          .evaluate()
          .map((e) => (e.component as DomComponent).classes ?? '');
      expect(wrappers, isNotEmpty);
      for (final classes in wrappers) {
        expect(classes, contains('text-on-surface-variant'));
        expect(classes, isNot(contains('text-on-surface-subtle')));
      }
    });

    testComponents('a label fills the row, with a gap before the trailing, '
        'only when a trailingBuilder is given', (tester) async {
      pumpWithTheme(tester, const Tree(nodes: _glyphNodes));
      await tester.pump();
      final plainClasses = _labelSpan('closed').classes ?? '';
      final plainSpans = _emptySpans();
      expect(plainClasses, isNot(contains('flex-1')));

      pumpWithTheme(
        tester,
        Tree(
          nodes: _glyphNodes,
          trailingBuilder: (context, node, {required expanded}) =>
              const Text('M'),
        ),
      );
      await tester.pump();
      expect(_labelSpan('closed').classes ?? '', contains('flex-1'));
      // One labelGap span ahead of each trailing: 'open' · 'leaf' · 'closed'.
      expect(_emptySpans(), plainSpans + 3);
    });
  });
}
