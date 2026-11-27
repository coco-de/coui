import 'dart:io';
import 'dart:typed_data';

import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart'
    show
        Column,
        Element,
        GlobalKey,
        KeyedSubtree,
        MediaQuery,
        MediaQueryData,
        SingleChildScrollView,
        SizedBox,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_paired.dart';
import 'box_padding_showcase_allocation_units.dart';
import 'capture_localizations.dart';
import 'parity_fonts.dart';
import 'parity_matrix_entry.dart';
import 'parity_network_image_stub.dart';

const _kMountFrameWait = Duration(milliseconds: 100);

const _kWire = <String, Object?>{
  'schemaVersion': 1,
  'logicalUnitId': 'classic-compound-showcase-allocation-host',
  'quantityId': 'inside-frame-own-content-inset-v1',
  'nativeAdapterId': 'classic-compound-showcase-allocation-host-v1',
  'webAdapterId': 'classic-compound-showcase-allocation-host-v1',
};
const _kRecipes = <(String, String), ({Type host, int count})>{
  ('card-image', 'default'): (host: SizedBox, count: 1),
  ('hidden', 'default'): (host: Column, count: 3),
  ('window', 'default'): (host: Column, count: 3),
  ('draggable-panel', 'default'): (host: SizedBox, count: 1),
  ('draggable-panel', 'outside'): (host: SizedBox, count: 1),
  ('scrollable-client', 'default'): (host: SizedBox, count: 1),
  ('table', 'scrollable'): (host: SizedBox, count: 1),
  ('mockup-foldable', 'angle'): (host: SizedBox, count: 1),
  ('mockup-foldable', 'default'): (host: Column, count: 2),
  ('scaffold', 'default'): (host: SizedBox, count: 1),
  ('bottom-action-bar', 'scaffold'): (host: SizedBox, count: 1),
  ('scrollview', 'default'): (host: SizedBox, count: 1),
};
late Uint8List _stubImageBytes;

void _environment() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadParityFonts);
  setUpAll(() async {
    _stubImageBytes = await renderParityStubImageBytes();
  });
  late Directory icons;
  late String previousCache;
  setUpAll(() async {
    previousCache = coui.IconResolver.instance.cacheDir;
    icons = Directory.systemTemp.createTempSync('hosted-showcase-icons-');
    File(
      '../../tool/parity/vendor/iconify/lucide-1.2.121.json',
    ).copySync('${icons.path}/lucide.json');
    coui.IconResolver.instance.cacheDir = icons.path;
    await coui.IconResolver.instance.loadFromDisk();
  });
  tearDownAll(() {
    coui.IconResolver.instance.clearMemoryCache();
    coui.IconResolver.instance.cacheDir = previousCache;
    icons.deleteSync(recursive: true);
  });
}

typedef _Mount = ({
  Widget result,
  GlobalKey capture,
  Element host,
  List<Widget?> raw,
  List<Element> seats,
});

List<Element> _children(Element parent) {
  final out = <Element>[];
  parent.visitChildren(out.add);
  return out;
}

Element? _parent(Element element) {
  Element? parent;
  element.visitAncestorElements((ancestor) {
    parent = ancestor;
    return false;
  });
  return parent;
}

