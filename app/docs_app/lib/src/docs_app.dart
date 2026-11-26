/// 앱 루트 — 라우터 · 테마 · 콘텐츠 저장소를 배선한다.
library;

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/content/content_repository.dart';
import 'package:docs_app/src/page/docs_page_view.dart';
import 'package:docs_app/src/search/docs_search.dart';
import 'package:docs_app/src/shell/docs_shell.dart';
import 'package:docs_app/src/shell/theme_mode_controller.dart';
import 'package:docs_core/shared/docs_navigation.dart';
import 'package:go_router/go_router.dart';

/// CoUI 문서 앱.
///
/// 라우트는 콘텐츠 자체에서 온다 — `docs_site` 가 소유한 마크다운 asset 을
/// 훑어서 만든다. 그래서 문서 페이지를 추가해도 여기엔 손댈 게 없다.
class DocsApp extends StatefulWidget {
  /// 앱을 만든다.
  const DocsApp({required this.repository, super.key});

  /// 콘텐츠를 읽어올 저장소 — 미리 [DocsContentRepository.load] 된 상태여야 한다.
  final DocsContentRepository repository;

  @override
  State<DocsApp> createState() => _DocsAppState();
}

class _DocsAppState extends State<DocsApp> {
  final _themeMode = DocsThemeModeController();
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _router = _buildRouter();
  }

  GoRouter _buildRouter() {
    return GoRouter(
      redirect: (_, state) => kDocsMovedPaths[state.uri.path],
      routes: [
        // 셸(앱바 · 사이드바)은 한 번 서고 그 안에서 문서 페이지만 바뀐다 —
        // 새 페이지가 화면 전환으로 들어오는 동안 셸은 제자리에 있다.
        ShellRoute(
          builder: (context, state, child) => DocsShell(
            currentPath: state.uri.path,
            onNavigate: _handleNavigate,
            onSearch: () => _handleSearch(context),
            child: child,
          ),
          routes: [
            // 라우트는 하나뿐이고 경로 전체를 잡는다. docs_site 의 URL 을
            // 그대로 쓰는 게 목표라, 라우트를 손으로 나열하는 대신 콘텐츠
            // 저장소가 경로를 해석하게 둔다 — 마크다운을 추가하면 자동으로
            // 살아난다.
            GoRoute(
              path: '/:path(.*)',
              pageBuilder: (context, state) {
                // 경로는 URI 에서 곧장 읽는다 — path 파라미터를 재조립하면
                // 루트에서 `//` 가 나온다.
                final path = state.uri.path;

                return RoutePage<void>(
                  // 패턴이 하나뿐이라 `state.pageKey` 는 모든 문서에서
                  // 같다. 경로로 키를 주어야 문서마다 새 페이지로 들어온다.
                  key: ValueKey(path),
                  child: DocsPageView(
                    repository: widget.repository,
                    path: path,
                    onNavigate: _handleNavigate,
                  ),
                );
              },
            ),
          ],
        ),
      ],
      initialLocation: '/',
    );
  }

  void _handleNavigate(String path) => _router.go(path);

  void _handleSearch(BuildContext context) =>
      unawaited(showDocsSearch(context, onNavigate: _handleNavigate));

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DocsThemeModeScope(
      controller: _themeMode,
      child: ListenableBuilder(
        listenable: _themeMode,
        builder: (context, _) {
          return CoUIApp.router(
            darkTheme: ThemeData.fromCore(CoreThemePresets.previewDark),
            debugShowCheckedModeBanner: false,
            routerConfig: _router,
            // 문서 셸은 어느 플랫폼에서도 같은 크기로 그린다. 배율을
            // CoUIApp 의 기본값에 맡기지 않고 명시한다.
            scaling: .desktop,
            theme: ThemeData.fromCore(CoreThemePresets.previewLight),
            themeMode: _themeMode.value,
            title: 'CoUI Docs',
          );
        },
      ),
    );
  }
}
