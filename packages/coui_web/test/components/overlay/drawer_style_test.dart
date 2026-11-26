import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

/// Opens a drawer over a real [OverlayHost] the way a page does, so the
/// panel the entry actually renders can be inspected.
class _DrawerOpener extends StatefulComponent {
  const _DrawerOpener({required this.side, required this.fillSafeArea});

  final CoreDrawerSide side;
  final bool fillSafeArea;

  @override
  State<_DrawerOpener> createState() => _DrawerOpenerState();
}

class _DrawerOpenerState extends State<_DrawerOpener> {
  @override
  void initState() {
    super.initState();
    // Deferred like every real caller: mounting notifies the host, and a
    // host `setState` reached from inside build throws.
    unawaited(
      Future<void>.microtask(() {
        if (!mounted) return;
        unawaited(
          openDrawer<void>(
            context: context,
            side: component.side,
            builder: (close) => Drawer(
              side: component.side,
              fillSafeArea: component.fillSafeArea,
              content: const Component.text('sheet'),
            ),
          ),
        );
      }),
    );
  }

  @override
  Component build(BuildContext context) => const span([], id: 'opener');
}

/// The rendered drawer panel — the only element carrying `role="dialog"`.
Finder _renderedPanel() => find.byComponentPredicate(
  (c) => c is DomComponent && c.attributes?['role'] == 'dialog',
);

Map<String, String> _renderedPanelStyles(ComponentTester tester) {
  final panel = _renderedPanel().evaluate().single.component as DomComponent;
  return panel.styles?.properties ?? const {};
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

void main() {
  group(
    'Drawer panel border width reaches the strokeFloor CSS-variable seat (#3771)',
    () {
      testComponents(
        'the default panelBorderWidth emits the "var(--coui-stroke-width-1)" '
        'token variable on the docked edge, not a raw rem literal',
        (tester) async {
          final context = _themedContext(tester);
          final resolved = resolveDrawer(
            context,
            side: CoreDrawerSide.left,
            open: true,
            dragDelta: 0,
          );

          // Before the fix `panelBorderWidth` was emitted as
          // `'${panelBorderWidth / kRemDivisor}rem'` — a raw literal that
          // never touches `var(--coui-stroke-width-1)`, so a `strokeFloor`
          // surface style (whose CSS override targets exactly that
          // variable) had no effect on the docked edge at all.
          expect(
            resolved.panel.inlineStyles?.properties['border-right-width'],
            'var(--coui-stroke-width-1)',
          );
        },
      );

      testComponents(
        'an arbitrary panelBorderWidth override still renders as a literal '
        'px value (no token step to route through a CSS variable)',
        (tester) async {
          final context = _themedContext(tester);
          const style = CoreDrawerStyle(panelBorderWidth: 7);
          final resolved = resolveDrawer(
            context,
            side: CoreDrawerSide.left,
            open: true,
            dragDelta: 0,
            drawerStyle: style,
          );

          expect(
            resolved.panel.inlineStyles?.properties['border-right-width'],
            '7px',
          );
        },
      );
    },
  );
  group('Drawer fillSafeArea', () {
    /// Inline styles of the resolved panel for [side] with the flag as given.
    Map<String, String> panelStyles(
      ComponentTester tester,
      CoreDrawerSide side, {
      bool? fillSafeArea,
    }) {
      final context = _themedContext(tester);
      final resolved = fillSafeArea == null
          ? resolveDrawer(context, side: side, open: true, dragDelta: 0)
          : resolveDrawer(
              context,
              side: side,
              open: true,
              dragDelta: 0,
              fillSafeArea: fillSafeArea,
            );
      return resolved.panel.inlineStyles?.properties ?? const {};
    }

    const paddingProperties = [
      'padding-top',
      'padding-right',
      'padding-bottom',
      'padding-left',
    ];

    testComponents('is off on the widget and the contract by default', (
      tester,
    ) async {
      expect(CoreDrawerContract.defaultFillSafeArea, isFalse);
      expect(const Drawer(content: Component.text('x')).fillSafeArea, isFalse);
      expect(
        const Drawer(
          content: Component.text('x'),
        ).copyWith(fillSafeArea: true).fillSafeArea,
        isTrue,
      );
      expect(
        const Drawer(
          content: Component.text('x'),
          fillSafeArea: true,
        ).copyWith(title: 'T').fillSafeArea,
        isTrue,
      );
    });

    for (final side in CoreDrawerSide.values) {
      testComponents('off — the ${side.name} panel adds no inset padding', (
        tester,
      ) async {
        final styles = panelStyles(tester, side);

        for (final property in paddingProperties) {
          expect(styles, isNot(contains(property)));
        }
        // An explicit `false` is the default, not a second state.
        expect(
          panelStyles(tester, side, fillSafeArea: false),
          equals(styles),
        );
      });
    }

    const dockedEdge = {
      CoreDrawerSide.left: 'left',
      CoreDrawerSide.right: 'right',
      CoreDrawerSide.top: 'top',
      CoreDrawerSide.bottom: 'bottom',
    };
    for (final entry in dockedEdge.entries) {
      testComponents(
        'on — the ${entry.key.name} panel pads its ${entry.value} edge by the '
        'safe-area inset',
        (tester) async {
          final styles = panelStyles(tester, entry.key, fillSafeArea: true);

          expect(
            styles['padding-${entry.value}'],
            'env(safe-area-inset-${entry.value}, 0.0rem)',
          );
          // Only the docked edge — every other edge is untouched.
          for (final property in paddingProperties) {
            if (property == 'padding-${entry.value}') continue;
            expect(styles, isNot(contains(property)));
          }
        },
      );
    }

    testComponents('on — nothing but that one padding changes', (
      tester,
    ) async {
      final off = panelStyles(tester, CoreDrawerSide.bottom);
      final on = panelStyles(
        tester,
        CoreDrawerSide.bottom,
        fillSafeArea: true,
      );

      expect(
        {...on}..remove('padding-bottom'),
        equals(off),
        reason:
            'the surface (fill, border, radius, shadow, extent) is the '
            'same either way',
      );
    });

    group('reaches the panel the entry renders', () {
      testComponents('on — the mounted bottom panel carries the padding', (
        tester,
      ) async {
        tester.pumpComponent(
          Theme.defaults(
            child: const OverlayHost(
              child: _DrawerOpener(
                side: CoreDrawerSide.bottom,
                fillSafeArea: true,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(
          _renderedPanelStyles(tester)['padding-bottom'],
          'env(safe-area-inset-bottom, 0.0rem)',
        );
      });

      testComponents('off — the mounted panel carries none', (tester) async {
        tester.pumpComponent(
          Theme.defaults(
            child: const OverlayHost(
              child: _DrawerOpener(
                side: CoreDrawerSide.bottom,
                fillSafeArea: false,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(_renderedPanelStyles(tester), isNot(contains('padding-bottom')));
      });
    });
  });
}
