/// 콘텐츠가 쓰는 커스텀 태그는 전부 등록돼 있어야 한다.
///
/// ## 왜 이 파일이 있나
///
/// 마크다운 렌더러는 **모르는 태그를 조용히 버린다**:
///
/// ```dart
/// // block_renderer.dart
/// final built = registry.builderFor(match.tag.name)?.call(context, tag);
/// if (built != null) blocks.add(built);
/// ```
///
/// 에러도 경고도 없다. 그래서 Web 쪽에서 새 태그를 만들고 여기 등록하지
/// 않으면, 그 태그가 있는 페이지는 네이티브 앱에서 **그 자리만 사라진
/// 채** 렌더된다. 페이지 내용이 그 태그뿐이면 빈 화면이 된다.
///
/// 실제로 그렇게 됐다 — 랜딩(`index.md`)을 `<SiteHero />` +
/// `<SiteShowcase />` 두 태그로 바꾸면서 Web 쪽만 구현했고, 네이티브
/// 홈이 통째로 비었다. 옆의 `markdown_test.dart` 는 이걸 못 잡는다:
/// 그 파일의 레지스트리는 **손으로 쓴 스텁 목록**이라, 콘텐츠에 새 태그가
/// 생겨도 목록이 따라오지 않고 렌더는 조용히 성공한다.
///
/// 여기서는 반대로 간다 — 목록을 콘텐츠에서 **읽어** 실제 레지스트리와
/// 대조한다. 그래서 새 태그를 쓰는 순간 이 테스트가 먼저 빨개진다.
library;

import 'dart:io';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';
import 'package:docs_app/src/markdown/tags/docs_tags.dart';
import 'package:flutter_test/flutter_test.dart';

/// 콘텐츠 루트 — 테스트 작업 디렉터리 기준.
const _kContentRoot = '../../docs_core/content';

/// 이미 등록돼 있지 않은 태그 — ratchet baseline.
///
/// 새 미등록 태그는 막고, 여기 적힌 것만 통과시킨다. **이 목록이
/// 길어지는 것은 "네이티브 문서가 Web 문서보다 적게 보여 준다" 가
/// 늘어난다는 뜻**이고, 그건 두 표면이 같은 콘텐츠를 읽는다는 전제 자체를
/// 무너뜨린다. 이름을 얹어 넘어가지 말고 등록한다.
///
///
/// 지금은 비어 있다 — 콘텐츠가 쓰는 태그는 전부 네이티브에도 있다.
const Set<String> _kKnownUnregistered = {};

List<File> _contentFiles() => Directory(_kContentRoot)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.md'))
    .toList();

void main() {
  test('콘텐츠가 쓰는 모든 커스텀 태그가 등록돼 있다', () {
    final registry = buildDocsTagRegistry(
      onInternalLink: (_) {},
      // `LivePreview` 는 이 파일이 소유하지 않아 주입받는다 — 주입하지
      // 않으면 등록되지 않으므로, 커버리지 검사에서는 자리를 채운다.
      livePreviewBuilder: (context, tag) => const Gap.space4(),
    );

    final missing = <String, Set<String>>{};

    for (final file in _contentFiles()) {
      final source = file.readAsStringSync();
      for (final match in findDocsTags(source)) {
        final name = match.tag.name;
        if (_kKnownUnregistered.contains(name)) continue;
        if (registry.contains(name)) continue;
        missing
            .putIfAbsent(name, () => <String>{})
            .add(
              file.path.replaceFirst('$_kContentRoot/', ''),
            );
      }
    }

    expect(
      missing,
      isEmpty,
      reason:
          '등록되지 않은 태그는 렌더러가 조용히 버린다 — 그 페이지는 '
          '네이티브 앱에서 그 자리가 빈 채로 나온다. baseline 에 이름을 '
          '얹지 말고 등록할 것.\n'
          '${missing.entries.map((e) => '  <${e.key} /> ← ${e.value.join(', ')}').join('\n')}',
    );
  });

  test('baseline 이 죽지 않았다', () {
    // 등록이 되면 이 목록에서 빼야 한다. 빼지 않으면 baseline 이
    // 조용히 자라고, 다음 사람이 그걸 정상으로 읽는다.
    final registry = buildDocsTagRegistry(onInternalLink: (_) {});
    final stale = _kKnownUnregistered.where(registry.contains).toList();

    expect(
      stale,
      isEmpty,
      reason: '이제 등록된 태그가 baseline 에 남아 있다: \$stale',
    );
  });

  test('콘텐츠 파일이 실제로 스캔됐다', () {
    // 경로가 틀리면 위 테스트는 빈 집합을 비교하며 **항상 통과**한다.
    // 스캔이 일어났다는 것을 따로 단언한다.
    expect(_contentFiles().length, greaterThan(50));
  });
}
