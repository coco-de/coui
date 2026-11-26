// Rendered geometry of a default `Tree` row.
//
// Each test reads a laid-out size or position back from the widget tree — a
// value the user sees — not the `default*` constant that was meant to produce
// it. A declaration can equal itself while the row paints something else.
//
// Every scaling axis is 1, so a measured pixel is the value the style stated
// (or the density's rung of it) and nothing else.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

final _theme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    textScaling: 1,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Tree tree, {
  CoreDensity? density,
}) async {
  final home = w.Align(
    alignment: w.Alignment.topLeft,
    child: w.SizedBox(width: 400, child: tree),
  );
  await tester.pumpWidget(
    density == null
        ? CoUIApp(theme: _theme, home: home)
        : CoUIApp(theme: _theme, density: density, home: home),
  );
  await tester.pumpAndSettle();
}

/// The painted row of the node labelled [label] — the outermost `Container`
/// around it that carries a corner, i.e. the one with the node padding (a
/// rename field in the row has a rounded surface of its own, nearer the text).
Finder _row(String label) => find
    .ancestor(
      of: find.text(label),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is w.Container &&
            widget.decoration is w.BoxDecoration &&
            (widget.decoration! as w.BoxDecoration).borderRadius != null,
      ),
    )
    .last;

Finder _glyph(IconName name) => find.byWidgetPredicate(
  (widget) => widget is Icon && widget.icon == name,
);

/// A theme token as the colour the active scheme paints.
Color _token(CoreColor color) => _theme.colorScheme.resolve(color).toValue();

/// The colour [glyph] is painted in — read off the SVG's colour filter, the
/// last step before the pixels.
w.ColorFilter? _paintedColor(WidgetTester tester, Finder glyph) => tester
    .widget<SvgPicture>(
      find.descendant(of: glyph.first, matching: find.byType(SvgPicture)),
    )
    .colorFilter;

/// The icon style handed to the glyph — what `Icon` resolves and paints. Read
/// here for the glyphs whose SVG data is fetched over the network, which a
/// widget test cannot load.
CoreIconStyle? _iconStyleOf(WidgetTester tester, Finder glyph) =>
    tester.widget<Icon>(glyph.first).iconStyle;

/// The fill of the row `Container` of the node labelled [label].
Color? _rowFill(WidgetTester tester, String label) =>
    (tester.widget<w.Container>(_row(label)).decoration! as w.BoxDecoration)
        .color;

/// Distance from the left edge of [label]'s row to where its name starts.
double _nameInset(WidgetTester tester, String label) =>
    tester.getTopLeft(find.text(label)).dx - tester.getTopLeft(_row(label)).dx;

const _foldersAndFile = [
  CoreTreeNode(
    id: 'dir',
    label: 'dir',
    children: [CoreTreeNode(id: 'dir/x', label: 'x')],
  ),
  CoreTreeNode(id: 'file', label: 'file'),
];

const _nodes = [
  CoreTreeNode(
    id: 'src',
    label: 'src',
    expanded: true,
    children: [
      CoreTreeNode(id: 'src/main', label: 'main.dart'),
      CoreTreeNode(
        id: 'src/lib',
        label: 'lib',
        expanded: true,
        children: [CoreTreeNode(id: 'src/lib/a', label: 'a.dart')],
      ),
    ],
  ),
  CoreTreeNode(id: 'README', label: 'README.md'),
];

