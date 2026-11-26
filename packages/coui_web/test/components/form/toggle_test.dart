import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/form/toggle/toggle.dart';
import 'package:coui_web/src/components/form/toggle/toggle_style.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<DomComponent> _doms(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// The one `<style>` a toggle renders — its scoped state-layer / ring rules.
String? _styleCss(ComponentTester tester) {
  final styles = _doms(tester).where((c) => c.tag == 'style');
  if (styles.isEmpty) return null;
  final raw = styles.single.children?.single;
  return raw is RawText ? raw.text : null;
}

DomComponent _track(ComponentTester tester) => _doms(
  tester,
).singleWhere((c) => c.attributes?['aria-hidden'] == 'true');

void main() {
  for (final enabled in [false, true]) {
    for (final value in [false, true]) {
      testComponents('thumb cast enabled=$enabled value=$value', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Toggle(
            value: value,
            enabled: enabled,
            onChanged: (_) {},
            toggleStyle: const CoreToggleStyle(thumbShadow: CoreShadow.sm),
          ),
        );
        final thumb = _doms(tester).singleWhere(
          (c) =>
              c.attributes?['data-state'] != null &&
              c.attributes?['aria-hidden'] == null,
        );
        expect(thumb.styles?.properties['box-shadow'], 'var(--shadow-sm)');
      });
    }
  }
  // The default cast is what carries the white off thumb's outline on a
  // light off track, so it reaches the markup without a caller asking —
  // through the shadow-strength variable, so dark mode strengthens it.
  testComponents('default thumb casts the faint default shadow', (
    tester,
  ) async {
    pumpWithTheme(tester, const Toggle());
    final thumb = _doms(tester).singleWhere(
      (c) =>
          c.attributes?['data-state'] != null &&
          c.attributes?['aria-hidden'] == null,
    );
    final shadow = thumb.styles?.properties['box-shadow'];
    expect(shadow, contains('calc(8% * var(--coui-shadow-strength, 1))'));
    expect(shadow, contains('calc(6% * var(--coui-shadow-strength, 1))'));
  });

  group('Toggle', () {
    testComponents('renders a track, and it is not a control', (tester) async {
      // The track is decoration: the composing `Clickable` root carries
      // role="switch" and every interaction. A `<button>` here would have
      // to be disarmed four times over (submit type, tab order, a11y tree,
      // pointer) to stop behaving like the control it is not.
      pumpWithTheme(tester, const Toggle());

      expect(find.tag('button'), findsNothing);

      final track = _doms(
        tester,
      ).where((c) => c.attributes?['aria-hidden'] == 'true');

      expect(track, isNotEmpty);
    });

    test('accepts custom id', () {
      const toggle = Toggle(id: 'toggle-1');
      expect(toggle.id, equals('toggle-1'));
    });

    testComponents('renders thumb span child', (tester) async {
      pumpWithTheme(tester, const Toggle());

      // Both the track and the thumb carry `data-state`, so identify the
      // thumb as the one that is not the track: the track is the piece
      // marked out of the a11y tree. Counting spans would not survive the
      // track becoming one, and it never verified anything the state check
      // below does not.
      final thumb = find
          .tag('span')
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (c) =>
                c.attributes?['data-state'] != null &&
                c.attributes?['aria-hidden'] == null,
          );

      expect(thumb, hasLength(1));
      expect(thumb.single.attributes?['data-state'], equals('unchecked'));
    });

    test('defaults to unchecked', () {
      const toggle = Toggle();
      expect(toggle.value, isFalse);
    });

    test('enabled defaults to null (effective state follows onChanged — '
        'Flutter parity)', () {
      // No explicit `enabled` resolves to `null`; the effective interactive
      // state then falls back to `onChanged != null` so a callback-less
      // toggle reads as disabled, matching Flutter `Toggle._enabled`.
      // Explicit `true`/`false` still force the state.
      expect(const Toggle().enabled, isNull);
      expect(const Toggle(enabled: true).enabled, isTrue);
      expect(const Toggle(enabled: false).enabled, isFalse);
    });

    test('copyWith preserves properties', () {
      const original = Toggle(
        value: true,
        enabled: false,
        id: 'toggle-orig',
      );

      final copy = original.copyWith(id: 'toggle-new');

      expect(copy.id, equals('toggle-new'));
      expect(copy.value, isTrue);
      expect(copy.enabled, isFalse);
    });

    test('copyWith changes value state', () {
      const original = Toggle();
      final copy = original.copyWith(value: true);

      expect(copy.value, isTrue);
    });

    // The read a screen reader makes: `role="switch"` carries the state a
    // person hears and the tab stop a keyboard finds. A toggle given no
    // callback has nothing to do when pressed, so it must not read as a live
    // control — the rendered attributes, not the getter, are what is checked.
    DomComponent switchOf(ComponentTester tester) => _doms(
      tester,
    ).singleWhere((c) => c.attributes?['role'] == 'switch');

    testComponents('with no callback it reads as disabled, off the tab order', (
      tester,
    ) async {
      pumpWithTheme(tester, const Toggle());

      final control = switchOf(tester);
      expect(control.attributes?['aria-disabled'], 'true');
      expect(control.attributes?['tabindex'], '-1');
    });

    testComponents('with a callback it reads as live and takes the tab stop', (
      tester,
    ) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}));

      final control = switchOf(tester);
      expect(control.attributes?.containsKey('aria-disabled'), isFalse);
      expect(control.attributes?['tabindex'], '0');
    });

    testComponents('an explicit enabled overrides the callback either way', (
      tester,
    ) async {
      pumpWithTheme(tester, Toggle(enabled: false, onChanged: (_) {}));
      expect(switchOf(tester).attributes?['aria-disabled'], 'true');

      pumpWithTheme(tester, const Toggle(enabled: true));
      expect(
        switchOf(tester).attributes?.containsKey('aria-disabled'),
        isFalse,
      );
    });

    testComponents('a disabled toggle states that on the control, not the '
        'decoration', (tester) async {
      // `disabled` is a form-control attribute, and the track is not one.
      // It was never read either — the disabled track colour is chosen in
      // Dart (`variantScale.disabled*Track`), not by a `:disabled` selector
      // — so it only ever described the markup inaccurately.
      pumpWithTheme(tester, const Toggle(enabled: false));

      final decoration = _doms(
        tester,
      ).where((c) => c.attributes?['aria-hidden'] == 'true');
      expect(decoration, isNotEmpty);
      for (final element in decoration) {
        expect(element.attributes?.containsKey('disabled'), isFalse);
        expect(element.attributes?.containsKey('tabindex'), isFalse);
      }
    });
  });

  // What the 2026-09 redesign draws — read back off the rendered DOM.
  group('Toggle redesign', () {
    // The disabled thumbs follow the enabled rule: the off thumb is fixed
    // white (no token class — painted inline), the on thumb is its track's
    // ink, `surface`.
    testComponents('the disabled off thumb is fixed white, the disabled '
        'on thumb stays surface', (tester) async {
      DomComponent thumb() => _doms(tester).singleWhere(
        (c) =>
            c.attributes?['data-state'] != null &&
            c.attributes?['aria-hidden'] == null,
      );

      pumpWithTheme(tester, const Toggle(enabled: false));
      expect(thumb().classes!.split(' '), isNot(contains(startsWith('bg-'))));
      expect(
        thumb().styles?.properties['background-color'],
        'rgb(255, 255, 255)',
      );

      pumpWithTheme(tester, const Toggle(enabled: false, value: true));
      expect(thumb().classes, contains('bg-${CoreColors.surface.name}'));
    });

    testComponents('disabled is said by the track — on and off take '
        'different tokens', (tester) async {
      pumpWithTheme(tester, const Toggle(enabled: false, value: true));
      expect(
        _track(tester).classes,
        contains('bg-${CoreColors.disabledContent.name}'),
      );
      // No scoped rules for a disabled toggle — nothing to wash toward and
      // nothing to focus.
      expect(_styleCss(tester), isNull);

      pumpWithTheme(tester, const Toggle(enabled: false));
      expect(
        _track(tester).classes,
        contains('bg-${CoreColors.disabledContainer.name}'),
      );
    });

    // The on thumb is the ink chosen to be read on its own track:
    // `onPrimary` on the primary on track. The off thumb is fixed white in
    // both modes — no scheme slot is, so it has no token class and is
    // painted inline. The off track is the highest container step.
    testComponents('the thumb is onPrimary on, fixed white off — and the off '
        'track is the highest container step', (tester) async {
      DomComponent thumb() => _doms(tester).singleWhere(
        (c) =>
            c.attributes?['data-state'] != null &&
            c.attributes?['aria-hidden'] == null,
      );

      pumpWithTheme(tester, Toggle(onChanged: (_) {}, value: true));
      expect(thumb().classes, contains('bg-${CoreColors.onPrimary.name}'));
      expect(thumb().classes, isNot(contains('bg-${CoreColors.surface.name}')));
      expect(_track(tester).classes, contains('bg-primary'));

      pumpWithTheme(tester, Toggle(onChanged: (_) {}));
      expect(thumb().classes!.split(' '), isNot(contains(startsWith('bg-'))));
      expect(
        thumb().styles?.properties['background-color'],
        'rgb(255, 255, 255)',
      );
      expect(
        _track(tester).classes,
        contains('bg-${CoreColors.surfaceContainerHighest.name}'),
      );
      // The negative control: the step below, `surfaceContainer`, must not be
      // what matched.
      expect(
        _track(tester).classes!.split(' '),
        isNot(contains('bg-${CoreColors.surfaceContainer.name}')),
      );
    });

    testComponents('hover / active wash the track with its own ink; the '
        'focus ring lands on the track, not the root', (tester) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}));

      final css = _styleCss(tester);
      expect(css, isNotNull);
      final rules = ResolvedToggleRules(scopeClass: '', css: css!);
      expect(
        rules.css,
        contains(':hover > :where(.co-toggle-content) > .$kToggleTrackMarker'),
      );
      expect(
        rules.css,
        contains(':active > :where(.co-toggle-content) > .$kToggleTrackMarker'),
      );
      expect(
        rules.css,
        contains(
          ':focus-visible > :where(.co-toggle-content) > .$kToggleTrackMarker',
        ),
      );
      // Off track: `onSurface` ink at 8% then 16% over the off track.
      expect(
        rules.css,
        contains(
          'color-mix(in srgb, rgb(var(--coui-${CoreColors.onSurface.name})) 8%',
        ),
      );
      expect(
        rules.css,
        contains(
          'color-mix(in srgb, '
          'rgb(var(--coui-${CoreColors.onSurface.name})) 16%',
        ),
      );
      // The ring is an outline on the track; the default band is
      // transparent, so the track's own resting box-shadow (the surface
      // rim) is left alone.
      expect(
        rules.css,
        contains(
          ':focus-visible > :where(.co-toggle-content) > '
          '.$kToggleTrackMarker{outline-color:',
        ),
      );
      expect(rules.css, isNot(contains('box-shadow')));
      expect(_track(tester).classes, contains(kToggleTrackMarker));

      // The root wears the scope class the rules select on, and no
      // utility ring of its own.
      final root = _doms(
        tester,
      ).singleWhere((c) => c.attributes?['role'] == 'switch');
      expect(root.classes, contains('co-toggle-sl-'));
      expect(root.classes, isNot(contains('focus-visible:ring')));
      expect(root.classes, isNot(contains('focus-visible:outline-')));
    });

    testComponents('the on track washes with surface ink', (tester) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}, value: true));
      expect(
        _styleCss(tester),
        contains(
          'color-mix(in srgb, rgb(var(--coui-${CoreColors.surface.name})) 8%',
        ),
      );
    });

    testComponents('label reads the size ladder — 13 / 14 / 15 / 15 / 15', (
      tester,
    ) async {
      const expected = {
        CoreComponentSize.sm: CoreTextStyles.bodySmall,
        CoreComponentSize.md: CoreTextStyles.bodyMedium,
        CoreComponentSize.lg: CoreTextStyles.bodyLarge,
        CoreComponentSize.xl: CoreTextStyles.bodyLarge,
        CoreComponentSize.xl2: CoreTextStyles.bodyLarge,
      };
      for (final entry in expected.entries) {
        pumpWithTheme(
          tester,
          Toggle(onChanged: (_) {}, size: entry.key, label: 'L'),
        );
        final wrapper = _doms(tester).singleWhere(
          (c) => c.classes?.contains('text-${entry.value.name}') ?? false,
        );
        expect(wrapper, isNotNull, reason: entry.key.name);
      }
    });

    // The picture the table describes: a track as wide as its height plus
    // 16, the thumb travelling the same 16 on every size. Read off the DOM
    // the resolver emits, so a row the resolver stops reading fails here.
    testComponents('the track is its height + 16 wide and the thumb travels '
        '16 — emitted at every size', (tester) async {
      const widths = {
        CoreComponentSize.sm: 32.0,
        CoreComponentSize.md: 36.0,
        CoreComponentSize.lg: 40.0,
        CoreComponentSize.xl: 44.0,
        CoreComponentSize.xl2: 48.0,
      };
      for (final entry in widths.entries) {
        final row = CoreToggleStyle.defaultsBySize[entry.key]!;
        pumpWithTheme(
          tester,
          Toggle(onChanged: (_) {}, value: true, size: entry.key),
        );
        final name = 'CoreComponentSize.${entry.key.name}';
        final raw = _track(tester).styles?.properties ?? const {};
        expect(raw['width'], '${entry.value / 16}rem', reason: '$name track');
        expect(
          raw['height'],
          '${row.trackHeight! / 16}rem',
          reason: '$name track height',
        );

        final thumb = _doms(tester).singleWhere(
          (c) =>
              c.attributes?['data-state'] != null &&
              c.attributes?['aria-hidden'] == null &&
              c.tag == 'span',
        );
        expect(
          thumb.styles?.properties['transform'],
          'translateX(1.0rem)', // 16px of travel, in rem
          reason: '$name thumb travel',
        );
      }
    });

    testComponents('xs has no row and draws the sm switch', (tester) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}, size: .xs));
      final sm = CoreToggleStyle.defaultsBySize[CoreComponentSize.sm]!;
      final raw = _track(tester).styles?.properties ?? const {};
      expect(raw['width'], '${sm.trackWidth! / 16}rem');
      expect(raw['height'], '${sm.trackHeight! / 16}rem');
    });
  });
  // The lens exists only while the thumb travels — read back off the DOM, so
  // a toggle that mounts it at rest (or never) fails here.
  group('Toggle transient lens', () {
    Iterable<DomComponent> lenses(ComponentTester tester) => _doms(
      tester,
    ).where((c) => c.classes?.contains(kWebSurfaceRoleFunctional) ?? false);

    Iterable<String> styleTexts(ComponentTester tester) => _doms(tester)
        .where((c) => c.tag == 'style')
        .map((c) => c.children?.single)
        .whereType<RawText>()
        .map((raw) => raw.text);

    // The resting markup, pinned. The lens may add a node while the thumb
    // travels and nothing else, so the switch at rest has to serialise to
    // exactly these strings — the same nodes, in the same order, with the
    // same classes, styles and attributes. A wrapper added "only to hold the
    // lens" fails here even though it draws nothing.
    for (final (label, value, pinned) in [
      ('off', false, _kRestingOffDom),
      ('on', true, _kRestingOnDom),
    ]) {
      testComponents(
        'the resting markup keeps the Core track dimensions ($label)',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            Toggle(onChanged: (_) {}, value: value, label: 'Wi-Fi'),
          );
          expect(_serialise(tester), pinned);
          expect(lenses(tester), isEmpty);
          expect(
            styleTexts(tester).any((css) => css.contains('@keyframes')),
            isFalse,
            reason: 'no lens keyframes in the resting markup',
          );
        },
      );
    }

    testComponents('mounts for one travel as a clear floating surface, then '
        'leaves', (tester) async {
      pumpWithTheme(tester, const _FlippingToggle());
      final resting = _serialise(tester);
      expect(lenses(tester), isEmpty);
      await tester.click(find.byType(Toggle));

      final lens = lenses(tester).single;
      expect(lens.attributes?['aria-hidden'], 'true');
      expect(lens.classes, contains(kWebSurfaceMarker));
      // Inside the flow, not positioned out of it — it is seated by its
      // margins, which is what lets the row keep its layout without a
      // wrapper around the track.
      expect(lens.classes, isNot(contains('absolute')));

      final md = CoreToggleStyle.sizeDefaults(CoreComponentSize.md);
      const outset = CoreToggleStyle.defaultLensOutset;
      final width = md.thumbSize! + outset.left + outset.right;
      final height = md.thumbSize! + outset.top + outset.bottom;
      final gap =
          md.iconLabelGapStyle?.size ??
          CoreToggleStyle.defaultIconLabelGapStyle.size!;
      final left = md.padding!.left - outset.left;
      final top = (md.trackHeight! - md.thumbSize!) / 2 - outset.top;
      final raw = lens.styles?.properties ?? const {};
      // Larger than the thumb and spilling past the track.
      expect(raw['width'], '${width / 16}rem');
      expect(raw['height'], '${height / 16}rem');
      expect(top, lessThan(0), reason: 'the capsule reaches past the track');
      // The four margins: seated over the track, footprint zero on both
      // axes — width + left + right cancels the row gap before it, and
      // height + top + bottom is nothing. The left margin walks back
      // across the row gap through the spacing variable the row's own
      // `gap` rides (the Flutter twin's `Gap` moves it with the density);
      // the rest is pinned.
      final margin = raw['margin']!;
      final walkBack = RegExp(
        r'calc\((-?[0-9.]+)rem - (var\(--coui-space-\d+\))\)$',
      ).firstMatch(margin);
      expect(walkBack, isNotNull, reason: margin);
      expect(walkBack!.group(2), spaceCss(gap));
      final [mt, mr, mb] = margin
          .substring(0, walkBack.start)
          .trim()
          .split(' ')
          .map((m) => double.parse(m.replaceAll('rem', '')) * 16)
          .toList();
      final ml = double.parse(walkBack.group(1)!) * 16 - gap;
      expect(ml, left - md.trackWidth! - gap);
      expect(width + ml + mr, -gap);
      expect(height + mt + mb, 0);
      expect(mt, top - md.trackHeight! / 2);
      // Travels from the off pose to the on pose.
      expect(raw[kToggleLensFromVar], '${0 / 16}rem');
      expect(raw[kToggleLensToVar], '${md.thumbOffset! / 16}rem');
      // Invisible outside its animation — a zero-length run never shows it.
      expect(raw['opacity'], '${CoreOpacity.opacity0}');
      expect(raw['animation'], isNot(contains(kToggleLensTravelKeyframes)));
      expect(lens.id, startsWith('co-toggle-thumb-'));
      final envelopeName = toggleLensEnvelopeKeyframes(
        CoreToggleStyle.defaultLensFadeFraction,
      );
      expect(raw['animation'], contains(envelopeName));
      expect(raw['animation'], contains('var(--coui-duration-'));
      // Its keyframes ride inside it, so they leave with it.
      final keyframes = lens.children?.whereType<DomComponent>().single;
      expect(keyframes?.tag, 'style');
      expect(
        (keyframes?.children?.single as RawText?)?.text,
        isNot(contains('@keyframes $kToggleLensTravelKeyframes')),
      );
      // The envelope's stops come from the Core fraction the Flutter twin
      // weights its envelope by — in, held, out at the same moments — under
      // the name the lens's `animation` names.
      expect(
        (keyframes?.children?.single as RawText?)?.text,
        allOf(
          contains('@keyframes $envelopeName{'),
          contains('${CoreToggleStyle.defaultLensFadeFraction * 100}%'),
          contains('${(1 - CoreToggleStyle.defaultLensFadeFraction) * 100}%'),
        ),
      );
      // The default chrome slot, written inline: a clear pill that casts
      // nothing and draws no stroke.
      expect(raw['background-color'], CoreColor.transparent.toValue());
      expect(raw['box-shadow'], 'none');
      expect(raw['border-style'], 'none');

      await Future<void>.delayed(
        CoreToggleStyle.defaultThumbTransitionDuration * 2,
      );
      await tester.pump();
      expect(lenses(tester), isEmpty);
      // Back at rest, the markup is the resting markup of the other pose —
      // the lens left nothing behind.
      expect(_serialise(tester), isNot(resting));
      expect(
        _serialise(tester).contains(kWebSurfaceRoleFunctional),
        isFalse,
      );
    });

    testComponents('a value the app sets in code moves with no lens', (
      tester,
    ) async {
      late CoreValueChanged<bool> setValue;
      pumpWithTheme(tester, _HostedToggle(onHost: (set) => setValue = set));

      setValue(true);
      await tester.pump();

      // The flip itself landed — only the lens stayed away.
      expect(
        _doms(tester).where((c) => c.attributes?['aria-checked'] == 'true'),
        isNotEmpty,
      );
      expect(lenses(tester), isEmpty);
    });

    testComponents('a keyboard flip rides the lens like a click', (
      tester,
    ) async {
      pumpWithTheme(tester, const _FlippingToggle());
      // Space and Enter reach the toggle through the composing Clickable's
      // `onPressed` — the same call a click makes. The live keydown cannot
      // be dispatched on the VM (`KeyboardEvent.key` throws outside a
      // browser; see `clickable_key_press_test.dart`), so the activation
      // the keydown handler invokes is invoked here.
      final clickable =
          find.byType(Clickable).evaluate().single.component as Clickable;
      clickable.onPressed!();
      await tester.pump();

      expect(lenses(tester), hasLength(1));
    });

    testComponents('a flip the host ignores leaves no mark for a later change '
        'in code', (tester) async {
      late CoreValueChanged<bool> setValue;
      pumpWithTheme(
        tester,
        _HostedToggle(ignoresFlip: true, onHost: (set) => setValue = set),
      );

      await tester.click(find.byType(Toggle));
      expect(
        _doms(tester).where((c) => c.attributes?['aria-checked'] == 'false'),
        isNotEmpty,
      );

      // The app moves the value later, in code — not the user's flip.
      setValue(true);
      await tester.pump();

      expect(lenses(tester), isEmpty);
    });

    testComponents('the envelope follows the fade fraction of the style', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _HostedToggle(
          onHost: (_) {},
          toggleStyle: const CoreToggleStyle(lensFadeFraction: 0.1),
        ),
      );
      await tester.click(find.byType(Toggle));

      final lens = lenses(tester).single;
      final name = toggleLensEnvelopeKeyframes(0.1);
      // Its own name — two toggles on different fractions can travel at
      // once without one envelope overwriting the other.
      expect(
        name,
        isNot(
          toggleLensEnvelopeKeyframes(CoreToggleStyle.defaultLensFadeFraction),
        ),
      );
      expect(lens.styles?.properties['animation'], contains(name));
      final css =
          (lens.children?.whereType<DomComponent>().single.children?.single
                  as RawText?)
              ?.text;
      expect(
        css,
        allOf(
          contains('@keyframes $name{'),
          contains('${0.1 * 100}%{opacity:${CoreOpacity.opacity100};}'),
          contains('${0.9 * 100}%{opacity:${CoreOpacity.opacity100};}'),
        ),
      );
    });

    testComponents('a zero fade holds the lens for the whole travel', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _HostedToggle(
          onHost: (_) {},
          toggleStyle: const CoreToggleStyle(lensFadeFraction: 0),
        ),
      );
      await tester.click(find.byType(Toggle));

      final css =
          (lenses(tester).single.children
                      ?.whereType<DomComponent>()
                      .single
                      .children
                      ?.single
                  as RawText?)
              ?.text;
      // Opaque at both ends — never a doubled stop that would cascade to
      // the later one and fade the lens out over the travel instead.
      expect(
        css,
        contains(
          '0%{opacity:${CoreOpacity.opacity100};} '
          '100%{opacity:${CoreOpacity.opacity100};}',
        ),
      );
      expect(css, isNot(contains('opacity:${CoreOpacity.opacity0}')));
    });

    testComponents('the lens chrome is the Core slot, sized by the outset', (
      tester,
    ) async {
      const tint = CoreColor.token(CoreColors.primary);
      pumpWithTheme(
        tester,
        _HostedToggle(
          onHost: (_) {},
          toggleStyle: const CoreToggleStyle(
            lensContainerStyle: CoreOutlinedContainerStyle(
              backgroundColor: tint,
              borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
              // The size is the outset's to state, not the slot's.
              width: 999,
            ),
          ),
        ),
      );
      await tester.click(find.byType(Toggle));

      final raw = lenses(tester).single.styles?.properties ?? const {};
      expect(raw['background-color'], tint.toValue());
      expect(
        raw['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius4).toValue(),
      );
      // The rest of the slot stays the design default — no cast, no stroke.
      expect(raw['box-shadow'], 'none');
      expect(raw['border-style'], 'none');
      final md = CoreToggleStyle.sizeDefaults(CoreComponentSize.md);
      const outset = CoreToggleStyle.defaultLensOutset;
      expect(
        raw['width'],
        '${(md.thumbSize! + outset.left + outset.right) / 16}rem',
      );
    });

    testComponents('a disabled toggle gets no lens', (tester) async {
      pumpWithTheme(tester, const _FlippingToggle(enabled: false));
      await tester.click(find.byType(_FlippingToggle));
      // The flip still happened — the host drives the value, not the
      // (disabled) control — and no lens came with it.
      expect(
        _doms(tester).where((c) => c.attributes?['aria-checked'] == 'true'),
        isNotEmpty,
      );
      expect(lenses(tester), isEmpty);
    });
  });
}

