import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/internal/preview/flutter_card_view.dart';
import 'package:docs_core/internal/preview/flutter_stage.dart'
    show DocsStage, FlutterDocsSizeSpec;
import 'package:docs_core/shared/size_spec.dart' show docsSizeSpecFor;
import 'package:flutter/rendering.dart' show RenderDecoratedBox, RenderPadding;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_scene_units.dart';
import 'box_padding_source_bindings.dart';

const BoxObservationSourceSpec _cardSource =
    BoxObservationSourceSpec.wholeDocCard;

const BoxObservationSourceSpec _sizeSource =
    BoxObservationSourceSpec.docsSizePreview;

FlutterDocsSizeSpec _sizeSpec(String component) => FlutterDocsSizeSpec(
  component: component,
  spec: docsSizeSpecFor(component)!,
  attributes: {'component': component},
);

Future<Element> _mountSize(WidgetTester tester, Widget result) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      SingleChildScrollView(
        child: KeyedSubtree(key: key, child: result),
      ),
      theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentContext! as Element;
}

SceneBoxSourceBinding _bindSize(Element root, Widget result) =>
    bindDocumentationBoxSource(
      captureRoot: root,
      registryResult: result,
      source: _sizeSource,
    )!;

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

Future<Element> _mount(WidgetTester tester, Widget result) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    buildTestApp(
      KeyedSubtree(key: key, child: result),
      theme: coui.ThemeData.fromCore(coui.CoreThemePresets.light),
    ),
  );
  await tester.pumpAndSettle();
  return key.currentContext! as Element;
}

SceneBoxSourceBinding _bind(Element root, Widget result, {bool card = false}) =>
    bindDocumentationBoxSource(
      captureRoot: root,
      registryResult: result,
      source: card ? _cardSource : BoxObservationSourceSpec.docsStage,
    )!;

class _UnknownStageBuild extends DocsStage {
  const _UnknownStageBuild() : super(attributes: const {});

  @override
  Widget build(BuildContext context) => Container();
}

