import 'package:docs_core/internal/preview/flutter_stage.dart'
    show buildFlutterPlaygroundStage;
import 'package:flutter/rendering.dart' show RenderDecoratedBox;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../tool/parity/src/model/box_observation_source_spec.dart';
import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_playground_units.dart';
import 'box_padding_preview_receipts.dart';

const BoxObservationSourceSpec _source =
    BoxObservationSourceSpec.docsPlayground;

// Synthetic call-receipt mechanics; the official-registry witness is separate.
SceneValueAuthority _authority() => SceneValueAuthority(
  component: 'button',
  reference: 'docs-v2-${'a'.padLeft(32, 'a')}',
  tag: 'Playground',
  documentPath: 'fixture/button.md',
  documentSha256: 'a'.padLeft(64, 'a'),
  sourceClosureSha256: 'b'.padLeft(64, 'b'),
  manifestSha256: 'c'.padLeft(64, 'c'),
  sceneValueSha256: 'd'.padLeft(64, 'd'),
);

class _StageFixture extends StatelessWidget {
  const _StageFixture(this.child, {this.extraInset = false});
  final Widget child;
  final bool extraInset;
  @override
  Widget build(BuildContext context) => extraInset
      ? ConstrainedBox(
          constraints: const BoxConstraints(),
          child: DecoratedBox(
            decoration: const BoxDecoration(),
            child: Padding(
              padding: EdgeInsets.zero,
              child: Center(child: child),
            ),
          ),
        )
      : buildFlutterPlaygroundStage(context, child);
}

enum _ForeignRoute { constrained, decorated, center }

class _ForeignConstrainedBox extends ConstrainedBox {
  _ForeignConstrainedBox({required super.child})
    : super(constraints: const BoxConstraints());
}

class _ForeignDecoratedBox extends DecoratedBox {
  const _ForeignDecoratedBox({required super.child})
    : super(decoration: const BoxDecoration());
}

class _ForeignCenter extends Center {
  const _ForeignCenter({required super.child});
}

// The same public fields and child chain cannot authorize unknown subclasses.
class _ForeignStageFixture extends StatelessWidget {
  const _ForeignStageFixture(this.route);
  final _ForeignRoute route;

  @override
  Widget build(BuildContext context) {
    const child = Text('child');
    final center = route == _ForeignRoute.center
        ? const _ForeignCenter(child: child)
        : const Center(child: child);
    final frame = route == _ForeignRoute.decorated
        ? _ForeignDecoratedBox(child: center)
        : DecoratedBox(decoration: const BoxDecoration(), child: center);
    return route == _ForeignRoute.constrained
        ? _ForeignConstrainedBox(child: frame)
        : ConstrainedBox(constraints: const BoxConstraints(), child: frame);
  }
}

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having(
    (error) => error.code,
    'code',
    code,
  ),
);

Future<ValidatedPreviewReceipt> _mount(
  WidgetTester tester,
  Widget result,
) async {
  Widget builder(String? _) => result;
  final manager = OfficialPreviewReceipts.capture(
    registry: {'button': builder},
    epoch: 'capture',
  );
  final token = manager.authorize(
    entryKey: 'entry',
    component: 'button',
    variant: _authority().reference,
    builder: builder,
    sceneValueAuthority: _authority(),
  );
  final actual = builder(_authority().reference);
  final key = GlobalKey();
  final keyed = KeyedSubtree(key: key, child: actual);
  manager.record(token: token, keyedHandle: keyed, result: actual);
  await tester.pumpWidget(buildTestApp(keyed));
  await tester.pumpAndSettle();
  return manager.requireMounted(
    captureRoot: key.currentContext! as Element,
    entryKey: 'entry',
    component: 'button',
    variant: _authority().reference,
    epoch: 'capture',
    sceneValueAuthority: _authority(),
  );
}

