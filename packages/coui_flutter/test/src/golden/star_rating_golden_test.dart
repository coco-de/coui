import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('StarRating Golden', () {
    goldenTest(
      'all variants',
      fileName: 'star_rating_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'empty',
            child: buildGoldenTestApp(const StarRating(value: 0)),
          ),
          GoldenTestScenario(
            name: 'partial fill',
            child: buildGoldenTestApp(const StarRating(value: 2.5)),
          ),
          GoldenTestScenario(
            name: 'full',
            child: buildGoldenTestApp(const StarRating(value: 5)),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: buildGoldenTestApp(
              const StarRating(value: 3, enabled: false),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
