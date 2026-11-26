import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/page/page_transition_style.dart'
    show kPageTransitionDirectionScript;
import 'package:jaspr_test/server_test.dart';

// The page transition reaches the browser only through the document head,
// so these read the real server render (`testServer`), not a component tree.

const _kStyleSelector = 'style#coui-page-transition';
const _kScriptSelector = 'script#coui-page-transition-direction';

/// The rules the default theme states, whole: every rule but the keyframes
/// sits inside the no-preference query, the arrival animates the new page
/// over the old one, and a step back animates the old page over the new.
final String _kDefaultRules = [
  '@media (prefers-reduced-motion:no-preference){',
  '@view-transition{navigation:auto;}',
  '::view-transition-old(root){animation:none;}',
  '::view-transition-new(root){animation: ',
  'coui-page-enter var(--coui-duration-500) var(--easing-ease-out) both;}',
  'html:active-view-transition-type(back)::view-transition-old(root)',
  '{z-index:1;animation: ',
  'coui-page-exit var(--coui-duration-300) var(--easing-ease-in) both;}',
  'html:active-view-transition-type(back)::view-transition-new(root)',
  '{animation:none;}',
  '}',
  '@keyframes coui-page-enter{from{opacity:0; ',
  'transform:translateY(1.0rem);}}',
  '@keyframes coui-page-exit{to{opacity:0; ',
  'transform:translateY(1.0rem);}}',
].join();

/// What the server put in the page for the transition.
typedef _Head = ({
  String? rules,
  String? script,
  int rulesCount,
  int scriptCount,
  bool rulesInBody,
});

Future<_Head> _render(ServerTester tester, Component app) async {
  tester.pumpComponent(app);
  final document = (await tester.request('/')).document!;

  return (
    // The server indents what it puts inside an element.
    rules: document.head!.querySelector(_kStyleSelector)?.text.trim(),
    script: document.head!.querySelector(_kScriptSelector)?.text.trim(),
    rulesCount: document.querySelectorAll(_kStyleSelector).length,
    scriptCount: document.querySelectorAll(_kScriptSelector).length,
    rulesInBody: document.body!.querySelector(_kStyleSelector) != null,
  );
}

ThemeData _themeWith(CorePageTransitionStyle style) => ThemeData(
  coreComponentTheme: CoreComponentTheme(
    pageTransition: CorePageTransitionTheme(style: style),
  ),
);

void main() {
  group('Page transition — document head', () {
    testServer('states the arrival and, on a step back, the departure', (
      tester,
    ) async {
      final head = await _render(
        tester,
        CoUIWeb(theme: .coui, child: const div([])),
      );

      expect(head.rules, _kDefaultRules);
      // In the head, not the body: the browser reads view-transition rules
      // before it first shows the page.
      expect(head.rulesInBody, isFalse);
    });

    testServer('marks a step back with the direction script', (tester) async {
      final head = await _render(
        tester,
        CoUIWeb(theme: .coui, child: const div([])),
      );

      expect(head.script, kPageTransitionDirectionScript);
    });

    testServer('the component theme sets the timing and distance', (
      tester,
    ) async {
      final head = await _render(
        tester,
        CoUIWeb(
          theme: _themeWith(
            const CorePageTransitionStyle(
              enterDuration: Duration(milliseconds: CoreDuration.normal),
              exitDuration: Duration(milliseconds: CoreDuration.fast),
              slideDistance: CoreSpace.space48,
            ),
          ),
          child: const div([]),
        ),
      );
      final rules = head.rules!;

      expect(rules, contains('coui-page-enter var(--coui-duration-200) '));
      expect(rules, contains('coui-page-exit var(--coui-duration-150) '));
      expect('translateY(3.0rem)'.allMatches(rules), hasLength(2));
      expect(rules, isNot(contains('translateY(1.0rem)')));
    });

    testServer('an app that turns both motions off has no transition rules', (
      tester,
    ) async {
      final head = await _render(
        tester,
        CoUIWeb(
          theme: _themeWith(
            const CorePageTransitionStyle(
              enterDuration: Duration.zero,
              exitDuration: Duration.zero,
            ),
          ),
          child: const div([]),
        ),
      );

      expect(head.rules, isEmpty);
      expect(head.scriptCount, 0);
    });

    testServer('a later sibling root supplies the page timing', (tester) async {
      final head = await _render(
        tester,
        div([
          CoUIWeb(
            theme: _themeWith(
              const CorePageTransitionStyle(
                enterDuration: Duration(milliseconds: 111),
              ),
            ),
            child: const div([]),
          ),
          CoUIWeb(
            theme: _themeWith(
              const CorePageTransitionStyle(
                enterDuration: Duration(milliseconds: 222),
              ),
            ),
            child: const div([]),
          ),
        ]),
      );
      expect(head.rules, contains('coui-page-enter ${durationMsCss(222)} '));
    });

    testServer('the server resolves a later sibling after a deeper root', (
      tester,
    ) async {
      final head = await _render(
        tester,
        div([
          CoUIWeb(
            theme: .coui,
            child: CoUIWeb(
              theme: _themeWith(
                const CorePageTransitionStyle(
                  enterDuration: Duration(milliseconds: 222),
                ),
              ),
              child: const div([]),
            ),
          ),
          CoUIWeb(
            theme: _themeWith(
              const CorePageTransitionStyle(
                enterDuration: Duration(milliseconds: 333),
              ),
            ),
            child: const div([]),
          ),
        ]),
      );
      expect(head.rules, contains('coui-page-enter ${durationMsCss(333)} '));
    });

    testServer('a deeper off value overrides an enabled parent', (
      tester,
    ) async {
      final head = await _render(
        tester,
        CoUIWeb(
          theme: .coui,
          child: CoUIWeb(
            theme: _themeWith(
              const CorePageTransitionStyle(
                enterDuration: Duration.zero,
                exitDuration: Duration.zero,
              ),
            ),
            child: const div([]),
          ),
        ),
      );
      expect(head.rules, isEmpty);
    });

    testServer('a page with two roots states the rules once', (tester) async {
      final head = await _render(
        tester,
        div([
          CoUIWeb(theme: .coui, child: const div([])),
          CoUIWeb(theme: .coui, child: const div([])),
        ]),
      );

      expect(head.rulesCount, 1);
      expect(head.scriptCount, 1);
    });
  });
}
