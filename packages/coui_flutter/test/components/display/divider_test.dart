import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show SemanticsFlag, SemanticsNode;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

// Test constants.
const _kThickness = 2.0;
const _kIndent = 20.0;
const _kEndIndent = 10.0;
const _kPadding = 16.0;
const _kBoxExtent = 300.0;

Widget _buildApp(Widget child) {
  return material.MaterialApp(
    home: Theme(data: const ThemeData(), child: child),
  );
}

/// Walks the current semantics tree, collecting every non-empty `label`
/// and every node flagged [SemanticsFlag.isSlider].
({List<String> labels, bool hasSlider}) _collectSemantics(
  WidgetTester tester,
) {
  final labels = <String>[];
  var hasSlider = false;

  void visit(SemanticsNode node) {
    final data = node.getSemanticsData();
    if (data.label.isNotEmpty) labels.add(data.label);
    if (data.flagsCollection.isSlider) hasSlider = true;
    node.visitChildren((child) {
      visit(child);
      return true;
    });
  }

  final root = tester.binding.pipelineOwner.semanticsOwner?.rootSemanticsNode;
  if (root != null) visit(root);
  return (labels: labels, hasSlider: hasSlider);
}

/// The two line segments of a labelled divider, in widget order:
/// element `0` is the leading segment, element `1` the trailing one.
///
/// Widget order is deliberately *not* screen order — under `rtl` the
/// leading segment is painted on the right. That is the whole point of
/// naming the field logically: `leadingExtent` answers "did the leading
/// segment collapse?" identically in both directions, while the label's
/// on-screen position is what flips.
List<double> _segmentExtents(WidgetTester tester, {required bool horizontal}) {
  final sizes = find
      .descendant(of: find.byType(Divider), matching: find.byType(LimitedBox))
      .evaluate()
      .map((element) => element.size!)
      .toList();
  return sizes.map((size) => horizontal ? size.width : size.height).toList();
}

/// Free space between the divider's own edges and the label's, along the
/// main axis. Comparing the two gaps is scale- and padding-independent:
/// it asks only "which side is the label nearer to", which is exactly
/// what `childAlignment` claims to control.
({double before, double after}) _labelGaps(
  WidgetTester tester, {
  required bool horizontal,
}) {
  final dividerStart = tester.getTopLeft(find.byType(Divider));
  final dividerEnd = tester.getBottomRight(find.byType(Divider));
  final labelStart = tester.getTopLeft(find.text('OR'));
  final labelEnd = tester.getBottomRight(find.text('OR'));

  return horizontal
      ? (
          before: labelStart.dx - dividerStart.dx,
          after: dividerEnd.dx - labelEnd.dx,
        )
      : (
          before: labelStart.dy - dividerStart.dy,
          after: dividerEnd.dy - labelEnd.dy,
        );
}

Widget _alignedDivider(
  CoreDividerChildAlignment? alignment, {
  CoreDividerOrientation orientation = CoreDividerOrientation.horizontal,
}) {
  final divider = Divider(
    orientation: orientation,
    dividerStyle: alignment == null
        ? null
        : CoreDividerStyle(childAlignment: alignment),
    child: const material.Text('OR'),
  );
  return orientation == CoreDividerOrientation.horizontal
      ? SizedBox(width: _kBoxExtent, child: divider)
      : SizedBox(height: _kBoxExtent, child: divider);
}

// ── Logical indents ──────────────────────────────────────────────────
//
// `indent` is the inset at the side the line starts on and `endIndent`
// the inset at the side it ends on. These tests read the rect the line is
// painted into, not the resolved numbers: a resolver that hands out the
// right values to a widget that pads the wrong physical side looks fine
// from the style and wrong on screen.
const _kLogicalIndent = 24.0;
const _kLogicalEndIndent = 8.0;
const _kLogicalBox = 300.0;

const _kIndentedStyle = CoreDividerStyle(
  indent: _kLogicalIndent,
  endIndent: _kLogicalEndIndent,
);

