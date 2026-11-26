@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_core/shared/component_deprecation_status.g.dart';
import 'package:test/test.dart';

import '../../tool/deprecation_status_generator.dart';

/// 커밋된 `component_deprecation_status.g.dart` 가 실제 소스와 어긋나지
/// 않았는지 게이트한다.
///
/// 왜 테스트인가: 이 파일은 손으로 고치지 않는다 — `@Deprecated 어노테이션을
/// 파싱해(손 관리 목록 아님)` 이라는 요구사항의 실제 강제 지점이 여기다.
/// 컴포넌트를 새로 deprecated 처리하고 생성기를 재실행하는 걸 잊으면, 카탈로그가
/// "Active" 라고 계속 거짓말하는 회귀가 조용히 들어온다 — 이 테스트가 그걸
/// 깨뜨린다.
void main() {
  test('생성된 deprecation 상태가 소스와 일치한다', () {
    final recomputed = computeDeprecationStatus(
      flutterComponentsDir: Directory(
        '../packages/coui_flutter/lib/src/components',
      ),
      webComponentsDir: Directory('../packages/coui_web/lib/src/components'),
    );

    expect(
      kDocsDeprecationStatus.length,
      recomputed.length,
      reason:
          '커밋된 component_deprecation_status.g.dart 의 개수가 소스와 '
          '다르다 — `cd docs_core && dart run tool/gen_deprecation_status.dart` '
          '로 재생성하라',
    );
    for (final slug in recomputed.keys) {
      expect(
        kDocsDeprecationStatus[slug],
        recomputed[slug],
        reason:
            '$slug 의 deprecation 상태가 소스와 어긋난다 — '
            '`cd docs_core && dart run tool/gen_deprecation_status.dart` 로 '
            '재생성하라',
      );
    }
  });
}
