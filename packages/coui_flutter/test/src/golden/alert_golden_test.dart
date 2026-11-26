import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Alert Golden', () {
    goldenTest(
      'all variants',
      fileName: 'alert_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'default with title',
            child: buildGoldenTestApp(
              const Alert(
                description: 'This is an informational alert.',
                title: 'Information',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'default title only',
            child: buildGoldenTestApp(
              // Genuinely title-only. It said "title only" while passing a
              // description too — added during the migration that made
              // `title` required, which left all four scenarios identical
              // in shape and this case uncovered. It is the one that
              // matters most: a single line is what the height floor
              // exists to hold up, so a golden of it is the only place a
              // collapsed one-line alert would be visible.
              const Alert(title: 'Heads up!'),
            ),
          ),
          GoldenTestScenario(
            name: 'destructive with title',
            child: buildGoldenTestApp(
              const Alert.destructive(
                description: 'Something went wrong.',
                title: 'Error',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'destructive title only',
            child: buildGoldenTestApp(
              const Alert.destructive(title: 'Destructive action'),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
