/// 문서 브라우저의 크롬 — 앱바 + 사이드바, 그리고 페이지 한 장의 틀(본문 + 목차).
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_heading.dart';
import 'package:docs_app/src/shell/docs_sidebar.dart';
import 'package:docs_app/src/shell/docs_toc.dart';
import 'package:docs_app/src/shell/theme_mode_controller.dart';

/// 목차를 붙이기 시작하는 본문 영역 폭.
///
/// 사이드바를 뺀 *본문* 폭 기준이다 — 뷰포트 기준이 아니다.
const CoreBreakpoint kDocsTocBreakpoint = .lg;

/// 문서 페이지들을 감싸는 앱 셸 — 앱바와 사이드바.
///
/// 셸은 한 번 서고 그 안에서 페이지만 바뀐다. 그래서 새 페이지가 화면
/// 전환으로 들어오는 동안 앱바와 사이드바는 제자리에 있다.
class DocsShell extends StatelessWidget {
  /// 셸을 만든다.
  const DocsShell({
    required this.currentPath,
    required this.onNavigate,
    required this.child,
    this.onSearch,
    super.key,
  });

  /// 지금 보고 있는 라우트 경로 — 사이드바의 활성 항목을 고른다.
  final String currentPath;

  /// 사이드바 링크를 눌렀을 때 그 경로로 호출된다.
  final void Function(String path) onNavigate;

  /// 페이지가 서는 자리 — 라우터의 페이지 스택.
  final Widget child;

  /// 검색 버튼 핸들러. `null` 이면 버튼을 그리지 않는다.
  final VoidCallback? onSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: [
        AppBar(
          title: const Text('CoUI').titleMedium.semiBold,
          trailing: [
            if (onSearch != null)
              Button(
                onPressed: onSearch,
                variant: .ghost,
                size: .sm,
                child: const Icon(LucideIcons.search),
              ),
            const DocsThemeModeToggle(),
          ],
        ),
      ],
      sidebar: DocsSidebar(currentPath: currentPath, onNavigate: onNavigate),
      child: child,
    );
  }
}

/// 문서 페이지 한 장의 틀 — 스크롤되는 본문, 넓은 화면에서는 오른쪽의 목차.
///
/// 페이지마다 하나라서 새 페이지는 맨 위에서 시작하고, 목차는 본문과 함께
/// 들어온다.
class DocsPageFrame extends StatelessWidget {
  /// 틀을 만든다.
  const DocsPageFrame({
    required this.child,
    this.headings = const [],
    this.onHeadingTap,
    super.key,
  });

  /// 페이지 본문.
  final Widget child;

  /// 목차에 그릴 헤딩들. 비어 있으면 목차를 붙이지 않는다.
  final List<DocsHeading> headings;

  /// 목차 항목을 눌렀을 때 호출된다.
  ///
  /// 헤딩 → 스크롤 오프셋을 아는 건 본문을 그리는 쪽이라, 틀은 그 결정을
  /// 하지 않고 콜백만 위로 넘긴다. `null` 이면 목차는 읽기 전용이 된다.
  final void Function(DocsHeading)? onHeadingTap;

  /// 목차 항목 탭을 [onHeadingTap] 으로 넘긴다. 핸들러가 없으면 무시한다.
  void handleHeadingTap(DocsHeading heading) => onHeadingTap?.call(heading);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final showToc =
            headings.isNotEmpty &&
            constraints.maxWidth >= kDocsTocBreakpoint.minWidth;

        return Row(
          crossAxisAlignment: .stretch,
          children: [
            Expanded(
              child: ScrollArea(
                // docs_site 본문(`.content-container`)은 좌우 여백을 갖는다
                // (콘텐츠가 사이드바·목차에 붙지 않게) — 같은 폭을 준다.
                child: Padding(
                  padding: const .symmetric(horizontal: CoreSpace.space40),
                  child: child,
                ),
              ),
            ),
            if (showToc) DocsToc(onTap: handleHeadingTap, headings: headings),
          ],
        );
      },
    );
  }
}
