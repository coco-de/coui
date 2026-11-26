import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        Align,
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        Size,
        SizedBox,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'parity_matrix_entry.dart';

const List<(String, String, BoxObservationSourceSpec)> _recipes = [
  ('mockup', 'phone', BoxObservationSourceSpec.mockupDeviceBodyFrame),
  ('mockup', 'tablet', BoxObservationSourceSpec.mockupDeviceBodyFrame),
  ('mockup', 'landscape', BoxObservationSourceSpec.mockupDeviceBodyFrame),
  ('mockup-device', 'default', BoxObservationSourceSpec.mockupDeviceBodyFrame),
  ('mockup-device', 'flat', BoxObservationSourceSpec.mockupDeviceBodyFrame),
  ('mockup', 'browser', BoxObservationSourceSpec.mockupBrowserFrame),
  ('mockup', 'app', BoxObservationSourceSpec.mockupBrowserFrame),
  ('join', 'default', BoxObservationSourceSpec.joinStripLayoutHost),
  ('join', 'vertical', BoxObservationSourceSpec.joinStripLayoutHost),
  ('join', 'input', BoxObservationSourceSpec.joinStripLayoutHost),
  ('table', 'default', BoxObservationSourceSpec.tableGridContentInset),
  ('table', 'resizable', BoxObservationSourceSpec.tableGridContentInset),
];

Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  SizedBox(width: 1100, height: 1100, child: Align(child: child)),
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);

