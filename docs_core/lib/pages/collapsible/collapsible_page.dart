/// Collapsible 페이지 — 플레이그라운드. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `collapsible_web.dart` · `collapsible_flutter.dart` 가 그린다.
///
/// `expanded` 를 바꾼 효과가 처음 화면에서부터 보이도록, 두 플랫폼 빌더는
/// 속성이 바뀌면 [collapsiblePreviewKey] 로 미리보기를 새로 만든다.
library;

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/collapsible.md`.
const String slug = 'collapsible';

/// 미리보기의 머리 글자.
const String collapsibleDemoTrigger = '고급 설정';

/// 미리보기의 본문 글자.
const String collapsibleDemoContent = '알림 주기와 언어를 바꿀 수 있어요.';

/// 미리보기의 폭(logical px). 두 플랫폼이 같은 폭에 그린다.
const double collapsibleDemoWidth = 320;

/// 플레이그라운드.
DocsPlaygroundSpec? get playground => const DocsPlaygroundSpec(
  initial: {'expanded': 'true'},
  controls: [
    DocsPlaygroundFlag(label: '처음부터 펼침 (expanded)', on: {'expanded': 'true'}),
    DocsPlaygroundFlag(label: '머리 줄에 아이콘 (trigger)', on: {'icon': 'true'}),
  ],
  code: _collapsibleCode,
  webCode: _collapsibleWebCode,
);

/// 크기 표. Collapsible 에는 크기 축이 없다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기를 새로 만들어야 하는 속성 묶음의 이름.
String collapsiblePreviewKey(Map<String, String> props) =>
    'collapsible-${previewFlag(props, 'expanded')}-${previewFlag(props, 'icon')}';

String _collapsibleCode(Map<String, String> props, String? label) => _code(
  props,
  previewFlag(props, 'icon')
      ? const [
          '  trigger: Row(',
          '    children: [',
          '      Icon(LucideIcons.settings),',
          '      const Gap.space8(),',
          "      Text('$collapsibleDemoTrigger'),",
          '    ],',
          '  ),',
        ]
      : const ["  trigger: Text('$collapsibleDemoTrigger'),"],
);

String _collapsibleWebCode(Map<String, String> props, String? label) => _code(
  props,
  previewFlag(props, 'icon')
      ? const [
          '  trigger: div(',
          '    [',
          '      Icon(LucideIcons.settings),',
          '      const Gap.space8(),',
          "      Text('$collapsibleDemoTrigger'),",
          '    ],',
          "    classes: 'flex items-center',",
          '  ),',
        ]
      : const ["  trigger: Text('$collapsibleDemoTrigger'),"],
  // Web 의 루트는 내용만큼만 차지한다 — 미리보기처럼 폭을 채운다.
  extra: const ["  classes: 'w-full',"],
);

String _code(Map<String, String> props, List<String> trigger, {List<String> extra = const []}) => [
  'Collapsible(',
  ...trigger,
  "  content: Text('$collapsibleDemoContent'),",
  if (previewFlag(props, 'expanded')) '  expanded: true,',
  ...extra,
  ')',
].join('\n');
