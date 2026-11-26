import 'dart:convert';

import 'package:coui_flutter/coui_flutter.dart' as co;
import 'package:coui_widgetbook/add_on/surface_material_addon.dart';
import 'package:coui_widgetbook/components.g.dart';
import 'package:coui_widgetbook/widgetbook_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart' as wb;

import '../../../packages/coui_flutter/test/parity/parity_network_image_stub.dart';

void main() {
  late Uint8List imageBytes;
  setUpAll(() async {
    await _loadCatalogFonts();
    imageBytes = await renderParityStubImageBytes();
  });

  test('catalog routes are unique and nonempty', () {
    expect(components, isNotEmpty);
    final paths = <String>{};
    for (final component in components) {
      expect(paths.add(component.fullPath), isTrue, reason: component.fullPath);
      expect(component.stories, isNotEmpty, reason: component.fullPath);
      final storyPaths = <String>{};
      for (final story in component.stories) {
        expect(storyPaths.add(story.path), isTrue, reason: story.path);
      }
    }
  });

  for (final profile in [
    (
      name: 'workbench',
      size: const Size(1000, 800),
      dark: false,
      material: co.CoreSurfaceStyleId.defaultStyle,
    ),
    (
      name: 'docs-dark',
      size: const Size(600, 500),
      dark: true,
      material: co.CoreSurfaceStyleId.defaultStyle,
    ),
    (
      name: 'glass',
      size: const Size(1000, 800),
      dark: false,
      material: co.CoreSurfaceStyleId.liquidGlass,
    ),
    (
      name: 'glass-docs-dark',
      size: const Size(600, 500),
      dark: true,
      material: co.CoreSurfaceStyleId.liquidGlass,
    ),
  ]) {
    for (final component in components) {
      for (final story in component.stories) {
        testWidgets('${profile.name}: ${story.path}', (tester) async {
          await tester.binding.setSurfaceSize(profile.size);
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final config = createWidgetbookConfig();
          final materialIndex = config.addons!.indexWhere(
            (addon) => addon is SurfaceMaterialAddon,
          );
          config.addons![materialIndex] = SurfaceMaterialAddon(
            initialValue: profile.material,
          );
          final themeAddon = config.addons!
              .whereType<wb.ThemeAddon<co.ThemeData>>()
              .single;
          await _expectNoErrors(tester, imageBytes, () async {
            await tester.pumpWidget(
              MaterialApp(
                home: Builder(
                  builder: (context) => story.buildWithConfig(
                    context,
                    config,
                    modes: profile.dark
                        ? [
                            wb.ThemeMode<co.ThemeData>(
                              'Dark',
                              themeAddon.themes['Dark']!,
                              themeAddon.builder,
                            ),
                          ]
                        : null,
                  ),
                ),
              ),
            );
          });
        });
      }
    }
  }

  // Keep the real app mounted while visiting Docs pages. Repeated runApp calls
  // schedule warm-up frames and reset the clock under still-repeating tickers.
  testWidgets('every catalog Docs page mounts all of its stories', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1440, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _expectNoErrors(tester, imageBytes, () async {
      wb.runWidgetbook(
        createWidgetbookConfig(
          initialRoute: Uri(
            path: '/',
            queryParameters: {'path': components.first.docsPath},
          ).toString(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final state = wb.WidgetbookState.of(
        tester.element(find.byType(wb.StoryDocBlock).first),
      );
      for (final component in components) {
        state.goToDocs(component);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));
        expect(
          find.byType(wb.StoryDocBlock),
          findsNWidgets(component.stories.length),
          reason: component.docsPath,
        );
      }
    });
  });
}

Future<void> _expectNoErrors(
  WidgetTester tester,
  Uint8List imageBytes,
  Future<void> Function() mount,
) async {
  final errors = <FlutterErrorDetails>[];
  final previousHandler = FlutterError.onError;
  var errorWidgetCount = 0;
  FlutterError.onError = errors.add;
  try {
    await runParityEntryWithStubbedNetwork(imageBytes, () async {
      await mount();
      // Some stories animate forever, so pumpAndSettle is not a smoke gate.
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));
      errorWidgetCount = find.byType(ErrorWidget).evaluate().length;
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    });
  } finally {
    FlutterError.onError = previousHandler;
  }
  expect(
    errors
        .map(
          (error) => error.exceptionAsString().split('\n').take(6).join('\n'),
        )
        .toList(),
    isEmpty,
    reason: errors.firstOrNull?.stack.toString(),
  );
  expect(errorWidgetCount, 0);
}

Future<void> _loadCatalogFonts() async {
  // Use the shipped font manifest, not Ahem's square glyphs: otherwise a
  // healthy Korean label can appear to overflow only in this test process.
  final manifest =
      jsonDecode(await rootBundle.loadString('FontManifest.json'))
          as List<dynamic>;
  for (final entry in manifest.cast<Map<String, dynamic>>()) {
    final family = (entry['family'] as String).replaceFirst(
      'packages/widgetbook/',
      '',
    );
    final loader = FontLoader(family);
    for (final font
        in (entry['fonts'] as List<dynamic>).cast<Map<String, dynamic>>()) {
      final asset = font['asset'] as String;
      expect(
        asset.split('/'),
        isNot(contains('..')),
        reason: 'Font escapes the deployed asset root: $asset',
      );
      loader.addFont(rootBundle.load(asset));
    }
    await loader.load();
  }
}
