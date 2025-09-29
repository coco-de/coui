import 'package:flutter/material.dart';
import 'package:ui_kit/ui_kit.dart';

/// MyLibraryPage 유즈케이스
Widget buildWidgetbookMyLibraryUseCase(BuildContext context) {
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
                'My Library Page',
                style: context.textTheme.headlineSmall,
              ),
              const SizedBox(height: Insets.large),
              Text(
                'This is a placeholder '
                'for the My Library feature in the widgetbook.',
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
