/// 문서 내비게이션 사이드바 — jaspr 사이트와 같은 구조에서 나온 목록.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/shared/docs_navigation.dart';

/// 사이드바가 차지하는 가로 폭.
///
/// CoUI `Scaffold` 는 사이드바를 평범한 `Row` 자식으로 놓는다 — 폭 제약을
/// 주지 않으므로 사이드바가 스스로 정하지 않으면 가장 긴 링크 글자 폭으로
/// 벌어진다.
const double kDocsSidebarWidth = CoreSpace.space256;

/// 문서 내비게이션 사이드바.
///
/// 목록은 사이트 구조(`kDocsNavTabs`)에서 파생된다 — jaspr 사이트의 헤더
/// 탭 · 사이드바 · 페이저가 읽는 바로 그 구조다. 손으로 관리하는 두 번째
/// 목록을 두지 않는다.
///
/// 사이트는 탭마다 다른 사이드바를 보이지만, 이 앱에는 탭이 없다. 그래서
/// 탭의 이름을 구획의 머리로 두고 모든 탭의 묶음을 한 목록에 잇는다.
class DocsSidebar extends StatelessWidget {
  /// 사이드바를 만든다.
  const DocsSidebar({
    required this.currentPath,
    required this.onNavigate,
    super.key,
  });

  /// 지금 보고 있는 라우트 경로 (예: `/components/button`).
  final String currentPath;

  /// 링크를 눌렀을 때 그 경로로 호출된다.
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    // docs_site 사이드바는 우측 테두리가 없다(`border-right: 0`) — 본문과
    // 가르는 선을 그리지 않으므로 Divider 를 합성하지 않는다.
    return SizedBox(
      width: kDocsSidebarWidth,
      child: ScrollArea(
        child: Padding(
          padding: const .symmetric(
            vertical: CoreSpace.space16,
            horizontal: CoreSpace.space12,
          ),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            spacing: CoreSpace.space20,
            children: [
              for (final group in _docsNavGroups())
                _NavGroupView(
                  group: group,
                  currentPath: currentPath,
                  onNavigate: onNavigate,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 사이드바 링크 하나.
class _NavLink {
  const _NavLink({
    required this.label,
    required this.path,
    this.deprecated = false,
  });

  final String label;
  final String path;

  /// 카탈로그 엔트리의 파싱된 deprecation 상태에서 온다 — 손으로 세팅하지
  /// 않는다(비-컴포넌트 정적 링크는 항상 `false`). #3580.
  final bool deprecated;
}

/// 제목(선택) + 링크 묶음.
class _NavGroup {
  const _NavGroup({required this.links, this.title, this.section});

  /// 이 묶음이 탭의 첫 묶음일 때 그 탭의 이름 — 구획의 머리로 그려진다.
  final String? section;

  final String? title;
  final List<_NavLink> links;
}

/// 사이드바 전체 목록 — 사이트 구조의 탭 · 묶음 · 페이지 순서 그대로.
List<_NavGroup> _docsNavGroups() {
  return [
    for (final tab in kDocsNavTabs)
      for (final (index, group) in tab.groups.indexed)
        _NavGroup(
          links: [
            for (final page in group.pages)
              _NavLink(
                label: page.label,
                path: page.path,
                deprecated: page.deprecated,
              ),
          ],
          title: group.title,
          section: index == 0 ? tab.label : null,
        ),
  ];
}

class _NavGroupView extends StatelessWidget {
  const _NavGroupView({
    required this.group,
    required this.currentPath,
    required this.onNavigate,
  });

  final _NavGroup group;
  final String currentPath;
  final void Function(String path) onNavigate;

  @override
  Widget build(BuildContext context) {
    final title = group.title;
    final section = group.section;

    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      spacing: CoreSpace.space2,
      children: [
        if (section != null)
          Padding(
            padding: const .only(
              left: CoreSpace.space8,
              bottom: CoreSpace.space8,
            ),
            child: Text(section).titleSmall.onSurface,
          ),
        if (title != null)
          Padding(
            padding: const .only(
              left: CoreSpace.space8,
              bottom: CoreSpace.space4,
            ),
            child: Text(title).labelSmall.onSurfaceVariant.semiBold,
          ),
        for (final link in group.links)
          _NavLinkView(
            link: link,
            active: link.path == currentPath,
            onNavigate: onNavigate,
          ),
      ],
    );
  }
}

class _NavLinkView extends StatefulWidget {
  const _NavLinkView({
    required this.link,
    required this.active,
    required this.onNavigate,
  });

  final _NavLink link;
  final bool active;
  final void Function(String path) onNavigate;

  @override
  State<_NavLinkView> createState() => _NavLinkViewState();
}

class _NavLinkViewState extends State<_NavLinkView> {
  bool _hovered = false;

  /// Hover 는 Clickable 이 알려주고, 그 상태로 배경 토큰을 고른다.
  void handleHover({required bool hovered}) {
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final label = widget.link.label;

    final backgroundToken = switch ((widget.active, _hovered)) {
      (true, _) => const CoreColor.token(CoreColors.secondaryContainer),
      (false, true) => const CoreColor.token(CoreColors.surfaceContainerHigh),
      (false, false) => CoreColor.transparent,
    };

    final text = widget.active
        ? Text(label).labelMedium.onSurface.semiBold
        : Text(label).labelMedium.onSurfaceVariant;

    return Clickable(
      onPressed: () => widget.onNavigate(widget.link.path),
      onHover: (hovered) => handleHover(hovered: hovered),
      child: AnimatedContainer(
        padding: const .symmetric(
          vertical: CoreSpace.space6,
          horizontal: CoreSpace.space8,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.resolve(backgroundToken).toValue(),
          borderRadius: .circular(CoreRadius.radius6),
        ),
        duration: const Duration(milliseconds: CoreDuration.ms150),
        child: Row(
          children: [
            Expanded(
              child: Align(alignment: .centerLeft, child: text),
            ),
            // Active/Deprecated 를 시각적으로 분리한다 — 카탈로그의 파싱된
            // 상태에서 온다(손 관리 아님). #3580.
            if (widget.link.deprecated) ...[
              const Gap.space4(),
              Badge(
                variant: .outlined,
                child: const Text('Deprecated').labelSmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
