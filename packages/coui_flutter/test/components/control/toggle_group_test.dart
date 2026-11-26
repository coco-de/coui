import 'dart:ui' show CheckedState;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kItems = <CoreToggleGroupItem<String, material.Widget>>[
  CoreToggleGroupItem(value: 'am', label: 'AM'),
  CoreToggleGroupItem(value: 'pm', label: 'PM'),
];

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: Theme(
    data: const ThemeData(),
    child: material.Scaffold(body: material.Center(child: child)),
  ),
);

/// Each label is also painted by an invisible twin that reserves the
/// chosen weight's width, so the visible one is the last match.
Finder _visibleLabel(String label) => find.text(label).last;

/// The segment box that paints the item's fill, found from its label.
Finder _segmentOf(String label) => find
    .ancestor(
      of: _visibleLabel(label),
      matching: find.byType(material.AnimatedContainer),
    )
    .first;

material.BoxDecoration _decorationOf(WidgetTester tester, String label) {
  final box = tester.widget<material.AnimatedContainer>(_segmentOf(label));
  return box.decoration! as material.BoxDecoration;
}

/// The track: the outermost `AnimatedContainer` above the segments (the
/// composed `OutlinedContainer` paints its fill there).
Finder _track() => find
    .ancestor(
      of: _visibleLabel('AM'),
      matching: find.byType(material.AnimatedContainer),
    )
    .last;

material.BoxDecoration _trackDecoration(WidgetTester tester) =>
    tester.widget<material.AnimatedContainer>(_track()).decoration!
        as material.BoxDecoration;