void _view(WidgetTester tester) {
  tester.view.physicalSize = const Size(1500, 1500);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> _mount(
  WidgetTester tester,
  Widget result,
  GlobalKey capture, {
  bool dark = false,
}) async {
  _view(tester);
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

Map<String, Object?> _dispatch(
  GlobalKey capture,
  Widget result,
  BoxObservationSourceSpec source, {
  bool omitted = true,
  bool includeUndeclaredStage = false,
}) => observePairedNativePadding(
  key: 'independent-key-with-arbitrary-future-style',
  probes: [
    ParityProbeSpec(
      role: 'root',
      flutterFinder: 'source-only',
      fields: const {'paddingPx'},
      boxObservationSource: source.toJson(),
    ),
    if (includeUndeclaredStage)
      const ParityProbeSpec(
        role: 'stage',
        flutterFinder: 'source-only',
        fields: {'paddingPx'},
      ),
  ],
  captureRoot: capture.currentContext! as Element,
  registryResult: result,
  legacyRootOmitted: omitted,
);

Map<String, Object?> _root(Map<String, Object?> payload) =>
    (payload['byRole']! as Map<String, Object?>)['root']!
        as Map<String, Object?>;

void _complete(
  Map<String, Object?> payload,
  BoxObservationSourceSpec source, {
  required bool omitted,
}) {
  final root = _root(payload);
  expect(root['status'], 'source-complete', reason: '$root');
  expect(root['source'], source.toJson());
  expect(root['sourceUnitValidated'], isTrue);
  expect(root['sourceBindingAuthority'], isNotEmpty);
  expect(root['sourceReaderId'], isNotEmpty);
  expect(root['frameSourceStatus'], 'bound-configured-frame');
  expect(root['legacyRoleEligible'], !omitted);
  expect(root['canonicalComparisonEligible'], isFalse);
  expect(root['paintRequired'], isFalse);
  expect(payload['legacyRootOmitted'], omitted);
  expect(payload['mode'], 'additive-only');
  expect(payload['canonicalComparisonEligible'], isFalse);
}

class _UnknownBrowser extends coui.MockupBrowser {
  const _UnknownBrowser() : super(child: const SizedBox());
}

void main() {
  test('three new units preserve the existing browser source tuple', () {
    expect(BoxObservationSourceSpec.framedCollectionFrames.toSet(), {
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
      BoxObservationSourceSpec.joinStripLayoutHost,
      BoxObservationSourceSpec.tableGridContentInset,
    });
    expect(
      BoxObservationSourceSpec.componentFrames,
      contains(BoxObservationSourceSpec.mockupBrowserFrame),
    );
    expect(
      BoxObservationSourceSpec.framedCollectionFrames,
      isNot(contains(BoxObservationSourceSpec.mockupBrowserFrame)),
    );
  });

  for (final (component, variant, source) in _recipes) {
    for (final dark in [false, true]) {
      testWidgets('framed dispatcher $component/$variant/$dark', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry[component]!(
          variant == 'default' ? null : variant,
        );
        final capture = GlobalKey();
        await _mount(tester, result, capture, dark: dark);
        for (final omitted in [false, true]) {
          final payload = _dispatch(capture, result, source, omitted: omitted);
          _complete(payload, source, omitted: omitted);
          final root = _root(payload);
          final expectedKind =
              source == BoxObservationSourceSpec.mockupBrowserFrame
              ? PaddingQuantityKind.frameworkOwnParameter
              : source == BoxObservationSourceSpec.tableGridContentInset
              ? PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder
              : PaddingQuantityKind.declaredNoOwnPadding;
          expect(root['quantityKind'], expectedKind.name);
          // The exact existing browser Example intentionally retains its old
          // binding provenance. Every new binding names its actual reader refs.
          if (!(component == 'mockup' && variant == 'browser')) {
            expect(root['ownerElement'], root['declaredPaddingSourceElement']);
            expect(
              root['frameSourceOwnerElement'],
              root['declaredFrameSourceElement'],
            );
          }
        }
      });
    }
  }

  testWidgets('existing default browser remains a source-complete sibling', (
    tester,
  ) async {
    final result = kFlutterPreviewRegistry['mockup-browser']!(null);
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    final payload = _dispatch(
      capture,
      result,
      BoxObservationSourceSpec.mockupBrowserFrame,
    );
    _complete(
      payload,
      BoxObservationSourceSpec.mockupBrowserFrame,
      omitted: true,
    );
    expect(_root(payload)['sourceReaderId'], 'outlined-content-v1');
  });

  testWidgets('bad tuple and unknown Browser cannot enter the old sibling', (
    tester,
  ) async {
    const unknown = _UnknownBrowser();
    final capture = GlobalKey();
    await _mount(tester, unknown, capture);
    final unsupported = _root(
      _dispatch(capture, unknown, BoxObservationSourceSpec.mockupBrowserFrame),
    );
    expect(unsupported['status'], 'incomplete');
    expect(unsupported.containsKey('value'), isFalse);

    const result = coui.Join(children: [SizedBox(width: 8, height: 8)]);
    final nextCapture = GlobalKey();
    await _mount(tester, result, nextCapture);
    final source = BoxObservationSourceSpec.fromJson({
      ...BoxObservationSourceSpec.joinStripLayoutHost.toJson(),
      'webAdapterId': 'unsupported-paired-adapter',
    });
    final mismatched = _root(_dispatch(nextCapture, result, source));
    expect(mismatched['status'], 'incomplete');
    expect(mismatched.containsKey('value'), isFalse);
  });

  testWidgets(
    'whole foreign cell Padding never supplies dispatcher ownership',
    (
      tester,
    ) async {
      final a = GlobalKey();
      final b = GlobalKey();
      final result = coui.Table(
        rows: [
          coui.CoreTableRowData<Widget>(
            cells: [
              coui.CoreTableCellData<Widget>(
                child: Padding(
                  key: a,
                  padding: const EdgeInsets.all(71),
                  child: const SizedBox(width: 8, height: 8),
                ),
              ),
              coui.CoreTableCellData<Widget>(
                child: Padding(
                  key: b,
                  padding: const EdgeInsets.all(83),
                  child: const SizedBox(width: 9, height: 9),
                ),
              ),
            ],
          ),
        ],
      );
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final payload = _dispatch(
        capture,
        result,
        BoxObservationSourceSpec.tableGridContentInset,
      );
      _complete(
        payload,
        BoxObservationSourceSpec.tableGridContentInset,
        omitted: true,
      );
      final root = _root(payload);
      for (final key in [a, b]) {
        final current = key.currentContext;
        expect(current, isNotNull);
        final foreign = identityHashCode(current);
        expect(root['ownerElement'], isNot(foreign));
        expect(root['frameSourceOwnerElement'], isNot(foreign));
      }
      expect(
        root['quantityKind'],
        PaddingQuantityKind.declaredOuterEdgeInsetWithinBorder.name,
      );
    },
  );

  testWidgets('unrendered current raw replacement is incomplete, never zero', (
    tester,
  ) async {
    final cells = [
      const coui.CoreTableCellData<Widget>(
        child: SizedBox(width: 8, height: 8),
      ),
    ];
    final result = coui.Table(
      rows: [
        coui.CoreTableRowData<Widget>(cells: cells),
      ],
    );
    final capture = GlobalKey();
    await _mount(tester, result, capture);
    _complete(
      _dispatch(
        capture,
        result,
        BoxObservationSourceSpec.tableGridContentInset,
      ),
      BoxObservationSourceSpec.tableGridContentInset,
      omitted: true,
    );
    cells[0] = const coui.CoreTableCellData<Widget>(
      child: SizedBox(width: 19, height: 19),
    );
    final stale = _root(
      _dispatch(
        capture,
        result,
        BoxObservationSourceSpec.tableGridContentInset,
      ),
    );
    expect(stale['status'], 'incomplete');
    expect(stale.containsKey('value'), isFalse);
  });

  testWidgets('same mounted producer replacement rejects the old registry', (
    tester,
  ) async {
    const first = coui.MockupDevice(child: SizedBox(width: 8, height: 8));
    final current = ValueNotifier<Widget>(first);
    addTearDown(current.dispose);
    final capture = GlobalKey();
    _view(tester);
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
    final producer = tester.element(find.byType(coui.MockupDevice));
    const next = coui.MockupDevice(child: SizedBox(width: 11, height: 11));
    current.value = next;
    await tester.pumpAndSettle();
    expect(tester.element(find.byType(coui.MockupDevice)), same(producer));
    final stale = _root(
      _dispatch(capture, first, BoxObservationSourceSpec.mockupDeviceBodyFrame),
    );
    expect(stale['status'], 'incomplete');
    expect(stale.containsKey('value'), isFalse);
    _complete(
      _dispatch(capture, next, BoxObservationSourceSpec.mockupDeviceBodyFrame),
      BoxObservationSourceSpec.mockupDeviceBodyFrame,
      omitted: true,
    );
  });

  testWidgets(
    'every requested role stays present, undeclared stage incomplete',
    (
      tester,
    ) async {
      const result = coui.MockupDevice(child: SizedBox(width: 8, height: 8));
      final capture = GlobalKey();
      await _mount(tester, result, capture);
      final payload = _dispatch(
        capture,
        result,
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        includeUndeclaredStage: true,
      );
      _complete(
        payload,
        BoxObservationSourceSpec.mockupDeviceBodyFrame,
        omitted: true,
      );
      final roles = payload['byRole']! as Map<String, Object?>;
      expect(roles.keys, orderedEquals(['root', 'stage']));
      final stage = roles['stage']! as Map<String, Object?>;
      expect(stage['status'], 'incomplete');
      expect(stage['error'], 'MISSING_PAIRED_BOX_SOURCE');
    },
  );
}
