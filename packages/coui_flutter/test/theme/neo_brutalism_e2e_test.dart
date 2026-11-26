import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/clickable_feedback.dart';

/// Upper bound for "capped small" corners in the widget-list assertion
/// below — generous headroom above `CoreRadius.radius6` (today's cap)
/// so a ring standoff grown on top of a capped `circleBorderRadius`
/// (`focus_outline_circle_radius_test.dart`) still reads as "capped",
/// while staying far enough under `CoreRadius.radius9999` that a
/// genuinely-preserved pill can never be mistaken for a capped corner.
const double _kCappedRadiusHeadroom = 20;

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  CoreSurfaceStyleId style = CoreSurfaceStyleId.neoBrutalism,
}) => tester.pumpWidget(
  CoUIApp(
    theme: ThemeData.fromCore(CoreThemePresets.light),
    surfaceStyle: style,
    home: Center(child: child),
  ),
);

Iterable<BoxDecoration> _decorations(WidgetTester tester) => tester
    .widgetList<DecoratedBox>(find.byType(DecoratedBox))
    .map((d) => d.decoration)
    .whereType<BoxDecoration>();

double? _maxCorner(BorderRadiusGeometry? radius) {
  if (radius is! BorderRadius) return null;

  return [
    radius.topLeft.x,
    radius.topRight.x,
    radius.bottomLeft.x,
    radius.bottomRight.x,
  ].reduce((a, b) => a > b ? a : b);
}

