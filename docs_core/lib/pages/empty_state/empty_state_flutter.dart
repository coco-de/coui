/// EmptyState 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · 플레이그라운드가, 장면은
/// `<Preview demo="empty-state/...">` 와 카드가 읽는다. 같은 이름의 Web
/// 파일(`empty_state_web.dart`)과 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import '../page_kit_flutter.dart';
import 'empty_state_page.dart' show emptyStateDemoStyle, emptyStatePreviewSample, emptyStateToneTitles;

/// 속성 → Widget.
///
/// `icon` · `description` · `action` 은 켜고 끄는 값이고, 아이콘과 글은 톤에
/// 맞는 예시를 쓴다. 태그의 `label` 을 주면 제목이 된다.
FlutterPropPreviewBuilder? get propPreview => _emptyState;

/// 장면 이름(`empty-state/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'empty-state/anatomy': () => EmptyState(
    icon: const Icon(LucideIcons.inbox),
    title: const Text('받은 메시지가 없어요'),
    description: const Text('새 메시지가 오면 여기에 보여요.'),
    action: _action('새 메시지 쓰기'),
  ),
  'empty-state/tones': () => docsFlutterDemoRow([
    for (final tone in CoreEmptyStateTone.values)
      SizedBox(
        width: CoreSpace.space200,
        child: EmptyState.compact(
          tone: tone,
          icon: const Icon(LucideIcons.inbox),
          title: Text(emptyStateToneTitles[tone]!),
          description: Text(tone.name),
        ),
      ),
  ]),
  'empty-state/do-specific': () => EmptyState.compact(
    icon: const Icon(LucideIcons.search),
    title: const Text("'가을 코트' 검색 결과가 없어요"),
    description: const Text('철자를 확인하거나 필터를 줄여 보세요.'),
    action: _action('필터 초기화'),
  ),
  'empty-state/dont-vague': () => const EmptyState.compact(title: Text('데이터 없음')),
  'empty-state/do-failure-tone': () => EmptyState.compact(
    tone: CoreEmptyStateTone.failure,
    icon: const Icon(LucideIcons.circleAlert),
    title: const Text('주문을 불러오지 못했어요'),
    description: const Text('연결을 확인한 뒤 다시 시도해 주세요.'),
    action: _action('다시 시도'),
  ),
  'empty-state/dont-failure-as-empty': () => const EmptyState.compact(
    icon: Icon(LucideIcons.inbox),
    title: Text('주문이 없어요'),
  ),
  'empty-state/in-panel': () => _frame(
    Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(CoreSpace.space16, CoreSpace.space16, CoreSpace.space16, 0),
          child: const Text('최근 알림').titleSmall,
        ),
        const EmptyState.compact(
          icon: Icon(LucideIcons.inbox),
          title: Text('새 알림이 없어요'),
          description: Text('알림이 오면 여기에 쌓여요.'),
        ),
      ],
    ),
  ),
  'empty-state/fill-area': () => _frame(
    height: CoreLayout.layout320,
    const EmptyState(
      icon: Icon(LucideIcons.search),
      title: Text('검색 결과가 없어요'),
      description: Text('필터를 바꿔 보세요.'),
    ),
  ),
  'empty-state/custom-style': () => const EmptyState(
    icon: Icon(LucideIcons.folderOpen),
    title: Text('저장한 필터가 없어요'),
    description: Text('자주 쓰는 조건을 저장해 보세요.'),
    emptyStateStyle: emptyStateDemoStyle,
  ),
  'empty-state/related-alert': () => const Alert.destructive(
    title: '주문을 저장하지 못했어요',
    description: '잠시 뒤 다시 시도해 주세요.',
  ),
  'empty-state/related-skeleton': () => _still(const SizedBox(width: CoreSpace.space200, child: Skeleton.text())),
  'empty-state/related-loading': () => _still(const Loading()),
  'empty-state/related-banner': () => const Banner.info(message: Text('점검이 예정되어 있어요')),
};

Widget _emptyState(Map<String, String> props, String? label) {
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
Widget _action(String label) => Button(
  variant: CoreButtonVariant.outline,
  onPressed: () {},
  child: Text(label),
);

/// 카드의 스켈레톤 · 스피너를 멈춘 그림. 계속 도는 애니메이션이 있으면 네이티브
/// 앱의 카드 검사(`pumpAndSettle`)가 끝나지 않는다.
Widget _still(Widget child) => TickerMode(enabled: false, child: child);

/// 자리를 보이는 선 상자 — EmptyState 는 자기 상자를 그리지 않아, 선이 있어야
/// 어디까지가 자리인지 보인다.
Widget _frame(Widget child, {double? height}) => Builder(
  builder: (context) => Container(
    width: CoreLayout.layout320,
    height: height,
    decoration: BoxDecoration(
      border: Border.all(
        color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.outlineVariant)).toValue(),
      ),
      borderRadius: const BorderRadius.all(Radius.circular(CoreRadius.radius12)),
    ),
    child: child,
  ),
);
