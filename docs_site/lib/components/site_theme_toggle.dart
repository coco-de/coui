/// 헤더의 밝기 토글 — CoUI `Button`.
///
/// ## 밝기는 이 토글이 갖는다
///
/// 문서의 밝기 속성(`data-theme`)은 이 토글의 상태에서 **선언**된다
/// (`Document.html`). `<html>` 에 대한 선언은 페이지의 모든 island 이 함께
/// 맞춰지는데, 어느 island 이든 다시 그려지면 아무도 선언하지 않은 속성은
/// 페이지가 시작했을 때의 값으로 돌아간다. 그래서 속성을 DOM 에 직접 쓰기만
/// 하면 화면이 어두워졌다가, 검색 팔레트가 열리는 순간 다시 밝아진다.
/// 선언이 있으면 그 값이 남는다.
///
/// 다른 컨트롤(랜딩의 테마 스위치)은 속성을 쓰지 않고 이 토글을 누른다
/// (`site_theme_dom_web.dart` 의 `toggleSiteTheme`).
///
/// ## 왜 island 인가, 그리고 왜 인라인 스크립트가 따로 있나
///
/// 누름은 상태를 바꾸므로 브라우저에서 돌아야 한다. 하지만 밝기의 **첫
/// 값**은 island 가 뜨기 전에 정해져야 한다 — 클라이언트 번들이 뜬 뒤에
/// 정하면 페이지를 옮길 때마다 밝은 면이 먼저 그려졌다가 어두워진다. 그래서
/// 저장된 값을 문서 속성에 적는 일은 `<head>` 의 인라인 스크립트
/// ([kSiteThemeRestoreScript])가 첫 페인트 전에 하고, 이 island 는 그
/// 속성을 읽어 시작한다.
///
/// ## 서버는 값을 모른다
///
/// 밝기는 브라우저가 정한다(저장된 선택, 없으면 OS 설정). 서버가 그린
/// 아이콘은 아는 값이 아니라 빈 값이라, island 가 실제 값을 읽을 때까지
/// 감춘다 — 틀린 아이콘을 보였다가 뒤집는 것보다 아는 순간에 그리는 편이
/// 낫다. 같은 이유로 서버는 속성을 선언하지 않는다: 선언하면 저장된 선택이
/// 어두운 사람에게 밝은 면이 먼저 간다.
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/docs_locale.dart';

import 'site_theme_dom.dart';

/// 첫 페인트 전에 밝기를 문서 속성에 적는 스크립트.
///
/// 저장된 선택이 있으면 그것, 없으면 OS 의 밝기다. 속성 이름과 저장 키는
/// `site_theme_dom_web.dart` 가 읽고 쓰는 것과 같다.
const String kSiteThemeRestoreScript =
    '(function(){var d=document.documentElement,t=null;'
    'try{t=localStorage.getItem("$kSiteThemeStorageKey")}catch(e){}'
    'if(t!=="dark"&&t!=="light")'
    't=matchMedia("(prefers-color-scheme: dark)").matches?"dark":"light";'
    'd.setAttribute("$kSiteThemeAttribute",t)})()';

/// 헤더의 밝기 토글.
@client
class SiteThemeToggle extends StatefulComponent {
  /// 토글을 만든다.
  const SiteThemeToggle({super.key});

  @override
  State<SiteThemeToggle> createState() => _SiteThemeToggleState();
}

class _SiteThemeToggleState extends State<SiteThemeToggle> {
  bool _dark = false;
  void Function()? _stopListening;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    _dark = readDarkTheme();
    // 이 토글이 깨어나기 전에 누가 속성을 썼다면(랜딩의 스위치가 그
    // 틈에 눌렸다면) 그 값을 따라간다.
    _stopListening = observeTheme(_handleThemeChanged);
  }

  @override
  void dispose() {
    _stopListening?.call();
    _stopListening = null;
    super.dispose();
  }

  void _handleThemeChanged() {
    final dark = readDarkTheme();
    if (dark != _dark) setState(() => _dark = dark);
  }

  void _handlePressed() {
    final dark = !_dark;
    rememberSiteTheme(dark: dark);
    // 속성은 여기서 쓰지 않는다 — 아래 `build` 의 선언이 쓴다.
    setState(() => _dark = dark);
  }

  @override
  Component build(BuildContext context) {
    // island 는 서버가 렌더한 페이지의 `Theme` 조상을 물려받지 않는다 —
    // `Button` 이 `Theme.of(context)` 를 읽으므로 자기 `CoUIWeb` 로 감싼다.
    return Component.fragment([
      // 브라우저에서만 선언한다 — 서버는 값을 모른다(위 문서).
      Document.html(
        attributes: {if (kIsWeb) kSiteThemeAttribute: _dark ? 'dark' : 'light'},
      ),
      _button(),
    ]);
  }

  Component _button() {
    return CoUIWeb(
      theme: ThemeData.coui,
      locale: const Locale(kDocsLanguageCode),
      child: Button(
        variant: CoreButtonVariant.outline,
        size: CoreComponentSize.sm,
        shape: CoreButtonShape.square,
        // 도구 줄의 높이와 선 — 검색 상자 · 스타일 고르기와 같은 높이,
        // 같은 테두리(`outlineSubtle`)다.
        buttonStyle: const CoreButtonStyle(
          height: CoreSize.size36,
          width: CoreSize.size36,
          borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
          borderColor: CoreColor.token(CoreColors.outlineSubtle),
          hoverBorderColor: CoreColor.token(CoreColors.outlineSubtle),
        ),
        classes: kSiteThemeToggleClass,
        // 서버가 그린 값은 아는 값이 아니다 — 브라우저에서 읽은 뒤에 보인다.
        css: kIsWeb ? null : const Styles(raw: {'visibility': 'hidden'}),
        attributes: {'aria-label': _dark ? '밝은 테마로 전환' : '어두운 테마로 전환'},
        onPressed: _handlePressed,
        child: Icon(
          _dark ? LucideIcons.sun : LucideIcons.moon,
          iconStyle: const CoreIconStyle(size: CoreIconSize.size18),
        ),
      ),
    );
  }
}
