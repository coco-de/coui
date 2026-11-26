/// Dialog 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card>` · 플레이그라운드가, 장면은
/// `<Preview demo="dialog/...">` 가 읽는다. 같은 이름의 Web 파일(`dialog_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 무대의 패널은 그림이다. `Dialog` 는 열리면 루트 내비게이터에 라우트를
/// 올리고 — 네이티브 문서 앱에서는 앱 전체를 덮는다 — 패널을 그 자리에 그리는
/// 공개 경로가 없다. 그래서 그림은 `resolveDialog` 가 낸 값(테마 포함)으로
/// 패널을 그리고, 안의 제목 · 본문 · 간격 · 버튼은 킷의 것을 쓴다. 실제
/// `Dialog` 는 플레이그라운드의 "열어 보기"가 연다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'dialog_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _dialog;

/// 장면 이름(`dialog/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'dialog/anatomy': () => _DialogPicture(
    leading: const Icon(LucideIcons.triangleAlert),
    title: '변경 사항을 버릴까요?',
    close: true,
    content: '저장하지 않은 내용은 사라져요.',
    actions: [_outline('취소'), _destructive('버리기')],
  ),
  'dialog/alert': () => _DialogPicture(
    title: '저장하지 못했어요',
    content: '네트워크 연결이 끊겼어요. 잠시 뒤 다시 시도해 주세요.',
    actions: [_primary('확인')],
  ),
  'dialog/with-icon': () => const _DialogPicture(
    leading: Icon(LucideIcons.triangleAlert),
    title: '경고',
    close: true,
    content: '이 작업은 되돌릴 수 없어요.',
  ),
  'dialog/do-clear-result': () => _DialogPicture(
    title: '계정을 삭제할까요?',
    content: '계정을 삭제하면 모든 데이터가 영구적으로 지워지고, 되돌릴 수 없어요.',
    actions: [_outline('취소'), _destructive('계정 삭제')],
  ),
  'dialog/dont-vague': () => _DialogPicture(
    title: '확인',
    content: '진행할까요?',
    actions: [_primary('확인')],
  ),
  'dialog/do-one-decision': () => _DialogPicture(
    title: '변경 사항을 저장할까요?',
    content: '저장하지 않은 변경 사항이 있어요.',
    actions: [_outline('저장 안 함'), _primary('저장')],
  ),
  'dialog/dont-too-much': () => _DialogPicture(
    title: '설정',
    body: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space12,
      children: [
        for (final label in const ['이름', '이메일', '회사', '전화번호']) TextField(label: label),
      ],
    ),
    actions: [_outline('취소'), _primary('저장')],
  ),
  'dialog/do-close-path': () => _DialogPicture(
    title: '내보내기를 마쳤어요',
    content: '파일은 다운로드 폴더에 있어요.',
    actions: [_primary('확인')],
  ),
  'dialog/dont-no-close': () => const _DialogPicture(
    title: '내보내기를 마쳤어요',
    content: '파일은 다운로드 폴더에 있어요.',
  ),
  'dialog/placement-stacked': () => _DialogPicture(
    title: '나가기 전에 저장할까요?',
    content: '저장하지 않은 변경 사항이 있어요.',
    actions: [_outline('저장하지 않고 나가기'), _primary('저장')],
    layout: CoreDialogActionsLayout.stretch,
    stacked: true,
  ),
};

Widget _dialog(Map<String, String> props, String? label) {
  if (previewFlag(props, 'opener')) return _DialogOpener(props: props, label: label);
  return _propPicture(props, label);
}

/// 속성으로 고른 패널 그림.
Widget _propPicture(Map<String, String> props, String? label) => _DialogPicture(
  leading: docsFlutterIcon(props['leading']),
  title: label ?? page.demoTitle,
  close: props['trailing'] != null,
  content: previewFlag(props, 'content') ? page.demoContent : null,
  actions: _propActions(props, () {}),
  layout: _layoutOf(props),
);

CoreDialogActionsLayout _layoutOf(Map<String, String> props) =>
    previewEnum(CoreDialogActionsLayout.values, props['actionsLayout'], CoreDialogStyle.defaultActionsLayout);

List<Widget> _propActions(Map<String, String> props, VoidCallback onPressed) => [
  if (page.demoHasTwoActions(props))
    Button(variant: CoreButtonVariant.outline, onPressed: onPressed, child: const Text(page.demoCancel)),
  Button(onPressed: onPressed, child: const Text(page.demoConfirm)),
];

Widget _primary(String label) => Button(onPressed: () {}, child: Text(label));

Widget _outline(String label) => Button(variant: CoreButtonVariant.outline, onPressed: () {}, child: Text(label));

