import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/item_picker/item_picker_style.dart';
import 'package:coui_web/src/components/form/multi_answer_card/multi_answer_card_style.dart';
import 'package:coui_web/src/components/layout/window/window_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// The places the surface material used to reach one platform and not the
/// other (#5429, #5434), read back from what the Web side now emits.

/// Captures the ambient themed [BuildContext] so a resolver can be called
/// directly.
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

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// Every element below [element], depth first.
List<Element> _descendants(Element element) {
  final found = <Element>[];
  void visit(Element child) {
    found.add(child);
    child.visitChildren(visit);
  }

  element.visitChildren(visit);
  return found;
}

void main() {
  group('ChatBubble — the fill reaches the material, the tail follows it', () {
    testComponents('the body fill rides a class a material rule can restate', (
      tester,
    ) async {
      // An inline `background-color` outranks every selector, so the rule a
      // material preset writes for marked surfaces never reached this
      // bubble: it was frosted and bent behind a fill that stayed opaque.
      final resolved = resolveChatBubble(
        _themedContext(tester),
        variant: .defaultVariant,
        alignment: .start,
        tail: true,
      );

      expect(_classes(resolved.root), contains(kWebSurfaceMarker));
      expect(
        _classes(resolved.root).where((c) => c.startsWith('bg-')),
        hasLength(1),
        reason: 'the token fill is a class',
      );
      expect(_inline(resolved.root), isNot(contains('background-color')));
      expect(_inline(resolved.root), contains(kWebSurfaceFillVar));
    });

    testComponents('the tail inherits the body fill', (tester) async {
      final resolved = resolveChatBubble(
        _themedContext(tester),
        variant: .defaultVariant,
        alignment: .end,
        tail: true,
      );

      expect(_inline(resolved.tail!)['background-color'], 'inherit');
    });

    testComponents('a raw fill still goes inline, and the tail follows it', (
      tester,
    ) async {
      final resolved = resolveChatBubble(
        _themedContext(tester),
        variant: .defaultVariant,
        alignment: .start,
        tail: true,
        chatBubbleStyle: const CoreChatBubbleStyle(
          backgroundColor: CoreColor(0xFF123456),
        ),
      );

      expect(_inline(resolved.root)['background-color'], isNotNull);
      expect(_inline(resolved.tail!)['background-color'], 'inherit');
    });

    testComponents('the tail is the body element’s child', (tester) async {
      // `inherit` reads the parent's computed value — only the body is a
      // parent whose fill a material restates.
      pumpWithTheme(tester, const ChatBubble(tail: true, child: Text('Hello')));

      final bodies = find
          .byType(DomComponent)
          .evaluate()
          .where(
            (e) => ((e.component as DomComponent).classes ?? '')
                .split(' ')
                .contains(kWebSurfaceMarker),
          )
          .toList();
      expect(bodies, hasLength(1));

      final tails = _descendants(bodies.single).where(
        (e) => switch (e.component) {
          DomComponent(:final styles) =>
            styles?.properties['clip-path'] != null,
          _ => false,
        },
      );
      expect(tails, hasLength(1), reason: 'the clipped tail is inside');
    });
  });

  group('Tooltip — the tail inherits the bubble fill', () {
    testComponents('no fill of its own, inherited instead', (tester) async {
      // The default states no tail, so the style states one to have a tail
      // whose fill can be read.
      final resolved = resolveTooltip(
        _themedContext(tester),
        didEnter: true,
        activeDurationMs: 0,
        placement: .top,
        tooltipStyle: const CoreTooltipStyle(tailWidth: 12, tailHeight: 6),
      );

      final tail = resolved.tail!;
      expect(_inline(tail)['background-color'], 'inherit');
      expect(_classes(tail).where((c) => c.startsWith('bg-')), isEmpty);
    });
  });

  group('Alert — the contributed boundary reaches it', () {
    testComponents('by default it carries the marker and no stroke of its '
        'own', (tester) async {
      final resolved = resolveAlert(_themedContext(tester), variant: .neutral);

      expect(_classes(resolved.root), contains(kControlBorderMarker));
      // The `border` utility and an inline width would outrank the
      // marker's rule — so the contributed width could never land.
      expect(_classes(resolved.root), isNot(contains('border')));
      expect(_inline(resolved.root), isNot(contains('border-width')));
      expect(_inline(resolved.root), isNot(contains('border-color')));
    });

    testComponents('an authored stroke outranks the contribution', (
      tester,
    ) async {
      final resolved = resolveAlert(
        _themedContext(tester),
        variant: .neutral,
        alertStyle: const CoreAlertStyle(
          borderWidth: CoreStrokeWidth.stroke1,
          borderColor: CoreColor.token(CoreColors.outline),
        ),
      );

      expect(_classes(resolved.root), isNot(contains(kControlBorderMarker)));
      expect(_classes(resolved.root), contains('border'));
      expect(_inline(resolved.root), contains('border-width'));
    });

    testComponents('a stated colour still wins on the contributed width', (
      tester,
    ) async {
      final resolved = resolveAlert(
        _themedContext(tester),
        variant: .neutral,
        alertStyle: const CoreAlertStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        ),
      );

      expect(_classes(resolved.root), contains(kControlBorderMarker));
      expect(_inline(resolved.root)['border-color'], contains('primary'));
    });
  });

  group('the style cast reaches surfaces at rest', () {
    // The item picker states a shadow of its own (the floating-panel cast),
    // so it takes no style-contributed cast at rest.
    testComponents('an item picker states its own cast instead', (
      tester,
    ) async {
      final resolved = resolveItemPicker(_themedContext(tester));

      expect(
        _classes(resolved.root),
        isNot(contains(kControlShadowRestMarker)),
      );
      expect(_classes(resolved.root), contains('shadow-lg'));
    });

    testComponents('a window snap bar states its own cast instead', (
      tester,
    ) async {
      final resolved = resolveWindow(_themedContext(tester));

      // The banner states the lg step, so it takes no style-contributed cast
      // at rest — it takes the rim a casting surface takes.
      expect(
        _classes(resolved.snapBarContainer),
        isNot(contains(kControlShadowRestMarker)),
      );
      expect(
        resolved.snapBarContainer.inlineStyles!.properties['box-shadow'],
        'var(--shadow-lg), $kSurfaceRimVar',
      );
    });
  });

  group('Button — a filled button is a surface, an unfilled one is not', () {
    ResolvedButton resolve(ComponentTester tester, CoreButtonVariant variant) =>
        resolveButton(
          _themedContext(tester),
          variant: variant,
          size: .md,
          shape: .rectangle,
          expanded: false,
        );

    for (final variant in const [
      CoreButtonVariant.primary,
      CoreButtonVariant.secondary,
      CoreButtonVariant.outline,
      CoreButtonVariant.destructive,
    ]) {
      testComponents('${variant.name} is marked', (tester) async {
        expect(
          _classes(resolve(tester, variant).root),
          contains(kWebSurfaceMarker),
        );
      });
    }

    for (final variant in const [
      CoreButtonVariant.ghost,
      CoreButtonVariant.plain,
      CoreButtonVariant.menu,
      CoreButtonVariant.menubar,
      CoreButtonVariant.fixed,
    ]) {
      testComponents('${variant.name} paints no fill and is not marked', (
        tester,
      ) async {
        // A material is a statement about a filled box: marked, a
        // fill-less button was frosted and edged around nothing.
        expect(
          _classes(resolve(tester, variant).root),
          isNot(contains(kWebSurfaceMarker)),
        );
      });
    }
  });

  group('Badge · ValidationBadge · Kbd — marked only while a fill paints', () {
    testComponents('a filled badge is marked and publishes its fill', (
      tester,
    ) async {
      final resolved = resolveBadge(
        _themedContext(tester),
        tone: .primary,
        variant: .filled,
        size: .sm,
        form: .count,
        interactive: false,
      );

      expect(_classes(resolved.root), contains(kWebSurfaceMarker));
      expect(_inline(resolved.root), contains(kWebSurfaceFillVar));
      expect(
        _inline(resolved.root),
        isNot(contains(kWebSurfaceFillAlphaVar)),
        reason: 'an opaque fill states no alpha — the reset reads 1',
      );
    });

    testComponents('an outlined badge paints no fill and is not a surface', (
      tester,
    ) async {
      // Its fill is the surface token at opacity 0. Marked, the material
      // rule painted it at the share and cleared the stroke that is its
      // only edge — a translucent pill with no outline, on Web alone.
      final resolved = resolveBadge(
        _themedContext(tester),
        tone: .neutral,
        variant: .outlined,
        size: .sm,
        form: .count,
        interactive: true,
      );

      expect(_classes(resolved.root), isNot(contains(kWebSurfaceMarker)));
      expect(_inline(resolved.root), isNot(contains(kWebSurfaceFillVar)));
      expect(
        _classes(resolved.root).where((c) => c.contains(kWebSurfaceFillVar)),
        isEmpty,
        reason: 'no state publishes a fill for a surface that is not one',
      );
    });

    testComponents(
      'a pressed or hovered badge hands its wash to the material — the '
      'washed fill stays translucent under glass, as on Flutter',
      (tester) async {
        // The wash is a state rule, not a utility class: no `hover:` class
        // publishes a second fill. Under a translucent preset the material
        // rule restates the fill from the surface vars and outranks the
        // state rule's own colour, so the state rule publishes the wash
        // through those vars. An `!important` colour would paint the washed
        // fill opaque while the backdrop still frosts — the Flutter twin
        // folds the share into its washed fills (`materialFill(washed)`).
        final context = _themedContext(tester);
        final resolved = resolveBadge(
          context,
          tone: .primary,
          variant: .filled,
          size: .sm,
          form: .count,
          interactive: true,
        );
        expect(
          _classes(resolved.root).where((c) => c.startsWith('hover:')),
          isEmpty,
        );
        expect(
          _inline(resolved.root)[kWebSurfaceFillVar],
          'var(--coui-primary)',
        );

        final css = resolveBadgeRules(
          context,
          scopeId: 'co-badge-glass',
          tone: .primary,
          variant: .filled,
          size: .sm,
          form: .count,
          interactive: true,
        ).css;
        const wash =
            'color-mix(in srgb, rgb(var(--coui-on-primary)) 8%, '
            'rgb(var(--coui-primary)))';
        // (0,2,0): over the `bg-*` utility, under the material rule's
        // `[data-coui-style] .coui-surface.<role>` (0,3,0).
        expect(
          css,
          contains(
            ':where(#co-badge-glass).$kWebSurfaceMarker:hover{'
            'background-color:$wash;'
            '$kWebSurfaceFillVar:from $wash r g b !important;'
            '$kWebSurfaceFillAlphaVar:1 !important;}',
          ),
        );

        // The rule the vars feed, under glass: the wash at the share — an
        // opaque fill's wash is opaque, so its alpha is the share alone,
        // the alpha the Flutter twin's washed fill carries there.
        final glass = CoreSurfaceRecipe.of(.liquidGlass).surfaceFor(.content)!;
        final pct = (glass.opacity.light * kPercentScale).round();
        expect(pct, lessThan(kPercentScale));
        expect(
          ThemeConfig.defaults().surfaceStyleTreatmentBlock(
            .liquidGlass,
            glass,
          ),
          contains(
            '.$kWebSurfaceMarker.$kWebSurfaceRoleContent{'
            'background-color:rgb(var($kWebSurfaceFillVar) / '
            'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct%));',
          ),
        );
      },
    );

    testComponents('a validation container publishes its fill with no alpha', (
      tester,
    ) async {
      final resolved = resolveValidationBadge(
        _themedContext(tester),
        state: .valid,
        size: CoreValidationBadgeStyle.defaultSize,
      );

      expect(_classes(resolved.root), contains(kWebSurfaceMarker));
      expect(
        _inline(resolved.root),
        containsPair(kWebSurfaceFillVar, 'var(--coui-success-container)'),
      );
      // The container is opaque, so there is no tint alpha to publish.
      expect(_inline(resolved.root), isNot(contains(kWebSurfaceFillAlphaVar)));
    });

    testComponents('a key cap is marked and publishes its fill', (
      tester,
    ) async {
      final resolved = resolveKbd(_themedContext(tester));

      expect(_classes(resolved.keyCap), contains(kWebSurfaceMarker));
      expect(_inline(resolved.keyCap), contains(kWebSurfaceFillVar));
    });

    testComponents('a key cap with no fill is not a surface', (tester) async {
      final resolved = resolveKbd(
        _themedContext(tester),
        kbdStyle: const CoreKbdStyle(keyBackgroundColor: .transparent),
      );

      expect(_classes(resolved.keyCap), isNot(contains(kWebSurfaceMarker)));
    });
  });

  group('the material composes the token alpha with its share', () {
    // The triplet carries no alpha. Restating it at the share erased the
    // token's own: a 10% tint came out at the share and a fill stated at
    // opacity 0 came out half-filled. Both platforms now paint
    // `token alpha × share` — the Flutter twin folds it with `scaleAlpha`.
    final glass = CoreSurfaceRecipe.of(.liquidGlass).surfaceFor(.content)!;
    final css = ThemeConfig.defaults().surfaceStyleTreatmentBlock(
      .liquidGlass,
      glass,
    );

    test('the share multiplies the published alpha', () {
      final pct = (glass.opacity.light * kPercentScale).round();
      expect(
        css,
        contains(
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'calc(var($kWebSurfaceFillAlphaVar, 1) * $pct%));',
        ),
      );
    });

    test('an opaque restatement keeps the token alpha and drops the share', () {
      expect(
        css,
        contains(
          'background-color:rgb(var($kWebSurfaceFillVar) / '
          'var($kWebSurfaceFillAlphaVar, 1)) !important;',
        ),
      );
    });

    test('every marked surface starts from 1, so none inherits a tint', () {
      // A custom property inherits. Without the reset, an opaque surface
      // nested in a tinted one would read the tint's alpha.
      expect(
        ThemeConfig.defaults().cssVariables,
        contains(':where(.$kWebSurfaceMarker){$kWebSurfaceFillAlphaVar:1;'),
      );
    });

    test('and from no border for the edge band to reach over', () {
      // The same inheritance, for the border a surface says it keeps: a
      // button inside a field would otherwise draw its band past its own
      // edge by the field's border.
      expect(
        ThemeConfig.defaults().cssVariables,
        contains(
          ':where(.$kWebSurfaceMarker){$kWebSurfaceFillAlphaVar:1;'
          '$kWebSurfaceBleedVar:0px;$kWebSurfaceBleedTopVar:initial;'
          '$kWebSurfaceBleedBottomVar:initial;'
          '$kWebSurfaceEdgeStyleVar:initial;$kWebSurfaceFoldVar:initial;}',
        ),
      );
    });
  });

  group('the rim rides only a shadow the surface authored', () {
    // A rim decorates a surface that casts its own shadow; it does not
    // raise a flat one. The Flutter twin keys `resolveSurfaceRim` on the
    // authored stack, and a flat surface here used to name the rim anyway —
    // lit under claymorphism on Web alone.
    String shadowOf(WebElementChrome chrome) => _inline(chrome)['box-shadow']!;

    testComponents('a flat container takes the contributed cast, no rim', (
      tester,
    ) async {
      final resolved = resolveOutlinedContainer(
        context: _themedContext(tester),
      );

      expect(shadowOf(resolved.root), kControlShadowVar);
    });

    testComponents('a lifted container takes the rim beside its lift', (
      tester,
    ) async {
      final resolved = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(elevation: .medium),
      );

      expect(shadowOf(resolved.root), endsWith(', $kSurfaceRimVar'));
      expect(shadowOf(resolved.root), isNot(contains(kControlShadowVar)));
    });

    testComponents('an explicitly empty stack stays empty', (tester) async {
      final resolved = resolveOutlinedContainer(
        context: _themedContext(tester),
        containerStyle: const CoreOutlinedContainerStyle(boxShadow: []),
      );

      expect(shadowOf(resolved.root), 'none');
    });

    testComponents('the default (inline) palette casts nothing and takes no '
        'rim', (tester) async {
      final resolved = resolveCommand(_themedContext(tester));

      expect(shadowOf(resolved.root), 'none');
      expect(
        _classes(resolved.root),
        isNot(contains(kControlShadowRestMarker)),
        reason: 'the twin hands its container an explicitly empty stack',
      );
    });

    testComponents('a dialog palette casts, and the rim rides its cast', (
      tester,
    ) async {
      final resolved = resolveCommand(
        _themedContext(tester),
        presentation: .dialog,
      );

      expect(shadowOf(resolved.root), endsWith(', $kSurfaceRimVar'));
    });

    testComponents('a reverse chip rests on the ghost cast alone', (
      tester,
    ) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: .defaultVariant,
        chipColor: .defaultColor,
        size: .defaultSize,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
        chipStyle: const CoreChipStyle(castMotion: .reverse),
      );

      expect(shadowOf(resolved.root), kControlShadowGhostVar);
    });

    testComponents('a multi-answer card takes the contributed cast, no rim', (
      tester,
    ) async {
      final resolved = resolveMultiAnswerCard(_themedContext(tester));

      for (final state in [
        resolved.root,
        resolved.hoverRoot,
        resolved.selectedRoot,
        resolved.disabledRoot,
      ]) {
        expect(shadowOf(state), endsWith(', $kControlShadowVar'));
        expect(shadowOf(state), isNot(contains(kSurfaceRimVar)));
      }
    });

    testComponents('a toggle track takes the contributed cast at rest and '
        'under its focus band', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveToggle(
        context,
        variant: .defaultVariant,
        size: .md,
        value: false,
        enabled: true,
      );
      final rules = resolveToggleRules(
        context,
        variant: .defaultVariant,
        value: false,
        enabled: true,
      );

      expect(_classes(resolved.track), contains(kControlShadowRestMarker));
      expect(rules.css, isNot(contains(kSurfaceRimVar)));
    });
  });

  group('MultiAnswerCard — the fill reaches the material', () {
    testComponents('each state fills through a class a material rule can '
        'restate', (tester) async {
      // An inline `background-color` outranks every selector, so this card
      // stayed opaque under a translucent material while its Flutter twin,
      // composing `OutlinedContainer`, took the share.
      final resolved = resolveMultiAnswerCard(_themedContext(tester));

      for (final (state, fill) in [
        (resolved.root, CoreMultiAnswerCardStyle.defaultBackgroundColor),
        (resolved.hoverRoot, CoreMultiAnswerCardStyle.defaultHoverColor),
        (
          resolved.selectedRoot,
          CoreMultiAnswerCardStyle.defaultSelectedBackgroundColor,
        ),
        (
          resolved.disabledRoot,
          CoreMultiAnswerCardStyle.defaultDisabledBackgroundColor,
        ),
      ]) {
        expect(_classes(state), contains(kWebSurfaceMarker));
        expect(
          _classes(state).where((c) => c.startsWith('bg-')),
          ['bg-${fill.tailwindColor}'],
        );
        expect(_inline(state), isNot(contains('background-color')));
      }
    });
  });
}