Future<void> _mounted(
  WidgetTester tester,
  (String, String) recipe,
  bool dark,
  Future<void> Function(_Mount mounted) run,
) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await runParityEntryWithStubbedNetwork(_stubImageBytes, () async {
    // The actual registry builder is called once.
    // Never replay any child builder.
    final result = kFlutterPreviewRegistry[recipe.$1]!(recipe.$2);
    final capture = GlobalKey();
    try {
      await tester.pumpWidget(
        captureLocalizations(
          child: buildTestApp(
            MediaQuery(
              data: const MediaQueryData(
                size: Size(800, 1200),
                devicePixelRatio: 1,
              ),
              child: SizedBox(
                width: 800,
                height: 1200,
                child: SingleChildScrollView(
                  child: KeyedSubtree(key: capture, child: result),
                ),
              ),
            ),
            theme: coui.ThemeData.fromCore(
              dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(_kMountFrameWait);
      await settleImagesInTree(tester);
      // HTTP, locale/provider, overflow and async framework errors invalidate
      // the fixture BEFORE any missing-source expectation can count as RED.
      expect(
        tester.takeException(),
        isNull,
        reason: 'ADDITIONAL_SHOWCASE_FIXTURE_INVALID',
      );
      final captureElement = capture.currentContext! as Element;
      final example = _children(captureElement).single;
      expect(example.widget, same(result));
      final host = _children(example).single;
      final shape = _kRecipes[recipe]!;
      expect(host.widget.runtimeType, shape.host);
      expect(_parent(host), same(example));
      final raw = host.widget is SizedBox
          ? <Widget?>[(host.widget as SizedBox).child]
          : List<Widget?>.of((host.widget as Column).children);
      expect(raw, hasLength(shape.count));
      expect(raw.every((slot) => slot != null), true);
      final seats = _children(host);
      expect(seats, hasLength(raw.length));
      expect(Set<Element>.identity()..addAll(seats), hasLength(raw.length));
      final render = host.renderObject! as RenderBox;
      expect(render.attached && render.hasSize, true);
      final frontiers = <RenderObject>[];
      for (var i = 0; i < raw.length; i++) {
        expect(seats[i].widget, same(raw[i]));
        expect(_parent(seats[i]), same(host));
        final frontier = seats[i].findRenderObject()!;
        expect(frontier.attached, true);
        expect(frontier.parent, same(render));
        frontiers.add(frontier);
      }
      final actual = <RenderObject>[];
      render.visitChildren(actual.add);
      expect(actual, orderedEquals(frontiers));
      expect(
        Set<RenderObject>.identity()..addAll(frontiers),
        hasLength(raw.length),
      );
      expect(
        tester.takeException(),
        isNull,
        reason: 'ADDITIONAL_SHOWCASE_FIXTURE_INVALID',
      );
      // All public mount-health assertions precede source observation.
      await run((
        result: result,
        capture: capture,
        host: host,
        raw: raw,
        seats: seats,
      ));
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'ADDITIONAL_SHOWCASE_FIXTURE_INVALID',
      );
    }
  });
}

Map<dynamic, dynamic> _paired(
  _Mount mounted, {
  Map<String, Object?>? source = _kWire,
}) {
  final payload = observePairedNativePadding(
    key: 'original-hosted-entry',
    probes: [
      ParityProbeSpec(
        role: 'root',
        flutterFinder: 'UnchangedFinder',
        fields: const {'paddingPx'},
        boxObservationSource: source,
      ),
    ],
    captureRoot: mounted.capture.currentContext! as Element,
    registryResult: mounted.result,
    legacyRootOmitted: true,
  );
  expect(payload['legacyRootOmitted'], true);
  expect(payload['canonicalComparisonEligible'], false);
  return (payload['byRole']! as Map)['root']! as Map;
}

ShowcaseAllocationBoxSourceBinding _bind(_Mount mounted) =>
    bindShowcaseAllocationBoxSource(
      captureRoot: mounted.capture.currentContext! as Element,
      registryResult: mounted.result,
      source: BoxObservationSourceSpec.showcaseAllocationHost,
    )!;

void main() {
  _environment();
  for (final recipe in _kRecipes.keys) {
    for (final dark in [false, true]) {
      testWidgets('$recipe/$dark actual host and real entry bind all slots', (
        tester,
      ) async {
        await _mounted(tester, recipe, dark, (mounted) async {
          final binding = _bind(mounted);
          expect(binding.fieldUnitElement, same(mounted.host));
          expect(binding.allOriginalSuppliedSlots, orderedEquals(mounted.raw));
          expect(binding.allOriginalMountedSeats, orderedEquals(mounted.seats));
          expect(binding.scope.foreignBoundaries, orderedEquals(mounted.seats));
          for (final seat in mounted.seats) {
            expect(
              () => binding.scope.requireOwned(seat),
              throwsA(isA<BoxObservationError>()),
            );
          }
          final row = _paired(mounted);
          expect(row['status'], 'source-complete', reason: '$row');
          expect(row['quantityKind'], 'declaredNoOwnPadding');
          expect(
            row['sourceReaderId'],
            'showcase-allocation-current-framework-host-v1',
          );
          final actual = binding.readDeclaredAbsence();
          expect(actual.owner, same(mounted.host));
          expect(actual.frameOwner, same(mounted.host));
          expect(actual.paddingElement, isNull);
          expect(actual.quantity, PaddingQuantityKind.declaredNoOwnPadding);
          expect(
            binding.readActualPadding,
            throwsA(isA<BoxObservationError>()),
          );
          expect(_paired(mounted, source: null)['status'], 'incomplete');
          final wrong = {..._kWire, 'webAdapterId': 'foreign'};
          expect(_paired(mounted, source: wrong)['status'], 'incomplete');
        });
      });
    }
  }
  for (final mutation in ['drop', 'reorder', 'extra repeated occurrence']) {
    testWidgets('$mutation cannot erase a Hidden raw seat', (tester) async {
      await _mounted(tester, ('hidden', 'default'), false, (mounted) async {
        final binding = _bind(mounted);
        final raw = (mounted.host.widget as Column).children;
        final original = List<Widget>.of(raw);
        try {
          if (mutation == 'drop') raw.removeLast();
          if (mutation == 'reorder') {
            final first = raw[0];
            raw[0] = raw[1];
            raw[1] = first;
          }
          if (mutation == 'extra repeated occurrence') raw.add(raw[1]);
          expect(
            binding.readDeclaredAbsence,
            throwsA(isA<BoxObservationError>()),
          );
          expect(() => _bind(mounted), throwsA(isA<BoxObservationError>()));
        } finally {
          raw
            ..clear()
            ..addAll(original);
        }
        binding.validateExistingCurrentBinding();
      });
    });
  }
  testWidgets('actual renderer reorder is not a source allocation', (
    tester,
  ) async {
    await _mounted(tester, ('hidden', 'default'), false, (mounted) async {
      final binding = _bind(mounted);
      final render = mounted.host.renderObject! as RenderFlex;
      final first = render.firstChild!;
      final second = render.childAfter(first)!;
      try {
        render.move(first, after: second);
        expect(
          binding.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
      } finally {
        render.move(first);
      }
      binding.validateExistingCurrentBinding();
    });
  });
  testWidgets('nullable SizedBox raw input is retained before rejection', (
    tester,
  ) async {
    await _mounted(tester, ('scrollable-client', 'default'), false, (
      mounted,
    ) async {
      final binding = _bind(mounted);
      final original = mounted.host.widget as SizedBox;
      const empty = SizedBox(height: 320);
      try {
        mounted.host.owner!.buildScope(
          mounted.host,
          () => mounted.host.update(empty),
        );
        await tester.pump();
        expect((mounted.host.widget as SizedBox).child, isNull);
        expect(
          binding.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
        expect(() => _bind(mounted), throwsA(isA<BoxObservationError>()));
      } finally {
        mounted.host.owner!.buildScope(
          mounted.host,
          () => mounted.host.update(original),
        );
        await tester.pump();
      }
      expect(
        _bind(mounted).allOriginalSuppliedSlots.single,
        same(original.child),
      );
    });
  });
  testWidgets('Scope cannot be shortened and stale unmount cannot read', (
    tester,
  ) async {
    await _mounted(tester, ('hidden', 'default'), false, (mounted) async {
      final binding = _bind(mounted);
      final foreign = binding.scope.foreignBoundaries.removeLast();
      try {
        expect(
          binding.readDeclaredAbsence,
          throwsA(isA<BoxObservationError>()),
        );
      } finally {
        binding.scope.foreignBoundaries.add(foreign);
      }
      binding.validateExistingCurrentBinding();
      await tester.pumpWidget(const SizedBox.shrink());
      expect(binding.readDeclaredAbsence, throwsA(isA<BoxObservationError>()));
    });
  });
}