void main() {
  testWidgets('helper returns source refs and excludes the real helper child', (
    tester,
  ) async {
    const child = Padding(padding: EdgeInsets.all(93), child: Text('child'));
    const result = _StageFixture(child);
    final receipt = await _mount(tester, result);
    final binding = bindPlaygroundBoxSource(
      captureRoot: receipt.captureRoot,
      registryResult: result,
      source: _source,
      validatedReceipt: receipt,
    );
    expect(binding.paddingSource.widget, isA<DecoratedBox>());
    expect(binding.fieldUnitElement, same(binding.frameSource));
    expect(binding.readerId, 'declared-no-own-padding-v1');
    final boundary = requireOneBoxOwner(
      boxElements(
        receipt.captureRoot,
      ).where((element) => identical(element.widget, child)),
      'actual helper child',
    );
    expect(
      () => binding.scope.requireOwned(boundary),
      _error('FOREIGN_SUPPLIED_CONTENT'),
    );
    expect(binding.scope.foreignBoundaries.single, same(boundary));
  });

  testWidgets(
    'even a zero inset inserted into the owned route is unsupported',
    (tester) async {
      const result = _StageFixture(Text('child'), extraInset: true);
      final receipt = await _mount(tester, result);
      expect(
        () => bindPlaygroundBoxSource(
          captureRoot: receipt.captureRoot,
          registryResult: result,
          source: _source,
          validatedReceipt: receipt,
        ),
        _error('PLAYGROUND_OWN_INSET_SOURCE_CHANGED'),
      );
    },
  );

  testWidgets('current border allocation is a fail-closed quantity premise', (
    tester,
  ) async {
    const result = _StageFixture(Text('child'));
    final receipt = await _mount(tester, result);
    final binding = bindPlaygroundBoxSource(
      captureRoot: receipt.captureRoot,
      registryResult: result,
      source: _source,
      validatedReceipt: receipt,
    );
    final render = binding.frameSource!.renderObject! as RenderDecoratedBox;
    final original = render.decoration;
    render.decoration = (original as BoxDecoration).copyWith(
      border: Border.all(),
    );
    expect(
      () => bindPlaygroundBoxSource(
        captureRoot: receipt.captureRoot,
        registryResult: result,
        source: _source,
        validatedReceipt: receipt,
      ),
      _error('PLAYGROUND_ALLOCATION_CHANGED'),
    );
    render.decoration = original;
  });

  testWidgets('wrong returned Widget and tuple cannot borrow a receipt', (
    tester,
  ) async {
    const result = _StageFixture(Text('child'));
    final receipt = await _mount(tester, result);
    expect(
      () => bindPlaygroundBoxSource(
        captureRoot: receipt.captureRoot,
        registryResult: const _StageFixture(Text('other')),
        source: _source,
        validatedReceipt: receipt,
      ),
      _error('PLAYGROUND_RECEIPT_ROOT_MISMATCH'),
    );
    expect(
      () => bindPlaygroundBoxSource(
        captureRoot: receipt.captureRoot,
        registryResult: result,
        source: BoxObservationSourceSpec.docsStage,
        validatedReceipt: receipt,
      ),
      _error('BOX_SOURCE_ADAPTER_UNIT_MISMATCH'),
    );
  });

  for (final route in _ForeignRoute.values) {
    testWidgets('unknown ${route.name} subclass cannot declare no own inset', (
      tester,
    ) async {
      final result = _ForeignStageFixture(route);
      final receipt = await _mount(tester, result);
      expect(
        () => bindPlaygroundBoxSource(
          captureRoot: receipt.captureRoot,
          registryResult: result,
          source: _source,
          validatedReceipt: receipt,
        ),
        _error(
          route == _ForeignRoute.center
              ? 'PLAYGROUND_OWN_INSET_SOURCE_CHANGED'
              : 'PLAYGROUND_SOURCE_CHANGED',
        ),
      );
    });
  }
}
