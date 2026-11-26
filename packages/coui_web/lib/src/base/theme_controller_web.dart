import 'dart:js_interop';

import 'package:coui_core/coui_core.dart';
import 'package:web/web.dart' as web;

/// CoUI 테마 컨트롤러
///
/// CoUI 테마 시스템을 관리하는 유틸리티 클래스입니다.
/// HTML의 data-theme 속성을 통해 테마를 변경합니다.
///
/// `ThemeConfig` 가 `--coui-*` 변수를 정의하는 테마는 [light] 와 [dark]
/// 둘뿐입니다. 그 밖의 이름을 `data-theme` 에 넣으면 대응하는 정의가 없어
/// 아무것도 바뀌지 않습니다 — 임의 팔레트는 [setCustomTheme] 으로 적용합니다.
class CoUIThemeController {
  // ========================================
  // CSS 정의가 있는 테마
  // ========================================

  /// Light 테마 (기본값)
  static const light = 'light';

  /// Dark 테마
  static const dark = 'dark';

  // ========================================
  // CSS 정의가 없는 이름 (deprecated)
  // ========================================

  /// Cupcake 테마 (핑크/파스텔)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cupcake = 'cupcake';

  /// Bumblebee 테마 (노랑)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const bumblebee = 'bumblebee';

  /// Emerald 테마 (초록)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const emerald = 'emerald';

  /// Corporate 테마 (비즈니스)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const corporate = 'corporate';

  /// Synthwave 테마 (사이버펑크 핑크)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const synthwave = 'synthwave';

  /// Retro 테마 (레트로)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const retro = 'retro';

  /// Cyberpunk 테마 (사이버펑크 노랑)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cyberpunk = 'cyberpunk';

  /// Valentine 테마 (발렌타인 핑크)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const valentine = 'valentine';

  /// Halloween 테마 (할로윈)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const halloween = 'halloween';

  /// Garden 테마 (가든)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const garden = 'garden';

  /// Forest 테마 (포레스트 그린)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const forest = 'forest';

  /// Aqua 테마 (아쿠아 블루)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const aqua = 'aqua';

  /// Lofi 테마 (로파이)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const lofi = 'lofi';

  /// Pastel 테마 (파스텔)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const pastel = 'pastel';

  /// Fantasy 테마 (판타지)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const fantasy = 'fantasy';

  /// Wireframe 테마 (와이어프레임)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const wireframe = 'wireframe';

  /// Black 테마 (블랙)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const black = 'black';

  /// Luxury 테마 (럭셔리)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const luxury = 'luxury';

  /// Dracula 테마 (드라큘라)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const dracula = 'dracula';

  /// CMYK 테마
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const cmyk = 'cmyk';

  /// Autumn 테마 (가을)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const autumn = 'autumn';

  /// Business 테마 (비즈니스 다크)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const business = 'business';

  /// Acid 테마 (산성)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const acid = 'acid';

  /// Lemonade 테마 (레모네이드)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const lemonade = 'lemonade';

  /// Night 테마 (나이트)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const night = 'night';

  /// Coffee 테마 (커피)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const coffee = 'coffee';

  /// Winter 테마 (겨울)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const winter = 'winter';

  /// Dim 테마 (딤)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const dim = 'dim';

  /// Nord 테마 (노르드)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const nord = 'nord';

  /// Sunset 테마 (선셋)
  @Deprecated(
    'No CSS definition: data-theme only styles light and dark. '
    'Use setCustomTheme for a custom palette (since 0.150)',
  )
  static const sunset = 'sunset';

  /// 테마 이름 목록
  ///
  /// CSS 정의가 있는 것은 [light] 와 [dark] 뿐이고, 나머지는 deprecated
  /// 이름이 제거될 때까지 호환을 위해 남아 있습니다.
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
  // 테마 관리 메서드
  // ========================================

  /// 현재 적용된 테마 가져오기
  ///
  /// HTML document의 data-theme 속성을 읽습니다.
  /// 값이 없으면 기본값인 [light]를 반환합니다.
  ///
  /// 예시:
  /// ```dart
  /// final currentTheme = CoUIThemeController.getCurrentTheme();
  /// print('Current theme: $currentTheme'); // 'light' 또는 설정된 테마
  /// ```
  static String getCurrentTheme() {
    final theme = web.document.documentElement?.getAttribute('data-theme');
    return theme ?? light;
  }

  /// 테마 변경하기
  ///
  /// HTML document의 data-theme 속성을 변경합니다.
  ///
  /// [theme]: 변경할 테마 이름 — CSS 정의가 있는 것은 [light] 와 [dark] 뿐
  ///
  /// 예시:
  /// ```dart
  /// // 다크 테마로 변경
  /// CoUIThemeController.setTheme(CoUIThemeController.dark);
  ///
  /// // 라이트 테마로 되돌리기
  /// CoUIThemeController.setTheme(CoUIThemeController.light);
  /// ```
  static void setTheme(String theme) {
    web.document.documentElement?.setAttribute('data-theme', theme);
  }

