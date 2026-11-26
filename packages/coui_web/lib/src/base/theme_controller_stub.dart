import 'package:coui_core/coui_core.dart';

/// CoUI 테마 컨트롤러 (서버/네이티브 스텁).
///
/// 서버 사이드 렌더링 환경에서는 DOM에 접근할 수 없으므로
/// 모든 DOM 관련 메서드가 no-op 또는 기본값을 반환합니다.
///
/// `ThemeConfig` 가 `--coui-*` 변수를 정의하는 테마는 [light] 와 [dark]
/// 둘뿐입니다 — 웹 구현과 같은 표면을 유지합니다.
class CoUIThemeController {
  // ========================================
  // CSS 정의가 있는 테마
  // ========================================

  /// Light 테마 (기본값).
  static const light = 'light';

  /// Dark 테마.
  static const dark = 'dark';

  // ========================================
  // CSS 정의가 없는 이름 (deprecated)
  // ========================================

  /// Cupcake 테마 (핑크/파스텔).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cupcake = 'cupcake';

  /// Bumblebee 테마 (노랑).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const bumblebee = 'bumblebee';

  /// Emerald 테마 (초록).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const emerald = 'emerald';

  /// Corporate 테마 (비즈니스).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const corporate = 'corporate';

  /// Synthwave 테마 (사이버펑크 핑크).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const synthwave = 'synthwave';

  /// Retro 테마 (레트로).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const retro = 'retro';

  /// Cyberpunk 테마 (사이버펑크 노랑).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cyberpunk = 'cyberpunk';

  /// Valentine 테마 (발렌타인 핑크).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const valentine = 'valentine';

  /// Halloween 테마 (할로윈).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const halloween = 'halloween';

  /// Garden 테마 (가든).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const garden = 'garden';

  /// Forest 테마 (포레스트 그린).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const forest = 'forest';

  /// Aqua 테마 (아쿠아 블루).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const aqua = 'aqua';

  /// Lofi 테마 (로파이).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const lofi = 'lofi';

  /// Pastel 테마 (파스텔).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const pastel = 'pastel';

  /// Fantasy 테마 (판타지).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const fantasy = 'fantasy';

  /// Wireframe 테마 (와이어프레임).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const wireframe = 'wireframe';

  /// Black 테마 (블랙).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const black = 'black';

  /// Luxury 테마 (럭셔리).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const luxury = 'luxury';

  /// Dracula 테마 (드라큘라).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const dracula = 'dracula';

  /// CMYK 테마.
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cmyk = 'cmyk';

  /// Autumn 테마 (가을).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const autumn = 'autumn';

  /// Business 테마 (비즈니스 다크).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const business = 'business';

  /// Acid 테마 (산성).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const acid = 'acid';

  /// Lemonade 테마 (레모네이드).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const lemonade = 'lemonade';

  /// Night 테마 (나이트).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const night = 'night';

  /// Coffee 테마 (커피).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const coffee = 'coffee';

  /// Winter 테마 (겨울).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const winter = 'winter';

  /// Dim 테마 (딤).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const dim = 'dim';

  /// Nord 테마 (노르드).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const nord = 'nord';

  /// Sunset 테마 (선셋).
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const sunset = 'sunset';

  /// 테마 이름 목록 — CSS 정의가 있는 것은 [light] 와 [dark] 뿐이고,
  /// 나머지는 deprecated 이름이 제거될 때까지 호환을 위해 남아 있습니다.
  static const availableThemes = [
    light,
    dark,
    cupcake,
    bumblebee,
    emerald,
    corporate,
    synthwave,
    retro,
    cyberpunk,
    valentine,
    halloween,
    garden,
    forest,
    aqua,
    lofi,
    pastel,
    fantasy,
    wireframe,
    black,
    luxury,
    dracula,
    cmyk,
    autumn,
    business,
    acid,
    lemonade,
    night,
    coffee,
    winter,
    dim,
    nord,
    sunset,
  ];

  // ========================================
  // 테마 관리 메서드 (서버 스텁)
  // ========================================

  /// 현재 적용된 테마 가져오기 (서버: 기본값 반환).
  static String getCurrentTheme() => light;

  /// 테마 변경하기 (서버: no-op).
  static void setTheme(String theme) {}

  /// 다크 모드 토글 (서버: no-op).
  static void toggleDarkMode() {}

  /// 시스템 설정 다크 모드 확인 (서버: false 반환).
  static bool prefersDarkMode() => false;

  /// 시스템 설정에 따라 테마 적용 (서버: no-op).
  static void useSystemPreference() {}

  /// 시스템 설정 변경 감지 (서버: no-op).
  static void watchSystemPreference(void Function(bool isDark) callback) {}

  /// 테마 이름을 한글로 변환.
  static String getThemeDisplayName(String theme) {
    return switch (theme) {
      light => '라이트',
      dark => '다크',
      cupcake => '컵케이크',
      bumblebee => '범블비',
      emerald => '에메랄드',
      corporate => '코포레이트',
      synthwave => '신스웨이브',
      retro => '레트로',
      cyberpunk => '사이버펑크',
      valentine => '발렌타인',
      halloween => '할로윈',
      garden => '가든',
      forest => '포레스트',
      aqua => '아쿠아',
      lofi => '로파이',
      pastel => '파스텔',
      fantasy => '판타지',
      wireframe => '와이어프레임',
      black => '블랙',
      luxury => '럭셔리',
      dracula => '드라큘라',
      cmyk => 'CMYK',
      autumn => '가을',
      business => '비즈니스',
      acid => '애시드',
      lemonade => '레모네이드',
      night => '나이트',
      coffee => '커피',
      winter => '겨울',
      dim => '딤',
      nord => '노르드',
      sunset => '선셋',
      _ => theme,
    };
  }

  /// 테마가 다크 계열인지 확인.
  static bool isDarkTheme(String theme) {
    const darkThemes = [
      dark,
      synthwave,
      halloween,
      forest,
      black,
      luxury,
      dracula,
      business,
      night,
      coffee,
      dim,
      sunset,
    ];
    return darkThemes.contains(theme);
  }

  /// 커스텀 [CoreColorScheme]을 CSS 커스텀 프로퍼티로 적용합니다 (서버: no-op).
  static void setCustomTheme(
    CoreColorScheme colorScheme, {
    CoreBrightness brightness = .light,
    double radiusScaling = 1.0,
  }) {}
}
