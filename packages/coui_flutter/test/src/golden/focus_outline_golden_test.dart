import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('FocusOutline Golden', () {
    goldenTest(
      'all variants',
      fileName: 'focus_outline_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'unfocused',
            child: buildGoldenTestApp(
              FocusOutline(
                child: Container(
                  width: 120,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'focused rectangle',
            child: buildGoldenTestApp(
              FocusOutline(
                focused: true,
                child: Container(
                  width: 120,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'focused circle',
            child: buildGoldenTestApp(
              FocusOutline(
                focused: true,
                shape: CoreFocusOutlineShape.circle,
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'focused custom radius',
            child: buildGoldenTestApp(
              FocusOutline(
                focused: true,
                child: Container(
                  width: 120,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
              ).radius16,
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