/// The DOM a test rendered, one node per line in tree order — tag, then
/// classes, inline styles and attributes with keys sorted, then raw text.
/// Everything a reader of the markup could tell apart.
String _serialise(ComponentTester tester) {
  String sorted(Map<String, String>? map) {
    if (map == null || map.isEmpty) return '';
    final keys = map.keys.toList()..sort();
    return keys.map((k) => '$k=${map[k]}').join(';');
  }

  final buffer = StringBuffer();
  for (final node in _doms(tester)) {
    buffer
      ..write('<${node.tag}')
      ..write(' class="${node.classes ?? ''}"')
      ..write(' style="${sorted(node.styles?.properties)}"')
      ..write(' attrs="${sorted(node.attributes)}"');
    for (final child in node.children ?? const <Component>[]) {
      if (child is RawText) buffer.write(' text="${child.text}"');
      if (child is Text) buffer.write(' text="${child.text}"');
    }
    buffer.write('>\n');
  }
  return buffer.toString();
}

const String _kRestingOffDom = '''
<div class="inline-flex max-w-full select-none cursor-pointer outline-none coui-clickable-press transition duration-100 coui-touch-target co-toggle-sl-bwxdj7" style="--coui-press-scale=0.97;border-radius=var(--coui-radius-4) var(--coui-radius-4) var(--coui-radius-4) var(--coui-radius-4);transition-timing-function=var(--easing-ease-in-out)" attrs="aria-checked=false;role=switch;tabindex=0">
<span class="co-toggle-content inline-flex items-center max-w-full min-w-0 text-body-medium" style="color=rgb(var(--coui-on-surface));gap=var(--coui-space-8)" attrs="">
<style class="" style="" attrs="" text=".co-toggle-sl-bwxdj7:hover > :where(.co-toggle-content) > .co-toggle-track:where(:not(.co-toggle-owned-fill)){background-color:color-mix(in srgb, rgb(var(--coui-on-surface)) 8%, rgb(var(--coui-surface-container-highest)));}.co-toggle-sl-bwxdj7:active > :where(.co-toggle-content) > .co-toggle-track:where(:not(.co-toggle-owned-fill)){background-color:color-mix(in srgb, rgb(var(--coui-on-surface)) 16%, rgb(var(--coui-surface-container-highest)));}.co-toggle-sl-bwxdj7 > :where(.co-toggle-content) > .co-toggle-track{outline-color:transparent;}:where(.co-toggle-sl-bwxdj7 > :where(.co-toggle-content) > .co-toggle-track){outline-style:solid;}.co-toggle-sl-bwxdj7:focus-visible > :where(.co-toggle-content) > .co-toggle-track{outline-color:rgb(var(--coui-focus-ring));outline-width:var(--coui-stroke-width-2);outline-offset:calc(4.0px - var(--coui-stroke-width-2));}">
<span class="co-toggle-track box-border peer inline-flex shrink-0 items-center bg-surface-container-highest coui-control-shadow-rest coui-surface coui-surface-content" style="--coui-surface-rgb=var(--coui-surface-container-highest);border-radius=var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999);height=1.25rem;padding=0.125rem 0.125rem 0.125rem 0.125rem;transition=background-color var(--coui-duration-100) var(--easing-ease-in-out);width=2.25rem" attrs="aria-hidden=true;data-state=unchecked">
<span class="pointer-events-none block ring-0" style="background-color=rgb(255, 255, 255);border-radius=var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999);box-shadow=0.0rem 0.0625rem 0.125rem 0.0rem color-mix(in srgb, rgb(var(--coui-shadow)) calc(8% * var(--coui-shadow-strength, 1)), transparent), 0.0rem 0.0rem 0.0625rem 0.0rem color-mix(in srgb, rgb(var(--coui-shadow)) calc(6% * var(--coui-shadow-strength, 1)), transparent);height=1.0rem;transform=translateX(0.0rem);transition=transform var(--coui-duration-100) var(--easing-ease-in-out);width=1.0rem" attrs="data-state=unchecked">
<span class="min-w-0" style="" attrs="">
<span class="text-inherit" style="" attrs="" text="Wi-Fi">
''';

