// How the Dialog spreads its actions across the actions row, read back from
// what the Web resolver emits and what the widget renders.
//
// At the end the row is what it always was — the actions sit straight in the
// wrapping footer. Stretched, every action sits in a cell that starts at an
// equal share of the row. Where the browser then puts each cell is pinned by
// the real-Chrome probe (`tool/parity/test/web/
// dialog_actions_stretch_probe_test.dart`) against the vector table the Core
// placement and the Flutter twin read.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
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

ResolvedDialog _resolve(
  ComponentTester tester, {
  int actionCount = 0,
  CoreDialogStyle? dialogStyle,
}) {
  late ResolvedDialog resolved;
  pumpWithTheme(
    tester,
    _ContextCapture(
      (context) => resolved = resolveDialog(
        context,
        actionCount: actionCount,
        dialogStyle: dialogStyle,
      ),
    ),
  );
  return resolved;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

Iterable<DomComponent> _doms(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent);

/// The footer `<div>` the rendered dialog holds — the one element carrying
/// the footer chrome.
DomComponent _footer(ComponentTester tester, WebElementChrome footer) =>
    _doms(tester).singleWhere((c) => c.classes == footer.className);

/// The footer row as it is today — the class string and gaps every dialog
/// with the default layout has always rendered.
const String _kFooterClassName =
    'flex flex-wrap justify-end items-center shrink-0';

Map<String, String> _footerGaps({
  double actionSpacing = CoreDialogStyle.defaultActionSpacing,
}) => {
  'column-gap': spaceCss(actionSpacing),
  'row-gap': spaceCss(CoreDialogStyle.defaultActionRunSpacing),
};

/// The share each of [count] actions starts at, with [actionSpacing]
/// between them.
String _share(
  int count, {
  double actionSpacing = CoreDialogStyle.defaultActionSpacing,
}) => 'calc((100% - ${count - 1} * ${spaceCss(actionSpacing)}) / $count)';

void main() {
  group('Dialog actions at the end (the default)', () {
    testComponents('the footer row is the wrapping row it has always been', (
      tester,
    ) async {
      for (final style in const [
        null,
        CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.end),
      ]) {
        final resolved = _resolve(tester, actionCount: 2, dialogStyle: style);

        expect(resolved.footer.className, _kFooterClassName, reason: '$style');
        expect(_inline(resolved.footer), _footerGaps(), reason: '$style');
        expect(resolved.actionCell, isNull, reason: '$style');
      }
    });

    testComponents('the default layout is the end', (tester) async {
      expect(CoreDialogStyle.defaultActionsLayout, CoreDialogActionsLayout.end);
    });

    testComponents('each action is a direct child of the footer', (
      tester,
    ) async {
      final resolved = _resolve(tester, actionCount: 2);
      const cancel = Component.text('Cancel');
      final ok = Button(child: const Component.text('OK'));
      pumpWithTheme(tester, Dialog(actions: [cancel, ok]));
      await tester.pump();

      final children = _footer(tester, resolved.footer).children!;

      expect(children, hasLength(2));
      expect(children.whereType<div>(), isEmpty);
      expect(identical(children.first, cancel), isTrue);
      expect(identical(children.last, ok), isTrue);
    });
  });

  group('Dialog actions stretched', () {
    const stretch = CoreDialogStyle(
      actionsLayout: CoreDialogActionsLayout.stretch,
    );

    testComponents('leave the footer row as it is', (tester) async {
      final resolved = _resolve(
        tester,
        actionCount: 2,
        dialogStyle: stretch,
      );

      expect(resolved.footer.className, _kFooterClassName);
      expect(_inline(resolved.footer), _footerGaps());
    });

    testComponents('seat each action in a flex column that grows and never '
        'goes narrower than its action', (tester) async {
      final cell = _resolve(
        tester,
        actionCount: 2,
        dialogStyle: stretch,
      ).actionCell!;

      expect(cell.className.split(' ').toSet(), {
        WebLayout.flex,
        WebLayout.flexCol,
        WebLayout.grow,
        WebLayout.minWFit,
      });
      expect(cell.className.split(' '), hasLength(4));
    });

    testComponents('one action starts at the whole row', (tester) async {
      final cell = _resolve(
        tester,
        actionCount: 1,
        dialogStyle: stretch,
      ).actionCell!;

      expect(_inline(cell), {'flex-basis': '100%'});
    });

    testComponents('two and three actions start at an equal share of the row '
        'less the gaps between them', (tester) async {
      for (final count in [2, 3]) {
        final cell = _resolve(
          tester,
          actionCount: count,
          dialogStyle: stretch,
        ).actionCell!;

        expect(_inline(cell), {'flex-basis': _share(count)}, reason: '$count');
      }
      expect(
        _share(2),
        'calc((100% - 1 * ${spaceCss(CoreSpace.space8)}) / 2)',
      );
    });

    testComponents('no actions, no cell', (tester) async {
      expect(_resolve(tester, dialogStyle: stretch).actionCell, isNull);
    });

    testComponents('a stated actionSpacing moves the gap and the share '
        'together', (tester) async {
      final resolved = _resolve(
        tester,
        actionCount: 2,
        dialogStyle: const CoreDialogStyle(
          actionsLayout: CoreDialogActionsLayout.stretch,
          actionSpacing: CoreSpace.space12,
        ),
      );

      expect(
        _inline(resolved.footer),
        _footerGaps(actionSpacing: CoreSpace.space12),
      );
      expect(_inline(resolved.actionCell!), {
        'flex-basis': _share(2, actionSpacing: CoreSpace.space12),
      });
    });

    testComponents('a theme that stretches the row reaches every dialog', (
      tester,
    ) async {
      late ResolvedDialog resolved;
      tester.pumpComponent(
        Theme(
          data: const ThemeData(
            coreComponentTheme: CoreComponentTheme(
              dialog: CoreDialogTheme(style: stretch),
            ),
          ),
          child: _ContextCapture(
            (context) => resolved = resolveDialog(context, actionCount: 2),
          ),
        ),
      );

      expect(resolved.actionCell, isNotNull);
      expect(_inline(resolved.actionCell!), {'flex-basis': _share(2)});
    });

    testComponents('every action renders in its cell, in the order handed in, '
        'a Button still taking the action button style', (tester) async {
      const actionButtonStyle = CoreButtonStyle(borderWidth: 3);
      const buttonStyle = CoreButtonStyle(
        foregroundColor: CoreColor.token(CoreColors.primary),
      );
      const dialogStyle = CoreDialogStyle(
        actionsLayout: CoreDialogActionsLayout.stretch,
        actionButtonStyle: actionButtonStyle,
      );
      const cancel = Component.text('Cancel');
      final resolved = _resolve(
        tester,
        actionCount: 2,
        dialogStyle: dialogStyle,
      );
      final cell = resolved.actionCell!;
      pumpWithTheme(
        tester,
        Dialog(
          dialogStyle: dialogStyle,
          actions: [
            cancel,
            Button(buttonStyle: buttonStyle, child: const Component.text('OK')),
          ],
        ),
      );
      await tester.pump();

      final cells = _footer(tester, resolved.footer).children!;

      expect(cells, hasLength(2));
      for (final seated in cells) {
        expect(seated, isA<div>());
        seated as div;
        expect(seated.classes, cell.className);
        expect(seated.styles?.properties, _inline(cell));
        expect(seated.children, hasLength(1));
      }
      final first = (cells.first as div).children.single;
      final last = (cells.last as div).children.single;
      expect(identical(first, cancel), isTrue);
      expect(last, isA<Button>());
      expect(
        (last as Button).buttonStyle,
        actionButtonStyle.merge(buttonStyle),
      );
    });
  });
}
