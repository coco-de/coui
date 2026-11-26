import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The DOM children of [element] — the nearest element nodes under it, past
/// the components (`div`, `span`) that only wrap one.
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

void main() {
  group('Web PageHeader', () {
    PageHeader header({
      List<Component> actions = const [Text('Cancel'), Text('Save')],
      int headingLevel = CorePageHeaderContract.defaultHeadingLevel,
      CorePageHeaderStyle? style,
    }) => PageHeader(
      eyebrow: const Text('Workspace'),
      title: const Text('Settings'),
      description: const Text('Everything about this workspace.'),
      actions: actions,
      headingLevel: headingLevel,
      pageHeaderStyle: style,
    );

    testComponents('a column: the eyebrow, the title line with the actions, '
        'the description', (tester) async {
      pumpWithTheme(tester, header());

      final root = _root<PageHeader>();
      // Fills its container even where a parent sizes it to its content.
      expect(_dom(root).classes, 'flex flex-col w-full');
      expect(_dom(root).styles?.properties, {
        'gap': spaceCss(CorePageHeaderStyle.defaultTextSpacing),
      });
      final [eyebrow, row, description] = _domChildren(root);
      expect(_text(eyebrow), 'Workspace');
      expect(_text(description), 'Everything about this workspace.');
      expect(_dom(row).classes, 'flex flex-wrap items-center');
      expect(_dom(row).styles?.properties, {
        'gap': spaceCss(CorePageHeaderStyle.defaultTextActionsSpacing),
      });
      final [titleBlock, actions] = _domChildren(row);
      expect(_dom(titleBlock).classes, 'min-w-0');
      expect(_dom(titleBlock).styles?.properties, {
        // The 160 floor: below it the actions wrap onto their own line.
        'flex': '1 1 10.0rem',
      });
      expect(_dom(actions).classes, 'flex flex-wrap items-center');
      expect(_dom(actions).styles?.properties, {
        'gap': spaceCss(CorePageHeaderStyle.defaultActionSpacing),
      });
      expect(_text(actions), 'CancelSave');
    });

    Element titleOf(Element root) =>
        _domChildren(_domChildren(_domChildren(root)[1]).first).single;

    testComponents('the lines take the header roles; the title is an <h1>', (
      tester,
    ) async {
      pumpWithTheme(tester, header());

      final root = _root<PageHeader>();
      final [eyebrow, _, description] = _domChildren(root);
      final title = titleOf(root);
      expect(_dom(eyebrow).classes, 'text-label-xl text-on-surface-variant');
      expect(_text(eyebrow), 'Workspace');
      expect(_dom(title).tag, 'h1');
      expect(_dom(title).classes, 'text-headline-medium text-on-surface');
      // coui_web ships without Tailwind's preflight, so the heading's own
      // margin is reset here.
      expect(_dom(title).styles?.properties, {'margin': spaceCss(0)});
      expect(_text(title), 'Settings');
      expect(
        _dom(description).classes,
        'text-body-medium text-on-surface-variant',
      );
    });

    testComponents('headingLevel picks the heading element', (tester) async {
      pumpWithTheme(tester, header(headingLevel: 3));

      expect(_dom(titleOf(_root<PageHeader>())).tag, 'h3');
    });

    testComponents('no actions: the title sits in the column itself', (
      tester,
    ) async {
      pumpWithTheme(tester, header(actions: const []));

      final [_, title, _] = _domChildren(_root<PageHeader>());
      expect(_dom(title).tag, 'h1');
    });

    testComponents('stated values reach the markup', (tester) async {
      pumpWithTheme(
        tester,
        header(
          style: const CorePageHeaderStyle(
            titleTextStyle: CoreTextStyle(
              color: CoreColor.fromARGB(255, 10, 20, 30),
            ),
            textActionsSpacing: CoreSpace.space24,
            minTextWidth: CoreLayout.layout320,
          ),
        ),
      );

      final root = _root<PageHeader>();
      final row = _domChildren(root)[1];
      expect(_dom(row).styles?.properties['gap'], spaceCss(CoreSpace.space24));
      final titleBlock = _domChildren(row).first;
      expect(_dom(titleBlock).styles?.properties['flex'], '1 1 20.0rem');
      final title = titleOf(root);
      // A raw colour has no class — it goes inline.
      expect(_dom(title).classes, 'text-headline-medium');
      expect(
        _dom(title).styles?.properties['color'],
        const CoreColor.fromARGB(255, 10, 20, 30).toValue(),
      );
    });

    testComponents('the project theme reaches, the instance wins', (
      tester,
    ) async {
      tester.pumpComponent(
        Theme(
          data: ThemeData.coui.copyWith(
            coreComponentTheme: const CoreComponentTheme(
              pageHeader: CorePageHeaderTheme(
                style: CorePageHeaderStyle(
                  textSpacing: CoreSpace.space12,
                  actionSpacing: CoreSpace.space12,
                ),
              ),
            ),
          ),
          child: header().withStyle(
            const CorePageHeaderStyle(actionSpacing: CoreSpace.space16),
          ),
        ),
      );

      final root = _root<PageHeader>();
      expect(_dom(root).styles?.properties['gap'], spaceCss(CoreSpace.space12));
      final actions = _domChildren(_domChildren(root)[1])[1];
      expect(
        _dom(actions).styles?.properties['gap'],
        spaceCss(CoreSpace.space16),
      );
    });
  });

  group('Web PanelHeader', () {
    PanelHeader header({
      Component? action = const Text('All'),
      int headingLevel = CorePanelHeaderContract.defaultHeadingLevel,
      CorePanelHeaderStyle? style,
    }) => PanelHeader(
      title: const Text('Recent'),
      action: action,
      headingLevel: headingLevel,
      panelHeaderStyle: style,
    );

    testComponents('a wrapping row: the title heading, then the action', (
      tester,
    ) async {
      pumpWithTheme(tester, header());

      final root = _root<PanelHeader>();
      expect(
        _dom(root).classes,
        'flex flex-wrap items-center w-full '
        'pl-space0 pr-space0 pt-space0 pb-space8',
      );
      expect(_dom(root).styles?.properties, {
        'gap': spaceCss(CorePanelHeaderStyle.defaultTitleActionSpacing),
      });
      final [title, action] = _domChildren(root);
      expect(_dom(title).tag, 'h2');
      expect(_dom(title).classes, 'text-title-medium text-on-surface min-w-0');
      expect(_dom(title).styles?.properties, {
        'margin': spaceCss(0),
        // The 128 floor: below it the action wraps onto its own line.
        'flex': '1 1 8.0rem',
      });
      expect(_text(title), 'Recent');
      expect(_dom(action).classes, 'flex');
      expect(_text(action), 'All');
    });

    testComponents('no action: the title alone', (tester) async {
      pumpWithTheme(tester, header(action: null));

      expect(_domChildren(_root<PanelHeader>()), hasLength(1));
    });

    testComponents('headingLevel picks the heading element', (tester) async {
      pumpWithTheme(tester, header(headingLevel: 4));

      expect(_dom(_domChildren(_root<PanelHeader>()).first).tag, 'h4');
    });

    testComponents('stated values reach the markup', (tester) async {
      pumpWithTheme(
        tester,
        header().withStyle(
          const CorePanelHeaderStyle(
            padding: CoreEdgeInsets.only(bottom: CoreSpace.space2),
            minTitleWidth: CoreSize.size96,
            titleActionSpacing: CoreSpace.space4,
          ),
        ),
      );

      final root = _root<PanelHeader>();
      // A stated padding goes inline and its class drops.
      expect(_dom(root).classes, 'flex flex-wrap items-center w-full');
      expect(_dom(root).styles?.properties['gap'], spaceCss(CoreSpace.space4));
      expect(_dom(root).styles?.properties['padding'], isNotNull);
      final title = _domChildren(root).first;
      expect(_dom(title).styles?.properties['flex'], '1 1 6.0rem');
    });
  });
}