const String _kRestingOnDom = '''
<div class="inline-flex max-w-full select-none cursor-pointer outline-none coui-clickable-press transition duration-100 coui-touch-target co-toggle-sl-3r16pe" style="--coui-press-scale=0.97;border-radius=var(--coui-radius-4) var(--coui-radius-4) var(--coui-radius-4) var(--coui-radius-4);transition-timing-function=var(--easing-ease-in-out)" attrs="aria-checked=true;role=switch;tabindex=0">
<span class="co-toggle-content inline-flex items-center max-w-full min-w-0 text-body-medium" style="color=rgb(var(--coui-on-surface));gap=var(--coui-space-8)" attrs="">
<style class="" style="" attrs="" text=".co-toggle-sl-3r16pe:hover > :where(.co-toggle-content) > .co-toggle-track:where(:not(.co-toggle-owned-fill)){background-color:color-mix(in srgb, rgb(var(--coui-surface)) 8%, rgb(var(--coui-primary)));}.co-toggle-sl-3r16pe:active > :where(.co-toggle-content) > .co-toggle-track:where(:not(.co-toggle-owned-fill)){background-color:color-mix(in srgb, rgb(var(--coui-surface)) 16%, rgb(var(--coui-primary)));}.co-toggle-sl-3r16pe > :where(.co-toggle-content) > .co-toggle-track{outline-color:transparent;}:where(.co-toggle-sl-3r16pe > :where(.co-toggle-content) > .co-toggle-track){outline-style:solid;}.co-toggle-sl-3r16pe:focus-visible > :where(.co-toggle-content) > .co-toggle-track{outline-color:rgb(var(--coui-focus-ring));outline-width:var(--coui-stroke-width-2);outline-offset:calc(4.0px - var(--coui-stroke-width-2));}">
<span class="co-toggle-track box-border peer inline-flex shrink-0 items-center bg-primary coui-control-shadow-rest coui-surface coui-surface-content" style="--coui-surface-rgb=var(--coui-primary);border-radius=var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999);height=1.25rem;padding=0.125rem 0.125rem 0.125rem 0.125rem;transition=background-color var(--coui-duration-100) var(--easing-ease-in-out);width=2.25rem" attrs="aria-hidden=true;data-state=checked">
<span class="pointer-events-none block ring-0 bg-on-primary" style="border-radius=var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999) var(--coui-radius-9999);box-shadow=0.0rem 0.0625rem 0.125rem 0.0rem color-mix(in srgb, rgb(var(--coui-shadow)) calc(8% * var(--coui-shadow-strength, 1)), transparent), 0.0rem 0.0rem 0.0625rem 0.0rem color-mix(in srgb, rgb(var(--coui-shadow)) calc(6% * var(--coui-shadow-strength, 1)), transparent);height=1.0rem;transform=translateX(1.0rem);transition=transform var(--coui-duration-100) var(--easing-ease-in-out);width=1.0rem" attrs="data-state=checked">
<span class="min-w-0" style="" attrs="">
<span class="text-inherit" style="" attrs="" text="Wi-Fi">
''';

