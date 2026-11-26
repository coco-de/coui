/// Label 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 플레이그라운드가, 장면은 `<Preview demo="label/...">` ·
/// `<Card demo="label/...">` 가 읽는다. 같은 이름의 Flutter 파일
/// (`label_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'label_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _label;

/// 장면 이름(`label/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조의 번호는 이 장면의 루트(`<span>`)와 그 안의 부분을 찾는다 — 감싸지 않는다.
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
      div(
        styles: Styles(raw: {'display': 'flex', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)}),
        [
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
    const FormField(
      label: page.labelPreviewText,
      required: true,
      child: TextField(placeholder: Text(page.labelPlaceholder)),
    ),
    CoreLayout.layout240,
  ),
  'label/related-form-label': () => const FormLabel(label: Text(page.labelPreviewText), isRequired: true),
  'label/related-fieldset': () => _sized(
    const Fieldset(
      legend: Text('계정'),
      children: [TextField(placeholder: Text(page.labelPlaceholder))],
    ),
    CoreLayout.layout240,
  ),
  'label/related-validation-badge': () => const ValidationBadge(label: '8자 이상', state: CoreValidationState.valid),
};

Component _label(Map<String, String> props, String? label) => Label(
  text: label ?? page.labelPreviewText,
  icon: docsWebIcon(props['icon']),
  isRequired: previewFlag(props, 'isRequired'),
  disabled: previewFlag(props, 'disabled'),
);

/// 라벨을 입력 위에 놓은 한 칸.
Component _field(Component label, {bool enabled = true}) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-direction': 'column',
      'gap': spaceCss(CoreSpace.space6),
      'width': pinnedLengthCss(CoreLayout.layout240),
      'max-width': '100%',
    },
  ),
  [label, TextField(enabled: enabled, placeholder: const Text(page.labelPlaceholder))],
);

/// 장면의 폭 — 무대를 채우되 [width] 를 넘지 않는다.
Component _sized(Component child, double width) => div(
  styles: Styles(raw: {'width': '100%', 'max-width': pinnedLengthCss(width)}),
  [child],
);

/// 이름을 단 조각들을 나란히 놓고, 좁으면 줄을 바꾼다.
Component _row(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'justify-content': 'center',
      'align-items': 'flex-start',
      'gap': '${spaceCss(CoreSpace.space16)} ${spaceCss(CoreSpace.space32)}',
    },
  ),
  children,
);

/// 위에 이름을 단 장면 조각. 이름은 라벨과 헷갈리지 않게 고정폭 글자다.
Component _captioned(String caption, Component child) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': spaceCss(CoreSpace.space8)},
  ),
  [Text(caption).codeXs.onSurfaceVariant, child],
);
