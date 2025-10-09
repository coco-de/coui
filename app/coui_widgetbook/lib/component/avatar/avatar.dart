import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the default Avatar use case for Widgetbook.
@UseCase(name: 'Default', type: Avatar)
material.Widget buildAvatarUseCase(material.BuildContext context) {
  return const Avatar(initials: 'AB');
}