/// A toggle whose value changes the way an app changes it — the same
/// element is updated in place, which is what a value flip looks like to
/// the toggle's state.
///
/// A disabled toggle does not report taps, so for [enabled] `false` the
/// host flips on its own the first time the button beside it is clicked.
class _FlippingToggle extends StatefulComponent {
  const _FlippingToggle({this.enabled = true});

  final bool enabled;

  @override
  State<_FlippingToggle> createState() => _FlippingToggleState();
}

class _FlippingToggleState extends State<_FlippingToggle> {
  bool _value = false;

  void _handleChanged(bool value) => setState(() => _value = value);

  @override
  Component build(BuildContext context) {
    return Component.element(
      tag: 'div',
      events: {
        if (!component.enabled) 'click': (_) => _handleChanged(!_value),
      },
      children: [
        Toggle(
          value: _value,
          enabled: component.enabled,
          onChanged: component.enabled ? _handleChanged : null,
        ),
      ],
    );
  }
}

/// A toggle whose host the test drives directly. [onHost] receives the
/// host's own setter — the way an app sets a value in code (a form reset, a
/// "turn all on"). With [ignoresFlip] the host reports nothing back to the
/// user's flip.
class _HostedToggle extends StatefulComponent {
  const _HostedToggle({
    required this.onHost,
    this.ignoresFlip = false,
    this.toggleStyle,
  });

  final void Function(CoreValueChanged<bool> setValue) onHost;
  final bool ignoresFlip;
  final CoreToggleStyle? toggleStyle;

  @override
  State<_HostedToggle> createState() => _HostedToggleState();
}

class _HostedToggleState extends State<_HostedToggle> {
  bool _value = false;

  void _handleValue(bool value) => setState(() => _value = value);

  @override
  void initState() {
    super.initState();
    component.onHost(_handleValue);
  }

  @override
  Component build(BuildContext context) {
    return Toggle(
      value: _value,
      onChanged: component.ignoresFlip ? (_) {} : _handleValue,
      toggleStyle: component.toggleStyle,
    );
  }
}
