/// EmptyState 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="empty-state/...">` 와 카드가 읽는다. 같은 이름의 Flutter
/// 파일(`empty_state_flutter.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import '../page_kit_web.dart';
import 'empty_state_page.dart' show emptyStateDemoStyle, emptyStatePreviewSample, emptyStateToneTitles;

/// 속성 → Component.
///
/// `icon` · `description` · `action` 은 켜고 끄는 값이고, 아이콘과 글은 톤에
/// 맞는 예시를 쓴다. 태그의 `label` 을 주면 제목이 된다.
WebPropPreviewBuilder? get propPreview => _emptyState;

/// 장면 이름(`empty-state/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 무대는 flex 행이라 빈 상태가 내용 폭이 된다. 번호를 놓을 자리를 두려고
  // 루트의 폭을 정한다 — 감싸는 상자를 두면 구조 번호가 그 상자를 루트로 본다.
  // 설명은 선택자로 짚을 표지를 단다.
  // 좁은 화면에서도 왼쪽에 번호 자리가 남도록 화면 폭에서 여백을 뺀 값이 상한이다.
  'empty-state/anatomy': () => EmptyState(
    css: Styles(raw: {'width': 'min(24rem, calc(100vw - 8rem))', 'max-width': '100%'}),
    icon: Icon(LucideIcons.inbox),
    title: const Text('받은 메시지가 없어요'),
    description: span(
      attributes: const {'data-docs-part': 'description'},
      [const Text('새 메시지가 오면 여기에 보여요.')],
    ),
    action: _action('새 메시지 쓰기'),
  ),
  'empty-state/tones': () => docsWebDemoRow([
    for (final tone in CoreEmptyStateTone.values)
      div(styles: Styles(raw: {'width': '12rem'}), [
        EmptyState.compact(
          tone: tone,
          icon: Icon(LucideIcons.inbox),
          title: Text(emptyStateToneTitles[tone]!),
          description: Text(tone.name),
        ),
      ]),
  ]),
  'empty-state/do-specific': () => EmptyState.compact(
    icon: Icon(LucideIcons.search),
    title: const Text("'가을 코트' 검색 결과가 없어요"),
    description: const Text('철자를 확인하거나 필터를 줄여 보세요.'),
    action: _action('필터 초기화'),
  ),
  'empty-state/dont-vague': () => EmptyState.compact(title: const Text('데이터 없음')),
  'empty-state/do-failure-tone': () => EmptyState.compact(
    tone: CoreEmptyStateTone.failure,
    icon: Icon(LucideIcons.circleAlert),
    title: const Text('주문을 불러오지 못했어요'),
    description: const Text('연결을 확인한 뒤 다시 시도해 주세요.'),
    action: _action('다시 시도'),
  ),
  'empty-state/dont-failure-as-empty': () => EmptyState.compact(
    icon: Icon(LucideIcons.inbox),
    title: const Text('주문이 없어요'),
  ),
  'empty-state/in-panel': () => _frame([
    div(styles: Styles(raw: {'padding': 'var(--coui-space-16) var(--coui-space-16) 0'}), [
      const Text('최근 알림').titleSmall,
    ]),
    EmptyState.compact(
      icon: Icon(LucideIcons.inbox),
      title: const Text('새 알림이 없어요'),
      description: const Text('알림이 오면 여기에 쌓여요.'),
    ),
  ]),
  'empty-state/fill-area': () => _frame(
    height: '20rem',
    [
      EmptyState(
        classes: 'h-full',
        icon: Icon(LucideIcons.search),
        title: const Text('검색 결과가 없어요'),
        description: const Text('필터를 바꿔 보세요.'),
      ),
    ],
  ),
  'empty-state/custom-style': () => EmptyState(
    icon: Icon(LucideIcons.folderOpen),
    title: const Text('저장한 필터가 없어요'),
    description: const Text('자주 쓰는 조건을 저장해 보세요.'),
    emptyStateStyle: emptyStateDemoStyle,
  ),
  'empty-state/related-alert': () => const Alert.destructive(
    title: '주문을 저장하지 못했어요',
    description: '잠시 뒤 다시 시도해 주세요.',
  ),
  // 카드 무대는 flex 라 글 모양 스켈레톤은 폭을 정한 상자에 넣는다.
  'empty-state/related-skeleton': () => div(styles: Styles(raw: {'width': '12rem'}), [Skeleton.text()]),
  'empty-state/related-loading': () => const Loading(),
  'empty-state/related-banner': () => const Banner.info(message: Text('점검이 예정되어 있어요')),
};

Component _emptyState(Map<String, String> props, String? label) {
  final tone = previewEnum(CoreEmptyStateTone.values, props['tone'], CoreEmptyStateTone.defaultTone);
  final sample = emptyStatePreviewSample(tone);
  return EmptyState(
    variant: previewEnum(CoreEmptyStateVariant.values, props['variant'], CoreEmptyStateVariant.defaultVariant),
    tone: tone,
    icon: previewFlag(props, 'icon') ? Icon(sample.icon) : null,
    title: Text(label ?? sample.title),
    description: previewFlag(props, 'description') ? Text(sample.description) : null,
    action: previewFlag(props, 'action') ? _action(sample.action) : null,
  );
}

/// 빈 상태 아래에 놓는 행동 — 플레이그라운드 코드(`empty_state_page.dart`)와 같은
/// 모양.
Component _action(String label) => Button(
  variant: CoreButtonVariant.outline,
  onPressed: () {},
  child: Text(label),
);

/// 자리를 보이는 선 상자 — EmptyState 는 자기 상자를 그리지 않아, 선이 있어야
/// 어디까지가 자리인지 보인다.
Component _frame(List<Component> children, {String? height}) => div(
  styles: Styles(
    raw: {
      'width': '20rem',
      'max-width': '100%',
      'height': ?height,
      'border': 'var(--coui-stroke-width-1) solid ${const CoreColor.token(CoreColors.outlineVariant).toValue()}',
      'border-radius': 'var(--coui-radius-12)',
    },
  ),
  children,
);
