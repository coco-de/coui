/// 번들된 `docs_site` 콘텐츠를 asset 에서 읽는다.
library;

import 'package:docs_app/src/content/docs_page.dart';
import 'package:docs_app/src/content/docs_route.dart';
import 'package:flutter/services.dart' show AssetBundle, AssetManifest;

/// 문서 라우트를 찾고 페이지를 읽는다.
///
/// 콘텐츠는 `docs_site` 패키지의 asset 이므로 사본이 없다 — jaspr 사이트가
/// 서빙하는 것과 **똑같은** 마크다운 파일을 읽는다.
class DocsContentRepository {
  /// 주어진 번들에서 읽는 저장소를 만든다.
  DocsContentRepository(this._bundle);
  final AssetBundle _bundle;
  Map<String, DocsRoute> _routesByPath = const {};
  Map<String, DocsPage> _cache = const {};
  bool _loaded = false;

  /// 해석된 라우트 — 경로순 정렬.
  List<DocsRoute> get routes {
    final list = _routesByPath.values.toList()
      ..sort((a, b) => a.path.compareTo(b.path));
    return list;
  }

  /// Asset 매니페스트를 훑어 라우트 테이블을 만든다.
  ///
  /// 매니페스트를 쓰므로 파일 목록을 손으로 관리할 필요가 없다 — 콘텐츠에
  /// md 를 추가하면 docs_app 이 자동으로 집는다.
  Future<void> load() async {
    if (_loaded) return;
    final manifest = await AssetManifest.loadFromAssetBundle(_bundle);
    _routesByPath = {
      for (final route in manifest.listAssets().map(resolveDocsRoute).nonNulls)
        route.path: route,
    };
    _loaded = true;
  }

  /// 이 경로에 라우트가 있나?
  bool hasRoute(String path) => _routesByPath.containsKey(path);

  /// 경로의 페이지를 읽고 파싱한다. 라우트가 없으면 `null`.
  Future<DocsPage?> page(String path) async {
    final cached = _cache[path];
    if (cached != null) return cached;

    final route = _routesByPath[path];
    if (route == null) return null;

    final source = await _bundle.loadString(route.assetKey);
    final parsed = parseDocsPage(path: path, source: source);
    _cache = {..._cache, path: parsed};
    return parsed;
  }
}
