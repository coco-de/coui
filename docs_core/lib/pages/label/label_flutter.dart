/// Label 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="label/...">` ·
/// `<Card demo="label/...">` 가 읽는다. 같은 이름의 Web 파일
/// (`label_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'label_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _label;

/// 장면 이름(`label/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'label/anatomy': () => const Label(text: page.labelPreviewText, icon: Icon(LucideIcons.mail), isRequired: true),
  'label/content': () => _row([
    _captioned('text', const Label(text: page.labelPreviewText)),
    _captioned('isRequired', const Label(text: page.labelPreviewText, isRequired: true)),
    _captioned('icon', const Label(text: page.labelPreviewText, icon: Icon(LucideIcons.mail))),
    _captioned(
      'icon · isRequired',
      const Label(text: page.labelPreviewText, icon: Icon(LucideIcons.mail), isRequired: true),
    ),
  ]),
  'label/states': () => _row([
    _captioned('활성', const Label(text: page.labelPreviewText, icon: Icon(LucideIcons.mail), isRequired: true)),
    _captioned(
      '비활성',
      const Label(text: page.labelPreviewText, icon: Icon(LucideIcons.mail), isRequired: true, disabled: true),
    ),
  ]),
  'label/layout': () => _row([
    _captioned('위에', _field(const Label(text: page.labelPreviewText, isRequired: true))),
    _captioned(
      '옆에',
      Row(
        mainAxisSize: MainAxisSize.min,
        spacing: CoreSpace.space8,
        children: [
          const Label(text: page.labelToggleText, icon: Icon(LucideIcons.bell)),
          Toggle(value: true, onChanged: (_) {}),
        ],
      ),
    ),
  ]),
  'label/do-sync-disabled': () => _field(
    const Label(text: page.labelPreviewText, disabled: true),
    enabled: false,
  ),
  'label/dont-unsynced': () => _field(const Label(text: page.labelPreviewText), enabled: false),
  'label/do-is-required': () => const Label(text: page.labelPreviewText, isRequired: true),
  'label/dont-typed-asterisk': () => const Label(text: page.labelTypedAsterisk),
  'label/related-form-field': () => _sized(
    FormField(
      label: page.labelPreviewText,
      required: true,
      child: TextField(placeholder: const Text(page.labelPlaceholder)),
    ),
    CoreLayout.layout240,
  ),
  'label/related-form-label': () => const FormLabel(label: Text(page.labelPreviewText), isRequired: true),
  'label/related-fieldset': () => _sized(
    Fieldset(
      legend: const Text('계정'),
      children: [TextField(placeholder: const Text(page.labelPlaceholder))],
    ),
    CoreLayout.layout240,
  ),
  'label/related-validation-badge': () => const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
};

Widget _label(Map<String, String> props, String? label) => Label(
  text: label ?? page.labelPreviewText,
  icon: docsFlutterIcon(props['icon']),
  isRequired: previewFlag(props, 'isRequired'),
  disabled: previewFlag(props, 'disabled'),
);

/// 라벨을 입력 위에 놓은 한 칸.
Widget _field(Widget label, {bool enabled = true}) => _sized(
  Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    spacing: CoreSpace.space6,
    children: [
      label,
      TextField(enabled: enabled, placeholder: const Text(page.labelPlaceholder)),
    ],
  ),
  CoreLayout.layout240,
);

/// 장면의 폭 — [width] 를 넘지 않는다.
Widget _sized(Widget child, double width) => SizedBox(width: width, child: child);

/// 이름을 단 조각들을 나란히 놓고, 좁으면 줄을 바꾼다.
Widget _row(List<Widget> children) => Wrap(
  alignment: WrapAlignment.center,
  spacing: CoreSpace.space32,
  runSpacing: CoreSpace.space16,
  children: children,
);

/// 위에 이름을 단 장면 조각. 이름은 라벨과 헷갈리지 않게 고정폭 글자다.
Widget _captioned(String caption, Widget child) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space8,
  children: [Text(caption).codeXs.onSurfaceVariant, child],
);