  /// 다크 모드 토글
  ///
  /// 현재 테마가 [dark]이면 [light]로,
  /// 그 외의 경우 [dark]로 변경합니다.
  ///
  /// 예시:
  /// ```dart
  /// // 다크 모드 토글 버튼
  /// Button.ghost(
  ///   onPressed: () => CoUIThemeController.toggleDarkMode(),
  ///   child: Icon(name: 'moon'),
  /// )
  /// ```
  static void toggleDarkMode() {
    final current = getCurrentTheme();
    setTheme(current == dark ? light : dark);
  }

  /// 시스템 설정 다크 모드 확인
  ///
  /// 사용자의 OS 설정에서 다크 모드를 사용하는지 확인합니다.
  ///
  /// 반환값: 다크 모드 사용 중이면 true
  ///
  /// 예시:
  /// ```dart
  /// if (CoUIThemeController.prefersDarkMode()) {
  ///   print('User prefers dark mode');
  /// }
  /// ```
  static bool prefersDarkMode() {
    return web.window.matchMedia('(prefers-color-scheme: dark)').matches;
  }

  /// 시스템 설정에 따라 테마 적용
  ///
  /// OS의 다크 모드 설정에 따라 자동으로 테마를 변경합니다.
  /// 다크 모드 사용 중이면 [dark], 아니면 [light]로 설정합니다.
  ///
  /// 예시:
  /// ```dart
  /// void main() {
  ///   // 앱 시작 시 시스템 설정 따르기
  ///   CoUIThemeController.useSystemPreference();
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  static void useSystemPreference() {
    final theme = prefersDarkMode() ? dark : light;
    setTheme(theme);
  }

  /// 시스템 설정 변경 감지
  ///
  /// OS의 다크 모드 설정이 변경될 때마다 콜백을 실행합니다.
  ///
  /// [callback]: 다크 모드 상태가 변경될 때 실행할 함수
  ///              (파라미터: isDark - 다크 모드 여부)
  ///
  /// 예시:
  /// ```dart
  /// void main() {
  ///   // 시스템 설정 변경 감지
  ///   CoUIThemeController.watchSystemPreference((isDark) {
  ///     print('System dark mode: $isDark');
  ///     // 자동으로 앱 테마 변경
  ///     CoUIThemeController.setTheme(isDark ? CoUIThemeController.dark : CoUIThemeController.light);
  ///   });
  ///
  ///   runApp(MyApp());
  /// }
  /// ```
  static void watchSystemPreference(void Function(bool isDark) callback) {
    final mediaQuery = web.window.matchMedia('(prefers-color-scheme: dark)');

    // 초기 상태 콜백
    callback(mediaQuery.matches);

    // 변경 감지
    mediaQuery.addEventListener(
      'change',
      (web.Event event) {
        final mediaQueryEvent = event as web.MediaQueryListEvent;
        callback(mediaQueryEvent.matches);
      }.toJS,
    );
  }

  /// 테마 이름을 한글로 변환
  ///
  /// [theme]: 테마 이름 (영문)
  /// 반환값: 한글 테마 이름
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
      _ => theme, // 알 수 없는 테마는 원본 반환
    };
  }

  /// 테마가 다크 계열인지 확인
  ///
  /// [theme]: 확인할 테마 이름
  /// 반환값: 다크 계열 테마면 true
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

  /// 커스텀 [CoreColorScheme]을 CSS 커스텀 프로퍼티로 적용합니다.
  ///
  /// [CoreThemeData]를 생성하고 [CssVariableGenerator.runtimeVars]를 통해
  /// 색(`--coui-{token}`)과 반경(`--coui-radius-*`) CSS 변수를 document
  /// root에 인라인으로 주입합니다.
  ///
  /// 글자 역할 변수(`--coui-text-*`)는 쓰지 않습니다. 인라인 선언은
  /// 스타일시트의 모든 규칙을 이기므로, 여기서 역할을 쓰면 스타일시트가 역할을
  /// 다시 진술하는 규칙(서페이스 스타일의 굵기 하한 등)이 이 호출 뒤로 모두
  /// 꺼집니다. 글자는 스타일시트를 만드는 자리(`ThemeConfig.typography`)에서
  /// 정합니다.
  ///
  /// [colorScheme]: 적용할 [CoreColorScheme].
  /// [brightness]: 라이트/다크 모드.
  /// [radiusScaling]: 전역 radius 스케일 인수.
  ///
  /// 예시:
  /// ```dart
  /// CoUIThemeController.setCustomTheme(
  ///   myColorScheme,
  ///   brightness: CoreBrightness.dark,
  /// );
  /// ```
  static void setCustomTheme(
    CoreColorScheme colorScheme, {
    CoreBrightness brightness = .light,
    double radiusScaling = 1.0,
  }) {
    final theme = CoreThemeData(
      colorScheme: colorScheme,
      brightness: brightness,
      designSystem: .coui,
      radiusScaling: radiusScaling,
    );
    final vars = CssVariableGenerator.runtimeVars(theme);
    final root = web.document.documentElement;
    if (root != null) {
      final htmlRoot = root as web.HTMLElement;
      for (final entry in vars.entries) {
        htmlRoot.style.setProperty(entry.key, entry.value);
      }
    }
  }
}
