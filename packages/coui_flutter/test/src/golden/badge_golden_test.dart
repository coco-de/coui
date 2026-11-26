import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Badge Golden', () {
    goldenTest(
      'all variants',
      fileName: 'badge_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'default (neutral tonal label)',
            child: buildGoldenTestApp(const Badge(child: Text('Tag'))),
          ),
          for (final tone in CoreBadgeTone.values)
            GoldenTestScenario(
              name: '${tone.name} tonal · filled · outlined',
              child: buildGoldenTestApp(
                Row(
                  mainAxisSize: .min,
                  spacing: CoreSpace.space8,
                  children: [
                    for (final variant in CoreBadgeVariant.values)
                      Badge(
                        tone: tone,
                        variant: variant,
                        child: Text(variant.name),
                      ),
                  ],
                ),
              ),
            ),
          GoldenTestScenario(
            name: 'status label with dot',
            child: buildGoldenTestApp(
              const Badge(tone: .success, showDot: true, child: Text('Done')),
            ),
          ),
          GoldenTestScenario(
            name: 'count · dot',
            child: buildGoldenTestApp(
              const Row(
                mainAxisSize: .min,
                spacing: CoreSpace.space8,
                children: [
                  Badge(
                    tone: .info,
                    variant: .filled,
                    form: .count,
                    size: .xs,
                    child: Text('3'),
                  ),
                  Badge(
                    tone: .destructive,
                    variant: .filled,
                    form: .count,
                    child: Text('128'),
                  ),
                  Badge(tone: .warning, form: .dot),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with leading icon',
            child: buildGoldenTestApp(
              const Badge(
                tone: .primary,
                leading: Icon(LucideIcons.check),
                child: Text('Verified'),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
