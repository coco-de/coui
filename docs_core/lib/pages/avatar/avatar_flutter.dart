/// Avatar 페이지의 미리보기 — Flutter.
///
/// 속성 빌더는 `<Preview props>` · `<Card component>` · 플레이그라운드가, 장면은
/// `<Preview demo="avatar/...">` 가 읽는다. 같은 이름의 Web 파일(`avatar_web.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_flutter/coui_flutter.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/flutter_prop_previews.dart';
import 'avatar_page.dart'
    show
        avatarA11yName,
        avatarCommentBody,
        avatarCommentName,
        avatarGroupMembers,
        avatarPreviewShowsIcon,
        avatarSampleInitials;

/// 속성 → Widget.
FlutterPropPreviewBuilder? get propPreview => _avatar;

/// 장면 이름(`avatar/<장면>`) → 장면.
final Map<String, Widget Function()> demos = {
  'avatar/anatomy': () => const Avatar(initials: 'JD', size: CoreComponentSize.xl2, badge: _onlineDot),
  'avatar/content': () => _spacedRow([
    _captioned('initials', const Avatar(initials: 'JD', size: CoreComponentSize.lg)),
    _captioned('child', const Avatar(size: CoreComponentSize.lg, child: Icon(LucideIcons.house))),
    _captioned('내용 없음', const Avatar(size: CoreComponentSize.lg)),
  ]),
  'avatar/sizes': () => _spacedRow([
    for (final size in CoreAvatarStyle.defaultsBySize.keys)
      _captioned(size.name, Avatar(initials: 'JD', size: size, badge: _onlineDot)),
  ]),
  'avatar/diameter': () => _spacedRow([
    _captioned(
      '44',
      const Avatar(
        initials: 'A',
        size: CoreComponentSize.lg,
        avatarStyle: CoreAvatarStyle(diameter: CoreSize.size44),
      ),
    ),
    _captioned(
      '56',
      const Avatar(
        initials: 'B',
        size: CoreComponentSize.lg,
        avatarStyle: CoreAvatarStyle(diameter: CoreSize.size56),
      ),
    ),
  ]),
  'avatar/ring': () => _spacedRow([
    _captioned('ring: false', const Avatar(initials: 'JD', size: CoreComponentSize.lg)),
    _captioned('ring: true', const Avatar(initials: 'JD', size: CoreComponentSize.lg, ring: true)),
    _captioned(
      'rounded',
      const Avatar(initials: 'CO', size: CoreComponentSize.lg, shape: CoreAvatarShape.rounded, ring: true),
    ),
    _captioned(
      'ringColor',
      const Avatar(
        initials: 'JD',
        size: CoreComponentSize.lg,
        ring: true,
        avatarStyle: CoreAvatarStyle(
          ringColor: CoreColor.token(CoreColors.success),
          ringWidth: CoreStrokeWidth.stroke3,
        ),
      ),
    ),
  ]),
  'avatar/badge-placement': () => _spacedRow([
    _captioned('circle', const Avatar(initials: 'JD', size: CoreComponentSize.xl, badge: _onlineDot)),
    _captioned(
      'rounded',
      const Avatar(initials: 'CO', size: CoreComponentSize.xl, shape: CoreAvatarShape.rounded, badge: _onlineDot),
    ),
    _captioned(
      'bottomEnd',
      const Avatar(
        initials: 'JD',
        size: CoreComponentSize.xl,
        avatarStyle: CoreAvatarStyle(badgeAlignment: CoreAlignment.bottomEnd),
        badge: _onlineDot,
      ),
    ),
  ]),
  'avatar/group': () => AvatarGroup(
    max: 3,
    children: [for (final (initials, style) in avatarGroupMembers) Avatar(initials: initials, avatarStyle: style)],
  ),
  'avatar/do-initials': () => const Avatar(initials: 'JD', size: CoreComponentSize.lg),
  'avatar/dont-empty': () => const Avatar(size: CoreComponentSize.lg),
  'avatar/do-role-text': () => _personRow(const Avatar(initials: 'JD', size: CoreComponentSize.md), 'JD', '관리자'),
  'avatar/dont-role-dot': () => _personRow(
    const Avatar(
      initials: 'JD',
      size: CoreComponentSize.md,
      badge: AvatarBadge(
        avatarBadgeStyle: CoreAvatarBadgeStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
      ),
    ),
    'JD',
    null,
  ),
  'avatar/do-row-size': () => _personRow(
    const Avatar(initials: 'JD', size: CoreComponentSize.sm),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/dont-row-size': () => _personRow(
    const Avatar(initials: 'JD', size: CoreComponentSize.xl),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/placement-comment': () => _personRow(
    Avatar(initials: Avatar.getInitials(avatarCommentName), badge: _onlineDot),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/background': () => _spacedRow(const [
    Avatar(initials: 'A', size: CoreComponentSize.lg),
    Avatar(
      initials: 'B',
      size: CoreComponentSize.lg,
      avatarStyle: CoreAvatarStyle(
        backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
        fallbackTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSecondaryContainer)),
      ),
    ),
  ]),
  'avatar/a11y-name': () => Semantics(
    label: avatarA11yName,
    image: true,
    excludeSemantics: true,
    child: const Avatar(initials: 'JD', size: CoreComponentSize.lg, badge: _onlineDot),
  ),
  'avatar/related-badge': () => const Badge(tone: CoreBadgeTone.success, showDot: true, child: Text('온라인')),
  'avatar/related-icon': () => const Icon(LucideIcons.house),
  'avatar/related-hover-card': () => const HoverCard(
    trigger: Avatar(initials: 'JD'),
    content: Text('프로필 미리보기'),
  ),
};

Widget _avatar(Map<String, String> props, String? label) {
  final showsIcon = avatarPreviewShowsIcon(props);
  return Avatar(
    initials: showsIcon ? null : avatarSampleInitials(label),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreAvatarContract.defaultSize),
    shape: previewEnum(CoreAvatarShape.values, props['shape'], CoreAvatarShape.defaultShape),
    ring: previewFlag(props, 'ring'),
    badge: previewFlag(props, 'badge') ? _onlineDot : null,
    child: showsIcon ? const Icon(LucideIcons.house) : null,
  );
}

/// 온라인 상태 점.
const Widget _onlineDot = AvatarBadge(
  avatarBadgeStyle: CoreAvatarBadgeStyle(backgroundColor: CoreColor.token(CoreColors.success)),
);

/// 링이 이웃에 닿지 않도록 간격을 넓힌 한 줄 — `docsFlutterDemoRow` 보다 넓다.
Widget _spacedRow(List<Widget> children) => Wrap(
  spacing: CoreSpace.space24,
  runSpacing: CoreSpace.space24,
  crossAxisAlignment: WrapCrossAlignment.end,
  children: children,
);

/// 아바타 아래에 그 아바타를 가르는 이름을 붙인다.
Widget _captioned(String caption, Widget avatar) => Column(
  mainAxisSize: MainAxisSize.min,
  spacing: CoreSpace.space12,
  children: [avatar, Text(caption).codeSm.onSurfaceVariant],
);

/// 아바타 옆에 이름과 보조 글을 놓은 한 줄.
Widget _personRow(Widget avatar, String name, String? detail) => ConstrainedBox(
  constraints: const BoxConstraints(maxWidth: 320),
  child: Row(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CoreSpace.space12,
    children: [
      avatar,
      Flexible(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(name).bodyMedium.semiBold,
            if (detail != null) Text(detail).bodySmall.onSurfaceVariant,
          ],
        ),
      ),
    ],
  ),
);
