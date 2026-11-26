/// Button 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="button/...">` 가 읽는다. 같은 이름의 Web 파일(`button_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _button;

/// 장면 이름(`button/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'button/anatomy': () => Button(
    size: CoreComponentSize.lg,
    leading: const Icon(LucideIcons.plus),
    trailing: const Icon(LucideIcons.arrowRight),
    onPressed: () {},
    child: const Text('저장하기'),
  ),
  'button/states': _buttonStates,
  'button/do-one-primary': () => docsFlutterDemoRow([_outline('취소'), _primary('저장하기')]),
  'button/dont-two-primary': () => docsFlutterDemoRow([_primary('취소'), _primary('저장하기')]),
  'button/do-clear-label': () => docsFlutterDemoRow([
    _outline('취소'),
    Button(
      variant: CoreButtonVariant.destructive,
      leading: const Icon(LucideIcons.trash2),
      onPressed: () {},
      child: const Text('항목 3개 삭제'),
    ),
  ]),
  'button/dont-vague-label': () => docsFlutterDemoRow([
    _outline('취소'),
    Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: const Text('확인')),
  ]),
  'button/do-ghost-repeat': () => docsFlutterDemoRow([
    for (final label in ['편집', '공유', '복제'])
      Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(label)),
  ]),
  'button/dont-heavy-repeat': () => docsFlutterDemoRow([
    for (final label in ['편집', '공유', '복제']) Button(size: CoreComponentSize.sm, onPressed: () {}, child: Text(label)),
  ]),
  'button/placement-dialog': () => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    spacing: CoreSpace.space16,
    children: [
      const Align(alignment: AlignmentDirectional.centerStart, child: Text('항목 3개를 삭제할까요?')),
      docsFlutterDemoRow([
        _outline('취소'),
        Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: const Text('3개 삭제')),
      ]),
    ],
  ),
  'button/placement-mobile': () => SizedBox(
    width: 220,
    child: Button(size: CoreComponentSize.lg, expanded: true, onPressed: () {}, child: const Text('다음')),
  ),
  'button/a11y-icon-name': () => Button(
    variant: CoreButtonVariant.outline,
    shape: CoreButtonShape.square,
    onPressed: () {},
    child: const Icon(LucideIcons.plus),
  ),
  'button/related-fab': () => Fab(trigger: const Icon(LucideIcons.plus), onPressed: () {}),
  'button/related-toggle': () => docsFlutterDemoRow([
    Toggle(value: true, onChanged: (_) {}),
    Toggle(value: false, onChanged: (_) {}),
  ]),
  'button/related-menu': () => Menu(
    ariaLabel: '행동',
    items: [
      CoreMenuItem.action('복사', onPressed: () {}, active: true),
      CoreMenuItem.action('이름 변경', onPressed: () {}),
      CoreMenuItem.action('삭제', onPressed: () {}),
    ],
  ),
  'button/theme-order': () => const Text('디자인 시스템 기본값 → 테마 기본값 → 테마 variant별 값 → 부모 슬롯 → 인스턴스 buttonStyle'),
};

Widget _button(Map<String, String> props, String? label) {
  final shape = previewEnum(CoreButtonShape.values, props['shape'], CoreButtonShape.rectangle);
  final iconOnly = shape != CoreButtonShape.rectangle;
  return Button(
    variant: previewEnum(CoreButtonVariant.values, props['variant'], CoreButtonVariant.primary),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    shape: shape,
    leading: iconOnly ? null : docsFlutterIcon(props['leading']),
    trailing: iconOnly ? null : docsFlutterIcon(props['trailing']),
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    expanded: previewFlag(props, 'expanded'),
    href: props['href'],
    external: previewFlag(props, 'external'),
    onPressed: props['href'] == null ? () {} : null,
    child: iconOnly ? (docsFlutterIcon(props['icon']) ?? Icon(LucideIcons.plus)) : Text(label ?? '버튼'),
  );
}

Widget _primary(String label) => Button(onPressed: () {}, child: Text(label));

Widget _outline(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

Widget _buttonStates() => docsFlutterDemoRow([
  for (final variant in const [CoreButtonVariant.primary, CoreButtonVariant.outline]) ...[
    Button(variant: variant, onPressed: () {}, child: const Text('저장하기')),
    Button(variant: variant, enabled: false, child: const Text('저장하기')),
  ],
]);
