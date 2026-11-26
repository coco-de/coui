import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'box_padding_observation.dart';

Widget _host(Widget child) => Directionality(
  textDirection: .ltr,
  child: Center(child: child),
);

BoxProducerScope _scope(Element owner) => BoxProducerScope(
  producer: owner,
  suppliedSlots: [?(owner.widget as Container).child],
);

void main() {
  testWidgets('colourless padding is measured independently of paint', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _host(
        Container(
          key: key,
          padding: const .all(16),
          child: const Text('Layout source'),
        ),
      ),
    );
    final owner = key.currentContext! as Element;
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, const EdgeInsets.all(16));
    expect(observed.paddingElement, isNotNull);
    expect(observed.allocatedDecorationInsets, EdgeInsets.zero);
  });

  testWidgets('equal margin and padding use distinct framework slots', (
    tester,
  ) async {
    final key = GlobalKey();
    const sameInput = EdgeInsets.all(16);
    await tester.pumpWidget(
      _host(
        Container(
          key: key,
          margin: sameInput,
          padding: sameInput,
          child: const Text('Same input values'),
        ),
      ),
    );
    final owner = key.currentContext! as Element;
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, sameInput);
    expect(observed.excludedMargin, sameInput);
    final marginSlot = observed.generatedSlots.singleWhere(
      (slot) => slot['slot'] == 'margin',
    );
    final paddingSlot = observed.generatedSlots.singleWhere(
      (slot) => slot['slot'] == 'paddingIncludingDecoration',
    );
    expect(marginSlot['element'], isNot(paddingSlot['element']));
  });

  testWidgets('paint absence is not a missing source and no padding is zero', (
    tester,
  ) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _host(Container(key: key, child: const Text('No padding argument'))),
    );
    final owner = key.currentContext! as Element;
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, EdgeInsets.zero);
    expect(observed.paddingElement, isNull);
    expect(
      () => requireOneBoxOwner(const [], 'missing layout owner'),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('nonuniform allocation is separated per side', (tester) async {
    final key = GlobalKey();
    await tester.pumpWidget(
      _host(
        Container(
          key: key,
          padding: const .fromLTRB(11, 3, 5, 7),
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(width: 1),
              right: BorderSide(width: 2),
              bottom: BorderSide(width: 3),
              left: BorderSide(width: 4),
            ),
          ),
          child: const Text('Per side'),
        ),
      ),
    );
    final owner = key.currentContext! as Element;
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, const EdgeInsets.fromLTRB(11, 3, 5, 7));
    expect(
      observed.currentRenderPadding,
      const EdgeInsets.fromLTRB(15, 4, 7, 10),
    );
  });

  testWidgets('foreign padding and a wrong declared boundary are rejected', (
    tester,
  ) async {
    final key = GlobalKey();
    final foreign = GlobalKey();
    final leaf = GlobalKey();
    await tester.pumpWidget(
      _host(
        Container(
          key: key,
          child: Padding(
            key: foreign,
            padding: const .all(4),
            child: SizedBox(key: leaf, width: 40, height: 20),
          ),
        ),
      ),
    );
    final owner = key.currentContext! as Element;
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, EdgeInsets.zero);
    expect(observed.contentBoundary, same(foreign.currentContext));
    expect(
      () => observeCurrentContainerPadding(
        owner: owner,
        scope: _scope(owner),
        declaredContentBoundary: leaf.currentContext! as Element,
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });

  testWidgets('current animation value is distinct from its target', (
    tester,
  ) async {
    final key = GlobalKey();
    Widget app(double value) => _host(
      AnimatedContainer(
        key: key,
        duration: const Duration(milliseconds: 100),
        padding: .all(value),
        child: const Text('Current'),
      ),
    );
    await tester.pumpWidget(app(0));
    await tester.pumpWidget(app(16));
    await tester.pump(const Duration(milliseconds: 50));
    final owner = evaluatedAnimatedContainer(key.currentContext! as Element);
    final observed = observeCurrentContainerPadding(
      owner: owner,
      scope: _scope(owner),
    );
    expect(observed.value, const EdgeInsets.all(8));
    await tester.pump(const Duration(milliseconds: 50));
  });
}
