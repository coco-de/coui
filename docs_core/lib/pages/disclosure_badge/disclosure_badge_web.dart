/// DisclosureBadge 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="disclosure-badge/...">` 류의 블록이 읽는다. 같은 이름의
/// Flutter 파일(`disclosure_badge_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'disclosure_badge_page.dart'
    show
        disclosureBadgeKind,
        disclosureBadgeOneColorStyle,
        disclosureBadgePlaygroundStyle,
        disclosureBadgeRows,
        disclosureBadgeSampleLabels;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _disclosureBadge;

/// 장면 이름(`disclosure-badge/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 세 부분(상자 · 마커 점 · 라벨)이 모두 있는 commitment 로 그린다.
  'disclosure-badge/anatomy': () => const DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '계약 시 제공'),
  'disclosure-badge/do-reason': () => docsWebDemoRow(const [
    DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · NDA'),
    DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · 고객사 요청'),
  ]),
  'disclosure-badge/dont-bare-private': () => const DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개'),
  'disclosure-badge/do-commitment': () => docsWebDemoRow(const [
    DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '계약 시 제공'),
    DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '킥오프 시 제공'),
  ]),
  'disclosure-badge/dont-false-open': () => const DisclosureBadge(kind: CoreDisclosureKind.open, label: '계약 후 제공'),
  'disclosure-badge/do-link': () => docsWebDemoRow(const [
    DisclosureBadge(kind: CoreDisclosureKind.open, label: '근거 공개'),
    Link(href: '/components/link', child: Text('근거 열기')),
  ]),
  'disclosure-badge/dont-one-color': () => docsWebDemoRow([
    for (final MapEntry(key: kind, value: label) in disclosureBadgeSampleLabels.entries)
      DisclosureBadge(kind: kind, label: label, disclosureBadgeStyle: disclosureBadgeOneColorStyle),
  ]),
  'disclosure-badge/rows': _rows,
  'disclosure-badge/related-link': () => const Link(href: '/components/link', child: Text('근거 열기')),
  'disclosure-badge/related-badge': () => const Badge(
    tone: CoreBadgeTone.info,
    showDot: true,
    child: Text('검토 중'),
  ),
  'disclosure-badge/related-chip': () => Chip(label: '디자인', onRemove: () {}),
  'disclosure-badge/related-validation-badge': () =>
      const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
};

Component _disclosureBadge(Map<String, String> props, String? label) {
  final kind = disclosureBadgeKind(props);
  return DisclosureBadge(
    kind: kind,
    label: label ?? disclosureBadgeSampleLabels[kind]!,
    disclosureBadgeStyle: disclosureBadgePlaygroundStyle(props),
  );
}

/// 항목 목록 — 한 줄에 이름, 배지, 그리고 지금 열 수 있는 항목에만 링크.
Component _rows() => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'align-items': 'flex-start',
      'gap': 'var(--coui-space-12)',
    },
  ),
  [
    for (final (title, kind) in disclosureBadgeRows)
      div(styles: Styles(raw: {'display': 'flex', 'flex-wrap': 'wrap', 'align-items': 'center'}), [
        Text(title).bodyMedium.onSurface,
        const Gap.space8(),
        DisclosureBadge(kind: kind, label: disclosureBadgeSampleLabels[kind]!),
        if (kind == CoreDisclosureKind.open) ...[
          const Gap.space8(),
          const Link(href: '/components/link', child: Text('근거 열기')),
        ],
      ]),
  ],
);
