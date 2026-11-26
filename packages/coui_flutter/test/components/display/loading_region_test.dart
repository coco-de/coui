// Reads the semantics tree a screen reader walks, and the widgets that were
// asked to produce it. Both are counted because they fail differently: the
// region's exclusion hides a skeleton's live region from the tree even if
// the skeleton still builds one, so only the widget count shows whether the
// skeleton actually read that it is inside a region.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';

const _kSkeletons = 10;
const _kOverride = 'Loading orders';
const _kEnglish = 'Loading';
const _kKorean = '로딩 중';
const _kOpener = ValueKey<String>('opener');

// The skeletons pulse forever, so "settled" never arrives — fixed pumps.
const _kFrame = Duration(milliseconds: 100);

Future<void> _pump(WidgetTester tester, Widget home, {Locale? locale}) async {
  await tester.pumpWidget(
    CoUIApp(
      home: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(width: 320, child: home),
      ),
      locale: locale,
      supportedLocales: const [Locale('en', 'US'), Locale('ko')],
      theme: ThemeData.fromCore(CoreThemePresets.light),
    ),
  );
  await tester.pump(_kFrame);
}

Widget _skeletons() => Column(
  children: [
    for (var i = 0; i < _kSkeletons; i++) const Skeleton(height: 20),
  ],
);

/// Every node in the committed semantics tree.
List<SemanticsData> _nodes(WidgetTester tester) {
  final out = <SemanticsData>[];
  bool visit(SemanticsNode node) {
    out.add(node.getSemanticsData());
    node.visitChildren(visit);
    return true;
  }

  var root = tester.getSemantics(find.byType(SizedBox).first);
  while (root.parent != null) {
    root = root.parent!;
  }
  visit(root);
  return out;
}

/// The labels of the live regions a screen reader would announce.
List<String> _announced(WidgetTester tester) => [
  for (final n in _nodes(tester))
    if (n.flagsCollection.isLiveRegion) n.label,
];

/// Live regions built at all, excluded or not.
int _liveRegionWidgets(WidgetTester tester) => tester
    .widgetList<Semantics>(find.byType(Semantics))
    .where((w) => w.properties.liveRegion ?? false)
    .length;

void main() {
  group('LoadingRegion announces once for its area', () {
    testWidgets('ten skeletons in a region are one announcement', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, LoadingRegion(child: _skeletons()));

      expect(_announced(tester), [_kEnglish]);
      // The skeletons read the region and built no live region of their
      // own — not merely hidden under the region's exclusion.
      expect(_liveRegionWidgets(tester), 1);
      handle.dispose();
    });

    testWidgets('a skeleton on its own still announces itself', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, const Skeleton(height: 20));

      expect(_announced(tester), [_kEnglish]);
      handle.dispose();
    });

    testWidgets('the caller names what is loading', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        LoadingRegion(semanticLabel: _kOverride, child: _skeletons()),
      );

      expect(_announced(tester), [_kOverride]);
      handle.dispose();
    });

    testWidgets('the default label follows the active locale', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        LoadingRegion(child: _skeletons()),
        locale: const Locale('ko'),
      );

      expect(_announced(tester), [_kKorean]);
      handle.dispose();
    });

    testWidgets('a region inside a region is still one announcement', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        LoadingRegion(
          semanticLabel: _kOverride,
          child: LoadingRegion(child: _skeletons()),
        ),
      );

      expect(_announced(tester), [_kOverride]);
      expect(_liveRegionWidgets(tester), 1);
      handle.dispose();
    });

    testWidgets('the area is hidden while the region speaks for it', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        const LoadingRegion(child: Text('Placeholder order #1')),
      );

      // Not on a node of its own, and not folded into the region's label —
      // unexcluded, it merges into the region's node and is read with the
      // announcement.
      expect(
        _nodes(tester).where((n) => n.label.contains('Placeholder')),
        isEmpty,
      );
      expect(_announced(tester), [_kEnglish]);
      handle.dispose();
    });

    testWidgets('the label keeps its own node inside a labelled parent', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pump(
        tester,
        Semantics(
          label: 'Orders',
          child: LoadingRegion(child: _skeletons()),
        ),
      );

      // Folded into the parent's node, the announcement would read
      // "Orders, Loading" — the region is its own node.
      expect(_announced(tester), [_kEnglish]);
      handle.dispose();
    });

    testWidgets(
      'a skeleton in an overlay opened from the region announces itself',
      (tester) async {
        final handle = tester.ensureSemantics();
        await _pump(
          tester,
          LoadingRegion(
            semanticLabel: _kOverride,
            child: Builder(
              builder: (context) => GestureDetector(
                key: _kOpener,
                behavior: .opaque,
                onTap: () => Overlay.of(context).insert(
                  OverlayEntry(
                    builder: (_) => const Center(
                      child: Skeleton(width: 40, height: 40),
                    ),
                  ),
                ),
                child: const SizedBox(width: 100, height: 40),
              ),
            ),
          ),
        );

        await tester.tap(find.byKey(_kOpener));
        await tester.pump(_kFrame);
        await tester.pump(_kFrame);

        // The entry builds in the app's overlay, outside the region: neither
        // its scope nor its exclusion reaches there, so the skeleton
        // announces in its own words.
        expect(_announced(tester), [_kOverride, _kEnglish]);
        handle.dispose();
      },
    );

    testWidgets('reduced motion keeps the announcement', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CoUIApp(
            home: SizedBox(
              width: 320,
              child: LoadingRegion(child: _skeletons()),
            ),
            theme: ThemeData.fromCore(CoreThemePresets.light),
          ),
        ),
      );
      await tester.pump(_kFrame);

      expect(_announced(tester), [_kEnglish]);
      handle.dispose();
    });
  });
}
