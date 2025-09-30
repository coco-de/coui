import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A text loading skeleton use case.
@UseCase(
  name: 'text loading',
  type: Text,
)
Widget buildSkeletonTextLoadingUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(initialValue: true, label: 'enabled');

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Title Text').asSkeleton(enabled: enabled),
      const SizedBox(height: 8),
      const Text('This is a longer text that simulates content loading')
          .asSkeleton(enabled: enabled),
      const SizedBox(height: 8),
      const Text('Short text').asSkeleton(enabled: enabled),
    ],
  );
}

/// A card loading skeleton use case.
@UseCase(
  name: 'card loading',
  type: coui.Card,
)
Widget buildSkeletonCardLoadingUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(initialValue: true, label: 'enabled');

  return coui.Card(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const coui.Avatar(initials: 'AB', size: 48)
                .asSkeleton(enabled: enabled),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('John Doe').asSkeleton(enabled: enabled),
                  const SizedBox(height: 4),
                  const Text('john@example.com')
                      .asSkeleton(enabled: enabled),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          'This is a description text that shows how skeleton loading works with longer content.',
        ).asSkeleton(enabled: enabled),
      ],
    ),
  );
}

/// A list loading skeleton use case.
@UseCase(
  name: 'list loading',
  type: ListView,
)
Widget buildSkeletonListLoadingUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(initialValue: true, label: 'enabled');
  final itemCount = context.knobs.int.slider(
    initialValue: 3,
    label: 'item count',
    max: 10,
    min: 1,
  );

  return ListView.builder(
    shrinkWrap: true,
    itemCount: itemCount,
    itemBuilder: (context, index) {
      return ListTile(
        leading: const coui.Avatar(initials: 'AB'),
        title: Text('Item ${index + 1}'),
        subtitle: const Text('Description text'),
      ).asSkeleton(enabled: enabled);
    },
  );
}
