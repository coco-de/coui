import 'dart:ui' show SemanticsAction, Tristate;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter_test/flutter_test.dart';

Widget _buildApp(Widget child) => material.MaterialApp(
  home: Theme(data: const ThemeData(), child: child),
);

/// The one `OutlinedContainer` a toggle composes — its track.
OutlinedContainer _track(WidgetTester tester) =>
    tester.widget<OutlinedContainer>(find.byType(OutlinedContainer));

/// What a screen reader lands on: the node that says it is a toggle. The
/// `Toggle` element itself sits above it, on a wrapper that states nothing.
SemanticsData _toggleNode(WidgetTester tester) => tester
    .getSemantics(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.toggled != null,
        description: 'the Semantics that states a toggle',
      ),
    )
    .getSemanticsData();

void main() {
  for (final scaling in [1.0, 2.0]) {
    for (final dark in [false, true]) {
      for (final enabled in [false, true]) {
        for (final value in [false, true]) {
          testWidgets(
            'thumb cast dark=$dark enabled=$enabled '
            'value=$value scaling=$scaling',
            (
              tester,
            ) async {
              final theme = ThemeData(
                scaling: scaling,
                colorScheme: dark
                    ? CoreThemePresets.darkColorScheme
                    : CoreThemePresets.lightColorScheme,
              );
              await tester.pumpWidget(
                material.MaterialApp(
                  home: Theme(
                    data: theme,
                    child: Toggle(
                      value: value,
                      enabled: enabled,
                      onChanged: (_) {},
                      toggleStyle: const CoreToggleStyle(
                        thumbShadow: CoreShadow.sm,
                      ),
                    ),
                  ),
                ),
              );
              await tester.pumpAndSettle();
              final thumb = tester.widget<material.Container>(
                find
                    .descendant(
                      of: find.byType(AspectRatio),
                      matching: find.byType(material.Container),
                    )
                    .first,
              );
              final decoration = thumb.decoration! as BoxDecoration;
              expect(
                decoration.boxShadow,
                CoreShadow.sm.toValue(
                  base: theme.colorScheme
                      .resolve(CoreToggleStyle.defaultThumbShadowBaseColor)
                      .toValue(),
                  geometry: theme.geometry,
                  scale: scaling,
                ),
              );
              expect(decoration.boxShadow, hasLength(2));
              expect(tester.takeException(), isNull);
            },
          );
        }
      }
    }
  }
  // The default cast is what carries the white off thumb's outline on a
  // light off track, so it paints without a caller asking.
  testWidgets('default thumb casts the faint default shadow', (tester) async {
    late ThemeData theme;
    await tester.pumpWidget(
      _buildApp(
        material.Builder(
          builder: (context) {
            theme = Theme.of(context);
            return Toggle(value: false, onChanged: (_) {});
          },
        ),
      ),
    );
    final thumb = tester.widget<material.Container>(
      find
          .descendant(
            of: find.byType(AspectRatio),
            matching: find.byType(material.Container),
          )
          .first,
    );
    final boxShadow = (thumb.decoration! as BoxDecoration).boxShadow!;
    expect(boxShadow, hasLength(2));
    expect(
      boxShadow,
      CoreToggleStyle.defaultThumbShadow.toValue(
        base: theme.colorScheme
            .resolve(CoreToggleStyle.defaultThumbShadowBaseColor)
            .toValue(),
        geometry: theme.geometry,
        scale: theme.scaling,
      ),
    );
  });

  group('ToggleController', () {
    test('initializes with false by default', () {
      final controller = ToggleController();
      expect(controller.value, isFalse);
      controller.dispose();
    });

    test('initializes with provided value', () {
      final controller = ToggleController(true);
      expect(controller.value, isTrue);
      controller.dispose();
    });

    test('toggle() switches false to true', () {
      final controller = ToggleController()..toggle();
      expect(controller.value, isTrue);
      controller.dispose();
    });

    test('toggle() switches true to false', () {
      final controller = ToggleController(true)..toggle();
      expect(controller.value, isFalse);
      controller.dispose();
    });
  });

  group('Toggle widget', () {
    testWidgets('renders without error in off state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (_) {},
            value: false,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Toggle), findsOneWidget);
    });

    testWidgets('renders without error in on state', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (_) {},
            value: true,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(Toggle), findsOneWidget);
    });

    testWidgets('respects key parameter', (tester) async {
      const testKey = Key('toggle-key');

      await tester.pumpWidget(
        _buildApp(
          Toggle(
            key: testKey,
            onChanged: (_) {},
            value: false,
          ),
        ),
      );

      expect(find.byKey(testKey), findsOneWidget);
    });

    testWidgets('calls onChanged when tapped', (tester) async {
      bool? receivedValue;

      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (value) {
              receivedValue = value;
            },
            value: false,
          ),
        ),
      );

      await tester.tap(find.byType(Toggle));
      final _ = await tester.pumpAndSettle();

      expect(receivedValue, isTrue);
    });

    testWidgets('calls onChanged with false when toggled from true', (
      tester,
    ) async {
      bool? receivedValue;

      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (value) {
              receivedValue = value;
            },
            value: true,
          ),
        ),
      );

      await tester.tap(find.byType(Toggle));
      final _ = await tester.pumpAndSettle();

      expect(receivedValue, isFalse);
    });

    // The read a screen reader makes: a toggle given no callback has nothing
    // to do when pressed, so it must not announce as a live control. The
    // rendered semantics node is read, not the widget's own getter.
    testWidgets('with no callback it announces as disabled and offers no tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(const Toggle(onChanged: null, value: false)),
      );

      final data = _toggleNode(tester);
      expect(data.flagsCollection.isEnabled, Tristate.isFalse);
      expect(data.hasAction(SemanticsAction.tap), isFalse);
      handle.dispose();
    });

    testWidgets('with a callback it announces as live and offers a tap', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(Toggle(onChanged: (_) {}, value: false)),
      );

      final data = _toggleNode(tester);
      expect(data.flagsCollection.isEnabled, Tristate.isTrue);
      expect(data.hasAction(SemanticsAction.tap), isTrue);
      handle.dispose();
    });

    testWidgets('an explicit enabled overrides the callback either way', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _buildApp(Toggle(onChanged: (_) {}, value: false, enabled: false)),
      );
      expect(
        _toggleNode(tester).flagsCollection.isEnabled,
        Tristate.isFalse,
      );

      await tester.pumpWidget(
        _buildApp(const Toggle(onChanged: null, value: false, enabled: true)),
      );
      expect(
        _toggleNode(tester).flagsCollection.isEnabled,
        Tristate.isTrue,
      );
      handle.dispose();
    });

    testWidgets('renders leading widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (_) {},
            value: false,
            prefix: const Text('leading label'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('leading label'), findsOneWidget);
    });

    testWidgets('renders trailing widget when provided', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          Toggle(
            onChanged: (_) {},
            value: false,
            suffix: const Text('trailing label'),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.text('trailing label'), findsOneWidget);
    });
  });

  // What the 2026-09 redesign draws — read back off the composed track and
  // the outline around it, not off the style table, so a resolver that
  // stops forwarding a value fails here.
  group('Toggle redesign', () {
    testWidgets('disabled is said by the track — on and off take different '
        'tokens', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const Row(
            children: [
              Toggle(onChanged: null, value: true, enabled: false),
              Toggle(onChanged: null, value: false, enabled: false),
            ],
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tracks = tester
          .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
          .toList();
      expect(tracks, hasLength(2));
      expect(
        tracks[0].containerStyle!.backgroundColor,
        const CoreColor.token(CoreColors.disabledContent),
      );
      expect(
        tracks[1].containerStyle!.backgroundColor,
        const CoreColor.token(CoreColors.disabledContainer),
      );
    });

    // The enabled poses: the off track is the highest container step, the
    // on thumb is the ink chosen to be read on the primary track
    // (`onPrimary`), and the off thumb is fixed white in both modes.
    // Read off the painted track bundle and the painted thumb, so a
    // resolver or widget that stops selecting these tokens fails here.
    testWidgets('the off track is the highest container step; the thumbs are '
        'onPrimary on / fixed white off', (tester) async {
      late ResolvedColorScheme scheme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return Row(
                children: [
                  Toggle(onChanged: (_) {}, value: true),
                  Toggle(onChanged: (_) {}, value: false),
                ],
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final tracks = tester
          .widgetList<OutlinedContainer>(find.byType(OutlinedContainer))
          .toList();
      expect(tracks, hasLength(2));
      expect(
        tracks[0].containerStyle!.backgroundColor,
        const CoreColor.token(CoreColors.primary),
      );
      expect(
        tracks[1].containerStyle!.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerHighest),
      );

      material.Color thumbOf(int index) {
        final thumb = tester.widget<material.Container>(
          find
              .descendant(
                of: find.byType(AspectRatio).at(index),
                matching: find.byType(material.Container),
              )
              .first,
        );
        return (thumb.decoration! as BoxDecoration).color!;
      }

      material.Color token(CoreColorToken t) =>
          scheme.resolve(CoreColor.token(t)).toValue();

      expect(thumbOf(0), token(CoreColors.onPrimary));
      expect(thumbOf(1), const material.Color(0xFFFFFFFF));
      // The negative controls: the off thumb is not the scheme's `onSurface`
      // ink, and the off track is not `surfaceContainer`.
      expect(thumbOf(1), isNot(token(CoreColors.onSurface)));
      expect(
        tracks[1].containerStyle!.backgroundColor,
        isNot(const CoreColor.token(CoreColors.surfaceContainer)),
      );
    });

    // The disabled thumbs follow the enabled rule: the off thumb is fixed
    // white, the on thumb is its track's ink, `surface`. Read off the painted
    // thumb, so a resolver or widget that stops selecting them fails here.
    testWidgets('the disabled off thumb paints fixed white, the on thumb '
        'stays surface', (tester) async {
      late ResolvedColorScheme scheme;
      await tester.pumpWidget(
        _buildApp(
          material.Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return const Row(
                children: [
                  Toggle(onChanged: null, value: true, enabled: false),
                  Toggle(onChanged: null, value: false, enabled: false),
                ],
              );
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      material.Color thumbOf(int index) {
        final thumb = tester.widget<material.Container>(
          find
              .descendant(
                of: find.byType(AspectRatio).at(index),
                matching: find.byType(material.Container),
              )
              .first,
        );
        return (thumb.decoration! as BoxDecoration).color!;
      }

      material.Color token(CoreColorToken t) =>
          scheme.resolve(CoreColor.token(t)).toValue();

      expect(thumbOf(0), token(CoreColors.surface));
      expect(thumbOf(1), const material.Color(0xFFFFFFFF));
      expect(thumbOf(1), isNot(token(CoreColors.disabledContent)));
    });

    testWidgets('the focus ring wraps the track, not the row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(Toggle(onChanged: (_) {}, value: false, label: 'Wi-Fi')),
      );
      final _ = await tester.pumpAndSettle();

      // Exactly one `FocusOutline`, and it is the one around the track:
      // the composing `Clickable` keeps its own row-wide ring off.
      final outlines = find.byType(FocusOutline);
      expect(outlines, findsOneWidget);
      expect(
        find.descendant(of: outlines, matching: find.byType(OutlinedContainer)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: outlines, matching: find.text('Wi-Fi')),
        findsNothing,
      );
      expect(
        tester.widget<Clickable>(find.byType(Clickable)).focusOutline,
        isFalse,
      );
      expect(
        tester.widget<FocusOutline>(outlines).focusOutlineStyle?.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    testWidgets("hover washes the track with its own ink at the ramp's "
        'hover weight; a press at the pressed weight', (tester) async {
      // The Clickable reports hover through `FocusableActionDetector`, which
      // only shows a hover highlight under the traditional strategy — the
      // test binding starts in touch mode.
      final previous = material.FocusManager.instance.highlightStrategy;
      material.FocusManager.instance.highlightStrategy = .alwaysTraditional;
      addTearDown(
        () => material.FocusManager.instance.highlightStrategy = previous,
      );
      await tester.pumpWidget(
        _buildApp(Toggle(onChanged: (_) {}, value: true)),
      );
      final _ = await tester.pumpAndSettle();
      final rest = _track(tester).containerStyle!.backgroundColor;
      expect(rest, const CoreColor.token(CoreColors.primary));

      final gesture = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await gesture.moveTo(tester.getCenter(find.byType(Toggle)));
      await tester.pump();
      final hovered = _track(tester).containerStyle!.backgroundColor;
      expect(hovered, isNot(rest));
      // A raw composite, no longer a token — the wash is blended once
      // against the scheme-resolved colours.
      expect(hovered?.token, isNull);

      await gesture.down(tester.getCenter(find.byType(Toggle)));
      await tester.pump();
      final pressed = _track(tester).containerStyle!.backgroundColor;
      expect(pressed, isNot(rest));
      expect(pressed, isNot(hovered));

      await gesture.up();
      await tester.pump();
      await gesture.moveTo(const Offset(-100, -100));
      await tester.pump();
      expect(_track(tester).containerStyle!.backgroundColor, rest);
    });

    testWidgets('label reads the size ladder — 13 / 14 / 15 / 15 / 15', (
      tester,
    ) async {
      // Body copy at the size's role: sm is `bodySmall`, md `bodyMedium`,
      // lg..xl2 `bodyLarge` — read off the role table so a change to the
      // scale moves this with it.
      const scale = CoreTypography.coui;
      final expected = {
        CoreComponentSize.sm: scale.bodySmall.fontSize,
        CoreComponentSize.md: scale.bodyMedium.fontSize,
        CoreComponentSize.lg: scale.bodyLarge.fontSize,
        CoreComponentSize.xl: scale.bodyLarge.fontSize,
        CoreComponentSize.xl2: scale.bodyLarge.fontSize,
      };
      expect(expected.values.toList(), [13.0, 14.0, 15.0, 15.0, 15.0]);
      for (final entry in expected.entries) {
        await tester.pumpWidget(
          _buildApp(
            Toggle(
              onChanged: (_) {},
              value: false,
              size: entry.key,
              label: 'L',
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();
        final text = tester.widget<Text>(find.text('L'));
        expect(
          text.style?.fontSize,
          entry.value,
          reason: 'CoreComponentSize.${entry.key.name}',
        );
        expect(text.style?.fontWeight, FontWeight.w400);
      }
    });

    // The picture the table describes: a track as wide as its height plus
    // 16, a thumb 2 inside each end, travelling the same 16 on every size.
    // Read off the laid-out boxes, so a row that restates a width the
    // resolver then ignores fails here.
    testWidgets('the track is its height + 16 wide and the thumb travels 16 '
        '— drawn at every size', (tester) async {
      const drawn = {
        CoreComponentSize.sm: Size(32, 16),
        CoreComponentSize.md: Size(36, 20),
        CoreComponentSize.lg: Size(40, 24),
        CoreComponentSize.xl: Size(44, 28),
        CoreComponentSize.xl2: Size(48, 32),
      };
      const inset = CoreToggleStyle.defaultThumbInset;
      for (final entry in drawn.entries) {
        var on = false;
        await tester.pumpWidget(
          _buildApp(
            material.StatefulBuilder(
              builder: (context, setState) => Toggle(
                value: on,
                onChanged: (value) => setState(() => on = value),
                size: entry.key,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        final name = 'CoreComponentSize.${entry.key.name}';
        final track = tester.getRect(find.byType(OutlinedContainer));
        expect(track.size, entry.value, reason: '$name track');

        final thumb = find.descendant(
          of: find.byType(Toggle),
          matching: find.byType(AspectRatio),
        );
        final off = tester.getRect(thumb);
        expect(off.left - track.left, inset, reason: '$name off');

        await tester.tap(find.byType(Toggle));
        final _ = await tester.pumpAndSettle();
        final onRect = tester.getRect(thumb);
        expect(onRect.left - off.left, 16, reason: '$name travel');
        expect(track.right - onRect.right, inset, reason: '$name on');
      }
    });

    testWidgets('xs has no row and draws the sm switch', (tester) async {
      await tester.pumpWidget(
        _buildApp(Toggle(onChanged: (_) {}, value: false, size: .xs)),
      );
      final _ = await tester.pumpAndSettle();
      final sm = CoreToggleStyle.defaultsBySize[CoreComponentSize.sm]!;
      expect(_track(tester).containerStyle!.width, sm.trackWidth);
      expect(_track(tester).containerStyle!.height, sm.trackHeight);
    });
  });
  // The lens exists only while the thumb travels — read back off the tree,
  // so a widget that mounts it at rest (or never) fails here.
  group('Toggle transient lens', () {
    Finder lensFinder() => find.byWidgetPredicate(
      (w) => w is OutlinedContainer && w.role == CoreSurfaceRole.functional,
    );

    /// A toggle whose host follows every flip — or, with [hostIgnoresFlip],
    /// reports nothing back. [setValue] receives the host's own setter, the
    /// way an app sets a value in code (a form reset, a "turn all on").
    Widget flipping({
      bool initial = false,
      bool enabled = true,
      bool disableAnimations = false,
      bool hostIgnoresFlip = false,
      FocusNode? focusNode,
      void Function(ValueChanged<bool> setValue)? setValue,
    }) {
      var value = initial;
      return _buildApp(
        MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: StatefulBuilder(
            builder: (context, setState) {
              setValue?.call((v) => setState(() => value = v));
              return Toggle(
                onChanged: hostIgnoresFlip
                    ? (_) {}
                    : (v) => setState(() => value = v),
                value: value,
                enabled: enabled,
                focusNode: focusNode,
              );
            },
          ),
        ),
      );
    }

    /// Lets the travel reach its middle, where the lens (if any) is shown.
    Future<void> pumpToMidTravel(WidgetTester tester) async {
      await tester.pump();
      await tester.pump(CoreToggleStyle.defaultThumbTransitionDuration ~/ 2);
    }

    testWidgets('is absent at rest, in both poses', (tester) async {
      for (final value in [false, true]) {
        await tester.pumpWidget(flipping(initial: value));
        final _ = await tester.pumpAndSettle();
        expect(lensFinder(), findsNothing, reason: 'value: $value');
        expect(find.byType(OutlinedContainer), findsOneWidget);
      }
    });

    testWidgets('rides the thumb for exactly one travel, then leaves', (
      tester,
    ) async {
      await tester.pumpWidget(flipping());
      final _ = await tester.pumpAndSettle();
      final trackRect = tester.getRect(find.byType(OutlinedContainer));

      await tester.tap(find.byType(Toggle));
      await tester.pump();
      await tester.pump(
        CoreToggleStyle.defaultThumbTransitionDuration ~/ 2,
      );

      expect(lensFinder(), findsOneWidget);
      final lensRect = tester.getRect(lensFinder());
      // Larger than the thumb and spilling past the track, which is what a
      // transient lens is free to do — it takes no room in the layout.
      const outset = CoreToggleStyle.defaultLensOutset;
      final md = CoreToggleStyle.sizeDefaults(CoreComponentSize.md);
      expect(lensRect.height, md.thumbSize! + outset.top + outset.bottom);
      expect(lensRect.width, md.thumbSize! + outset.left + outset.right);
      expect(lensRect.top, lessThan(trackRect.top));
      expect(lensRect.bottom, greaterThan(trackRect.bottom));
      // Mid-travel: between the two resting poses, not at either.
      final restLeft = trackRect.left + md.padding!.left - outset.left;
      expect(lensRect.left, greaterThan(restLeft));
      expect(lensRect.left, lessThan(restLeft + md.thumbOffset!));
      // Shown, not a transparent placeholder.
      final opacity = tester.widget<Opacity>(
        find.ancestor(of: lensFinder(), matching: find.byType(Opacity)),
      );
      expect(opacity.opacity, greaterThan(0));

      final _ = await tester.pumpAndSettle();
      expect(lensFinder(), findsNothing);
      // The resting switch after the travel is the resting switch before it.
      expect(find.byType(OutlinedContainer), findsOneWidget);
      expect(tester.getRect(find.byType(OutlinedContainer)), trackRect);
    });

    testWidgets('is suppressed with the transition under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(flipping(disableAnimations: true));
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byType(Toggle));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: CoreDuration.ms50));

      expect(lensFinder(), findsNothing);
    });

    testWidgets('lens stays on the rendered thumb when travel reverses', (
      tester,
    ) async {
      await tester.pumpWidget(flipping());
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Toggle));
      await tester.pump();
      await tester.pump(
        CoreToggleStyle.defaultThumbTransitionDuration ~/ 3,
      );
      await tester.tap(find.byType(Toggle));
      await tester.pump();
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final thumb = tester.getRect(find.byType(CompositedTransformTarget));
        final lens = tester.getRect(lensFinder());
        expect(lens.center.dx, closeTo(thumb.center.dx, 0.01));
        expect(lens.center.dy, closeTo(thumb.center.dy, 0.01));
      }
      await tester.pumpAndSettle();
    });

    testWidgets('enabling reduced motion ends an in-flight lens', (
      tester,
    ) async {
      var reduceMotion = false;
      var value = false;
      late StateSetter update;
      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return MediaQuery(
                data: MediaQueryData(disableAnimations: reduceMotion),
                child: Toggle(
                  value: value,
                  onChanged: (next) => setState(() => value = next),
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Toggle));
      await pumpToMidTravel(tester);
      expect(lensFinder(), findsOneWidget);
      update(() => reduceMotion = true);
      await tester.pump();
      expect(lensFinder(), findsNothing);
      await tester.pumpAndSettle();
    });

    testWidgets('a value the app sets in code moves with no lens', (
      tester,
    ) async {
      late ValueChanged<bool> setValue;
      await tester.pumpWidget(flipping(setValue: (set) => setValue = set));
      final _ = await tester.pumpAndSettle();

      setValue(true);
      await pumpToMidTravel(tester);

      expect(lensFinder(), findsNothing);
      // The flip itself landed — only the lens stayed away.
      expect(tester.widget<Toggle>(find.byType(Toggle)).value, isTrue);
    });

    testWidgets('a keyboard flip rides the lens like a tap', (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      await tester.pumpWidget(flipping(focusNode: focusNode));
      final _ = await tester.pumpAndSettle();
      focusNode.requestFocus();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await pumpToMidTravel(tester);

      expect(lensFinder(), findsOneWidget);
      expect(tester.widget<Toggle>(find.byType(Toggle)).value, isTrue);
      // The keyboard press pulse (`Clickable`) runs out with the travel.
      final _ = await tester.pumpAndSettle();
      expect(lensFinder(), findsNothing);
    });

    testWidgets('a flip the host ignores leaves no mark for a later change '
        'in code', (tester) async {
      late ValueChanged<bool> setValue;
      await tester.pumpWidget(
        flipping(hostIgnoresFlip: true, setValue: (set) => setValue = set),
      );
      final _ = await tester.pumpAndSettle();

      await tester.tap(find.byType(Toggle));
      await tester.pump();
      expect(tester.widget<Toggle>(find.byType(Toggle)).value, isFalse);

      // The app moves the value later, in code — not the user's flip.
      setValue(true);
      await pumpToMidTravel(tester);

      expect(lensFinder(), findsNothing);
    });

    testWidgets('a disabled toggle gets no lens', (tester) async {
      var value = false;
      late StateSetter setOuter;
      await tester.pumpWidget(
        _buildApp(
          StatefulBuilder(
            builder: (context, setState) {
              setOuter = setState;
              return Toggle(onChanged: null, value: value, enabled: false);
            },
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      setOuter(() => value = true);
      await tester.pump();
      await tester.pump(
        CoreToggleStyle.defaultThumbTransitionDuration ~/ 2,
      );

      expect(lensFinder(), findsNothing);
    });

    /// Resolves the toggle in a real tree, under [toggleStyle].
    Future<ResolvedToggle> resolveUnder(
      WidgetTester tester,
      CoreToggleStyle? toggleStyle,
    ) async {
      late ResolvedToggle resolved;
      await tester.pumpWidget(
        _buildApp(
          Builder(
            builder: (context) {
              resolved = resolveToggle(
                context,
                variant: CoreToggleVariant.defaultVariant,
                size: CoreComponentSize.md,
                toggleStyle: toggleStyle,
              );
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      return resolved;
    }

    testWidgets('the envelope follows the fade fraction of the style', (
      tester,
    ) async {
      final standard = (await resolveUnder(tester, null)).lensEnvelope;
      // In over the first quarter, held, out over the last.
      expect(standard.transform(0), CoreOpacity.opacity0);
      expect(
        standard.transform(CoreToggleStyle.defaultLensFadeFraction / 2),
        closeTo(0.5, 1e-9),
      );
      expect(standard.transform(0.5), CoreOpacity.opacity100);
      expect(standard.transform(1), CoreOpacity.opacity0);

      final quick = (await resolveUnder(
        tester,
        const CoreToggleStyle(lensFadeFraction: 0.1),
      )).lensEnvelope;
      // Already fully shown where the default is still fading in.
      expect(quick.transform(0.15), CoreOpacity.opacity100);
      expect(standard.transform(0.15), lessThan(CoreOpacity.opacity100));

      // `0` holds the whole travel; past the bound it clamps to no hold.
      final held = (await resolveUnder(
        tester,
        const CoreToggleStyle(lensFadeFraction: 0),
      )).lensEnvelope;
      expect(held.transform(0), CoreOpacity.opacity100);
      expect(held.transform(1), CoreOpacity.opacity100);
      final clamped = (await resolveUnder(
        tester,
        const CoreToggleStyle(lensFadeFraction: 0.9),
      )).lensEnvelope;
      expect(clamped.transform(CoreToggleStyle.maxLensFadeFraction), 1);
      expect(clamped.transform(CoreToggleStyle.maxLensFadeFraction / 2), 0.5);
    });

    testWidgets('the lens chrome is the Core slot, sized by the outset', (
      tester,
    ) async {
      const tint = CoreColor.token(CoreColors.primary);
      final resolved = await resolveUnder(
        tester,
        const CoreToggleStyle(
          lensContainerStyle: CoreOutlinedContainerStyle(
            backgroundColor: tint,
            // The size is the outset's to state, not the slot's.
            width: 999,
          ),
        ),
      );
      final lens = resolved.lensContainerStyle;
      expect(lens.backgroundColor, tint);
      // The rest of the slot stays the design default — a pill, no cast.
      const standard = CoreToggleStyle.defaultLensContainerStyle;
      expect(lens.borderRadius, standard.borderRadius);
      expect(lens.boxShadow, standard.boxShadow);
      expect(lens.borderStyle, standard.borderStyle);
      const outset = CoreToggleStyle.defaultLensOutset;
      final md = CoreToggleStyle.sizeDefaults(CoreComponentSize.md);
      expect(lens.width, md.thumbSize! + outset.left + outset.right);
      expect(lens.height, md.thumbSize! + outset.top + outset.bottom);

      // Untouched, the lens wears the default slot exactly.
      final plain = (await resolveUnder(tester, null)).lensContainerStyle;
      expect(
        plain,
        standard.copyWith(width: lens.width, height: lens.height),
      );
    });
  });
}
