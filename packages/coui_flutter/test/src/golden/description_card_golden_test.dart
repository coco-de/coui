import 'package:alchemist/alchemist.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/golden_test_app.dart';

void main() {
  group('DescriptionCard Golden', () {
    goldenTest(
      'all variants',
      fileName: 'description_card_variants',
      builder: () => GoldenTestGroup(
        scenarioConstraints: const BoxConstraints(maxWidth: 550),
        children: [
          GoldenTestScenario(
            name: 'outlined horizontal',
            child: buildGoldenTestApp(
              const DescriptionCard(
                title: '주문 상세',
                rows: [
                  DescriptionRow(label: '주문번호', value: 'ORD-2025-00391'),
                  DescriptionRow(
                    label: '결제금액',
                    value: '₩369,000',
                    isEmphasized: true,
                  ),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'filled',
            child: buildGoldenTestApp(
              const DescriptionCard(
                variant: CoreDescriptionCardVariant.filled,
                title: 'Shipping',
                rows: [
                  DescriptionRow(label: 'Carrier', value: 'DHL'),
                  DescriptionRow(
                    label: 'Tracking',
                    value: '1Z999AA10123456784',
                  ),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'vertical layout',
            child: buildGoldenTestApp(
              const DescriptionCard(
                layout: CoreDescriptionCardLayout.vertical,
                title: 'Customer',
                rows: [
                  DescriptionRow(label: 'Name', value: 'Jane Doe'),
                  DescriptionRow(label: 'Email', value: 'jane@example.com'),
                ],
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'ghost, no title',
            child: buildGoldenTestApp(
              const DescriptionCard(
                variant: CoreDescriptionCardVariant.ghost,
                rows: [DescriptionRow(label: 'Status', value: 'Active')],
              ),
            ),
          ),
        ],
      ),
    ).ignore();
  });
}
