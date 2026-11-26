/// Dialog 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="dialog/...">` 가 읽는다. 같은 이름의 Flutter 파일(`dialog_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 패널은 그림이다. `Dialog` 는 열리면 오버레이 호스트의 대화상자 층에
/// 올라가 화면 전체를 덮고, 문서 본문은 늘 `CoUIWeb` 의 호스트 아래에 있다 —
/// 패널을 그 자리에 그리는 공개 경로가 없다. 그래서 그림은 패널의 겉모습을
/// `CoreDialogStyle` 의 기본값에서 읽어 그리고, 안의 제목 · 본문 · 간격 · 버튼은
/// 킷의 것(`Gap` · `Button` · 역할 글자)을 쓴다. 테마 · 서페이스 스타일은 그림에
/// 닿지 않는다. 실제 `Dialog` 는 플레이그라운드의 "열어 보기"가 연다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'dialog_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _dialog;

/// 장면 이름(`dialog/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'dialog/anatomy': () => _panel(
    leading: Icon(LucideIcons.triangleAlert),
    title: '변경 사항을 버릴까요?',
    close: true,
    content: '저장하지 않은 내용은 사라져요.',
    actions: [_outline('취소'), _destructive('버리기')],
  ),
  'dialog/alert': () => _panel(
    title: '저장하지 못했어요',
    content: '네트워크 연결이 끊겼어요. 잠시 뒤 다시 시도해 주세요.',
    actions: [_primary('확인')],
  ),
  'dialog/with-icon': () => _panel(
    leading: Icon(LucideIcons.triangleAlert),
    title: '경고',
    close: true,
    content: '이 작업은 되돌릴 수 없어요.',
  ),
  'dialog/do-clear-result': () => _panel(
    title: '계정을 삭제할까요?',
    content: '계정을 삭제하면 모든 데이터가 영구적으로 지워지고, 되돌릴 수 없어요.',
    actions: [_outline('취소'), _destructive('계정 삭제')],
  ),
  'dialog/dont-vague': () => _panel(
    title: '확인',
    content: '진행할까요?',
    actions: [_primary('확인')],
  ),
  'dialog/do-one-decision': () => _panel(
    title: '변경 사항을 저장할까요?',
    content: '저장하지 않은 변경 사항이 있어요.',
    actions: [_outline('저장 안 함'), _primary('저장')],
  ),
  'dialog/dont-too-much': () => _panel(
    title: '설정',
    body: div(
      styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12)}),
      [
        for (final label in const ['이름', '이메일', '회사', '전화번호']) TextField(label: label),
      ],
    ),
    actions: [_outline('취소'), _primary('저장')],
  ),
  'dialog/do-close-path': () => _panel(
    title: '내보내기를 마쳤어요',
    content: '파일은 다운로드 폴더에 있어요.',
    actions: [_primary('확인')],
  ),
  'dialog/dont-no-close': () => _panel(
    title: '내보내기를 마쳤어요',
    content: '파일은 다운로드 폴더에 있어요.',
  ),
  'dialog/placement-stacked': () => _panel(
    title: '나가기 전에 저장할까요?',
    content: '저장하지 않은 변경 사항이 있어요.',
    actions: [_outline('저장하지 않고 나가기'), _primary('저장')],
    layout: CoreDialogActionsLayout.stretch,
  ),
};

Component _dialog(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _DialogOpener(props: props, label: label);
  return _propPanel(props, label);
}

/// 속성으로 고른 패널 그림.
Component _propPanel(Map<String, String> props, String? label) => _panel(
  leading: docsWebIcon(props['leading']),
  title: label ?? page.demoTitle,
  close: props['trailing'] != null,
  content: previewFlag(props, 'content') ? page.demoContent : null,
  actions: _propActions(props, () {}),
  layout: _layoutOf(props),
);

CoreDialogActionsLayout _layoutOf(Map<String, String> props) =>
    previewEnum(CoreDialogActionsLayout.values, props['actionsLayout'], CoreDialogStyle.defaultActionsLayout);

List<Component> _propActions(Map<String, String> props, void Function() onPressed) => [
  if (page.demoHasTwoActions(props))
    Button(variant: CoreButtonVariant.outline, onPressed: onPressed, child: const Text(page.demoCancel)),
  Button(onPressed: onPressed, child: const Text(page.demoConfirm)),
];

Component _primary(String label) => Button(onPressed: () {}, child: Text(label));

Component _outline(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

Component _destructive(String label) =>
    Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: Text(label));

/// 제목 뒤의 닫기 버튼 — 아이콘만 있어 이름을 `aria-label` 로 준다.
Component _closeButton(void Function() onPressed) => Button(
  variant: CoreButtonVariant.plain,
  size: CoreComponentSize.sm,
  shape: CoreButtonShape.square,
  attributes: const {'aria-label': '닫기'},
  onPressed: onPressed,
  child: Icon(LucideIcons.x),
);