void main() {
  group('selecting the style changes what is painted', () {
    testWidgets('corners cap small across composed and self-drawn boxes', (
      tester,
    ) async {
      // Card composes the shared primitive; Badge paints its own box. A
      // style that reached only one of them would be the hybrid screen the
      // acceptance gate calls a regression rather than a partial success.
      //
      // Badge / Range default to a full pill (`radius9999`), which a
      // nonzero cap leaves alone by design — "a range leaves a pill
      // alone" (`surface_radius_range_test.dart`), the same sentinel
      // check that made squaring at the old `radiusCap: 0` "different in
      // kind" from every other cap. The assertion below accepts either
      // outcome rather than asserting per widget which one applies, so it
      // keeps working if a widget's own default ever changes shape.
      //
      // Range's own focus ring (`FocusOutline` around its thumb) is the
      // one shape here that isn't cleanly one or the other: its capped
      // `circleBorderRadius` legitimately grows by the ring's standoff
      // distance before it paints (a ring drawn *outside* a small-radius
      // shape needs a slightly larger outer radius to stay a consistent
      // ring — `focus_outline_circle_radius_test.dart` covers that math
      // precisely). So "capped" here means "small, not the raw pill
      // sentinel" — `_kCappedRadiusHeadroom`, not the bare cap value —
      // rather than an exact `<= CoreRadius.radius6`.
      //
      // Loading's `.pulse` dot is the pill case once removed: its raw
      // `geometry.radius(9999)` is the same preserved sentinel, but the
      // widget then clamps that to its own half-extent to paint a true
      // circle rather than a literal `9999`-radius corner — so its
      // painted number is neither "capped small" nor "reads as the
      // sentinel," even though it is the identical "stayed round"
      // outcome under the hood. Checked separately below instead of
      // forcing it through the same numeric bound as the others.
      for (final widget in <Widget>[
        const Card(child: SizedBox(width: 80, height: 40)),
        const Badge(child: Text('9')),
        const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
        // Range's default radius resolver skipped the design-system
        // default fallback entirely (`merged.borderRadius?.toValue(...)`,
        // no `?? CoreRangeStyle.defaultBorderRadius`), so the un-overridden
        // path left `ResolvedRange.borderRadius` null and the widget
        // re-derived its own un-geometried `circular(trackH / 2)` /
        // `BoxShape.circle` fallback shape instead — never reaching
        // `theme.geometry` at all in the (most common) default case.
        const Range(),
        // Tracker's `endRadius` was a plain `(merged ?? default) * scaling`
        // scalar with no `theme.geometry.borderRadius(...)` call at all —
        // radius full-bypass, the same shape as Range above but on a
        // segment fill `Container` instead of a track/thumb.
        const Tracker(segments: [CoreTrackerSegment(status: .fine)]),
        // TextBlock's `inlineCodeRadius` (the `.pre` preformatted-text
        // surface box) was the same `(merged ?? default) * scaling` shape
        // with no `theme.geometry.radius(...)` call.
        const TextBlock(text: 'code', element: .pre),
      ]) {
        await _pump(tester, widget);
        final rounded = _decorations(
          tester,
        ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

        expect(rounded, isNotEmpty, reason: '$widget painted no radius');
        expect(
          rounded.every(
            (r) => r <= _kCappedRadiusHeadroom || r >= CoreRadius.radius9999,
          ),
          isTrue,
          reason: '$widget kept a corner neither capped nor a pill: $rounded',
        );
      }

      // Loading's `.pulse` dot — see the comment above the widget list.
      // `cornerRadius` (dots/pulse/bar variants) used to be a plain
      // `(merged ?? default) * scaling` scalar with no geometry call at
      // all — a full bypass, the same historical bug as Range/Tracker
      // above. Its own half-extent clamp means the *numeric* corner
      // cannot distinguish "geometry ran and preserved the pill" from
      // "geometry never ran" the way it could when `radiusCap` was `0`
      // (which forced a literal, unambiguous `0`) — both now clamp down
      // to the same small circle. So this only re-asserts "painted a
      // nonzero, i.e. not force-squared, corner"; the numeric-bound
      // regression coverage for the other six widgets above is the load-
      // bearing check for "geometry reached the paint site at all".
      await _pump(tester, const Loading(variant: .pulse));
      final loadingCorners = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();
      expect(loadingCorners, isNotEmpty, reason: 'Loading painted no radius');
      expect(
        loadingCorners.every((r) => r > 0),
        isTrue,
        reason: 'Loading painted a squared-off corner: $loadingCorners',
      );
    });

    testWidgets('a drawn border reaches the style floor', (tester) async {
      await _pump(
        tester,
        const OutlinedContainer(child: SizedBox(width: 40, height: 40)),
      );

      final widths = _decorations(
        tester,
      ).map((d) => d.border?.top.width).whereType<double>().where((w) => w > 0);

      expect(widths, isNotEmpty);
      expect(
        widths.every((w) => w >= CoreStrokeWidth.stroke4),
        isTrue,
        reason: 'a border stayed under the floor: $widths',
      );
    });

    testWidgets(
      'a self-drawn border reaches the floor too '
      '(Command, Kbd, Button, ColorPicker, MultipleChoice, PhoneInput, '
      'Stepper, DraggablePanel, TabPane, WindowPanel, Menubar, '
      'ValidationBadge, DotIndicator, ModalContainer, Drawer, Alert — '
      'bypass OutlinedContainer; MockupDevice, MockupBrowser (web page and '
      'app-window compositions), Avatar now compose it (#4362) '
      'and are kept here as composition-reaches-the-floor coverage)',
      (tester) async {
        // Command paints its own palette `Border.all` directly in
        // `command.dart` rather than composing `OutlinedContainer`, Kbd
        // draws each key cap's own `Border.all` (its width is the
        // `keyBorderWidth` slot, drawn while a visible colour is stated —
        // see the note on Kbd below), and Button's own
        // `borderWidth` local skipped the geometry seat its sibling
        // `borderRadius`/`boxShadow` already used two lines away — all
        // three are exactly the shape of component the E3 epic's coverage
        // (Card/Badge/OutlinedContainer above) did not reach, and the
        // regression this acceptance gate exists to catch: a resolver that
        // never calls `theme.geometry.stroke(...)` leaves its border under
        // the floor no matter what the preset states. Button matters
        // beyond itself — ColorPicker/Menubar/Toast/Alert/Drawer all
        // compose it for an action/trigger/dismiss affordance, so this
        // one fix reaches every one of them too.
        //
        // ColorPicker's trigger swatch had no `borderWidth` field at all
        // (same shape as Kbd); MultipleChoice's `optionBorderWidth` was a
        // raw scaled scalar with no `theme.geometry.stroke(...)` call
        // (same shape as Command, sibling `optionBorderRadius` wired,
        // adjacent width not); PhoneInput's outer container width was a
        // plain `?? default` fallback with no geometry call at all.
        //
        // Stepper's indicator border (only painted when a colour/width
        // override is explicitly given), DraggablePanel's floating-panel
        // border, TabPane's boxed-tab/content-panel border, WindowPanel's
        // own outer frame border, and Menubar's outer bar border are all
        // the same partial/full-bypass shapes on their own surface
        // boundary (not a delegated child / focus ring / ephemeral
        // overlay).
        //
        // ValidationBadge hardcoded (or omitted entirely) its own
        // container border width with no `CoreXxxStyle` slot to even
        // reach (same shape as Kbd).
        //
        // DotIndicator's `inactiveBorderWidth` was a raw `merged ??
        // default` scalar with no `theme.geometry.stroke(...)` call
        // (same partial-bypass shape as Command/MultipleChoice).
        //
        // MockupDevice / MockupBrowser / MockupWindow / Avatar used to be
        // in this same self-drawn-bypass shape (Avatar's decorative `ring`
        // width skipped the geometry seat its sibling `borderRadius`
        // already used; the three mockups had no `borderWidth` slot at all,
        // same shape as Kbd) — #4362 composed `OutlinedContainer` for all
        // of them, so the floor is now reached through that primitive's own
        // `theme.geometry.stroke(...)` call rather than a bypass fix here.
        // Kept in the widget list below as regression coverage that
        // composition still reaches the floor.
        //
        // ModalContainer had no override slot reachable through geometry
        // at all (same shape as Kbd — a raw `double?` ctor param with an
        // ungeometried literal default). Drawer's / Alert's
        // `panelBorderWidth`/`borderWidth` were the same partial-bypass
        // shape as Command — each has a sibling `borderRadius` two lines
        // away that is wired, the width is not.
        //
        // ── CodeDiff is NOT in this list, and that is the decision ──────
        //
        // Its block states no border: `defaultBorderWidth` is `stroke0` and
        // `defaultOutlineColor` is transparent, so the block is told apart
        // from the page by its `surfaceContainerLow` face. A floor raises a
        // width that is already being painted, and zero is not a thin
        // border but the absence of one — leaving CodeDiff here would assert
        // a boundary the component never draws. Accepted on both platforms:
        // CodeDiff is unboxed under this preset on Flutter and on Web alike,
        // the same absence rather than a boxed Flutter beside an unboxed
        // Web.
        //
        // ── Kbd is in this list with a stated edge, and that is the decision ─
        //
        // The list checks a key cap that states its edge colour explicitly,
        // so the check does not depend on the default. The default key's
        // hairline under this preset is asserted separately, below.
        //
        // ── ValidationBadge is in this list with a stated width ─────────
        //
        // Its default border is `stroke0` — the badge states itself with a
        // fill, a glyph and a label, and a floor does not lift a zero. The
        // list keeps a badge that states a width, so what it checks is that
        // a border the badge does draw is raised to the floor.
        //
        // ── Toast is NOT in this list, and that is the decision ─────────
        //
        // Its panel states no border at all: `defaultPanelBorderWidth` is
        // `stroke0`, because a hairline in the fill's own colour was
        // invisible and a hairline in any other colour is not the design.
        // A floor cannot lift that — it raises a width that is already
        // being painted, and zero is not a thin border but the absence of
        // one. Leaving Toast here would assert a boundary the component
        // never draws, and the only way to satisfy it would be to give
        // Toast a border the designer removed on purpose.
        //
        // What carries the boundary instead, measured off the preset
        // snapshot baselines rather than argued:
        //
        //   neoBrutalism · toast panel   fill rgb(24,25,27)  a=1.0
        //   neoBrutalism · page ground   fill rgb(252,252,253)
        //
        // An opaque near-black panel on a near-white page. The fill edge
        // IS the boundary, and it is a stronger one than a 4px stroke —
        // which is why the same measurement is the reason the border was
        // dropped, not an excuse found afterwards.
        //
        // Alert stays. It looks like the same case and is not: the same
        // baselines read `border.top.w` of **4.0** on its panel under this
        // preset (and 0.0 under `defaultStyle`), so the floor does reach
        // it and this gate still has something to check. The two were
        // changed by the same sweep, which is exactly why the exclusion is
        // decided per surface off the rendered value instead of by
        // reasoning from the sweep.
        for (final widget in <Widget>[
          Command(
            onSelect: (_) {},
            groups: const [
              CoreCommandGroup(
                items: [CoreCommandItem(value: 'cmd', label: 'Command')],
              ),
            ],
          ),
          const Kbd(
            keys: ['Ctrl'],
            kbdStyle: CoreKbdStyle(
              keyBorderColor: CoreColor.token(CoreColors.outline),
            ),
          ),
          Button(
            variant: .outline,
            onPressed: () {},
            child: const Text('x'),
          ),
          const ColorPicker(color: Color(0xFFFF0000)),
          const MultipleChoice<String>(
            options: [(value: 'a', label: 'A')],
          ),
          const PhoneInput(),
          const Stepper(
            steps: [CoreStepItem(label: 'Step 1')],
            stepperStyle: CoreStepperStyle(indicatorBorderWidth: 1),
          ),
          DraggablePanel(
            controller: CoreDraggablePanelController(initiallyOpen: true),
            panel: const SizedBox(width: 80, height: 80),
          ),
          const TabPane(
            tabs: [
              CoreTabItem(label: 'Tab 1', content: Text('Content')),
            ],
            selectedIndex: 0,
          ),
          const WindowPanel(),
          const Menubar(
            menus: [
              CoreMenubarMenu(
                label: 'File',
                entries: [CoreMenubarEntry.action(label: 'Open')],
              ),
            ],
          ),
          const ValidationBadge(
            label: 'Valid',
            state: CoreValidationState.valid,
            style: CoreValidationBadgeStyle(
              borderWidth: CoreStrokeWidth.stroke1,
            ),
          ),
          const MockupDevice(
            width: 100,
            child: SizedBox(width: 40, height: 80),
          ),
          const MockupBrowser(
            addressBar: 'https://example.com',
            child: SizedBox(width: 80, height: 40),
          ),
          const Avatar(initials: 'AB', ring: true),
          // The app-window composition — controls only, no address bar —
          // is what `MockupWindow` used to draw.
          const MockupBrowser(
            addressBar: null,
            child: SizedBox(width: 40, height: 40),
          ),
          const DotIndicator(index: 0, length: 3),
          const ModalContainer(
            borderColor: Color(0xFF000000),
            child: SizedBox(width: 40, height: 40),
          ),
          const Drawer(content: Text('content')),
          // Toast is deliberately absent — see the note above the list.
          const Alert(title: 'described'),
        ]) {
          await _pump(tester, widget);
          // The widest edge, not the top one: a side panel draws its line on
          // the inner edge only.
          final widths = _decorations(tester)
              .map((d) {
                final border = d.border;
                if (border is! Border) return null;

                return [
                  border.top.width,
                  border.right.width,
                  border.bottom.width,
                  border.left.width,
                ].reduce((a, b) => a > b ? a : b);
              })
              .whereType<double>()
              .where((w) => w > 0);

          expect(widths, isNotEmpty, reason: '$widget painted no border');
          expect(
            widths.every((w) => w >= CoreStrokeWidth.stroke4),
            isTrue,
            reason: '$widget kept a border under the floor: $widths',
          );
        }
      },
    );

    testWidgets(
      "a key cap's default hairline is lifted, and no cast is added",
      (
        tester,
      ) async {
        // The default edge is the drawn hairline, so the preset's stroke floor
        // lifts it like any other stroke. The surface style still contributes
        // no cast — a key cap is flat by design.
        await _pump(tester, const Kbd(keys: ['Ctrl']));

        final widths =
            _decorations(
                  tester,
                )
                .map((d) => d.border?.top.width)
                .whereType<double>()
                .where((w) => w > 0);
        expect(widths, isNotEmpty, reason: 'a default key cap drew no edge');
        expect(widths.every((w) => w > CoreStrokeWidth.stroke0_5), isTrue);

        final keyShadows = _decorations(
          tester,
        ).expand((d) => d.boxShadow ?? const <BoxShadow>[]);
        expect(keyShadows, isEmpty);
      },
    );

    testWidgets('the boundary colour is pushed toward the foreground', (
      tester,
    ) async {
      late CoreColorScheme scheme;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              scheme = Theme.of(context).colorScheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      // What the pumped theme authored before the style bent it — the same
      // scheme `CoreThemePresets.light` carries.
      final authored = CouiColorPresets.source.light().resolved(.light);

      // Both boundary tones move: the subtler one carries the shared
      // primitive's border and is the only boundary token 13 components
      // reference.
      expect(scheme.outline, isNot(equals(authored.outline)));
      expect(scheme.outlineVariant, isNot(equals(authored.outlineVariant)));
      expect(scheme.outline!.red, lessThan(authored.outline.red));
    });
  });

  group('the default surface is unaffected', () {
    testWidgets('selecting nothing paints the original chrome', (tester) async {
      // The regression that matters most: every app that never opts in has
      // to render exactly as it did before this preset existed.
      await _pump(
        tester,
        const Card(child: SizedBox(width: 80, height: 40)),
        style: CoreSurfaceStyleId.defaultStyle,
      );

      final rounded = _decorations(
        tester,
      ).map((d) => _maxCorner(d.borderRadius)).whereType<double>();

      expect(rounded, isNotEmpty);
      expect(rounded.any((r) => r > 0), isTrue);
    });
  });

  group('the signature shadow is cast hard', () {
    testWidgets('a painted shadow loses its blur and is thrown further', (
      tester,
    ) async {
      await _pump(
        tester,
        const Card(
          cardStyle: CoreCardStyle(elevation: CoreCardElevation.medium),
          child: SizedBox(width: 80, height: 40),
        ),
      );

      final shadows = _decorations(
        tester,
      ).expand((d) => d.boxShadow ?? const <BoxShadow>[]);

      expect(shadows, isNotEmpty, reason: 'nothing painted a shadow');
      expect(
        shadows.every((s) => s.blurRadius == 0),
        isTrue,
        reason: 'a layer kept its blur: ${shadows.map((s) => s.blurRadius)}',
      );
      expect(
        shadows.any((s) => s.offset.dy.abs() > 0),
        isTrue,
        reason: 'the cast collapsed to nothing',
      );
    });

    testWidgets('the default surface keeps its soft cast', (tester) async {
      await _pump(
        tester,
        const Card(
          cardStyle: CoreCardStyle(elevation: CoreCardElevation.medium),
          child: SizedBox(width: 80, height: 40),
        ),
        style: CoreSurfaceStyleId.defaultStyle,
      );

      final shadows = _decorations(
        tester,
      ).expand((d) => d.boxShadow ?? const <BoxShadow>[]);

      expect(shadows, isNotEmpty);
      expect(shadows.any((s) => s.blurRadius > 0), isTrue);
    });
  });

  group('type is set heavier', () {
    testWidgets('body weight reaches the floor and headings keep theirs', (
      tester,
    ) async {
      late CoreTypography typography;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: Builder(
            builder: (context) {
              typography = Theme.of(context).typography;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(typography.bodyMedium.fontWeight, CoreFontWeight.semiBold);
      expect(
        typography.titleLarge.fontWeight,
        CoreTypography.coui.titleLarge.fontWeight,
        reason: 'a role already heavy should keep its own weight',
      );
    });

    testWidgets('the default surface keeps the authored scale', (tester) async {
      late CoreTypography typography;
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          home: Builder(
            builder: (context) {
              typography = Theme.of(context).typography;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(
        typography.bodyMedium.fontWeight,
        CoreTypography.coui.bodyMedium.fontWeight,
      );
    });
  });

  group('the press-squash affordance is one clock, not two', () {
    // The shadow-hide (paired with `Clickable.pressedTranslate`) used to
    // live inside Button's own per-state `AnimatedContainer`, which
    // animates on `resolved.animationDuration` (`CoreDuration.fast`,
    // 150ms) — a different clock than the 50ms `pressDuration` the
    // translate uses. Two animations on separate clocks is exactly the
    // drift `Clickable`'s own pressedTranslate/pressedBoxShadow doc
    // comment warns against for its own pair. These two checks pin the
    // fix at the widget-configuration level (not by pumping partial
    // animation frames, which would be timing-fragile) — a regression
    // here means the numbers this test reads drift apart again, not
    // that a screenshot looks slightly different.
    testWidgets(
      'the shadow wrapper animates on the press clock, not the chrome clock',
      (tester) async {
        await _pump(
          tester,
          const Button(enableFeedback: true, child: Text('Primary')),
        );

        // The cast moved out of a decoration and onto `InjectedCast`,
        // which paints it outside the box the way CSS does — a
        // decoration would fill under the button and show through its
        // 80%-alpha hover fill. The clock it animates on is the point of
        // this test and is unchanged.
        final shadowContainer = tester
            .widgetList<InjectedCast>(find.byType(InjectedCast))
            .where((c) => c.shadows.isNotEmpty)
            .single;

        expect(
          shadowContainer.duration,
          const Duration(milliseconds: CoreDuration.ms50),
          reason:
              'the shadow must animate on the same clock as '
              "Clickable's translate — not the chrome-transition clock "
              "(150ms) the button's own colour/border container uses",
        );
      },
    );

    testWidgets('the scale-shrink is pinned off when the shift carries the '
        'press signal', (tester) async {
      // `onPressed` is required for `enabled` to default `true` (nullable
      // + callback-derived, `cross-platform/api.md`) — an unwired button
      // never enters the pressed state a held gesture is meant to reach.
      await _pump(
        tester,
        Button(
          enableFeedback: true,
          onPressed: () {},
          child: const Text('Primary'),
        ),
      );

      // The painted scale is the visual result for the current state, and
      // the widget only asks for the shrink while genuinely pressed
      // (`_pressed && enableFeedback`, `co_button.dart`) — so the check
      // needs a held gesture, not a rest-state read (at rest the target
      // is always `1.0` regardless of what `pressedScale` states, which
      // would make this pass for the wrong reason).
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(() async {
        await gesture.up();
      });
      await tester.pumpAndSettle();

      final scale = clickableFeedback(tester).single;
      expect(
        scale.scale,
        1.0,
        reason:
            'a simultaneous shrink would compound with the shift/fade '
            'and read as a different gesture than the Web `:active` '
            'twin, which has no scale step at all',
      );
    });

    testWidgets('the pin is conditional — a button with no signature shadow '
        'still shrinks on press', (tester) async {
      await _pump(
        tester,
        Button(
          enableFeedback: true,
          onPressed: () {},
          child: const Text('Primary'),
        ),
        style: CoreSurfaceStyleId.defaultId,
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Button)),
      );
      addTearDown(() async {
        await gesture.up();
      });
      await tester.pumpAndSettle();

      final scale = clickableFeedback(tester).single;
      expect(
        scale.scale,
        CoreHoverStyle.defaultScaleDownFactor,
        reason:
            'suppressing the shrink is specifically for a style whose '
            'shadow carries the press signal — every other style keeps '
            "Button's ordinary press-shrink feedback",
      );
    });

    testWidgets('a composing component with its own stated shadow squashes '
        'too — the affordance is not blanket-excluded for it', (
      tester,
    ) async {
      // `Fab` states `buttonStyle.boxShadow` itself (its own elevation)
      // rather than relying on the style's *injected* `controlShadow` —
      // the same style-wide `shadowOffsetAdd` still throws it diagonally
      // under neo-brutalism, so it should retreat by that same distance
      // on press, exactly like a plain `Button`.
      await _pump(tester, const Fab(trigger: Text('+')));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(Fab)),
      );
      addTearDown(() async {
        await gesture.up();
      });
      await tester.pumpAndSettle();

      final scale = clickableFeedback(tester).single;
      expect(
        scale.scale,
        1.0,
        reason:
            'the translate carries the press signal for this style, same '
            'as a plain Button — a compounding shrink is not wanted here '
            'either',
      );
    });
  });
}
