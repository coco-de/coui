import 'package:coui_web/coui_web.dart';
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

/// A hard, offset stack — nothing like [CoreShadow.xs], so a test that reads
/// it back cannot be satisfied by the default.
const _kHard = <CoreShadowLayer>[
  (
    offsetX: 3,
    offsetY: 3,
    blurRadius: 0,
    spreadRadius: 0,
    opacity: 1,
    inset: false,
  ),
];

/// A key that states the xs stack itself — the default casts nothing, so a
/// test of how a stated stack goes out names it.
const _kXs = CoreKbdStyle(keyShadow: CoreShadow.xs);

/// A key that states a visible edge — the default has none, so a test of how
/// a drawn edge goes out names one.
const _kEdged = CoreKbdStyle(
  keyBorderColor: CoreColor.token(CoreColors.outlineSubtle),
);

ResolvedKbd _resolve(ComponentTester tester, {CoreKbdStyle? kbdStyle}) {
  late ResolvedKbd resolved;
  pumpWithTheme(
    tester,
    _ContextCapture((context) {
      resolved = resolveKbd(context, kbdStyle: kbdStyle);
    }),
  );
  return resolved;
}

/// The row that holds the keys — the only element laid out as a flex row.
DomComponent _root(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .firstWhere((c) => c.classes?.split(' ').contains('flex-row') ?? false);

String? _inline(WebElementChrome chrome, String property) =>
    chrome.inlineStyles?.properties[property];

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

void main() {
  group('Kbd key cap — chrome', () {
    testComponents(
      'a stated edge is the hairline variable, drawn as a border',
      (
        tester,
      ) async {
        final cap = _resolve(tester, kbdStyle: _kEdged).keyCap;

        expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0_5)');
        // A border, not an inset box-shadow: forced-colors mode recolours
        // borders and leaves shadows alone, so a shadow edge would vanish.
        expect(_classes(cap), contains('border'));
        expect(_inline(cap, 'box-shadow'), isNot(contains('inset')));
      },
    );

    testComponents('the default key draws the subtle hairline edge', (
      tester,
    ) async {
      // The default border colour is the visible `outlineSubtle`, so the key
      // cap takes room for the hairline edge. Rendered from the defaults.
      final cap = _resolve(tester).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0_5)');
      expect(_classes(cap), contains('border-outline-subtle'));
    });

    testComponents(
      'a transparent edge is not in the layout — no border, no width',
      (
        tester,
      ) async {
        // A border adds its width to the box even in a colour nobody can
        // see, and the docs site's reset sets `border-style: solid` on
        // everything, so an inline width on a transparent edge would still
        // take room. It goes out as 0, and without the `border` class.
        final cap = _resolve(
          tester,
          kbdStyle: const CoreKbdStyle(keyBorderColor: CoreColor.transparent),
        ).keyCap;

        expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0)');
        expect(_classes(cap), isNot(contains('border')));
      },
    );

    testComponents('the fold holds for a width the app states too', (
      tester,
    ) async {
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.transparent,
          keyBorderWidth: CoreStrokeWidth.stroke2,
        ),
      ).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0)');
    });

    testComponents('a raw opaque edge keeps its width and its border', (
      tester,
    ) async {
      // The negative control for the fold: `CoreColor.isTransparent` is true
      // of every colour that carries no token, so judging by it would drop an
      // opaque raw edge. The fold reads the alpha byte instead.
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyBorderColor: CoreColor(0xFF112233)),
      ).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0_5)');
      expect(_classes(cap), contains('border'));
    });

    testComponents('a token edge at opacity 0 folds like a transparent one', (
      tester,
    ) async {
      // A token is hidden by its opacity modifier, not by its alpha byte (an
      // unresolved token carries none). The Flutter twin folds the same edge
      // from the resolved alpha, so the cap is one box on both platforms.
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline, opacity: 0),
        ),
      ).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0)');
      expect(_classes(cap), isNot(contains('border')));
    });

    testComponents('a token edge at partial opacity keeps its width', (
      tester,
    ) async {
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline, opacity: 0.4),
        ),
      ).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-0_5)');
      expect(_classes(cap), contains('border'));
    });

    testComponents(
      'one verdict for every kind of edge — the fold is paintsNothing',
      (tester) async {
        // The cap asks the colour (`paintsNothing`) rather than restating the
        // question, so a colour the helper calls invisible folds and a colour
        // it calls visible keeps its width — raw or token, whatever the alpha.
        const edges = <String, CoreColor>{
          'the transparent sentinel': CoreColor.transparent,
          'a raw colour whose alpha byte is 0': CoreColor(0x00FF0000),
          'a raw colour at alpha 1': CoreColor(0x01FF0000),
          'a raw half-transparent colour': CoreColor(0x80112233),
          'a raw opaque colour': CoreColor(0xFF112233),
          'a token at opacity 0': CoreColor.token(
            CoreColors.outline,
            opacity: 0,
          ),
          'a token at opacity 0.01': CoreColor.token(
            CoreColors.outline,
            opacity: 0.01,
          ),
          'a token at full opacity': CoreColor.token(CoreColors.outline),
        };

        for (final MapEntry(key: kind, value: color) in edges.entries) {
          final cap = _resolve(
            tester,
            kbdStyle: CoreKbdStyle(
              keyBorderColor: color,
              keyBorderWidth: CoreStrokeWidth.stroke2,
            ),
          ).keyCap;

          expect(
            _inline(cap, 'border-width'),
            color.paintsNothing
                ? 'var(--coui-stroke-width-0)'
                : 'var(--coui-stroke-width-2)',
            reason: kind,
          );
          expect(
            _classes(cap).contains('border'),
            !color.paintsNothing,
            reason: kind,
          );
        }

        // The verdicts themselves, so the loop above cannot pass by agreeing
        // on the wrong answer for every row.
        expect(CoreColor.transparent.paintsNothing, isTrue);
        expect(const CoreColor(0x00FF0000).paintsNothing, isTrue);
        expect(const CoreColor(0x01FF0000).paintsNothing, isFalse);
        expect(
          const CoreColor.token(CoreColors.outline, opacity: 0).paintsNothing,
          isTrue,
        );
        expect(
          const CoreColor.token(CoreColors.outline).paintsNothing,
          isFalse,
        );
      },
    );

    testComponents('a visible edge draws the width it is given', (
      tester,
    ) async {
      // The fold takes the width away only from an edge nobody can see.
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(
          keyBorderColor: CoreColor.token(CoreColors.outline),
          keyBorderWidth: CoreStrokeWidth.stroke2,
        ),
      ).keyCap;

      expect(_inline(cap, 'border-width'), 'var(--coui-stroke-width-2)');
      expect(_classes(cap), contains('border'));
    });

    testComponents('padding is 2 down and 6 across; the floor is 18', (
      tester,
    ) async {
      final cap = _resolve(tester).keyCap;

      expect(
        _inline(cap, 'padding'),
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space6,
          vertical: CoreSpace.space2,
        ).toValue(),
      );
      const floor = 'calc(1.125rem + var(--coui-stroke-width-0_5) * 2)';
      expect(_inline(cap, 'min-width'), floor);
      expect(_inline(cap, 'min-height'), floor);
    });

    testComponents('the fill is the page face', (tester) async {
      final cap = _resolve(tester).keyCap;

      expect(_classes(cap), contains('bg-surface'));
      // The negative control: the former container fill.
      expect(_classes(cap), isNot(contains('bg-surface-container-highest')));
    });

    testComponents('a stated edge colour goes out as a border class', (
      tester,
    ) async {
      final cap = _resolve(tester, kbdStyle: _kEdged).keyCap;

      expect(_classes(cap), contains('border-outline-subtle'));
      expect(_classes(cap), isNot(contains('border-outline')));
    });
  });

  group('Kbd key cap — shadow', () {
    testComponents('a key casts nothing unless a style states a stack', (
      tester,
    ) async {
      final cap = _resolve(tester).keyCap;

      expect(_inline(cap, 'box-shadow'), isNull);
      expect(CoreKbdStyle.defaultKeyShadow, isEmpty);
    });

    testComponents('a stated xs stack goes out through its variable', (
      tester,
    ) async {
      final cap = _resolve(tester, kbdStyle: _kXs).keyCap;

      // `var(--shadow-xs)` rather than a baked literal, so a surface style
      // that re-points `--shadow-*` bends it.
      expect(_inline(cap, 'box-shadow'), startsWith('var(--shadow-xs)'));
    });

    testComponents("the surface style's rim rides the same declaration", (
      tester,
    ) async {
      // Naming the rim beside the shadow is how a surface opts in; the base
      // stylesheet declares it as a layer that draws nothing, so naming it
      // is safe under every style.
      final cap = _resolve(tester, kbdStyle: _kXs).keyCap;

      expect(
        _inline(cap, 'box-shadow'),
        'var(--shadow-xs), $kSurfaceRimVar',
      );
    });

    testComponents('a key that casts no shadow carries no rim', (tester) async {
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyShadow: CoreShadow.none),
      ).keyCap;

      expect(_inline(cap, 'box-shadow'), isNull);
    });

    testComponents('the shadow is on the key cap, not the row', (tester) async {
      final resolved = _resolve(tester, kbdStyle: _kXs);

      expect(_inline(resolved.keyCap, 'box-shadow'), isNotNull);
      expect(_inline(resolved.root, 'box-shadow'), isNull);
    });

    testComponents("the style's injected cast no longer rides the key", (
      tester,
    ) async {
      // The key authors its own shadow, so the style bends that instead of
      // contributing its cast: carrying the cast marker as well would paint
      // two shadows under a preset that injects one.
      final cap = _resolve(tester).keyCap;

      expect(_classes(cap), isNot(contains(kControlShadowRestMarker)));
    });

    testComponents('a stated stack replaces the default whole', (
      tester,
    ) async {
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyShadow: _kHard),
      ).keyCap;

      final shadow = _inline(cap, 'box-shadow');
      expect(shadow, isNot(startsWith('var(--shadow-xs)')));
      // Shadow geometry rides rem on the Web, like every other length.
      const offset = '${3 / 16}rem';
      expect(shadow, startsWith('$offset $offset'));
    });

    testComponents('an empty stack emits no shadow at all', (tester) async {
      final cap = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keyShadow: CoreShadow.none),
      ).keyCap;

      expect(_inline(cap, 'box-shadow'), isNull);
    });
  });

  group('Kbd — rendered', () {
    testComponents('one shadow per key, none on the row that holds them', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Kbd(keys: ['Ctrl', 'C'], kbdStyle: _kXs),
      );

      final shadowed = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (c) =>
                c.styles?.properties['box-shadow']?.startsWith(
                  'var(--shadow-xs)',
                ) ??
                false,
          );
      expect(shadowed, hasLength(2));
    });
  });

  group('Kbd — keys sit side by side', () {
    testComponents('the row owns the gap, space/4 by default', (tester) async {
      final resolved = _resolve(tester);

      expect(_inline(resolved.root, 'gap'), spaceCss(CoreSpace.space4));
      expect(CoreKbdStyle.defaultKeySeparatorSpacing, CoreSpace.space4);
    });

    testComponents('keySeparatorSpacing moves the row gap', (tester) async {
      final resolved = _resolve(
        tester,
        kbdStyle: const CoreKbdStyle(keySeparatorSpacing: 12),
      );

      expect(_inline(resolved.root, 'gap'), spaceCss(12));
    });

    testComponents('a key carries no margin of its own', (tester) async {
      // The space between keys is the row's gap. A margin on the key would be
      // zero for the first and last key and double on the others.
      final cap = _resolve(tester).keyCap;

      expect(_inline(cap, 'margin-left'), isNull);
      expect(_inline(cap, 'margin-right'), isNull);
      expect(_inline(cap, 'margin'), isNull);
    });

    testComponents('a key never shrinks', (tester) async {
      final cap = _resolve(tester).keyCap;

      expect(_classes(cap), contains('shrink-0'));
    });
  });

  group('Kbd — rendered keys', () {
    List<DomComponent> caps(ComponentTester tester) => find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .where((c) => c.classes?.split(' ').contains('shrink-0') ?? false)
        .toList();

    testComponents('one, three and four keys each draw one cap per key', (
      tester,
    ) async {
      const combos = [
        ['Esc'],
        ['⌘', 'Shift', 'F'],
        ['⌃', '⇧', '⌘', '4'],
      ];
      for (final keys in combos) {
        pumpWithTheme(tester, Kbd(keys: keys));

        expect(caps(tester), hasLength(keys.length));
        for (final key in keys) {
          expect(find.text(key), findsOneComponent);
        }
        expect(find.text('+'), findsNothing);
      }
    });

    testComponents('the row is a single line of keys', (tester) async {
      pumpWithTheme(tester, const Kbd(keys: ['Ctrl', 'Alt', 'Shift', 'F5']));

      final root = _root(tester);
      expect(root.classes, contains('inline-flex'));
      expect(root.classes, isNot(contains('flex-wrap')));
      expect(root.styles?.properties['gap'], spaceCss(CoreSpace.space4));
    });
  });

  group('Kbd — one accessible name', () {
    Map<String, String> rootAttributes(ComponentTester tester) =>
        _root(tester).attributes ?? const {};

    testComponents('a combination is one image named by its keys', (
      tester,
    ) async {
      pumpWithTheme(tester, const Kbd(keys: ['Ctrl', 'S']));

      final attributes = rootAttributes(tester);
      expect(attributes['role'], 'img');
      expect(attributes['aria-label'], 'Ctrl S');
    });

    testComponents('four keys are still one name', (tester) async {
      pumpWithTheme(tester, const Kbd(keys: ['⌃', '⇧', '⌘', '4']));

      expect(rootAttributes(tester)['aria-label'], '⌃ ⇧ ⌘ 4');
    });

    testComponents('Kbd.single is named by its key', (tester) async {
      pumpWithTheme(tester, Kbd.single(keyText: 'Esc'));

      expect(rootAttributes(tester)['aria-label'], 'Esc');
    });

    testComponents('Kbd.icon is named by its label', (tester) async {
      pumpWithTheme(
        tester,
        const Kbd.icon(keyContent: Text('↑'), label: '위로'),
      );

      final attributes = rootAttributes(tester);
      expect(attributes['role'], 'img');
      expect(attributes['aria-label'], '위로');
    });

    testComponents('Kbd.icon without a label stays silent', (tester) async {
      pumpWithTheme(tester, const Kbd.icon(keyContent: Text('↑')));

      final attributes = rootAttributes(tester);
      expect(attributes.containsKey('role'), isFalse);
      expect(attributes.containsKey('aria-label'), isFalse);
    });

    testComponents('a caller attribute wins over the derived name', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Kbd(keys: ['Ctrl', 'S'], attributes: {'aria-label': 'Save'}),
      );

      expect(rootAttributes(tester)['aria-label'], 'Save');
    });

    testComponents('copyWith re-derives the name from the new keys', (
      tester,
    ) async {
      final copy = const Kbd(keys: ['Ctrl', 'S']).copyWith(keys: ['Esc']);
      pumpWithTheme(tester, copy);

      expect(rootAttributes(tester)['aria-label'], 'Esc');
    });
  });
}
