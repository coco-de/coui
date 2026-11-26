import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

import 'allowlist.dart';
import 'parity_platform.dart';
import 'parity_signal.dart';

/// 한 (키, 플랫폼, 신호) 조합에 대한 baseline 판정 결과.
enum BaselineOutcome {
  /// baseline 이 없다 — regression 은 건너뛰고 parity 만 수행한다.
  ///
  /// 첫 캡처를 허용하는 자리다. 이걸 실패로 두면 새 컴포넌트를 추가할 때마다
  /// 게이트가 빨간불이 되고, 항상 빨간 게이트는 우회된다.
  firstCapture,

  /// baseline 과 지문이 같다.
  match,

  /// 지문이 다르지만 allowlist 에 등록된 의도적 변경이다.
  approvedChange,

  /// 승인 없는 변경 — 회귀다.
  regression,

  /// 승인은 있으나 만료됐다.
  allowlistExpired,

  /// 승인은 있으나 등록된 지문과 다른 **새** 변경이다.
  allowlistMismatch;

  /// 이 결과가 게이트를 실패시키는가.
  bool get isFailure => switch (this) {
    BaselineOutcome.firstCapture => false,
    BaselineOutcome.match => false,
    BaselineOutcome.approvedChange => false,
    BaselineOutcome.regression => true,
    BaselineOutcome.allowlistExpired => true,
    BaselineOutcome.allowlistMismatch => true,
  };

  /// regression 비교를 건너뛰어야 하는가(= baseline 부재).
  bool get skipsRegression => this == BaselineOutcome.firstCapture;
}

/// [BaselineOutcome] 과 사람이 읽는 사유를 함께 나른다.
///
/// 사유를 값에 포함시키는 이유는, 실패 카테고리만 남고 "왜" 가 사라지면
/// 리포트를 본 사람이 다시 로컬에서 재현해야 하기 때문이다.
class BaselineVerdict {
  const BaselineVerdict(this.outcome, this.reason);

  final BaselineOutcome outcome;

  /// 리포트·로그에 그대로 실리는 사유.
  final String reason;

  /// 이 판정이 게이트를 실패시키는가.
  bool get isFailure => outcome.isFailure;

  @override
  String toString() => '${outcome.name}: $reason';
}

/// `test/parity/` 아래의 baseline 파일과 allowlist 를 읽는 저장소.
///
/// baseline 을 git 에 커밋하는 것이 의도된 설계다 — PR diff 에서 "이 변경이
/// 무엇을 바꿨는지" 가 리뷰 대상이 되고, 롤백이 곧 `git revert` 가 된다.
class BaselineStore {
  BaselineStore({required Directory root, required this.allowlist})
    : _root = root;

  /// `test/parity/` 경로에서 allowlist 까지 함께 읽어 만든다.
  factory BaselineStore.at(String rootPath) {
    final root = Directory(rootPath);

    return BaselineStore(
      root: root,
      allowlist: Allowlist.fromFile(File(p.join(rootPath, allowlistFileName))),
    );
  }

  /// 승인 파일 이름. 승격 스크립트와 CODEOWNERS 규칙이 같은 이름을 참조한다.
  static const String allowlistFileName = 'allowlist.yaml';

  /// 커밋되는 baseline 이 사는 하위 디렉터리 이름.
  static const String baselineDirName = 'baseline';

  /// 이번 실행이 캡처한 산출물이 사는 하위 디렉터리 이름(.gitignore).
  static const String capturedDirName = 'captured';

  /// `test/parity/captured/`.
  Directory get capturedDir => Directory(p.join(_root.path, capturedDirName));

  final Directory _root;

  /// 읽어들인 승인 목록.
  final Allowlist allowlist;

  /// `test/parity/baseline/`.
  Directory get baselineDir => Directory(p.join(_root.path, baselineDirName));

  /// 바이트열의 지문.
  ///
  /// baseline·캡처·승격이 **모두 이 함수 하나**를 거쳐야 한다. 지문 계산이
  /// 두 곳에 생기면 한쪽만 바뀌었을 때 전 항목이 한꺼번에 회귀로 뜬다.
  static String fingerprintOfBytes(List<int> bytes) =>
      sha256.convert(bytes).toString();

