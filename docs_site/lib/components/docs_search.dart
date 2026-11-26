/// 전역 검색 팔레트 — `Cmd+K` / `Ctrl+K` 또는 헤더의 검색 버튼으로 연다.
///
/// docs_app(Flutter, `app/docs_app/lib/src/search/docs_search.dart`)과 같은
/// 공유 인덱스(`docs_core/lib/shared/docs_search_index.dart`)를 읽는다 —
/// 검색 결과 목록이 플랫폼마다 갈라지지 않는다. #3577.
///
/// `@client` island 다: 열림/질의 상태와 키보드 리스너가 진짜 상태를 필요로
/// 하고, `Command`(coui_web)가 이미 검색 팔레트의 필터링·키보드 탐색을
/// 구현해 두고 있어 재사용하는 쪽이 손 구현보다 정확하다. hydration 이
/// 끝나기 전까지 `Cmd+K`/클릭이 반응하지 않는 짧은 창이 있다 — 이 사이트의
/// `SurfaceStyleSwitcher` 처럼 hydration-전 반응이 필요한 라이브 테마
/// 전환과 달리, 검색은 그 창이 사용자 경험을 깨지 않는다(문서 사이트에서
/// 첫 상호작용 전까지 dart2js 번들은 이미 로드돼 있는 게 보통이다).
library;

import 'package:coui_web/coui_web.dart';
import 'package:docs_core/shared/docs_search_index.dart';

import '../web_navigation.dart';
import 'package:docs_core/shared/docs_locale.dart';

/// 검색 트리거에 보이는 안내 — 트리거의 이름이기도 하다.
const String kDocsSearchPlaceholder = '컴포넌트, 토큰 검색';

/// 전역 검색 트리거 + 팔레트.
@client
class DocsSearch extends StatefulComponent {
  /// 검색 island 를 만든다.
  const DocsSearch({super.key});

  @override
  State<DocsSearch> createState() => _DocsSearchState();
}

class _DocsSearchState extends State<DocsSearch> {
  bool _open = false;
  String _query = '';
  void Function()? _disposeShortcut;

  @override
  void initState() {
    super.initState();
    // `SSR-safe` 리스너 — 서버에서는 inert no-op, 브라우저에서만 실제
    // document keydown 을 청취한다(popover_dom.dart 의 조건부 export).
    _disposeShortcut = registerDocumentShortcutListener(({
      required key,
      required metaKey,
      required ctrlKey,
      required preventDefault,
    }) {
      final isShortcut = (metaKey || ctrlKey) && key.toLowerCase() == 'k';
      if (!isShortcut) return;
      preventDefault();
      handleOpen();
    });
  }

  @override
  void dispose() {
    _disposeShortcut?.call();
    _disposeShortcut = null;
    super.dispose();
  }

  void handleOpen() {
    if (_open) return;
    setState(() => _open = true);
  }

  void handleClose() {
    setState(() {
      _open = false;
      _query = '';
    });
  }

  void handleQueryChanged(String query) {
    setState(() => _query = query);
  }

  void handleSelect(String slug) {
    // `Router.of(context)` 는 여기서 못 쓴다 — `@client` island 는
    // `main.server.dart` 의 `ContentApp` 라우터 조상과 별개로 hydrate 되어
    // (Theme 과 같은 문제, 위 build() 의 CoUIWeb 재감싸기 참고) 그 조상이
    // 없다. 전체 페이지 이동으로 대신한다 — `web_navigation.dart` 가
    // SSR-safe 하게 감싼다(`package:web` 직접 import 는 서버 컴파일
    // 대상을 깬다).
    navigateToPath(docsSearchPath(slug));
  }

  @override
  Component build(BuildContext context) {
    // `@client` island 는 독립적으로 hydrate 된다 — 서버가 렌더한 페이지
    // 전체(`main.server.dart` 의 `CoUIWeb`)가 주는 `Theme` 조상을 물려받지
    // 않는다. `Button`/`Dialog`/`Command` 는 전부 `Theme.of(context)` 를
    // 읽으므로, 이 island 자신의 `CoUIWeb` 로 다시 감싼다 — `WebPreview`
    // (`docs_core/lib/components/web_preview.dart`)가 이미 쓰는 것과 같은
    // 패턴. `CoUIWeb` 은 `<div class="coui-root w-full …">` 래퍼를 하나
    // 낸다 — 헤더의 도구 줄에서 늘어나지 않게 시트가 그 폭을 내용에
    // 맞춘다(`docs-shell.css` 의 `.site-tools > .coui-root`).
    return CoUIWeb(
      theme: ThemeData.coui,
      locale: const Locale(kDocsLanguageCode),
      child: Component.fragment([
        // 검색 입력처럼 보이는 트리거 — 킷의 `SidebarSearch` 다. 실제 입력은
        // 열린 팔레트 안에 있고, 이 상자는 그것을 여는 버튼이다.
        SidebarSearch(
          placeholder: kDocsSearchPlaceholder,
          shortcut: const ['⌘K'],
          attributes: const {'aria-keyshortcuts': 'Meta+K Control+K'},
          sidebarSearchStyle: const CoreSidebarSearchStyle(
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
            padding: CoreEdgeInsets.directional(start: CoreSpace.space12, end: CoreSpace.space8),
            kbdStyle: CoreKbdStyle(
              keyRadius: CoreBorderRadius.all(CoreRadius.radius6),
              keyBackgroundColor: CoreColor.token(CoreColors.surface),
              keyBorderColor: CoreColor.token(CoreColors.outlineSubtle),
              keyBorderWidth: CoreStrokeWidth.stroke1,
              keyTextStyle: CoreTextStyle.token(
                CoreTextStyles.codeXs,
                color: CoreColor.token(CoreColors.onSurfaceVariant),
              ),
            ),
          ),
          classes: 'docs-search-trigger',
          onPressed: handleOpen,
        ),
        Dialog(
          open: _open,
          onClose: handleClose,
          content: Command(
            query: _query,
            onQueryChanged: handleQueryChanged,
            onSelect: handleSelect,
            groups: [
              for (final group in buildDocsSearchIndex())
                CoreCommandGroup<Component>(
                  heading: group.heading,
                  items: [
                    for (final item in group.items)
                      CoreCommandItem<Component>(
                        value: item.value,
                        label: item.label,
                        keywords: item.keywords,
                      ),
                  ],
                ),
            ],
          ),
          // `Command` already paints its own background / border /
          // 20px corner radius (the modal role, same as `Dialog`'s own
          // panel) — it's designed to BE the visible surface
          // wherever it's mounted, not float inside a second one.
          // Without this the panel's default 24px padding + the
          // unconditional pre-content section gap (16px, meant to
          // separate a header from the body — this dialog has no
          // header) stack into 40px of empty frame around Command,
          // plus a redundant second border. Zeroing them here — not
          // in `Command`/`Dialog` themselves — mirrors shadcn's
          // `CommandDialog`, which gives `DialogContent` its own
          // `overflow-hidden p-0` rather than stripping `Command`'s
          // or `Dialog`'s general-purpose defaults.
        ).withStyle(
          const CoreDialogStyle(
            panelPadding: CoreEdgeInsets.zero,
            panelBorderWidth: 0,
            sectionGapStyle: CoreGapStyle(size: 0),
          ),
        ),
      ]),
    );
  }
}
