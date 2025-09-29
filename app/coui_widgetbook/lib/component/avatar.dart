import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'default', type: KBAvatar, path: '[Component]')
/// KBAvatar 유즈케이스
Widget buildKBAvatarDefaultUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    divisions: 52,
    initialValue: 48,
    label: 'size',
    max: 128,
    min: 24,
  );

  return KBAvatar(size: size);
}

@UseCase(name: 'with_image', type: KBAvatar, path: '[Component]')
/// KBAvatar 유즈케이스
Widget buildKBAvatarWithImageUseCase(BuildContext context) {
  final size = context.knobs.double.slider(
    divisions: 52,
    initialValue: 72,
    label: 'size',
    max: 128,
    min: 24,
  );
  final imageUrl = context.knobs.string(
    initialValue: 'https://picsum.photos/seed/coui/256',
    label: 'imageUrl',
  );

  return KBAvatar(imageUrl: imageUrl, size: size);
}
