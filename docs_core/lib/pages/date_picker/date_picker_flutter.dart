/// DatePicker 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="date-picker/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`date_picker_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
///
/// Flutter 의 DatePicker 는 넘긴 `value` 만 보여 주므로, 속성 미리보기는 고른
/// 날짜를 스스로 든다 — 그래야 플레이그라운드에서 고른 값이 트리거에 남는다.
///
/// 열린 달력 장면은 그림이다. 팝오버와 대화상자는 열려야만 패널을 만든다.
/// 달력은 실제 `Calendar` 로, 팝오버의 판은 킷의 `Popup` 에
/// `CorePopoverStyle.defaultPanelStyle` 을 넘겨 그리고, 대화상자의 틀은
/// `resolveDialog` 가 낸 값(테마 포함)으로 그린다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'date_picker_page.dart' as page;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _datePicker;

/// 장면 이름(`date-picker/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'date-picker/anatomy': () => _sized(
    DatePicker(
      label: page.previewLabel,
      value: page.previewDateTime,
      description: page.previewDescription,
      onChanged: (_) {},
    ),
  ),
  'date-picker/popover-calendar': () => _popoverPicture(_singleCalendar()),
  'date-picker/dialog-panel': () => const _DialogPicture(),
  'date-picker/range-calendar': () => FittedBox(
    fit: BoxFit.scaleDown,
    child: _popoverPicture(
      Calendar(
        selectionMode: CoreCalendarSelectionMode.range,
        value: CoreCalendarValue.range(page.previewDateTime, page.previewRangeEndTime),
        initialView: page.previewView,
      ),
    ),
  ),
  'date-picker/weekdays': () => _popoverPicture(
    const Calendar(stateBuilder: page.weekdaysOnly, initialView: page.previewView),
  ),
  'date-picker/states': _states,
  'date-picker/dont-two-pickers': () => _sized(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: CoreSpace.space12,
      children: [
        DatePicker(label: '시작일', value: page.previewDateTime, onChanged: (_) {}),
        DatePicker(label: '종료일', value: DateTime(2026, 12, 20), onChanged: (_) {}),
      ],
    ),
  ),
};

Widget _sized(Widget child) => SizedBox(width: 240, child: child);

Widget _datePicker(Map<String, String> props, String? label) => _sized(_DatePickerPreview(props: props));

Widget _singleCalendar() => Calendar(
  value: CoreCalendarValue.single(page.previewDateTime),
  initialView: page.previewView,
);

/// 팝오버 패널 그림 — 판은 킷의 `Popup` 이다.
Widget _popoverPicture(Widget calendar) => Popup(
  popupStyle: CorePopoverStyle.defaultPanelStyle,
  children: [calendar],
);

/// 속성으로 고른 DatePicker 또는 DateRangePicker.
class _DatePickerPreview extends StatefulWidget {
  const _DatePickerPreview({required this.props});

  final Map<String, String> props;

  @override
  State<_DatePickerPreview> createState() => _DatePickerPreviewState();
}

class _DatePickerPreviewState extends State<_DatePickerPreview> {
  DateTime? _date;
  DateTimeRange? _range;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void didUpdateWidget(_DatePickerPreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.props['value'] != widget.props['value']) _seed();
  }

  void _seed() {
    final start = DateTime.tryParse(widget.props['value'] ?? '');
    _date = start;
    _range = start == null ? null : DateTimeRange(start, page.previewRangeEndTime);
  }

  @override
  Widget build(BuildContext context) {
    final props = widget.props;
    final range = previewFlag(props, 'range');
    final mode = previewEnum(
      CorePromptMode.values,
      props['mode'],
      range ? CorePromptMode.dialog : CorePromptMode.popover,
    );
    final enabled = previewFlag(props, 'enabled', fallback: true);
    if (range) {
      return DateRangePicker(
        value: _range,
        onChanged: (next) => setState(() => _range = next),
        mode: mode,
        label: props['label'],
        placeholder: Text(page.previewPlaceholderOf(props)),
        description: props['description'],
        errorText: props['errorText'],
        enabled: enabled,
        dialogTitle: const Text(page.previewRangeDialogTitle),
      );
    }
    return DatePicker(
      value: _date,
      onChanged: (next) => setState(() => _date = next),
      mode: mode,
      label: props['label'],
      placeholder: page.previewPlaceholderOf(props),
      description: props['description'],
      errorText: props['errorText'],
      enabled: enabled,
      dialogTitle: const Text(page.previewDialogTitle),
    );
  }
}

/// 대화상자 패널 그림 — DatePicker 가 여는 대화상자의 내용(제목 · 달력 ·
/// 취소 · 저장)을 `resolveDialog` 가 낸 값으로 놓는다. 폭과 달력의 배치는
/// `Dialog` 와 같다 — 패널은 최대 폭까지 늘고, 달력의 머리 줄은 본문 폭을
/// 채우며 날짜 칸은 가운데에 놓인다.
class _DialogPicture extends StatelessWidget {
  const _DialogPicture();

  @override
  Widget build(BuildContext context) {
    final resolved = resolveDialog(context);
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: resolved.panelMinWidth, maxWidth: resolved.panelMaxWidth),
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle.merge(
                  style: resolved.titleTextStyle,
                  child: const Text(page.previewDialogTitle),
                ),
                Gap(gapStyle: resolved.sectionGapStyle),
                DefaultTextStyle.merge(style: resolved.contentTextStyle, child: _singleCalendar()),
                Gap(gapStyle: resolved.actionsGapStyle),
                Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: resolved.actionSpacing,
                  runSpacing: resolved.actionRunSpacing,
                  children: [
                    Button(variant: CoreButtonVariant.secondary, onPressed: () {}, child: const Text('취소')),
                    Button(onPressed: () {}, child: const Text('저장')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 상태 격자 — Web 과 같은 네 칸.
Widget _states() {
  const columns = ['기본', '선택됨', '오류', '비활성'];
  Widget cell(String state) => SizedBox(
    width: 152,
    child: switch (state) {
      '선택됨' => DatePicker(value: page.previewDateTime, onChanged: (_) {}),
      '오류' => DatePicker(placeholder: '날짜 선택', errorText: '필수 항목', onChanged: (_) {}),
      '비활성' => DatePicker(value: page.previewDateTime, enabled: false, onChanged: (_) {}),
      _ => DatePicker(placeholder: '날짜 선택', onChanged: (_) {}),
    },
  );
  return Wrap(
    spacing: CoreSpace.space12,
    runSpacing: CoreSpace.space12,
    children: [
      for (final column in columns)
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: CoreSpace.space8,
          children: [Text(column).labelSmall.onSurfaceVariant, cell(column)],
        ),
    ],
  );
}
