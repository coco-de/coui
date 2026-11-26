import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The slot `<div>` that holds the child labelled [label].
DomComponent _slotOf(String label) {
  final element = find.text(label).evaluate().single;
  DomComponent? slot;
  element.visitAncestorElements((ancestor) {
    final component = ancestor.component;
    if (component is DomComponent &&
        component.styles?.properties['grid-area'] != null) {
      slot = component;

      return false;
    }

    return true;
  });

  return slot!;
}

String _prop(DomComponent slot, String name) =>
    slot.styles?.properties[name] ?? '';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);

    return const div([]);
  }
}

IndexedSwitcher _switcher(int index, {CoreIndexedSwitcherStyle? style}) =>
    IndexedSwitcher(
      index: index,
      indexedSwitcherStyle: style,
      children: const [
        Component.text('home'),
        Component.text('search'),
        Component.text('profile'),
      ],
    );

void main() {
  group('IndexedSwitcher', () {
    testComponents('every child is in the document; only the indexed one '
        'is shown', (tester) async {
      pumpWithTheme(tester, _switcher(1));

      expect(_prop(_slotOf('search'), 'visibility'), 'visible');
      expect(_prop(_slotOf('search'), 'opacity'), '1');
      for (final hidden in ['home', 'profile']) {
        expect(_prop(_slotOf(hidden), 'visibility'), 'hidden');
        expect(_prop(_slotOf(hidden), 'opacity'), '0');
      }
    });

    testComponents('hidden slots are inert; the shown one is not', (
      tester,
    ) async {
      pumpWithTheme(tester, _switcher(0));

      expect(_slotOf('home').attributes?['inert'], isNull);
      expect(_slotOf('search').attributes?['inert'], '');
      expect(_slotOf('profile').attributes?['inert'], '');
    });

    testComponents('all slots share one grid cell, so the root is as large '
        'as its largest child', (tester) async {
      pumpWithTheme(tester, _switcher(0));

      for (final label in ['home', 'search', 'profile']) {
        expect(_prop(_slotOf(label), 'grid-area'), '1 / 1');
      }
    });

    testComponents('the shown slot fades in after the fade-out, on the '
        'design-system tokens', (tester) async {
      pumpWithTheme(tester, _switcher(0));

      final enter = durationMsCss(
        CoreIndexedSwitcherStyle.defaultEnterDuration.inMilliseconds,
      );
      final exit = durationMsCss(
        CoreIndexedSwitcherStyle.defaultExitDuration.inMilliseconds,
      );
      final enterCurve = CoreIndexedSwitcherStyle.defaultEnterCurve.toVarCss();
      expect(
        _prop(_slotOf('home'), 'transition'),
        'opacity $enter $enterCurve $exit, visibility 0s',
      );
      // The token variables are what a reduced-motion request zeroes.
      expect(enter, startsWith('var(--coui-duration-'));
      expect(exit, startsWith('var(--coui-duration-'));
    });

    testComponents('a hidden slot fades out, then turns hidden', (
      tester,
    ) async {
      pumpWithTheme(tester, _switcher(0));

      final exit = durationMsCss(
        CoreIndexedSwitcherStyle.defaultExitDuration.inMilliseconds,
      );
      final exitCurve = CoreIndexedSwitcherStyle.defaultExitCurve.toVarCss();
      expect(
        _prop(_slotOf('search'), 'transition'),
        'opacity $exit $exitCurve, visibility 0s linear $exit',
      );
    });

    testComponents('the instance style reaches both transitions', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _switcher(
          0,
          style: const CoreIndexedSwitcherStyle(
            exitDuration: Duration.zero,
            enterDuration: Duration(milliseconds: CoreDuration.slow),
            enterCurve: CoreEasing.move,
          ),
        ),
      );

      final shown = _prop(_slotOf('home'), 'transition');
      expect(shown, contains(durationMsCss(CoreDuration.slow)));
      expect(shown, contains(CoreEasing.move.toVarCss()));
      expect(shown, contains(durationMsCss(0)));
      expect(
        _prop(_slotOf('search'), 'transition'),
        contains(durationMsCss(0)),
      );
    });

    testComponents('the component theme sets the timing', (tester) async {
      final themed = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          indexedSwitcher: CoreIndexedSwitcherTheme(
            style: CoreIndexedSwitcherStyle(
              enterDuration: Duration(milliseconds: CoreDuration.slow),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themed, child: _ContextCapture((c) => context = c)),
      );

      final resolved = resolveIndexedSwitcher(context);
      expect(
        resolved.shownSlot.inlineStyles?.properties['transition'],
        contains(durationMsCss(CoreDuration.slow)),
      );
    });

    testComponents('caller id and classes reach the root', (tester) async {
      pumpWithTheme(
        tester,
        const IndexedSwitcher(
          id: 'shell',
          classes: 'flex-1',
          children: [Component.text('home')],
        ),
      );

      final root = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere((c) => c.id == 'shell');
      expect(root.classes, contains('flex-1'));
      expect(root.classes, contains('grid'));
    });

    test('withStyle merges onto the instance style', () {
      final switcher = const IndexedSwitcher(
        indexedSwitcherStyle: CoreIndexedSwitcherStyle(
          exitDuration: Duration.zero,
        ),
        children: [Component.text('home')],
      ).withStyle(const CoreIndexedSwitcherStyle(enterCurve: CoreEasing.move));

      expect(switcher.indexedSwitcherStyle?.exitDuration, Duration.zero);
      expect(switcher.indexedSwitcherStyle?.enterCurve, CoreEasing.move);
    });
  });
}
