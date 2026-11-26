import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/bottom_sheet/bottom_sheet_style.dart'
    show kBottomSheetMoreBelowVar;
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The DOM children of [element] — the nearest element nodes under it, past
/// the components (`Text`, `Button`) that only wrap one.
List<Element> _domChildren(Element element) {
  final out = <Element>[];
  void visit(Element child) {
    if (child.component is DomComponent) {
      out.add(child);
    } else {
      child.visitChildren(visit);
    }
  }

  element.visitChildren(visit);
  return out;
}

DomComponent _dom(Element element) => element.component as DomComponent;

/// The root element of the first [T] on the page.
Element _root<T extends Component>() =>
    _domChildren(find.byType(T).evaluate().single).single;

String _text(Element element) {
  final out = StringBuffer();
  void visit(Element child) {
    if (child.component case jaspr.Text(:final text)) out.write(text);
    child.visitChildren(visit);
  }

  visit(element);
  return out.toString();
}

/// The DOM child of [element] whose text is [text].
Element _childWithText(Element element, String text) =>
    _domChildren(element).firstWhere((child) => _text(child) == text);

Component _marker(String name) =>
    div([Component.text(name)], classes: 'slot-$name');

void main() {
  group('Web BottomSheet', () {
    BottomSheet sheet({
      bool showHandle = true,
      bool showCloseButton = false,
      bool showDivider = false,
      Component? description,
      Component? content,
      Component? footer,
      CoreBottomSheetStyle? style,
    }) => BottomSheet(
      title: const Text('Sort by'),
      description: description,
      content: content,
      footer: footer,
      showHandle: showHandle,
      showCloseButton: showCloseButton,
      showDivider: showDivider,
      bottomSheetStyle: style,
    );

    testComponents('the root: a functional surface, one column, rounded top', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet());

      final root = _root<BottomSheet>();
      expect(_dom(root).tag, 'div');
      expect(
        _dom(root).classes,
        'coui-surface coui-surface-functional w-full box-border flex flex-col '
        'bg-surface-bright '
        '${CoreBottomSheetStyle.defaultBorderRadius.tailwindClasses()}',
      );
      // No role: the sheet is a surface, not a dialog.
      expect(_dom(root).attributes?['role'], isNull);
      // No border and no shadow of its own — only the published fill, and
      // the height ceiling: 90 % of the viewport.
      expect(_dom(root).styles?.properties, {
        '--coui-surface-rgb': 'var(--coui-surface-bright)',
        'max-height': '90dvh',
      });
    });

    testComponents('the handle: a 36 x 4 pill with 8 above it', (tester) async {
      pumpWithTheme(tester, sheet());

      final rows = _domChildren(_root<BottomSheet>());
      final handleRow = rows.first;
      expect(_dom(handleRow).classes, 'flex justify-center');
      expect(_dom(handleRow).styles?.properties, {
        'padding':
            '${spaceCss(CoreBottomSheetStyle.defaultHandlePadding.top)} '
            '${spaceCss(CoreBottomSheetStyle.defaultHandlePadding.right)} '
            '${spaceCss(CoreBottomSheetStyle.defaultHandlePadding.bottom)} '
            '${spaceCss(CoreBottomSheetStyle.defaultHandlePadding.left)}',
      });
      final handle = _domChildren(handleRow).single;
      expect(_dom(handle).classes, contains('bg-outline'));
      expect(
        _dom(handle).classes,
        contains(
          CoreBottomSheetStyle.defaultHandleBorderRadius.tailwindClasses(),
        ),
      );
      expect(_dom(handle).styles?.properties, {
        'width': pinnedLengthCss(CoreBottomSheetStyle.defaultHandleWidth),
        'height': pinnedLengthCss(CoreBottomSheetStyle.defaultHandleHeight),
      });
    });

    testComponents('showHandle: false leaves the handle row out', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet(showHandle: false));

      final rows = _domChildren(_root<BottomSheet>());
      expect(rows, hasLength(1));
      expect(_text(rows.single), 'Sort by');
    });

    testComponents('the header: the inset, the title row, the title fills', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet());

      final header = _domChildren(_root<BottomSheet>())[1];
      const padding = CoreBottomSheetStyle.defaultHeaderPadding;
      expect(_dom(header).classes, 'flex flex-col');
      expect(_dom(header).styles?.properties, {
        'padding':
            '${spaceCss(padding.top)} ${spaceCss(padding.right)} '
            '${spaceCss(padding.bottom)} ${spaceCss(padding.left)}',
      });
      final row = _domChildren(header).single;
      expect(_dom(row).styles?.properties, {
        'gap': spaceCss(CoreBottomSheetStyle.defaultHeaderSpacing),
      });
      final title = _childWithText(row, 'Sort by');
      expect(_dom(title).classes, contains('min-w-0 flex-1'));
      expect(_dom(title).classes, contains('text-on-surface'));
    });

    testComponents('the close button: absent by default, labelled when on', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet());
      expect(find.byType(Button), findsNothing);

      pumpWithTheme(tester, sheet(showCloseButton: true));
      final button = find.byType(Button);
      expect(button, findsOneComponent);
      final root = _domChildren(button.evaluate().single).single;
      expect(_dom(root).attributes?['aria-label'], isNotEmpty);
    });

    testComponents('the description follows a gap and carries its text role', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet(description: const Text('Pick one')));

      expect(find.byType(Gap), findsOneComponent);
      final header = _domChildren(_root<BottomSheet>())[1];
      final description = _childWithText(header, 'Pick one');
      expect(_dom(description).classes, contains('text-on-surface-variant'));
    });

    testComponents('the divider appears between the header and the content', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet(content: _marker('body')));
      expect(find.byType(Divider), findsNothing);

      pumpWithTheme(
        tester,
        sheet(showDivider: true, content: _marker('body')),
      );
      expect(find.byType(Divider), findsOneComponent);
    });

    testComponents('the content scrolls above a pinned footer', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        sheet(content: _marker('body'), footer: _marker('foot')),
      );

      final rows = _domChildren(_root<BottomSheet>());
      // handle row, header, body.
      expect(rows, hasLength(3));
      final body = rows[2];
      // A shrinkable column, so the root's ceiling reaches the viewport.
      expect(_dom(body).classes, 'flex flex-col min-h-0');
      final [viewport, footerArea] = _domChildren(body);

      const padding = CoreBottomSheetStyle.defaultContentPadding;
      expect(_dom(viewport).classes, 'min-h-0 overflow-y-auto');
      expect(_dom(viewport).id, isNotNull);
      expect(_dom(viewport).styles?.properties, {
        'padding':
            '${spaceCss(padding.top)} ${spaceCss(padding.right)} '
            '${spaceCss(padding.bottom)} ${spaceCss(padding.left)}',
      });
      expect(_text(viewport), 'body');

      expect(_dom(footerArea).classes, 'relative shrink-0');
      expect(_dom(footerArea).id, isNotNull);
      final [footer, line] = _domChildren(footerArea);
      // A footer that is not a `BottomActionBar` is placed as it is.
      expect(_dom(footer).classes, 'slot-foot');
      expect(
        _dom(line).classes,
        'absolute inset-x-0 top-0 pointer-events-none bg-outline-variant',
      );
      expect(_dom(line).attributes?['aria-hidden'], 'true');
      // The two state values: rest `0` through the fallback, `1` written by
      // the measurer while more content lies below.
      expect(_dom(line).styles?.properties, {
        'height': strokeWidthCss(
          CoreBottomSheetStyle.defaultFooterDividerWidth,
        ),
        'opacity': 'var($kBottomSheetMoreBelowVar, 0)',
      });
    });

    testComponents('a sheet without a footer draws no footer hairline', (
      tester,
    ) async {
      pumpWithTheme(tester, sheet(content: _marker('body')));

      final body = _domChildren(_root<BottomSheet>())[2];
      final [viewport] = _domChildren(body);
      expect(_dom(viewport).classes, 'min-h-0 overflow-y-auto');
    });

    testComponents(
      'a BottomActionBar in the footer paints no fill and no hairline',
      (tester) async {
        pumpWithTheme(
          tester,
          sheet(
            content: _marker('body'),
            footer: BottomActionBar(
              primaryAction: Button(child: const Text('Apply')),
            ),
          ),
        );

        final bar = _root<BottomActionBar>();
        expect(_dom(bar).classes, isNot(contains('bg-surface')));
        expect(_dom(bar).classes, isNot(contains('coui-surface')));
        expect(_dom(bar).styles?.properties['background-color'], isNotNull);
        expect(
          _dom(bar).styles?.properties['border-top-width'],
          strokeWidthCss(CoreStrokeWidth.stroke0),
        );
      },
    );

    testComponents('a standalone BottomActionBar keeps its fill and hairline', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        BottomActionBar(primaryAction: Button(child: const Text('Apply'))),
      );

      final bar = _root<BottomActionBar>();
      expect(_dom(bar).classes, contains('bg-surface'));
      expect(
        _dom(bar).styles?.properties['border-top-width'],
        strokeWidthCss(CoreBottomActionBarStyle.defaultDividerWidth),
      );
    });

    testComponents("the bar's own style still wins inside the sheet", (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        sheet(
          footer: BottomActionBar(
            primaryAction: Button(child: const Text('Apply')),
            bottomActionBarStyle: const CoreBottomActionBarStyle(
              backgroundColor: CoreColor.token(CoreColors.surface),
            ),
          ),
        ),
      );

      expect(_dom(_root<BottomActionBar>()).classes, contains('bg-surface'));
    });

    testComponents('maxHeightFactor sets the ceiling', (tester) async {
      pumpWithTheme(
        tester,
        sheet(style: const CoreBottomSheetStyle(maxHeightFactor: 0.75)),
      );

      expect(
        _dom(_root<BottomSheet>()).styles?.properties['max-height'],
        '75dvh',
      );
    });

    testComponents('a raw colour override goes inline and drops the class', (
      tester,
    ) async {
      const plum = CoreColor.fromARGB(255, 10, 20, 30);
      pumpWithTheme(
        tester,
        sheet(style: const CoreBottomSheetStyle(backgroundColor: plum)),
      );

      final root = _root<BottomSheet>();
      expect(_dom(root).classes, isNot(contains('bg-surface-bright')));
      expect(
        _dom(root).styles?.properties.containsKey('background-color'),
        isTrue,
      );
    });
  });
}
