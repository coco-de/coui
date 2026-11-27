/// Avatar 페이지 — 플레이그라운드와 장면이 함께 읽는 값. 순수 Dart.
///
/// 사이트(Jaspr)와 네이티브 문서 앱(Flutter)이 함께 읽는다. 미리보기는 같은
/// 폴더의 `avatar_web.dart` · `avatar_flutter.dart` 가 그린다. 이 폴더는
/// `tool/gen_page_registry.dart` 가 찾아 레지스트리에 싣는다.
///
/// 속성 `content` 는 위젯 파라미터가 아니라 아바타에 무엇을 담을지 고르는
/// 문서 속성이다 — `initials`(기본)는 이니셜을, `icon` 은 `child` 에 넣은
/// 아이콘을 담는다. `badge` 는 켜면 `badge` 슬롯에 상태 점을 넣는다.
library;

import 'package:coui_core/coui_core.dart';

import '../../shared/playground_spec.dart';
import '../../shared/preview_props.dart';
import '../../shared/size_spec.dart';

/// 문서 슬러그 — `docs_core/content/components/avatar.md`.
const String slug = 'avatar';

/// 플레이그라운드. 없는 컴포넌트는 `null`.
DocsPlaygroundSpec? get playground => _playground;

/// 크기 표. Avatar 는 크기를 장면(`avatar/sizes`)과 본문의 표로 보인다.
DocsSizeSpec Function()? get sizeSpec => null;

/// 미리보기에 라벨을 주지 않았을 때의 이니셜. 두 플랫폼의 속성 빌더와
/// 플레이그라운드 코드가 같은 글자를 쓰도록 한 곳에 둔다.
String avatarSampleInitials(String? label) => label ?? 'JD';

/// 이 속성이 이니셜 대신 `child` 아이콘을 담는가.
bool avatarPreviewShowsIcon(Map<String, String> props) => props['content'] == 'icon';

/// 접근성 장면의 아바타 이름 — 이름과 상태를 함께 적는다.
const String avatarA11yName = 'JD, 온라인';

/// 그룹 장면의 구성원 — 이니셜과 아바타마다의 스타일. 겹친 아바타가 서로
/// 갈라져 보이도록 면과 글자색을 짝으로 바꾼다.
const List<(String, CoreAvatarStyle)> avatarGroupMembers = [
  ('AB', CoreAvatarStyle()),
  (
    'CD',
    CoreAvatarStyle(
      backgroundColor: CoreColor.token(CoreColors.successContainer),
      fallbackTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSuccessContainer)),
    ),
  ),
  (
    'EF',
    CoreAvatarStyle(
      backgroundColor: CoreColor.token(CoreColors.warningContainer),
      fallbackTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onWarningContainer)),
    ),
  ),
  ('GH', CoreAvatarStyle()),
  ('IJ', CoreAvatarStyle()),
];

/// 댓글 줄 장면의 이름과 본문.
const String avatarCommentName = 'Jane Doe';

/// 댓글 줄 장면의 본문.
const String avatarCommentBody = '확인했습니다.';

// 선택지는 enum 과 크기 행에서 읽는다 — 모양이나 크기 행이 늘면
// 플레이그라운드도 따라온다.
final DocsPlaygroundSpec _playground = DocsPlaygroundSpec(
  initial: {
    'shape': CoreAvatarShape.defaultShape.name,
    'size': CoreComponentSize.xl.name,
    'content': 'initials',
    'badge': 'true',
  },
  controls: [
    DocsPlaygroundChoice(
      label: 'shape',
      prop: 'shape',
      options: [for (final shape in CoreAvatarShape.values) shape.name],
      segmented: true,
    ),
    DocsPlaygroundChoice(
      label: 'size',
      prop: 'size',
      options: [for (final size in CoreAvatarStyle.defaultsBySize.keys) size.name],
      segmented: true,
    ),
    const DocsPlaygroundChoice(label: '내용', prop: 'content', options: ['initials', 'icon'], segmented: true),
    const DocsPlaygroundFlag(label: '링', on: {'ring': 'true'}),
    const DocsPlaygroundFlag(label: '상태 점', on: {'badge': 'true'}),
  ],
  code: _avatarCode,
);

/// 속성 → 코드. 기본값과 같은 축은 적지 않는다. 두 플랫폼의 코드가 같다.
String _avatarCode(Map<String, String> props, String? label) {
  final size = previewEnum(CoreComponentSize.values, props['size'], CoreAvatarContract.defaultSize);
  final shape = previewEnum(CoreAvatarShape.values, props['shape'], CoreAvatarShape.defaultShape);
  final showsIcon = avatarPreviewShowsIcon(props);
  final lines = [
    if (!showsIcon) "initials: '${avatarSampleInitials(label)}',",
    if (size != CoreAvatarContract.defaultSize) 'size: CoreComponentSize.${size.name},',
    if (shape != CoreAvatarShape.defaultShape) 'shape: CoreAvatarShape.${shape.name},',
    if (previewFlag(props, 'ring')) 'ring: true,',
    if (previewFlag(props, 'badge')) ...[
      'badge: AvatarBadge(',
      '  avatarBadgeStyle: CoreAvatarBadgeStyle(',
      '    backgroundColor: CoreColor.token(CoreColors.success),',
      '  ),',
      '),',
    ],
    if (showsIcon) 'child: Icon(LucideIcons.house),',
  ];
  return 'Avatar(\n${lines.map((l) => '  $l').join('\n')}\n)';
}
