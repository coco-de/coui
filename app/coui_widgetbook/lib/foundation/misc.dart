import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// Builds the BorderRadius use case for Widgetbook.
@UseCase(name: 'radius', type: BorderRadius)
Widget buildRadiusUseCase(BuildContext context) {
  final theme = coui.Theme.of(context);
  final radii = {
    'lg': theme.borderRadiusLg,
    'md': theme.borderRadiusMd,
    'sm': theme.borderRadiusSm,
    'xl': theme.borderRadiusXl,
    'xs': theme.borderRadiusXs,
    'xxl': theme.borderRadiusXxl,
  };

  return ListView.builder(
    itemBuilder: (context, index) {
      final name = radii.keys.elementAtOrNull(index) ?? '';
      final radius = radii.values.elementAtOrNull(index) ?? BorderRadius.zero;

      return ListTile(
        leading: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: radius,
          ),
          width: 48,
          height: 48,
        ),
        title: Text(name),
        subtitle: Text(radius.toString()),
      );
    },
    itemCount: radii.length,
  );
}

/// Builds the icon sizes use case for Widgetbook.
@UseCase(name: 'icon sizes', type: IconThemeData)
Widget buildIconSizesUseCase(BuildContext context) {
  final iconTheme = coui.Theme.of(context).iconTheme;
  final sizes = {
    'large': iconTheme.large.size,
    'medium': iconTheme.medium.size,
    'small': iconTheme.small.size,
    'x2Large': iconTheme.x2Large.size,
    'x2Small': iconTheme.x2Small.size,
    'x3Large': iconTheme.x3Large.size,
    'x3Small': iconTheme.x3Small.size,
    'x4Large': iconTheme.x4Large.size,
    'x4Small': iconTheme.x4Small.size,
    'xLarge': iconTheme.xLarge.size,
    'xSmall': iconTheme.xSmall.size,
  };

  return ListView.builder(
    itemBuilder: (context, index) {
      final name = sizes.keys.elementAtOrNull(index) ?? '';
      final size = sizes.values.elementAtOrNull(index);

      return ListTile(
        leading: Icon(Icons.star, size: size),
        title: Text(name),
        subtitle: Text('${size ?? 0}px'),
      );
    },
    itemCount: sizes.length,
  );
}
