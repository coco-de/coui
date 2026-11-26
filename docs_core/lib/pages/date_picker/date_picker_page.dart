/// DatePicker 페이지 — 플레이그라운드와 미리보기가 같이 쓰는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `date_picker_web.dart` · `date_picker_flutter.dart` 가 그린다. 이
/// 폴더는 `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 미리보기의 날짜 · 글자는 아래 상수 한 곳에 둔다 — 두 플랫폼의 그림과
/// 플레이그라운드의 코드가 같은 값을 쓴다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/date-picker.md`.
const String slug = 'date-picker';

/// 미리보기가 고른 날짜. 범위 미리보기에서는 시작 날짜다.
const String previewDate = '2026-12-24';

/// 범위 미리보기의 끝 날짜.
const String previewRangeEnd = '2026-12-27';

/// 달력 그림이 여는 달 — 고정해야 그림이 오늘 날짜에 따라 바뀌지 않는다.
const CoreCalendarView previewView = CoreCalendarView(2026, 12);

/// 미리보기의 라벨.
const String previewLabel = '예약 날짜';

/// 날짜 하나를 고르는 미리보기의 안내 문구.
const String previewPlaceholder = '날짜를 선택해 주세요';

/// 범위를 고르는 미리보기의 안내 문구.
const String previewRangePlaceholder = '기간을 선택해 주세요';

/// 미리보기의 도움말.
const String previewDescription = '방문할 날짜를 고르세요.';

/// 미리보기의 오류 문구.
const String previewError = '예약 날짜를 확인해 주세요.';

/// 날짜 하나를 고르는 대화상자의 제목.
const String previewDialogTitle = '날짜 선택';

/// 범위를 고르는 대화상자의 제목.
const String previewRangeDialogTitle = '기간 선택';

/// [previewDate] 를 Flutter · Calendar 가 받는 값으로 읽은 것.
DateTime get previewDateTime => DateTime.parse(previewDate);

/// [previewRangeEnd] 를 읽은 것.
DateTime get previewRangeEndTime => DateTime.parse(previewRangeEnd);

/// 속성이 안내 문구를 주지 않으면 고르는 대상에 맞는 문구를 쓴다.
String previewPlaceholderOf(Map<String, String> props) =>
    props['placeholder'] ?? (previewFlag(props, 'range') ? previewRangePlaceholder : previewPlaceholder);

/// 주말을 고를 수 없게 하는 `stateBuilder` — `date-picker/weekdays` 장면.
CoreCalendarDateState weekdaysOnly(DateTime date) =>
    date.weekday >= DateTime.saturday ? CoreCalendarDateState.disabled : CoreCalendarDateState.enabled;

/// 플레이그라운드. 없는 컴포넌트는 `null`.
///
/// `range` 는 위젯의 속성이 아니라 미리보기의 손잡이다 — 켜면 `DatePicker`
/// 대신 `DateRangePicker` 를 그린다. `value` 는 날짜를 미리 고른 상태이고,
/// 코드에서는 앱의 상태 변수(`selectedDate` · `selectedRange`)가 그 값을 든다.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'mode': 'popover', 'label': previewLabel},
  controls: [
    DocsPlaygroundChoice(label: 'mode', prop: 'mode', options: ['popover', 'dialog'], segmented: true),
    DocsPlaygroundFlag(label: '기간 선택', on: {'range': 'true'}),
    DocsPlaygroundFlag(label: '선택됨', on: {'value': previewDate}),
    DocsPlaygroundFlag(label: '도움말', on: {'description': previewDescription}),
    DocsPlaygroundFlag(label: '오류', on: {'errorText': previewError}),
    DocsPlaygroundFlag(label: '비활성', on: {'enabled': 'false'}),
  ],
  code: _datePickerCode,
);

/// 크기 표. DatePicker 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

String _datePickerCode(Map<String, String> props, String? label) {
  final range = previewFlag(props, 'range');
  final defaultMode = range ? 'dialog' : 'popover';
  final mode = props['mode'] ?? defaultMode;
  final placeholder = previewPlaceholderOf(props);
  final lines = [
    if (range) 'value: selectedRange,' else 'value: selectedDate,',
    if (range) 'onChanged: setRange,' else 'onChanged: setDate,',
    if (mode != defaultMode) 'mode: CorePromptMode.$mode,',
    if (props['label'] case final v?) "label: '$v',",
    if (range) "placeholder: Text('$placeholder')," else "placeholder: '$placeholder',",
    if (props['description'] case final v?) "description: '$v',",
    if (props['errorText'] case final v?) "errorText: '$v',",
    if (mode == 'dialog') "dialogTitle: Text('${range ? previewRangeDialogTitle : previewDialogTitle}'),",
    if (!previewFlag(props, 'enabled', fallback: true)) 'enabled: false,',
  ];
  final name = range ? 'DateRangePicker' : 'DatePicker';
  return '$name(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
