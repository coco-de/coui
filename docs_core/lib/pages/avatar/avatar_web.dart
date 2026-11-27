/// Avatar 페이지의 미리보기 — Jaspr Web.
///
/// 속성 빌더는 `<Preview props>` · `<Card component>` · 플레이그라운드가, 장면은
/// `<Preview demo="avatar/...">` 가 읽는다. 같은 이름의 Flutter 파일(`avatar_flutter.dart`)과
/// 컴포넌트 · 속성 · 장면 이름이 같아야 한다.
library;

import 'package:coui_web/coui_web.dart';

import '../../shared/preview_props.dart';
import '../../previews/props/web_prop_previews.dart';
import 'avatar_page.dart'
    show
        avatarA11yName,
        avatarCommentBody,
        avatarCommentName,
        avatarGroupMembers,
        avatarPreviewShowsIcon,
        avatarSampleInitials;

/// 속성 → Component.
WebPropPreviewBuilder? get propPreview => _avatar;

/// 장면 이름(`avatar/<장면>`) → 장면.
final Map<String, Component Function()> demos = {
  // 구조 — 링 없이 그린다. 링을 켜면 바깥에 래퍼가 하나 더 생겨, 가장 바깥
  // 요소가 아바타 면이 아니게 된다.
  'avatar/anatomy': () => Avatar(initials: 'JD', size: CoreComponentSize.xl2, badge: _onlineDot()),
  'avatar/content': () => _spacedRow([
    _captioned('initials', Avatar(initials: 'JD', size: CoreComponentSize.lg)),
    _captioned('child', Avatar(size: CoreComponentSize.lg, child: Icon(LucideIcons.house))),
    _captioned('내용 없음', Avatar(size: CoreComponentSize.lg)),
  ]),
  'avatar/sizes': () => _spacedRow([
    for (final size in CoreAvatarStyle.defaultsBySize.keys)
      _captioned(size.name, Avatar(initials: 'JD', size: size, badge: _onlineDot())),
  ]),
  'avatar/diameter': () => _spacedRow([
    _captioned(
      '44',
      Avatar(
        initials: 'A',
        size: CoreComponentSize.lg,
        avatarStyle: const CoreAvatarStyle(diameter: CoreSize.size44),
      ),
    ),
    _captioned(
      '56',
      Avatar(
        initials: 'B',
        size: CoreComponentSize.lg,
        avatarStyle: const CoreAvatarStyle(diameter: CoreSize.size56),
      ),
    ),
  ]),
  'avatar/ring': () => _spacedRow([
    _captioned('ring: false', Avatar(initials: 'JD', size: CoreComponentSize.lg)),
    _captioned('ring: true', Avatar(initials: 'JD', size: CoreComponentSize.lg, ring: true)),
    _captioned(
      'rounded',
      Avatar(initials: 'CO', size: CoreComponentSize.lg, shape: CoreAvatarShape.rounded, ring: true),
    ),
    _captioned(
      'ringColor',
      Avatar(
        initials: 'JD',
        size: CoreComponentSize.lg,
        ring: true,
        avatarStyle: const CoreAvatarStyle(
          ringColor: CoreColor.token(CoreColors.success),
          ringWidth: CoreStrokeWidth.stroke3,
        ),
      ),
    ),
  ]),
  'avatar/badge-placement': () => _spacedRow([
    _captioned('circle', Avatar(initials: 'JD', size: CoreComponentSize.xl, badge: _onlineDot())),
    _captioned(
      'rounded',
      Avatar(initials: 'CO', size: CoreComponentSize.xl, shape: CoreAvatarShape.rounded, badge: _onlineDot()),
    ),
    _captioned(
      'bottomEnd',
      Avatar(
        initials: 'JD',
        size: CoreComponentSize.xl,
        avatarStyle: const CoreAvatarStyle(badgeAlignment: CoreAlignment.bottomEnd),
        badge: _onlineDot(),
      ),
    ),
  ]),
  'avatar/group': () => AvatarGroup(
    max: 3,
    children: [for (final (initials, style) in avatarGroupMembers) Avatar(initials: initials, avatarStyle: style)],
  ),
  'avatar/do-initials': () => Avatar(initials: 'JD', size: CoreComponentSize.lg),
  'avatar/dont-empty': () => Avatar(size: CoreComponentSize.lg),
  'avatar/do-role-text': () => _personRow(
    Avatar(initials: 'JD', size: CoreComponentSize.md, classes: 'shrink-0'),
    'JD',
    '관리자',
  ),
  'avatar/dont-role-dot': () => _personRow(
    Avatar(
      initials: 'JD',
      size: CoreComponentSize.md,
      classes: 'shrink-0',
      badge: AvatarBadge(
        avatarBadgeStyle: const CoreAvatarBadgeStyle(backgroundColor: CoreColor.token(CoreColors.tertiary)),
      ),
    ),
    'JD',
    null,
  ),
  'avatar/do-row-size': () => _personRow(
    Avatar(initials: 'JD', size: CoreComponentSize.sm, classes: 'shrink-0'),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/dont-row-size': () => _personRow(
    Avatar(initials: 'JD', size: CoreComponentSize.xl, classes: 'shrink-0'),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/placement-comment': () => _personRow(
    Avatar(initials: Avatar.getInitials(avatarCommentName), classes: 'shrink-0', badge: _onlineDot()),
    avatarCommentName,
    avatarCommentBody,
  ),
  'avatar/background': () => _spacedRow([
    Avatar(initials: 'A', size: CoreComponentSize.lg),
    Avatar(
      initials: 'B',
      size: CoreComponentSize.lg,
      avatarStyle: const CoreAvatarStyle(
        backgroundColor: CoreColor.token(CoreColors.secondaryContainer),
        fallbackTextStyle: CoreTextStyle(color: CoreColor.token(CoreColors.onSecondaryContainer)),
      ),
    ),
  ]),
  'avatar/a11y-name': () => div(classes: 'docs-demo-caption', [
    Avatar(
      initials: 'JD',
      size: CoreComponentSize.lg,
      badge: _onlineDot(),
      attributes: const {'aria-label': avatarA11yName},
    ),
    div([
      code([Component.text('aria-label="$avatarA11yName"')]),
      const Text('상태 점에는 이름이 없습니다. 상태를 아바타의 이름에 함께 적습니다.').bodySmall.onSurfaceVariant,
    ]),
  ]),
  'avatar/related-badge': () => Badge(tone: CoreBadgeTone.success, showDot: true, child: const Text('온라인')),
  'avatar/related-icon': () => Icon(LucideIcons.house),
  'avatar/related-hover-card': () => HoverCard(
    trigger: Avatar(initials: 'JD'),
    content: const Text('프로필 미리보기'),
  ),
};

