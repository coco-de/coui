// The Dialog body's scroll region and the actions row's wrapping, read back
// from what the Web resolver emits and what the widget renders. The Flutter
// twin (`dialog_scroll_wrap_test.dart`) measures the same rules as laid out.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/dialog/dialog_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

late ResolvedDialog _seen;

class _Capture extends StatelessComponent {
  const _Capture({this.dialogStyle});

  final CoreDialogStyle? dialogStyle;

  @override
  Component build(BuildContext context) {
    _seen = resolveDialog(context, dialogStyle: dialogStyle);
    return const Component.text('x');
  }
}

Future<ResolvedDialog> _resolve(
  ComponentTester tester, {
  CoreDialogStyle? dialogStyle,
}) async {
  pumpWithTheme(tester, _Capture(dialogStyle: dialogStyle));
  await tester.pump();
  return _seen;
}

Set<String> _classes(WebElementChrome chrome) =>
    chrome.className.split(' ').where((c) => c.isNotEmpty).toSet();

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('Dialog panel height', () {
    testComponents('stops at the viewport less the route room, like the '
        'width', (tester) async {
      final panel = (await _resolve(tester)).panel;
      final room =
          'calc(100% - 2 * ${spaceCss(CoreDialogStyle.defaultRoutePadding)})';

      expect(_inline(panel)['max-height'], room);
      expect(_inline(panel)['width'], room);
    });
  });

  group('Dialog body scroll region', () {
    testComponents('is a vertical scroll container the flex column can '
        'shrink', (tester) async {
      final content = (await _resolve(tester)).content;

      expect(
        _classes(content),
        containsAll(<String>[
          WebLayout.minHZero,
          WebLayout.overflowYAuto,
          WebLayout.overflowXHidden,
        ]),
      );
    });

    testComponents('reaches contentClipMargin past its box and pads back by '
        'the same length', (tester) async {
      final content = (await _resolve(tester)).content;
      final reach = pinnedLengthCss(CoreDialogStyle.defaultContentClipMargin);

      expect(_inline(content)['margin'], '-$reach');
      expect(_inline(content)['padding'], reach);
      // The focus outline's reach — 4px, a quarter rem.
      expect(reach, '0.25rem');
    });

    testComponents('a stated contentClipMargin reaches both declarations', (
      tester,
    ) async {
      final content = (await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(
          contentClipMargin: CoreSpace.space8,
        ),
      )).content;
      final reach = pinnedLengthCss(CoreSpace.space8);

      expect(_inline(content)['margin'], '-$reach');
      expect(_inline(content)['padding'], reach);
    });

    testComponents('keeps its typography role beside the scroll classes', (
      tester,
    ) async {
      final content = (await _resolve(tester)).content;
      final role = emitTypography(null, CoreDialogStyle.defaultContentStyle);

      for (final cls in role.className.split(' ').where((c) => c.isNotEmpty)) {
        expect(_classes(content), contains(cls));
      }
    });

    testComponents('the header never gives up its room', (tester) async {
      final header = (await _resolve(tester)).header;

      expect(_classes(header), contains(WebLayout.shrinkZero));
    });
  });

  group('Dialog actions row', () {
    testComponents('wraps at the end, centred across, and keeps its room', (
      tester,
    ) async {
      final footer = (await _resolve(tester)).footer;

      expect(
        _classes(footer),
        containsAll(<String>[
          WebLayout.flex,
          WebLayout.flexWrap,
          WebLayout.justifyEnd,
          WebLayout.itemsCenter,
          WebLayout.shrinkZero,
        ]),
      );
    });

    testComponents('sets actionSpacing between actions and actionRunSpacing '
        'between rows', (tester) async {
      final footer = (await _resolve(tester)).footer;

      expect(
        _inline(footer)['column-gap'],
        spaceCss(CoreDialogStyle.defaultActionSpacing),
      );
      expect(
        _inline(footer)['row-gap'],
        spaceCss(CoreDialogStyle.defaultActionRunSpacing),
      );
      // One `gap` shorthand no longer speaks for both.
      expect(_inline(footer).containsKey('gap'), isFalse);
    });

    testComponents('a stated actionRunSpacing moves only the row gap', (
      tester,
    ) async {
      final footer = (await _resolve(
        tester,
        dialogStyle: const CoreDialogStyle(
          actionRunSpacing: CoreSpace.space20,
        ),
      )).footer;

      expect(
        _inline(footer)['column-gap'],
        spaceCss(CoreDialogStyle.defaultActionSpacing),
      );
      expect(_inline(footer)['row-gap'], spaceCss(CoreSpace.space20));
    });
  });

  group('Dialog body and actions, as rendered', () {
    testComponents('the body sits in the scroll region and the actions in '
        'the wrapping row', (tester) async {
      final resolved = await _resolve(tester);
      pumpWithTheme(
        tester,
        const Dialog(
          title: Component.text('Title'),
          content: Component.text('Body'),
          actions: [Component.text('Cancel'), Component.text('OK')],
        ),
      );
      await tester.pump();

      Finder slot(WebElementChrome chrome) => find.byComponentPredicate(
        (component) =>
            component is DomComponent && component.classes == chrome.className,
      );

      expect(
        find.descendant(
          of: slot(resolved.content),
          matching: find.text('Body'),
        ),
        findsOneComponent,
      );
      for (final action in ['Cancel', 'OK']) {
        expect(
          find.descendant(
            of: slot(resolved.footer),
            matching: find.text(action),
          ),
          findsOneComponent,
        );
      }
    });
  });
}
