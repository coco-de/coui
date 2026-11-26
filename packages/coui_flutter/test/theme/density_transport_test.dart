// The density axis on Flutter — read back from what components render,
// not from the theme that carries it.
//
// The density reaches a component only where a Core value becomes a
// Flutter one: an inset conversion, a spacing double, a control row's
// height, a corner. A theme can carry the density and every one of those
// can still ignore it, which is what these tests rule out — each pumps a
// real component under `CoUIApp(density: …)` and measures it.
//
// The expectations are written out as numbers on purpose, the way
// `coui_core/test/density_test.dart` writes its rungs: a second source, so
// a change to a ladder fails here instead of moving the implementation and
// the expectation together.
import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/widgets.dart' as w;
import 'package:flutter_test/flutter_test.dart';

/// Every scaling axis at 1, so a measured pixel is the density's rung and
/// nothing else.
final _theme = ThemeData.fromCore(
  CoreThemePresets.previewLight.copyWith(
    textScaling: 1,
    sizeScaling: 1,
    radiusScaling: 1,
  ),
);

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  CoreDensity? density,
}) async {
  await tester.pumpWidget(
    density == null
        ? CoUIApp(
            theme: _theme,
            home: w.Center(child: child),
          )
        : CoUIApp(
            theme: _theme,
            density: density,
            home: w.Center(child: child),
          ),
  );
  await tester.pumpAndSettle();
}

const w.ValueKey<String> _a = w.ValueKey('a');
const w.ValueKey<String> _b = w.ValueKey('b');
const w.ValueKey<String> _c = w.ValueKey('c');

/// The vertical space between the bottom of [_a] and the top of [_b].
double _gapBetween(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_b)).dy -
    tester.getBottomLeft(find.byKey(_a)).dy;

/// Where [child] sits inside the nearest [T] above it.
w.Offset _insetOf<T>(WidgetTester tester, w.Key child) =>
    tester.getTopLeft(find.byKey(child)) -
    tester.getTopLeft(
      find.ancestor(of: find.byKey(child), matching: find.byType(T)).first,
    );

