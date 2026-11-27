/// DisclosureBadge 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="disclosure-badge/...">` 류의 블록이 읽는다. 같은 이름의 Web
/// 파일(`disclosure_badge_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'disclosure_badge_page.dart'
    show
        disclosureBadgeKind,
        disclosureBadgeOneColorStyle,
        disclosureBadgePlaygroundStyle,
        disclosureBadgeRows,
        disclosureBadgeSampleLabels;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _disclosureBadge;

/// 장면 이름(`disclosure-badge/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  // 구조 — 세 부분(상자 · 마커 점 · 라벨)이 모두 있는 commitment 로 그린다.
  'disclosure-badge/anatomy': () => const DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '계약 시 제공'),
  'disclosure-badge/do-reason': () => docsFlutterDemoRow(const [
    DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · NDA'),
    DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개 · 고객사 요청'),
  ]),
  'disclosure-badge/dont-bare-private': () => const DisclosureBadge(kind: CoreDisclosureKind.private, label: '비공개'),
  'disclosure-badge/do-commitment': () => docsFlutterDemoRow(const [
    DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '계약 시 제공'),
    DisclosureBadge(kind: CoreDisclosureKind.commitment, label: '킥오프 시 제공'),
  ]),
  'disclosure-badge/dont-false-open': () => const DisclosureBadge(kind: CoreDisclosureKind.open, label: '계약 후 제공'),
  'disclosure-badge/do-link': () => docsFlutterDemoRow([
    const DisclosureBadge(kind: CoreDisclosureKind.open, label: '근거 공개'),
    Link(href: '/components/link', onPressed: () {}, child: const Text('근거 열기')),
  ]),
  'disclosure-badge/dont-one-color': () => docsFlutterDemoRow([
    for (final MapEntry(key: kind, value: label) in disclosureBadgeSampleLabels.entries)
      DisclosureBadge(kind: kind, label: label, disclosureBadgeStyle: disclosureBadgeOneColorStyle),
  ]),
  'disclosure-badge/rows': _rows,
  'disclosure-badge/related-link': () => Link(href: '/components/link', onPressed: () {}, child: const Text('근거 열기')),
  'disclosure-badge/related-badge': () => const Badge(
    tone: CoreBadgeTone.info,
    showDot: true,
    child: Text('검토 중'),
  ),
  'disclosure-badge/related-chip': () => Chip(label: '디자인', onRemove: () {}),
  'disclosure-badge/related-validation-badge': () =>
      const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
};

Widget _disclosureBadge(Map<String, String> props, String? label) {
  final kind = disclosureBadgeKind(props);
  return DisclosureBadge(
    kind: kind,
    label: label ?? disclosureBadgeSampleLabels[kind]!,
    disclosureBadgeStyle: disclosureBadgePlaygroundStyle(props),
  );
}

/// 항목 목록 — 한 줄에 이름, 배지, 그리고 지금 열 수 있는 항목에만 링크.
Widget _rows() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final (title, kind) in disclosureBadgeRows)
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title).bodyMedium.onSurface,
          const Gap.space8(),
          DisclosureBadge(kind: kind, label: disclosureBadgeSampleLabels[kind]!),
          if (kind == CoreDisclosureKind.open) ...[
            const Gap.space8(),
            Link(href: '/components/link', onPressed: () {}, child: const Text('근거 열기')),
          ],
        ],
      ),
  ],
);
