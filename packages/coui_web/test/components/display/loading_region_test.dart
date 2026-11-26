// The rendered DOM, read the way a screen reader reads it — by counting what
// the markup carries. A live region announces its content, not its name, so
// every check below reads the status element's text.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

const _kSkeletons = 10;
const _kOverride = 'Loading orders';
const _kEnglish = 'Loading';
const _kKorean = '로딩 중';

Component _skeletons() => Component.element(
  tag: 'div',
  children: [
    for (var i = 0; i < _kSkeletons; i++) Skeleton(height: '20px'),
  ],
);

/// What the markup carries for assistive technology.
typedef _Markup = ({
  /// The text each live region would announce.
  List<String> announced,

  /// Elements that carry an accessible name.
  int named,

  /// The text under each `aria-hidden` element.
  List<String> hidden,

  /// Live regions inside a hidden element.
  int statusesHidden,

  /// The class of every visually hidden element — where the status text sits.
  List<String> hiddenText,
});

Future<_Markup> _render(ServerTester tester, Component child) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: child));
  final doc = (await tester.request('/')).document!;
  final hidden = doc.querySelectorAll('[aria-hidden="true"]');

  return (
    announced: [
      for (final e in doc.querySelectorAll('[role="status"]')) e.text.trim(),
    ],
    named: doc.querySelectorAll('[aria-label]').length,
    hidden: [for (final e in hidden) e.text],
    statusesHidden: [
      for (final e in hidden) ...e.querySelectorAll('[role="status"]'),
    ].length,
    hiddenText: [
      for (final e in doc.querySelectorAll('.sr-only')) e.className,
    ],
  );
}

void main() {
  group('LoadingRegion announces once for its area', () {
    testServer('ten skeletons in a region are one announcement', (
      tester,
    ) async {
      final markup = await _render(tester, LoadingRegion(child: _skeletons()));

      expect(markup.announced, [_kEnglish]);
      // The skeletons read the region and emit no status of their own —
      // not merely hidden under the region's `aria-hidden`.
      expect(markup.named, 0);
    });

    testServer('the hidden text stays out of the page scrollable overflow', (
      tester,
    ) async {
      final markup = await _render(tester, LoadingRegion(child: _skeletons()));

      // A plain `sr-only` is absolute against the nearest positioned
      // ancestor, which outside an `overflow-x-auto` row is the page: one
      // per item widened the document (measured 500 → 2432 with twenty).
      // `fixed` is what keeps it out — headless Chrome, same twenty items.
      expect(markup.hiddenText, hasLength(1));
      expect(markup.hiddenText.single, contains('fixed'));
    });

    testServer('the area is hidden while the region speaks for it', (
      tester,
    ) async {
      final markup = await _render(
        tester,
        const LoadingRegion(child: Text('Placeholder order #1')),
      );

      expect(markup.hidden, hasLength(1));
      expect(markup.hidden.single, contains('Placeholder order #1'));
      // The announcement is not inside what is hidden.
      expect(markup.statusesHidden, 0);
    });

    testServer('the caller names what is loading', (tester) async {
      final markup = await _render(
        tester,
        LoadingRegion(semanticLabel: _kOverride, child: _skeletons()),
      );

      expect(markup.announced, [_kOverride]);
    });

    testServer('the default label follows the active locale', (
      tester,
    ) async {
      final markup = await _render(
        tester,
        CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: LoadingRegion(child: _skeletons()),
        ),
      );

      expect(markup.announced, [_kKorean]);
    });

    testServer('a region inside a region is still one announcement', (
      tester,
    ) async {
      final markup = await _render(
        tester,
        LoadingRegion(
          semanticLabel: _kOverride,
          child: LoadingRegion(child: _skeletons()),
        ),
      );

      expect(markup.announced, [_kOverride]);
      expect(markup.hidden, hasLength(1));
    });
  });

  group('a skeleton on its own announces itself', () {
    testServer('its status has text to read', (tester) async {
      final markup = await _render(tester, Skeleton(height: '20px'));

      // The label alone left the status with nothing to say.
      expect(markup.announced, [_kEnglish]);
    });

    testServer('its hidden text stays out of the scrollable overflow', (
      tester,
    ) async {
      final markup = await _render(
        tester,
        Component.element(
          tag: 'div',
          children: [
            Skeleton(height: '20px'),
            Skeleton.circle(size: '40px'),
            Skeleton.text(),
          ],
        ),
      );

      expect(markup.hiddenText, hasLength(3));
      expect(markup.hiddenText.every((c) => c.contains('fixed')), isTrue);
    });

    testServer('in the active locale', (tester) async {
      final markup = await _render(
        tester,
        CouiLocalizationsScope(
          localizations: KoCouiLocalizations.instance,
          child: Skeleton(height: '20px'),
        ),
      );

      expect(markup.announced, [_kKorean]);
    });

    testServer('every variant carries the text', (tester) async {
      final markup = await _render(
        tester,
        Component.element(
          tag: 'div',
          children: [
            Skeleton(height: '20px'),
            Skeleton.circle(size: '40px'),
            Skeleton.text(),
          ],
        ),
      );

      expect(markup.announced, [_kEnglish, _kEnglish, _kEnglish]);
    });
  });
}