void main() {
  group('a control row moves one rung of the ladder', () {
    for (final (density, height, inset) in [
      (CoreDensity.compact, 32.0, 12.0),
      (CoreDensity.standard, 40.0, 16.0),
      (CoreDensity.spacious, 48.0, 20.0),
    ]) {
      testWidgets('an md Button under ${density.name} is $height tall', (
        tester,
      ) async {
        await _pump(
          tester,
          Button(
            onPressed: () {},
            child: const Text('Label', key: _c),
          ),
          density: density,
        );

        expect(tester.getSize(find.byType(Button)).height, height);
        // The row's padding moves with it: 16 → 12 / 20 on the 4px grid.
        expect(_insetOf<Button>(tester, _c).dx, inset);
      });
    }

    testWidgets('every Button size takes its rung, with compact stopping at '
        'sm and spacious at xl2', (tester) async {
      Future<List<double>> heights(CoreDensity density) async {
        final out = <double>[];
        for (final size in CoreComponentSize.values) {
          await _pump(
            tester,
            Button(size: size, onPressed: () {}, child: const Text('L')),
            density: density,
          );
          out.add(tester.getSize(find.byType(Button)).height);
        }
        return out;
      }

      expect(CoreComponentSize.values, hasLength(6));
      expect(await heights(.compact), [24.0, 32.0, 32.0, 40.0, 48.0, 56.0]);
      expect(await heights(.standard), [24.0, 32.0, 40.0, 48.0, 56.0, 64.0]);
      expect(await heights(.spacious), [32.0, 40.0, 48.0, 56.0, 64.0, 64.0]);
    });

    for (final (density, height) in [
      (CoreDensity.compact, 32.0),
      (CoreDensity.standard, 40.0),
      (CoreDensity.spacious, 48.0),
    ]) {
      testWidgets('an md TextField under ${density.name} is $height tall', (
        tester,
      ) async {
        await _pump(
          tester,
          w.SizedBox(
            width: 240,
            child: TextField(placeholder: const Text('Search')),
          ),
          density: density,
        );

        expect(tester.getSize(find.byType(TextField)).height, height);
      });
    }

    testWidgets('a caller’s own Button height is not a row and stays', (
      tester,
    ) async {
      // Composites size affordance buttons with an explicit height — a
      // chip's 24px remove button. The ladder would take 24 to 32 under
      // spacious; it is not a row of the ladder, so it must not.
      for (final density in CoreDensity.values) {
        await _pump(
          tester,
          Button(
            buttonStyle: const CoreButtonStyle(
              height: CoreSize.size24,
              width: CoreSize.size24,
              padding: CoreEdgeInsets.zero,
            ),
            onPressed: () {},
            child: const w.SizedBox(width: 12, height: 12),
          ),
          density: density,
        );

        expect(
          tester.getSize(find.byType(Button)),
          const w.Size(24, 24),
          reason: density.name,
        );
      }
    });
  });

  group('spacing moves one rung on the 4px grid', () {
    for (final (density, gap) in [
      (CoreDensity.compact, 12.0),
      (CoreDensity.standard, 16.0),
      (CoreDensity.spacious, 20.0),
    ]) {
      testWidgets('a 16px Gap under ${density.name} is $gap', (tester) async {
        await _pump(
          tester,
          const w.Column(
            mainAxisSize: .min,
            children: [
              w.SizedBox(key: _a, width: 10, height: 10),
              Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
              w.SizedBox(key: _b, width: 10, height: 10),
            ],
          ),
          density: density,
        );

        expect(_gapBetween(tester), gap);
      });
    }

    testWidgets('a 4px Gap never moves — the gap beside an icon', (
      tester,
    ) async {
      for (final density in CoreDensity.values) {
        await _pump(
          tester,
          const w.Column(
            mainAxisSize: .min,
            children: [
              w.SizedBox(key: _a, width: 10, height: 10),
              Gap(gapStyle: CoreGapStyle(size: CoreSpace.space4)),
              w.SizedBox(key: _b, width: 10, height: 10),
            ],
          ),
          density: density,
        );

        expect(_gapBetween(tester), 4, reason: density.name);
      }
    });

    for (final (density, horizontal, vertical) in [
      (CoreDensity.compact, 20.0, 16.0),
      (CoreDensity.standard, 24.0, 20.0),
      (CoreDensity.spacious, 28.0, 24.0),
    ]) {
      testWidgets(
        'a Card’s padding under ${density.name} is $horizontal across and '
        '$vertical down',
        (tester) async {
          await _pump(
            tester,
            const Card(child: w.SizedBox(key: _c, width: 40, height: 40)),
            density: density,
          );

          // The padding alone: the default (filled) variant draws no border
          // inside it.
          expect(_insetOf<Card>(tester, _c), w.Offset(horizontal, vertical));
        },
      );
    }

    for (final (density, spacing) in [
      (CoreDensity.compact, 4.0),
      (CoreDensity.standard, 8.0),
      (CoreDensity.spacious, 12.0),
    ]) {
      testWidgets('a ChipGroup’s item spacing under ${density.name} is '
          '$spacing', (tester) async {
        // A spacing double that feeds `Wrap.spacing` — the class of value
        // with no conversion to carry the density.
        await _pump(
          tester,
          ChipGroup<String>(
            items: const ['A', 'B'],
            chipBuilder:
                (item, {required selected, required enabled, required onTap}) =>
                    Chip(label: item, selected: selected, onTap: onTap),
          ),
          density: density,
        );

        final chips = find.byType(Chip);
        expect(
          tester.getTopLeft(chips.at(1)).dx -
              tester.getTopRight(chips.at(0)).dx,
          spacing,
        );
      });
    }

    testWidgets('a Frame’s gap, padding and margin each move a rung', (
      tester,
    ) async {
      // Frame draws a caller's values as stated (no size factor), so the
      // density is the only step between what is written and what draws.
      Future<void> pumpFrame(CoreDensity density) => _pump(
        tester,
        const Frame(
          key: _c,
          direction: .row,
          gap: CoreSpace.space16,
          padding: CoreEdgeInsets.all(CoreSpace.space16),
          margin: CoreEdgeInsets.all(CoreSpace.space16),
          children: [
            w.SizedBox(key: _a, width: 10, height: 10),
            w.SizedBox(key: _b, width: 10, height: 10),
          ],
        ),
        density: density,
      );

      for (final (density, step) in [
        (CoreDensity.compact, 12.0),
        (CoreDensity.standard, 16.0),
        (CoreDensity.spacious, 20.0),
      ]) {
        await pumpFrame(density);

        final gap =
            tester.getTopLeft(find.byKey(_b)).dx -
            tester.getTopRight(find.byKey(_a)).dx;
        // Margin + padding sit between the frame's edge and its first child.
        final inset =
            tester.getTopLeft(find.byKey(_a)) -
            tester.getTopLeft(find.byKey(_c));
        expect(gap, step, reason: '${density.name} gap');
        expect(inset, w.Offset(step * 2, step * 2), reason: density.name);
      }
    });

    testWidgets('a MultiAnswerCard keeps its content still across selection '
        'under every density', (tester) async {
      // The card makes up the thicker selected border with a smaller
      // inset. Folding that difference into the padding a density then
      // moves would erase it — one rung down, 17 lands on 16 and 16 on 12.
      Future<w.Offset> contentAt(
        CoreDensity density, {
        required bool on,
      }) async {
        await _pump(
          tester,
          w.SizedBox(
            width: 200,
            child: MultiAnswerCard<int>(
              value: 1,
              selected: on,
              onChanged: (_) {},
              // The default widths are equal; a thicker selected border is
              // what makes the card compensate with an inset.
              multiAnswerCardStyle: const CoreMultiAnswerCardStyle(
                selectedBorderWidth: CoreStrokeWidth.stroke2,
              ),
              child: const w.SizedBox(key: _c, width: 40, height: 20),
            ),
          ),
          density: density,
        );
        return _insetOf<MultiAnswerCard<int>>(tester, _c);
      }

      for (final (density, padding) in [
        (CoreDensity.compact, 12.0),
        (CoreDensity.standard, 16.0),
        (CoreDensity.spacious, 20.0),
      ]) {
        final idle = await contentAt(density, on: false);
        final selected = await contentAt(density, on: true);
        // Padding plus the thicker (2px) border, in both states.
        expect(idle, w.Offset(padding + 2, padding + 2), reason: density.name);
        expect(selected, idle, reason: '${density.name} content moved');
      }
    });
  });

  group('a part of a component is not spacing', () {
    // What a component draws as one of its own parts — the place a glyph
    // holds, the band a moving part sits in — keeps its length under every
    // density. Each test reads that part against what it has to stay in
    // line with: the two come apart the moment one takes the density and
    // the other does not.

    testWidgets('a Tree leaf row stays in line with its parent siblings '
        'while the gaps beside its chevron slot move', (tester) async {
      // A parent row draws a 12px chevron and a leaf row keeps that place
      // empty. The gaps on either side of it are spacing.
      Finder glyph(IconName name) => find.byWidgetPredicate(
        (widget) => widget is Icon && widget.icon == name,
      );

      for (final (density, labelGap) in [
        (CoreDensity.compact, 4.0),
        (CoreDensity.standard, 6.0),
        (CoreDensity.spacious, 8.0),
      ]) {
        await _pump(
          tester,
          const w.SizedBox(
            width: 300,
            height: 200,
            child: Tree(
              nodes: [
                CoreTreeNode(
                  label: 'src',
                  children: [CoreTreeNode(label: 'main.dart')],
                ),
                CoreTreeNode(label: 'README.md'),
              ],
            ),
          ),
          density: density,
        );

        expect(
          tester.getTopLeft(glyph(LucideIcons.file)).dx,
          tester.getTopLeft(glyph(LucideIcons.folderClosed)).dx,
          reason: '${density.name}: the leaf icon left its column',
        );
        expect(
          tester.getTopLeft(find.text('README.md')).dx,
          tester.getTopLeft(find.text('src')).dx,
          reason: '${density.name}: the leaf label left its column',
        );
        expect(
          tester.getTopLeft(find.text('README.md')).dx -
              tester.getTopRight(glyph(LucideIcons.file)).dx,
          labelGap,
          reason: '${density.name}: the icon–label gap is spacing',
        );
      }
    });

    testWidgets('a Toggle thumb stays in its track — at rest and under its '
        'lens — under every density', (tester) async {
      // A 6px band, above the 4px floor the density leaves alone. The
      // thumb's travel and the lens's place are lengths derived from the
      // band, so a band that took the density on its own would move the
      // thumb off the place they were computed for.
      const band = CoreSpace.space6;
      final track = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedContainer &&
            widget.role == CoreSurfaceRole.content,
      );
      final lens = find.byWidgetPredicate(
        (widget) =>
            widget is OutlinedContainer &&
            widget.role == CoreSurfaceRole.functional,
      );
      final thumb = find.descendant(
        of: find.byType(Toggle),
        matching: find.byType(w.AspectRatio),
      );

      for (final density in CoreDensity.values) {
        var on = false;
        await _pump(
          tester,
          w.StatefulBuilder(
            builder: (context, setState) => Toggle(
              value: on,
              onChanged: (value) => setState(() => on = value),
              toggleStyle: const CoreToggleStyle(
                padding: CoreEdgeInsets.all(band),
              ),
            ),
          ),
          density: density,
        );

        final box = tester.getRect(track);
        final off = tester.getRect(thumb);
        expect(off.left - box.left, band, reason: '${density.name} off');
        expect(off.top - box.top, band, reason: '${density.name} top');
        expect(box.bottom - off.bottom, band, reason: '${density.name} bottom');

        // Halfway through a flip the lens rides the thumb: its origin is
        // the band less the lens's outset.
        await tester.tap(find.byType(Toggle));
        await tester.pump();
        await tester.pump(CoreToggleStyle.defaultThumbTransitionDuration ~/ 2);
        expect(
          tester.getRect(lens).left + CoreToggleStyle.defaultLensOutset.left,
          moreOrLessEquals(tester.getRect(thumb).left),
          reason: '${density.name}: the lens left the thumb',
        );

        await tester.pumpAndSettle();
        expect(
          box.right - tester.getRect(thumb).right,
          band,
          reason: '${density.name} on',
        );
      }
    });
  });

  group('a field with no Size axis sits on the md row', () {
    // ChipInput's frame and ItemPicker's search are fields
    // that sit beside an md TextField. They state the md rung of the control
    // ladder, so a density moves them with that field.
    Future<double> heightOf(
      WidgetTester tester,
      Widget child,
      Finder measured,
      CoreDensity density,
    ) async {
      await _pump(
        tester,
        w.SizedBox(width: 300, child: child),
        density: density,
      );
      return tester.getSize(measured).height;
    }

    final pickerSearch = find.descendant(
      of: find.byType(ItemPicker),
      matching: find.byType(TextField),
    );

    for (final (density, row) in [
      (CoreDensity.compact, 32.0),
      (CoreDensity.standard, 40.0),
      (CoreDensity.spacious, 48.0),
    ]) {
      testWidgets('under ${density.name} each is the text field’s $row', (
        tester,
      ) async {
        expect(
          await heightOf(tester, TextField(), find.byType(TextField), density),
          row,
          reason: 'TextField',
        );
        // Under compact the frame runs 1 past its row: its 4 + 4 of padding
        // and the entry's own transparent border hold the value line at
        // the role's 150% (21), one step taller than the 140% line the
        // field used to lay over it. The floor still holds at standard and
        // spacious. Whether compact keeps the 1 or the frame trims it is
        // a design decision (#5762) — this pins today's value so a change
        // in either direction is seen.
        expect(
          await heightOf(
            tester,
            const ChipInput(),
            find.byType(ChipInput),
            density,
          ),
          density == CoreDensity.compact ? row + 1 : row,
          reason: 'ChipInput',
        );
        expect(
          await heightOf(
            tester,
            const ItemPicker(items: ['Apple']),
            pickerSearch,
            density,
          ),
          row,
          reason: 'ItemPicker search',
        );
      });
    }

    // The phone input sits on the lg row — the text field's default row
    // since #5831 — so a density moves it one rung of the ladder from there.
    for (final (density, row) in [
      (CoreDensity.compact, 40.0),
      (CoreDensity.standard, 48.0),
      (CoreDensity.spacious, 56.0),
    ]) {
      testWidgets('PhoneInput under ${density.name} is the lg row $row', (
        tester,
      ) async {
        expect(
          await heightOf(
            tester,
            const PhoneInput(),
            find.byType(PhoneInput),
            density,
          ),
          row,
        );
      });
    }

    testWidgets('a caller’s own height or minimum is a statement and stays', (
      tester,
    ) async {
      for (final density in CoreDensity.values) {
        expect(
          await heightOf(
            tester,
            const ChipInput(
              chipInputStyle: CoreChipInputStyle(minHeight: CoreSize.size56),
            ),
            find.byType(ChipInput),
            density,
          ),
          56,
          reason: 'ChipInput ${density.name}',
        );
        expect(
          await heightOf(
            tester,
            const PhoneInput(
              phoneInputStyle: CorePhoneInputStyle(height: CoreSize.size44),
            ),
            find.byType(PhoneInput),
            density,
          ),
          44,
          reason: 'PhoneInput ${density.name}',
        );
        expect(
          await heightOf(
            tester,
            const ItemPicker(
              items: ['Apple'],
              itemPickerStyle: CoreItemPickerStyle(
                searchHeight: CoreSize.size44,
              ),
            ),
            pickerSearch,
            density,
          ),
          44,
          reason: 'ItemPicker search ${density.name}',
        );
      }
    });
  });

  testWidgets('an ItemPicker search whose field slot states a height holds '
      'the authored row — as on Web', (tester) async {
    // The row beats a height the slot states. Web can only beat it with a
    // forwarded length, which no density reaches, so both platforms hold the
    // authored rung here rather than part.
    for (final density in CoreDensity.values) {
      await _pump(
        tester,
        const w.SizedBox(
          width: 300,
          child: ItemPicker(
            items: ['Apple'],
            itemPickerStyle: CoreItemPickerStyle(
              searchFieldStyle: CoreTextFieldStyle(height: CoreSize.size56),
            ),
          ),
        ),
        density: density,
      );

      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(ItemPicker),
                matching: find.byType(TextField),
              ),
            )
            .height,
        CoreItemPickerStyle.defaultSearchHeight,
        reason: density.name,
      );
    }
  });

  group('a row on its own ladder stays', () {
    testWidgets('a Filter bar is 40 under every density', (tester) async {
      // The segment is the composed ToggleGroup's own 32 row inside a
      // 4 + 32 + 4 track, tied to the 32 reset button — not a control row.
      // The inset 4 is at the ladder's floor, so no density moves it.
      for (final density in CoreDensity.values) {
        await _pump(
          tester,
          w.SizedBox(
            width: 300,
            child: Filter<int>(
              groupValue: 0,
              items: const [
                CoreFilterItem(value: 0, label: 'All'),
                CoreFilterItem(value: 1, label: 'Open'),
              ],
              onValueChanged: (_) {},
            ),
          ),
          density: density,
        );

        expect(
          tester.getSize(find.byType(Filter<int>)).height,
          40,
          reason: density.name,
        );
      }
    });

    testWidgets('a TabPane strip keeps its 44 bar under every density', (
      tester,
    ) async {
      // Navigation on its own ladder: the bar holds tabs that keep theirs.
      for (final density in CoreDensity.values) {
        await _pump(
          tester,
          w.SizedBox(
            width: 400,
            height: 200,
            child: TabPane(
              selectedIndex: 0,
              onChanged: (_) {},
              tabs: const [
                CoreTabItem<Widget>(label: 'Overview'),
                CoreTabItem<Widget>(label: 'Details'),
              ],
            ),
          ),
          density: density,
        );

        expect(
          tester
              .getSize(
                find
                    .ancestor(
                      of: find.text('Details'),
                      matching: find.byType(Clickable),
                    )
                    .first,
              )
              .height,
          CoreTabPaneStyle.boxed.barHeight,
          reason: density.name,
        );
      }
    });
  });

  group('a gap the resolver did not see now moves with it', () {
    testWidgets('a Carousel’s slides keep their stops while the gap moves', (
      tester,
    ) async {
      // The sliding layout places every slide and advances the line from the
      // one gap the resolver hands it, so moving the gap cannot move a slide
      // off its stop: the active slide lands where the first one sat.
      Finder slide(int i) => find.byKey(w.ValueKey('slide$i')).hitTestable();

      for (final transition in const <CoreCarouselTransition>[
        CarouselTransition.sliding(gap: CoreSpace.space16),
        CoreCarouselTransition.sliding(gap: CoreSpace.space16),
      ]) {
        for (final (density, gap) in [
          (CoreDensity.compact, 12.0),
          (CoreDensity.standard, 16.0),
          (CoreDensity.spacious, 20.0),
        ]) {
          final controller = CarouselController();
          await _pump(
            tester,
            w.SizedBox(
              width: 300,
              height: 80,
              child: Carousel(
                autoPlay: false,
                controller: controller,
                draggable: false,
                items: [
                  // Hit-testable, so the invisible sizing copy of the active
                  // slide (under `IgnorePointer`) is not the one measured.
                  for (var i = 0; i < 4; i++)
                    w.ColoredBox(
                      key: w.ValueKey('slide$i'),
                      color: const w.Color(0xFF000000),
                    ),
                ],
                showIndicators: false,
                showNavigation: false,
                sizeConstraint: const CarouselFixedConstraint(100),
                transition: transition,
                wrap: false,
              ),
            ),
            density: density,
          );

          final origin = tester.getTopLeft(find.byType(Carousel)).dx;
          final stop = tester.getTopLeft(slide(0)).dx - origin;
          expect(
            tester.getTopLeft(slide(1)).dx - tester.getTopRight(slide(0)).dx,
            gap,
            reason: '${density.name}: the gap between slides',
          );

          controller.jumpTo(2);
          await tester.pump();

          expect(
            tester.getTopLeft(slide(2)).dx - origin,
            moreOrLessEquals(stop),
            reason: '${density.name}: slide 2 left the stop',
          );
          expect(
            tester.getTopLeft(slide(2)).dx - tester.getTopRight(slide(1)).dx,
            moreOrLessEquals(gap),
            reason: '${density.name}: the gap after moving',
          );
        }
      }
    });

    testWidgets('a ToastLayer moves the gap between toasts and its padding', (
      tester,
    ) async {
      // Two toasts fanned out: the room between them is the layer's spacing
      // plus lengths that do not move, so the density shows as the change in
      // that room — one rung (4) either way — and the front toast's inset
      // from the screen edge is the layer's padding.
      Future<({double between, double inset})> measure(
        CoreDensity density, {
        double spacing = CoreToastStyle.defaultStackSpacing,
        w.EdgeInsetsGeometry? padding,
      }) async {
        late BuildContext context;
        await _pump(
          tester,
          ToastLayer(
            expandMode: .alwaysExpanded,
            padding: padding,
            spacing: spacing,
            child: w.Builder(
              builder: (builderContext) {
                context = builderContext;
                return const w.SizedBox.expand();
              },
            ),
          ),
          density: density,
        );
        for (final key in const [_a, _b]) {
          showToast(
            context: context,
            builder: (_, _) => w.SizedBox(key: key, height: 40),
          );
          await tester.pumpAndSettle();
        }
        // The innermost layer — the app hosts one of its own above it.
        final screen = tester.getRect(find.byType(ToastLayer).last);
        final front = tester.getRect(find.byKey(_b));
        final back = tester.getRect(find.byKey(_a));
        final result = (
          between: front.top - back.bottom,
          inset: screen.right - front.right,
        );
        // Let both toasts time out and close before the next pump.
        await tester.pump(const Duration(seconds: 30));
        await tester.pumpAndSettle();
        return result;
      }

      final standard = await measure(.standard);
      final compact = await measure(.compact);
      final spacious = await measure(.spacious);
      expect(standard.between - compact.between, 4, reason: 'compact gap');
      expect(spacious.between - standard.between, 4, reason: 'spacious gap');
      expect(
        [compact.inset, standard.inset, spacious.inset],
        [20.0, 24.0, 28.0],
        reason: 'layer padding',
      );

      // A stated spacing is a gap too: 16 → 12 / 20.
      final stated = await measure(.standard, spacing: CoreSpace.space16);
      final statedCompact = await measure(
        .compact,
        spacing: CoreSpace.space16,
      );
      expect(stated.between - standard.between, 8, reason: 'stated 16');
      expect(stated.between - statedCompact.between, 4, reason: 'stated 12');

      // A stated padding is a framework inset the kit never converts: it
      // reaches the screen as given under every density.
      for (final density in CoreDensity.values) {
        final inset = await measure(
          density,
          padding: const w.EdgeInsets.all(CoreSpace.space16),
        );
        expect(inset.inset, 16.0, reason: '${density.name}: stated padding');
      }
    });

    for (final (density, room) in [
      (CoreDensity.compact, 12.0),
      (CoreDensity.standard, 16.0),
      (CoreDensity.spacious, 20.0),
    ]) {
      testWidgets('a dialog route leaves $room around the panel under '
          '${density.name}', (tester) async {
        late BuildContext context;
        await _pump(
          tester,
          w.Builder(
            builder: (builderContext) {
              context = builderContext;
              return const w.SizedBox.expand();
            },
          ),
          density: density,
        );

        unawaited(
          showDialog<void>(
            context: context,
            builder: (_) => const w.SizedBox.expand(key: _c),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.byKey(_c)), w.Offset(room, room));

        // A stated route padding is spacing too: 24 → 20 / 24 / 28.
        Navigator.of(context).pop();
        await tester.pumpAndSettle();
        unawaited(
          showDialog<void>(
            context: context,
            dialogStyle: const CoreDialogStyle(
              routePadding: CoreSpace.space24,
            ),
            builder: (_) => const w.SizedBox.expand(key: _c),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.getTopLeft(find.byKey(_c)).dx,
          density.space(CoreSpace.space24),
        );
      });
    }

    testWidgets('a Dialog opened by its flag hands its own route padding to '
        'the route', (tester) async {
      // On an 800-wide screen a 200 room on either side leaves the panel
      // 400 — narrower than its own maximum, so the cap is the route's.
      await _pump(
        tester,
        const Dialog(
          dialogStyle: CoreDialogStyle(routePadding: CoreSpace.space200),
          content: Text('Body'),
        ),
        density: CoreDensity.standard,
      );

      // The panel box (its own maximum is 640) sits inside the route.
      final panel = find
          .ancestor(of: find.text('Body'), matching: find.byType(InsetShadow))
          .first;
      expect(tester.getSize(panel).width, lessThanOrEqualTo(400));
      expect(tester.getTopLeft(panel).dx, greaterThanOrEqualTo(200));
    });
  });

  group('standard is the values as authored', () {
    testWidgets('stating standard renders what stating nothing does', (
      tester,
    ) async {
      Future<List<Object>> measure(CoreDensity? density) async {
        await _pump(
          tester,
          w.Column(
            mainAxisSize: .min,
            children: [
              Button(onPressed: () {}, child: const Text('L')),
              const Card(child: w.SizedBox(key: _c, width: 40, height: 40)),
              const w.SizedBox(key: _a, width: 10, height: 10),
              const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space24)),
              const w.SizedBox(key: _b, width: 10, height: 10),
            ],
          ),
          density: density,
        );
        return [
          tester.getSize(find.byType(Button)),
          _insetOf<Card>(tester, _c),
          _gapBetween(tester),
        ];
      }

      expect(await measure(.standard), await measure(null));
    });

    testWidgets('an app that states no density keeps the identity geometry', (
      tester,
    ) async {
      late ThemeData seen;
      await _pump(
        tester,
        w.Builder(
          builder: (context) {
            seen = Theme.of(context);
            return const w.SizedBox();
          },
        ),
      );

      expect(seen.geometry.density, CoreDensity.standard);
      expect(seen.geometry.isIdentity, isTrue);
    });
  });

  group('a row off the control ladder stays put', () {
    // The md MenuItem row's height floor is 36 — between the sm and md
    // rungs, so no density moves the floor. Its insets still move, so a
    // spacious row whose content outgrows 36 grows with them.
    for (final density in CoreDensity.values) {
      testWidgets('an md MenuItem floor under ${density.name} is 36', (
        tester,
      ) async {
        await _pump(
          tester,
          w.SizedBox(
            width: 240,
            child: MenuItem(label: const Text('Row'), onPressed: () {}),
          ),
          density: density,
        );

        final floor = tester
            .widgetList<w.AnimatedContainer>(
              find.descendant(
                of: find.byType(MenuItem),
                matching: find.byType(w.AnimatedContainer),
              ),
            )
            .firstWhere((container) => container.constraints != null)
            .constraints!
            .minHeight;
        expect(floor, 36);
        if (density != CoreDensity.spacious) {
          expect(tester.getSize(find.byType(MenuItem)).height, 36);
        }
      });
    }

    testWidgets('the sm and lg MenuItem rows still take their rung', (
      tester,
    ) async {
      Future<double> height(CoreMenuItemSize size, CoreDensity density) async {
        await _pump(
          tester,
          w.SizedBox(
            width: 240,
            child: MenuItem(
              label: const Text('Row'),
              size: size,
              onPressed: () {},
            ),
          ),
          density: density,
        );

        return tester.getSize(find.byType(MenuItem)).height;
      }

      expect(await height(.sm, .compact), 32);
      expect(await height(.sm, .spacious), 40);
      expect(await height(.lg, .compact), 40);
      expect(await height(.lg, .spacious), 56);
    });
  });

  testWidgets('switching the density rebuilds what is on screen', (
    tester,
  ) async {
    // The axis is switched the way the surface style is: by rebuilding the
    // app with a different value.
    Widget app(CoreDensity density) => CoUIApp(
      theme: _theme,
      density: density,
      home: w.Center(
        child: Button(onPressed: () {}, child: const Text('L')),
      ),
    );

    await tester.pumpWidget(app(.standard));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Button)).height, 40);

    await tester.pumpWidget(app(.compact));
    await tester.pumpAndSettle();
    expect(tester.getSize(find.byType(Button)).height, 32);
  });
}
