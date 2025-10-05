import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

@UseCase(name: 'Default', type: Avatar)
material.Widget buildAvatarUseCase(material.BuildContext context) {
  return const Avatar(initials: 'AB');
}
