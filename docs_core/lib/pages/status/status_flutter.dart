/// Status 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · `<SizeSpec>` · 플레이그라운드가,
/// 장면은 `<Preview demo="status/...">` · `<Card demo>` · `<Anatomy demo>` 가
/// 읽는다. 같은 이름의 Web 파일(`status_web.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../previews/props/flutter_prop_previews.dart';
import '../../shared/preview_props.dart';
import '../page_kit_flutter.dart';
import 'status_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _status;

/// 장면 이름(`status/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'status/anatomy': () => Status(
    variant: CoreStatusVariant.busy,
    size: CoreStatusSize.xl,
    statusStyle: page.statusAnatomyStyle,
    label: Text(page.statusVariantWords[CoreStatusVariant.busy]!),
  ),
  'status/colors': () => _spaced([
    for (final color in CoreStatusColor.values) Status(color: color, size: CoreStatusSize.lg, label: Text(color.name)),
  ]),
  // 맥동은 보이는 글자 없는 점에 건다 — 두 플랫폼이 같은 그림을 낸다.
  'status/animated': () => _spaced([
    _captioned(
      'animated: true',
      const Status(
        variant: CoreStatusVariant.online,
        size: CoreStatusSize.xl,
        animated: true,
        semanticLabel: '실시간 연결 중',
      ),
    ),
    _captioned(
      'animated: false',
      const Status(variant: CoreStatusVariant.online, size: CoreStatusSize.xl, semanticLabel: '온라인'),
    ),
  ]),
  'status/do-state-text': () => _list([
    for (final variant in CoreStatusVariant.values)
      Status(variant: variant, label: Text(page.statusVariantWords[variant]!)),
  ]),
  'status/dont-color-only': () => _spaced([
    for (final color in page.statusColorOnlySamples) Status(color: color, size: CoreStatusSize.xl),
  ]),
  'status/do-count': () => const Badge(
    tone: CoreBadgeTone.destructive,
    variant: CoreBadgeVariant.filled,
    form: CoreBadgeForm.count,
    child: Text('3'),
  ),
  'status/dont-count': () => _spaced(const [
    Icon(LucideIcons.bell),
    Status(color: CoreStatusColor.error, size: CoreStatusSize.xl, semanticLabel: '읽지 않은 알림'),
  ]),
  'status/with-avatar': () => _spaced([
    for (final (initials, variant) in page.statusAvatarSamples) _avatar(initials, variant),
  ]),
  'status/service-list': () => _list([
    for (final (color, text) in page.statusServiceSamples) Status(color: color, label: Text(text)),
  ]),
  'status/related-avatar': () => _avatar('AB', CoreStatusVariant.online),
  'status/related-badge': () => docsFlutterDemoRow(const [
    Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('승인됨')),
    Badge(
      tone: CoreBadgeTone.destructive,
      variant: CoreBadgeVariant.filled,
      form: CoreBadgeForm.count,
      child: Text('3'),
    ),
  ]),
  'status/related-validation-badge': () => const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
  'status/related-tracker': () => SizedBox(
    width: CoreSpace.space160,
    child: Tracker(segments: [for (final status in page.statusHistorySamples) CoreTrackerSegment(status: status)]),
  ),
};

Widget _status(Map<String, String> props, String? label) {
  final variant = page.statusPreviewVariant(props);
  final color = previewEnum(CoreStatusColor.values, props['color'], page.statusDefaultColor);
  final word = page.statusPreviewWord(variant, color, label);
  final showLabel = previewFlag(props, 'showLabel');
  return Status(
    color: color,
    variant: variant,
    size: previewEnum(CoreStatusSize.values, props['size'], page.statusDefaultSize),
    label: showLabel ? Text(word) : null,
    semanticLabel: showLabel ? null : word,
    animated: previewFlag(props, 'animated'),
  );
}

/// 접속 상태 점을 `badge` 슬롯에 붙인 아바타.
Widget _avatar(String initials, CoreStatusVariant variant) => Avatar(
  initials: initials,
  size: CoreComponentSize.lg,
  badge: Status(variant: variant, size: CoreStatusSize.lg, semanticLabel: page.statusVariantWords[variant]),
);

/// 점마다 넉넉히 띄워 나란히 놓는다 — 좁으면 다음 줄로 넘어간다.
Widget _spaced(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  crossAxisAlignment: WrapCrossAlignment.center,
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space12,
  children: children,
);

/// 상태 목록 — 한 줄에 하나씩, 앞을 맞춘다.
Widget _list(List<Widget> children) => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space8,
  children: children,
);

/// 아래에 설명을 단 장면 조각.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [child, Text(caption).labelSmall.onSurfaceVariant],
);
