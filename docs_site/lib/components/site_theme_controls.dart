/// 랜딩 테마 타일의 토글 셋 — 다크 모드 · 고대비 · 모션 줄이기.
///
/// `@client` island 다. 토글은 켜짐 상태를 갖고, CoUI `Toggle` 은 그
/// 상태를 hydration 뒤에야 받는다. 서버 렌더는 셋 다 꺼진 모습으로
/// 나가고, 브라우저에서 문서와 OS 의 실제 값을 읽어 맞춘다.
///
/// ## 셋은 같은 종류의 스위치가 아니다
///
/// **다크 모드**는 사이트의 설정이다. 헤더의 토글이 그 상태를 소유하므로
/// 이 타일은 그 토글을 누르고, 문서 속성을 지켜보며 따라간다 — 상태를
/// 두 곳에 두지 않는다.
///
/// **고대비**와 **모션 줄이기**는 OS 의 설정이다. 킷은 그 둘을 미디어
/// 쿼리로만 받으므로, 여기서 켜는 것은 설정이 아니라 **이 페이지의
/// 미리보기**다: 그 미디어 쿼리 아래의 규칙을 그대로 꺼내 적용한다
/// (`previewMediaFeature`). OS 에서 이미 켜져 있으면 토글은 켜진 채
/// 잠긴다 — 페이지가 OS 설정을 끌 수는 없다.
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/docs_locale.dart';

import 'site_theme_dom.dart';

/// 대비를 높여 달라는 OS 설정.
const String _kContrastFeature = 'prefers-contrast: more';

/// 동작을 줄여 달라는 OS 설정.
const String _kReducedMotionFeature = 'prefers-reduced-motion: reduce';

/// 미리보기 토글이 무엇을 하는지.
const String _kPreviewNote = '고대비와 모션 줄이기는 이 페이지에서만 미리 봅니다. 앱에서는 OS 접근성 설정을 따릅니다.';

/// OS 에서 이미 켜진 설정의 토글에 붙는 설명.
const String _kSystemNote = 'OS 접근성 설정에서 켜져 있습니다.';

/// island 가 브라우저의 값을 읽었다는 표시 — 시트가 이것으로 줄을 드러낸다.
const String _kReadyAttribute = 'data-ready';

/// 사이트 표지색(`--site-accent`, `web/docs-shell.css`)의 밝은 쪽.
///
/// 표지색은 킷의 토큰이 아니라 사이트가 갖는 색이라 `CoreColor` 가
/// 이름으로 가리킬 수 없다. 값은 시트의 그 줄과 같아야 한다 —
/// `landing_motion_test.dart` 가 둘을 대조한다.
const int kSiteAccentLight = 0xFF167463;

/// 사이트 표지색의 어두운 쪽.
const int kSiteAccentDark = 0xFF5BE0C8;

/// 토글의 칠 — 시안은 켜진 트랙을 표지색, 손잡이를 흰색으로 그린다.
///
/// 꺼진 트랙은 밝기마다 다른 토큰이다. 킷의 기본
/// (`surface-container-highest`)은 다크에서 이 줄이 놓인 면
/// (`surface-raised`)과 같은 단계라 트랙이 면에 묻힌다. 한 토큰으로 적을
/// 수 없으므로 island 가 아는 밝기로 고른다.
///
/// 대비를 높여 달라는 요청에서는 시트가 표지색을 본문색으로 바꾸듯,
/// 켜진 트랙을 킷의 기본으로 돌린다 — 색 하나에 기대지 않는다.
CoreToggleStyle _toggleStyle({required bool dark, required bool contrast}) {
  return CoreToggleStyle(
    trackActiveColor: contrast ? null : CoreColor(dark ? kSiteAccentDark : kSiteAccentLight),
    trackInactiveColor: CoreColor.token(dark ? CoreColors.surfaceContainerHigh : CoreColors.outlineVariant),
    thumbActiveColor: contrast ? null : const CoreColor(0xFFFFFFFF),
  );
}

/// 테마 타일의 토글 셋.
@client
class SiteThemeControls extends StatefulComponent {
  /// 토글 island 를 만든다.
  const SiteThemeControls({super.key});

  @override
  State<SiteThemeControls> createState() => _SiteThemeControlsState();
}

class _SiteThemeControlsState extends State<SiteThemeControls> {
  bool _dark = false;
  bool _contrastPreview = false;
  bool _motionPreview = false;
  bool _systemContrast = false;
  bool _systemReducedMotion = false;

