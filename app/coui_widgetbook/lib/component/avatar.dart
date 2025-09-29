import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(
  name: 'default',
  type: coui.Avatar,
)
Widget buildAvatarDefaultUseCase(BuildContext context) {
  return coui.Avatar(
    initials: context.knobs.string(label: 'initials', initialValue: 'JD'),
    size: context.knobs.double.slider(
      label: 'size',
      initialValue: 48,
      min: 24,
      max: 128,
    ),
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    borderRadius: context.knobs.double.slider(
      label: 'borderRadius',
      initialValue: 24,
      min: 0,
      max: 64,
    ),
  );
}

@UseCase(
  name: 'with image',
  type: coui.Avatar,
)
Widget buildAvatarWithImageUseCase(BuildContext context) {
  return coui.Avatar.network(
    initials: context.knobs.string(label: 'initials', initialValue: 'JD'),
    photoUrl: context.knobs.string(
      label: 'photoUrl',
      initialValue: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
    ),
    size: context.knobs.double.slider(
      label: 'size',
      initialValue: 72,
      min: 24,
      max: 128,
    ),
  );
}

@UseCase(
  name: 'with badge',
  type: coui.Avatar,
)
Widget buildAvatarWithBadgeUseCase(BuildContext context) {
  return coui.Avatar(
    initials: 'AB',
    size: 72,
    badge: coui.AvatarBadge(
      color: context.knobs.color(label: 'badgeColor', initialValue: Colors.green),
      size: context.knobs.double.slider(
        label: 'badgeSize',
        initialValue: 16,
        min: 8,
        max: 32,
      ),
      child: context.knobs.boolean(label: 'badge has child', initialValue: false)
          ? const Icon(Icons.check, color: Colors.white, size: 10)
          : null,
    ),
  );
}

@UseCase(
  name: 'group',
  type: coui.AvatarGroup,
)
Widget buildAvatarGroupUseCase(BuildContext context) {
  return coui.AvatarGroup.toRight(
    gap: context.knobs.double.slider(label: 'gap', initialValue: 8, min: 0, max: 20),
    offset: context.knobs.double.slider(
      label: 'offset',
      initialValue: 0.7,
      min: 0,
      max: 1,
    ),
    children: const [
      coui.Avatar(initials: 'AB'),
      coui.Avatar(initials: 'CD'),
      coui.Avatar(initials: 'EF'),
      coui.Avatar(initials: 'GH'),
    ],
  );
}