/// 커스텀 태그 이름 → 위젯 빌더 레지스트리.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag.dart';

/// 커스텀 태그 하나를 위젯으로 만든다.
///
/// `null` 을 주면 렌더러가 그 태그를 조용히 건너뛴다 — 속성이 모자라거나
/// 이 태그를 이 문맥에서 그릴 수 없을 때 쓴다.
typedef DocsTagBuilder = Widget? Function(BuildContext context, DocsTag tag);

/// 태그 이름으로 [DocsTagBuilder] 를 찾는다.
///
/// 이름은 대소문자를 구분한다 — 콘텐츠가 `LivePreview` / `TabItem` 처럼
/// 파스칼 케이스로 쓰므로 그대로 맞춘다.
class DocsTagRegistry {
  /// 레지스트리를 만든다.
  const DocsTagRegistry(this.builders);

  /// 아무 태그도 모르는 레지스트리 — 전부 건너뛴다.
  const DocsTagRegistry.empty() : builders = const {};

  /// 태그 이름 → 빌더.
  final Map<String, DocsTagBuilder> builders;

  /// [name] 의 빌더 — 모르는 태그면 `null`.
  DocsTagBuilder? builderFor(String name) => builders[name];

  /// [name] 을 아는지 여부.
  bool contains(String name) => builders.containsKey(name);

  /// [other] 의 빌더를 얹은 새 레지스트리 — 같은 이름은 [other] 가 이긴다.
  DocsTagRegistry merge(DocsTagRegistry other) =>
      .new({...builders, ...other.builders});
}