Widget _destructive(String label) =>
    Button(variant: CoreButtonVariant.destructive, onPressed: () {}, child: Text(label));

/// 제목 뒤의 닫기 버튼.
Widget _closeButton(VoidCallback onPressed) => Button(
  variant: CoreButtonVariant.plain,
  size: CoreComponentSize.sm,
  shape: CoreButtonShape.square,
  onPressed: onPressed,
  child: const Icon(LucideIcons.x),
);

/// 패널 그림 — 겉모습은 `resolveDialog` 가 낸 값, 배치는 `Dialog` 의 패널과 같다.
///
/// stretch 의 행동 줄은 그림이 고른다 — 같은 몫으로 나눈 한 줄, [stacked] 면
/// 세로로 쌓은 줄. `Dialog` 는 행동이 몫에 들어가는지를 재서 둘 중 하나를
/// 고르지만, 그 배치(`DialogActionsStretchLayout`)는 공개되지 않았다.
class _DialogPicture extends StatelessWidget {
  const _DialogPicture({
    required this.title,
    this.leading,
    this.close = false,
    this.content,
    this.body,
    this.actions = const [],
    this.layout = CoreDialogStyle.defaultActionsLayout,
    this.stacked = false,
  });

  final String title;
  final Widget? leading;
  final bool close;
  final String? content;
  final Widget? body;
  final List<Widget> actions;
  final CoreDialogActionsLayout layout;
  final bool stacked;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDialog(context);
    final bodyWidget = body ?? (content == null ? null : Text(content!));
    final stretch = layout == CoreDialogActionsLayout.stretch;
    final actionsRow = switch ((stretch, stacked)) {
      (false, _) => Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: resolved.actionSpacing,
        runSpacing: resolved.actionRunSpacing,
        children: actions,
      ),
      (true, true) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: resolved.actionRunSpacing,
        children: actions,
      ),
      (true, false) => Row(
        spacing: resolved.actionSpacing,
        children: [for (final action in actions) Expanded(child: action)],
      ),
    };

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: stretch ? CoreLayout.layout320 : CoreLayout.layout400),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: resolved.panelBackgroundColor,
          border: Border.all(color: resolved.panelBorderColor, width: resolved.panelBorderWidth),
          borderRadius: resolved.panelBorderRadius,
          boxShadow: resolved.panelBoxShadow,
        ),
        child: Padding(
          padding: resolved.panelPadding,
          child: DefaultTextStyle.merge(
            style: TextStyle(color: resolved.panelForegroundColor),
            child: IconTheme.merge(
              data: IconThemeData(color: resolved.panelForegroundColor),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      if (leading != null) ...[leading!, Gap(gapStyle: resolved.sectionGapStyle)],
                      Expanded(
                        child: DefaultTextStyle.merge(style: resolved.titleTextStyle, child: Text(title)),
                      ),
                      if (close) ...[Gap(gapStyle: resolved.sectionGapStyle), _closeButton(() {})],
                    ],
                  ),
                  if (bodyWidget != null) ...[
                    Gap(gapStyle: resolved.sectionGapStyle),
                    DefaultTextStyle.merge(style: resolved.contentTextStyle, child: bodyWidget),
                  ],
                  if (actions.isNotEmpty) ...[Gap(gapStyle: resolved.actionsGapStyle), actionsRow],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 플레이그라운드의 미리보기 — 패널 그림 아래의 버튼이 같은 속성의 실제
/// `Dialog` 를 연다.
///
/// 열린 `Dialog` 는 루트 내비게이터에 라우트를 올린다 — 사이트의 임베드에서는
/// 임베드 안을, 네이티브 문서 앱에서는 앱 전체를 덮는다. 스크림 · Escape ·
/// 행동 버튼이 닫는다. `Dialog` 는 속성마다 새로 만든다: 열린 동안 바뀐
/// `dialogStyle` 을 열려 있는 패널이 따라가지 않기 때문이다.
class _DialogOpener extends StatefulWidget {
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
  Widget build(BuildContext context) {
    final props = widget.props;
    void close() => _setOpen(false);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _propPicture(props, widget.label),
        const Gap(gapStyle: CoreGapStyle(size: CoreSpace.space16)),
        Button(
          variant: CoreButtonVariant.outline,
          size: CoreComponentSize.sm,
          onPressed: () => _setOpen(true),
          child: const Text(page.demoOpener),
        ),
        Dialog(
          key: ValueKey(
            {
              for (final e in props.entries)
                if (e.key != 'opener') e.key: e.value,
            }.toString(),
          ),
          open: _open,
          onClose: close,
          leading: docsFlutterIcon(props['leading']),
          title: Text(widget.label ?? page.demoTitle),
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
