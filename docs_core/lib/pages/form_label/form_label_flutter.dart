/// FormLabel 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<SizeSpec>` · 플레이그라운드가, 장면은
/// `<Preview demo="form-label/...">` · `<Card demo="form-label/...">` 가 읽는다.
/// 같은 이름의 Web 파일(`form_label_web.dart`)과 컴포넌트 · 속성 · 장면 이름이
/// 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'form_label_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _formLabel;

/// 장면 이름(`form-label/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
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
    TextField(
      label: page.formLabelPreviewText,
      required: true,
      enabled: false,
      placeholder: const Text(page.formLabelPlaceholder),
    ),
    CoreLayout.layout240,
  ),
  'form-label/dont-separate-label': () => _sized(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space6,
      children: [
        const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true),
        TextField(enabled: false, placeholder: const Text(page.formLabelPlaceholder)),
      ],
    ),
    CoreLayout.layout240,
  ),
  'form-label/layout': () => _sized(
    const FormLabel(label: Text(page.formLabelLongText), isRequired: true),
    CoreLayout.layout160,
  ),
  'form-label/related-form-field': () => _sized(
    FormField(
      label: page.formLabelPreviewText,
      required: true,
      description: page.formLabelDescription,
      child: TextField(placeholder: const Text(page.formLabelPlaceholder)),
    ),
    _relatedWidth,
  ),
  'form-label/related-text-field': () => _sized(
    TextField(
      label: page.formLabelPreviewText,
      required: true,
      placeholder: const Text(page.formLabelPlaceholder),
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

Widget _formLabel(Map<String, String> props, String? label) {
  final indicator = props['requiredIndicator'];
  return FormLabel(
    label: Text(label ?? page.formLabelPreviewText),
    isRequired: previewFlag(props, 'isRequired'),
    requiredIndicator: indicator == null ? null : Text(indicator),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    enabled: previewFlag(props, 'enabled', fallback: true),
  );
}

/// 상태 — Web 과 같은 네 가지.
Widget _states() => _row([
  _captioned('기본', const FormLabel(label: Text(page.formLabelPreviewText))),
  _captioned('필수', const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true)),
  _captioned('비활성', const FormLabel(label: Text(page.formLabelPreviewText), enabled: false)),
  _captioned(
    '비활성 · 필수',
    const FormLabel(label: Text(page.formLabelPreviewText), isRequired: true, enabled: false),
  ),
]);

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
