/// MultiAnswerCard 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card props>` · 플레이그라운드가, 장면은
/// `<Preview demo="multi-answer-card/...">` 가 읽는다. 같은 이름의 Flutter
/// 파일(`multi_answer_card_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야
/// 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'multi_answer_card_page.dart';

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _multiAnswerCard;

/// 장면 이름(`multi-answer-card/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
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
      child: div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}), [
        const Text(multiAnswerTwoLineTitle),
        const Text(multiAnswerTwoLineNote).bodySmall.onSurfaceVariant,
      ]),
    ),
  ),
  'multi-answer-card/list': () => _sized(
    _column(gap: 'var(--coui-space-8)', [
      for (final (value, answer, selected) in multiAnswerListRows)
        MultiAnswerCard<String>(value: value, selected: selected, onChanged: (_) {}, child: Text(answer)),
    ]),
  ),
  'multi-answer-card/related-multiple-choice': () => MultipleChoice<String>(
    options: const [(value: 'daily', label: '매일'), (value: 'weekly', label: '주 3회'), (value: 'rarely', label: '가끔')],
    value: 'daily',
    onChanged: (_) {},
  ),
};

/// 카드는 받은 폭을 채우므로 무대에는 폭을 정해 놓는다.
Component _sized(Component child) => div(styles: Styles(raw: {'width': '20rem', 'max-width': '100%'}), [child]);

Component _column(List<Component> children, {required String gap}) =>
    div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column', 'gap': gap}), children);

Component _multiAnswerCard(Map<String, String> props, String? label) => _sized(
  MultiAnswerCard<String>(
    value: 'exercise',
    selected: previewFlag(props, 'selected'),
    enabled: previewFlag(props, 'enabled', fallback: true),
    onChanged: (_) {},
    child: Text(props['answer'] ?? label ?? multiAnswerPreviewAnswer),
  ),
);

/// 상태 장면 — 네 상태를 실제 카드로 놓는다. hover · 눌림 · 포커스는
/// 브라우저가 포인터나 키보드 없이 켤 수 없어 표의 설명으로 대신한다.
Component _multiAnswerCardStates() => _column(gap: 'var(--coui-space-12)', [
  for (final (name, selected, enabled) in multiAnswerStateRows)
    _column(gap: 'var(--coui-space-4)', [
      span([Text(name).labelSmall.onSurfaceVariant]),
      _sized(
        MultiAnswerCard<String>(
          value: name,
          selected: selected,
          enabled: enabled,
          onChanged: (_) {},
          child: const Text(multiAnswerPreviewAnswer),
        ),
      ),
    ]),
]);
