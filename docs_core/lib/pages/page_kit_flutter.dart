/// 컴포넌트 페이지 파일(`pages/<slug>/<slug>_flutter.dart`)이 함께 쓰는 도구 — Flutter.
///
/// 같은 이름 · 같은 뜻의 도구가 `page_kit_web.dart` 에 있다. 아이콘
/// 이름은 두 파일이 같아야 한다(`prop_previews_parity_test.dart` 가 대조한다).
library;

import 'package:coui_flutter/coui_flutter.dart';

/// 아이콘 이름 → 아이콘. 이름은 Lucide 의 kebab-case 를 쓴다.
Widget? docsFlutterIcon(String? name) => switch (name) {
  'layout-grid' => Icon(LucideIcons.layoutGrid),
  'list' => Icon(LucideIcons.list),
  'minus' => Icon(LucideIcons.minus),
  'phone' => Icon(LucideIcons.phone),
  'plus' => Icon(LucideIcons.plus),
  'trash-2' => Icon(LucideIcons.trash2),
  'external-link' => Icon(LucideIcons.externalLink),
  'hash' => Icon(LucideIcons.hash),
  'arrow-right' => Icon(LucideIcons.arrowRight),
  'calendar' => Icon(LucideIcons.calendar),
  'search' => Icon(LucideIcons.search),
  'smartphone' => Icon(LucideIcons.smartphone),
  'star' => Icon(LucideIcons.star),
  'circle-alert' => Icon(LucideIcons.circleAlert),
  'clock' => Icon(LucideIcons.clock),
  'copy' => Icon(LucideIcons.copy),
  'credit-card' => Icon(LucideIcons.creditCard),
  'x' => Icon(LucideIcons.x),
  _ => null,
};

/// 장면 안에 여러 개를 나란히 놓는다.
Widget docsFlutterDemoRow(List<Widget> children) =>
    Wrap(spacing: CoreSpace.space8, runSpacing: CoreSpace.space8, children: children);
