/// DatePicker 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="date-picker/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`date_picker_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// 열린 달력 장면은 그림이다. 팝오버와 대화상자는 열려야만 패널을 만들고,
/// 사이트의 플레이그라운드 밖 무대는 브라우저에서 깨어나지 않는다. 그래서
/// 달력은 실제 `Calendar` 로, 팝오버의 판은 킷의 `Popup` 에
/// `CorePopoverStyle.defaultPanelStyle` 을 넘겨 그린다. 대화상자의 틀은
/// `CoreDialogStyle` 의 기본값으로 그린다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'date_picker_page.dart' as page;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _datePicker;

/// 장면 이름(`date-picker/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  'date-picker/anatomy': () => _sized(
    DatePicker(
      attributes: const {'data-docs-part': 'picker'},
      label: page.previewLabel,
      value: page.previewDate,
      description: page.previewDescription,
      onChanged: (_) {},
    ),
  ),
  'date-picker/popover-calendar': () => _popoverPicture(_singleCalendar()),
  'date-picker/dialog-panel': _dialogPicture,
  'date-picker/range-calendar': () => _scrollable(
    _popoverPicture(
      Calendar(
        selectionMode: CoreCalendarSelectionMode.range,
        value: CoreCalendarValue.range(page.previewDateTime, page.previewRangeEndTime),
        initialView: page.previewView,
      ),
    ),
  ),
  'date-picker/weekdays': () => _popoverPicture(
    Calendar(stateBuilder: page.weekdaysOnly, initialView: page.previewView),
  ),
  'date-picker/states': _states,
  'date-picker/dont-two-pickers': () => _sized(
    div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': spaceCss(CoreSpace.space12)}), [
      DatePicker(label: '시작일', value: page.previewDate, onChanged: (_) {}),
      DatePicker(label: '종료일', value: '2026-12-20', onChanged: (_) {}),
    ]),
  ),
};

Component _sized(Component child) => div(styles: Styles(raw: {'width': '15rem'}), [child]);

Component _datePicker(Map<String, String> props, String? label) {
  final range = previewFlag(props, 'range');
  final selected = props['value'];
  final mode = previewEnum(
    CorePromptMode.values,
    props['mode'],
    range ? CorePromptMode.dialog : CorePromptMode.popover,
  );
  final enabled = previewFlag(props, 'enabled', fallback: true);
  return _sized(
    range
        ? DateRangePicker(
            value: selected == null ? null : (start: selected, end: page.previewRangeEnd),
            onChanged: (_) {},
            mode: mode,
            label: props['label'],
            placeholder: Text(page.previewPlaceholderOf(props)),
            description: props['description'],
            errorText: props['errorText'],
            enabled: enabled,
            dialogTitle: const Text(page.previewRangeDialogTitle),
          )
        : DatePicker(
            value: selected,
            onChanged: (_) {},
            mode: mode,
            label: props['label'],
            placeholder: page.previewPlaceholderOf(props),
            description: props['description'],
            errorText: props['errorText'],
            enabled: enabled,
            dialogTitle: const Text(page.previewDialogTitle),
          ),
  );
}

Component _singleCalendar() => Calendar(
  value: CoreCalendarValue.single(page.previewDateTime),
  initialView: page.previewView,
);

/// 팝오버 패널 그림 — 판은 킷의 `Popup` 이다. `Popup` 의 기본 역할(`menu`)은
/// 그림에 맞지 않아 지운다. `Popup` 은 부모 폭을 채우므로 제 폭만큼의 상자에
/// 담는다.
Component _popoverPicture(Component calendar) => div(styles: Styles(raw: {'width': 'max-content'}), [
  Popup(
    attributes: const {'role': 'presentation'},
    popupStyle: CorePopoverStyle.defaultPanelStyle,
    children: [calendar],
  ),
]);

/// 두 달 폭의 그림 — 좁은 화면에서는 무대 안에서 옆으로 스크롤한다. 안쪽
/// 여백은 스크롤 상자가 판의 그림자를 자르지 않게 둔다.
Component _scrollable(Component picture) => div(
  styles: Styles(
    raw: {'max-width': '100%', 'overflow-x': 'auto', 'padding': spaceCss(CoreSpace.space16)},
  ),
  [picture],
);

/// 대화상자 패널 그림 — DatePicker 가 여는 대화상자의 내용(제목 · 달력 ·
/// 취소 · 저장)을 `CoreDialogStyle` 의 기본값으로 놓는다. 폭과 달력의 배치는
/// `Dialog` 와 같다 — 패널은 최대 폭까지 늘고, 달력은 제 폭으로 가운데에
/// 놓인다.
Component _dialogPicture() {
  const colors = CoreDialogStyle.defaultsByVariant;
  final titleText = emitTypography(null, CoreDialogStyle.defaultTitleStyle);
  return div(
    styles: Styles(
      raw: {
        'display': 'flex',
        'flex-direction': 'column',
        'box-sizing': 'border-box',
        'width': 'min(100%, ${pinnedLengthCss(CoreDialogStyle.defaultPanelMaxWidth)})',
        'min-width': 'min(100%, ${pinnedLengthCss(CoreDialogStyle.defaultPanelMinWidth)})',
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
      div(
        classes: titleText.className,
        styles: titleText.inline == null ? null : Styles(raw: titleText.inline!),
        [const Text(page.previewDialogTitle)],
      ),
      Gap(gapStyle: CoreDialogStyle.defaultSectionGapStyle),
      div(styles: Styles(raw: {'display': 'flex', 'justify-content': 'center'}), [_singleCalendar()]),
      Gap(gapStyle: CoreDialogStyle.defaultActionsGapStyle),
      div(
        styles: Styles(
          raw: {
            'display': 'flex',
            'justify-content': 'flex-end',
            'column-gap': spaceCss(CoreDialogStyle.defaultActionSpacing),
          },
        ),
        [
          Button(variant: CoreButtonVariant.secondary, onPressed: () {}, child: const Text('취소')),
          Button(onPressed: () {}, child: const Text('저장')),
        ],
      ),
    ],
  );
}

/// 상태 격자 — 네 칸 모두 실제 DatePicker 다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _states() {
  const columns = ['기본', '선택됨', '오류', '비활성'];
  Component cell(String state) => div(styles: Styles(raw: {'width': '9.5rem'}), [
    switch (state) {
      '선택됨' => DatePicker(value: page.previewDate, onChanged: (_) {}),
      '오류' => DatePicker(placeholder: '날짜 선택', errorText: '필수 항목', onChanged: (_) {}),
      '비활성' => DatePicker(value: page.previewDate, enabled: false, onChanged: (_) {}),
      _ => DatePicker(placeholder: '날짜 선택', onChanged: (_) {}),
    },
  ]);
  return div(
    classes: 'docs-demo-field-states',
    styles: Styles(raw: {'grid-template-columns': 'repeat(${columns.length}, max-content)'}),
    [
      for (final column in columns) span([Text(column).labelSmall.onSurfaceVariant]),
      for (final column in columns) cell(column),
    ],
  );
}
