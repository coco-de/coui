@TestOn('vm')
library;

import 'dart:io';

import 'package:docs_app/src/preview/web_render.dart';
import 'package:flutter_test/flutter_test.dart';

/// in-process Web 렌더가 서버 없이 사이트와 동일한 HTML 을 내는지 검증한다.
///
/// 이게 되면 Web 페인이 jaspr serve·localhost·adb reverse 없이 동작한다.
void main() {
  setUpAll(() {
    // Android/iOS 조건 재현: cwd 위로 pubspec.yaml 이 없는 상태. 데스크톱
    // 테스트는 우연히 프로젝트 cwd(pubspec 존재)에서 돌아 이 실패를 놓쳤다.
    // 렌더러가 cwd 를 마커 디렉터리로 옮겨 이 조건을 견뎌야 한다.
    Directory.current = Directory.systemTemp.createTempSync('docs_app_nopub');
  });

  test('pubspec 없는 cwd 에서도 in-process HTML 을 렌더한다', () async {
    final html = await renderWebPreviewHtml(
      component: 'badge',
      variant: 'default',
      dark: false,
    );

    expect(html, isNotNull, reason: '패키지된 앱 조건에서도 렌더돼야 한다');
    // 사이트와 동일한 head(CDN·폰트·테마)가 그대로 들어간다.
    expect(html, contains('cdn.tailwindcss.com'));
    expect(html, contains('pretendard'));
    expect(html, contains('data-theme'));
    // 실제 컴포넌트가 렌더된다.
    expect(html, contains('web-badge'));
  });

  test('다크 테마가 반영된다', () async {
    final html = await renderWebPreviewHtml(component: 'button', dark: true);
    expect(html, contains('data-theme="dark"'));
  });
}
