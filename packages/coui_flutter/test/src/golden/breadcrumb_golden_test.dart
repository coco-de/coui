import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Breadcrumb Golden', () {
    goldenTest(
      'all variants',
      fileName: 'breadcrumb_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 550),
        children: [
          GoldenTestScenario(
            name: 'single item',
            child: buildGoldenTestApp(
              const Breadcrumb(
                items: [CoreBreadcrumbItem(label: 'Home')],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'two items, non-interactive',
            child: buildGoldenTestApp(
              const Breadcrumb(
                items: [
                  CoreBreadcrumbItem(label: 'Home'),
                  CoreBreadcrumbItem(label: 'Components'),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'three items, interactive',
            child: buildGoldenTestApp(
              Breadcrumb(
                items: const [
                  CoreBreadcrumbItem(label: 'Home'),
                  CoreBreadcrumbItem(label: 'Products'),
                  CoreBreadcrumbItem(label: 'Details'),
                ],
                onItemTap: (_) {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'many items',
            child: buildGoldenTestApp(
              Breadcrumb(
                items: const [
                  CoreBreadcrumbItem(label: 'Home'),
                  CoreBreadcrumbItem(label: 'Category'),
                  CoreBreadcrumbItem(label: 'Subcategory'),
                  CoreBreadcrumbItem(label: 'Product'),
                  CoreBreadcrumbItem(label: 'Reviews'),
                ],
                onItemTap: (_) {},
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