/// The rect of the divider's own box, and the rects of the lines painted
/// inside it, in widget order — element `0` is the leading segment (the
/// only element when the divider has no label).
({Rect box, List<Rect> lines}) _paintedLines(WidgetTester tester) {
  final lines = find.descendant(
    of: find.byType(Divider),
    matching: find.byType(ColoredBox),
  );
  return (
    box: tester.getRect(find.byType(Divider)),
    lines: [
      for (var i = 0; i < lines.evaluate().length; i++)
        tester.getRect(lines.at(i)),
    ],
  );
}

Widget _indentedDivider({
  CoreDividerOrientation orientation = CoreDividerOrientation.horizontal,
  Widget? child,
  CoreDividerStyle style = _kIndentedStyle,
}) {
  final divider = Divider(
    orientation: orientation,
    dividerStyle: style,
    child: child,
  );
  return orientation == CoreDividerOrientation.horizontal
      ? SizedBox(width: _kLogicalBox, child: divider)
      : SizedBox(height: _kLogicalBox, child: divider);
}

void main() {
  group('Divider', () {
    testWidgets('renders the widget in the tree', (tester) async {
      await tester.pumpWidget(
        _buildApp(const SizedBox(width: 200, child: Divider())),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with center child label', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(width: 200, child: Divider(child: Text('OR'))),
        ),
      );

      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('renders with custom color via dividerStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            width: 200,
            child: Divider(
              dividerStyle: CoreDividerStyle(color: CoreColor(0xFFFF0000)),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with custom thickness via dividerStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            width: 200,
            child: Divider(
              dividerStyle: CoreDividerStyle(thickness: _kThickness),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with indent/endIndent via dividerStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            width: 200,
            child: Divider(
              dividerStyle: CoreDividerStyle(
                indent: _kIndent,
                endIndent: _kEndIndent,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with childPadding via dividerStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            width: 200,
            child: Divider(
              dividerStyle: CoreDividerStyle(
                childPadding: CoreEdgeInsets.all(_kPadding),
              ),
              child: Text('Padded'),
            ),
          ),
        ),
      );

      expect(find.text('Padded'), findsOneWidget);
    });

    testWidgets('respects provided key', (tester) async {
      const testKey = Key('test-divider');

      await tester.pumpWidget(
        _buildApp(
          const SizedBox(width: 200, child: Divider(key: testKey)),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    test('default orientation is horizontal', () {
      const divider = Divider();

      expect(divider.orientation, equals(CoreDividerOrientation.horizontal));
    });
  });

  group('Divider vertical orientation', () {
    testWidgets('renders the widget in the tree', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            height: 200,
            child: Row(
              children: [Divider(orientation: .vertical)],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('renders with custom color via dividerStyle', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const SizedBox(
            height: 200,
            child: Row(
              children: [
                Divider(
                  orientation: .vertical,
                  dividerStyle: CoreDividerStyle(color: CoreColor(0xFFFF0000)),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Divider), findsOneWidget);
    });

    test('orientation getter returns vertical', () {
      const divider = Divider(orientation: .vertical);

      expect(divider.orientation, equals(CoreDividerOrientation.vertical));
    });
  });

  group('Divider indent / endIndent are logical', () {
    // The pre-existing claim these tests keep: left-to-right output is the
    // physical layout every divider already had. The new claim is the
    // mirror image — in a right-to-left locale the indent moves to the
    // right edge, because it is the side the text starts on.
    testWidgets('ltr: indent pads the left edge, endIndent the right', (
      tester,
    ) async {
      await pumpTestApp(tester, _indentedDivider());

      final painted = _paintedLines(tester);
      expect(painted.lines, hasLength(1));
      expect(painted.lines.single.left - painted.box.left, _kLogicalIndent);
      expect(
        painted.box.right - painted.lines.single.right,
        _kLogicalEndIndent,
      );
    });

    testWidgets('rtl: indent pads the right edge, endIndent the left', (
      tester,
    ) async {
      await pumpTestApp(tester, _indentedDivider(), textDirection: .rtl);

      final painted = _paintedLines(tester);
      expect(painted.lines, hasLength(1));
      expect(
        painted.box.right - painted.lines.single.right,
        _kLogicalIndent,
        reason: 'the start edge of right-to-left text is the right edge',
      );
      expect(
        painted.lines.single.left - painted.box.left,
        _kLogicalEndIndent,
        reason: 'the end edge of right-to-left text is the left edge',
      );
    });

    testWidgets('the line keeps the same length in both directions', (
      tester,
    ) async {
      await pumpTestApp(tester, _indentedDivider());
      final ltr = _paintedLines(tester).lines.single.width;

      await pumpTestApp(tester, _indentedDivider(), textDirection: .rtl);

      expect(_paintedLines(tester).lines.single.width, ltr);
      expect(ltr, _kLogicalBox - _kLogicalIndent - _kLogicalEndIndent);
    });

    group('with a label', () {
      // `Row` mirrors in right-to-left, so the segment before the label
      // sits on the right there. It carries the start indent in both
      // directions; the segment after the label carries the end indent.
      testWidgets('ltr: the leading segment starts at the indent', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          _indentedDivider(child: const material.Text('OR')),
        );

        final painted = _paintedLines(tester);
        expect(painted.lines, hasLength(2));
        final leading = painted.lines[0];
        final trailing = painted.lines[1];
        expect(leading.left - painted.box.left, _kLogicalIndent);
        expect(painted.box.right - trailing.right, _kLogicalEndIndent);
      });

      testWidgets('rtl: the leading segment is on the right, indented there', (
        tester,
      ) async {
        await pumpTestApp(
          tester,
          _indentedDivider(child: const material.Text('OR')),
          textDirection: .rtl,
        );

        final painted = _paintedLines(tester);
        expect(painted.lines, hasLength(2));
        final leading = painted.lines[0];
        final trailing = painted.lines[1];
        expect(
          leading.center.dx,
          greaterThan(trailing.center.dx),
          reason: 'the segment before the label is on the right in rtl',
        );
        expect(painted.box.right - leading.right, _kLogicalIndent);
        expect(trailing.left - painted.box.left, _kLogicalEndIndent);
      });
    });

    group('vertical', () {
      // Top and bottom are not reading-direction sides, so the vertical
      // divider is the same in both directions.
      for (final direction in TextDirection.values) {
        testWidgets(
          '${direction.name}: indent is the top, endIndent the bottom',
          (
            tester,
          ) async {
            await pumpTestApp(
              tester,
              _indentedDivider(orientation: .vertical),
              textDirection: direction,
            );

            final painted = _paintedLines(tester);
            expect(painted.lines, hasLength(1));
            expect(painted.lines.single.top - painted.box.top, _kLogicalIndent);
            expect(
              painted.box.bottom - painted.lines.single.bottom,
              _kLogicalEndIndent,
            );
          },
        );
      }
    });
  });

  group('Divider under an unbounded main axis', () {
    // A divider asked for `infinity` along its main axis, which is an
    // assertion failure rather than "as long as possible" when the
    // parent bounds nothing there. Both shapes below threw before —
    // the childless one on `BoxConstraints forces an infinite …`, the
    // labelled one on `RenderFlex children have non-zero flex but
    // incoming … constraints are unbounded` — so a vertical divider in
    // a scrolling column took the whole subtree down with it.
    //
    // The expectation is collapse-to-zero, not fill: that is what the
    // Web twin already does (`h-full` against a parent with no
    // definite height resolves to `auto`), so this is also the axis on
    // which the two platforms agree.
    testWidgets('vertical, childless, does not throw and collapses', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.SingleChildScrollView(
            child: material.Row(
              children: const [
                material.Text('a'),
                Divider(orientation: .vertical),
                material.Text('b'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Divider)).height, equals(0));
    });

    testWidgets('vertical, with child, does not throw', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          material.SingleChildScrollView(
            child: material.Row(
              children: const [
                material.Text('a'),
                Divider(orientation: .vertical, child: material.Text('OR')),
                material.Text('b'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      // The label survives — only the two line segments collapse.
      expect(find.text('OR'), findsOneWidget);
    });

    testWidgets('horizontal, childless, does not throw and collapses', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.SingleChildScrollView(
            scrollDirection: .horizontal,
            child: material.Column(
              mainAxisSize: .min,
              children: const [
                material.Text('a'),
                Divider(),
                material.Text('b'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Divider)).width, equals(0));
    });

    // The collapse must not leak into the ordinary bounded case, and it
    // must not cost the divider its intrinsic sizing — `IntrinsicHeight`
    // is exactly where a `LayoutBuilder`-based fix would have thrown.
    testWidgets('still fills a bounded parent', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: material.SizedBox(
              width: 300,
              child: material.Column(mainAxisSize: .min, children: [Divider()]),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Divider)).width, equals(300));
    });

    testWidgets('vertical divider inside IntrinsicHeight still measures', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.IntrinsicHeight(
            child: material.Row(
              crossAxisAlignment: .stretch,
              children: [
                material.Text('a'),
                Divider(orientation: .vertical),
                material.Text('b'),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(Divider)).height, greaterThan(0));
    });
  });

  group('Divider childAlignment (#4200)', () {
    // Before this axis existed both segments carried an implicit
    // `flex: 1`, so the label was always centred. These tests measure
    // the segments themselves rather than trusting the style value:
    // wiring the field into the resolver and forgetting to hand it to
    // `Flexible` would leave every assertion below on the floor.
    testWidgets('unspecified keeps the label centred', (tester) async {
      await pumpTestApp(tester, _alignedDivider(null));

      final extents = _segmentExtents(tester, horizontal: true);
      expect(extents, hasLength(2));
      expect(extents[0], extents[1]);
    });

    testWidgets('explicit center matches the unspecified render', (
      tester,
    ) async {
      await pumpTestApp(tester, _alignedDivider(null));
      final unspecified = _segmentExtents(tester, horizontal: true);

      await pumpTestApp(tester, _alignedDivider(.center));

      expect(_segmentExtents(tester, horizontal: true), unspecified);
    });

    testWidgets('start collapses the leading segment', (tester) async {
      await pumpTestApp(tester, _alignedDivider(.start));

      final extents = _segmentExtents(tester, horizontal: true);
      expect(extents[0], 0.0);
      expect(extents[1], greaterThan(0));
    });

    testWidgets('end collapses the trailing segment', (tester) async {
      await pumpTestApp(tester, _alignedDivider(.end));

      final extents = _segmentExtents(tester, horizontal: true);
      expect(extents[0], greaterThan(0));
      expect(extents[1], 0.0);
    });

    testWidgets('start pulls the label toward the leading edge', (
      tester,
    ) async {
      await pumpTestApp(tester, _alignedDivider(.start));

      final gaps = _labelGaps(tester, horizontal: true);
      expect(gaps.before, lessThan(gaps.after));
    });

    testWidgets('end pushes the label toward the trailing edge', (
      tester,
    ) async {
      await pumpTestApp(tester, _alignedDivider(.end));

      final gaps = _labelGaps(tester, horizontal: true);
      expect(gaps.after, lessThan(gaps.before));
    });

    testWidgets('the divider keeps its full width at every alignment', (
      tester,
    ) async {
      for (final alignment in CoreDividerChildAlignment.values) {
        await pumpTestApp(tester, _alignedDivider(alignment));
        expect(
          tester.getSize(find.byType(Divider)).width,
          _kBoxExtent,
          reason: 'alignment $alignment resized the divider',
        );
      }
    });

    testWidgets('start follows the reading direction under rtl', (
      tester,
    ) async {
      await pumpTestApp(tester, _alignedDivider(.start));
      final ltrLabelX = tester.getTopLeft(find.text('OR')).dx;

      await pumpTestApp(
        tester,
        _alignedDivider(.start),
        textDirection: .rtl,
      );
      final rtlLabelX = tester.getTopLeft(find.text('OR')).dx;

      // The logical claim: `start` is the side text begins on, so
      // flipping the direction must move the label across the divider.
      // A physical `left`/`right` implementation would leave it put.
      expect(rtlLabelX, greaterThan(ltrLabelX));

      // …and the *leading* segment is still the collapsed one, which is
      // what makes the move a mirroring rather than a swap of intent.
      expect(_segmentExtents(tester, horizontal: true)[0], 0.0);
    });

    testWidgets('end follows the reading direction under rtl', (tester) async {
      await pumpTestApp(tester, _alignedDivider(.end));
      final ltrLabelX = tester.getTopLeft(find.text('OR')).dx;

      await pumpTestApp(tester, _alignedDivider(.end), textDirection: .rtl);

      expect(tester.getTopLeft(find.text('OR')).dx, lessThan(ltrLabelX));
      expect(_segmentExtents(tester, horizontal: true)[1], 0.0);
    });

    testWidgets('vertical start collapses the leading segment', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        _alignedDivider(.start, orientation: .vertical),
      );

      final extents = _segmentExtents(tester, horizontal: false);
      expect(extents[0], 0.0);
      expect(extents[1], greaterThan(0));

      final gaps = _labelGaps(tester, horizontal: false);
      expect(gaps.before, lessThan(gaps.after));
    });

    testWidgets('vertical end collapses the trailing segment', (tester) async {
      await pumpTestApp(tester, _alignedDivider(.end, orientation: .vertical));

      final extents = _segmentExtents(tester, horizontal: false);
      expect(extents[0], greaterThan(0));
      expect(extents[1], 0.0);

      final gaps = _labelGaps(tester, horizontal: false);
      expect(gaps.after, lessThan(gaps.before));
    });

    testWidgets('vertical unspecified stays centred', (tester) async {
      await pumpTestApp(tester, _alignedDivider(null, orientation: .vertical));

      final extents = _segmentExtents(tester, horizontal: false);
      expect(extents[0], extents[1]);
    });

    // A zero weight makes the segment inflexible, which is exactly the
    // case `RenderFlex` hands the parent's own (here unbounded)
    // main-axis constraint. Without `_DividerLine`'s `LimitedBox` that
    // is an infinite-extent assertion, so this pins the interaction
    // between the new axis and the unbounded-axis guard rather than
    // either one alone.
    testWidgets('start survives an unbounded main axis', (tester) async {
      await pumpTestApp(
        tester,
        material.SingleChildScrollView(
          scrollDirection: .horizontal,
          child: material.Column(
            mainAxisSize: .min,
            children: [
              const material.Text('a'),
              Divider(
                dividerStyle: const CoreDividerStyle(childAlignment: .start),
                child: const material.Text('OR'),
              ),
            ],
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('OR'), findsOneWidget);
    });
  });

  group('Divider semantic separator (#3497)', () {
    test('semantic defaults to false', () {
      const divider = Divider();

      expect(divider.semantic, isFalse);
    });

    testWidgets(
      'a decorative divider (default) exposes no accessible name and no '
      'slider flag — over-announce guard',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          _buildApp(const SizedBox(width: 200, child: Divider())),
        );

        final result = _collectSemantics(tester);
        expect(
          result.labels,
          isNot(
            contains(DefaultCoUILocalizations.instance.dividerSeparatorLabel),
          ),
        );
        expect(result.hasSlider, isFalse);

        handle.dispose();
      },
    );

    testWidgets(
      'Divider(semantic: true) exposes the separator accessible name and '
      'never the slider flag `CoreSemanticRole.separator` would add',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          _buildApp(const SizedBox(width: 200, child: Divider(semantic: true))),
        );

        final result = _collectSemantics(tester);
        expect(
          result.labels,
          contains(DefaultCoUILocalizations.instance.dividerSeparatorLabel),
        );
        // The over-announce failure mode this issue warns against is
        // calling `CoreSemanticRole.separator`'s generic Flutter mapping
        // (`slider: true` — correct for the focusable "window splitter"
        // variant, wrong here) instead of stating a plain accessible
        // name directly. If a future change wires that mapping in, this
        // line catches it.
        expect(result.hasSlider, isFalse);

        handle.dispose();
      },
    );

    testWidgets(
      'a Menu divider item is semantic — reverting `semantic: true` in '
      "Menu's `_buildDivider` turns this red",
      (tester) async {
        final handle = tester.ensureSemantics();

        await pumpTestApp(
          tester,
          const Menu(
            items: [
              CoreMenuItem<Widget>.action('First'),
              CoreMenuItem<Widget>.divider(),
              CoreMenuItem<Widget>.action('Second'),
            ],
          ),
        );

        final result = _collectSemantics(tester);
        expect(
          result.labels,
          contains(DefaultCoUILocalizations.instance.dividerSeparatorLabel),
        );

        handle.dispose();
      },
    );
  });
}
