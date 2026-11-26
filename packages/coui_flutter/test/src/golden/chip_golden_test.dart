import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Chip Golden', () {
    goldenTest(
      'all variants',
      fileName: 'chip_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'neutral',
            child: buildGoldenTestApp(const Chip(label: 'Flutter')),
          ),
          GoldenTestScenario(
            name: 'primary',
            child: buildGoldenTestApp(
              const Chip(label: 'Primary', chipColor: CoreChipColor.primary),
            ),
          ),
          // A resting chip states no colour, so this draws the same picture as
          // `neutral` above — the scenario pins that, and 'primary selected'
          // below is where the colour shows.
          GoldenTestScenario(
            name: 'primary selected',
            child: buildGoldenTestApp(
              const Chip(
                label: 'Primary Selected',
                chipColor: CoreChipColor.primary,
                selected: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'selected',
            child: buildGoldenTestApp(
              const Chip(label: 'Selected', selected: true),
            ),
          ),
          // The grey-filled resting chip, and the same variant selected —
          // `variant` never touches a selected chip, so the second must
          // match 'selected' above.
          GoldenTestScenario(
            name: 'filled',
            child: buildGoldenTestApp(
              const Chip(label: 'Filled', variant: CoreChipVariant.filled),
            ),
          ),
          GoldenTestScenario(
            name: 'filled selected',
            child: buildGoldenTestApp(
              const Chip(
                label: 'Filled Selected',
                variant: CoreChipVariant.filled,
                selected: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: buildGoldenTestApp(
              const Chip(label: 'Disabled', enabled: false),
            ),
          ),
          // Selected + disabled together — the combination the invisible
          // border regression lived in (border == fill colour, only
          // visible as a stroke node, not a pixel difference). This
          // scenario is the net that would have caught it.
          GoldenTestScenario(
            name: 'disabled selected',
            child: buildGoldenTestApp(
              const Chip(
                label: 'Disabled Selected',
                enabled: false,
                selected: true,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'with remove button',
            child: buildGoldenTestApp(
              Chip(label: 'Removable', onRemove: () {}),
            ),
          ),
        ],
      ),
    ).ignore();

    // `shape: pill` on every size — the full corner, clamped by the painter
    // to half of each height, so both ends are half circles at 28, 32 and
    // 40. Kept out of 'all variants' above so that picture stays the
    // default (`rounded`) render it has always been.
    goldenTest(
      'pill shape',
      fileName: 'chip_shape_pill',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          for (final size in CoreChipSize.values)
            GoldenTestScenario(
              name: 'pill ${size.name}',
              child: buildGoldenTestApp(
                Chip(label: 'Pill', size: size, shape: CoreChipShape.pill),
              ),
            ),
          GoldenTestScenario(
            name: 'pill md selected',
            child: buildGoldenTestApp(
              const Chip(
                label: 'Selected',
                selected: true,
                shape: CoreChipShape.pill,
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'pill md filled',
            child: buildGoldenTestApp(
              const Chip(
                label: 'Filled',
                variant: CoreChipVariant.filled,
                shape: CoreChipShape.pill,
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
