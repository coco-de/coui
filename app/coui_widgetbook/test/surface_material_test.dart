import 'package:coui_flutter/coui_flutter.dart' as co;
import 'package:coui_widgetbook/add_on/surface_material_addon.dart';
import 'package:coui_widgetbook/widgetbook_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:widgetbook/widgetbook.dart' as wb;

void main() {
  test('the material control exposes and serializes every surface preset', () {
    final addon = SurfaceMaterialAddon();
    expect(addon.initialValue, co.CoreSurfaceStyleId.defaultStyle);
    expect(
      (addon.field as wb.ObjectDropdownField<co.CoreSurfaceStyleId>).values,
      co.CoreSurfaceStyleId.values,
    );
    for (final material in co.CoreSurfaceStyleId.values) {
      expect(
        addon.valueFromQueryGroup(addon.valueToQueryGroup(material)),
        material,
      );
    }
  });

  testWidgets('ordinary stories switch every material independently of theme', (
    tester,
  ) async {
    final state = await _mount(tester, 'navigation/AppBar/Default');
    final addon = state.config.addons!.whereType<SurfaceMaterialAddon>().single;
    final themeAddon = state.config.addons!
        .whereType<wb.ThemeAddon<co.ThemeData>>()
        .single;
    for (final theme in themeAddon.themes.entries) {
      state.updateQueryGroup(
        themeAddon.groupName,
        themeAddon.valueToQueryGroup(theme.value),
      );
      for (final sample in [
        (path: 'navigation/AppBar/Default', type: co.AppBar),
        (path: 'navigation/NavigationBar/Default', type: co.NavigationBar),
        (path: 'layout/Card/Default', type: co.Card),
      ]) {
        state.updatePath(sample.path);
        for (final material in [
          ...co.CoreSurfaceStyleId.values,
          co.CoreSurfaceStyleId.defaultStyle,
        ]) {
          state.updateQueryGroup(
            addon.groupName,
            addon.valueToQueryGroup(material),
          );
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));
          expect(
            find.byType(sample.type),
            findsWidgets,
            reason: '${sample.path} ${theme.key} $material at ${state.path}',
          );
          final context = tester.element(find.byType(sample.type).first);
          final actual = co.Theme.of(context);
          final expected = co.applySurfaceStyle(
            theme.value,
            surfaceStyle: material,
            highContrast: false,
          );
          expect(co.SurfaceStyleScope.of(context), material);
          expect(actual.brightness, expected.brightness);
          expect(actual.surfaceBlur, expected.surfaceBlur);
          expect(actual.surfaceOpacity, expected.surfaceOpacity);
          expect(actual.surfaceRefraction, expected.surfaceRefraction);
          expect(actual.geometry, expected.geometry);
          expect(tester.takeException(), isNull);
        }
      }
    }
  });

  testWidgets('changing material preserves navigation selection', (
    tester,
  ) async {
    final state = await _mount(tester, 'navigation/NavigationBar/Default');
    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<co.NavigationBar>(find.byType(co.NavigationBar))
          .selectedIndex,
      3,
      reason: 'the selection must change before the material changes',
    );
    final addon = state.config.addons!.whereType<SurfaceMaterialAddon>().single;
    for (final material in [
      co.CoreSurfaceStyleId.liquidGlass,
      co.CoreSurfaceStyleId.defaultStyle,
    ]) {
      state.updateQueryGroup(
        addon.groupName,
        addon.valueToQueryGroup(material),
      );
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<co.NavigationBar>(find.byType(co.NavigationBar))
            .selectedIndex,
        3,
      );
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('AppBar toolbar menu inherits the selected material', (
    tester,
  ) async {
    final state = await _mount(tester, 'navigation/AppBar/Menus and Toolbars');
    final addon = state.config.addons!.whereType<SurfaceMaterialAddon>().single;
    state.updateQueryGroup(
      addon.groupName,
      addon.valueToQueryGroup(co.CoreSurfaceStyleId.liquidGlass),
    );
    await tester.pumpAndSettle();
    // The clear bar must not put another material around its two groups.
    expect(
      find.byType(co.SurfaceBlur),
      findsNWidgets(3),
      reason: 'one leading capsule and two explicit trailing groups',
    );
    await tester.tap(find.byType(co.DropdownMenu));
    await tester.pumpAndSettle();
    final context = tester.element(find.text('Save collection'));
    expect(co.Theme.of(context).surfaceRefraction, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

Future<wb.WidgetbookState> _mount(WidgetTester tester, String path) async {
  await tester.binding.setSurfaceSize(const Size(1440, 1000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  wb.runWidgetbook(
    createWidgetbookConfig(
      initialRoute: Uri(path: '/', queryParameters: {'path': path}).toString(),
    ),
  );
  await tester.pumpAndSettle();
  expect(tester.takeException(), isNull);
  return wb.WidgetbookState.of(
    tester.element(find.byKey(const ValueKey('widgetbook-preview-surface'))),
  );
}
