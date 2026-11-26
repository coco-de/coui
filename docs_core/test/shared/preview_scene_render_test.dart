import 'package:coui_flutter/coui_flutter.dart';
import 'package:docs_core/internal/preview/flutter_scene.dart';
import 'package:docs_core/internal/preview/scene_file.dart';
import 'package:docs_core/internal/preview/scenes.dart';
import 'package:docs_core/previews/props/flutter_doc_demos.dart';
import 'package:docs_core/previews/flutter_registry.dart';
import 'package:docs_core/shared/playground_spec.dart';
import 'package:docs_core/shared/size_spec.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Every page the registry knows — a page cannot leave these checks by
  // being added after the two reference pages were.
  final pages = kDocsPlaygrounds.keys.toList()..sort();

  test('the canonical registry returns each declared scene owner without a nested-component fallback', () {
    expect(pages, containsAll(['button', 'text-field']));
    for (final component in pages) {
      for (final scene in readDocsScenes(component)) {
        final widget = kFlutterPreviewRegistry[component]!(scene.reference);
        expect(widget.runtimeType.toString(), scene.flutterOwnerType, reason: scene.origins.join(', '));
      }
    }
    expect(() => kFlutterPreviewRegistry['button']!('docs-v2-not-declared'), throwsStateError);
  });

  for (final dark in [false, true]) {
    Future<void> mount(WidgetTester tester, Widget child) => tester.pumpWidget(
      CoUIApp(
        theme: ThemeData.fromCore(dark ? CoreThemePresets.dark : CoreThemePresets.light),
        themeMode: dark ? CoreThemeMode.dark : CoreThemeMode.light,
        darkTheme: ThemeData.fromCore(CoreThemePresets.dark),
        home: child,
      ),
    );

    DocsScene scene(String component, bool Function(DocsScene) predicate) =>
        readDocsScenes(component).firstWhere(predicate);

    // Each page's own scenes render where a reader sees them, in both modes,
    // without throwing — a scene that only fails on one platform or one mode
    // is otherwise found by opening the native app on that page.
    for (final component in pages) {
      testWidgets('$component — every declared scene renders, dark=$dark', (tester) async {
        tester.view.physicalSize = const Size(1200, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        for (final input in readDocsScenes(component)) {
          // A fresh element per scene — each is its own place on the page.
          await mount(
            tester,
            SingleChildScrollView(key: ValueKey(input.reference), child: renderFlutterScene(input)),
          );
          expect(tester.takeException(), isNull, reason: input.origins.join(', '));
          if (input.tag == 'SizeSpec') {
            for (final row in docsSizeSpecFor(component)!.rows) {
              expect(find.text(row.size.name), findsWidgets, reason: '${input.origins.first} ${row.size.name}');
            }
          }
        }
      });
    }

    testWidgets('cold playground keeps the current spec input, dark=$dark', (tester) async {
      final input = scene('button', (scene) => scene.tag == 'Playground');
      final spec = kDocsPlaygrounds['button']!;
      await mount(tester, renderFlutterScene(input));
      final button = tester.widget<Button>(find.byType(Button));
      expect(button.size.name, spec.initial['size']);
      expect(button.variant.name, spec.initial['variant']);
      expect(button.leading, isNotNull);
      expect(find.text(spec.label!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SizeSpec renders every Core row rather than one default, dark=$dark', (tester) async {
      final input = scene('button', (scene) => scene.tag == 'SizeSpec');
      await mount(tester, SingleChildScrollView(child: renderFlutterScene(input)));
      expect(
        tester.widgetList<Button>(find.byType(Button)).map((button) => button.size),
        docsSizeSpecFor('button')!.rows.map((row) => row.size),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('error scene reaches the actual editor and existing error message, dark=$dark', (tester) async {
      final input = scene('text-field', (scene) => scene.attributes['demo'] == 'text-field/do-helpful-error');
      await mount(tester, renderFlutterScene(input));
      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.errorText, '8자 이상 입력해 주세요.');
      expect(field.obscureText, isTrue);
      expect(find.text(field.errorText!), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a composite keeps the original Native scene instead of a nested fallback, dark=$dark', (tester) async {
      final input = scene('button', (scene) => scene.attributes['demo'] == 'button/states');
      await mount(tester, kFlutterDocDemos['button/states']!());
      final direct = tester
          .widgetList<Button>(find.byType(Button))
          .map((button) => (button.variant, button.enabled))
          .toList();
      await mount(tester, renderFlutterScene(input));
      expect(tester.widgetList<Button>(find.byType(Button)).map((button) => (button.variant, button.enabled)), direct);
      expect(direct.length, greaterThan(1));
      expect(tester.takeException(), isNull);
    });
  }
}
