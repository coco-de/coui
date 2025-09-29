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
    backgroundColor: context.knobs.colorOrNull(label: 'backgroundColor'),
    borderRadius: context.knobs.double.slider(
      initialValue: 24,
      label: 'borderRadius',
      max: 64,
      min: 0,
    ),
    initials: context.knobs.string(initialValue: 'JD', label: 'initials'),
    size: context.knobs.double.slider(
      initialValue: 48,
      label: 'size',
      max: 128,
      min: 24,
    ),
  );
}

@UseCase(
  name: 'with image',
  type: coui.Avatar,
)
Widget buildAvatarWithImageUseCase(BuildContext context) {
  return coui.Avatar.network(
    initials: context.knobs.string(initialValue: 'JD', label: 'initials'),
    photoUrl: context.knobs.string(
      initialValue: 'https://i.pravatar.cc/150?u=a042581f4e29026704d',
      label: 'photoUrl',
    ),
    size: context.knobs.double.slider(
      initialValue: 72,
      label: 'size',
      max: 128,
      min: 24,
    ),
  );
}

@UseCase(
  name: 'with badge',
  type: coui.Avatar,
)
Widget buildAvatarWithBadgeUseCase(BuildContext context) {
  return coui.Avatar(
    badge: coui.AvatarBadge(
      color: context.knobs.color(
        initialValue: Colors.green,
        label: 'badgeColor',
      ),
      size: context.knobs.double.slider(
        initialValue: 16,
        label: 'badgeSize',
        max: 32,
        min: 8,
      ),
      child:
          context.knobs.boolean(initialValue: false, label: 'badge has child')
          ? const Icon(Icons.check, color: Colors.white, size: 10)
          : null,
    ),
    initials: 'AB',
    size: 72,
  );
}

@UseCase(
  name: 'group',
  type: coui.AvatarGroup,
)
Widget buildAvatarGroupUseCase(BuildContext context) {
  return coui.AvatarGroup.toRight(
    gap: context.knobs.double.slider(
      initialValue: 8,
      label: 'gap',
      max: 20,
      min: 0,
    ),
    offset: context.knobs.double.slider(
      initialValue: 0.7,
      label: 'offset',
      max: 1,
      min: 0,
    ),
    children: const [
      coui.Avatar(initials: 'AB'),
      coui.Avatar(initials: 'CD'),
      coui.Avatar(initials: 'EF'),
      coui.Avatar(initials: 'GH'),
    ],
  );
}
