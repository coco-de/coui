/// Button 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<VariantRow>` · 플레이그라운드가, 장면은
/// `<Preview demo="button/...">` 가 읽는다. 같은 이름의 Flutter 파일(`button_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _button;

/// 장면 이름(`button/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'button/anatomy': () => Button(
    size: CoreComponentSize.lg,
    leading: Icon(LucideIcons.plus),
    trailing: Icon(LucideIcons.arrowRight),
    onPressed: () {},
    child: const Text('저장하기'),
  ),
  'button/states': _buttonStates,
  'button/do-one-primary': () => docsWebDemoRow([_outline('취소'), _primary('저장하기')]),
  'button/dont-two-primary': () => docsWebDemoRow([_primary('취소'), _primary('저장하기')]),
  'button/do-clear-label': () => docsWebDemoRow([
    _outline('취소'),
    Button(
      variant: CoreButtonVariant.destructive,
      leading: Icon(LucideIcons.trash2),
      onPressed: () {},
      child: const Text('항목 3개 삭제'),
    ),
  ]),
  'button/dont-vague-label': () => docsWebDemoRow([
    _outline('취소'),
    Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: const Text('확인')),
  ]),
  'button/do-ghost-repeat': () => docsWebDemoRow([
    for (final label in ['편집', '공유', '복제'])
      Button(variant: CoreButtonVariant.ghost, size: CoreComponentSize.sm, onPressed: () {}, child: Text(label)),
  ]),
  'button/dont-heavy-repeat': () => docsWebDemoRow([
    for (final label in ['편집', '공유', '복제']) Button(size: CoreComponentSize.sm, onPressed: () {}, child: Text(label)),
  ]),
  'button/placement-dialog': () => div(classes: 'docs-demo-dialog', [
    div(classes: 'docs-demo-dialog-text', [
      const Text('항목 3개를 삭제할까요?').titleMedium.semiBold,
      const Text('삭제한 항목은 되돌릴 수 없어요.').bodyMedium.onSurfaceVariant,
    ]),
    div(classes: 'docs-demo-dialog-actions', [
      _outline('취소'),
      Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: const Text('3개 삭제')),
    ]),
  ]),
  'button/placement-mobile': () => div(classes: 'docs-demo-phone', [
    div(classes: 'docs-demo-phone-lines', [
      for (final width in ['70%', '100%', '90%', '50%']) span(styles: Styles(raw: {'width': width}), []),
    ]),
    Button(size: CoreComponentSize.lg, expanded: true, onPressed: () {}, child: const Text('다음')),
  ]),
  'button/theme-order': () => div(classes: 'docs-demo-order', [
    const Text('적용 순서 · 뒤로 갈수록 우선합니다').labelMedium.onSurfaceVariant,
    ol([
      for (final (index, step) in const ['디자인 시스템 기본값', '테마 기본값', '테마 variant별 값', '부모 슬롯', '인스턴스 buttonStyle'].indexed)
        li(classes: index == 4 ? 'is-strong' : null, [
          span([Component.text('${index + 1}')]),
          Component.text(step),
        ]),
    ]),
  ]),
  'button/a11y-icon-name': () => div(classes: 'docs-demo-caption', [
    Button(
      variant: CoreButtonVariant.outline,
      shape: CoreButtonShape.square,
      attributes: const {'aria-label': '항목 추가'},
      onPressed: () {},
      child: Icon(LucideIcons.plus),
    ),
    div([
      code([Component.text('aria-label="항목 추가"')]),
      const Text('아이콘만 있는 버튼은 웹에서 aria-label로 이름을 지정합니다.').bodySmall.onSurfaceVariant,
    ]),
  ]),
  'button/related-fab': () => Fab(trigger: Icon(LucideIcons.plus), onPressed: () {}),
  'button/related-toggle': () => docsWebDemoRow([
    Toggle(value: true, onChanged: (_) {}),
    Toggle(onChanged: (_) {}),
  ]),
  'button/related-menu': () => Menu(
    ariaLabel: '행동',
    items: [
      CoreMenuItem.action('복사', onPressed: () {}, active: true),
      CoreMenuItem.action('이름 변경', onPressed: () {}),
      CoreMenuItem.action('삭제', onPressed: () {}),
    ],
  ),
};

Component _button(Map<String, String> props, String? label) {
  final shape = previewEnum(CoreButtonShape.values, props['shape'], CoreButtonShape.rectangle);
  final iconOnly = shape != CoreButtonShape.rectangle;
  return Button(
    variant: previewEnum(CoreButtonVariant.values, props['variant'], CoreButtonVariant.primary),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreComponentSize.md),
    shape: shape,
    leading: iconOnly ? null : docsWebIcon(props['leading']),
    trailing: iconOnly ? null : docsWebIcon(props['trailing']),
    enabled: props.containsKey('enabled') ? previewFlag(props, 'enabled', fallback: true) : null,
    expanded: previewFlag(props, 'expanded'),
    href: props['href'],
    external: previewFlag(props, 'external'),
    onPressed: props['href'] == null ? () {} : null,
    child: iconOnly ? (docsWebIcon(props['icon']) ?? Icon(LucideIcons.plus)) : Text(label ?? '버튼'),
  );
}

Component _primary(String label) => Button(onPressed: () {}, child: Text(label));

Component _outline(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

/// 상태 격자의 열 이름.
const List<String> _stateColumns = ['기본', 'Hover', 'Pressed', 'Focus', '비활성'];

/// 상태 격자 — 쉬는 상태와 비활성은 실제 버튼, hover · pressed 는 그
/// 상태의 채움을 Core 기본값에서 읽어 고정한 버튼, focus 는 문서 시트가
/// 링을 그린다(브라우저는 포인터 없이 hover 를 켤 수 없다).
Component _buttonStates() {
  Component cell(CoreButtonVariant variant, String state) {
    final vs = CoreButtonStyle.defaultsByVariant[variant]!;
    final layer = vs.stateLayer;
    CoreColor? fill(double? alpha, CoreColor? solid) =>
        solid != null && layer == null ? solid : (alpha == null ? null : vs.foregroundColor.scaleAlpha(alpha));
    final style = switch (state) {
      'Hover' => CoreButtonStyle(backgroundColor: fill(layer?.hover, vs.hoverBackgroundColor)),
      'Pressed' => CoreButtonStyle(
        backgroundColor: fill(layer?.pressed, vs.pressedBackgroundColor ?? vs.hoverBackgroundColor),
      ),
      _ => null,
    };
    final button = Button(
      variant: variant,
      enabled: state != '비활성',
      buttonStyle: style,
      disableHoverEffect: true,
      onPressed: () {},
      child: const Text('저장하기'),
    );
    return state == 'Focus' ? span(classes: 'docs-demo-focus', [button]) : button;
  }

  return div(classes: 'docs-demo-states', [
    span([const Text('variant').labelSmall.onSurfaceVariant]),
    for (final column in _stateColumns) span([Text(column).labelSmall.onSurfaceVariant]),
    for (final variant in const [CoreButtonVariant.primary, CoreButtonVariant.outline]) ...[
      code([Component.text(variant.name)]),
      for (final column in _stateColumns) cell(variant, column),
    ],
  ]);
}
