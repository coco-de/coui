import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_public_wrapper_units.dart';
import 'box_padding_structured_root_units.dart';

Future<Element> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  TextDirection direction = TextDirection.ltr,
  double width = 800,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    buildTestApp(
      SizedBox(
        width: width,
        height: 400,
        child: KeyedSubtree(key: capture, child: result),
      ),
      textDirection: direction,
      disableAnimations: true,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return capture.currentContext! as Element;
}

PublicWrapperBoxSourceBinding _bind(
  Element capture,
  Widget result,
  BoxObservationSourceSpec source,
) => bindPublicWrapperBoxSource(
  captureRoot: capture,
  registryResult: result,
  source: source,
)!;

void main() {
  for (final width in [400.0, 800.0]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'Media normal public branch/$width/$direction owns SizedBox only',
        (tester) async {
          const first = Padding(
            padding: EdgeInsets.fromLTRB(31, 37, 41, 43),
            child: Text('primary'),
          );
          const second = Padding(
            padding: EdgeInsets.fromLTRB(47, 53, 59, 61),
            child: Text('alternate'),
          );
          const product = coui.MediaQueryVisibility(
            minBreakpoint: coui.CoreBreakpoint.md,
            alternateChild: second,
            child: first,
          );
          final capture = GlobalKey();
          final root = await _mount(
            tester,
            product,
            capture,
            width: width,
            direction: direction,
          );
          final binding = _bind(
            root,
            product,
            BoxObservationSourceSpec.mediaQueryVisibilityHost,
          );
          expect(binding.fieldUnitElement.widget, isA<SizedBox>());
          expect(
            binding.fieldUnitElement.renderObject,
            isA<RenderConstrainedBox>(),
          );
          final actual = binding.readDeclaredAbsence();
          expect(actual.quantity.name, 'declaredNoOwnPadding');
          expect(actual.paddingElement, isNull);
          expect(binding.allOriginalSuppliedSlots, [first, second]);
          expect(binding.scope.foreignBoundaries, hasLength(1));
          expect(find.byWidget(width < 768 ? second : first), findsOneWidget);
          expect(actual.owner, same(binding.fieldUnitElement));
        },
      );
    }
  }
  testWidgets(
    'Media nullable omitted alternate and aliases remain distinct source facts',
    (tester) async {
      const child = Text('only');
      const product = coui.MediaQueryVisibility(minWidth: 900, child: child);
      final capture = GlobalKey();
      final root = await _mount(tester, product, capture);
      final binding = _bind(
        root,
        product,
        BoxObservationSourceSpec.mediaQueryVisibilityHost,
      );
      expect(binding.allOriginalSuppliedSlots, [child, null]);
      expect(binding.scope.foreignBoundaries, isEmpty);
      binding.readDeclaredAbsence();
      const alias = coui.MediaQueryVisibility(
        minWidth: 900,
        alternateChild: child,
        child: child,
      );
      final other = GlobalKey();
      final otherRoot = await _mount(tester, alias, other);
      expect(
        () => _bind(
          otherRoot,
          alias,
          BoxObservationSourceSpec.mediaQueryVisibilityHost,
        ),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets(
    'whole foreign descendant renderer changes keep Media source valid',
    (tester) async {
      final value = ValueNotifier<Widget>(
        const Padding(padding: EdgeInsets.all(71), child: Text('a')),
      );
      addTearDown(value.dispose);
      final foreign = ValueListenableBuilder<Widget>(
        valueListenable: value,
        builder: (context, w, child) => w,
      );
      final product = coui.MediaQueryVisibility(minWidth: 1, child: foreign);
      final capture = GlobalKey();
      final root = await _mount(tester, product, capture);
      final binding = _bind(
        root,
        product,
        BoxObservationSourceSpec.mediaQueryVisibilityHost,
      )..readDeclaredAbsence();
      value.value = const SizedBox(width: 91, height: 29);
      await tester.pump();
      binding.validateExistingCurrentBinding();
      expect(binding.scope.foreignBoundaries.single.widget, same(foreign));
    },
  );
  testWidgets('held Media branch changes reject then fresh binding succeeds', (
    tester,
  ) async {
    const product = coui.MediaQueryVisibility(
      minWidth: 600,
      alternateChild: Text('b'),
      child: Text('a'),
    );
    final width = ValueNotifier<double>(800);
    addTearDown(width.dispose);
    final capture = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        ValueListenableBuilder<double>(
          valueListenable: width,
          builder: (context, w, child) =>
              SizedBox(width: w, height: 200, child: child),
          child: KeyedSubtree(key: capture, child: product),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final root = capture.currentContext! as Element;
    final held = _bind(
      root,
      product,
      BoxObservationSourceSpec.mediaQueryVisibilityHost,
    )..readDeclaredAbsence();
    width.value = 400;
    await tester.pumpAndSettle();
    expect(
      held.validateExistingCurrentBinding,
      throwsA(isA<BoxObservationError>()),
    );
    _bind(
      root,
      product,
      BoxObservationSourceSpec.mediaQueryVisibilityHost,
    ).readDeclaredAbsence();
  });
  for (final enabled in [true, false]) {
    for (final direction in TextDirection.values) {
      testWidgets(
        'Swipe normal open/close disabled=$enabled direction=$direction keeps Stack source',
        (tester) async {
          var calls = 0;
          final product = coui.SwipeActions(
            enabled: enabled,
            swipeActionsStyle: const coui.CoreSwipeActionsStyle(
              platterInset: 29,
            ),
            trailingActions: [
              coui.CoreSwipeAction<Widget>(
                label: 'act',
                icon: const Text('icon'),
                onPressed: () => calls++,
              ),
            ],
            child: const SizedBox(
              width: 400,
              height: 64,
              child: Padding(
                padding: EdgeInsets.fromLTRB(31, 37, 41, 43),
                child: Text('row'),
              ),
            ),
          );
          final capture = GlobalKey();
          final root = await _mount(
            tester,
            product,
            capture,
            direction: direction,
            width: 400,
          );
          var binding = _bind(
            root,
            product,
            BoxObservationSourceSpec.swipeActionsOuterHost,
          );
          expect(binding.fieldUnitElement.widget, isA<Stack>());
          expect(binding.fieldUnitElement.renderObject, isA<RenderStack>());
          binding.readDeclaredAbsence();
          expect(calls, 0);
          if (enabled) {
            await tester.drag(
              find.byWidget(product.child),
              Offset(direction == TextDirection.ltr ? -65 : 65, 0),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
            expect(
              binding.validateExistingCurrentBinding,
              throwsA(isA<BoxObservationError>()),
            );
            binding = _bind(
              root,
              product,
              BoxObservationSourceSpec.swipeActionsOuterHost,
            )..readDeclaredAbsence();
            await tester.tap(find.byWidget(product.child));
            await tester.pumpAndSettle();
            _bind(
              root,
              product,
              BoxObservationSourceSpec.swipeActionsOuterHost,
            ).readDeclaredAbsence();
            expect(calls, 0, reason: 'Observer never invokes action callbacks');
          }
        },
      );
    }
  }
  testWidgets(
    'Swipe retains raw icon aliases even while actions are disabled',
    (tester) async {
      const same = Text('alias');
      final product = coui.SwipeActions(
        enabled: false,
        trailingActions: [
          coui.CoreSwipeAction<Widget>(
            label: 'a',
            icon: same,
            onPressed: () {},
          ),
        ],
        child: same,
      );
      final capture = GlobalKey();
      final root = await _mount(tester, product, capture);
      expect(
        () => _bind(
          root,
          product,
          BoxObservationSourceSpec.swipeActionsOuterHost,
        ),
        throwsA(isA<BoxObservationError>()),
      );
    },
  );
  testWidgets(
    'copied producer is not the original capture and '
    'held render parameter swaps reject',
    (tester) async {
      Widget create() =>
          const coui.MediaQueryVisibility(minWidth: 1, child: Text('child'));
      final original = create();
      final other = coui.MediaQueryVisibility(
        minWidth: 1,
        child: (original as coui.MediaQueryVisibility).child,
      );
      expect(identical(original, other), false);
      final capture = GlobalKey();
      final root = await _mount(tester, original, capture);
      final binding = _bind(
        root,
        original,
        BoxObservationSourceSpec.mediaQueryVisibilityHost,
      )..readDeclaredAbsence();
      expect(
        () => _bind(
          root,
          other,
          BoxObservationSourceSpec.mediaQueryVisibilityHost,
        ),
        throwsA(isA<BoxObservationError>()),
      );
      final render =
          binding.fieldUnitElement.renderObject! as RenderConstrainedBox;
      final before = render.additionalConstraints;
      render.additionalConstraints = const BoxConstraints.tightFor(width: 73);
      expect(identical(render.additionalConstraints, before), false);
      expect(
        binding.validateExistingCurrentBinding,
        throwsA(isA<BoxObservationError>()),
      );
      render.additionalConstraints = before;
      binding.validateExistingCurrentBinding();
    },
  );
  testWidgets('Tree generic callback remains rejected without replay', (
    tester,
  ) async {
    var calls = 0;
    final product = coui.Tree(
      nodes: const [coui.CoreTreeNode(label: 'node')],
      trailingBuilder: (context, node, {required expanded}) {
        calls++;
        return const Padding(
          padding: EdgeInsets.all(93),
          child: Text('foreign'),
        );
      },
    );
    final capture = GlobalKey();
    final root = await _mount(tester, product, capture);
    final normalCalls = calls;
    expect(normalCalls, greaterThan(0));
    expect(
      () => bindStructuredRootBoxSource(
        captureRoot: root,
        registryResult: product,
        source: BoxObservationSourceSpec.treeOuterLayoutHost,
      ),
      throwsA(isA<BoxObservationError>()),
    );
    expect(calls, normalCalls);
  });
  testWidgets(
    'original Tree trailing rows are generated opaque boundaries, '
    'not supplied slots',
    (tester) async {
      final result = kFlutterPreviewRegistry['tree']!('trailing');
      final capture = GlobalKey();
      final root = await _mount(tester, result, capture);
      final held = bindStructuredRootBoxSource(
        captureRoot: root,
        registryResult: result,
        source: BoxObservationSourceSpec.treeOuterLayoutHost,
      )!;
      expect(held.scope.suppliedSlots, isEmpty);
      held.readDeclaredAbsence();
      await tester.tap(find.text('src'));
      await tester.pumpAndSettle();
      expect(
        held.validateExistingCurrentBinding,
        throwsA(isA<BoxObservationError>()),
      );
      final fresh = bindStructuredRootBoxSource(
        captureRoot: root,
        registryResult: result,
        source: BoxObservationSourceSpec.treeOuterLayoutHost,
      )!..readDeclaredAbsence();
      expect(fresh.fieldUnitElement.widget, isA<Column>());
    },
  );
}
