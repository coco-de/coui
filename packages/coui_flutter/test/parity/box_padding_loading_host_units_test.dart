import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_loading_host_units.dart';
import 'box_padding_observation.dart';

const _kPump = Duration(milliseconds: 40);
const double _kCallerSize = 37;
const double _kForeignInset = 11;
Matcher _changed() => throwsA(isA<BoxObservationError>());

Future<LoadingHostBoxSourceBinding> _mount(
  WidgetTester tester,
  Widget result, {
  bool dark = false,
}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      KeyedSubtree(key: key, child: result),
      theme: coui.ThemeData.fromCore(
        dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
      ),
    ),
  );
  await tester.pump(_kPump);
  return bindLoadingHostBoxSource(
    captureRoot: key.currentContext! as Element,
    registryResult: result,
    source: BoxObservationSourceSpec.loadingSizeHost,
  )!;
}

void main() {
  for (final recipe in ['default', 'dots', 'bar', 'pulse']) {
    for (final dark in [false, true]) {
      testWidgets('$recipe dark=$dark actual registry sizing host', (
        tester,
      ) async {
        final result = kFlutterPreviewRegistry['loading']!(
          recipe == 'default' ? null : recipe,
        );
        final binding = await _mount(tester, result, dark: dark);
        final before = binding.frameSource;
        final observed = binding.readDeclaredAbsence();
        expect(binding.registryResultElement.widget, same(result));
        expect(binding.scope.producer, same(binding.registryResultElement));
        expect(binding.fieldUnitElement, same(before));
        expect(binding.paddingSource, same(before));
        expect(observed.owner, same(before));
        expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
        expect(observed.paddingElement, isNull);
        expect(observed.value, EdgeInsets.zero);
        await tester.pump(_kPump);
        expect(binding.readDeclaredAbsence().owner, same(before));
        expect(tester.takeException(), isNull);
      });
    }
  }
  for (final variant in coui.CoreLoadingVariant.values) {
    testWidgets(
      '$variant direct public source ignores dimensions and animated paint',
      (tester) async {
        final result = coui.Loading(
          variant: variant,
          loadingStyle: const coui.CoreLoadingStyle(size: _kCallerSize),
        );
        final binding = await _mount(tester, result);
        final frame = binding.frameSource;
        await tester.pump(const Duration(milliseconds: 170));
        expect(binding.readDeclaredAbsence().owner, same(frame));
        expect(binding.frameSource.widget, isA<SizedBox>());
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'same mounted producer replacement rejects old binding '
    'and fresh bind succeeds',
    (tester) async {
      const original = coui.Loading(
        loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
      );
      final value = ValueNotifier<Widget>(original);
      final capture = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(
          ValueListenableBuilder<Widget>(
            valueListenable: value,
            builder: (context, current, child) =>
                KeyedSubtree(key: capture, child: current),
          ),
        ),
      );
      await tester.pump(_kPump);
      final root = capture.currentContext! as Element;
      final old = bindLoadingHostBoxSource(
        captureRoot: root,
        registryResult: original,
        source: BoxObservationSourceSpec.loadingSizeHost,
      )!;
      value.value = const coui.Loading(variant: coui.CoreLoadingVariant.bar);
      await tester.pump(_kPump);
      expect(old.readDeclaredAbsence, _changed());
      final fresh = bindLoadingHostBoxSource(
        captureRoot: root,
        registryResult: value.value,
        source: BoxObservationSourceSpec.loadingSizeHost,
      )!;
      expect(fresh.registryResultElement, same(old.registryResultElement));
      expect(fresh.frameSource, same(old.frameSource));
      expect(fresh.readDeclaredAbsence().owner, same(fresh.frameSource));
      value.dispose();
    },
  );
  testWidgets('theme rebuild permits current frame Widget replacement', (
    tester,
  ) async {
    final theme = ValueNotifier<coui.ThemeData>(
      coui.ThemeData.fromCore(coui.CoreThemePresets.light),
    );
    const result = coui.Loading(
      loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      ValueListenableBuilder<coui.ThemeData>(
        valueListenable: theme,
        builder: (context, value, child) => buildTestApp(
          KeyedSubtree(key: capture, child: result),
          theme: value,
        ),
      ),
    );
    await tester.pump(_kPump);
    final binding = bindLoadingHostBoxSource(
      captureRoot: capture.currentContext! as Element,
      registryResult: result,
      source: BoxObservationSourceSpec.loadingSizeHost,
    )!;
    final frameWidget = binding.frameSource.widget;
    theme.value = coui.ThemeData.fromCore(coui.CoreThemePresets.dark);
    await tester.pump(_kPump);
    expect(binding.frameSource.widget, isNot(same(frameWidget)));
    expect(binding.readDeclaredAbsence().owner, same(binding.frameSource));
    theme.dispose();
  });
  for (final result in <Widget>[
    const _ForeignLoading(),
    const _ForeignSizedBox(),
    const Padding(
      padding: EdgeInsets.all(_kForeignInset),
      child: coui.Loading(),
    ),
    const SizedBox(child: coui.Loading()),
    const Column(children: [coui.Loading(), coui.Loading()]),
  ]) {
    testWidgets(
      '${result.runtimeType} unknown subclass/wrapper/collection rejected',
      (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(KeyedSubtree(key: key, child: result)),
        );
        await tester.pump(_kPump);
        expect(
          () => bindLoadingHostBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: BoxObservationSourceSpec.loadingSizeHost,
          ),
          _changed(),
        );
      },
    );
  }
  testWidgets('wrong registry Widget identity rejected', (tester) async {
    const actual = coui.Loading(
      loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
    );
    final binding = await _mount(tester, actual);
    expect(
      () => bindLoadingHostBoxSource(
        captureRoot: binding.registryResultElement,
        registryResult: const coui.Loading(),
        source: BoxObservationSourceSpec.loadingSizeHost,
      ),
      _changed(),
    );
  });
  testWidgets('duplicate raw registry object cannot grant parent absence', (
    tester,
  ) async {
    const loading = coui.Loading(
      loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
    );
    const result = Column(children: [loading, loading]);
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pump(_kPump);
    expect(
      () => bindLoadingHostBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: BoxObservationSourceSpec.loadingSizeHost,
      ),
      _changed(),
    );
  });
  for (final field in [
    'schemaVersion',
    'quantityId',
    'nativeAdapterId',
    'webAdapterId',
  ]) {
    testWidgets('invalid $field fails closed', (tester) async {
      const result = coui.Loading(
        loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
      );
      final binding = await _mount(tester, result);
      final raw = BoxObservationSourceSpec.loadingSizeHost.toJson();
      raw[field] = field == 'schemaVersion' ? 99 : 'unknown';
      final source = BoxObservationSourceSpec.fromJson(raw);
      expect(
        () => bindLoadingHostBoxSource(
          captureRoot: binding.registryResultElement,
          registryResult: result,
          source: source,
        ),
        _changed(),
      );
    });
  }
  testWidgets('unrelated unit declines without generic absence', (
    tester,
  ) async {
    const result = coui.Loading(
      loadingStyle: coui.CoreLoadingStyle(size: _kCallerSize),
    );
    final binding = await _mount(tester, result);
    expect(
      bindLoadingHostBoxSource(
        captureRoot: binding.registryResultElement,
        registryResult: result,
        source: BoxObservationSourceSpec.stepsSequenceHost,
      ),
      isNull,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    expect(binding.readDeclaredAbsence, _changed());
  });
}

class _ForeignLoading extends coui.Loading {
  const _ForeignLoading();
  @override
  Widget build(BuildContext context) =>
      const Padding(padding: EdgeInsets.all(_kForeignInset), child: SizedBox());
}

class _ForeignSizedBox extends SizedBox {
  const _ForeignSizedBox();
}
