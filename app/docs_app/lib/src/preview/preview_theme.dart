/// 프리뷰 페인의 테마 — jaspr 사이트의 프리뷰 앱과 일치시킨다.
library;

import 'package:coui_flutter/coui_flutter.dart';

/// 프리뷰 하나를 그릴 때 쓰는 [ThemeData].
///
/// `CoreThemePresets.previewLight`/`previewDark` 는 3축 스케일링을 1.15 로
/// 들고 있다. Jaspr 사이트의 프리뷰 호스트는 그걸 1.0 으로 중화해서, 스케일
/// 되지 않은 Web 페인과 나란히 놓았을 때 Flutter 타이포가 부풀지 않게 한다.
/// 여기서도 똑같이 중화하지 않으면 docs_app 의 모든 프리뷰가 조용히 15%
/// 커진 채로 렌더된다.
ThemeData docsPreviewTheme({required bool dark}) {
  final core = dark
      ? CoreThemePresets.previewDark
      : CoreThemePresets.previewLight;
  return ThemeData.fromCore(
    core.copyWith(textScaling: 1, sizeScaling: 1, radiusScaling: 1),
  );
}
