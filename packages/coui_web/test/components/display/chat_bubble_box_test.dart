// What the Web chat bubble emits for its box — the inner padding, the
// corners, where each of them is re-pointed by a density, and the face the
// neutral bubble fills with.
//
// The resolver reads `defaultPadding` / `defaultBorderRadius` from Core
// without naming a number, so comparing the emitted `padding` against those
// same defaults would pass for any value. The expectations here are written
// from the tokens the default names (`space10` / `space14` / `radius14`) and
// from the CSS variables they go out as. The neutral face is written from
// the shipped scheme's slots: the class and the fill variable the bubble
// names, and the value the stylesheet gives that name in each mode.

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

ResolvedChatBubble _resolve(
  ComponentTester tester, {
  CoreChatAlignment alignment = .start,
  bool tail = false,
  CoreChatBubbleStyle? style,
}) => resolveChatBubble(
  _themedContext(tester),
  variant: .defaultVariant,
  alignment: alignment,
  tail: tail,
  chatBubbleStyle: style,
);

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

/// The `R G B` triplet a stylesheet gives the colour variable [name] — the
/// first declaration in [css].
String? _triplet(String css, String name) => RegExp(
  '--coui-$name:\\s*(\\d+ \\d+ \\d+)',
).firstMatch(css)?.group(1);

/// [color] as the `R G B` triplet a variable carries.
String _rgb(CoreColor color) => '${color.red} ${color.green} ${color.blue}';

/// The `--coui-*` declarations a density's rule writes.
String _densityRule(String name) {
  final blocks = ThemeConfig.defaults().densityVariableBlocks;
  return RegExp(
    '\\[data-coui-density="$name"\\]\\{([^}]*)\\}',
  ).firstMatch(blocks)!.group(1)!;
}

