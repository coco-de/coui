import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// StorePage 유즈케이스
Widget buildWidgetbookStoreUseCase(BuildContext context) {
  return Center(
    child: Padding(
      padding: const EdgeInsets.all(Insets.large),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(Insets.large),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Store Page',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: Insets.large),
              Text(
                'This is a placeholder '
                'for the Store feature in the widgetbook.',
                style: context.textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