void main() {
  // These families come from the frozen current1100 manifest, not a success
  // target inferred from the historical SizeSpec18 cohort.
  for (final component in [
    'badge',
    'button',
    'checkbox',
    'radio-group',
    'select',
    'tabs',
    'text-area',
    'text-field',
    'toggle',
  ]) {
    testWidgets('SizeSpec $component binds preview and excludes table', (
      tester,
    ) async {
      final result = _sizeSpec(component);
      final root = await _mountSize(tester, result);
      final binding = _bindSize(root, result);
      final resultChildren = <Element>[];
      binding.registryResultElement.visitChildren(resultChildren.add);
      final column = resultChildren.single;
      final children = <Element>[];
      column.visitChildren(children.add);
      expect(binding.fieldUnitElement, same(children[0]));
      expect(binding.fieldUnitElement.widget, isA<DecoratedBox>());
      expect(binding.frameSource, same(binding.fieldUnitElement));
      expect(binding.paddingSource.widget, isA<Padding>());
      expect(binding.paddingSource.renderObject, isA<RenderPadding>());
      expect(binding.readerId, 'current-render-padding-v1');
      expect(binding.scope.producer, same(binding.registryResultElement));
      expect(
        BoxProducerScope.contains(binding.fieldUnitElement, children[1]),
        false,
      );
      final tablePadding = boxElements(
        children[1],
      ).where((element) => element.widget is Padding).toList();
      expect(tablePadding, isNotEmpty);
      expect(tablePadding, isNot(contains(binding.paddingSource)));
      binding.scope.requireOwned(binding.paddingSource);
    });
  }

  testWidgets('SizeSpec missing, duplicate and stale source children fail', (
    tester,
  ) async {
    final result = _sizeSpec('button');
    final root = await _mountSize(tester, result);
    final binding = _bindSize(root, result);
    final resultChildren = <Element>[];
    binding.registryResultElement.visitChildren(resultChildren.add);
    final column = resultChildren.single.widget as Column;
    final preview = column.children[0];
    final table = column.children[1];
    column.children.removeLast();
    expect(
      () => _bindSize(root, result),
      _error('DOCS_SIZE_SPEC_SOURCE_CHANGED'),
    );
    column.children.add(table);
    column.children[0] = table;
    expect(
      () => _bindSize(root, result),
      _error('DOCS_SIZE_SPEC_SOURCE_CHANGED'),
    );
    column.children[0] = preview;
    column.children[1] = preview;
    expect(
      () => _bindSize(root, result),
      _error('DOCS_SIZE_SPEC_SOURCE_CHANGED'),
    );
    column.children[1] = table;
  });

  testWidgets('SizeSpec route does not invoke its current builder again', (
    tester,
  ) async {
    var calls = 0;
    final result = _sizeSpec('button');
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        SingleChildScrollView(
          child: Builder(
            builder: (_) {
              calls++;
              return KeyedSubtree(key: key, child: result);
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = calls;
    _bindSize(key.currentContext! as Element, result);
    _bindSize(key.currentContext! as Element, result);
    expect(calls, before);
  });

  testWidgets('SizeSpec tuple cannot borrow the existing DocsStage unit', (
    tester,
  ) async {
    const result = DocsStage(attributes: {});
    final root = await _mount(tester, result);
    expect(
      () => _bindSize(root, result),
      _error('SOURCE_CONTRACT_PRODUCER_MISMATCH'),
    );
  });

  testWidgets('SizeSpec rejects border allocation on its actual bound frame', (
    tester,
  ) async {
    final result = _sizeSpec('button');
    final root = await _mountSize(tester, result);
    final binding = _bindSize(root, result);
    final frame = binding.frameSource!.renderObject! as RenderDecoratedBox;
    final original = frame.decoration;
    // A public renderer mutation is a guard fixture, not a new source scene
    // or product failure. Source identity stays fixed before this mutation.
    frame.decoration = (original as BoxDecoration).copyWith(
      border: Border.all(),
    );
    expect(
      () => _bindSize(root, result),
      _error('DOCS_SIZE_PREVIEW_ALLOCATION_CHANGED'),
    );
    frame.decoration = original;
    expect(_bindSize(root, result).frameSource, same(binding.frameSource));
  });

  for (final compact in [false, true]) {
    testWidgets('DocsStage compact=$compact binds its direct current box', (
      tester,
    ) async {
      final result = DocsStage(
        compact: compact,
        attributes: const {'component': 'Button'},
      );
      final root = await _mount(tester, result);
      final binding = _bind(root, result);
      expect(binding.registryResultElement.widget, same(result));
      expect(binding.fieldUnitElement, same(binding.registryResultElement));
      expect(binding.paddingSource.widget, isA<Container>());
      expect(binding.frameSource, same(binding.paddingSource));
      expect(binding.readerId, 'current-container-v1');
      binding.scope.requireOwned(binding.paddingSource);
      final observed = observeCurrentContainerPadding(
        owner: binding.paddingSource,
        scope: binding.scope,
      );
      expect(observed.owner, same(binding.paddingSource));
      expect(observed.producer.widget, same(result));
    });
  }

  for (final attributes in <Map<String, String>>[
    {'title': 'Plain'},
    {'title': 'Preview', 'component': 'OutlinedContainer'},
    {'title': 'Linked', 'href': '/components/button'},
  ]) {
    testWidgets('whole-card source branch $attributes preserves slot owners', (
      tester,
    ) async {
      final result = FlutterDocsCardView(
        attributes: attributes,
        rawBody: 'Body',
      );
      final root = await _mount(tester, result);
      final binding = _bind(root, result, card: true);
      expect(binding.registryResultElement.widget, same(result));
      expect(binding.fieldUnitElement.widget, isA<coui.Card>());
      expect(binding.paddingSource.widget, isA<coui.OutlinedContainer>());
      expect(binding.readerId, 'outlined-content-v1');
      expect(binding.scope.producer, same(binding.registryResultElement));
      binding.scope.requireOwned(binding.paddingSource);
      final observed = observeOutlinedContainerContentPadding(
        primitive: binding.paddingSource,
        declaringScope: binding.scope,
      );
      expect(
        BoxProducerScope.contains(binding.paddingSource, observed.owner),
        true,
      );
      expect(observed.producer, same(binding.registryResultElement));
      final card = binding.fieldUnitElement.widget as coui.Card;
      for (final slot in [
        ?card.child,
        ?card.media,
        ?card.header,
        ?card.body,
        ?card.footer,
        ?card.overlay,
      ]) {
        final element = requireOneBoxOwner(
          boxElements(binding.fieldUnitElement).where(
            (element) => identical(element.widget, slot),
          ),
          'the actual Card public content slot',
        );
        expect(
          () => binding.scope.requireOwned(element),
          _error('FOREIGN_SUPPLIED_CONTENT'),
        );
      }
    });
  }

  testWidgets('capture identity cannot be borrowed from a foreign descendant', (
    tester,
  ) async {
    const result = DocsStage(attributes: {});
    final root = await _mount(
      tester,
      const Padding(padding: EdgeInsets.zero, child: result),
    );
    expect(() => _bind(root, result), _error('MISMATCHED_CONSTRUCTION_RESULT'));
  });

  testWidgets(
    'unknown subclass constructor cannot borrow a known stage route',
    (
      tester,
    ) async {
      const result = _UnknownStageBuild();
      final root = await _mount(tester, result);
      expect(
        () => _bind(root, result),
        _error('SOURCE_CONTRACT_PRODUCER_MISMATCH'),
      );
    },
  );

  testWidgets(
    'missing, duplicate and stale cards.single identities fail closed',
    (
      tester,
    ) async {
      const result = FlutterDocsCardView(
        attributes: {'title': 'Card'},
        rawBody: '',
      );
      final root = await _mount(tester, result);
      final layout = boxElements(root)
          .map((element) => element.widget)
          .whereType<FlutterDocsCardsLayout>()
          .single;
      final original = layout.cards.single;
      layout.cards.add(const SizedBox());
      expect(
        () => _bind(root, result, card: true),
        _error('DOCS_CARD_CARDINALITY_CHANGED'),
      );
      layout.cards.clear();
      expect(
        () => _bind(root, result, card: true),
        _error('DOCS_CARD_CARDINALITY_CHANGED'),
      );
      layout.cards.add(const coui.Card(child: SizedBox()));
      expect(
        () => _bind(root, result, card: true),
        _error('DOCS_CARD_LAYOUT_CHANGED'),
      );
      layout.cards[0] = original;
    },
  );

  testWidgets('changed href branch cannot adopt a same-looking descendant', (
    tester,
  ) async {
    final attributes = {'title': 'Card'};
    final result = FlutterDocsCardView(attributes: attributes, rawBody: '');
    final root = await _mount(tester, result);
    attributes['href'] = '/changed-without-rebuild';
    expect(
      () => _bind(root, result, card: true),
      _error('DOCS_CARD_HREF_BRANCH_CHANGED'),
    );
  });

  testWidgets('source observation does not call a builder again', (
    tester,
  ) async {
    var calls = 0;
    const result = DocsStage(attributes: {});
    final key = GlobalKey();
    await tester.pumpWidget(
      buildTestApp(
        Builder(
          builder: (_) {
            calls++;
            return KeyedSubtree(key: key, child: result);
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final before = calls;
    _bind(key.currentContext! as Element, result);
    _bind(key.currentContext! as Element, result);
    expect(calls, before);
  });

  testWidgets(
    'wrong unit, unknown adapter and version cannot produce a value',
    (
      tester,
    ) async {
      const result = DocsStage(attributes: {});
      final root = await _mount(tester, result);
      expect(
        () => _bind(root, result, card: true),
        _error('SOURCE_CONTRACT_PRODUCER_MISMATCH'),
      );
      for (final source in [
        const BoxObservationSourceSpec(
          schemaVersion: 2,
          logicalUnitId: 'registry-scene-frame',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'docs-stage-current-container-v1',
          webAdapterId: 'matched-docs-stage-v1',
        ),
        const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'registry-scene-frame',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'unknown',
          webAdapterId: 'matched-docs-stage-v1',
        ),
      ]) {
        expect(
          () => bindDocumentationBoxSource(
            captureRoot: root,
            registryResult: result,
            source: source,
          ),
          throwsA(isA<BoxObservationError>()),
        );
      }
      expect(
        bindDocumentationBoxSource(
          captureRoot: root,
          registryResult: result,
          source: BoxObservationSourceSpec.outlined,
        ),
        isNull,
      );
    },
  );
}
