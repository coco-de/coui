import 'package:coui_web/coui_web.dart';
// dot_indicator_style.dart is not re-exported by the barrel — import it
// directly for resolver-level assertions.
import 'package:coui_web/src/components/display/dot_indicator/dot_indicator_style.dart';
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

/// Every rendered element, so a test can assert which one a class landed
/// on rather than only that it landed somewhere.
List<DomComponent> _elements(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .toList();

const _kRawGreen = CoreColor(0xFF00FF00);

/// Dot count used by every case here — enough dots that the selected one
/// and an unselected one are both present.
const _kLength = 3;

ResolvedDotIndicator _resolve(
  BuildContext context, {
  CoreDotIndicatorStyle? style,
  CoreAxis direction = CoreAxis.horizontal,
  String scopeId = 'sc',
}) => resolveDotIndicator(
  context,
  direction: direction,
  size: CoreDotIndicatorSize.defaultSize,
  length: _kLength,
  activeIndex: 0,
  isClickable: true,
  scopeId: scopeId,
  dotIndicatorStyle: style,
);

ResolvedDotIndicatorRules _rules(
  BuildContext context, {
  CoreDotIndicatorStyle? style,
  String scopeId = 'sc',
}) => resolveDotIndicatorRules(
  context,
  scopeId: scopeId,
  isClickable: true,
  dotIndicatorStyle: style,
);

void main() {
  group('DotIndicator active length', () {
    testComponents('without an override the selected dot remains round', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = _resolve(
        context,
        style: const CoreDotIndicatorStyle(dotSize: 6),
      );
      final active = resolved.dots[0].root.inlineStyles!.properties;
      expect(active['width'], '0.375rem');
      expect(active['height'], '0.375rem');
    });
    for (final direction in CoreAxis.values) {
      testComponents('active length follows $direction', (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(
          context,
          direction: direction,
          style: const CoreDotIndicatorStyle(dotSize: 6, activeLength: 18),
        );
        final active = resolved.dots[0].root.inlineStyles!.properties;
        final inactive = resolved.dots[1].root.inlineStyles!.properties;
        expect(
          active['width'],
          direction == CoreAxis.horizontal ? '1.125rem' : '0.375rem',
        );
        expect(
          active['height'],
          direction == CoreAxis.vertical ? '1.125rem' : '0.375rem',
        );
        expect(inactive['width'], '0.375rem');
        expect(inactive['height'], '0.375rem');
      });
    }
  });
  group('DotIndicator adjacent pointer targets', () {
    for (final direction in CoreAxis.values) {
      testComponents('spacing is never animated for $direction', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final dots = _resolve(context, direction: direction).dots;
        for (final dot in dots) {
          final properties = dot.root.inlineStyles!.properties;
          final transitions = properties['transition-property']!
              .split(',')
              .map((value) => value.trim())
              .toSet();
          expect(transitions, isNot(contains('all')));
          expect(transitions, isNot(contains('margin')));
          expect(transitions, isNot(contains('margin-inline-end')));
          expect(transitions, isNot(contains('margin-bottom')));
          expect(
            transitions,
            containsAll(['width', 'height', 'transform', 'box-shadow']),
          );
        }
      });
    }
    for (final direction in CoreAxis.values) {
      testComponents('split the visible gap for $direction', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = _resolve(
          context,
          direction: direction,
          style: const CoreDotIndicatorStyle(
            dotSize: 6,
            activeLength: 18,
            spacing: 6,
          ),
        );
        final first = resolved.dots[0].root.inlineStyles!.properties;
        final middle = resolved.dots[1].root.inlineStyles!.properties;
        final last = resolved.dots[2].root.inlineStyles!.properties;
        expect(first['--co-dot-hit-before'], 'max(50%, 12.0px)');
        expect(
          first['--co-dot-hit-after'],
          'min(max(50%, 12.0px), calc(50% + var(--coui-space-6) / 2))',
        );
        expect(middle['--co-dot-hit-before'], first['--co-dot-hit-after']);
        expect(
          middle['--co-dot-hit-after'],
          'min(max(50%, 12.0px), calc(50% + var(--coui-space-6) / 2))',
        );
        expect(last['--co-dot-hit-before'], middle['--co-dot-hit-after']);
        expect(last['--co-dot-hit-after'], 'max(50%, 12.0px)');
        expect(
          resolved.dots[0].root.className,
          contains(
            direction == CoreAxis.horizontal
                ? 'co-dot-hit-h-sc'
                : 'co-dot-hit-v-sc',
          ),
        );
      });
    }
    for (final direction in CoreAxis.values) {
      testComponents('explicit spacing uses the $direction axis', (
        tester,
      ) async {
        final context = _themedContext(tester);
        final resolved = _resolve(
          context,
          direction: direction,
          style: const CoreDotIndicatorStyle(dotSize: 6, spacing: 30),
        );
        final first = resolved.dots.first.root.inlineStyles!.properties;
        final last = resolved.dots.last.root.inlineStyles!.properties;
        final property = direction == CoreAxis.horizontal
            ? 'margin-inline-end'
            : 'margin-bottom';
        expect(first[property], '1.875rem');
        expect(last, isNot(contains(property)));
        expect(first['width'], '0.375rem');
        expect(first['height'], '0.375rem');
        expect(
          first['--co-dot-hit-after'],
          contains('calc(50% + 1.875rem / 2)'),
        );
      });
    }
    testComponents('instance style wins over the theme for hit boundaries', (
      tester,
    ) async {
      late BuildContext context;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              dotIndicator: CoreDotIndicatorTheme(
                style: CoreDotIndicatorStyle(
                  dotSize: 10,
                  activeLength: 20,
                  spacing: 16,
                ),
              ),
            ),
          ),
          child: _ContextCapture((value) => context = value),
        ),
      );
      final themed = _resolve(context).dots.first.root.inlineStyles!.properties;
      final overridden = _resolve(
        context,
        style: const CoreDotIndicatorStyle(
          dotSize: 6,
          activeLength: 18,
          spacing: 6,
        ),
      ).dots.first.root.inlineStyles!.properties;
      expect(themed['width'], '1.25rem');
      expect(themed['margin-inline-end'], 'var(--coui-space-16)');
      expect(overridden['width'], '1.125rem');
      expect(overridden['margin-inline-end'], 'var(--coui-space-6)');
      expect(
        overridden['--co-dot-hit-after'],
        'min(max(50%, 12.0px), calc(50% + var(--coui-space-6) / 2))',
      );
    });
    testComponents('non-interactive dots do not get a target partition', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveDotIndicator(
        context,
        direction: CoreAxis.horizontal,
        size: CoreDotIndicatorSize.defaultSize,
        length: 3,
        activeIndex: 0,
        isClickable: false,
        scopeId: 'passive',
      );
      expect(resolved.dots[0].root.className, isNot(contains('co-dot-hit-')));
      expect(
        resolved.dots[0].root.inlineStyles!.properties,
        isNot(contains('--co-dot-hit-before')),
      );
      expect(
        resolveDotIndicatorRules(
          context,
          scopeId: 'passive',
          isClickable: false,
        ).css,
        isEmpty,
      );
    });
  });

  group('DotIndicator pseudo-state — default (class-safe) path', () {
    testComponents(
      'clickable dots keep hover:border-* + group-focus-visible:outline-* '
      'classes while the target partition has a scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = _resolve(context);
        expect(resolved.dots[1].root.className, contains('hover:border-'));
        final selected = resolved.dots[0].root.className.split(' ');
        // The selected dot's ring is an outline: `outline-none` is its
        // resting state, the group's keyboard focus moves the colour.
        expect(
          selected,
          containsAll(<String>[
            'outline-none',
            'group-focus-visible:outline-2',
            'group-focus-visible:outline-offset-2',
            'group-focus-visible:outline-focus-ring',
          ]),
        );
        expect(resolved.dots[0].root.className, isNot(contains('ring-')));
        // Only the selected dot carries a ring.
        expect(
          resolved.dots[1].root.className,
          isNot(contains('group-focus-visible:outline')),
        );
        expect(_rules(context).css, contains('co-dot-hit-horizontal::after'));
        expect(_rules(context).css, isNot(contains('co-dot-r-sc')));
      },
    );
  });

  group('DotIndicator pseudo-state — gap band', () {
    testComponents(
      'a stated band (the slide Carousel states one) leaves the class path '
      'and paints as a box-shadow on the selected dot',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreDotIndicatorStyle(
          focusOutlineStyle:
              CoreCarouselStyle.defaultOverlayIndicatorFocusOutlineStyle,
        );
        final resolved = _resolve(context, style: style, scopeId: 'd4');
        expect(
          resolved.dots[0].root.className,
          isNot(contains('group-focus-visible:outline')),
        );
        expect(resolved.dots[0].root.className, contains('co-dot-r-d4'));

        final css = _rules(context, style: style, scopeId: 'd4').css;
        expect(css, contains('.group:focus-visible .co-dot-raw-ring'));
        expect(css, contains(':where(.co-dot-ring-band)'));
        expect(resolved.dots[0].root.className, contains('co-dot-ring-band'));
        final values = resolved.dots[0].root.inlineStyles!.properties;
        expect(
          values['--co-dot-focus-outline-color'],
          'rgb(var(--coui-focus-ring))',
        );
        expect(
          values['--co-dot-focus-outline-width'],
          'var(--coui-stroke-width-2)',
        );
        expect(
          values['--co-dot-focus-outline-offset'],
          'calc(4.0px - var(--coui-stroke-width-2))',
        );
        expect(
          values['--co-dot-focus-box-shadow'],
          '0 0 0 calc(4.0px - var(--coui-stroke-width-2)) '
          'rgb(var(--coui-surface))',
        );
      },
    );
  });

  group('DotIndicator pseudo-state — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverBorderColor drops the hover:border class, adds the scope '
      'class, and emits a .co-dot-h:hover rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreDotIndicatorStyle(hoverBorderColor: _kRawGreen);
        final resolved = _resolve(context, style: style, scopeId: 'd1');
        expect(
          resolved.dots[1].root.className,
          isNot(contains('hover:border-')),
        );
        expect(resolved.dots[1].root.className, contains('co-dot-h-d1'));

        final css = _rules(context, style: style, scopeId: 'd1').css;
        expect(css, contains('.co-dot-raw-hover:hover'));
        expect(
          resolved
              .dots[1]
              .root
              .inlineStyles!
              .properties['--co-dot-hover-border-color'],
          'rgb(0, 255, 0)',
        );
        expect(
          resolved.dots[0].root.inlineStyles!.properties,
          isNot(contains('--co-dot-hover-border-color')),
        );
      },
    );

    testComponents(
      'a raw focusOutlineStyle.borderColor drops the group ring classes on '
      'the active dot and emits a .group:focus-visible .co-dot-r rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreDotIndicatorStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderColor: _kRawGreen),
        );
        final resolved = _resolve(context, style: style, scopeId: 'd2');
        expect(
          resolved.dots[0].root.className,
          isNot(contains('group-focus-visible:outline')),
        );
        expect(resolved.dots[0].root.className, contains('co-dot-r-d2'));

        final css = _rules(context, style: style, scopeId: 'd2').css;
        expect(css, contains('.group:focus-visible .co-dot-raw-ring'));
        final values = resolved.dots[0].root.inlineStyles!.properties;
        expect(values['--co-dot-focus-outline-color'], 'rgb(0, 255, 0)');
        // A shared band rule exists, but a bandless dot must never match it.
        expect(
          resolved.dots[0].root.className,
          isNot(contains('co-dot-ring-band')),
        );
        expect(values, isNot(contains('--co-dot-focus-box-shadow')));
      },
    );

    testComponents(
      'a fractional focusOutlineStyle.borderWidth drops the group ring '
      'classes and paints both derived numbers exactly (#3993)',
      (tester) async {
        final context = _themedContext(tester);
        // This is the derived path: the dot computes
        // `offset = align - width`, so ONE fractional override makes BOTH
        // numbers fractional (width 2.5, offset 4 - 2.5 = 1.5). Truncation
        // called that pair `outline-2` + `outline-offset-1` — two wrong
        // numbers from a single override, and neither is the one
        // requested.
        const style = CoreDotIndicatorStyle(
          focusOutlineStyle: CoreFocusOutlineStyle(borderWidth: 2.5),
        );
        final resolved = _resolve(context, style: style, scopeId: 'd3');
        expect(
          resolved.dots[0].root.className,
          isNot(contains('group-focus-visible:outline')),
        );
        expect(resolved.dots[0].root.className, contains('co-dot-r-d3'));

        final css = _rules(context, style: style, scopeId: 'd3').css;
        expect(css, contains('.group:focus-visible .co-dot-raw-ring'));
        // width 2.5 → 2.5px; offset 1.5 → 1.5px (px-fixed stroke; a
        // width off the stroke scale is a literal, and so is its gap).
        final values = resolved.dots[0].root.inlineStyles!.properties;
        expect(values['--co-dot-focus-outline-width'], '2.5px');
        expect(values['--co-dot-focus-outline-offset'], '1.5px');
      },
    );
  });

  group(
    'DotIndicator pointer target — the overlay must not shadow the dot',
    () {
      testComponents(
        'the element carrying hover chrome is the element carrying the marker',
        (tester) async {
          // The pointer-target overlay (`.coui-touch-target::after`) accepts
          // the pointer — that is its job. So it makes the marked element
          // the hit target, and any DESCENDANT of it stops matching
          // `:hover`. Putting the marker on the surrounding `Clickable`
          // therefore killed every hover affordance on the dot inside it.
          //
          // Asserted on rendered elements rather than on the resolver,
          // because the resolver cannot see which element the widget
          // finally hangs each class on — which is exactly how the marker
          // ended up one level above the chrome it was supposed to sit with.
          pumpWithTheme(
            tester,
            DotIndicator(onChanged: (_) {}, index: 0, length: _kLength),
          );

          final withHover = _elements(
            tester,
          ).where((c) => (c.classes ?? '').contains('hover:')).toList();
          expect(withHover, isNotEmpty, reason: 'no hover chrome rendered');
          for (final element in withHover) {
            expect(
              (element.classes ?? '').split(' '),
              contains(kWebTouchTargetMarker),
              reason:
                  'hover chrome sits on an element without the pointer-target '
                  'marker — if the marker is on an ancestor, the overlay eats '
                  'the hover and this chrome never paints',
            );
          }
        },
      );

      testComponents('a non-interactive indicator carries no marker', (
        tester,
      ) async {
        // Same reasoning as the display-only `Chip`: an overlay that
        // captures pointers and does nothing with them is worse than a
        // small target.
        pumpWithTheme(tester, DotIndicator(index: 0, length: _kLength));

        for (final element in _elements(tester)) {
          expect(
            (element.classes ?? '').split(' '),
            isNot(contains(kWebTouchTargetMarker)),
          );
        }
      });
    },
  );

  group('DotIndicator dot chrome', () {
    testComponents('hover affordances are inactive-only, as in Flutter', (
      tester,
    ) async {
      // Flutter draws the selected dot with `_ActiveDotItem`, which has no
      // `MouseRegion` and no `AnimatedScale` — hovering it changes nothing.
      // `hoverBorderColor` is likewise defined on the contract as the
      // colour "for clickable inactive dots".
      final context = _themedContext(tester);
      final resolved = _resolve(context);

      expect(resolved.dots[0].root.className, isNot(contains('hover:')));
      expect(resolved.dots[1].root.className, contains('hover:'));
      // The selected dot is still a pointer target — it is still clickable
      // and still drawn under the floor.
      expect(
        resolved.dots[0].root.className.split(' '),
        contains(kWebTouchTargetMarker),
      );
    });
  });
}
