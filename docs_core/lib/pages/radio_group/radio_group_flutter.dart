/// RadioGroup 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="radio-group/...">` 가 읽는다. 같은 이름의 Web 파일(`radio_group_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'radio_group_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _radioGroup;

/// 장면 이름(`radio-group/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'radio-group/anatomy': () => RadioGroup<String>(
    value: 'pro',
    onChanged: (_) {},
    child: const Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: CoreSpace.space8,
      children: [
        Radio(value: 'basic', label: 'Basic', description: '개인 프로젝트용'),
        Radio(value: 'pro', label: 'Pro', description: '팀 협업과 우선 지원'),
      ],
    ),
  ),
  'radio-group/card': () => SizedBox(
    width: 288,
    child: RadioGroup<String>(
      value: 'pro',
      onChanged: (_) {},
      variant: CoreRadioGroupVariant.card,
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: CoreSpace.space8,
        children: [
          Radio(value: 'basic', label: 'Basic', description: '개인 프로젝트용'),
          Radio(value: 'pro', label: 'Pro', description: '팀 협업과 우선 지원'),
        ],
      ),
    ),
  ),
  'radio-group/states': _radioStates,
  'radio-group/dont-many': () => RadioGroup<String>(
    value: 'kr',
    onChanged: (_) {},
    options: const [
      (value: 'kr', label: '대한민국'),
      (value: 'jp', label: '일본'),
      (value: 'us', label: '미국'),
      (value: 'gb', label: '영국'),
      (value: 'de', label: '독일'),
      (value: 'fr', label: '프랑스'),
      (value: 'ca', label: '캐나다'),
      (value: 'au', label: '호주'),
    ],
  ),
  'radio-group/related-switch-field': () => SizedBox(
    width: 240,
    child: SwitchField(label: '알림 받기', value: true, onChanged: (_) {}),
  ),
};

Widget _radioGroup(Map<String, String> props, String? label) {
  final count = int.tryParse(props['options'] ?? '') ?? radioGroupPreviewOptions.length;
  return RadioGroup<String>(
    value: props['value'] ?? 'pro',
    onChanged: (_) {},
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    variant: previewEnum(CoreRadioGroupVariant.values, props['variant'], CoreRadioGroupVariant.defaultVariant),
    orientation: previewEnum(
      CoreRadioGroupOrientation.values,
      props['orientation'],
      CoreRadioGroupOrientation.vertical,
    ),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    options: [
      for (final (value, text) in radioGroupPreviewOptions.take(count)) (value: value, label: text),
    ],
  );
}

/// 상태 격자 — Web 과 같은 네 상태.
Widget _radioStates() {
  const columns = ['미선택', '선택', '비활성', '비활성 · 선택'];
  Widget cell(String state) => switch (state) {
    '선택' => Radio<String>(value: 'a', groupValue: 'a', onChanged: (_) {}),
    '비활성' => Radio<String>(value: 'a', enabled: false, onChanged: (_) {}),
    '비활성 · 선택' => Radio<String>(value: 'a', groupValue: 'a', enabled: false, onChanged: (_) {}),
    _ => Radio<String>(value: 'a', onChanged: (_) {}),
  };
  return Wrap(
    spacing: CoreSpace.space16,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
