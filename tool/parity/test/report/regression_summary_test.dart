// RegressionSummary 렌더러 — 컴포넌트별 비주얼 회귀 리포트 마크다운의
// 형태(영향 범위 표 · 회귀 상세 · 검증 표)와 정직성(비교 0건을 초록으로
// 위장하지 않음)을 고정한다.
import 'package:test/test.dart';

import '../../src/baseline/parity_platform.dart';
import '../../src/diff/pixel_diff.dart';
import '../../src/report/regression_summary.dart';

PixelDiffResult _failingDiff() => const PixelDiffResult(
  mode: .regression,
  totalPixels: 836964,
  diffPixelCount: 20622,
  diffImageBytes: null,
  width: 1041,
  height: 804,
  maxChannelDelta: 74,
  topColorTransitions: [
    ColorTransition(fromRgb: 0x2eb8a1, toRgb: 0x207e6f, count: 12400),
  ],
);

PixelDiffResult _passingDiff() => const PixelDiffResult(
  mode: .regression,
  totalPixels: 3200,
  diffPixelCount: 0,
  diffImageBytes: null,
  width: 80,
  height: 40,
  maxChannelDelta: 2,
);

RegressionCell _cell({
  required String key,
  required String component,
  required ParityPlatform platform,
  required RegressionCellStatus status,
  PixelDiffResult? diff,
  String? diffArtifactPath,
  String? allowlistHint,
}) => RegressionCell(
  key: key,
  component: component,
  platform: platform,
  status: status,
  diff: diff,
  diffArtifactPath: diffArtifactPath,
  allowlistHint: allowlistHint,
);

