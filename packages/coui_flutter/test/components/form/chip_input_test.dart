import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: material.Scaffold(
    body: Theme(data: const ThemeData(), child: child),
  ),
);

/// A geometry constraint that is deliberately NOT the identity, so a
/// radius that gets bent one time too many is numerically visible.
/// `ThemeData`'s default constraint has every field null and short-
/// circuits `borderRadius(v)` to `v`, which makes a pre-bent and an
/// un-bent resolver indistinguishable.
const _kRadiusFloorPreset = CoreSurfaceGeometryConstraint(radiusFloor: 16);

/// Height of the composed `Chip` badge — the `sm` row's floor.
const double _kChipHeight = 28;

/// The close affordance inside a badge: a 16px square ghost button.
const double _kCloseButtonSize = 16;

/// The X glyph inside that button — 12, the decided close size of an `sm` chip.
const double _kCloseGlyphSize = 12;

/// Single-run frame ceiling — a second run would exceed this.
const double _kSingleRowMaxHeight = 50;

/// Test-harness frame width. The test font (Ahem) renders every glyph
/// at fontSize width, so the placeholder measures ~2x wider than real
/// fonts; keep room for a single run.
const double _kSingleRowFrameWidth = 500;

/// The frame's painted border colour: the nearest decorated box above the
/// inline entry field that draws a border of the frame's width. The entry
/// field itself is chromeless and the focus ring wraps the frame from
/// outside, so this is the one box that is the visible boundary.
Color _frameBorderColor(WidgetTester tester) {
  final resolved = resolveChipInput(tester.element(find.byType(ChipInput)));
  final boxes = tester.widgetList<DecoratedBox>(
    find.ancestor(
      of: find.byType(TextField),
      matching: find.byType(DecoratedBox),
    ),
  );
  for (final box in boxes) {
    final decoration = box.decoration;
    if (decoration is! BoxDecoration) continue;
    final border = decoration.border;
    if (border is! Border) continue;
    if (border.top.width == resolved.borderWidth && border.top.color.a > 0) {
      return border.top.color;
    }
  }
  fail('no frame border found above the entry field');
}

/// Parks a mouse pointer over the centre of [finder] and returns the
/// gesture so the test can move it away again.
Future<TestGesture> _hoverOver(WidgetTester tester, Finder finder) async {
  final gesture = await tester.createGesture(kind: .mouse);
  await gesture.addPointer(location: .zero);
  addTearDown(gesture.removePointer);
  await gesture.moveTo(tester.getCenter(finder));
  await tester.pump();
  return gesture;
}