/// 패널 그림 — 겉모습은 `CoreDialogStyle` 의 기본값, 배치는 `Dialog` 의 패널과 같다.
///
/// 머리 줄(leading · title · trailing), 본문, 행동 줄을 같은 간격 슬롯
/// (`defaultSectionGapStyle` · `defaultActionsGapStyle`)으로 잇는다. stretch 의
/// 행동 칸은 `Dialog` 와 같은 규칙이다 — 같은 몫에서 시작해 줄을 채우고, 몫보다
/// 넓은 행동은 다음 줄로 넘어간다. 부분마다 `data-docs-part` 를 달아 구조 블록이
/// 번호를 붙인다.
Component _panel({
  required String title,
  Component? leading,
  bool close = false,
  String? content,
  Component? body,
  List<Component> actions = const [],
  CoreDialogActionsLayout layout = CoreDialogStyle.defaultActionsLayout,
}) {
  const colors = CoreDialogStyle.defaultsByVariant;
  final titleText = emitTypography(null, CoreDialogStyle.defaultTitleStyle);
  final contentText = emitTypography(null, CoreDialogStyle.defaultContentStyle);
  final sectionGap = Gap(gapStyle: CoreDialogStyle.defaultSectionGapStyle);
  final actionGap = spaceCss(CoreDialogStyle.defaultActionSpacing);
  final stretch = layout == CoreDialogActionsLayout.stretch;
  final width = stretch ? CoreLayout.layout320 : CoreLayout.layout400;
  final bodyNode = body ?? (content == null ? null : Text(content));

  Component seat(Component action) => !stretch
      ? action
      : div(
          styles: Styles(
            raw: {
              'display': 'flex',
              'flex-direction': 'column',
              'flex-grow': '1',
              'min-width': 'fit-content',
              'flex-basis': actions.length == 1
                  ? '100%'
                  : 'calc((100% - ${actions.length - 1} * $actionGap) / ${actions.length})',
            },
          ),
          [action],
        );

  return div(
    attributes: const {'data-docs-part': 'panel'},
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'box-sizing': 'border-box',
        'width': 'min(100%, ${pinnedLengthCss(width)})',
        'padding': CoreDialogStyle.defaultPanelPadding.toValue(),
        'border': '${strokeWidthCss(CoreDialogStyle.defaultPanelBorderWidth)} solid ${colors.borderColor.toValue()}',
        'border-radius': CoreDialogStyle.defaultPanelBorderRadius.toValue(),
        'background-color': colors.backgroundColor.toValue(),
        'color': colors.foregroundColor.toValue(),
        'box-shadow': emitShadow(
          CoreDialogStyle.defaultPanelBoxShadow,
          base: CoreDialogStyle.defaultShadowBaseColor.toValue(),
        ),
      },
    ),
    [
      div(styles: Styles(raw: {'display': 'flex', 'align-items': 'center'}), [
        if (leading != null) ...[leading, sectionGap],
        div(
          attributes: const {'data-docs-part': 'title'},
          classes: titleText.className,
          styles: Styles(raw: {'flex': '1', ...?titleText.inline}),
          [Text(title)],
        ),
        if (close) ...[sectionGap, _closeButton(() {})],
      ]),
      if (bodyNode != null) ...[
        sectionGap,
        div(
          attributes: const {'data-docs-part': 'content'},
          classes: contentText.className,
          styles: contentText.inline == null ? null : Styles(raw: contentText.inline!),
          [bodyNode],
        ),
      ],
      if (actions.isNotEmpty) ...[
        Gap(gapStyle: CoreDialogStyle.defaultActionsGapStyle),
        div(
          attributes: const {'data-docs-part': 'actions'},
          styles: Styles(
            raw: {
              'display': 'flex',
              'flex-wrap': 'wrap',
              'justify-content': 'flex-end',
              'align-items': 'center',
              'column-gap': actionGap,
              'row-gap': spaceCss(CoreDialogStyle.defaultActionRunSpacing),
            },
          ),
          [for (final action in actions) seat(action)],
        ),
      ],
    ],
  );
}

/// 플레이그라운드의 미리보기 — 패널 그림 아래의 버튼이 같은 속성의 실제
/// `Dialog` 를 연다.
///
/// 열린 `Dialog` 는 플레이그라운드의 오버레이 호스트에 올라가 화면을 덮는다.
/// 스크림 · Escape · 행동 버튼이 닫는다.
class _DialogOpener extends StatefulComponent {
  const _DialogOpener({required this.props, required this.label});

  final Map<String, String> props;
  final String? label;

  @override
  State<_DialogOpener> createState() => _DialogOpenerState();
}

class _DialogOpenerState extends State<_DialogOpener> {
  bool _open = false;

  void _setOpen(bool open) => setState(() => _open = open);

  @override
  Component build(BuildContext context) {
    final props = component.props;
    void close() => _setOpen(false);
    return div(
      styles: Styles(
        raw: {
          'display': 'flex',
          'flex-direction': 'column',
          'align-items': 'center',
          'gap': spaceCss(CoreSpace.space16),
          'width': '100%',
        },
      ),
      [
        _propPanel(props, component.label),
        Button(
          variant: CoreButtonVariant.outline,
          size: CoreComponentSize.sm,
          onPressed: () => _setOpen(true),
          child: const Text(page.demoOpener),
        ),
        Dialog(
          open: _open,
          onClose: close,
          leading: docsWebIcon(props['leading']),
          title: Text(component.label ?? page.demoTitle),
          trailing: props['trailing'] == null ? null : _closeButton(close),
          content: previewFlag(props, 'content') ? const Text(page.demoContent) : null,
          actions: _propActions(props, close),
          dialogStyle: _layoutOf(props) == CoreDialogActionsLayout.stretch
              ? const CoreDialogStyle(actionsLayout: CoreDialogActionsLayout.stretch)
              : null,
        ),
      ],
    );
  }
}
