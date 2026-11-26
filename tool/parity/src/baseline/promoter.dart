import 'dart:io';

import 'artifact_name.dart';
import 'baseline_store.dart';

/// 승격을 수행할 수 없는 상태 — 캡처 산출물 부재 같은 인프라 실패.
///
/// `Error` 가 아니라 `Exception` 인 이유: 이건 프로그래밍 버그가 아니라
/// "아직 캡처를 안 돌렸다" 는 **예상 가능한** 운영 상태이고, 호출자가 잡아서
/// 인프라 실패 종료 코드로 바꾸는 것이 정상 경로다.
class PromotionUnavailable implements Exception {
  const PromotionUnavailable(this.message);

  final String message;

  @override
  String toString() => message;
}

/// 승격 한 건이 baseline 에 무엇을 했는지.
enum PromotionKind {
  /// baseline 이 없던 조합 — 새로 커밋된다.
  added,

  /// 이미 있던 baseline 의 내용이 바뀐다. **가장 위험한 항목**이다.
  changed,

  /// 지문이 같아 파일을 건드리지 않았다.
  unchanged,
}

/// 승격 대상 하나.
class PromotionItem {
  const PromotionItem({
    required this.artifact,
    required this.kind,
    required this.fingerprint,
    required this.baselinePath,
    this.previousFingerprint,
  });

  final ArtifactName artifact;
  final PromotionKind kind;

  /// 승격 후 baseline 의 지문.
  final String fingerprint;

  /// 승격 전 baseline 의 지문. [PromotionKind.added] 면 `null`.
  final String? previousFingerprint;

  /// 리포지토리 기준 baseline 경로 — `git add` 대상이다.
  final String baselinePath;
}

/// 승격 결과 + 커밋 메시지에 실릴 요약.
class PromotionResult {
  const PromotionResult({required this.items, required this.skipped});

  final List<PromotionItem> items;

  /// 이름 규칙에 맞지 않아 건너뛴 파일들.
  ///
  /// 조용히 무시하지 않는 이유는, 캡처 단계가 이름을 잘못 붙이면 승격이
  /// "0건 성공" 으로 보이면서 실제로는 아무것도 갱신되지 않기 때문이다.
  final List<String> skipped;

  List<PromotionItem> get added => _of(PromotionKind.added);

  List<PromotionItem> get changed => _of(PromotionKind.changed);

  List<PromotionItem> get unchanged => _of(PromotionKind.unchanged);

  /// 실제로 파일을 쓴 항목의 경로(= 커밋에 담을 것).
  List<String> get writtenPaths => <String>[
    for (final item in items)
      if (item.kind != PromotionKind.unchanged) item.baselinePath,
  ];

  /// 승격이 baseline 을 하나라도 건드렸는가.
  bool get hasWrites => writtenPaths.isNotEmpty;

  List<PromotionItem> _of(PromotionKind kind) => <PromotionItem>[
    for (final item in items)
      if (item.kind == kind) item,
  ];

  /// 승격 커밋 메시지 본문.
  ///
  /// 잘못된 baseline 승격(회귀를 정상으로 굳힘)이 이 시스템의 가장 위험한
  /// 시나리오다. 리뷰어가 **커밋만 보고도** 무엇이 바뀌었는지 알아야 하므로
  /// 요약을 메시지에 싣는다 — 특히 `변경` 항목은 지문 전후를 함께 적는다.
  String commitMessage({String? onlyKey}) {
    final scope = onlyKey == null ? '전체' : '`$onlyKey`';
    final buffer = StringBuffer()
      ..writeln('chore(parity): baseline 승격 ($scope)')
      ..writeln()
      ..writeln(
        '추가 ${added.length} · 변경 ${changed.length} · '
        '동일 ${unchanged.length}',
      );

    if (changed.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 변경 — 기존 baseline 을 덮어쓴다 (검토 필요)');
      for (final item in changed) {
        buffer.writeln(
          '~ ${item.artifact} '
          '${_short(item.previousFingerprint)} → ${_short(item.fingerprint)}',
        );
      }
    }

    if (added.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 추가 — baseline 신규');
      for (final item in added) {
        buffer.writeln('+ ${item.artifact} ${_short(item.fingerprint)}');
      }
    }

    if (skipped.isNotEmpty) {
      buffer
        ..writeln()
        ..writeln('## 건너뜀 — 이름 규칙 불일치')
        ..writeAll(skipped.map((name) => '? $name'), '\n')
        ..writeln();
    }

    return buffer.toString().trimRight();
  }

  /// 콘솔 요약 — 커밋 메시지와 같은 정보를 사람이 훑기 좋게.
  String consoleSummary() =>
      '추가 ${added.length} · 변경 ${changed.length} · '
      '동일 ${unchanged.length}'
      '${skipped.isEmpty ? '' : ' · 건너뜀 ${skipped.length}'}';

  static String _short(String? fingerprint) {
    const previewLength = 12;
    if (fingerprint == null) {
      return '(없음)';
    }

    return fingerprint.length <= previewLength
        ? fingerprint
        : fingerprint.substring(0, previewLength);
  }
}

/// `captured/` 의 산출물을 `baseline/` 으로 승격한다.
class BaselinePromoter {
  const BaselinePromoter(this.store);

  final BaselineStore store;

  /// 승격을 수행한다.
  ///
  /// [onlyKey] 가 있으면 그 키만, 없으면 전체. [dryRun] 이면 분류만 하고
  /// 파일을 쓰지 않는다 — 무엇이 덮어써질지 먼저 보기 위한 모드다.
  PromotionResult promote({String? onlyKey, bool dryRun = false}) {
    final captured = store.capturedDir;
    if (!captured.existsSync()) {
      throw PromotionUnavailable(
        '${captured.path} 가 없다. 먼저 캡처를 돌려라 — 승격할 산출물이 없다.',
      );
    }

    final items = <PromotionItem>[];
    final skipped = <String>[];

    final files = captured.listSync().whereType<File>().toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    for (final file in files) {
      final fileName = file.uri.pathSegments.last;
      final artifact = ArtifactName.tryParse(fileName);
      if (artifact == null) {
        skipped.add(fileName);
        continue;
      }
      if (onlyKey != null && artifact.key != onlyKey) {
        continue;
      }

      items.add(_promoteOne(file, artifact, dryRun: dryRun));
    }

    return PromotionResult(items: items, skipped: skipped);
  }

  PromotionItem _promoteOne(
    File captured,
    ArtifactName artifact, {
    required bool dryRun,
  }) {
    final target = store.baselineFile(
      key: artifact.key,
      platform: artifact.platform,
      signal: artifact.signal,
    );

    final bytes = captured.readAsBytesSync();
    final fingerprint = BaselineStore.fingerprintOfBytes(bytes);
    final previous = target.existsSync()
        ? BaselineStore.fingerprintOfBytes(target.readAsBytesSync())
        : null;

    final kind = switch (previous) {
      null => PromotionKind.added,
      final existing when existing == fingerprint => PromotionKind.unchanged,
      _ => PromotionKind.changed,
    };

    if (!dryRun && kind != PromotionKind.unchanged) {
      target.parent.createSync(recursive: true);
      target.writeAsBytesSync(bytes);
    }

    return PromotionItem(
      artifact: artifact,
      kind: kind,
      fingerprint: fingerprint,
      previousFingerprint: previous,
      baselinePath: target.path,
    );
  }
}
