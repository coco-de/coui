import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:docs_core/previews/examples/flutter/avatar/avatar_default_example.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:flutter/widgets.dart'
    show
        BuildContext,
        Element,
        GlobalKey,
        KeyedSubtree,
        State,
        UniqueKey,
        Widget;
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_scope_extensions.dart';
import 'box_padding_surface_component_units.dart';

BoxObservationSourceSpec _source(String unit) => BoxObservationSourceSpec(
  schemaVersion: 1,
  logicalUnitId: '$unit-generated-frame',
  quantityId: BoxObservationSourceSpec.quantity,
  nativeAdapterId: '$unit-generated-frame-v1',
  webAdapterId: '$unit-generated-frame-v1',
);

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((error) => error.code, 'code', code),
);

Widget _app(Widget child, {bool dark = false}) => buildTestApp(
  child,
  theme: coui.ThemeData.fromCore(
    dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
  ),
);

void main() {
  const recipes = <({String component, String variant})>[
    (component: 'avatar', variant: 'default'),
    (component: 'avatar', variant: 'rounded'),
    (component: 'code-snippet', variant: 'default'),
    (component: 'mockup-code', variant: 'default'),
    (component: 'mockup-code', variant: 'tones'),
    (component: 'stat', variant: 'default'),
    (component: 'stat', variant: 'outlined'),
    (component: 'stat', variant: 'empty'),
    (component: 'validation-badge', variant: 'default'),
    (component: 'validation-badge', variant: 'pending'),
    (component: 'validation-badge', variant: 'invalid'),
    (component: 'validation-badge', variant: 'medium'),
  ];
  for (final recipe in recipes) {
    for (final dark in [false, true]) {
      testWidgets(
        '${recipe.component}/${recipe.variant} dark=$dark actual source refs',
        (tester) async {
          final result = kFlutterPreviewRegistry[recipe.component]!(
            recipe.variant == 'default' ? null : recipe.variant,
          );
          final capture = GlobalKey();
          await tester.pumpWidget(
            _app(
              KeyedSubtree(key: capture, child: result),
              dark: dark,
            ),
          );
          await tester.pumpAndSettle();
          final bound = bindDisplayBoxSource(
            captureRoot: capture.currentContext! as Element,
            registryResult: result,
            source: _source(recipe.component),
          )!;
          expect(bound.registryResultElement.widget, same(result));
          expect(bound.fieldUnitElement, isNot(same(bound.paddingSource)));
          expect(bound.paddingSource, same(bound.frameSource));
          expect(
            bound.readerId,
            recipe.component == 'validation-badge'
                ? 'current-container-v1'
                : 'outlined-content-v1',
          );
          expect(
            () => bound.scope.requireOwned(bound.paddingSource),
            returnsNormally,
          );
          // A source reference is not a numeric read or cross-platform
          // eligibility assertion. MockupCode's Web split remains pending.
          expect(bound.authority, isNotEmpty);
          expect(bound.scope.producer, same(bound.registryResultElement));
        },
      );
    }
  }

  testWidgets('a same-class unmounted result cannot replace the actual input', (
    tester,
  ) async {
    final actual = AvatarDefaultExample(key: UniqueKey());
    final other = AvatarDefaultExample(key: UniqueKey());
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(KeyedSubtree(key: capture, child: actual)),
    );
    expect(
      () => bindDisplayBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: other,
        source: _source('avatar'),
      ),
      _error('MISMATCHED_CONSTRUCTION_RESULT'),
    );
  });

  for (final variant in ['placeholder', 'diameter']) {
    testWidgets('unregistered avatar/$variant is not a source fallback', (
      tester,
    ) async {
      final result = kFlutterPreviewRegistry['avatar']!(variant);
      final capture = GlobalKey();
      await tester.pumpWidget(
        _app(KeyedSubtree(key: capture, child: result)),
      );
      await tester.pumpAndSettle();
      expect(
        () => bindDisplayBoxSource(
          captureRoot: capture.currentContext! as Element,
          registryResult: result,
          source: _source('avatar'),
        ),
        _error('UNREGISTERED_DISPLAY_CONSTRUCTION'),
      );
    });
  }

  testWidgets('unknown subclass returning foreign chrome stays unsupported', (
    tester,
  ) async {
    const result = _ForeignAvatarExample();
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(KeyedSubtree(key: capture, child: result)),
    );
    expect(
      () => bindDisplayBoxSource(
        captureRoot: capture.currentContext! as Element,
        registryResult: result,
        source: _source('avatar'),
      ),
      _error('UNREGISTERED_DISPLAY_CONSTRUCTION'),
    );
  });

  testWidgets('tuple/version/quantity guards precede any owner fallback', (
    tester,
  ) async {
    const result = AvatarDefaultExample();
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(KeyedSubtree(key: capture, child: result)),
    );
    final root = capture.currentContext! as Element;
    for (final entry in <({BoxObservationSourceSpec source, String code})>[
      (
        source: const BoxObservationSourceSpec(
          schemaVersion: 99,
          logicalUnitId: 'avatar-generated-frame',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'avatar-generated-frame-v1',
          webAdapterId: 'avatar-generated-frame-v1',
        ),
        code: 'UNSUPPORTED_BOX_SOURCE_VERSION',
      ),
      (
        source: const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'avatar-generated-frame',
          quantityId: 'unknown',
          nativeAdapterId: 'avatar-generated-frame-v1',
          webAdapterId: 'avatar-generated-frame-v1',
        ),
        code: 'UNSUPPORTED_BOX_QUANTITY',
      ),
      (
        source: const BoxObservationSourceSpec(
          schemaVersion: 1,
          logicalUnitId: 'avatar-generated-frame',
          quantityId: BoxObservationSourceSpec.quantity,
          nativeAdapterId: 'avatar-generated-frame-v1',
          webAdapterId: 'stat-generated-frame-v1',
        ),
        code: 'BOX_SOURCE_ADAPTER_UNIT_MISMATCH',
      ),
      (source: _source('stat'), code: 'UNREGISTERED_DISPLAY_CONSTRUCTION'),
    ]) {
      expect(
        () => bindDisplayBoxSource(
          captureRoot: root,
          registryResult: result,
          source: entry.source,
        ),
        _error(entry.code),
      );
    }
    expect(
      bindDisplayBoxSource(
        captureRoot: root,
        registryResult: result,
        source: _source('unknown'),
      ),
      isNull,
    );
  });

  testWidgets('CodeSnippet action chrome cannot become its own frame', (
    tester,
  ) async {
    const foreign = coui.OutlinedContainer(child: coui.Text('foreign'));
    const result = coui.CodeSnippet(
      code: 'void main() {}',
      mode: 'dart',
      actions: [foreign],
      showCopyButton: false,
    );
    final capture = GlobalKey();
    await tester.pumpWidget(
      _app(KeyedSubtree(key: capture, child: result)),
    );
    await tester.pumpAndSettle();
    final producer = requireOneBoxOwner(
      boxElements(capture.currentContext! as Element).where(
        (element) => identical(element.widget, result),
      ),
      'the actual public CodeSnippet input',
    );
    final declaration = describeAdditionalBoxProducerSource(producer)!;
    final scope = BoxProducerScope(
      producer: producer,
      suppliedSlots: declaration.supplied,
    );
    expect(declaration.supplied, contains(same(foreign)));
    final action = requireOneBoxOwner(
      boxElements(producer).where(
        (element) => identical(element.widget, foreign),
      ),
      'the actual supplied action',
    );
    expect(
      () => scope.requireOwned(action),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
    expect(
      () => scope.requireOwned(declaration.outlinedFrame!.primitive),
      returnsNormally,
    );
    expect(declaration.outlinedFrame!.primitive, isNot(same(action)));
  });
}

class _ForeignAvatarExample extends AvatarDefaultExample {
  const _ForeignAvatarExample();

  @override
  State<AvatarDefaultExample> createState() => _ForeignAvatarState();
}

class _ForeignAvatarState extends State<AvatarDefaultExample> {
  @override
  Widget build(BuildContext context) => const coui.OutlinedContainer(
    child: coui.Text('caller chrome, not an Avatar frame'),
  );
}
