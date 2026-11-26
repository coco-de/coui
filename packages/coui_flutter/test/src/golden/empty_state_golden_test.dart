import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('EmptyState Golden', () {
    goldenTest(
      'all variants',
      fileName: 'empty_state_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 400),
        children: [
          GoldenTestScenario(
            name: 'default',
            child: buildGoldenTestApp(
              const EmptyState(
                title: Text('No results found'),
                description: Text('Try adjusting your search criteria.'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with icon and action',
            child: buildGoldenTestApp(
              EmptyState(
                icon: const Icon(LucideIcons.inbox),
                title: const Text('No results found'),
                description: const Text(
                  'Try adjusting your search criteria.',
                ),
                action: Button(
                  variant: CoreButtonVariant.primary,
                  onPressed: () {},
                  child: const Text('Clear Filters'),
                ),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'compact',
            child: buildGoldenTestApp(
              const EmptyState.compact(title: Text('Nothing here')),
            ),
          ),
          GoldenTestScenario(
            name: 'failure tone',
            child: buildGoldenTestApp(
              const EmptyState(
                tone: CoreEmptyStateTone.failure,
                title: Text('Could not load orders'),
                description: Text('Check your connection and try again.'),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
