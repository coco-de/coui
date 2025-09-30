import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Breadcrumb] use case with arrow separator.
@UseCase(
  name: 'arrow separator',
  type: coui.Breadcrumb,
)
Widget buildBreadcrumbArrowUseCase(BuildContext context) {
  return coui.Breadcrumb(
    separator: coui.Breadcrumb.arrowSeparator,
    children: [
      GestureDetector(
        onTap: () {},
        child: const Text('Home'),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Products'),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Electronics'),
      ),
      const Text('Laptops'),
    ],
  );
}

/// A [coui.Breadcrumb] use case with slash separator.
@UseCase(
  name: 'slash separator',
  type: coui.Breadcrumb,
)
Widget buildBreadcrumbSlashUseCase(BuildContext context) {
  return coui.Breadcrumb(
    separator: coui.Breadcrumb.slashSeparator,
    children: [
      GestureDetector(
        onTap: () {},
        child: const Text('Dashboard'),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Settings'),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Profile'),
      ),
      const Text('Edit'),
    ],
  );
}

/// A [coui.Breadcrumb] use case with custom separator.
@UseCase(
  name: 'custom separator',
  type: coui.Breadcrumb,
)
Widget buildBreadcrumbCustomUseCase(BuildContext context) {
  return coui.Breadcrumb(
    separator: const Icon(Icons.keyboard_arrow_right, size: 16),
    children: [
      GestureDetector(
        onTap: () {},
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.home, size: 16),
            SizedBox(width: 4),
            Text('Home'),
          ],
        ),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Documents'),
      ),
      GestureDetector(
        onTap: () {},
        child: const Text('Projects'),
      ),
      const Text('My Project'),
    ],
  );
}