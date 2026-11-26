import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('OutlinedContainer Golden', () {
    goldenTest(
      'all variants',
      fileName: 'outlined_container_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'solid border',
            child: buildGoldenTestApp(
              const OutlinedContainer(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Solid border'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'dashed border',
            child: buildGoldenTestApp(
              const OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  borderStyle: CoreOutlinedContainerBorderStyle.dashed,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Dashed border'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'dotted border',
            child: buildGoldenTestApp(
              const OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  borderStyle: CoreOutlinedContainerBorderStyle.dotted,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Dotted border'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'elevated',
            child: buildGoldenTestApp(
              const OutlinedContainer(
                containerStyle: CoreOutlinedContainerStyle(
                  elevation: CoreOutlinedContainerElevation.strong,
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Elevated surface'),
                ),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
