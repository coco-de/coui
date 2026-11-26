import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        EdgeInsets,
        Element,
        GlobalKey,
        KeyedSubtree,
        Padding,
        Row,
        SizedBox,
        ValueKey,
        ValueListenableBuilder,
        ValueNotifier,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_inline_host_units.dart';
import 'box_padding_observation.dart';

BoxObservationSourceSpec _source(String component) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: '$component-generated-inline-host',
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$component-generated-inline-host-v1',
  webAdapterId: '$component-generated-inline-host-v1',
);

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

void main() {
  const recipes = <String, List<String>>{
    'label': ['default', 'required', 'with-icon', 'disabled'],
    'link': ['default', 'muted', 'underline', 'external', 'icons'],
  };
  for (final entry in recipes.entries) {
    for (final variant in entry.value) {
      for (final dark in [false, true]) {
        testWidgets('${entry.key}/$variant dark=$dark actual source host', (
          tester,
        ) async {
          // The official builder is invoked once; the binder only reads the
          // actual mounted returned Widget and never calls it again.
          final result = kFlutterPreviewRegistry[entry.key]!(
            variant == 'default' ? null : variant,
          );
          final key = GlobalKey();
          await tester.pumpWidget(
            buildTestApp(
              KeyedSubtree(key: key, child: result),
              theme: coui.ThemeData.fromCore(
                dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
              ),
            ),
          );
          await tester.pumpAndSettle();
          final binding = bindInlineHostBoxSource(
            captureRoot: key.currentContext! as Element,
            registryResult: result,
            source: _source(entry.key),
          )!;
          expect(binding.registryResultElement.widget, same(result));
          expect(binding.fieldUnitElement, same(binding.frameSource));
          expect(binding.paddingSource, same(binding.frameSource));
          expect(binding.readerId, 'inline-host-declared-absence-v1');
          final observed = binding.readDeclaredAbsence();
          expect(observed.quantity, PaddingQuantityKind.declaredNoOwnPadding);
          expect(observed.paddingElement, isNull);
          expect(observed.owner, same(binding.frameSource));
          expect(observed.frameOwner, same(binding.frameSource));
          expect(observed.value, EdgeInsets.zero);
          expect(tester.takeException(), isNull);
        });
      }
    }
  }

  for (final label in [true, false]) {
    testWidgets(
      'foreign Padding cannot donate ${label ? 'Label' : 'Link'} inset',
      (
        tester,
      ) async {
        final foreign = GlobalKey();
        final payload = Padding(
          key: foreign,
          padding: const EdgeInsets.all(31),
          child: const SizedBox(width: 8, height: 8),
        );
        final result = label
            ? coui.Label(text: 'own', icon: payload)
            : coui.Link(href: '#', child: payload);
        final key = GlobalKey();
        await tester.pumpWidget(
          buildTestApp(KeyedSubtree(key: key, child: result)),
        );
        await tester.pumpAndSettle();
        final binding = bindInlineHostBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _source(label ? 'label' : 'link'),
        )!;
        expect(
          () => binding.scope.requireOwned(foreign.currentContext! as Element),
          _error('FOREIGN_SUPPLIED_CONTENT'),
        );
        expect(binding.frameSource, isNot(same(foreign.currentContext)));
        expect(binding.readDeclaredAbsence().paddingElement, isNull);
      },
    );
  }

  for (final result in <Widget>[
    const _UnknownLabel(),
    const _UnknownLink(),
    const _ChangedLabel(),
    const _ChangedLink(),
    const Row(),
  ]) {
    testWidgets('unknown concrete construction ${result.runtimeType} rejects', (
      tester,
    ) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        buildTestApp(KeyedSubtree(key: key, child: result)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindInlineHostBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: result,
          source: _source('label'),
        ),
        _error('UNREGISTERED_COMPONENT_CONSTRUCTION'),
      );
    });
  }

  testWidgets('unsupported command branch never invokes callback', (
    tester,
  ) async {
    var calls = 0;
    final result = coui.Link(href: '#', onPressed: () => calls++);
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    expect(
      () => bindInlineHostBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _source('link'),
      ),
      _error('INLINE_HOST_SOURCE_CHANGED'),
    );
    expect(calls, 0);
  });

  testWidgets('duplicate supplied Widget identity is not de-duplicated', (
    tester,
  ) async {
    const payload = SizedBox(width: 7, height: 7);
    const result = coui.Link(href: '#', leading: payload, child: payload);
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    await tester.pumpAndSettle();
    expect(
      () => bindInlineHostBoxSource(
        captureRoot: key.currentContext! as Element,
        registryResult: result,
        source: _source('link'),
      ),
      _error('DUPLICATE_SUPPLIED_SLOT_IDENTITY'),
    );
  });

  for (final label in [true, false]) {
    testWidgets(
      'same-mounted ${label ? 'Label' : 'Link'} update invalidates old witness',
      (
        tester,
      ) async {
        final key = GlobalKey();
        const producerKey = ValueKey('same-inline-producer');
        final before = label
            ? const coui.Label(key: producerKey, text: 'before')
            : const coui.Link(key: producerKey, href: '#before');
        final after = label
            ? const coui.Label(key: producerKey, text: 'after')
            : const coui.Link(key: producerKey, href: '#after');
        final current = ValueNotifier<Widget>(before);
        addTearDown(current.dispose);
        await tester.pumpWidget(
          buildTestApp(
            ValueListenableBuilder<Widget>(
              valueListenable: current,
              builder: (_, value, _) => KeyedSubtree(key: key, child: value),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final old = bindInlineHostBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: before,
          source: _source(label ? 'label' : 'link'),
        )!;
        final originalElement = old.registryResultElement;
        final originalFrame = old.frameSource;
        current.value = after;
        await tester.pumpAndSettle();
        expect(originalElement.mounted, true);
        expect(originalFrame.mounted, true);
        expect(originalElement.widget, same(after));
        expect(old.readDeclaredAbsence, _error('INLINE_HOST_SOURCE_CHANGED'));
        final fresh = bindInlineHostBoxSource(
          captureRoot: key.currentContext! as Element,
          registryResult: after,
          source: _source(label ? 'label' : 'link'),
        )!;
        expect(fresh.registryResultElement, same(originalElement));
        expect(fresh.frameSource, same(originalFrame));
        expect(fresh.readDeclaredAbsence().owner, same(originalFrame));
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('missing/mismatched result and source tuple fail closed', (
    tester,
  ) async {
    const result = coui.Label(text: 'mounted');
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(KeyedSubtree(key: key, child: result)),
    );
    final capture = key.currentContext! as Element;
    expect(
      () => bindInlineHostBoxSource(
        captureRoot: capture,
        registryResult: const coui.Label(text: 'unmounted'),
        source: _source('label'),
      ),
      _error('INLINE_HOST_SOURCE_CHANGED'),
    );
    expect(
      () => bindInlineHostBoxSource(
        captureRoot: capture,
        registryResult: result,
        source: const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'label-generated-inline-host',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'link-generated-inline-host-v1',
          webAdapterId: 'label-generated-inline-host-v1',
        ),
      ),
      _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
    );
    final binding = bindInlineHostBoxSource(
      captureRoot: capture,
      registryResult: result,
      source: _source('label'),
    )!;
    await tester.pumpWidget(const SizedBox());
    expect(binding.readDeclaredAbsence, _error('INLINE_HOST_SOURCE_CHANGED'));
  });
}

class _UnknownLabel extends coui.Label {
  const _UnknownLabel() : super(text: 'same-looking');
}

class _UnknownLink extends coui.Link {
  const _UnknownLink() : super(href: '#');
}

class _ChangedLabel extends coui.Label {
  const _ChangedLabel() : super(text: 'changed');

  @override
  Widget build(coui.BuildContext context) => Padding(
    padding: const EdgeInsets.all(9),
    child: super.build(context),
  );
}

class _ChangedLink extends coui.Link {
  const _ChangedLink() : super(href: '#');
}
