import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Seeded on the unchanged parent commit, then compared on the extension.
/// These fixtures use only the public API available before the extension.
void main() {
  for (final dark in [false, true]) {
    for (final virtual in [false, true]) {
      testWidgets(
        'existing Tree output remains exact ($dark, $virtual)',
        (
          tester,
        ) async {
          tester.view.physicalSize = const Size(400, 300);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final core = CoreThemeData(
            designSystem: DesignSystem.coui,
            colorScheme: dark
                ? CouiSemanticMapping.dark(CouiColorPresets.palette)
                : CouiSemanticMapping.light(CouiColorPresets.palette),
            brightness: dark ? CoreBrightness.dark : CoreBrightness.light,
          );
          const boundary = ValueKey('tree.compatibility');
          await tester.pumpWidget(
            CoUIApp(
              theme: ThemeData.fromCore(core),
              home: Builder(
                builder: (context) => RepaintBoundary(
                  key: boundary,
                  child: ColoredBox(
                    color: context.theme.colorScheme.surface.toValue(),
                    child: Tree(
                      nodes: const [
                        CoreTreeNode(
                          id: 'root',
                          label: 'Workspace',
                          expanded: true,
                          children: [
                            CoreTreeNode(
                              id: 'main',
                              label: 'main.dart',
                              selected: true,
                            ),
                            CoreTreeNode(
                              id: 'lib',
                              label: 'lib',
                              expanded: true,
                              children: [
                                CoreTreeNode(
                                  id: 'nested',
                                  label: 'nested.dart',
                                ),
                              ],
                            ),
                          ],
                        ),
                        CoreTreeNode(id: 'readme', label: 'README.md'),
                      ],
                      virtualRowHeight: virtual ? 28 : null,
                      virtualViewportHeight: virtual ? 300 : null,
                      onNodeSelect: (_) {},
                      onNodeDrop: (_, _) {},
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await expectLater(
            find.byKey(boundary),
            matchesGoldenFile('goldens/tree-compatibility-$dark-$virtual.png'),
          );
        },
        skip: !const bool.fromEnvironment('COUI_TREE_COMPATIBILITY'),
        variant: TargetPlatformVariant.only(TargetPlatform.macOS),
      );
    }
  }
}
