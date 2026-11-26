/// FormLabel 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="form-label/...">` · `<Card demo="form-label/...">` 가 읽는다.
/// 같은 이름의 Flutter 파일(`form_label_flutter.dart`)과 컴포넌트 · 속성 · 장면
/// 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'form_label_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _formLabel;

/// 장면 이름(`form-label/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조의 번호는 이 장면의 루트(`<label>`)와 그 안의 부분을 찾는다 — 감싸지 않는다.
  'form-label/anatomy': () => const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true),
  'form-label/required': () => _row([
    _captioned('기본 *', const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true)),
    _captioned(
      'requiredIndicator',
      const FormLabel(
        label: Text(page.formLabelPreviewText),
        isRequired: true,
        requiredIndicator: Text(page.formLabelCustomIndicator),
      ),
    ),
  ]),
  'form-label/states': _states,
  'form-label/do-is-required': () => const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true),
  'form-label/dont-typed-asterisk': () => const FormLabel(label: Text(page.formLabelTypedAsterisk)),
  'form-label/do-field-label': () => _sized(
    const TextField(
      label: page.formLabelPreviewText,
      required: true,
      enabled: false,
      placeholder: Text(page.formLabelPlaceholder),
    ),
    CoreLayout.layout240,
  ),
  'form-label/dont-separate-label': () => _sized(
    div(
      styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space6)}),
      [
        const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true),
        const TextField(enabled: false, placeholder: Text(page.formLabelPlaceholder)),
      ],
    ),
    CoreLayout.layout240,
  ),
  'form-label/layout': () => _sized(
    const FormLabel(label: Text(page.formLabelLongText), isRequired: true),
    CoreLayout.layout160,
  ),
  'form-label/related-form-field': () => _sized(
    const FormField(
      label: page.formLabelPreviewText,
      required: true,
      description: page.formLabelDescription,
      child: TextField(placeholder: Text(page.formLabelPlaceholder)),
    ),
    _relatedWidth,
  ),
  'form-label/related-text-field': () => _sized(
    const TextField(
      label: page.formLabelPreviewText,
      required: true,
      placeholder: Text(page.formLabelPlaceholder),
    ),
    _relatedWidth,
  ),
  'form-label/related-label': () => Label(
    text: page.formLabelPreviewText,
    isRequired: true,
    icon: Icon(LucideIcons.mail),
  ),
};

/// 관련 컴포넌트 카드(3열)에 들어가는 폭.
const double _relatedWidth = 200;

Component _formLabel(Map<String, String> props, String? label) {
  final indicator = props['requiredIndicator'];
  return FormLabel(
    label: Text(label ?? page.formLabelPreviewText),
    isRequired: previewFlag(props, 'isRequired'),
    requiredIndicator: indicator == null ? null : Text(indicator),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

/// 상태 — 기본 · 필수 · 비활성 · 비활성이면서 필수.
Component _states() => _row([
  _captioned('기본', const FormLabel(label: Text(page.formLabelPreviewText))),
  _captioned('필수', const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true)),
  _captioned('비활성', const FormLabel(label: Text(page.formLabelPreviewText), enabled: false)),
  _captioned(
    '비활성 · 필수',
    const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true, enabled: false),
  ),
]);

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
