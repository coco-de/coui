/// 데이터 주도 레퍼런스 태그 — `<ComponentGrid />` 와 랜딩의 `<SiteShowcase />`
/// · `<SiteHero />`.
///
/// 값을 문서에 박지 않고 **살아있는 출처**(`kDocsComponentGroups`)에서
/// 끌어온다 — 카탈로그에 컴포넌트가 늘면 그리드가 따라온다.
library;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_app/src/markdown/docs_tag_registry.dart';
import 'package:docs_core/shared/component_catalog.dart';

/// 컴포넌트 카드 그리드의 열 수.
const _kComponentGridColumns = 3;

/// 레퍼런스 태그 이름 → 빌더.
///
/// [onInternalLink] 는 `<ComponentGrid />` 의 카드 탭에서 쓴다 — 컴포넌트
/// 페이지 경로(`/components/<slug>`)를 받는다.
Map<String, DocsTagBuilder> docsReferenceTagBuilders({
  required void Function(String path) onInternalLink,
}) => {
  'ComponentGrid': (context, tag) =>
      _ComponentGridView(onInternalLink: onInternalLink),
  // 랜딩(`index.md`)이 쓰는 둘. 같은 마크다운을 두 표면이 읽으므로
  // **등록하지 않으면 렌더러가 조용히 버린다** — `block_renderer.dart` 의
  // `if (built != null)` 경로다. index.md 는 이 두 태그가 전부이므로,
  // 빠지면 네이티브 홈이 빈 화면이 된다.
  //
  // Web 쪽은 벤토와 진입 카드를 그리고 여기서는 같은 카탈로그를 카드
  // 그리드로 그린다 — 렌더가 다른 것은 플랫폼 차이이고, **같은 출처**를
  // 읽는다는 것이 지켜야 할 것이다.
  'SiteShowcase': (context, tag) =>
      _ComponentGridView(onInternalLink: onInternalLink),
  'SiteHero': (context, tag) => const _SiteHeroView(),
};

// ── Component grid ──────────────────────────────────────────────────

/// 카탈로그의 138 개 컴포넌트를 그룹별 카드 그리드로 보여준다.
class _ComponentGridView extends StatelessWidget {
  const _ComponentGridView({required this.onInternalLink});

  final void Function(String path) onInternalLink;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: .min,
      crossAxisAlignment: .stretch,
      children: [
        for (final group in kDocsComponentGroups) ...[
          Padding(
            padding: const .only(
              top: CoreSpace.space24,
              bottom: CoreSpace.space8,
            ),
            child: Row(
              children: [
                Text(group.title).titleMedium.semiBold.onSurface,
                const Gap.space8(),
                Badge(
                  variant: .filled,
                  form: .count,
                  child: Text('${group.items.length}'),
                ),
              ],
            ),
          ),
          if (group.description != null) ...[
            Text(group.description!).bodySmall.onSurfaceVariant,
            const Gap.space12(),
          ],
          ResponsiveGrid(
            columns: _kComponentGridColumns,
            cellSpacing: CoreSpace.space12,
            children: [
              for (final entry in group.items)
                _ComponentCard(entry: entry, onInternalLink: onInternalLink),
            ],
          ),
        ],
      ],
    );
  }
}

/// 컴포넌트 카드 하나 — 탭하면 그 컴포넌트 페이지로.
class _ComponentCard extends StatelessWidget {
  const _ComponentCard({required this.entry, required this.onInternalLink});

  final DocsComponentEntry entry;
  final void Function(String path) onInternalLink;

  @override
  Widget build(BuildContext context) {
    return Card(
      onTap: () => onInternalLink('/components/${entry.slug}'),
      body: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        children: [
          Row(
            children: [
              // 카탈로그의 아이콘은 타입 있는 글리프가 아니라 이모지 문자라
              // Icon 이 아니라 Text 로 그린다 — Web 과 같은 문자를 낸다.
              Text(entry.icon).titleMedium,
              const Gap.space8(),
              Expanded(child: Text(entry.name).titleSmall.semiBold.onSurface),
              // Active/Deprecated 시각 분리 — 카탈로그의 파싱된 상태에서
              // 온다(손 관리 아님). docs_site `component_grid.dart` 의
              // `.deprecated-badge` 와 같은 자리. #3580.
              if (entry.isDeprecated)
                Badge(
                  variant: .outlined,
                  child: const Text('Deprecated').labelSmall,
                ),
            ],
          ),
          const Gap.space4(),
          Text(entry.description).bodySmall.onSurfaceVariant,
        ],
      ),
    );
  }
}

// ── Landing hero ────────────────────────────────────────────────────

/// 랜딩 헤드라인 — Web 히어로의 네이티브 대응.
///
/// 숫자는 카탈로그에서 읽는다. 적어 두면 컴포넌트가 하나 늘어난 날 두
/// 표면이 서로 다른 수를 말하게 된다.
class _SiteHeroView extends StatelessWidget {
  const _SiteHeroView();

  static int get _componentCount =>
      kDocsComponentGroups.fold(0, (sum, group) => sum + group.items.length);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '한 번 배워서 Flutter 와 Web 에 그대로',
        ).headlineMedium.bold.onSurface,
        const Gap.space12(),
        Text(
          '같은 API · 같은 토큰 · 같은 렌더링. '
          '$_componentCount 개 컴포넌트를 두 플랫폼에서 같은 코드로 씁니다.',
        ).bodyLarge.onSurfaceVariant,
      ],
    );
  }
}
