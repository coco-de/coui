import 'package:coui_web/coui_web.dart';
// navigation_bar_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/navigation_bar/navigation_bar_style.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The Web twin of the Flutter `navigation_bar_selection_mark_test`.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

Component _host(Component child) => CoUIWeb(theme: .coui, child: child);

/// Bare-label tabs — the bar the selection mark was added for.
NavigationBar _bar({
  CoreNavigationSelectionMark selectionMark = CoreNavigationSelectionMark.dot,
  CoreNavigationBarMode mode = CoreNavigationBarMode.bar,
  CoreNavigationLabelPosition? labelPosition,
  CoreNavigationBarStyle? navigationBarStyle,
}) {
  return NavigationBar(
    id: 'nav',
    mode: mode,
    labelMode: CoreNavigationLabelMode.all,
    labelPosition: labelPosition,
    selectionMark: selectionMark,
    selectedIndex: 0,
    onSelected: (_) {},
    navigationBarStyle: navigationBarStyle,
    items: const [
      CoreNavigationBarItem.destination(label: 'Home'),
      CoreNavigationBarItem.destination(label: 'Search'),
      CoreNavigationBarItem.destination(label: 'Profile'),
    ],
  );
}

/// The item chrome of every destination.
const _destination = '[data-coui-nav-chrome]';

/// The column that stacks a marked destination's dot over its content.
const _column = '$_destination > span.flex-col';

/// The selection-mark wrapper of a marked destination.
const _mark = '$_column > span[aria-hidden="true"]';

/// The dot itself — the composed `Badge`.
const _dot = '$_mark > span';

/// The spacer between the dot and the content.
const _gap = '$_column > div';

void main() {
  group('NavigationBar selectionMark (Web)', () {
    testServer('none draws no mark — the bar it was before', (tester) async {
      tester.pumpComponent(
        _host(_bar(selectionMark: CoreNavigationSelectionMark.none)),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll(_column), isEmpty);
      expect(document.querySelectorAll(_mark), isEmpty);
      // The content span sits straight in the item chrome.
      for (final destination in document.querySelectorAll(_destination)) {
        expect(
          destination.children.first.attributes['style'],
          contains('flex-direction: column'),
        );
      }
    });

    testServer('dot: every destination keeps the room, one shows it', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;
      final marks = document.querySelectorAll(_mark);

      expect(marks, hasLength(3));
      expect(marks[0].attributes['style'], contains('opacity: 1'));
      expect(marks[1].attributes['style'], contains('opacity: 0'));
      expect(marks[2].attributes['style'], contains('opacity: 0'));
    });

    testServer('the fade rides the selection clock and the move curve', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;

      // Through the duration scale's variable, so reduced motion reaches it.
      expect(
        document.querySelector(_mark)!.attributes['style'],
        contains(
          'transition: opacity var(--coui-duration-150) '
          '${CoreEasing.move.toVarCss()}',
        ),
      );
      // The destination's own colour change rides the same variable.
      expect(
        document.querySelector(_destination)!.attributes['style'],
        contains('transition-duration: var(--coui-duration-150)'),
      );
    });

    testServer('the dot is a 4px badge dot, 6 above its label', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;
      final column = document.querySelector(_column)!;
      final dot = document.querySelector(_dot)!;

      expect(column.classes, containsAll(['inline-flex', 'items-center']));
      expect(document.querySelector(_mark)!.classes, contains('flex'));
      expect(dot.attributes['style'], contains('width: 0.25rem'));
      expect(dot.attributes['style'], contains('height: 0.25rem'));
      expect(
        document.querySelector(_gap)!.attributes['style'],
        contains('flex-basis: var(--coui-space-6)'),
      );
      // The dot reads in the selected label's colour — the bar's `primary`
      // (#5740).
      expect(dot.classes, contains('bg-primary'));
      expect(
        document.getElementById('nav-item-0-label')!.classes,
        contains('text-primary'),
      );
    });

    testServer('the mark adds nothing to the destination name', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar()));
      final document = (await tester.request('/')).document!;

      expect(
        document
            .querySelector('[data-coui-nav-index="0"]')!
            .attributes['aria-labelledby'],
        'nav-item-0-label',
      );
      expect(document.querySelectorAll(_mark), hasLength(3));
    });

    for (final (name, bar) in [
      ('the sidebar', _bar(mode: CoreNavigationBarMode.sidebar)),
      (
        'a label beside its icon',
        _bar(labelPosition: CoreNavigationLabelPosition.end),
      ),
    ]) {
      testServer('$name is a row, so it draws no mark', (tester) async {
        tester.pumpComponent(_host(bar));
        final document = (await tester.request('/')).document!;

        expect(document.querySelectorAll(_mark), isEmpty);
      });
    }

    testServer('the rail stacks its labels, so it takes the mark', (
      tester,
    ) async {
      tester.pumpComponent(_host(_bar(mode: CoreNavigationBarMode.rail)));
      final document = (await tester.request('/')).document!;

      expect(document.querySelectorAll(_mark), hasLength(3));
    });

    testServer('the nested slots reach the dot and the gap', (tester) async {
      tester.pumpComponent(
        _host(
          _bar(
            navigationBarStyle: const CoreNavigationBarStyle(
              selectionMarkStyle: CoreBadgeStyle(
                backgroundColor: CoreColor.token(CoreColors.error),
              ),
              selectionMarkGapStyle: CoreGapStyle(size: CoreSpace.space8),
            ),
          ),
        ),
      );
      final document = (await tester.request('/')).document!;
      final dot = document.querySelector(_dot)!;

      expect(dot.classes, contains('bg-error'));
      // The default dot size stays under the caller's colour.
      expect(dot.attributes['style'], contains('width: 0.25rem'));
      expect(
        document.querySelector(_gap)!.attributes['style'],
        contains('flex-basis: var(--coui-space-8)'),
      );
    });

    testServer('the glass bar takes its own selection colour', (
      tester,
    ) async {
      tester.pumpComponent(
        _host(
          _bar(
            navigationBarStyle: const CoreNavigationBarStyle(
              surfaceStyle: CoreSurfaceStyleId.liquidGlass,
            ),
          ),
        ),
      );
      final document = (await tester.request('/')).document!;

      expect(document.querySelector(_dot)!.classes, contains('bg-primary'));
    });

    testComponents('the resolver hands the composed children their slots', (
      tester,
    ) async {
      late BuildContext context;
      pumpWithTheme(tester, _ContextCapture((c) => context = c));
      final resolved = resolveNavigationBar(
        context,
        mode: CoreNavigationBarMode.bar,
        variant: CoreNavigationBarVariant.defaultVariant,
        overflow: CoreNavigationOverflow.ellipsis,
        labelPosition: CoreNavigationLabelPosition.bottom,
      );

      expect(
        resolved.selectionMarkStyle,
        CoreNavigationBarStyle.defaultSelectionMarkStyle.merge(
          CoreNavigationBarStyle
              .defaultsByIndicator[CoreNavigationSelectionIndicator.color]!
              .selectionMarkStyle,
        ),
      );
      expect(
        resolved.selectionMarkGapStyle,
        CoreNavigationBarStyle.defaultSelectionMarkGapStyle,
      );
      expect(
        resolved.selectionMarkShown.inlineStyles?.properties['opacity'],
        '1',
      );
      expect(
        resolved.selectionMarkHidden.inlineStyles?.properties['opacity'],
        '0',
      );
    });
  });
}