Component _avatar(Map<String, String> props, String? label) {
  final showsIcon = avatarPreviewShowsIcon(props);
  return Avatar(
    initials: showsIcon ? null : avatarSampleInitials(label),
    size: previewEnum(CoreComponentSize.values, props['size'], CoreAvatarContract.defaultSize),
    shape: previewEnum(CoreAvatarShape.values, props['shape'], CoreAvatarShape.defaultShape),
    ring: previewFlag(props, 'ring'),
    badge: previewFlag(props, 'badge') ? _onlineDot() : null,
    child: showsIcon ? Icon(LucideIcons.house) : null,
  );
}

/// 온라인 상태 점.
Component _onlineDot() => AvatarBadge(
  avatarBadgeStyle: const CoreAvatarBadgeStyle(backgroundColor: CoreColor.token(CoreColors.success)),
);

/// 링이 이웃에 닿지 않도록 간격을 넓힌 한 줄 — `docsWebDemoRow` 보다 넓다.
Component _spacedRow(List<Component> children) => div(
  styles: Styles(
    raw: {
      'display': 'flex',
      'flex-wrap': 'wrap',
      'align-items': 'flex-end',
      'justify-content': 'center',
      'gap': 'var(--coui-space-24)',
    },
  ),
  children,
);

/// 아바타 아래에 그 아바타를 가르는 이름을 붙인다.
Component _captioned(String caption, Component avatar) => div(
  styles: Styles(
    raw: {'display': 'flex', 'flex-direction': 'column', 'align-items': 'center', 'gap': 'var(--coui-space-12)'},
  ),
  [
    avatar,
    code([Component.text(caption)]),
  ],
);

/// 아바타 옆에 이름과 보조 글을 놓은 한 줄.
Component _personRow(Component avatar, String name, String? detail) => div(
  styles: Styles(raw: {'display': 'flex', 'align-items': 'flex-start', 'gap': 'var(--coui-space-12)'}),
  [
    avatar,
    div(styles: Styles(raw: {'display': 'flex', 'flex-direction': 'column'}), [
      Text(name).bodyMedium.semiBold,
      if (detail != null) Text(detail).bodySmall.onSurfaceVariant,
    ]),
  ],
);
