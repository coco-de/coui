import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/mockup/mockup_browser_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_component_units.dart';
import 'box_padding_framed_collection_units.dart';
import 'box_padding_observation.dart';
import 'box_padding_source_bindings.dart';

const _recipes = <({String component, String variant})>[
  (component: 'mockup', variant: 'phone'),
  (component: 'mockup', variant: 'tablet'),
  (component: 'mockup', variant: 'landscape'),
  (component: 'mockup-device', variant: 'default'),
  (component: 'mockup-device', variant: 'flat'),
  (component: 'mockup', variant: 'browser'),
  (component: 'mockup', variant: 'app'),
  (component: 'join', variant: 'default'),
  (component: 'join', variant: 'vertical'),
  (component: 'join', variant: 'input'),
  (component: 'table', variant: 'default'),
  (component: 'table', variant: 'resizable'),
];

BoxObservationSourceSpec _source(String component, String variant) {
  if (component == 'table') {
    return BoxObservationSourceSpec.tableGridContentInset;
  }
  if (component == 'join') return BoxObservationSourceSpec.joinStripLayoutHost;
  if (component == 'mockup' && (variant == 'browser' || variant == 'app')) {
    return BoxObservationSourceSpec.mockupBrowserFrame;
  }
  return BoxObservationSourceSpec.mockupDeviceBodyFrame;
}

Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  SizedBox(width: 1100, height: 1100, child: Align(child: child)),
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
}) async {
  tester.view.physicalSize = const Size(1500, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    _app(
      KeyedSubtree(key: capture, child: result),
      dark: dark,
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
}

FramedCollectionBoxSourceBinding? _bind(
  GlobalKey capture,
  Widget result,
  BoxObservationSourceSpec source,
) => bindFramedCollectionBoxSource(
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  source: source,
);

BoxPaddingObservation _read(FramedCollectionBoxSourceBinding binding) =>
    binding.readerId == 'framed-collection-declared-absence-v1'
    ? binding.readDeclaredAbsence()
    : binding.readActualPadding();

Widget _foreign(double inset) => Padding(
  padding: EdgeInsets.all(inset),
  child: const SizedBox(width: 8, height: 8),
);

List<coui.CoreTableRowData<Widget>> _rows(Widget a, Widget b) => [
  coui.CoreTableRowData<Widget>.header(
    cells: [coui.CoreTableCellData<Widget>(child: a)],
  ),
  coui.CoreTableRowData<Widget>(
    cells: [coui.CoreTableCellData<Widget>(child: b)],
  ),
];

class _UnknownDevice extends coui.MockupDevice {
  const _UnknownDevice() : super(child: const SizedBox());
}

class _UnknownJoin extends coui.Join {
  const _UnknownJoin() : super(children: const [SizedBox()]);
}

class _UnknownTable extends coui.Table {
  const _UnknownTable() : super(rows: const []);
}

class _UnknownBrowser extends coui.MockupBrowser {
  const _UnknownBrowser() : super(child: const SizedBox());
}

class _UnknownCell extends coui.CoreTableCellData<Widget> {
  const _UnknownCell() : super(child: const SizedBox());
}

void main() {
  for (final recipe in _recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant}/$dark actual registry',
        (
          tester,
        ) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await _mount(tester, result, capture, dark: dark);
          final source = _source(recipe.component, recipe.variant);
          final binding = _bind(capture, result, source);
          if (recipe.component == 'mockup' && recipe.variant == 'browser') {
            expect(result.runtimeType, MockupBrowserExample);
            expect(binding, isNull);
            final old = bindComponentBoxSource(
              captureRoot: capture.currentContext! as Element,
              registryResult: result,
              source: source,
            )!;
            final observed = observeOutlinedContainerContentPadding(
              primitive: old.paddingSource,
              declaringScope: old.scope,
            );
            expect(
              observed.quantity,
              PaddingQuantityKind.frameworkOwnParameter,
            );
            expect(observed.frameOwner, isNotNull);
            return;
          }
          expect(binding, isNotNull);
          final current = binding!..validateExistingCurrentBinding();
          final observed = _read(current);
          expect(observed.owner, same(current.paddingSource));
          expect(observed.frameOwner, same(current.frameSource));
          expect(observed.producer, same(current.registryResultElement));
          if (recipe.component == 'table') {
            expect(
              observed.quantity,
              PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder,
            );
            expect(current.frameSource.widget, isA<DecoratedBox>());
            expect(current.paddingSource.widget, isA<Padding>());
          } else if (recipe.variant == 'app') {
            expect(
              observed.quantity,
              PaddingQuantityKind.frameworkOwnParameter,
            );
            expect(current.paddingSource.widget, isA<Container>());
            expect(current.frameSource.widget, isA<Container>());
          } else {
            expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
            expect(observed.value, EdgeInsets.zero);
          }
          for (final boundary in current.scope.foreignBoundaries) {
            expect(
              () => current.scope.requireOwned(boundary),
              throwsA(isA<BoxObservationError>()),
            );
          }
        },
      );
    }
  }

  testWidgets('device owns the body SizedBox, not screen SafeArea or child', (
    tester,
  ) async {
    final foreign = _foreign(71);
    final result = coui.MockupDevice(child: foreign);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(
      capture,
      result,
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
    )!;
    expect(binding.fieldUnitElement.widget, isA<SizedBox>());
    expect(binding.fieldUnitElement.renderObject, isA<RenderConstrainedBox>());
    expect(binding.scope.foreignBoundaries.single.widget, same(foreign));
    expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
    expect(
      binding.readActualPadding,
      throwsA(isA<BoxObservationError>()),
    );
  });

  for (final vertical in [false, true]) {
    testWidgets('Join whole foreign items and current focus/$vertical', (
      tester,
    ) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      final first = Focus(focusNode: node, child: _foreign(71));
      final second = _foreign(83);
      final result = coui.Join(vertical: vertical, children: [first, second]);
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final binding = _bind(
        capture,
        result,
        BoxObservationSourceSpec.joinStripLayoutHost,
      )!;
      expect(
        binding.fieldUnitElement.widget,
        vertical ? isA<IntrinsicWidth>() : isA<IntrinsicHeight>(),
      );
      expect(
        binding.scope.foreignBoundaries.map((e) => e.widget),
        orderedEquals([first, second]),
      );
      expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);
      binding.validateExistingCurrentBinding();
      expect(binding.readDeclaredAbsence().value, EdgeInsets.zero);
      expect(binding.scope.foreignBoundaries.first.widget, same(first));
    });
  }

  testWidgets('duplicate Join raw widgets reject before any absence read', (
    tester,
  ) async {
    final child = _foreign(31);
    final result = coui.Join(children: [child, child]);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(
      () =>
          _bind(capture, result, BoxObservationSourceSpec.joinStripLayoutHost),
      throwsA(isA<BoxObservationError>()),
    );
  });

  for (final width in [0.0, 1.5, 7.0]) {
    testWidgets('Table reads actual padding and same border parts/$width', (
      tester,
    ) async {
      final result = coui.Table(
        rows: _rows(_foreign(71), _foreign(83)),
        tableStyle: coui.CoreTableStyle(outerBorderWidth: width),
      );
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final binding = _bind(
        capture,
        result,
        BoxObservationSourceSpec.tableGridContentInset,
      )!;
      final observation = binding.readActualPadding();
      final renderPadding =
          binding.paddingSource.renderObject! as RenderPadding;
      final decoration =
          (binding.frameSource.renderObject! as RenderDecoratedBox).decoration
              as BoxDecoration;
      final direction = Directionality.of(binding.paddingSource);
      final actualPadding = renderPadding.padding.resolve(direction);
      final actualBorder =
          decoration.border?.dimensions.resolve(direction) ?? EdgeInsets.zero;
      expect(observation.currentRenderPadding, actualPadding);
      expect(observation.allocatedDecorationInsets, actualBorder);
      expect(observation.value, actualPadding - actualBorder);
      expect(actualPadding, EdgeInsets.all(width));
      expect(actualBorder, EdgeInsets.all(width));
      expect(binding.scope.foreignBoundaries.length, 2);
      expect(
        binding.readDeclaredAbsence,
        throwsA(isA<BoxObservationError>()),
      );
    });
  }

  testWidgets('all table rows reject cross-row raw aliases and unknown data', (
    tester,
  ) async {
    final duplicate = _foreign(71);
    for (final rows in [
      _rows(duplicate, duplicate),
      <coui.CoreTableRowData<Widget>>[
        const coui.CoreTableRowData<Widget>(cells: [_UnknownCell()]),
      ],
    ]) {
      final result = coui.Table(rows: rows);
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      expect(
        () => _bind(
          capture,
          result,
          BoxObservationSourceSpec.tableGridContentInset,
        ),
        throwsA(isA<BoxObservationError>()),
      );
    }
  });

  testWidgets('ResizableTable observes the actual current public controller', (
    tester,
  ) async {
    final controller = coui.ResizableTableController(
      defaultColumnWidth: 160,
      defaultRowHeight: 64,
    );
    addTearDown(controller.dispose);
    final result = coui.ResizableTable(
      controller: controller,
      rows: _rows(_foreign(7), _foreign(11)),
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final binding = _bind(
      capture,
      result,
      BoxObservationSourceSpec.tableGridContentInset,
    )!;
    final frame = binding.frameSource;
    controller.resizeColumn(0, 220);
    await tester.pumpAndSettle();
    binding.validateExistingCurrentBinding();
    expect(binding.frameSource, same(frame));
    expect(
      binding.readActualPadding().quantity,
      PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder,
    );
  });

  testWidgets(
    'Browser actual reader is shared, including a null content slot',
    (
      tester,
    ) async {
      for (final child in <Widget?>[null, _foreign(71)]) {
        final result = coui.MockupBrowser(addressBar: null, child: child);
        final capture = GlobalKey();
        await _mount(tester, result, capture);
        final binding = _bind(
          capture,
          result,
          BoxObservationSourceSpec.mockupBrowserFrame,
        )!;
        final observed = binding.readActualPadding();
        expect(observed.owner, same(binding.paddingSource));
        expect(observed.frameOwner, same(binding.frameSource));
        expect(observed.quantity, PaddingQuantityKind.frameworkOwnParameter);
        expect(binding.scope.foreignBoundaries.length, child == null ? 0 : 1);
      }
    },
  );

  testWidgets('legacy default Browser remains the unchanged sibling route', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['mockup-browser']!(null);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    expect(result.runtimeType, MockupBrowserExample);
    expect(
      _bind(capture, result, BoxObservationSourceSpec.mockupBrowserFrame),
      isNull,
    );
    final old = bindComponentBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: BoxObservationSourceSpec.mockupBrowserFrame,
    )!;
    expect(
      observeOutlinedContainerContentPadding(
        primitive: old.paddingSource,
        declaringScope: old.scope,
      ).quantity,
      PaddingQuantityKind.frameworkOwnParameter,
    );
  });

  testWidgets(
    'unknown concrete producers are terminal, never sibling fallback',
    (
      tester,
    ) async {
      final fixtures = <(Widget, BoxObservationSourceSpec)>[
        (
          const _UnknownDevice(),
          BoxObservationSourceSpec.mockupDeviceBodyFrame,
        ),
        (const _UnknownJoin(), BoxObservationSourceSpec.joinStripLayoutHost),
        (const _UnknownTable(), BoxObservationSourceSpec.tableGridContentInset),
        (const _UnknownBrowser(), BoxObservationSourceSpec.mockupBrowserFrame),
      ];
      for (final (result, source) in fixtures) {
        final capture = GlobalKey();
        await _mount(tester, result, capture);
        expect(
          () => _bind(capture, result, source),
          throwsA(isA<BoxObservationError>()),
        );
      }
    },
  );

  testWidgets('same mounted producer replacement rejects a held binding', (
    tester,
  ) async {
    final first = coui.MockupDevice(child: _foreign(7));
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    final capture = GlobalKey();
    tester.view.physicalSize = const Size(1500, 1500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      _app(
        ValueListenableBuilder<Widget>(
          valueListenable: current,
          builder: (_, value, child) =>
              KeyedSubtree(key: capture, child: value),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final held = _bind(
      capture,
      first,
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
    )!;
    final firstElement = tester.element(find.byType(coui.MockupDevice));
    final next = coui.MockupDevice(child: _foreign(19));
    current.value = next;
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(coui.MockupDevice)), same(firstElement));
    expect(
      held.readDeclaredAbsence,
      throwsA(isA<BoxObservationError>()),
    );
    final replacement = _bind(
      capture,
      next,
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
    )!;
    expect(replacement.scope.foreignBoundaries.single.widget, same(next.child));
    expect(replacement.readDeclaredAbsence().value, EdgeInsets.zero);
  });

  testWidgets('wrong adapter and missing independent Join frame reject', (
    tester,
  ) async {
    final result = coui.MockupDevice(child: _foreign(5));
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    const spec = BoxObservationSourceSpec.mockupDeviceBodyFrame;
    final wrong = BoxObservationSourceSpec(
      schemaVersion: 1,
      logicalUnitId: spec.logicalUnitId,
      quantityId: spec.quantityId,
      nativeAdapterId: 'foreign-adapter',
      webAdapterId: spec.webAdapterId,
    );
    expect(
      () => _bind(capture, result, wrong),
      throwsA(isA<BoxObservationError>()),
    );
    const empty = coui.Join(children: []);
    final emptyCapture = GlobalKey();
    await _mount(tester, empty, emptyCapture);
    expect(
      () => _bind(
        emptyCapture,
        empty,
        BoxObservationSourceSpec.joinStripLayoutHost,
      ),
      throwsA(isA<BoxObservationError>()),
    );
  });
}
