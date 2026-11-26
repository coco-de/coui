// 파리티 baseline 승격 CLI.
//
//   melos run parity:promote                 # 전체
//   melos run parity:promote -- <key>        # 단일
//   melos run parity:promote -- --dry-run    # 무엇이 덮어써질지만 확인
//
// 잘못된 baseline 승격(회귀를 정상으로 굳힘)이 이 시스템의 가장 위험한
// 시나리오다. 그래서 기본 동작이 "승격 + 요약을 담은 커밋 생성" 이다 —
// 요약이 커밋 메시지에 없으면 리뷰어가 diff 의 PNG 바이트를 보고 판단해야 한다.
import 'dart:io';

import 'src/baseline/baseline_store.dart';
import 'src/baseline/promoter.dart';

/// 인프라 실패(캡처 산출물 부재 등) 종료 코드.
///
/// 검증 실패(1)와 구분해야 CI 에서 "실제 회귀" 와 "러너 문제" 가 섞이지 않는다.
const int kExitInfraFailure = 2;

const String kDefaultRoot = 'test/parity';

void main(List<String> args) {
  if (args.contains('--help') || args.contains('-h')) {
    _printUsage();

    return;
  }

  final dryRun = args.contains('--dry-run');
  final commit = !args.contains('--no-commit') && !dryRun;
  final root = _valueOf(args, '--root') ?? kDefaultRoot;
  final positional = args
      .where((arg) => !arg.startsWith('-'))
      .toList(growable: false);

  if (positional.length > 1) {
    stderr.writeln('키는 하나만 지정할 수 있다: ${positional.join(', ')}');
    exitCode = kExitInfraFailure;

    return;
  }

  final onlyKey = positional.isEmpty ? null : positional.first;

  final PromotionResult result;
  try {
    result = BaselinePromoter(
      BaselineStore.at(root),
    ).promote(onlyKey: onlyKey, dryRun: dryRun);
  } on PromotionUnavailable catch (error) {
    stderr.writeln('[promote] ${error.message}');
    exitCode = kExitInfraFailure;

    return;
  }

  stdout.writeln('[promote] ${result.consoleSummary()}');
  for (final name in result.skipped) {
    stdout.writeln('[promote] 건너뜀 (이름 규칙 불일치): $name');
  }

  if (!result.hasWrites) {
    stdout.writeln('[promote] 갱신할 baseline 이 없다.');

    return;
  }

  if (dryRun) {
    stdout
      ..writeln('[promote] --dry-run — 파일을 쓰지 않았다. 커밋 메시지 미리보기:')
      ..writeln()
      ..writeln(result.commitMessage(onlyKey: onlyKey));

    return;
  }

  stdout.writeln('[promote] ${result.writtenPaths.length}개 baseline 갱신됨.');

  if (!commit) {
    stdout
      ..writeln('[promote] --no-commit — 아래 메시지로 직접 커밋하라:')
      ..writeln()
      ..writeln(result.commitMessage(onlyKey: onlyKey));

    return;
  }

  _commit(result, onlyKey: onlyKey);
}

/// 승격된 baseline 파일**만** 스테이지해 커밋한다.
///
/// `git add -A` 가 아닌 이유는 작업 중이던 다른 변경까지 쓸어 담지 않기
/// 위해서다 — 승격 커밋은 baseline 만 담아야 리뷰가 성립한다.
void _commit(PromotionResult result, {String? onlyKey}) {
  final added = Process.runSync('git', <String>[
    'add',
    '--',
    ...result.writtenPaths,
  ]);
  if (added.exitCode != 0) {
    stderr.writeln('[promote] git add 실패: ${added.stderr}');
    exitCode = kExitInfraFailure;

    return;
  }

  // Unique per run — a fixed name under the shared temp dir lets two
  // promotions on one host overwrite each other's commit message.
  final messageDir = Directory.systemTemp.createTempSync(
    'coui-parity-promote-',
  );
  final messageFile = File('${messageDir.path}/message.txt')
    ..writeAsStringSync(result.commitMessage(onlyKey: onlyKey));

  try {
    final committed = Process.runSync('git', <String>[
      'commit',
      '-F',
      messageFile.path,
    ]);
    if (committed.exitCode != 0) {
      stderr.writeln('[promote] git commit 실패: ${committed.stderr}');
      exitCode = kExitInfraFailure;

      return;
    }
    stdout.writeln('[promote] 승격 커밋 생성됨 (요약 포함).');
  } finally {
    messageDir.deleteSync(recursive: true);
  }
}

String? _valueOf(List<String> args, String flag) {
  for (final arg in args) {
    if (arg.startsWith('$flag=')) {
      return arg.substring(flag.length + 1);
    }
  }

  return null;
}

void _printUsage() {
  stdout.writeln('''
파리티 baseline 승격 — captured/ 를 baseline/ 으로 올린다.

  melos run parity:promote                  전체 승격
  melos run parity:promote -- <key>         단일 키만 승격

⚠️ melos 는 위치 인자만 스크립트로 넘긴다 — 플래그는 자기 옵션으로 해석해
   "Could not find an option named ..." 로 실패한다. 플래그가 필요하면
   dart run 을 직접 쓴다:

  dart run tool/parity/promote.dart --dry-run
  dart run tool/parity/promote.dart <key> --no-commit

옵션
  --root=<path>   데이터 루트 (기본 $kDefaultRoot)
  --dry-run       분류만 하고 아무것도 쓰지 않는다
  --no-commit     baseline 은 갱신하되 커밋은 만들지 않는다
  -h, --help      이 도움말

기본 동작은 승격 + 요약을 담은 커밋 생성이다. 잘못된 승격이 회귀를 정상으로
굳히는 가장 위험한 경로라, 리뷰어가 커밋만 보고도 무엇이 바뀌었는지 알아야 한다.

종료 코드: 0 정상 / $kExitInfraFailure 인프라 실패(캡처 산출물 부재 등)''');
}
