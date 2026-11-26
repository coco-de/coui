/// MultiAnswerCard 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="multi-answer-card/...">` 가 읽는다. 같은 이름의 Web
/// 파일(`multi_answer_card_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'multi_answer_card_page.dart';

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _multiAnswerCard;

/// 장면 이름(`multi-answer-card/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'multi-answer-card/anatomy': () => _sized(
    MultiAnswerCard<String>(
      value: 'exercise',
      selected: true,
      onChanged: (_) {},
      child: const Text(multiAnswerPreviewAnswer),
    ),
  ),
  'multi-answer-card/states': _multiAnswerCardStates,
  'multi-answer-card/content': () => _sized(
    MultiAnswerCard<String>(
      value: 'breakfast',
      selected: true,
      onChanged: (_) {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(multiAnswerTwoLineTitle),
          const Text(multiAnswerTwoLineNote).bodySmall.onSurfaceVariant,
        ],
      ),
    ),
  ),
  'multi-answer-card/list': () => _sized(
    Column(
      mainAxisSize: MainAxisSize.min,
      spacing: CoreSpace.space8,
      children: [
        for (final (value, answer, selected) in multiAnswerListRows)
          MultiAnswerCard<String>(value: value, selected: selected, onChanged: (_) {}, child: Text(answer)),
      ],
    ),
  ),
  'multi-answer-card/related-multiple-choice': () => MultipleChoice<String>(
    options: const [(value: 'daily', label: '매일'), (value: 'weekly', label: '주 3회'), (value: 'rarely', label: '가끔')],
    value: 'daily',
    onChanged: (_) {},
  ),
};

/// 카드는 받은 폭을 채우므로 무대에는 폭을 정해 놓는다.
Widget _sized(Widget child) => SizedBox(width: 320, child: child);

Widget _multiAnswerCard(Map<String, String> props, String? label) => _sized(
  MultiAnswerCard<String>(
    value: 'exercise',
    selected: previewFlag(props, 'selected'),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
    child: Text(props['answer'] ?? label ?? multiAnswerPreviewAnswer),
  ),
);

/// 상태 장면 — Web 과 같은 네 상태.
Widget _multiAnswerCardStates() => Column(
  mainAxisSize: MainAxisSize.min,
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: CoreSpace.space12,
  children: [
    for (final (name, selected, enabled) in multiAnswerStateRows)
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: CoreSpace.space4,
        children: [
          Text(name).labelSmall.onSurfaceVariant,
          _sized(
            MultiAnswerCard<String>(
              value: name,
              selected: selected,
              enabled: enabled,
              onChanged: (_) {},
              child: const Text(multiAnswerPreviewAnswer),
            ),
          ),
        ],
      ),
  ],
);
