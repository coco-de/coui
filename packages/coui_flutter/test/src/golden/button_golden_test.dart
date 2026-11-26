import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('Button Golden', () {
    goldenTest(
      'all variants',
      fileName: 'button_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 300),
        children: [
          GoldenTestScenario(
            name: 'primary',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.primary,
                onPressed: () {},
                child: const Text('Primary'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'secondary',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.secondary,
                onPressed: () {},
                child: const Text('Secondary'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'tonal',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.tonal,
                onPressed: () {},
                child: const Text('Tonal'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'outline',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.outline,
                onPressed: () {},
                child: const Text('Outline'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'ghost',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.ghost,
                onPressed: () {},
                child: const Text('Ghost'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'destructive',
            child: buildGoldenTestApp(
              Button(
                variant: CoreButtonVariant.destructive,
                onPressed: () {},
                child: const Text('Destructive'),
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: buildGoldenTestApp(
              const Button(
                variant: CoreButtonVariant.primary,
                child: material.Text('Disabled'),
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
