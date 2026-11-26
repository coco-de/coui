/// `cd docs_core && dart run tool/gen_deprecation_status.dart` 로 실행한다.
///
/// 카탈로그 컴포넌트의 위젯 소스에서 클래스-레벨 `@Deprecated(...)` 를
/// 스캔해 `lib/shared/component_deprecation_status.g.dart` 를 다시 굽는다.
/// 이 생성 파일이 손 관리 목록을 대신한다 — deprecation 상태는 소스 코드가
/// 유일한 출처다. 컴포넌트를 새로 deprecated 처리했으면 이 스크립트를
/// 재실행해 결과를 커밋한다(`test/registry/deprecation_status_sync_test.dart`
/// 가 재실행을 잊었는지 게이트한다).
library;

import 'dart:io';

import 'deprecation_status_generator.dart';

void main() {
  final status = computeDeprecationStatus(
    flutterComponentsDir: Directory(
      '../packages/coui_flutter/lib/src/components',
    ),
    webComponentsDir: Directory('../packages/coui_web/lib/src/components'),
  );
  final outFile = File('lib/shared/component_deprecation_status.g.dart');
  outFile.writeAsStringSync(renderGeneratedFile(status));
  stdout.writeln(
    '✅ ${status.length}개 deprecated 컴포넌트를 ${outFile.path} 에 썼다.',
  );
}
