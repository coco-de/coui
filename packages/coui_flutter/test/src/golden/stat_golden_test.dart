import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Stat Golden', () {
    goldenTest(
      'all variants',
      fileName: 'stat_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'basic',
            child: buildGoldenTestApp(
              const Stat(label: 'Total Revenue', value: r'$45,231'),
            ),
          ),
          GoldenTestScenario(
            name: 'positive change',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Total Revenue',
                value: r'$45,231',
                change: '+20.1%',
                changeType: CoreStatChangeType.positive,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'negative change',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Active Users',
                value: '1,205',
                change: '-4.3%',
                changeType: CoreStatChangeType.negative,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'outlined',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Total Revenue',
                value: r'$45,231',
                variant: CoreStatVariant.outlined,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'unit and description',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Subscribers',
                value: '12,480',
                unit: '명',
                change: '+5.2%',
                changeType: CoreStatChangeType.positive,
                description: 'Last 30 days',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'empty value',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Pending',
                unit: '명',
                description: 'Not counted yet',
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'neutral change with icon',
            child: buildGoldenTestApp(
              const Stat(
                label: 'Sessions',
                value: '8,492',
                change: '0.0%',
                changeType: CoreStatChangeType.neutral,
                icon: Icon(LucideIcons.user),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