Future<void> _pump(
  WidgetTester tester, {
  String? value = 'am',
  ValueChanged<String>? onChanged,
  bool? enabled,
  CoreToggleGroupStyle? style,
}) async {
  await tester.pumpWidget(
    _buildApp(
      ToggleGroup<String>(
        items: _kItems,
        value: value,
        onChanged: onChanged,
        enabled: enabled,
        toggleGroupStyle: style,
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Color _resolved(WidgetTester tester, CoreColor token) {
  final context = tester.element(find.byType(ToggleGroup<String>));
  return Theme.of(context).colorScheme.resolve(token).toValue();
}

void main() {
  testWidgets('disabled selected weight wins without losing other typography', (
    tester,
  ) async {
    await _pump(
      tester,
      enabled: false,
      style: const CoreToggleGroupStyle(
        selectedFontWeight: 600,
        disabledLabelTextStyle: CoreTextStyle(fontWeight: 800, fontSize: 19),
      ),
    );
    final selected = tester.widget<material.RichText>(
      find
          .descendant(
            of: _visibleLabel('AM'),
            matching: find.byType(material.RichText),
          )
          .last,
    );
    final unselected = tester.widget<material.RichText>(
      find
          .descendant(
            of: _visibleLabel('PM'),
            matching: find.byType(material.RichText),
          )
          .last,
    );
    expect(selected.text.style!.fontWeight, material.FontWeight.w600);
    expect(unselected.text.style!.fontWeight, material.FontWeight.w800);
    expect(selected.text.style!.fontSize, 19);
  });

  group('ToggleGroup', () {
    testWidgets('paints the track and the raised chosen face', (tester) async {
      await _pump(tester, onChanged: (_) {});

      final chosen = _decorationOf(tester, 'AM');
      final unchosen = _decorationOf(tester, 'PM');
      expect(
        chosen.color,
        _resolved(tester, CoreToggleGroupStyle.defaultSelectedColor),
      );
      // The unchosen face is the chosen hue at alpha 0, so the lerp is
      // alpha-only.
      expect(unchosen.color!.a, 0);
      expect(
        _trackDecoration(tester).color,
        _resolved(tester, CoreToggleGroupStyle.defaultBackgroundColor),
      );
    });

    testWidgets('the chosen face carries the smallest shadow step only', (
      tester,
    ) async {
      await _pump(tester, onChanged: (_) {});

      final chosen = _decorationOf(tester, 'AM');
      final unchosen = _decorationOf(tester, 'PM');
      final context = tester.element(find.byType(ToggleGroup<String>));
      final theme = Theme.of(context);
      // The same Core layers, converted the way every other shadow is.
      final expected = CoreShadow.xs.toValue(
        base: theme.colorScheme
            .resolve(const CoreColor.token(CoreColors.shadow))
            .toValue(),
        geometry: theme.geometry,
        scale: theme.scaling,
      );
      expect(chosen.boxShadow, expected);
      expect(chosen.boxShadow, hasLength(CoreShadow.xs.length));
      expect(unchosen.boxShadow, anyOf(isNull, isEmpty));
    });

    testWidgets('the track inset is 4 and the segments sit 2 apart', (
      tester,
    ) async {
      await _pump(tester, onChanged: (_) {});

      final track = tester.getRect(_track());
      final am = tester.getRect(_segmentOf('AM'));
      final pm = tester.getRect(_segmentOf('PM'));
      expect(am.left - track.left, 4);
      expect(am.top - track.top, 4);
      expect(track.bottom - am.bottom, 4);
      expect(pm.left - am.right, 2);
      expect(am.height, CoreToggleGroupStyle.defaultItemHeight);
    });

    testWidgets('the chosen label is heavier and darker than the rest', (
      tester,
    ) async {
      await _pump(tester, onChanged: (_) {});

      final chosen = tester.widget<material.Text>(_visibleLabel('AM')).style!;
      final unchosen = tester.widget<material.Text>(_visibleLabel('PM')).style!;
      expect(chosen.fontWeight, material.FontWeight.w600);
      expect(chosen.color, isNot(unchosen.color));
    });

    testWidgets('reports the tapped value', (tester) async {
      String? changed;
      await _pump(tester, onChanged: (v) => changed = v);

      await tester.tap(_visibleLabel('PM'));
      await tester.pump();
      expect(changed, 'pm');
    });

    testWidgets('Tab reaches a segment and Enter / Space choose it', (
      tester,
    ) async {
      final changes = <String>[];
      await _pump(tester, onChanged: changes.add);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(changes, ['pm', 'pm']);
    });

    testWidgets('a disabled group takes no focus and ignores keys', (
      tester,
    ) async {
      final changes = <String>[];
      await _pump(tester, onChanged: changes.add, enabled: false);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, isEmpty);
    });

    testWidgets('without onChanged the group is inert and flat', (
      tester,
    ) async {
      await _pump(tester);

      final chosen = _decorationOf(tester, 'AM');
      expect(
        chosen.color,
        _resolved(tester, CoreToggleGroupStyle.defaultDisabledSelectedColor),
      );
      expect(chosen.boxShadow, anyOf(isNull, isEmpty));
      expect(
        _trackDecoration(tester).color,
        _resolved(tester, CoreToggleGroupStyle.defaultDisabledBackgroundColor),
      );
      final ink = tester
          .widget<material.Text>(_visibleLabel('PM'))
          .style!
          .color;
      expect(
        ink,
        _resolved(
          tester,
          CoreToggleGroupStyle.defaultDisabledLabelTextStyle.color!,
        ),
      );
      // The chosen label keeps its weight but not its colour.
      final chosenInk = tester
          .widget<material.Text>(_visibleLabel('AM'))
          .style!;
      expect(chosenInk.color, ink);
      expect(chosenInk.fontWeight, material.FontWeight.w600);
    });

    testWidgets('enabled: false wins over onChanged and ignores taps', (
      tester,
    ) async {
      String? changed;
      await _pump(tester, onChanged: (v) => changed = v, enabled: false);

      await tester.tap(_visibleLabel('PM'), warnIfMissed: false);
      await tester.pump();
      expect(changed, isNull);
      expect(
        _decorationOf(tester, 'AM').color,
        _resolved(tester, CoreToggleGroupStyle.defaultDisabledSelectedColor),
      );
    });

    testWidgets('a style override reaches the painted values', (tester) async {
      await _pump(
        tester,
        onChanged: (_) {},
        style: const CoreToggleGroupStyle(
          selectedColor: CoreColor.token(CoreColors.primary),
          selectedShadow: [],
        ),
      );

      final chosen = _decorationOf(tester, 'AM');
      expect(
        chosen.color,
        _resolved(tester, const CoreColor.token(CoreColors.primary)),
      );
      expect(chosen.boxShadow, anyOf(isNull, isEmpty));
    });

    group('hover state layer', () {
      Future<TestGesture> mouse(WidgetTester tester) async {
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await tester.pump();
        return gesture;
      }

      material.BoxDecoration? layerOf(WidgetTester tester, String label) =>
          tester
                  .widget<material.AnimatedContainer>(_segmentOf(label))
                  .foregroundDecoration
              as material.BoxDecoration?;

      Color hoverLayer(WidgetTester tester) => _resolved(
        tester,
        CoreToggleGroupStyle.defaultStateLayerColor.scaleAlpha(
          CoreToggleGroupStyle.defaultStateLayer.hover,
        ),
      );

      testWidgets('lays onSurface at the hover weight over the hovered '
          'segment, face and shadow unchanged', (tester) async {
        final gesture = await mouse(tester);
        await _pump(tester, onChanged: (_) {});
        final restFace = _decorationOf(tester, 'PM').color;
        expect(layerOf(tester, 'PM')?.color?.a ?? 0, 0);

        await gesture.moveTo(tester.getCenter(_segmentOf('PM')));
        await tester.pumpAndSettle();

        expect(layerOf(tester, 'PM')!.color, hoverLayer(tester));
        expect(
          layerOf(tester, 'PM')!.borderRadius,
          _decorationOf(tester, 'PM').borderRadius,
        );
        expect(_decorationOf(tester, 'PM').color, restFace);
        // Only the hovered segment wears it.
        expect(layerOf(tester, 'AM')?.color?.a ?? 0, 0);

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();
        expect(layerOf(tester, 'PM')?.color?.a ?? 0, 0);
      });

      testWidgets('the chosen segment wears it over its raised face', (
        tester,
      ) async {
        final gesture = await mouse(tester);
        await _pump(tester, onChanged: (_) {});
        final raised = _decorationOf(tester, 'AM');

        await gesture.moveTo(tester.getCenter(_segmentOf('AM')));
        await tester.pumpAndSettle();

        expect(layerOf(tester, 'AM')!.color, hoverLayer(tester));
        expect(_decorationOf(tester, 'AM').color, raised.color);
        expect(_decorationOf(tester, 'AM').boxShadow, raised.boxShadow);
      });

      testWidgets('a disabled group paints none', (tester) async {
        final gesture = await mouse(tester);
        await _pump(tester, enabled: false);

        await gesture.moveTo(tester.getCenter(_segmentOf('PM')));
        await tester.pumpAndSettle();

        expect(layerOf(tester, 'PM'), isNull);
        expect(layerOf(tester, 'AM'), isNull);
      });

      testWidgets('the colour and weight slots reach the painted layer', (
        tester,
      ) async {
        final gesture = await mouse(tester);
        await _pump(
          tester,
          onChanged: (_) {},
          style: const CoreToggleGroupStyle(
            stateLayerColor: CoreColor.token(CoreColors.primary),
            stateLayer: CoreStateLayer(
              hover: CoreOpacity.opacity16,
              focus: CoreOpacity.opacity16,
              pressed: CoreOpacity.opacity16,
            ),
          ),
        );

        await gesture.moveTo(tester.getCenter(_segmentOf('PM')));
        await tester.pumpAndSettle();

        expect(
          layerOf(tester, 'PM')!.color,
          _resolved(
            tester,
            const CoreColor.token(CoreColors.primary).scaleAlpha(
              CoreOpacity.opacity16,
            ),
          ),
        );
      });
    });

    testWidgets('announces a mutually exclusive checked segment', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, onChanged: (_) {});

      final am = tester.getSemantics(_segmentOf('AM'));
      expect(am.flagsCollection.isChecked, CheckedState.isTrue);
      expect(am.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      final pm = tester.getSemantics(_segmentOf('PM'));
      expect(pm.flagsCollection.isChecked, CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('withStyle merges a patch', (tester) async {
      final group =
          ToggleGroup<String>(
                items: _kItems,
                value: 'am',
                onChanged: (_) {},
              )
              .withStyle(const CoreToggleGroupStyle(itemHeight: 40))
              .withStyle(const CoreToggleGroupStyle(itemSpacing: 6));
      expect(group.toggleGroupStyle!.itemHeight, 40);
      expect(group.toggleGroupStyle!.itemSpacing, 6);
    });

    testWidgets('trailing sits inside the track after the last segment', (
      tester,
    ) async {
      const key = material.ValueKey<String>('trail');
      await tester.pumpWidget(
        _buildApp(
          ToggleGroup<String>(
            items: _kItems,
            value: 'am',
            onChanged: (_) {},
            trailing: const material.SizedBox(key: key, width: 10, height: 10),
          ),
        ),
      );

      final trail = tester.getRect(find.byKey(key));
      final last = tester.getRect(_segmentOf('PM'));
      final track = tester.getRect(find.byType(ToggleGroup<String>));
      expect(trail.left, greaterThanOrEqualTo(last.right));
      expect(trail.right, lessThanOrEqualTo(track.right));
    });
    testWidgets('fillWidth: the track takes the parent width, cells split it', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.SizedBox(
            width: 300,
            child: ToggleGroup<String>(
              items: _kItems,
              value: 'am',
              onChanged: (_) {},
              fillWidth: true,
            ),
          ),
        ),
      );
      final track = tester.getRect(find.byType(ToggleGroup<String>));
      final am = tester.getRect(_segmentOf('AM'));
      final pm = tester.getRect(_segmentOf('PM'));
      expect(track.width, 300);
      expect(am.width, closeTo(pm.width, 0.01));
      // Track inset 4 each side, 2 between the cells.
      expect(am.width + pm.width + 2 + 8, closeTo(300, 0.01));
      // The label stays centred in its cell.
      final amLabel = tester.getRect(_visibleLabel('AM'));
      expect(amLabel.center.dx, closeTo(am.center.dx, 0.5));
    });

    testWidgets('fillWidth defaults to false: the track hugs its cells', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ToggleGroup<String>(
            items: _kItems,
            value: 'am',
            onChanged: (_) {},
          ),
        ),
      );
      // Under the loose constraints of `Center` the track wraps its cells.
      expect(
        tester.getRect(find.byType(ToggleGroup<String>)).width,
        lessThan(150),
      );
    });

    group('size', () {
      Future<void> pumpSized(WidgetTester tester, CoreComponentSize? size) =>
          tester.pumpWidget(
            _buildApp(
              size == null
                  ? ToggleGroup<String>(
                      items: _kItems,
                      value: 'am',
                      onChanged: (_) {},
                    )
                  : ToggleGroup<String>(
                      items: _kItems,
                      value: 'am',
                      onChanged: (_) {},
                      size: size,
                    ),
            ),
          );

      testWidgets('md (the default) paints a 32 cell in a 40 track', (
        tester,
      ) async {
        await pumpSized(tester, null);
        expect(tester.getRect(_segmentOf('AM')).height, 32);
        expect(tester.getRect(find.byType(ToggleGroup<String>)).height, 40);
      });

      testWidgets('sm paints a 26 cell in a 32 track, inset 3, corner 8', (
        tester,
      ) async {
        await pumpSized(tester, CoreComponentSize.sm);
        final track = tester.getRect(find.byType(ToggleGroup<String>));
        final am = tester.getRect(_segmentOf('AM'));
        final pm = tester.getRect(_segmentOf('PM'));
        expect(am.height, 26);
        expect(pm.height, 26);
        expect(track.height, 32);
        expect(am.top - track.top, 3);
        expect(track.bottom - am.bottom, 3);
        expect(pm.left - am.right, 2);
        expect(
          _trackDecoration(tester).borderRadius,
          material.BorderRadius.circular(8),
        );
        expect(
          _decorationOf(tester, 'AM').borderRadius,
          material.BorderRadius.circular(6),
        );
      });

      testWidgets('md and sm segment labels sit at equal top and bottom gaps', (
        tester,
      ) async {
        for (final size in [CoreComponentSize.md, CoreComponentSize.sm]) {
          await pumpSized(tester, size);
          await tester.pumpAndSettle();
          final am = tester.getRect(_segmentOf('AM'));
          final label = tester.getRect(_visibleLabel('AM'));
          expect(
            label.top - am.top,
            closeTo(am.bottom - label.bottom, 0.01),
            reason: '$size',
          );
          expect(
            label.left - am.left,
            closeTo(am.right - label.right, 0.01),
            reason: '$size',
          );
        }
      });

      testWidgets('sm labels are labelMedium, md labels labelLarge', (
        tester,
      ) async {
        await pumpSized(tester, CoreComponentSize.md);
        final context = tester.element(find.byType(ToggleGroup<String>));
        final typography = Theme.of(context).typography;
        double sizeOf(String label) =>
            tester.widget<material.Text>(_visibleLabel(label)).style!.fontSize!;
        expect(sizeOf('PM'), typography.labelLarge.fontSize);
        await pumpSized(tester, CoreComponentSize.sm);
        expect(sizeOf('PM'), typography.labelMedium.fontSize);
        expect(sizeOf('AM'), typography.labelMedium.fontSize);
      });

      testWidgets('two sm cells are 60 tall with the gap — a time tile', (
        tester,
      ) async {
        await pumpSized(tester, CoreComponentSize.sm);
        final am = tester.getRect(_segmentOf('AM'));
        final pm = tester.getRect(_segmentOf('PM'));
        expect(3 + am.height + 2 + pm.height + 3, 60);
      });

      testWidgets('an icon-only segment is a square at both sizes', (
        tester,
      ) async {
        for (final (size, side) in [
          (CoreComponentSize.md, 32.0),
          (CoreComponentSize.sm, 26.0),
        ]) {
          await tester.pumpWidget(
            _buildApp(
              ToggleGroup<String>(
                items: const [
                  CoreToggleGroupItem(
                    value: 'a',
                    label: 'A',
                    icon: Icon(LucideIcons.check),
                    showLabel: false,
                  ),
                  CoreToggleGroupItem(value: 'b', label: 'B'),
                ],
                value: 'a',
                onChanged: (_) {},
                size: size,
              ),
            ),
          );
          // The previous size's segment animates to this one's.
          await tester.pumpAndSettle();
          final segment = tester.getRect(
            find
                .ancestor(
                  of: find.byType(Icon),
                  matching: find.byType(material.AnimatedContainer),
                )
                .first,
          );
          expect(segment.width, side, reason: '$size');
          expect(segment.height, side, reason: '$size');
        }
      });

      testWidgets('an explicit itemHeight outranks the size row', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            ToggleGroup<String>(
              items: _kItems,
              value: 'am',
              onChanged: (_) {},
              size: CoreComponentSize.sm,
              toggleGroupStyle: const CoreToggleGroupStyle(itemHeight: 40),
            ),
          ),
        );
        expect(tester.getRect(_segmentOf('AM')).height, 40);
      });
    });

    group('direction', () {
      Future<void> pumpVertical(
        WidgetTester tester, {
        CoreComponentSize size = CoreComponentSize.md,
        bool fillWidth = false,
        CoreAxis direction = CoreAxis.vertical,
      }) => tester.pumpWidget(
        _buildApp(
          ToggleGroup<String>(
            items: _kItems,
            value: 'am',
            onChanged: (_) {},
            size: size,
            direction: direction,
            fillWidth: fillWidth,
          ),
        ),
      );

      testWidgets('horizontal is the default: segments sit side by side', (
        tester,
      ) async {
        await pumpVertical(tester, direction: CoreAxis.horizontal);
        final am = tester.getRect(_segmentOf('AM'));
        final pm = tester.getRect(_segmentOf('PM'));
        expect(pm.left - am.right, 2);
        expect(pm.top, am.top);
      });

      testWidgets('vertical stacks AM above PM with the same 2 gap', (
        tester,
      ) async {
        await pumpVertical(tester);
        final am = tester.getRect(_segmentOf('AM'));
        final pm = tester.getRect(_segmentOf('PM'));
        expect(pm.top - am.bottom, 2);
        expect(pm.left, am.left);
        // Both segments take the track's width.
        expect(pm.width, am.width);
      });

      testWidgets('vertical sm is 3 + 26 + 2 + 26 + 3 = 60 tall', (
        tester,
      ) async {
        await pumpVertical(tester, size: CoreComponentSize.sm);
        final track = tester.getRect(find.byType(ToggleGroup<String>));
        final am = tester.getRect(_segmentOf('AM'));
        final pm = tester.getRect(_segmentOf('PM'));
        expect(am.height, 26);
        expect(pm.height, 26);
        expect(track.height, 60);
        expect(am.top - track.top, 3);
        expect(track.bottom - pm.bottom, 3);
        expect(am.left - track.left, 3);
        expect(track.right - am.right, 3);
      });

      testWidgets('a vertical track is as wide as its widest segment', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            ToggleGroup<String>(
              items: const [
                CoreToggleGroupItem(value: 'a', label: 'A'),
                CoreToggleGroupItem(value: 'long', label: 'Much longer'),
              ],
              value: 'a',
              onChanged: (_) {},
              direction: CoreAxis.vertical,
            ),
          ),
        );
        final a = tester.getRect(_segmentOf('A'));
        final long = tester.getRect(_segmentOf('Much longer'));
        expect(a.width, long.width);
        final track = tester.getRect(find.byType(ToggleGroup<String>));
        expect(track.width, long.width + 8);
      });

      testWidgets('vertical fillWidth stretches to the parent', (
        tester,
      ) async {
        await tester.pumpWidget(
          _buildApp(
            material.SizedBox(
              width: 200,
              child: ToggleGroup<String>(
                items: _kItems,
                value: 'am',
                onChanged: (_) {},
                direction: CoreAxis.vertical,
                fillWidth: true,
              ),
            ),
          ),
        );
        expect(tester.getRect(find.byType(ToggleGroup<String>)).width, 200);
        expect(tester.getRect(_segmentOf('AM')).width, 192);
      });
    });
  });
}
