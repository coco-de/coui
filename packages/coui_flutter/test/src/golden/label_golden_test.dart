import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Label Golden', () {
    goldenTest(
      'all variants',
      fileName: 'label_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'default',
            child: buildGoldenTestApp(const Label(text: 'Email')),
          ),
          GoldenTestScenario(
            name: 'required',
            child: buildGoldenTestApp(
              const Label(text: 'Password', isRequired: true),
            ),
          ),
          GoldenTestScenario(
            name: 'with icon',
            child: buildGoldenTestApp(
              const Label(text: 'Email', icon: Icon(LucideIcons.mail)),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: buildGoldenTestApp(
              const Label(text: 'Disabled Field', disabled: true),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
