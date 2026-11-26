/// `cd docs_core && dart run tool/gen_llms_txt.dart` 로 실행한다.
///
/// 컴포넌트 · 가이드 카탈로그에서 `llms.txt` 를 다시 굽어
/// `docs_site/web/llms.txt` 에 쓴다. docs_site 는 `web/` 을 정적 자산으로
/// 그대로 싣기 때문에 배포된 사이트의 `/llms.txt` 가 이 파일이다.
///
/// 카탈로그 엔트리를 추가·수정했으면 이 스크립트를 재실행해 결과를 커밋한다
/// — `test/registry/llms_txt_sync_test.dart` 가 재실행을 잊었는지 게이트한다.
library;

import 'dart:io';

import 'package:docs_core/shared/llms_txt.dart';

/// 생성물 경로 — docs_core 패키지 루트 기준. 테스트도 같은 상수를 읽는다.
const String kLlmsTxtOutputPath = '../docs_site/web/llms.txt';

void main() {
  final outFile = File(kLlmsTxtOutputPath)..writeAsStringSync(renderLlmsTxt());
  stdout.writeln('✅ ${outFile.path} 를 카탈로그에서 다시 썼다.');
}
