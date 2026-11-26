import 'package:docs_core/previews/flutter_registry.dart'
    show FlutterPreviewBuilder;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import 'box_padding_observation.dart';
import 'box_padding_preview_receipts.dart';

// Synthetic value contracts exercise receipt mechanics, not file attestation.
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

Matcher _error(String code) => throwsA(
  isA<BoxObservationError>().having((value) => value.code, 'code', code),
);

OfficialPreviewToken _authorize(
  OfficialPreviewReceipts manager,
  FlutterPreviewBuilder builder,
) => manager.authorize(
  entryKey: 'entry',
  component: 'button',
  variant: _authority().reference,
  builder: builder,
  sceneValueAuthority: _authority(),
);

ValidatedPreviewReceipt _mounted(
  OfficialPreviewReceipts manager,
  Element root, {
  String key = 'entry',
  String epoch = 'capture',
  SceneValueAuthority? authority,
}) => manager.requireMounted(
  captureRoot: root,
  entryKey: key,
  component: 'button',
  variant: _authority().reference,
  epoch: epoch,
  sceneValueAuthority: authority ?? _authority(),
);

void main() {
  test('capture and authorization do not invoke an official handle', () {
    var calls = 0;
    Widget builder(String? _) {
      calls++;
      return const SizedBox();
    }

    final manager = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    final token = _authorize(manager, builder);
    expect(calls, 0);
    final result = builder(_authority().reference); // The original real call.
    final keyed = KeyedSubtree(child: result);
    manager.record(token: token, keyedHandle: keyed, result: result);
    expect(calls, 1);
  });

  test(
    'changed or missing registry handle fails before another invocation',
    () {
      var calls = 0;
      Widget builder(String? _) {
        calls++;
        return const SizedBox();
      }

      final registry = <String, FlutterPreviewBuilder>{'button': builder};
      final manager = OfficialPreviewReceipts.capture(
        registry: registry,
        epoch: 'capture',
      );
      final token = _authorize(manager, builder);
      registry['button'] = (_) => const SizedBox();
      expect(
        () => _authorize(manager, builder),
        _error('OFFICIAL_PREVIEW_HANDLE_CHANGED'),
      );
      expect(
        () => manager.record(
          token: token,
          keyedHandle: const KeyedSubtree(child: SizedBox()),
          result: const SizedBox(),
        ),
        _error('OFFICIAL_PREVIEW_HANDLE_CHANGED'),
      );
      registry.clear();
      expect(
        () => _authorize(manager, builder),
        _error('OFFICIAL_PREVIEW_HANDLE_CHANGED'),
      );
      expect(calls, 0);
    },
  );

  test('mismatched args, malformed hashes and missing fields fail closed', () {
    Widget builder(String? _) => const SizedBox();
    final manager = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    expect(
      () => manager.authorize(
        entryKey: 'entry',
        component: 'button',
        variant: 'other',
        builder: builder,
        sceneValueAuthority: _authority(),
      ),
      _error('PREVIEW_RECEIPT_ARGUMENT_MISMATCH'),
    );
    expect(
      () => SceneValueAuthority.fromJson({
        ..._authority().toJson(),
        'documentSha256': 'bad',
      }),
      _error('INVALID_SCENE_VALUE_AUTHORITY'),
    );
    expect(
      () => SceneValueAuthority.fromJson({}),
      _error('INVALID_SCENE_VALUE_AUTHORITY'),
    );
  });

  test('tokens and keyed records are single-use and manager-local', () {
    Widget builder(String? _) => const SizedBox();
    final manager = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    final other = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    final token = _authorize(manager, builder);
    final result = builder(_authority().reference);
    final keyed = KeyedSubtree(child: result);
    expect(
      () => other.record(token: token, keyedHandle: keyed, result: result),
      _error('DUPLICATE_OR_FOREIGN_PREVIEW_RECORD'),
    );
    manager.record(token: token, keyedHandle: keyed, result: result);
    expect(
      () => manager.record(token: token, keyedHandle: keyed, result: result),
      _error('DUPLICATE_OR_FOREIGN_PREVIEW_RECORD'),
    );
    expect(
      () => manager.record(
        token: _authorize(manager, builder),
        keyedHandle: keyed,
        result: result,
      ),
      _error('DUPLICATE_OR_FOREIGN_PREVIEW_RECORD'),
    );
  });

  test('recording requires the result in that existing keyed child', () {
    Widget builder(String? _) => const SizedBox();
    final manager = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    expect(
      () => manager.record(
        token: _authorize(manager, builder),
        keyedHandle: const KeyedSubtree(child: Text('foreign')),
        result: const SizedBox(),
      ),
      _error('PREVIEW_RESULT_KEYED_CHILD_MISMATCH'),
    );
  });

  testWidgets('actual keyed identity wins over the last generated record', (
    tester,
  ) async {
    const sharedResult = SizedBox();
    var calls = 0;
    Widget builder(String? _) {
      calls++;
      return sharedResult;
    }

    final manager = OfficialPreviewReceipts.capture(
      registry: {'button': builder},
      epoch: 'capture',
    );
    final key = GlobalKey();
    KeyedSubtree construct() {
      final token = _authorize(manager, builder);
      final result = builder(_authority().reference);
      final keyed = KeyedSubtree(key: key, child: result);
      manager.record(token: token, keyedHandle: keyed, result: result);
      return keyed;
    }

    final first = construct();
    final second = construct(); // Generated last, but not mounted yet.
    await tester.pumpWidget(buildTestApp(first));
    final receipt = _mounted(manager, key.currentContext! as Element);
    expect(receipt.captureRoot.widget, same(first));
    expect(receipt.result, same(sharedResult));
    expect(calls, 2);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(receipt.requireCurrent, _error('STALE_PREVIEW_RECEIPT'));
    await tester.pumpWidget(buildTestApp(second));
    await tester.pumpAndSettle();
    expect(
      _mounted(manager, key.currentContext! as Element).captureRoot.widget,
      same(second),
    );
    expect(calls, 2);
  });

  testWidgets(
    'missing receipt, changed epoch, args and hash do not authorize',
    (tester) async {
      Widget builder(String? _) => const SizedBox();
      final registry = <String, FlutterPreviewBuilder>{'button': builder};
      final manager = OfficialPreviewReceipts.capture(
        registry: registry,
        epoch: 'capture',
      );
      final key = GlobalKey();
      final token = _authorize(manager, builder);
      final result = builder(_authority().reference);
      final keyed = KeyedSubtree(key: key, child: result);
      await tester.pumpWidget(buildTestApp(keyed));
      final root = key.currentContext! as Element;
      expect(
        () => _mounted(manager, root),
        _error('MISSING_MOUNTED_PREVIEW_RECEIPT'),
      );
      manager.record(token: token, keyedHandle: keyed, result: result);
      expect(
        () => _mounted(manager, root, key: 'other'),
        _error('PREVIEW_RECEIPT_AUTHORITY_CHANGED'),
      );
      expect(
        () => _mounted(manager, root, epoch: 'other'),
        _error('PREVIEW_RECEIPT_AUTHORITY_CHANGED'),
      );
      final changed = SceneValueAuthority.fromJson({
        ..._authority().toJson(),
        'manifestSha256': 'e'.padLeft(64, 'e'),
      });
      expect(
        () => _mounted(manager, root, authority: changed),
        _error('PREVIEW_RECEIPT_AUTHORITY_CHANGED'),
      );
      final receipt = _mounted(manager, root);
      registry['button'] = (_) => const SizedBox();
      expect(
        receipt.requireCurrent,
        _error('OFFICIAL_PREVIEW_HANDLE_CHANGED'),
      );
    },
  );
}
