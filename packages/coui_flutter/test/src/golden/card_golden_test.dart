import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Card Golden', () {
    goldenTest(
      'all variants',
      fileName: 'card_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'outlined',
            child: buildGoldenTestApp(
              const Card(
                header: Text('Card Title'),
                body: Text('This is the outlined card body text.'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'filled',
            child: buildGoldenTestApp(
              const Card(
                variant: CoreCardVariant.filled,
                header: Text('Filled Card'),
                body: Text('This is the filled card body text.'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with footer',
            child: buildGoldenTestApp(
              Card(
                header: const Text('Order #1234'),
                body: const Text('Shipped yesterday.'),
                footer: Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () {},
                  child: const Text('View Details'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'interactive',
            child: buildGoldenTestApp(
              Card(
                onTap: () {},
                header: const Text('Clickable Card'),
                body: const Text('Tap anywhere on this card.'),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