void main() {
  group('ChipInput widget', () {
    testWidgets('renders with key parameter', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChipInput(key: Key('chip_input')),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byKey(const Key('chip_input')), findsOneWidget);
    });

    testWidgets('renders with empty chips', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChipInput()),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ChipInput), findsOneWidget);
    });

    testWidgets('accepts a placeholder', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChipInput(placeholder: 'Type here')),
      );
      final _ = await tester.pumpAndSettle();

      // The placeholder renders as the input's hint text, not a standalone
      // Text widget, so assert it via the widget property.
      final widget = tester.widget<ChipInput>(find.byType(ChipInput));
      expect(widget.placeholder, equals('Type here'));
    });

    testWidgets('composes unified Chip badges at the sm row, filled · low', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          ChipInput(
            onChanged: (_) {},
            chips: const ['Flutter', 'Dart'],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNWidgets(2));
      // The badge is the shipped `Chip` at its `sm` row — 28 floor — drawn
      // filled · low; the close affordance is the 16px ghost button.
      final chipHeight = tester.getSize(find.byType(Chip).first).height;
      expect(chipHeight, closeTo(_kChipHeight, 1));
      final chip = tester.widget<Chip>(find.byType(Chip).first);
      expect(chip.variant, CoreChipInputStyle.chipVariant);
      expect(chip.emphasis, CoreChipInputStyle.chipEmphasis);
      expect(chip.size, CoreChipInputStyle.chipSize);
      expect(CoreChipInputStyle.chipVariant, CoreChipVariant.filled);
      expect(CoreChipInputStyle.chipEmphasis, CoreChipEmphasis.low);
      expect(CoreChipInputStyle.chipSize, CoreChipSize.sm);
      final close = tester.getSize(
        find
            .descendant(
              of: find.byType(Chip).first,
              matching: find.byType(Button),
            )
            .first,
      );
      expect(close.width, closeTo(_kCloseButtonSize, 0.5));
      expect(close.height, closeTo(_kCloseButtonSize, 0.5));
      // The X inside it is the 12 glyph `defaultChipStyle` forwards (the `sm`
      // row's own is 16) — read off the painted box, not the style.
      final glyph = tester.getSize(
        find
            .descendant(
              of: find.byType(Chip).first,
              matching: find.byType(Icon),
            )
            .last,
      );
      expect(
        glyph.width,
        closeTo(CoreChipInputStyle.defaultChipStyle.closeIconStyle!.size!, 0.5),
      );
      expect(glyph.width, closeTo(_kCloseGlyphSize, 0.5));
    });

    testWidgets('the entry field is the plain TextField variant', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.variant, CoreTextFieldVariant.plain);
      expect(field.variant, CoreChipInputStyle.fieldVariant);
    });

    testWidgets('X glyph recolours on hover', (tester) async {
      // Hover highlights only fire in traditional highlight mode — the
      // test binding defaults to touch.
      material.FocusManager.instance.highlightStrategy = .alwaysTraditional;
      await tester.pumpWidget(
        _buildApp(
          ChipInput(
            onChanged: (_) {},
            chips: const ['Flutter'],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final iconFinder = find.descendant(
        of: find.byType(Button),
        matching: find.byType(Icon),
      );
      material.IconThemeData themeOf() =>
          material.IconTheme.of(tester.element(iconFinder));

      // Idle — the X takes the ghost close button's own ink inside the chip.
      final idle = themeOf().color;

      final gesture = await tester.createGesture(kind: .mouse);
      await gesture.addPointer(location: .zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(iconFinder));
      await tester.pump();

      // Hover — the Button's per-state IconTheme moves; a colour pinned on
      // the icon would freeze it there.
      expect(themeOf().color, isNot(equals(idle)));
    });

    testWidgets('shows the placeholder in the inline field', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          ChipInput(
            onChanged: (_) {},
            chips: const ['Flutter'],
            placeholder: 'Add a tag...',
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('Add a tag...'), findsOneWidget);
    });

    testWidgets('chips and the inline field share a single row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          material.Center(
            child: material.SizedBox(
              width: _kSingleRowFrameWidth,
              child: ChipInput(
                onChanged: (_) {},
                chips: const ['Flutter', 'Dart'],
                placeholder: 'Add a tag...',
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      // Self-sized inline field joins the chips' run — a second run
      // would push the frame past its 40px min height.
      final frameHeight = tester.getSize(find.byType(ChipInput)).height;
      expect(frameHeight, lessThan(_kSingleRowMaxHeight));
    });

    testWidgets('renders chips when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const ChipInput(chips: ['apple', 'banana']),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('apple'), findsOneWidget);
      expect(find.text('banana'), findsOneWidget);
    });

    testWidgets('renders disabled state', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChipInput(enabled: false)),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ChipInput), findsOneWidget);
    });

    testWidgets('onChanged callback is wired up', (tester) async {
      List<String>? changed;

      await tester.pumpWidget(
        _buildApp(
          ChipInput(
            onChanged: (chips) {
              changed = chips;
            },
            chips: const ['apple'],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ChipInput), findsOneWidget);
      expect(changed, isNull);
    });
  });

  group(
    'frame focus ring corner radius is raw-forwarded (not double-bent)',
    () {
      testWidgets('focusOutlineStyle.borderRadius is the un-bent default', (
        tester,
      ) async {
        // `FocusOutline`'s own resolver already runs the geometry bend +
        // scaling on whatever `CoreFocusOutlineStyle.borderRadius` it is
        // given (focus_outline_style.dart) — `chip_input.dart` forwards
        // `resolved.focusOutlineStyle` straight into that slot. If
        // `chip_input_style.dart` pre-bent/pre-scaled the radius before
        // folding it into that slot, that bend/scale would apply
        // a second time inside `FocusOutline`. Read the resolver output
        // directly (rather than fishing a `FocusOutline` instance out of
        // the render tree, where the composed chromeless `TextField`
        // buffer's own internal `FocusOutline` is indistinguishable —
        // `TextField`'s resolver fills its own non-null default
        // `borderRadius` before forwarding too).
        //
        // A non-identity `geometry` is required to make a double-bend
        // observable at all. `ThemeData` defaults `geometry` to a
        // constraint whose every field is null, so `isIdentity` is true
        // and `theme.geometry.borderRadius(v)` returns `v` unchanged —
        // under that default a resolver that pre-bends and one that does
        // not return the same value, and this assertion passes either
        // way. `_kRadiusFloorPreset` maps the 4px default up to 16, so a
        // pre-bend here shows up as 16 (and a second bend inside
        // `FocusOutline` would take it to 28).
        late ResolvedChipInput resolved;
        await tester.pumpWidget(
          _buildApp(
            Theme(
              data: const ThemeData(
                scaling: 1.25,
                geometry: _kRadiusFloorPreset,
              ),
              child: Builder(
                builder: (context) {
                  resolved = resolveChipInput(context);
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(
          resolved.focusOutlineStyle.borderRadius,
          CoreChipInputStyle.defaultBorderRadius,
          reason:
              'the frame focus ring should receive the raw design-system '
              'default corner radius — a bent/scaled scalar here would '
              'be geometry-bent a second time by FocusOutline itself',
        );
      });

      testWidgets('a caller borderRadius override reaches the ring un-bent', (
        tester,
      ) async {
        // The frame radius is folded in *under* the caller's slot, so an
        // override of the ChipInput's own `borderRadius` must reach the
        // ring too — otherwise the ring would keep tracing the default
        // corner around a re-cornered frame. Pumped under the same
        // non-identity geometry, and with an override *below* the floor,
        // so a pre-bend is observable here too (8 would arrive as 16).
        late ResolvedChipInput resolved;
        await tester.pumpWidget(
          _buildApp(
            Theme(
              data: const ThemeData(geometry: _kRadiusFloorPreset),
              child: Builder(
                builder: (context) {
                  resolved = resolveChipInput(
                    context,
                    chipInputStyle: const CoreChipInputStyle(
                      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
                    ),
                  );
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(
          resolved.focusOutlineStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius8),
          reason:
              'the caller radius must reach the ring un-bent — the bend '
              'belongs to FocusOutline, which applies it exactly once',
        );
      });
    },
  );

  group('frame focus ring — nested focusOutlineStyle slot', () {
    testWidgets('an unset slot leaves every ring field to FocusOutline', (
      tester,
    ) async {
      // Form C: `CoreChipInputStyle` carries no partial focus-outline
      // default, so nothing but the frame corner is stated here. A colour
      // (or width / offset / opacity) restated on this side would be a
      // second copy of `CoreFocusOutlineStyle`'s own default and would
      // drift from it silently.
      late ResolvedChipInput resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveChipInput(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(resolved.focusOutlineStyle.borderColor, isNull);
      expect(resolved.focusOutlineStyle.borderWidth, isNull);
      expect(resolved.focusOutlineStyle.align, isNull);
      expect(resolved.focusOutlineStyle.offsetColor, isNull);
      expect(resolved.focusOutlineStyle.ringOpacity, isNull);
    });

    testWidgets('a caller ring colour reaches the composed FocusOutline', (
      tester,
    ) async {
      // The slot is the only entry point for the ring's chrome now, and
      // it has to survive all the way to the widget that draws it — a
      // resolver that dropped it would still render a (default-coloured)
      // ring, which is exactly the failure mode this pins.
      const rawGreen = CoreColor(0xFF00FF00);
      await tester.pumpWidget(
        _buildApp(
          const ChipInput(
            chips: ['a'],
            chipInputStyle: CoreChipInputStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(borderColor: rawGreen),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final outline = tester.widgetList<FocusOutline>(
        find.byType(FocusOutline),
      );
      expect(
        outline.map((o) => o.focusOutlineStyle?.borderColor),
        contains(rawGreen),
      );
    });
  });

  // `ChipInput` draws its chips with `Chip`, so it inherits the remove
  // button's name. What it adds is the multiplicity: N identical
  // "button" announcements are exactly what the name exists to prevent,
  // so each one must say which chip it removes. Read from the semantics
  // tree — that is what the reader sees.
  testWidgets('each chip remove button carries a distinct name', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    const chips = ['Flutter', 'Dart', 'Jaspr'];
    await tester.pumpWidget(
      CoUIApp(
        home: ChipInput(onChanged: (_) {}, chips: chips),
        theme: ThemeData.fromCore(CoreThemePresets.light),
      ),
    );
    await tester.pumpAndSettle();

    // Each name found exactly once, and no other remove button beside
    // them — together that is "N buttons, N different names".
    for (final chip in chips) {
      expect(find.bySemanticsLabel('Remove $chip'), findsOneWidget);
    }
    expect(
      find.bySemanticsLabel(RegExp('^Remove ')),
      findsNWidgets(chips.length),
    );
    handle.dispose();
  });

  // The frame is the box and the entry field inside it is chromeless, so the
  // pointer has to step the frame's own border: `disabled > focus > hover >
  // rest`. A focused frame is ringed by `FocusOutline` and keeps the resting
  // border under the pointer — the ring is its state change.
  group('frame hover border', () {
    testWidgets('the resolver resolves both borders through the scheme', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();

      final context = tester.element(find.byType(ChipInput));
      final scheme = Theme.of(context).colorScheme;
      final resolved = resolveChipInput(context);

      expect(
        resolved.borderColor,
        scheme.resolve(CoreChipInputStyle.defaultBorderColor).toValue(),
      );
      expect(
        resolved.hoverBorderColor,
        scheme.resolve(CoreChipInputStyle.defaultHoverBorderColor).toValue(),
      );
      expect(resolved.hoverBorderColor, isNot(resolved.borderColor));
    });

    testWidgets('rests on the resting border', (tester) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();

      expect(
        _frameBorderColor(tester),
        resolveChipInput(tester.element(find.byType(ChipInput))).borderColor,
      );
    });

    testWidgets('the pointer steps the border to the hover colour and back', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();
      final resolved = resolveChipInput(
        tester.element(find.byType(ChipInput)),
      );

      final gesture = await _hoverOver(tester, find.byType(ChipInput));
      expect(_frameBorderColor(tester), resolved.hoverBorderColor);

      // Over a child of the frame (the composed Chip) is still over the
      // frame — the hover must not flicker off on the way in.
      await gesture.moveTo(tester.getCenter(find.byType(Chip)));
      await tester.pump();
      expect(_frameBorderColor(tester), resolved.hoverBorderColor);

      // Well below the frame — the app is laid out from the top-left, so
      // the corner of the screen is inside it.
      await gesture.moveTo(const Offset(1, 400));
      await tester.pump();
      expect(_frameBorderColor(tester), resolved.borderColor);
    });

    testWidgets('a per-instance hoverBorderColor wins over the default', (
      tester,
    ) async {
      const custom = CoreColor.token(CoreColors.error);
      await tester.pumpWidget(
        _buildApp(
          const ChipInput(
            chips: ['a'],
            chipInputStyle: CoreChipInputStyle(hoverBorderColor: custom),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      final scheme = Theme.of(
        tester.element(find.byType(ChipInput)),
      ).colorScheme;

      await _hoverOver(tester, find.byType(ChipInput));

      expect(_frameBorderColor(tester), scheme.resolve(custom).toValue());
    });

    testWidgets('focus wins: a focused frame keeps its resting border under '
        'the pointer', (tester) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();
      final resolved = resolveChipInput(
        tester.element(find.byType(ChipInput)),
      );

      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();
      // The frame's own ring is the outermost `FocusOutline`; the composed
      // chips carry rings of their own.
      expect(
        tester
            .widget<FocusOutline>(
              find
                  .descendant(
                    of: find.byType(ChipInput),
                    matching: find.byType(FocusOutline),
                  )
                  .first,
            )
            .focused,
        isTrue,
        reason: 'the tap has to focus the frame for this test to mean anything',
      );

      await _hoverOver(tester, find.byType(ChipInput));
      expect(_frameBorderColor(tester), resolved.borderColor);
    });

    testWidgets('a disabled frame has no hover step', (tester) async {
      await tester.pumpWidget(
        _buildApp(const ChipInput(chips: ['a'], enabled: false)),
      );
      final _ = await tester.pumpAndSettle();
      final resolved = resolveChipInput(
        tester.element(find.byType(ChipInput)),
      );

      await _hoverOver(tester, find.byType(ChipInput));

      expect(_frameBorderColor(tester), resolved.disabledBorderColor);
      expect(_frameBorderColor(tester), isNot(resolved.hoverBorderColor));
    });
  });

  // The frame's redesigned chrome (#5831): the md row
  // floor, corner 12 — with its quiet resting edge and disabled tokens.
  group('frame chrome', () {
    testWidgets('resolves the redesigned defaults through the scheme', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const ChipInput(chips: ['a'])));
      final _ = await tester.pumpAndSettle();
      final context = tester.element(find.byType(ChipInput));
      final scheme = Theme.of(context).colorScheme;
      final resolved = resolveChipInput(context);

      Color token(CoreColor c) => scheme.resolve(c).toValue();
      expect(
        resolved.borderColor,
        token(const CoreColor.token(CoreColors.outlineVariant)),
      );
      expect(
        resolved.hoverBorderColor,
        token(const CoreColor.token(CoreColors.outline)),
      );
      expect(
        resolved.disabledBackgroundColor,
        token(const CoreColor.token(CoreColors.disabledContainer)),
      );
      expect(
        resolved.disabledBorderColor,
        token(const CoreColor.token(CoreColors.disabledOutline)),
      );
      expect(resolved.borderRadiusValue, 12);
      expect(resolved.minHeight, 40);
      expect(
        resolved.padding,
        const EdgeInsetsDirectional.fromSTEB(10, 6, 14, 6),
      );
    });

    testWidgets('a disabled frame paints the disabled fill and edge', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const ChipInput(chips: ['a'], enabled: false)),
      );
      final _ = await tester.pumpAndSettle();
      final resolved = resolveChipInput(
        tester.element(find.byType(ChipInput)),
      );

      final frame = tester
          .widgetList<Container>(
            find.descendant(
              of: find.byType(ChipInput),
              matching: find.byType(Container),
            ),
          )
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .firstWhere((d) => d.border != null && d.borderRadius != null);
      expect(frame.color, resolved.disabledBackgroundColor);
      expect(frame.color, isNot(resolved.backgroundColor));
    });

    testWidgets('the frame holds the md row and grows with its chips', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const material.Center(
            child: material.SizedBox(
              width: _kSingleRowFrameWidth,
              child: ChipInput(chips: ['a']),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byType(ChipInput)).height,
        greaterThanOrEqualTo(40),
      );
    });
  });
}
