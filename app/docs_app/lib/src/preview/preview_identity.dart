/// 프리뷰 페인의 플랫폼 정체성 — 라벨 문구와 점 색.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// 라이브 프리뷰가 나란히 놓는 두 플랫폼.
enum DocsPreviewPlatform {
  /// Web 페인 — jaspr 이 그린 것을 WebView 로 임베드한다.
  web('Web', CoreColor(0xFF3B82F6)),

  /// 네이티브로 그리는 Flutter 페인.
  flutter('Flutter', CoreColor(0xFF06B6D4));

  const DocsPreviewPlatform(this.label, this.dotColor);

  /// 페인 라벨에 찍는 문구.
  final String label;

  /// 라벨 앞 점의 색.
  ///
  /// **테마 토큰이 아니라 브랜드 상수다.** 이 두 점은 chrome 이 아니라
  /// "이 페인이 어느 플랫폼인가" 를 말하는 정체성 표식이라, 라이트/다크나
  /// 프로젝트 테마가 바뀌어도 같은 색이어야 알아볼 수 있다. 값은 jaspr
  /// 사이트의 `.preview-label-dot--web` / `--flutter` 와 동일하다 — 두
  /// 사이트를 나란히 놓아도 같은 점이 같은 플랫폼을 가리킨다.
  ///
  /// 시맨틱 토큰(`primary` 210°, `info` 200°)으로 대신할 수 없다: 색상환에서
  /// 10° 밖에 안 떨어져 있어 두 점이 사실상 같은 파랑으로 보이고, 그 순간
  /// 점이 정체성 표식이기를 그만둔다.
  final CoreColor dotColor;
}
