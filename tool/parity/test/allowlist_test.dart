import 'package:test/test.dart';

import '../src/baseline/allowlist.dart';
import '../src/baseline/parity_signal.dart';

void main() {
  group('Allowlist.parse', () {
    test('빈 파일과 entries 누락은 승인 0건', () {
      expect(Allowlist.parse('', origin: 'x').entries, isEmpty);
      expect(Allowlist.parse('other: 1', origin: 'x').entries, isEmpty);
      expect(Allowlist.parse('entries: []', origin: 'x').entries, isEmpty);
    });

    test('세 신호를 모두 파싱한다 — 픽셀 전용이 아니다', () {
      final allowlist = Allowlist.parse(
        '''
entries:
  - key: dialog-default
    signal: pixel
    fingerprint: aaa
    reason: r1
    expires: "2026-11-01"
  - key: dialog-default
    signal: property
    fingerprint: bbb
    reason: r2
    expires: "2026-11-01"
  - key: dialog-default
    signal: motion
    fingerprint: ccc
    reason: r3
    expires: "2026-11-01"
''',
        origin: 'x',
      );

      expect(allowlist.entries.map((entry) => entry.signal), <ParitySignal>[
        ParitySignal.pixel,
        ParitySignal.property,
        ParitySignal.motion,
      ]);
    });

    test('같은 (key, signal) 에 플랫폼별로 여러 지문을 등록할 수 있다', () {
      final allowlist = Allowlist.parse(
        '''
entries:
  - key: k
    signal: pixel
    fingerprint: flutter-fp
    reason: r
    expires: "2026-11-01"
  - key: k
    signal: pixel
    fingerprint: web-fp
    reason: r
    expires: "2026-11-01"
''',
        origin: 'x',
      );

      expect(allowlist.entriesFor('k', ParitySignal.pixel), hasLength(2));
      expect(allowlist.entriesFor('k', ParitySignal.property), isEmpty);
      expect(allowlist.entriesFor('other', ParitySignal.pixel), isEmpty);
    });

    test('expires 는 따옴표 유무와 무관하게 UTC 날짜로 정규화된다', () {
      final allowlist = Allowlist.parse(
        '''
entries:
  - key: k
    signal: pixel
    fingerprint: fp
    reason: r
    expires: 2026-11-01
''',
        origin: 'x',
      );

      expect(allowlist.entries.first.expires, DateTime.utc(2026, 11));
    });

    group('형식이 깨지면 조용히 넘기지 않고 던진다', () {
      // 깨진 항목을 건너뛰면 승인이 사라진 채로 게이트가 통과해버리고,
      // 그건 승인 누락보다 발견이 늦다.
      test('알 수 없는 signal', () {
        expect(
          () => Allowlist.parse(
            'entries:\n  - {key: k, signal: colour, fingerprint: f, '
            'reason: r, expires: "2026-11-01"}',
            origin: 'x',
          ),
          throwsFormatException,
        );
      });

      test('필수 필드 누락', () {
        expect(
          () => Allowlist.parse(
            'entries:\n  - {key: k, signal: pixel, reason: r, '
            'expires: "2026-11-01"}',
            origin: 'x',
          ),
          throwsFormatException,
        );
      });

      test('날짜가 아닌 expires', () {
        expect(
          () => Allowlist.parse(
            'entries:\n  - {key: k, signal: pixel, fingerprint: f, '
            'reason: r, expires: "언젠가"}',
            origin: 'x',
          ),
          throwsFormatException,
        );
      });

      test('entries 가 리스트가 아님', () {
        expect(
          () => Allowlist.parse('entries: 1', origin: 'x'),
          throwsFormatException,
        );
      });

      test('같은 (key, signal, fingerprint) 중복', () {
        expect(
          () => Allowlist.parse(
            '''
entries:
  - {key: k, signal: pixel, fingerprint: f, reason: r, expires: "2026-11-01"}
  - {key: k, signal: pixel, fingerprint: f, reason: r2, expires: "2027-01-01"}
''',
            origin: 'x',
          ),
          throwsFormatException,
        );
      });
    });
  });

  group('AllowlistEntry.isExpiredAt — 시간 주입', () {
    final entry = AllowlistEntry(
      key: 'k',
      signal: ParitySignal.pixel,
      fingerprint: 'fp',
      reason: 'r',
      expires: DateTime.utc(2026, 11),
    );

    test('만료일 당일까지 유효하다', () {
      expect(entry.isExpiredAt(DateTime.utc(2026, 10, 31)), isFalse);
      expect(entry.isExpiredAt(DateTime.utc(2026, 11)), isFalse);
      expect(entry.isExpiredAt(DateTime.utc(2026, 11, 1, 23, 59, 59)), isFalse);
    });

    test('다음 날부터 만료다', () {
      expect(entry.isExpiredAt(DateTime.utc(2026, 11, 2)), isTrue);
      expect(entry.isExpiredAt(DateTime.utc(2027)), isTrue);
    });

    test('로컬 시간대를 넘겨도 UTC 날짜로 판정한다', () {
      // 시각이 아니라 날짜만 비교하므로 러너 시간대에 따라 흔들리지 않는다.
      expect(
        entry.isExpiredAt(DateTime.utc(2026, 11, 1, 12).toLocal()),
        isFalse,
      );
    });
  });
}
