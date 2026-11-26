// `probeRootOpacity` against small hand-built trees — the three shapes
// that matter: nothing dims the root, the root itself is wrapped, and a
// slot inside the chrome is wrapped (which is not the root's own opacity).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'chrome_node_probe.dart';
import 'root_opacity_probe.dart';

Widget _host(GlobalKey rootKey, Widget child) => Directionality(
  textDirection: TextDirection.ltr,
  child: Center(
    child: KeyedSubtree(key: rootKey, child: child),
  ),
);

void main() {
  testWidgets('a root nothing dims measures fully opaque, not null', (
    tester,
  ) async {
    // This is the case that failed 262 of 262 nightly cells — Web says `1`
    // for every element, and Flutter said nothing.
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      _host(
        rootKey,
        const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF102030)),
          child: SizedBox(width: 40, height: 40),
        ),
      ),
    );
    final root = find.byKey(rootKey);
    final chrome = findChromeNode(tester, rootFinder: root);
    expect(chrome, isNotNull);

    expect(
      probeRootOpacity(
        tester,
        rootFinder: root,
        chromeRenderObject: chrome!.renderBox,
      ),
      kFullyOpaque,
    );
  });

  testWidgets('an Opacity wrapping the whole component is the root\'s own', (
    tester,
  ) async {
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      _host(
        rootKey,
        const Opacity(
          opacity: 0.5,
          child: DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFF102030)),
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
    final root = find.byKey(rootKey);
    final chrome = findChromeNode(tester, rootFinder: root);

    expect(
      probeRootOpacity(
        tester,
        rootFinder: root,
        chromeRenderObject: chrome!.renderBox,
      ),
      0.5,
    );
  });

  testWidgets('stacked opacities between root and chrome multiply', (
    tester,
  ) async {
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      _host(
        rootKey,
        const Opacity(
          opacity: 0.5,
          child: Padding(
            padding: EdgeInsets.all(4),
            child: Opacity(
              opacity: 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF102030)),
                child: SizedBox(width: 40, height: 40),
              ),
            ),
          ),
        ),
      ),
    );
    final root = find.byKey(rootKey);
    final chrome = findChromeNode(tester, rootFinder: root);

    expect(
      probeRootOpacity(
        tester,
        rootFinder: root,
        chromeRenderObject: chrome!.renderBox,
      ),
      closeTo(0.25, 1e-9),
    );
  });

  testWidgets('an Opacity around a slot inside the chrome is not the root\'s', (
    tester,
  ) async {
    // Web reads the root element only; a dimmed descendant reports `1` at
    // the root there too. Same answer here.
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      _host(
        rootKey,
        const DecoratedBox(
          decoration: BoxDecoration(color: Color(0xFF102030)),
          child: Opacity(
            opacity: 0.3,
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ),
    );
    final root = find.byKey(rootKey);
    final chrome = findChromeNode(tester, rootFinder: root);

    expect(
      probeRootOpacity(
        tester,
        rootFinder: root,
        chromeRenderObject: chrome!.renderBox,
      ),
      kFullyOpaque,
    );
  });

  testWidgets('with no chrome node, the root\'s own render object decides', (
    tester,
  ) async {
    final rootKey = GlobalKey();
    await tester.pumpWidget(
      _host(
        rootKey,
        const Opacity(opacity: 0.4, child: Text('plain')),
      ),
    );
    final root = find.byKey(rootKey);
    expect(findChromeNode(tester, rootFinder: root), isNull);

    expect(probeRootOpacity(tester, rootFinder: root), closeTo(0.4, 1e-9));
  });
}
