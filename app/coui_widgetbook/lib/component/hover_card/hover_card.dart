import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.HoverCard] use case.
@UseCase(
  name: 'default',
  type: coui.HoverCard,
)
Widget buildHoverCardDefaultUseCase(BuildContext context) {
  return Center(
    child: coui.HoverCard(
      hoverBuilder: (context) {
        return coui.Card(
          padding: const EdgeInsets.all(12),
          child: const Text('This appears on hover'),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text('Hover over me'),
      ),
    ),
  );
}

/// A [coui.HoverCard] use case with rich content.
@UseCase(
  name: 'rich content',
  type: coui.HoverCard,
)
Widget buildHoverCardRichUseCase(BuildContext context) {
  return Center(
    child: coui.HoverCard(
      wait: const Duration(milliseconds: 300),
      debounce: const Duration(milliseconds: 200),
      hoverBuilder: (context) {
        return coui.Card(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: 250,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    CircleAvatar(
                      radius: 20,
                      child: Icon(Icons.person),
                    ),
                    SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'John Doe',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '@johndoe',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text('Software Developer | Tech Enthusiast'),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.location_on, size: 16),
                    SizedBox(width: 4),
                    Text('San Francisco, CA'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      child: const Text(
        '@johndoe',
        style: TextStyle(
          color: Colors.blue,
          decoration: TextDecoration.underline,
        ),
      ),
    ),
  );
}

/// A [coui.HoverCard] use case with help text.
@UseCase(
  name: 'help text',
  type: coui.HoverCard,
)
Widget buildHoverCardHelpUseCase(BuildContext context) {
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text('Password'),
        const SizedBox(width: 8),
        coui.HoverCard(
          popoverAlignment: Alignment.topCenter,
          anchorAlignment: Alignment.bottomCenter,
          hoverBuilder: (context) {
            return coui.Card(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: 200,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Password Requirements:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• At least 8 characters'),
                    Text('• One uppercase letter'),
                    Text('• One lowercase letter'),
                    Text('• One number'),
                    Text('• One special character'),
                  ],
                ),
              ),
            );
          },
          child: const Icon(
            Icons.help_outline,
            size: 20,
            color: Colors.grey,
          ),
        ),
      ],
    ),
  );
}