void main() {
  group('RegressionSummary.toMarkdown — mixed statuses', () {
    late String markdown;

    setUp(() {
      markdown = RegressionSummary(
        cells: [
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .flutter,
            status: .passed,
            diff: _passingDiff(),
          ),
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .web,
            status: .failed,
            diff: _failingDiff(),
            diffArtifactPath:
                'button-primary-light-defaultStyle.root'
                '.web-regression.diff.png',
            allowlistHint:
                '- key: button-primary-light-defaultStyle\n'
                '  signal: pixel\n'
                '  fingerprint: abc123\n'
                '  reason: <왜 이 변경을 승인하는지>\n'
                '  expires: <YYYY-MM-DD>',
          ),
          _cell(
            key: 'card-outlined-light-defaultStyle',
            component: 'card',
            platform: .flutter,
            status: .noBaseline,
          ),
          _cell(
            key: 'card-outlined-light-defaultStyle',
            component: 'card',
            platform: .web,
            status: .noBaseline,
          ),
          _cell(
            key: 'dialog-default-dark-defaultStyle',
            component: 'dialog',
            platform: .flutter,
            status: .infra,
          ),
          _cell(
            key: 'dialog-default-dark-defaultStyle',
            component: 'dialog',
            platform: .web,
            status: .infra,
          ),
        ],
      ).toMarkdown();
    });

    test('영향 범위 heading counts components, not cells', () {
      expect(markdown, contains('### 영향 범위 — 컴포넌트 3개 중 1개 회귀'));
    });

    test('failing component rows sort first', () {
      final buttonRow = markdown.indexOf('| `button` |');
      final cardRow = markdown.indexOf('| `card` |');
      final dialogRow = markdown.indexOf('| `dialog` |');
      expect(buttonRow, isNot(-1));
      expect(buttonRow, lessThan(cardRow));
      expect(buttonRow, lessThan(dialogRow));
    });

    test('per-platform cells carry status marks and counts', () {
      expect(markdown, contains('| `button` | ✅ 1/1 | ❌ 1 (/1) |'));
      expect(
        markdown,
        contains('| `card` | ⏭ baseline 없음 | ⏭ baseline 없음 |'),
      );
      expect(markdown, contains('| `dialog` | ⚠️ 1 (/1) | ⚠️ 1 (/1) |'));
    });

    test('회귀 상세 renders the describe block for the failing cell', () {
      expect(
        markdown,
        contains('#### `button-primary-light-defaultStyle` · web'),
      );
      expect(markdown, contains('해상도: 1041×804 (동일)'));
      expect(
        markdown,
        contains('픽셀 diff: 20,622 / 836,964 px (2.464%)'),
      );
      expect(markdown, contains('최대 채널차 74'));
      expect(markdown, contains('#2eb8a1 → #207e6f   (12,400 px)'));
    });

    test('회귀 상세 includes the diff artifact and allowlist hint', () {
      expect(
        markdown,
        contains(
          'Diff 이미지: `button-primary-light-defaultStyle.root'
          '.web-regression.diff.png`',
        ),
      );
      expect(markdown, contains('test/parity/allowlist.yaml'));
      expect(
        markdown,
        contains(
          'melos run parity:promote -- button-primary-light-defaultStyle',
        ),
      );
    });

    test('검증 table tallies every status and the compared count', () {
      expect(markdown, contains('| 회귀 비교 수행 (baseline 보유) | 2건 |'));
      expect(markdown, contains('| ✅ 통과 | 1건 |'));
      expect(markdown, contains('| ❌ 회귀 | 1건 |'));
      expect(markdown, contains('| ⏭ baseline 없음 | 2건 |'));
      expect(markdown, contains('| ⚠️ 인프라 실패 | 2건 |'));
    });

    test('comparisons ran, so the "verified nothing" warning is absent', () {
      expect(markdown, isNot(contains('아무 회귀도 검증하지 않았다')));
    });
  });

  group('RegressionSummary.toMarkdown — nothing compared', () {
    test('an all-noBaseline run states loudly that it verified nothing', () {
      final markdown = RegressionSummary(
        cells: [
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .flutter,
            status: .noBaseline,
          ),
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .web,
            status: .noBaseline,
          ),
        ],
      ).toMarkdown();
      expect(markdown, contains('아무 회귀도 검증하지 않았다'));
      expect(markdown, contains('melos run parity:promote'));
      expect(markdown, isNot(contains('### 회귀 상세')));
    });
  });

  group('RegressionSummary.toMarkdown — all passed', () {
    test('renders the scope and verification tables without a detail '
        'section', () {
      final markdown = RegressionSummary(
        cells: [
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .flutter,
            status: .passed,
            diff: _passingDiff(),
          ),
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .web,
            status: .passed,
            diff: _passingDiff(),
          ),
        ],
      ).toMarkdown();
      expect(markdown, contains('### 영향 범위 — 컴포넌트 1개 중 0개 회귀'));
      expect(markdown, contains('| `button` | ✅ 1/1 | ✅ 1/1 |'));
      expect(markdown, isNot(contains('### 회귀 상세')));
      expect(markdown, contains('| ✅ 통과 | 2건 |'));
    });
  });

  group('RegressionSummary.toMarkdown — 비교 미수행 사유', () {
    test('skip/infra notes render grouped by reason text', () {
      final markdown = RegressionSummary(
        cells: [
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .flutter,
            status: .infra,
          ),
          RegressionCell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .web,
            status: .infra,
            note: '캡처 파일을 찾지 못함: x.web.png',
          ),
          RegressionCell(
            key: 'button-primary-dark-defaultStyle',
            component: 'button',
            platform: .web,
            status: .infra,
            note: '캡처 파일을 찾지 못함: x.web.png',
          ),
        ],
      ).toMarkdown();
      expect(markdown, contains('### 비교 미수행 사유'));
      expect(
        markdown,
        contains(
          '- ⚠️ 2셀 — 캡처 파일을 찾지 못함: x.web.png '
          '(예: `button-primary-light-defaultStyle` · web)',
        ),
      );
    });

    test('the section is omitted when no skip/infra cell carries a note', () {
      final markdown = RegressionSummary(
        cells: [
          _cell(
            key: 'button-primary-light-defaultStyle',
            component: 'button',
            platform: .flutter,
            status: .passed,
            diff: _passingDiff(),
          ),
        ],
      ).toMarkdown();
      expect(markdown, isNot(contains('### 비교 미수행 사유')));
    });
  });

  group('RegressionCellCollector — 키당 가장 정보량 높은 쌍 유지', () {
    List<RegressionCell> pair(String key, RegressionCellStatus status) => [
      _cell(
        key: key,
        component: 'button',
        platform: .flutter,
        status: status,
        diff: status == RegressionCellStatus.failed ? _failingDiff() : null,
      ),
      _cell(key: key, component: 'button', platform: .web, status: status),
    ];

    const key = 'button-primary-light-defaultStyle';

    test('a later probe with a real pixel verdict replaces an earlier '
        'infra pair', () {
      final collector = RegressionCellCollector()
        ..offer(key, pair(key, .infra))
        ..offer(key, pair(key, .failed));
      expect(collector.cells, hasLength(2));
      expect(collector.cells.first.status, RegressionCellStatus.failed);
    });

    test('a later less-informed probe does not overwrite a real verdict', () {
      final collector = RegressionCellCollector()
        ..offer(key, pair(key, .passed))
        ..offer(key, pair(key, .infra));
      expect(collector.cells.first.status, RegressionCellStatus.passed);
    });

    test('distinct keys keep insertion (manifest) order', () {
      final collector = RegressionCellCollector()
        ..offer('b-key', pair('b-key', .passed))
        ..offer('a-key', pair('a-key', .passed));
      expect(collector.cells, hasLength(4));
      expect(collector.cells.first.key, 'b-key');
      expect(collector.cells.last.key, 'a-key');
    });
  });

  group('RegressionSummary getters', () {
    test('hasFailures / comparedCellCount reflect only real comparisons', () {
      final summary = RegressionSummary(
        cells: [
          _cell(
            key: 'a-default-light-defaultStyle',
            component: 'a',
            platform: .flutter,
            status: .approved,
            diff: _failingDiff(),
          ),
          _cell(
            key: 'a-default-light-defaultStyle',
            component: 'a',
            platform: .web,
            status: .skipped,
          ),
        ],
      );
      expect(summary.hasFailures, isFalse);
      expect(summary.comparedCellCount, 1);
    });
  });
}