void main() {
  group('Tree default row geometry', () {
    testWidgets('a row is 28 tall with the 21px label line centred', (
      tester,
    ) async {
      await _pump(tester, const Tree(nodes: _nodes));

      // The label is a fixed 21px line box (the `codeSm` role), whatever
      // its 12px glyphs would ask for on their own; the row's own minimum
      // height (28) does the rest.
      expect(tester.getSize(find.text('README.md')).height, 21);
      expect(tester.getSize(_row('README.md')).height, 28);
      expect(tester.getSize(_row('src')).height, 28);
      expect(
        tester.getCenter(find.text('README.md')).dy,
        tester.getCenter(_row('README.md')).dy,
      );
    });

    testWidgets('a nodeMinHeight override moves the row height', (
      tester,
    ) async {
      await _pump(
        tester,
        const Tree(
          nodes: _nodes,
          treeStyle: CoreTreeStyle(nodeMinHeight: 36),
        ),
      );

      expect(tester.getSize(_row('README.md')).height, 36);
    });

    testWidgets('the default glyphs: open / closed folder and a file', (
      tester,
    ) async {
      await _pump(
        tester,
        const Tree(
          nodes: [
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
          ],
        ),
      );

      expect(_glyph(LucideIcons.folderOpen), findsOneWidget);
      expect(_glyph(LucideIcons.folderClosed), findsOneWidget);
      expect(_glyph(LucideIcons.file), findsOneWidget);
      expect(_glyph(LucideIcons.folder), findsNothing);
    });

    testWidgets('a trailing widget sits at the row end; without one the '
        'name keeps its own width', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: _nodes,
          trailingBuilder: (context, node, {required expanded}) =>
              w.SizedBox(key: Key('trailing-${node.label}'), width: 10),
        ),
      );

      final row = tester.getRect(_row('README.md'));
      final trailing = tester.getRect(
        find.byKey(const Key('trailing-README.md')),
      );
      // The row's right inset is 6; the trailing ends there.
      expect(trailing.right, row.right - 6);
      // A 6px gap (the label gap) separates the name from the trailing.
      expect(
        trailing.left - tester.getRect(find.text('README.md')).right,
        greaterThanOrEqualTo(6),
      );

      await _pump(tester, const Tree(nodes: _nodes));
      expect(
        tester.getRect(find.text('README.md')).right,
        lessThan(tester.getRect(_row('README.md')).right - 40),
      );
    });

    testWidgets('the name is the mono code role at 12px', (tester) async {
      await _pump(tester, const Tree(nodes: _nodes));

      final style = tester.widget<Text>(find.text('README.md')).style!;
      expect(style.fontSize, 12);
      // 21 / 12 — the fixed line box expressed as the multiplier Flutter
      // takes.
      expect(style.height! * style.fontSize!, closeTo(21, 0.001));
      expect(style.fontFamily, contains('Mono'));
    });

    testWidgets('the name rests on onSurfaceVariant and steps up to onSurface '
        'when selected', (tester) async {
      await _pump(tester, const Tree(nodes: _nodes, selectedId: 'README'));

      expect(
        tester.widget<Text>(find.text('main.dart')).style!.color,
        _token(const CoreColor.token(CoreColors.onSurfaceVariant)),
      );
      expect(
        tester.widget<Text>(find.text('README.md')).style!.color,
        _token(const CoreColor.token(CoreColors.onSurface)),
      );
    });

    testWidgets('the selected face is the opaque surfaceContainerHigh', (
      tester,
    ) async {
      await _pump(tester, const Tree(nodes: _nodes, selectedId: 'README'));

      final face = _token(
        const CoreColor.token(CoreColors.surfaceContainerHigh),
      );
      expect(_rowFill(tester, 'README.md'), face);
      // Opaque — a container step, not a tint of the accent.
      expect(face.a, 1.0);
      // An unselected row paints no fill at all.
      expect(_rowFill(tester, 'main.dart'), isNull);
    });

    testWidgets('the chevron is onSurfaceSubtle in every row state', (
      tester,
    ) async {
      const nodes = [
        CoreTreeNode(
          id: 'a',
          label: 'a',
          children: [CoreTreeNode(id: 'a/x', label: 'x')],
        ),
        CoreTreeNode(
          id: 'b',
          label: 'b',
          children: [CoreTreeNode(id: 'b/y', label: 'y')],
        ),
      ];
      await _pump(tester, const Tree(nodes: nodes, selectedId: 'b'));

      final chevrons = _glyph(LucideIcons.chevronRight);
      expect(chevrons, findsNWidgets(2));
      final subtle = w.ColorFilter.mode(
        _token(const CoreColor.token(CoreColors.onSurfaceSubtle)),
        w.BlendMode.srcIn,
      );
      // Unselected and selected rows draw the same chevron colour — it does
      // not follow the label (onSurfaceVariant at rest, onSurface selected).
      expect(_paintedColor(tester, chevrons.at(0)), subtle);
      expect(_paintedColor(tester, chevrons.at(1)), subtle);
    });

    testWidgets('a caller chevronIconStyle colour wins over the default', (
      tester,
    ) async {
      await _pump(
        tester,
        const Tree(
          nodes: _foldersAndFile,
          selectedId: 'dir',
          treeStyle: CoreTreeStyle(
            chevronIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );

      expect(
        _paintedColor(tester, _glyph(LucideIcons.chevronRight)),
        w.ColorFilter.mode(
          _token(const CoreColor.token(CoreColors.primary)),
          w.BlendMode.srcIn,
        ),
      );
      // The size stays the chevron's own 12.
      expect(
        tester.getSize(_glyph(LucideIcons.chevronRight).first),
        const Size(12, 12),
      );
    });

    testWidgets('an iconStyle colour recolours folders and files alike', (
      tester,
    ) async {
      await _pump(
        tester,
        const Tree(
          nodes: _foldersAndFile,
          treeStyle: CoreTreeStyle(
            iconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );

      const primary = CoreColor.token(CoreColors.primary);
      expect(_iconStyleOf(tester, _glyph(LucideIcons.file))?.color, primary);
      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.folderClosed))?.color,
        primary,
      );
    });

    testWidgets('a file glyph is onSurfaceSubtle, a folder glyph '
        'onSurfaceVariant', (tester) async {
      await _pump(tester, const Tree(nodes: _foldersAndFile));

      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.file))?.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.folderClosed))?.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      // Same 14 glyph either way.
      expect(
        tester.getSize(_glyph(LucideIcons.file).first),
        const w.Size(14, 14),
      );
    });

    testWidgets('a leafIconStyle recolours the file glyph alone, over an '
        'iconStyle colour', (tester) async {
      await _pump(
        tester,
        const Tree(
          nodes: _foldersAndFile,
          treeStyle: CoreTreeStyle(
            iconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
            leafIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.error),
            ),
          ),
        ),
      );

      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.file))?.color,
        const CoreColor.token(CoreColors.error),
      );
      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.folderClosed))?.color,
        const CoreColor.token(CoreColors.primary),
      );
    });

    testWidgets('a leafIconStyle alone leaves the folder glyph on '
        'onSurfaceVariant and the leaf size on the leading size', (
      tester,
    ) async {
      await _pump(
        tester,
        const Tree(
          nodes: _foldersAndFile,
          treeStyle: CoreTreeStyle(
            iconStyle: CoreIconStyle(size: 16),
            leafIconStyle: CoreIconStyle(
              color: CoreColor.token(CoreColors.error),
            ),
          ),
        ),
      );

      expect(
        _iconStyleOf(tester, _glyph(LucideIcons.folderClosed))?.color,
        const CoreColor.token(CoreColors.onSurfaceVariant),
      );
      final file = _iconStyleOf(tester, _glyph(LucideIcons.file));
      expect(file?.color, const CoreColor.token(CoreColors.error));
      expect(file?.size, 16);
    });

    testWidgets('the row corner is 6', (tester) async {
      await _pump(tester, const Tree(nodes: _nodes));

      final decoration =
          tester.widget<w.Container>(_row('README.md')).decoration!
              as w.BoxDecoration;
      expect(decoration.borderRadius, w.BorderRadius.circular(6));
    });

    testWidgets('the leading glyph is 14, the chevron its own 12', (
      tester,
    ) async {
      await _pump(tester, const Tree(nodes: _nodes));

      expect(
        tester.getSize(_glyph(LucideIcons.folderOpen).first),
        const w.Size(14, 14),
      );
      expect(
        tester.getSize(_glyph(LucideIcons.file).first),
        const w.Size(14, 14),
      );
      expect(
        tester.getSize(_glyph(LucideIcons.chevronRight).first),
        const w.Size(12, 12),
      );
    });

    testWidgets('a root name starts at 6 + 12 + 6 + 14 + 6 = 44', (
      tester,
    ) async {
      await _pump(tester, const Tree(nodes: _nodes));

      // inset · chevron slot · chevron ↔ icon gap · icon · icon ↔ name gap.
      expect(_nameInset(tester, 'src'), 44);
      // A leaf holds the chevron's place, so it starts where a parent does.
      expect(_nameInset(tester, 'README.md'), 44);
    });

    testWidgets('each level steps the name in by 18', (tester) async {
      await _pump(tester, const Tree(nodes: _nodes));

      expect(_nameInset(tester, 'src'), 44);
      expect(_nameInset(tester, 'main.dart'), 44 + 18);
      expect(_nameInset(tester, 'a.dart'), 44 + 2 * 18);
    });

    testWidgets('a child chevron starts where its parent icon starts', (
      tester,
    ) async {
      await _pump(tester, const Tree(nodes: _nodes));

      // The 18 indent is one chevron slot (12) plus the gap after it (6).
      // An expanded chevron is turned a quarter, so its box corner is not
      // its left edge — the centre less half the 12px slot is.
      final parentIconLeft = tester
          .getTopLeft(_glyph(LucideIcons.folderOpen).first)
          .dx;
      final childChevronLeft =
          tester.getCenter(_glyph(LucideIcons.chevronRight).last).dx - 6;
      expect(childChevronLeft, parentIconLeft);
    });

    testWidgets('resizing the leading glyph leaves the chevron alone, and '
        'leaf rows stay in line with parent rows', (tester) async {
      await _pump(
        tester,
        const Tree(
          nodes: _nodes,
          treeStyle: CoreTreeStyle(iconStyle: CoreIconStyle(size: 20)),
        ),
      );

      expect(
        tester.getSize(_glyph(LucideIcons.folderOpen).first),
        const w.Size(20, 20),
      );
      expect(
        tester.getSize(_glyph(LucideIcons.chevronRight).first),
        const w.Size(12, 12),
      );
      // The leaf slot is the chevron's width, not the leading glyph's.
      expect(_nameInset(tester, 'README.md'), _nameInset(tester, 'src'));
    });

    testWidgets('a chevron override resizes the chevron, and the leaf slot '
        'follows it', (tester) async {
      await _pump(
        tester,
        const Tree(
          nodes: _nodes,
          treeStyle: CoreTreeStyle(chevronIconStyle: CoreIconStyle(size: 16)),
        ),
      );

      expect(
        tester.getSize(_glyph(LucideIcons.chevronRight).first),
        const w.Size(16, 16),
      );
      expect(_nameInset(tester, 'src'), 6 + 16 + 6 + 14 + 6);
      expect(_nameInset(tester, 'README.md'), _nameInset(tester, 'src'));
    });

    testWidgets('a node padding override moves the left inset', (tester) async {
      await _pump(
        tester,
        const Tree(
          nodes: _nodes,
          treeStyle: CoreTreeStyle(
            nodePadding: CoreEdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
        ),
      );

      expect(_nameInset(tester, 'src'), 44 + 4);
    });
  });

  group('Tree default row geometry under a density', () {
    // The inset and the two gaps are spacing (6 sits one rung off the 4px
    // grid, so each moves a rung); the chevron slot and the glyph are sizes
    // and stay put. The block inset (4) is the density floor, so the row
    // keeps its height.
    for (final (density, spacing) in [
      (CoreDensity.compact, 4.0),
      (CoreDensity.standard, 6.0),
      (CoreDensity.spacious, 8.0),
    ]) {
      testWidgets(
        '${density.name}: a root name starts at 3 × $spacing + 12 + 14',
        (tester) async {
          await _pump(tester, const Tree(nodes: _nodes), density: density);

          expect(_nameInset(tester, 'src'), 3 * spacing + 12 + 14);
          expect(_nameInset(tester, 'README.md'), 3 * spacing + 12 + 14);
          // nodeMinHeight is the row's own height: density moves the
          // padding beside it, never the row.
          expect(tester.getSize(_row('src')).height, 28);
        },
      );
    }
  });

  group('Tree rename field', () {
    Future<void> doubleTap(WidgetTester tester, String label) async {
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.tap(find.text(label));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('row stays 28 while renaming; the field takes the row corner '
        'and the code role', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: _nodes,
          onNodeSelect: (_) {},
          onNodeRename: (_, _) {},
        ),
      );

      await doubleTap(tester, 'README.md');

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(editable.style.fontSize, 12);
      expect(editable.style.fontFamily, contains('Mono'));

      // The field is the `xs` control height; the 21px code line sits inside
      // it without being clipped.
      final field = find.ancestor(
        of: find.byType(EditableText),
        matching: find.byType(TextField),
      );
      expect(tester.getSize(field).height, 24);
      expect(
        tester.getSize(find.byType(EditableText)).height,
        lessThanOrEqualTo(24),
      );
      // The 24px field fits the row's 28 minimum, so the row does not grow
      // while the name is edited.
      expect(tester.getSize(_row('README.md')).height, 28);

      // Its corner is the row's own — never rounder than the row it sits in.
      // (The focus band and ring drawn around a focused field are derived
      // from it, 2 and 4 larger, so the field's own surface is the box that
      // carries a fill.)
      final surfaces = tester
          .widgetList<w.DecoratedBox>(
            find.descendant(
              of: field,
              matching: find.byWidgetPredicate(
                (widget) =>
                    widget is w.DecoratedBox &&
                    widget.decoration is w.BoxDecoration &&
                    (widget.decoration as w.BoxDecoration).color != null,
              ),
            ),
          )
          .map((box) => (box.decoration as w.BoxDecoration).borderRadius)
          .toList();
      expect(surfaces, [w.BorderRadius.circular(6)]);

      // Leave the editor so the pending focus and timers settle.
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('while renaming, the field fills the row and the trailing '
        'still sits at the row end', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: _nodes,
          onNodeSelect: (_) {},
          onNodeRename: (_, _) {},
          trailingBuilder: (context, node, {required expanded}) =>
              w.SizedBox(key: Key('trailing-${node.label}'), width: 10),
        ),
      );

      await doubleTap(tester, 'README.md');

      final row = tester.getRect(_row('README.md'));
      final trailing = tester.getRect(
        find.byKey(const Key('trailing-README.md')),
      );
      final field = tester.getRect(find.byType(EditableText));
      expect(trailing.right, row.right - 6);
      expect(trailing.left - field.right, greaterThanOrEqualTo(6));
      expect(tester.getSize(_row('README.md')).height, 28);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });

    testWidgets('the typed text is onSurface — not the dimmer colour the '
        'label rests on', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: _nodes,
          onNodeSelect: (_) {},
          onNodeRename: (_, _) {},
        ),
      );
      final restingLabel = tester
          .widget<Text>(find.text('README.md'))
          .style!
          .color;
      expect(
        restingLabel,
        _token(const CoreColor.token(CoreColors.onSurfaceVariant)),
      );

      await doubleTap(tester, 'README.md');

      final editable = tester.widget<EditableText>(find.byType(EditableText));
      expect(
        editable.style.color,
        _token(const CoreColor.token(CoreColors.onSurface)),
      );
      expect(editable.style.color, isNot(restingLabel));

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();
    });
  });

  group('Tree drop affordances', () {
    // The drop tint and the insertion line are primary — their own colours,
    // not the selected face. A selected face that moves (here: a loud
    // override) must not drag them along.
    const loudFace = CoreColor.token(CoreColors.error);
    final primary = _token(const CoreColor.token(CoreColors.primary));
    final primaryTint = _token(
      const CoreColor.token(
        CoreColors.primary,
        opacity: CoreOpacity.opacity10,
      ),
    );

    // Holds the drag over [to]; the caller releases it so the tree is torn
    // down with no pointer still down.
    Future<TestGesture> dragOver(
      WidgetTester tester, {
      required String from,
      required String to,
    }) async {
      final gesture = await tester.startGesture(
        tester.getCenter(find.text(from)),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveTo(tester.getCenter(find.text(to)));
      await tester.pump();

      return gesture;
    }

    Future<void> drop(WidgetTester tester, TestGesture gesture) async {
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('a valid folder target is tinted primary at 10 %, off the '
        'selected face', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'src',
              label: 'src',
              expanded: true,
              children: [CoreTreeNode(id: 'src/main', label: 'main.dart')],
            ),
            CoreTreeNode(
              id: 'lib',
              label: 'lib',
              expanded: true,
              children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
            ),
          ],
          selectedId: 'src/main',
          treeStyle: const CoreTreeStyle(nodeSelectedColor: loudFace),
          onNodeDrop: (_, _) {},
        ),
      );

      final gesture = await dragOver(tester, from: 'main.dart', to: 'lib');

      final tints = tester
          .widgetList<w.DecoratedBox>(
            find.ancestor(
              of: find.text('lib'),
              matching: find.byType(w.DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as w.BoxDecoration).color)
          .whereType<Color>()
          .toList();
      expect(tints, contains(primaryTint));
      expect(tints, isNot(contains(_token(loudFace))));

      await drop(tester, gesture);
    });

    testWidgets('a valid leaf target gets a solid primary top edge, off the '
        'selected face', (tester) async {
      await _pump(
        tester,
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'src',
              label: 'src',
              expanded: true,
              children: [
                CoreTreeNode(id: 'src/main', label: 'main.dart'),
                CoreTreeNode(id: 'src/b', label: 'b.dart'),
              ],
            ),
            CoreTreeNode(id: 'lib', label: 'lib', canHaveChildren: true),
          ],
          selectedId: 'src/main',
          treeStyle: const CoreTreeStyle(nodeSelectedColor: loudFace),
          onNodeDrop: (_, _) {},
        ),
      );

      final gesture = await dragOver(tester, from: 'main.dart', to: 'b.dart');

      final edges = tester
          .widgetList<w.DecoratedBox>(
            find.ancestor(
              of: find.text('b.dart'),
              matching: find.byType(w.DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as w.BoxDecoration).border)
          .whereType<w.Border>()
          .map((border) => border.top.color)
          .toList();
      expect(edges, contains(primary));
      expect(edges, isNot(contains(_token(loudFace))));

      await drop(tester, gesture);
    });

    testWidgets('their own overrides are honoured, apart from the selected '
        'face', (tester) async {
      const tint = CoreColor.token(
        CoreColors.success,
        opacity: CoreOpacity.opacity20,
      );
      const line = CoreColor.token(CoreColors.success);
      await _pump(
        tester,
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'src',
              label: 'src',
              expanded: true,
              children: [CoreTreeNode(id: 'src/main', label: 'main.dart')],
            ),
            CoreTreeNode(
              id: 'lib',
              label: 'lib',
              expanded: true,
              children: [CoreTreeNode(id: 'lib/a', label: 'a.dart')],
            ),
          ],
          selectedId: 'src/main',
          treeStyle: const CoreTreeStyle(
            nodeSelectedColor: loudFace,
            dropTargetColor: tint,
            dropIndicatorColor: line,
          ),
          onNodeDrop: (_, _) {},
        ),
      );

      final gesture = await dragOver(tester, from: 'main.dart', to: 'lib');

      final tints = tester
          .widgetList<w.DecoratedBox>(
            find.ancestor(
              of: find.text('lib'),
              matching: find.byType(w.DecoratedBox),
            ),
          )
          .map((box) => (box.decoration as w.BoxDecoration).color)
          .whereType<Color>()
          .toList();
      expect(tints, contains(_token(tint)));
      expect(tints, isNot(contains(primaryTint)));
      // The selected row still wears its own face.
      expect(_rowFill(tester, 'main.dart'), _token(loudFace));

      await drop(tester, gesture);
    });

    testWidgets('the insertion line is solid primary, off the selected face', (
      tester,
    ) async {
      await _pump(
        tester,
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'root',
              label: 'root',
              expanded: true,
              children: [
                CoreTreeNode(id: 'root/a', label: 'a'),
                CoreTreeNode(id: 'root/b', label: 'b'),
              ],
            ),
          ],
          virtualRowHeight: 32,
          virtualViewportHeight: 200,
          selectedId: 'root/a',
          treeStyle: const CoreTreeStyle(nodeSelectedColor: loudFace),
          canDragNode: (node) => node.id != 'root',
          onNodePlace: (_, _) {},
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('a')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.moveTo(
        tester.getTopLeft(find.byKey(const Key('tree-node.root/b'))) +
            const Offset(12, 3),
      );
      await tester.pump();

      final lines = tester
          .widgetList<w.ColoredBox>(find.byType(w.ColoredBox))
          .map((box) => box.color)
          .toList();
      expect(lines, contains(primary));
      expect(lines, isNot(contains(_token(loudFace))));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('Tree drag proxy', () {
    // The twin of the Web drag-ghost test: the proxy lifted off a row is that
    // row — the row's corner and its left inset (node padding plus depth
    // steps of the indent).
    testWidgets('takes the row corner and left inset at its depth', (
      tester,
    ) async {
      await _pump(
        tester,
        Tree(
          nodes: const [
            CoreTreeNode(
              id: 'root',
              label: 'root',
              expanded: true,
              children: [
                CoreTreeNode(id: 'root/a', label: 'a'),
                CoreTreeNode(id: 'root/b', label: 'b'),
              ],
            ),
          ],
          virtualRowHeight: 32,
          virtualViewportHeight: 200,
          canDragNode: (node) => node.id != 'root',
          onNodePlace: (_, _) {},
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.text('a')),
        kind: PointerDeviceKind.mouse,
      );
      await gesture.moveBy(const Offset(0, 48));
      await tester.pump();
      await gesture.moveTo(
        tester.getTopLeft(find.byKey(const Key('tree-node.root/b'))) +
            const Offset(12, 3),
      );
      await tester.pump();

      // The proxy is the one box in the tree that casts a shadow.
      final proxies = tester
          .widgetList<w.Container>(find.byType(w.Container))
          .where(
            (box) =>
                box.decoration is w.BoxDecoration &&
                (box.decoration! as w.BoxDecoration).boxShadow != null,
          )
          .toList();
      expect(proxies, hasLength(1));
      final proxy = proxies.single;
      expect(
        (proxy.decoration! as w.BoxDecoration).borderRadius,
        w.BorderRadius.circular(6),
      );
      // `a` sits one level in: 6 + 1 × 18.
      expect(proxy.padding!.resolve(w.TextDirection.ltr).left, 6 + 18);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