  final List<void Function()> _stopListening = [];

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    _dark = readDarkTheme();
    _systemContrast = matchesMediaFeature(_kContrastFeature);
    _systemReducedMotion = matchesMediaFeature(_kReducedMotionFeature);

    _stopListening
      ..add(observeTheme(_handleThemeChanged))
      ..add(observeMediaFeature(_kContrastFeature, _handleSystemChanged))
      ..add(observeMediaFeature(_kReducedMotionFeature, _handleSystemChanged));
  }

  @override
  void dispose() {
    for (final stop in _stopListening) {
      stop();
    }
    // 미리보기는 이 island 의 것이다 — 떠날 때 걷어 간다.
    previewMediaFeature(_kContrastFeature, enabled: false);
    previewMediaFeature(_kReducedMotionFeature, enabled: false);
    super.dispose();
  }

  void _handleThemeChanged() {
    final dark = readDarkTheme();
    if (dark != _dark) setState(() => _dark = dark);
  }

  void _handleSystemChanged() {
    setState(() {
      _systemContrast = matchesMediaFeature(_kContrastFeature);
      _systemReducedMotion = matchesMediaFeature(_kReducedMotionFeature);
    });
  }

  // 값은 받지 않는다 — 헤더 토글이 뒤집고, 문서 속성이 바뀌면
  // [_handleThemeChanged] 가 그 결과를 읽어 온다.
  void _handleDarkChanged(bool _) => toggleSiteTheme();

  void _handleContrastChanged(bool enabled) {
    previewMediaFeature(_kContrastFeature, enabled: enabled);
    setState(() => _contrastPreview = enabled);
  }

  void _handleMotionChanged(bool enabled) {
    previewMediaFeature(_kReducedMotionFeature, enabled: enabled);
    setState(() => _motionPreview = enabled);
  }

  @override
  Component build(BuildContext context) {
    // island 는 서버가 렌더한 페이지의 `Theme` 조상을 물려받지 않는다 —
    // `Toggle` 이 `Theme.of(context)` 를 읽으므로 자기 `CoUIWeb` 로 감싼다.
    return CoUIWeb(
      theme: ThemeData.coui,
      locale: const Locale(kDocsLanguageCode),
      child: div(
        classes: 'site-theme-rows',
        // 브라우저에서 실제 값을 읽은 뒤에만 붙는다. 시트는 이 표시가 없는
        // 동안 줄을 감춘다 — 서버가 그린 "꺼짐" 은 아는 값이 아니라 빈 값이다.
        attributes: const {if (kIsWeb) _kReadyAttribute: ''},
        [
          _row(label: '다크 모드', value: _dark, onChanged: _handleDarkChanged),
          _row(
            label: '고대비',
            value: _systemContrast || _contrastPreview,
            onChanged: _handleContrastChanged,
            system: _systemContrast,
          ),
          _row(
            label: '모션 줄이기',
            value: _systemReducedMotion || _motionPreview,
            onChanged: _handleMotionChanged,
            system: _systemReducedMotion,
          ),
          // 스위치 뒤에 읽히는 설명. `Toggle` 은 호출자의 속성을 받지
          // 않아 `aria-describedby` 로 묶을 수 없으므로, 읽는 순서로 둔다.
          p(classes: 'site-sr-only', [Text(_kPreviewNote)]),
        ],
      ),
    );
  }

  /// 토글 한 줄 — 이름이 왼쪽, 스위치가 오른쪽.
  ///
  /// 이름은 `prefix` 로 넣는다. `Toggle` 의 루트가 줄 전체라 줄 어디를
  /// 눌러도 뒤집히고, 스위치의 접근 가능한 이름이 이 글자에서 온다.
  ///
  /// [system] 이 참이면 OS 가 이미 켠 설정이라 잠긴다.
  Component _row({
    required String label,
    required bool value,
    required void Function(bool value) onChanged,
    bool system = false,
  }) {
    return div(
      classes: 'site-theme-row',
      attributes: {if (system) 'title': _kSystemNote},
      [
        Toggle(
          value: value,
          onChanged: onChanged,
          enabled: !system,
          size: CoreComponentSize.lg,
          toggleStyle: _toggleStyle(dark: _dark, contrast: _systemContrast || _contrastPreview),
          prefix: Text(label).labelXl.onSurface,
        ),
      ],
    );
  }
}