void main() {
  group('ChatBubble box', () {
    testComponents('the padding is 10 down and 14 across, as variables', (
      tester,
    ) async {
      final root = _resolve(tester).root;

      // `top right bottom left`, every side on the space scale.
      expect(
        _inline(root)['padding'],
        'var(--coui-space-10) var(--coui-space-14) '
        'var(--coui-space-10) var(--coui-space-14)',
      );
    });

    testComponents('every corner is the 14 step when there is no tail', (
      tester,
    ) async {
      final root = _resolve(tester).root;

      expect(
        _inline(root)['border-radius'],
        List.filled(4, 'var(--coui-radius-14)').join(' '),
      );
    });

    testComponents(
      'the tail-side corner is square and the other three stay 14',
      (
        tester,
      ) async {
        const fourteen = 'var(--coui-radius-14)';
        final square = radiusCss(0);

        // `topLeft topRight bottomRight bottomLeft`.
        expect(
          _inline(_resolve(tester, tail: true).root)['border-radius'],
          '$fourteen $fourteen $fourteen $square',
          reason: 'start-aligned: the bottom-left corner is square',
        );
        expect(
          _inline(
            _resolve(tester, tail: true, alignment: .end).root,
          )['border-radius'],
          '$fourteen $fourteen $square $fourteen',
          reason: 'end-aligned: the bottom-right corner is square',
        );
      },
    );

    testComponents('a caller-stated padding and corner still win', (
      tester,
    ) async {
      final root = _resolve(
        tester,
        style: const CoreChatBubbleStyle(
          padding: CoreEdgeInsets.symmetric(
            horizontal: CoreSpace.space24,
            vertical: CoreSpace.space16,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
        ),
      ).root;

      expect(
        _inline(root)['padding'],
        'var(--coui-space-16) var(--coui-space-24) '
        'var(--coui-space-16) var(--coui-space-24)',
      );
      expect(
        _inline(root)['border-radius'],
        List.filled(4, 'var(--coui-radius-8)').join(' '),
      );
    });

    testComponents('the bubble renders the padding it resolved', (
      tester,
    ) async {
      pumpWithTheme(tester, const ChatBubble(child: Text('Hello')));

      final bodies = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (c) =>
                c.styles?.properties['padding']?.contains('space-14') ?? false,
          );

      expect(bodies, hasLength(1));
      expect(
        bodies.single.styles!.properties['border-radius'],
        contains('var(--coui-radius-14)'),
      );
    });
  });

  group('ChatBubble box under density', () {
    // The variables above are re-pointed, not recomputed — so each density
    // must write a rule for the three steps the bubble names. 10 and 14 are
    // off the 4px rungs and move to the next rung in the density's
    // direction; the corner follows the row band.
    for (final density in [CoreDensity.compact, CoreDensity.spacious]) {
      test('${density.name} re-points the steps the bubble names', () {
        final rule = _densityRule(density.name);

        expect(
          rule,
          contains(
            '--coui-space-10:${density.space(CoreSpace.space10) / 16}rem;',
          ),
        );
        expect(
          rule,
          contains(
            '--coui-space-14:${density.space(CoreSpace.space14) / 16}rem;',
          ),
        );
        expect(
          rule,
          contains(
            '--coui-radius-14:${density.radius(CoreRadius.radius14)}px;',
          ),
        );
      });
    }

    test('the values are the ones the table states', () {
      expect(_densityRule('compact'), contains('--coui-space-10:0.5rem;'));
      expect(_densityRule('compact'), contains('--coui-space-14:0.75rem;'));
      expect(_densityRule('compact'), contains('--coui-radius-14:12.0px;'));
      expect(_densityRule('spacious'), contains('--coui-space-10:0.75rem;'));
      expect(_densityRule('spacious'), contains('--coui-space-14:1.0rem;'));
      expect(_densityRule('spacious'), contains('--coui-radius-14:16.0px;'));
    });
  });

  group('ChatBubble neutral face', () {
    testComponents('the fill is the surface-container-high class', (
      tester,
    ) async {
      final root = _resolve(tester).root;

      expect(_classes(root), contains('bg-surface-container-high'));
      expect(
        _classes(root),
        isNot(contains('bg-surface-container')),
        reason: 'the slot the face read before is gone, not added to',
      );
      expect(_inline(root), isNot(contains('background-color')));
    });

    testComponents('the fill a material preset restates is the same slot', (
      tester,
    ) async {
      final root = _resolve(tester).root;

      expect(
        _inline(root)[kWebSurfaceFillVar],
        'var(--coui-surface-container-high)',
      );
    });

    testComponents('the text is the onSurface colour', (tester) async {
      final root = _resolve(tester).root;

      expect(_inline(root)['color'], 'rgb(var(--coui-on-surface))');
    });

    testComponents('the tail inherits that fill', (tester) async {
      final tail = _resolve(tester, tail: true).tail!;

      expect(_inline(tail)['background-color'], 'inherit');
    });

    testComponents('the primary face still names the primary slot', (
      tester,
    ) async {
      // Negative control: the swap is the neutral entry alone.
      final resolved = resolveChatBubble(
        _themedContext(tester),
        variant: .primary,
        alignment: .start,
        tail: false,
      );

      expect(_classes(resolved.root), contains('bg-primary'));
      expect(
        _inline(resolved.root)[kWebSurfaceFillVar],
        'var(--coui-primary)',
      );
    });

    testComponents('a caller-stated face is inline, and still wins', (
      tester,
    ) async {
      final root = _resolve(
        tester,
        style: const CoreChatBubbleStyle(
          backgroundColor: CoreColor(0xFF123456),
        ),
      ).root;

      expect(_inline(root)['background-color'], isNotNull);
      expect(_classes(root), isNot(contains('bg-surface-container-high')));
    });

    test("the stylesheet gives the slot the scheme's high container tone", () {
      final config = ThemeConfig.defaults();
      final light = CoreThemePresets.lightColorScheme;
      final dark = CoreThemePresets.darkColorScheme;

      expect(
        _triplet(config.cssVariables, 'surface-container-high'),
        _rgb(light.surfaceContainerHigh),
      );
      expect(
        _triplet(config.darkVariableBlock, 'surface-container-high'),
        _rgb(dark.surfaceContainerHigh),
      );
      expect(
        _rgb(light.surfaceContainerHigh),
        isNot(_rgb(light.surfaceContainer)),
        reason: 'the swap is visible in light',
      );
      expect(
        _rgb(dark.surfaceContainerHigh),
        isNot(_rgb(dark.surfaceContainer)),
        reason: 'the swap is visible in dark',
      );
    });
  });

  group('ChatBubble plain variant', () {
    ResolvedChatBubble resolvePlain(
      ComponentTester tester, {
      bool tail = false,
      CoreChatAlignment alignment = .start,
      CoreChatBubbleStyle? style,
    }) => resolveChatBubble(
      _themedContext(tester),
      variant: .plain,
      alignment: alignment,
      tail: tail,
      chatBubbleStyle: style,
    );

    testComponents('states no face, muted text, no padding, full width', (
      tester,
    ) async {
      final root = resolvePlain(tester).root;

      expect(_inline(root)['color'], 'rgb(var(--coui-on-surface-variant))');
      expect(
        _inline(root)['padding'],
        List.filled(4, 'var(--coui-space-0)').join(' '),
      );
      expect(_inline(root)['max-width'], '100%');
      expect(
        _classes(root).where((c) => c.startsWith('bg-')),
        isEmpty,
        reason: 'a transparent fill goes out as no background class',
      );
    });

    testComponents('wears no material marker and publishes no fill', (
      tester,
    ) async {
      final root = resolvePlain(tester).root;

      expect(_classes(root), isNot(contains(kWebSurfaceMarker)));
      expect(_inline(root), isNot(contains(kWebSurfaceFillVar)));
      expect(_inline(root), isNot(contains(kWebSurfaceFillAlphaVar)));
      // Negative control: the filled neutral bubble keeps both.
      final neutral = _resolve(tester).root;
      expect(_classes(neutral), contains(kWebSurfaceMarker));
      expect(_inline(neutral), contains(kWebSurfaceFillVar));
    });

    testComponents('a tail cannot be switched on: no wrapper, no tail', (
      tester,
    ) async {
      for (final alignment in CoreChatAlignment.values) {
        final resolved = resolvePlain(
          tester,
          tail: true,
          alignment: alignment,
        );

        expect(resolved.wrapper, isNull, reason: alignment.name);
        expect(resolved.tail, isNull, reason: alignment.name);
        expect(
          _inline(resolved.root)['border-radius'],
          List.filled(4, 'var(--coui-radius-14)').join(' '),
          reason: '${alignment.name}: no corner squared for a tail',
        );
      }
    });

    testComponents('a caller fill gives plain a face, a marker and a tail', (
      tester,
    ) async {
      final resolved = resolvePlain(
        tester,
        tail: true,
        style: const CoreChatBubbleStyle(
          backgroundColor: CoreColor.token(CoreColors.primary),
        ),
      );

      expect(_classes(resolved.root), contains(kWebSurfaceMarker));
      expect(resolved.tail, isNotNull);
      expect(resolved.wrapper, isNotNull);
    });

    testComponents(
      'a transparent override drops the tail of a filled variant',
      (
        tester,
      ) async {
        final resolved = _resolve(
          tester,
          tail: true,
          style: const CoreChatBubbleStyle(
            backgroundColor: CoreColor.transparent,
          ),
        );

        expect(resolved.tail, isNull);
        expect(resolved.wrapper, isNull);
        expect(_classes(resolved.root), isNot(contains(kWebSurfaceMarker)));
        // No wrapper to own the width, so the root takes it over.
        expect(_inline(resolved.root)['max-width'], '75%');
      },
    );

    testComponents('a caller padding and width still win over the variant', (
      tester,
    ) async {
      final root = resolvePlain(
        tester,
        style: const CoreChatBubbleStyle(
          padding: CoreEdgeInsets.all(CoreSpace.space8),
          maxWidthFactor: 0.5,
        ),
      ).root;

      expect(
        _inline(root)['padding'],
        List.filled(4, 'var(--coui-space-8)').join(' '),
      );
      expect(_inline(root)['max-width'], '50%');
    });
  });

  group('ChatBubble width without a tail', () {
    testComponents('the root carries the three quarters itself', (
      tester,
    ) async {
      final resolved = _resolve(tester);

      expect(resolved.wrapper, isNull);
      expect(_inline(resolved.root)['max-width'], '75%');
    });

    testComponents('tail: false draws no pointer', (tester) async {
      pumpWithTheme(
        tester,
        const ChatBubble(child: Text('Hello')),
      );

      final doms = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      // No clipped pointer anywhere, and the one box that carries the
      // three-quarters cap is the bubble body itself.
      expect(
        doms.where((c) => c.styles?.properties['clip-path'] != null),
        isEmpty,
        reason: 'no tail element',
      );
      expect(
        doms.where((c) => c.styles?.properties['max-width'] == '75%'),
        hasLength(1),
        reason: 'the root carries the cap, no wrapper',
      );
    });

    testComponents('a bubble draws no pointer by default', (tester) async {
      expect(CoreChatBubbleContract.defaultTail, isFalse);
      // Unstated: the side decides, and the start side keeps the default.
      expect(const ChatBubble(child: Text('Hello')).tail, isNull);
      expect(
        CoreChatBubbleContract.defaultTailFor(CoreChatAlignment.start),
        CoreChatBubbleContract.defaultTail,
      );

      pumpWithTheme(tester, const ChatBubble(child: Text('Hello')));

      final doms = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      expect(
        doms.where((c) => c.styles?.properties['clip-path'] != null),
        isEmpty,
        reason: 'no tail element',
      );
      expect(
        doms.where((c) => c.styles?.properties['max-width'] == '75%'),
        hasLength(1),
        reason: 'the root carries the cap, no wrapper',
      );
    });

    testComponents('tail: true draws the pointer', (tester) async {
      pumpWithTheme(
        tester,
        const ChatBubble(tail: true, child: Text('Hello')),
      );

      final doms = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .toList();
      expect(
        doms.where((c) => c.styles?.properties['clip-path'] != null),
        hasLength(1),
      );
    });

    testComponents('with a tail the wrapper owns it, the root does not', (
      tester,
    ) async {
      final resolved = _resolve(tester, tail: true);

      expect(_inline(resolved.wrapper!)['max-width'], '75%');
      expect(
        _inline(resolved.root)['max-width'],
        '100%',
        reason: 'a second 75% would nest to 56%',
      );
    });

    testComponents('wrapper and tail are never present one without the other', (
      tester,
    ) async {
      for (final variant in CoreChatBubbleVariant.values) {
        for (final tail in [true, false]) {
          final resolved = resolveChatBubble(
            _themedContext(tester),
            variant: variant,
            alignment: .start,
            tail: tail,
          );

          expect(
            resolved.wrapper == null,
            resolved.tail == null,
            reason: '${variant.name} tail:$tail',
          );
        }
      }
    });

    testComponents('the filled variants keep the shared padding', (
      tester,
    ) async {
      for (final variant in CoreChatBubbleVariant.values) {
        if (variant == .plain) continue;
        final resolved = resolveChatBubble(
          _themedContext(tester),
          variant: variant,
          alignment: .start,
          tail: false,
        );

        expect(
          _inline(resolved.root)['padding'],
          'var(--coui-space-10) var(--coui-space-14) '
          'var(--coui-space-10) var(--coui-space-14)',
          reason: variant.name,
        );
        expect(
          _inline(resolved.root)['max-width'],
          '75%',
          reason: variant.name,
        );
      }
    });
  });
}
