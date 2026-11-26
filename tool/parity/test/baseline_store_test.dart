import 'dart:io';

import 'package:test/test.dart';

import '../src/baseline/allowlist.dart';
import '../src/baseline/baseline_store.dart';
import '../src/baseline/parity_platform.dart';
import '../src/baseline/parity_signal.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('coui_parity_baseline_');
    Directory(
      '${root.path}/${BaselineStore.baselineDirName}',
    ).createSync(recursive: true);
  });

  tearDown(() {
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  });

  /// baseline 파일을 심고 그 지문을 돌려준다.
  String seedBaseline(
    String key,
    ParityPlatform platform,
    ParitySignal signal,
    String contents,
  ) {
    File(
      '${root.path}/${BaselineStore.baselineDirName}/'
      '$key.${platform.wireName}.${signal.fileExtension}',
    ).writeAsStringSync(contents);

    return BaselineStore.fingerprintOfString(contents);
  }

  BaselineStore storeWith(String allowlistYaml) => BaselineStore(
    root: root,
    allowlist: Allowlist.parse(allowlistYaml, origin: 'test'),
  );

  final now = DateTime.utc(2026, 8);

  group('baseline 부재', () {
    test('첫 캡처는 regression 을 건너뛰고 parity 만 수행한다', () {
      final verdict = storeWith('entries: []').evaluate(
        key: 'dialog-default',
        platform: ParityPlatform.flutter,
        signal: ParitySignal.property,
        capturedFingerprint: 'whatever',
        now: now,
      );

      expect(verdict.outcome, BaselineOutcome.firstCapture);
      expect(verdict.outcome.skipsRegression, isTrue);
      expect(verdict.isFailure, isFalse);
    });

    test('플랫폼·신호별로 따로 판정한다', () {
      seedBaseline(
        'k',
        ParityPlatform.flutter,
        ParitySignal.pixel,
        'png-bytes',
      );
      final store = storeWith('entries: []');

      expect(
        store.hasBaseline(
          key: 'k',
          platform: ParityPlatform.flutter,
          signal: ParitySignal.pixel,
        ),
        isTrue,
      );
      // 같은 키라도 다른 플랫폼·다른 신호의 baseline 은 아직 없다.
      expect(
        store.hasBaseline(
          key: 'k',
          platform: ParityPlatform.web,
          signal: ParitySignal.pixel,
        ),
        isFalse,
      );
      expect(
        store.hasBaseline(
          key: 'k',
          platform: ParityPlatform.flutter,
          signal: ParitySignal.property,
        ),
        isFalse,
      );
    });
  });

  test('지문이 같으면 통과', () {
    final fingerprint = seedBaseline(
      'k',
      ParityPlatform.flutter,
      ParitySignal.property,
      '{"color":"#fff"}',
    );

    final verdict = storeWith('entries: []').evaluate(
      key: 'k',
      platform: ParityPlatform.flutter,
      signal: ParitySignal.property,
      capturedFingerprint: fingerprint,
      now: now,
    );

    expect(verdict.outcome, BaselineOutcome.match);
    expect(verdict.isFailure, isFalse);
  });

  test('승인 없는 변경은 회귀로 실패한다', () {
    seedBaseline('k', ParityPlatform.flutter, ParitySignal.property, 'old');

    final verdict = storeWith('entries: []').evaluate(
      key: 'k',
      platform: ParityPlatform.flutter,
      signal: ParitySignal.property,
      capturedFingerprint: BaselineStore.fingerprintOfString('new'),
      now: now,
    );

    expect(verdict.outcome, BaselineOutcome.regression);
    expect(verdict.isFailure, isTrue);
  });

  group('allowlist 승인', () {
    late String changed;

    setUp(() {
      seedBaseline('k', ParityPlatform.flutter, ParitySignal.property, 'old');
      changed = BaselineStore.fingerprintOfString('new');
    });

    String yamlApproving(String fingerprint, String expires) =>
        '''
entries:
  - key: k
    signal: property
    fingerprint: $fingerprint
    reason: "의도적 토큰 상향 (#3622)"
    expires: "$expires"
''';

    test('유효한 승인은 통과하고 사유를 싣는다', () {
      final verdict = storeWith(yamlApproving(changed, '2026-11-01')).evaluate(
        key: 'k',
        platform: ParityPlatform.flutter,
        signal: ParitySignal.property,
        capturedFingerprint: changed,
        now: now,
      );

      expect(verdict.outcome, BaselineOutcome.approvedChange);
      expect(verdict.isFailure, isFalse);
      expect(verdict.reason, contains('의도적 토큰 상향'));
    });

    test('만료된 승인은 실패로 전환되고 사유에 "만료됨" 이 뜬다', () {
      final verdict = storeWith(yamlApproving(changed, '2026-07-31')).evaluate(
        key: 'k',
        platform: ParityPlatform.flutter,
        signal: ParitySignal.property,
        capturedFingerprint: changed,
        // 만료 다음 날 — 벽시계가 아니라 주입된 시각으로 판정한다.
        now: DateTime.utc(2026, 8),
      );

      expect(verdict.outcome, BaselineOutcome.allowlistExpired);
      expect(verdict.isFailure, isTrue);
      expect(verdict.reason, contains('만료됨'));
    });

    test('만료 당일에는 아직 유효하다', () {
      final verdict = storeWith(yamlApproving(changed, '2026-08-01')).evaluate(
        key: 'k',
        platform: ParityPlatform.flutter,
        signal: ParitySignal.property,
        capturedFingerprint: changed,
        now: DateTime.utc(2026, 8, 1, 23, 59),
      );

      expect(verdict.outcome, BaselineOutcome.approvedChange);
    });

    test('등록된 지문과 다른 새 변경은 실패한다', () {
      // 승인은 "이 키를 앞으로 무시하라" 가 아니라 "정확히 이 결과물을 승인한다".
      final verdict = storeWith(yamlApproving(changed, '2026-11-01')).evaluate(
        key: 'k',
        platform: ParityPlatform.flutter,
        signal: ParitySignal.property,
        capturedFingerprint: BaselineStore.fingerprintOfString('yet another'),
        now: now,
      );

      expect(verdict.outcome, BaselineOutcome.allowlistMismatch);
      expect(verdict.isFailure, isTrue);
    });

    test('다른 신호에 걸린 승인은 이 신호를 통과시키지 않는다', () {
      final verdict =
          storeWith('''
entries:
  - key: k
    signal: pixel
    fingerprint: $changed
    reason: r
    expires: "2026-11-01"
''').evaluate(
            key: 'k',
            platform: ParityPlatform.flutter,
            signal: ParitySignal.property,
            capturedFingerprint: changed,
            now: now,
          );

      expect(verdict.outcome, BaselineOutcome.regression);
    });
  });

  group('지문', () {
    test('같은 내용이면 같고 다르면 다르다', () {
      expect(
        BaselineStore.fingerprintOfString('a'),
        BaselineStore.fingerprintOfString('a'),
      );
      expect(
        BaselineStore.fingerprintOfString('a'),
        isNot(BaselineStore.fingerprintOfString('b')),
      );
    });

    test('디스크의 baseline 지문이 같은 함수로 계산된다', () {
      final seeded = seedBaseline(
        'k',
        ParityPlatform.web,
        ParitySignal.motion,
        'samples',
      );

      expect(
        storeWith('entries: []').baselineFingerprint(
          key: 'k',
          platform: ParityPlatform.web,
          signal: ParitySignal.motion,
        ),
        seeded,
      );
    });
  });

  test('allowlist.yaml 이 없으면 승인 0건으로 엄격 판정한다', () {
    seedBaseline('k', ParityPlatform.flutter, ParitySignal.property, 'old');
    final store = BaselineStore.at(root.path);

    expect(store.allowlist.entries, isEmpty);
    expect(
      store
          .evaluate(
            key: 'k',
            platform: ParityPlatform.flutter,
            signal: ParitySignal.property,
            capturedFingerprint: BaselineStore.fingerprintOfString('new'),
            now: now,
          )
          .outcome,
      BaselineOutcome.regression,
    );
  });
}
