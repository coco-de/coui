import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveBadge` / `resolveBadgeRules` directly.
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

BuildContext _contextUnder(ComponentTester tester, CoreBadgeTheme badge) {
  late BuildContext context;
  tester.pumpComponent(
    Theme(
      data: ThemeData.coui.copyWith(
        coreComponentTheme: CoreComponentTheme(badge: badge),
      ),
      child: _ContextCapture((c) => context = c),
    ),
  );
  return context;
}

/// `resolveBadge` with the widget's own defaults, so each test names only
/// the axis it is about.
ResolvedBadge _resolve(
  BuildContext context, {
  CoreBadgeTone tone = CoreBadgeTone.defaultTone,
  CoreBadgeVariant variant = CoreBadgeVariant.defaultVariant,
  CoreBadgeForm form = CoreBadgeForm.defaultForm,
  CoreComponentSize size = CoreBadgeContract.defaultSize,
  bool interactive = false,
  CoreBadgeStyle? badgeStyle,
}) => resolveBadge(
  context,
  tone: tone,
  variant: variant,
  form: form,
  size: size,
  interactive: interactive,
  badgeStyle: badgeStyle,
);

/// `resolveBadgeRules` with the widget's own defaults.
ResolvedBadgeRules _rules(
  BuildContext context, {
  String scopeId = 'co-badge-test',
  CoreBadgeTone tone = CoreBadgeTone.defaultTone,
  CoreBadgeVariant variant = CoreBadgeVariant.defaultVariant,
  CoreBadgeForm form = CoreBadgeForm.defaultForm,
  CoreComponentSize size = CoreBadgeContract.defaultSize,
  bool interactive = true,
  CoreBadgeStyle? badgeStyle,
}) => resolveBadgeRules(
  context,
  scopeId: scopeId,
  tone: tone,
  variant: variant,
  form: form,
  size: size,
  interactive: interactive,
  badgeStyle: badgeStyle,
);

/// A raw (token-less) colour — the exact case that used to throw
/// `token!.name` when routed onto a pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

/// The `focus-visible:outline-*` ring classes on [className], as whole
/// classes.
///
/// Whole classes, not substrings, so an assertion pins the exact set the
/// ring emits — width, offset and colour — rather than one fragment of
/// it.
List<String> _ringClasses(String className) => className
    .split(' ')
    .where((cls) => cls.startsWith('focus-visible:outline-'))
    .toList();

/// The selector a token fill on a marked surface washes under — below a
/// preset's material rule, above the fill utility.
String _surfaceScope(String scopeId) => ':where(#$scopeId).$kWebSurfaceMarker';

/// The sizes that have a row of their own; `xl2` is drawn as `xl`.
const List<CoreComponentSize> _kSizesWithRows = [
  CoreComponentSize.xs,
  CoreComponentSize.sm,
  CoreComponentSize.md,
  CoreComponentSize.lg,
  CoreComponentSize.xl,
  CoreComponentSize.xl2,
];

/// A duration off the `CoreDuration` scale on purpose — the case the Web
/// resolver must emit as a literal instead of throwing on a missing token.
const _kOffScaleDuration = Duration(milliseconds: 175);
void main() {
  group('Badge colours — tone × variant from the Core tone table', () {
    testComponents(
      'every tone × variant paints the fill, label and line its tone row '
      'states for that strength',
      (tester) async {
        final context = _themedContext(tester);
        for (final tone in CoreBadgeTone.values) {
          for (final variant in CoreBadgeVariant.values) {
            final resting = CoreBadgeStyle.defaultsByTone[tone]!
                .restingStyleFor(variant, CoreBadgeForm.label);
            final root = _resolve(context, tone: tone, variant: variant).root;
            final classes = _classes(root);
            final reason = '$tone × $variant';

            expect(
              classes,
              contains('bg-${resting.backgroundColor!.tailwindColor}'),
              reason: reason,
            );
            expect(
              classes,
              contains('text-${resting.foregroundColor!.tailwindColor}'),
              reason: reason,
            );
            if (variant == CoreBadgeVariant.outlined) {
              expect(
                classes,
                contains('border-${resting.borderColor!.tailwindColor}'),
                reason: reason,
              );
              expect(
                _inline(root)['border-width'],
                'var(--coui-stroke-width-1)',
                reason: reason,
              );
            } else {
              // No line is stated, so none is drawn — not a zero-width one,
              // and not a width that would paint the preflight's colour.
              expect(
                classes.where((cls) => cls.startsWith('border-')),
                isEmpty,
                reason: reason,
              );
              expect(
                _inline(root).containsKey('border-width'),
                isFalse,
                reason: reason,
              );
            }
          }
        }
      },
    );

    testComponents(
      'the default badge is the neutral tonal label of the spec — the '
      'surface ramp behind onSurfaceVariant',
      (tester) async {
        final classes = _classes(_resolve(_themedContext(tester)).root);
        expect(classes, contains('bg-surface-container-high'));
        expect(classes, contains('text-on-surface-variant'));
      },
    );

    testComponents(
      'neutral filled steps up the ramp, outlined reads the page text and the '
      'outline line, primary outlined reads primaryText',
      (tester) async {
        final context = _themedContext(tester);
        final filled = _classes(
          _resolve(context, variant: CoreBadgeVariant.filled).root,
        );
        expect(filled, contains('bg-surface-container-highest'));
        expect(filled, contains('text-on-surface-variant'));

        final outlined = _classes(
          _resolve(context, variant: CoreBadgeVariant.outlined).root,
        );
        expect(outlined, contains('border-outline'));
        expect(outlined, contains('text-on-surface'));
        // The fill under the line is the surface at opacity 0.
        expect(outlined, contains('bg-surface/0'));

        final primaryOutlined = _classes(
          _resolve(
            context,
            tone: CoreBadgeTone.primary,
            variant: CoreBadgeVariant.outlined,
          ).root,
        );
        expect(primaryOutlined, contains('text-primary-text'));
      },
    );

    testComponents(
      'a dot paints its tone dot colour at every variant, with no label '
      'colour and no line',
      (tester) async {
        final context = _themedContext(tester);
        for (final tone in CoreBadgeTone.values) {
          final dotColor = CoreBadgeStyle.defaultsByTone[tone]!.dotColor;
          for (final variant in CoreBadgeVariant.values) {
            final classes = _classes(
              _resolve(
                context,
                tone: tone,
                variant: variant,
                form: CoreBadgeForm.dot,
              ).root,
            );
            final reason = '$tone × $variant';
            expect(
              classes,
              contains('bg-${dotColor.tailwindColor}'),
              reason: reason,
            );
            expect(
              classes.where(
                (cls) => cls.startsWith('text-') || cls.startsWith('border-'),
              ),
              isEmpty,
              reason: reason,
            );
          }
        }
      },
    );

    testComponents(
      'an outlined badge carries no surface marker — its fill paints nothing',
      (tester) async {
        final context = _themedContext(tester);
        final outlined = _classes(
          _resolve(context, variant: CoreBadgeVariant.outlined).root,
        );
        expect(outlined, isNot(contains(kWebSurfaceMarker)));

        final tonal = _classes(_resolve(context).root);
        expect(tonal, contains(kWebSurfaceMarker));
      },
    );

    testComponents(
      'a raw fill override goes inline and drops the fill class',
      (tester) async {
        final root = _resolve(
          _themedContext(tester),
          badgeStyle: const CoreBadgeStyle(backgroundColor: _kRawGreen),
        ).root;
        expect(
          _classes(root).where((cls) => cls.startsWith('bg-')),
          isEmpty,
        );
        expect(_inline(root)['background-color'], 'rgb(0, 255, 0)');
      },
    );
  });

  group('Badge geometry — per size and per form', () {
    testComponents(
      'a word and a number stand on the step height; a number is never '
      'narrower than it is tall; a dot is its diameter',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in _kSizesWithRows) {
          final row = CoreBadgeStyle.defaultsBySize[size]!;
          final height = 'size${row.minHeight!.toInt()}';
          final dot = 'size${row.dotSize!.toInt()}';

          final label = _classes(_resolve(context, size: size).root);
          expect(label, contains('min-h-$height'), reason: '$size label');
          expect(
            label.where((cls) => cls.startsWith('min-w-')),
            isEmpty,
            reason: '$size label',
          );

          final count = _classes(
            _resolve(context, size: size, form: CoreBadgeForm.count).root,
          );
          expect(count, contains('min-h-$height'), reason: '$size count');
          expect(count, contains('min-w-$height'), reason: '$size count');

          final dotRoot = _resolve(
            context,
            size: size,
            form: CoreBadgeForm.dot,
          ).root;
          expect(_classes(dotRoot), containsAll(['w-$dot', 'h-$dot']));
          expect(
            _classes(dotRoot).where((cls) => cls.startsWith('min-h-')),
            isEmpty,
            reason: '$size dot',
          );
          // A dot pads nothing — its box is the step's diameter.
          expect(
            _inline(dotRoot).keys.where((key) => key.startsWith('padding')),
            isEmpty,
            reason: '$size dot',
          );
        }
      },
    );

    testComponents(
      'the step height is the spec ladder 18 / 20 / 24 / 28 / 32 / 36',
      (tester) async {
        final context = _themedContext(tester);
        const expected = {
          CoreComponentSize.xs: 'min-h-size18',
          CoreComponentSize.sm: 'min-h-size20',
          CoreComponentSize.md: 'min-h-size24',
          CoreComponentSize.lg: 'min-h-size28',
          CoreComponentSize.xl: 'min-h-size32',
          CoreComponentSize.xl2: 'min-h-size36',
        };
        expected.forEach((size, cls) {
          expect(_classes(_resolve(context, size: size).root), contains(cls));
        });
      },
    );

    testComponents(
      'padding is horizontal only and reads the step row',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in _kSizesWithRows) {
          final padding = CoreBadgeStyle.defaultsBySize[size]!.padding!;
          expect(padding.top, 0, reason: '$size');
          expect(padding.bottom, 0, reason: '$size');
          expect(
            _inline(_resolve(context, size: size).root)['padding'],
            padding.toValue(),
            reason: '$size',
          );
        }
      },
    );

    testComponents(
      'a word takes the step corner; a number and a dot take the pill',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in _kSizesWithRows) {
          final stepCorner = CoreBadgeStyle.defaultsBySize[size]!.borderRadius!;
          expect(
            _inline(_resolve(context, size: size).root)['border-radius'],
            stepCorner.toValue(),
            reason: '$size label',
          );
          for (final form in [CoreBadgeForm.count, CoreBadgeForm.dot]) {
            expect(
              _inline(
                _resolve(context, size: size, form: form).root,
              )['border-radius'],
              CoreBadgeStyle.defaultBorderRadius.toValue(),
              reason: '$size $form',
            );
          }
        }
        // md's word corner is 6 — a quarter of 24 on the ladder.
        expect(
          _inline(_resolve(context).root)['border-radius'],
          contains('var(--coui-radius-6)'),
        );
      },
    );

    testComponents(
      'an overridden height leaves the size class and goes inline as rem',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreBadgeStyle(minHeight: 30);
        final count = _resolve(
          context,
          form: CoreBadgeForm.count,
          badgeStyle: style,
        ).root;
        expect(
          _classes(count).where(
            (cls) => cls.startsWith('min-h-') || cls.startsWith('min-w-'),
          ),
          isEmpty,
        );
        expect(_inline(count)['min-height'], '1.875rem');
        expect(_inline(count)['min-width'], '1.875rem');

        final dot = _resolve(
          context,
          form: CoreBadgeForm.dot,
          badgeStyle: const CoreBadgeStyle(dotSize: 10),
        ).root;
        expect(
          _classes(dot).where(
            (cls) => cls.startsWith('w-') || cls.startsWith('h-'),
          ),
          isEmpty,
        );
        expect(_inline(dot)['width'], '0.625rem');
        expect(_inline(dot)['height'], '0.625rem');
      },
    );

    testComponents('xl2 has a row of its own, a step above xl', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final xl = _resolve(context, size: CoreComponentSize.xl);
      final xl2 = _resolve(context, size: CoreComponentSize.xl2);
      expect(_classes(xl2.root), contains('min-h-size36'));
      expect(xl2.root.className, isNot(xl.root.className));
    });
  });

  group('Badge typography — the step role with the form weight', () {
    testComponents(
      "a word is set at the role's weight and a number at 600, on the step "
      'role',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in _kSizesWithRows) {
          final role = CoreBadgeStyle.defaultsBySize[size]!.labelStyle!.token!;

          final label = _resolve(context, size: size).root;
          expect(_classes(label), contains('text-${role.name}'));
          expect(
            _inline(label),
            isNot(contains('font-weight')),
            reason: '$size label',
          );

          final count = _resolve(
            context,
            size: size,
            form: CoreBadgeForm.count,
          ).root;
          expect(_classes(count), contains('text-${role.name}'));
          expect(_inline(count)['font-weight'], '600', reason: '$size count');
        }
        // md's word is `labelSmall`.
        expect(_classes(_resolve(context).root), contains('text-label-small'));
      },
    );

    testComponents('a dot carries no label typography', (tester) async {
      final dot = _resolve(_themedContext(tester), form: CoreBadgeForm.dot);
      expect(_classes(dot.root).where((c) => c.startsWith('text-')), isEmpty);
      expect(_inline(dot.root).containsKey('font-weight'), isFalse);
    });
  });

  group('Badge leading dot', () {
    testComponents(
      'a circle of the step leading-dot diameter in the mark colour',
      (tester) async {
        final context = _themedContext(tester);
        for (final size in _kSizesWithRows) {
          final diameter = CoreBadgeStyle.defaultsBySize[size]!.leadingDotSize!;
          final side = 'size${diameter.toInt()}';
          final dot = _resolve(context, size: size).leadingDot;
          expect(_classes(dot), containsAll(['w-$side', 'h-$side']));
          expect(_inline(dot)['border-radius'], '50%');
        }

        for (final tone in CoreBadgeTone.values) {
          for (final variant in CoreBadgeVariant.values) {
            // The label's colour, unless the strength states one for the
            // dot (the outlined status tones: the line's colour).
            final resting = CoreBadgeStyle.defaultsByTone[tone]!
                .restingStyleFor(variant, CoreBadgeForm.label);
            final ink = resting.leadingDotColor ?? resting.foregroundColor!;
            expect(
              _classes(
                _resolve(context, tone: tone, variant: variant).leadingDot,
              ),
              contains('bg-${ink.tailwindColor}'),
              reason: '$tone × $variant',
            );
          }
        }
      },
    );

    testComponents(
      'a raw foreground override paints the leading dot inline',
      (tester) async {
        final dot = _resolve(
          _themedContext(tester),
          badgeStyle: const CoreBadgeStyle(foregroundColor: _kRawGreen),
        ).leadingDot;
        expect(_classes(dot).where((cls) => cls.startsWith('bg-')), isEmpty);
        expect(_inline(dot)['background-color'], 'rgb(0, 255, 0)');
      },
    );
  });

  group('Badge state layer — pressable only', () {
    testComponents(
      'a static badge has no states: no wash rule, no ring, no hover class',
      (tester) async {
        final context = _themedContext(tester);
        final root = _resolve(context).root;
        expect(root.className, isNot(contains('hover:')));
        expect(root.className, isNot(contains('focus-visible:outline')));
        expect(root.className, isNot(contains('outline-none')));
        expect(root.className, isNot(contains('cursor-pointer')));
        expect(_rules(context, interactive: false).css, isEmpty);
      },
    );

    testComponents(
      'a pressable badge washes its label colour over its fill — 8% while '
      'hovered, 16% while held by pointer or key — and states no focus wash',
      (tester) async {
        final context = _themedContext(tester);
        final css = _rules(context, scopeId: 'co-badge-wash').css;
        final scope = _surfaceScope('co-badge-wash');
        const hoverWash =
            'color-mix(in srgb, rgb(var(--coui-on-surface-variant)) 8%, '
            'rgb(var(--coui-surface-container-high)))';
        const pressedWash =
            'color-mix(in srgb, rgb(var(--coui-on-surface-variant)) 16%, '
            'rgb(var(--coui-surface-container-high)))';
        expect(
          css,
          contains(
            '$scope:hover{background-color:$hoverWash;'
            '$kWebSurfaceFillVar:from $hoverWash r g b !important;'
            '$kWebSurfaceFillAlphaVar:1 !important;}',
          ),
        );
        expect(
          css,
          contains(
            '$scope:active,$scope.$kClickableKeyPressedMarker'
            '{background-color:$pressedWash;'
            '$kWebSurfaceFillVar:from $pressedWash r g b !important;'
            '$kWebSurfaceFillAlphaVar:1 !important;}',
          ),
        );
        // Pressed is written after hover so it wins the tie while held.
        expect(
          css.indexOf(':hover{'),
          lessThan(css.indexOf(':active,')),
        );
        expect(css, isNot(contains(':focus{background')));
        expect(css, isNot(contains(':focus-visible{background')));
        // The old 80% hover fill is gone — no `hover:` class at all.
        expect(
          _resolve(context, interactive: true).root.className,
          isNot(contains('hover:')),
        );
      },
    );

    testComponents(
      'the wash on a marked fill stays under the material rule — no '
      '!important on the colour, so a translucent preset folds its share in',
      (tester) async {
        // A preset's material rule is `[data-coui-style] .coui-surface.<role>`
        // (0,3,0) and restates the fill from the surface vars. The state
        // rule is (0,2,0) — over the `bg-*` utility, under the material —
        // and hands that rule the wash through the same vars. An
        // `!important` colour here would paint the washed fill opaque
        // while the backdrop still frosted (Flutter keeps it translucent).
        final css = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-glass',
          tone: CoreBadgeTone.primary,
          variant: CoreBadgeVariant.filled,
        ).css;
        expect(css, isNot(contains('#co-badge-glass:hover')));
        expect(
          RegExp('background-color:[^;]*!important').hasMatch(css),
          isFalse,
        );
        expect(css, contains('${_surfaceScope('co-badge-glass')}:hover{'));
      },
    );

    testComponents(
      "a translucent token fill publishes the wash's own alpha — the ink at "
      'its weight over the fill at its alpha',
      (tester) async {
        final css = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-tint',
          badgeStyle: const CoreBadgeStyle(
            backgroundColor: CoreColor.token(CoreColors.primary, opacity: 0.5),
          ),
        ).css;
        // 0.08 + 0.5 × 0.92 and 0.16 + 0.5 × 0.84 — Flutter's
        // `Color.alphaBlend(ink @ w, fill @ 0.5)` alpha.
        expect(css, contains('$kWebSurfaceFillAlphaVar:0.54 !important;'));
        expect(css, contains('$kWebSurfaceFillAlphaVar:0.58 !important;'));
      },
    );

    testComponents(
      'the wash reads the CoreStateLayer weights the style states',
      (tester) async {
        expect(CoreBadgeStyle.defaultStateLayer, CoreStateLayer.standard);
        final css = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-heavy',
          badgeStyle: const CoreBadgeStyle(
            stateLayer: CoreStateLayer(
              hover: CoreOpacity.opacity12,
              focus: CoreOpacity.opacity12,
              pressed: CoreOpacity.opacity20,
            ),
          ),
        ).css;
        expect(css, contains(':hover{background-color:color-mix(in srgb, '));
        expect(css, contains(') 12%, '));
        expect(css, contains(') 20%, '));
        expect(css, isNot(contains(') 8%, ')));
      },
    );

    testComponents(
      'an outlined badge washes over its transparent fill, keeping the '
      "fill's zero alpha",
      (tester) async {
        final css = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-outlined',
          tone: CoreBadgeTone.destructive,
          variant: CoreBadgeVariant.outlined,
        ).css;
        expect(
          css,
          contains(
            'color-mix(in srgb, rgb(var(--coui-on-error-container)) 8%, '
            'rgb(var(--coui-surface) / 0%))',
          ),
        );
      },
    );

    testComponents(
      'a raw fill override is washed too — the rule carries the raw colour '
      'and outranks the inline fill',
      (tester) async {
        final css = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-raw-fill',
          badgeStyle: const CoreBadgeStyle(backgroundColor: _kRawGreen),
        ).css;
        expect(css, contains('#co-badge-raw-fill:hover{background-color:'));
        expect(css, contains('8%, rgb(0, 255, 0)) !important;}'));
        expect(css, isNot(contains(kWebSurfaceFillVar)));
      },
    );

    testComponents(
      'a dot has no label colour, so a pressable dot paints no wash',
      (tester) async {
        final css = _rules(
          _themedContext(tester),
          form: CoreBadgeForm.dot,
        ).css;
        expect(css, isEmpty);
      },
    );
  });

  group('Badge transition — every badge, on the move curve', () {
    testComponents(
      'a static badge transitions its colours too — the Flutter box is an '
      'AnimatedContainer either way — on the step clock and the move alias',
      (tester) async {
        final context = _themedContext(tester);
        for (final interactive in [false, true]) {
          final root = _resolve(context, interactive: interactive).root;
          expect(
            _classes(root),
            contains('transition-colors'),
            reason: 'interactive: $interactive',
          );
          expect(
            _classes(root).where((cls) => cls.startsWith('duration-')),
            isEmpty,
            reason: 'the clock rides inline, not a class',
          );
          expect(
            _inline(root)['transition-duration'],
            'var(--coui-duration-'
            '${CoreBadgeStyle.defaultTransitionDuration.inMilliseconds})',
          );
          expect(
            _inline(root)['transition-timing-function'],
            CoreEasing.move.toVarCss(),
          );
        }
      },
    );

    testComponents(
      'an off-scale duration honors reduced motion',
      (tester) async {
        final root = _resolve(
          _themedContext(tester),
          interactive: true,
          badgeStyle: const CoreBadgeStyle(
            transitionDuration: _kOffScaleDuration,
          ),
        ).root;
        expect(
          _inline(root)['transition-duration'],
          'calc(175ms * var(--coui-transition-motion-factor, 1))',
        );
      },
    );
  });

  group('Badge icon slots — the step icon style, handed to IconTheme', () {
    testComponents('each step hands its own icon size', (tester) async {
      final context = _themedContext(tester);
      for (final size in _kSizesWithRows) {
        expect(
          _resolve(context, size: size).iconStyle.size,
          CoreBadgeStyle.defaultsBySize[size]!.iconStyle!.size,
          reason: '$size',
        );
      }
      // The glyphs are not sized by a class on the root any more.
      expect(_resolve(context).root.className, isNot(contains('[&>svg]')));
    });

    testComponents(
      'an icon colour and an off-scale size reach the slots as stated — '
      'the leading and trailing icons can differ from the label',
      (tester) async {
        final iconStyle = _resolve(
          _themedContext(tester),
          badgeStyle: const CoreBadgeStyle(
            iconStyle: CoreIconStyle(size: 15, color: _kRawGreen),
          ),
        ).iconStyle;
        expect(iconStyle.size, 15);
        expect(iconStyle.color, _kRawGreen);
      },
    );

    testComponents(
      'with no icon colour stated the glyphs stay on currentColor — the '
      "label's colour",
      (tester) async {
        expect(_resolve(_themedContext(tester)).iconStyle.color, isNull);
      },
    );
  });

  group('Badge focus-ring — default (class-safe) path', () {
    testComponents(
      'a pressable default badge rides the focus-visible:outline-* utility '
      'classes on an unconditional outline-none resting state, and the '
      'scoped rules carry no ring',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context, interactive: true);
        expect(resolved.root.className.split(' '), contains('outline-none'));
        expect(
          _ringClasses(resolved.root.className),
          unorderedEquals(<String>[
            'focus-visible:outline-2',
            'focus-visible:outline-offset-2',
            'focus-visible:outline-focus-ring',
          ]),
        );
        // Keyboard focus only — a pointer press focuses the badge without
        // a ring, as Flutter's ring follows the focus highlight.
        expect(
          resolved.root.className
              .split(' ')
              .where((c) => c.startsWith('focus:')),
          isEmpty,
        );
        // The ring is an outline — no `ring-*` utilities, whose offset
        // band is a painted box-shadow.
        expect(resolved.root.className, isNot(contains('ring-offset')));

        final css = _rules(context).css;
        expect(css, isNot(contains(':focus')));
        expect(css, isNot(contains('outline')));
      },
    );
  });

  group('Badge focus-ring — gap band', () {
    testComponents(
      'a stated band leaves the class path and paints as a box-shadow over '
      'the resting cast — the band is the only box-shadow the ring writes',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreBadgeStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(
            offsetColor: CoreColor.token(CoreColors.secondary),
          ),
        );
        final resolved = _resolve(
          context,
          interactive: true,
          badgeStyle: style,
        );
        // No outline utility draws a box-shadow, so the classes drop.
        expect(_ringClasses(resolved.root.className), isEmpty);

        final rules = _rules(
          context,
          scopeId: 'co-badge-band',
          badgeStyle: style,
        );
        expect(
          rules.css,
          contains(
            [
              '#co-badge-band:focus-visible{',
              'outline-color:rgb(var(--coui-focus-ring));',
              'outline-width:var(--coui-stroke-width-2);',
              'outline-offset:calc(4.0px - var(--coui-stroke-width-2));',
              'box-shadow:0 0 0 calc(4.0px - var(--coui-stroke-width-2)) ',
              'rgb(var(--coui-secondary)), var(--coui-control-shadow);}',
            ].join(),
          ),
        );
      },
    );
  });

  group('Badge focus-ring — raw override (scoped-rule) path', () {
    testComponents(
      'a raw focusOutlineStyle.borderColor override does not throw — the '
      'ring classes are dropped and the ring paints via a scoped '
      '#id:focus-visible outline rule instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreBadgeStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
        );

        final resolved = _resolve(
          context,
          interactive: true,
          badgeStyle: style,
        );
        expect(resolved.root.className, contains('outline-none'));
        // The colour class cannot carry a raw colour, so the whole
        // `focus-visible:outline-*` block is dropped in favour of the
        // scoped rule.
        expect(_ringClasses(resolved.root.className), isEmpty);

        final rules = _rules(
          context,
          scopeId: 'co-badge-raw',
          badgeStyle: style,
        );
        expect(rules.css, contains('#co-badge-raw:focus-visible{'));
        expect(rules.css, contains('outline-color:rgb(0, 255, 0);'));
        // The default band is transparent — the outline offset is a real
        // gap, so the rule writes no box-shadow and the badge keeps its
        // own resting cast.
        expect(rules.css, isNot(contains('box-shadow')));
      },
    );

    testComponents(
      'a sub-1 ringOpacity override also routes to the scoped rule and is '
      'honoured (the class path could not express ring alpha)',
      (tester) async {
        final rules = _rules(
          _themedContext(tester),
          scopeId: 'co-badge-alpha',
          badgeStyle: const CoreBadgeStyle(
            focusOutlineStyle: CoreFocusOutlineStyle(ringOpacity: 0.5),
          ),
        );
        expect(rules.css, contains('/ 50%)'));
      },
    );
  });

  group('Badge theme chain', () {
    const themeStyle = CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    );
    const toneStyle = CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    );
    const variantStyle = CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    );
    const instanceStyle = CoreBadgeStyle(
      backgroundColor: CoreColor.token(CoreColors.inverseSurface),
    );

    String fillOf(
      ComponentTester tester,
      CoreBadgeTheme theme, {
      CoreBadgeStyle? badgeStyle,
    }) {
      final classes = _classes(
        _resolve(
          _contextUnder(tester, theme),
          tone: CoreBadgeTone.success,
          variant: CoreBadgeVariant.filled,
          badgeStyle: badgeStyle,
        ).root,
      );
      return classes.singleWhere((cls) => cls.startsWith('bg-'));
    }

    testComponents(
      'theme style → tone row → variant row → instance, later wins',
      (tester) async {
        const all = CoreBadgeTheme(
          style: themeStyle,
          toneStyles: {CoreBadgeTone.success: toneStyle},
          variantStyles: {CoreBadgeVariant.filled: variantStyle},
        );
        expect(
          fillOf(tester, all, badgeStyle: instanceStyle),
          'bg-inverse-surface',
        );
        expect(fillOf(tester, all), 'bg-surface-container');
        expect(
          fillOf(
            tester,
            const CoreBadgeTheme(
              style: themeStyle,
              toneStyles: {CoreBadgeTone.success: toneStyle},
            ),
          ),
          'bg-tertiary',
        );
        expect(
          fillOf(tester, const CoreBadgeTheme(style: themeStyle)),
          'bg-secondary',
        );
        // Nothing stated — the tone row's filled fill.
        expect(fillOf(tester, const CoreBadgeTheme()), 'bg-success');
      },
    );

    testComponents(
      'a tone row reaches only that tone, a variant row only that variant',
      (tester) async {
        final context = _contextUnder(
          tester,
          const CoreBadgeTheme(
            toneStyles: {CoreBadgeTone.success: toneStyle},
            variantStyles: {CoreBadgeVariant.outlined: variantStyle},
          ),
        );
        expect(
          _classes(
            _resolve(context, tone: CoreBadgeTone.info).root,
          ),
          contains('bg-info-container'),
        );
        expect(
          _classes(_resolve(context, tone: CoreBadgeTone.success).root),
          contains('bg-tertiary'),
        );
        expect(
          _classes(
            _resolve(context, variant: CoreBadgeVariant.outlined).root,
          ),
          contains('bg-surface-container'),
        );
      },
    );

    testComponents(
      "the scoped wash sees the theme chain's fill, not the table's",
      (tester) async {
        final css = _rules(
          _contextUnder(tester, const CoreBadgeTheme(style: themeStyle)),
          scopeId: 'co-badge-themed',
        ).css;
        expect(css, contains('rgb(var(--coui-secondary)))'));
      },
    );
  });
}
