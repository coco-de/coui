import 'package:core/core.dart' hide UseCase;
import 'package:flutter/material.dart';
import 'package:coui_widgetbook/foundation/group.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'KBBadge', type: KBBadge, path: '[Component]')
/// KBBadge 유즈케이스
Widget buildWidgetbookKBBadgeUseCase(BuildContext context) {
  final text = context.knobs.string(
    initialValue: getIt<Faker>().lorem.word(length: 6),
    label: 'Text',
  );
  final styleKey = context.knobs.object.dropdown<String>(
    initialOption: 'info',
    label: 'Style',
    labelBuilder: (v) => v,
    options: <String>[
      'positive',
      'negative',
      'inactive',
      'info',
      'expired',
      'active',
    ],
  );
  final withIcon = context.knobs.boolean(initialValue: true, label: 'Icon');

  BadgeStyle resolveStyle() {
    switch (styleKey) {
      case 'positive':
        return BadgeStyle.positive(context);
      case 'negative':
        return BadgeStyle.negative(context);
      case 'inactive':
        return BadgeStyle.inactive(context);
      case 'info':
        return BadgeStyle.info(context);
      case 'expired':
        return BadgeStyle.expired(context);
      case 'active':
        return BadgeStyle.active(context);
      default:
        return BadgeStyle.info(context);
    }
  }

  return WidgetbookGroup(
    label: 'Badge',
    children: [
      Padding(
        padding: const EdgeInsets.all(Insets.xxSmall),
        child: KBBadge(
          icon: withIcon ? const Icon(Icons.verified) : null,
          style: resolveStyle(),
          text: text,
        ),
      ),
    ],
  );
}

@UseCase(name: 'BadgeRole', type: BadgeRole, path: '[Component]')
/// BadgeRole 유즈케이스
Widget buildWidgetbookBadgeRoleUseCase(BuildContext context) {
  final type = context.knobs.object.dropdown<BadgeRoleType>(
    initialOption: BadgeRoleType.globalAdmin,
    label: 'Type',
    labelBuilder: BadgeRoleType.name,
    options: <BadgeRoleType>[
      BadgeRoleType.globalAdmin,
      BadgeRoleType.superAdmin,
      BadgeRoleType.featureAdmin,
      BadgeRoleType.readonly,
      BadgeRoleType.permissionDenied,
      BadgeRoleType.permissionBook,
      BadgeRoleType.permissionUser,
      BadgeRoleType.permissionAd,
      BadgeRoleType.permissionCoupon,
      BadgeRoleType.permissionClassChat,
      BadgeRoleType.permissionAiLog,
    ],
  );

  return WidgetbookGroup(
    label: 'BadgeRole',
    children: [
      Padding(
        padding: const EdgeInsets.all(Insets.xxSmall),
        child: BadgeRole(type: type),
      ),
    ],
  );
}