  /// 문자열의 지문(UTF-8 기준).
  static String fingerprintOfString(String text) =>
      fingerprintOfBytes(utf8.encode(text));

  /// 한 조합의 baseline 파일 — 존재 여부와 무관하게 경로를 돌려준다.
  File baselineFile({
    required String key,
    required ParityPlatform platform,
    required ParitySignal signal,
  }) => File(
    p.join(
      baselineDir.path,
      '$key.${platform.wireName}.${signal.fileExtension}',
    ),
  );

  /// baseline 이 커밋돼 있는가.
  bool hasBaseline({
    required String key,
    required ParityPlatform platform,
    required ParitySignal signal,
  }) => baselineFile(key: key, platform: platform, signal: signal).existsSync();

  /// baseline 의 지문. 파일이 없으면 `null`.
  String? baselineFingerprint({
    required String key,
    required ParityPlatform platform,
    required ParitySignal signal,
  }) {
    final file = baselineFile(key: key, platform: platform, signal: signal);
    if (!file.existsSync()) {
      return null;
    }

    return fingerprintOfBytes(file.readAsBytesSync());
  }

  /// 이번 캡처를 baseline·allowlist 에 비추어 판정한다.
  ///
  /// [now] 를 인자로 받는 이유는 만료 로직이 테스트 가능해야 하기 때문이다 —
  /// 벽시계를 직접 읽으면 "만료된 승인이 실패로 전환되는가" 를 고정할 방법이
  /// 달력을 기다리는 것밖에 없다.
  BaselineVerdict evaluate({
    required String key,
    required ParityPlatform platform,
    required ParitySignal signal,
    required String capturedFingerprint,
    required DateTime now,
  }) {
    final baseline = baselineFingerprint(
      key: key,
      platform: platform,
      signal: signal,
    );

    if (baseline == null) {
      return const BaselineVerdict(
        BaselineOutcome.firstCapture,
        'baseline 부재 — regression 스킵, parity 만 수행 (첫 캡처 허용).',
      );
    }

    if (baseline == capturedFingerprint) {
      return const BaselineVerdict(
        BaselineOutcome.match,
        'baseline 과 일치.',
      );
    }

    final candidates = allowlist.entriesFor(key, signal);
    if (candidates.isEmpty) {
      return BaselineVerdict(
        BaselineOutcome.regression,
        '승인되지 않은 변경 — allowlist 에 `$key` / ${signal.wireName} 항목이 없다.',
      );
    }

    final approved = _matching(candidates, capturedFingerprint);
    if (approved == null) {
      return BaselineVerdict(
        BaselineOutcome.allowlistMismatch,
        '등록된 변경과 다른 새 변경 — allowlist 지문 '
        '${candidates.map((entry) => _short(entry.fingerprint)).join(', ')} / '
        '이번 지문 ${_short(capturedFingerprint)}.',
      );
    }

    if (approved.isExpiredAt(now)) {
      return BaselineVerdict(
        BaselineOutcome.allowlistExpired,
        '만료됨 — ${_isoDate(approved.expires)} 까지 유효했던 승인 '
        '(사유: ${approved.reason}). 재승인하거나 baseline 을 승격하라.',
      );
    }

    return BaselineVerdict(
      BaselineOutcome.approvedChange,
      '승인된 의도적 변경 — ${approved.reason} '
      '(만료 ${_isoDate(approved.expires)}).',
    );
  }

  static AllowlistEntry? _matching(
    List<AllowlistEntry> candidates,
    String fingerprint,
  ) {
    for (final entry in candidates) {
      if (entry.fingerprint == fingerprint) {
        return entry;
      }
    }

    return null;
  }

  /// 지문 앞부분만 — 로그에서 전체 64자는 읽히지 않는다.
  static String _short(String fingerprint) {
    const previewLength = 12;

    return fingerprint.length <= previewLength
        ? fingerprint
        : fingerprint.substring(0, previewLength);
  }

  static String _isoDate(DateTime date) =>
      date.toIso8601String().split('T').first;
}
