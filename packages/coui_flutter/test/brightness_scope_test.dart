// A subtree in the brightness the app is not in.
//
// `CoUIApp` publishes its theme in both brightnesses, folded the same way the
// active one is, and `BrightnessScope` swaps that brightness's colours and
// shadow strength into the surrounding theme. Read back from the tree: the
// theme inside the scope, the text and icon colours a bare child inherits,
// and what stays the surroundings' own.

import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_app.dart';

final _light = ThemeData.fromCore(CoreThemePresets.light);
final _dark = ThemeData.fromCore(CoreThemePresets.dark);

/// How long an opened panel is given to finish its entrance — a test wait,
/// not a design value.
const Duration _kPanelSettle = Duration(milliseconds: 500);

/// What a probe saw: the theme, the text colour and the icon colour.
typedef _Seen = ({ThemeData theme, Color? text, Color? icon});

Widget _probe(void Function(_Seen seen) onSeen) => Builder(
  builder: (context) {
    onSeen((
      theme: Theme.of(context),
      text: DefaultTextStyle.of(context).style.color,
      icon: IconTheme.of(context).color,
    ));

    return const SizedBox.shrink();
  },
);

void main() {
  group('inside CoUIApp', () {
    late _Seen outside;
    late _Seen inside;

    Future<void> pump(
      WidgetTester tester, {
      required CoreThemeMode mode,
      required CoreBrightness scope,
      ThemeData? darkTheme,
    }) async {
      await tester.pumpWidget(
        CoUIApp(
          theme: _light,
          darkTheme: darkTheme ?? _dark,
          themeMode: mode,
          home: Column(
            children: [
              _probe((seen) => outside = seen),
              BrightnessScope(
                brightness: scope,
                child: _probe((seen) => inside = seen),
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('a light scope in a dark app takes the light colours', (
      tester,
    ) async {
      await pump(tester, mode: .dark, scope: .light);

      expect(outside.theme.coreBrightness, CoreBrightness.dark);
      expect(inside.theme.coreBrightness, CoreBrightness.light);
      expect(
        inside.theme.colorScheme.surface,
        _light.colorScheme.surface,
      );
      expect(
        inside.theme.colorScheme.onSurface,
        _light.colorScheme.onSurface,
      );
      expect(
        inside.theme.colorScheme.primary,
        _light.colorScheme.primary,
      );
    });

    testWidgets('a dark scope in a light app takes the dark colours', (
      tester,
    ) async {
      await pump(tester, mode: .light, scope: .dark);

      expect(outside.theme.coreBrightness, CoreBrightness.light);
      expect(inside.theme.coreBrightness, CoreBrightness.dark);
      expect(inside.theme.colorScheme.surface, _dark.colorScheme.surface);
    });

    testWidgets('the shadow strength follows the scope', (tester) async {
      // A dark page casts at four times the alpha; a light app previewed in
      // it must not.
      await pump(tester, mode: .dark, scope: .light);

      expect(outside.theme.geometry.brightness, CoreBrightness.dark);
      expect(inside.theme.geometry.brightness, CoreBrightness.light);
      expect(
        inside.theme.geometry.shadow(CoreShadow.md),
        _light.geometry.shadow(CoreShadow.md),
      );
    });

    testWidgets(
      'the content material takes the scope\u2019s share and dimming',
      (
        tester,
      ) async {
        // A glass style states its fill share and dimming per mode, and the
        // fold turns them into one number for the app's brightness. The scope
        // re-takes them for its own, as the Web scope rules do.
        late _Seen inside;
        late _Seen outside;
        late ThemeData? published;
        await tester.pumpWidget(
          CoUIApp(
            theme: _light,
            darkTheme: _dark,
            themeMode: .dark,
            surfaceStyle: .liquidGlass,
            home: Column(
              children: [
                _probe((seen) => outside = seen),
                BrightnessScope(
                  brightness: .light,
                  child: Builder(
                    builder: (context) {
                      published = AppBrightnessThemes.maybeOf(context, .light);

                      return _probe((seen) => inside = seen);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();

        final recipe = CoreSurfaceRecipe.of(.liquidGlass).surfaceFor(.content)!;
        expect(
          recipe.opacity.light,
          isNot(recipe.opacity.dark),
          reason: 'premise',
        );
        expect(inside.theme.surfaceOpacity, published!.surfaceOpacity);
        expect(inside.theme.surfaceOpacity, recipe.opacity.light);
        expect(outside.theme.surfaceOpacity, recipe.opacity.dark);
        expect(
          inside.theme.surfaceBackdropBrightness,
          recipe.backdropBrightness.light,
        );
      },
    );

    testWidgets('a bare child reads the scope’s onSurface', (
      tester,
    ) async {
      // The text and icon defaults above the scope belong to the
      // surrounding theme; without the restart a bare `Text` inside would
      // keep them. Read from the side where the two differ, so the restart
      // is what the assertion sees.
      await pump(tester, mode: .light, scope: .dark);
      final dark = _dark.colorScheme.onSurface.toValue();

      expect(inside.text, dark);
      expect(inside.icon, dark);
      expect(outside.text, isNot(dark));
      expect(outside.icon, isNot(dark));

      await pump(tester, mode: .dark, scope: .light);
      final light = _light.colorScheme.onSurface.toValue();

      expect(inside.text, light);
      expect(inside.icon, light);
    });

    testWidgets('the colours are the app\u2019s folded ones, not the preset', (
      tester,
    ) async {
      // A surface style bends the palette. CoUI's preset knows nothing of
      // the bend, so a scope reading it would come out unbent.
      late _Seen inside;
      late ThemeData? published;
      await tester.pumpWidget(
        CoUIApp(
          theme: _light,
          darkTheme: _dark,
          themeMode: .dark,
          surfaceStyle: .neoBrutalism,
          home: BrightnessScope(
            brightness: .light,
            child: Builder(
              builder: (context) {
                published = AppBrightnessThemes.maybeOf(context, .light);

                return _probe((seen) => inside = seen);
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(published, isNotNull);
      expect(inside.theme.colorScheme, published!.colorScheme);
      expect(
        inside.theme.colorScheme,
        isNot(_light.colorScheme),
        reason: 'the style bends the light palette too',
      );
    });

    testWidgets('a theme counts for the brightness it is, not its slot', (
      tester,
    ) async {
      // An app may pass one theme of either brightness and switch it itself
      // — a dark one in `theme`, with no `darkTheme`. Publishing it for both
      // would leave a light scope dark.
      late ThemeData? light;
      late ThemeData? dark;
      await tester.pumpWidget(
        CoUIApp(
          theme: _dark,
          home: Builder(
            builder: (context) {
              light = AppBrightnessThemes.maybeOf(context, .light);
              dark = AppBrightnessThemes.maybeOf(context, .dark);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(dark?.colorScheme.surface, _dark.colorScheme.surface);
      expect(light?.coreBrightness, CoreBrightness.light);
      expect(light?.colorScheme.surface, _light.colorScheme.surface);
    });

    testWidgets('the app\u2019s own theme for the other brightness wins', (
      tester,
    ) async {
      // A dark theme that is not CoUI's preset — so only the app's own can
      // produce these colours.
      final ownDark = ThemeData.fromCore(CoreThemePresets.highContrastDark);
      late _Seen inside;
      await tester.pumpWidget(
        CoUIApp(
          theme: _light,
          darkTheme: ownDark,
          themeMode: .light,
          home: BrightnessScope(
            brightness: .dark,
            child: _probe((seen) => inside = seen),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(ownDark.colorScheme, isNot(_dark.colorScheme));
      expect(inside.theme.colorScheme, ownDark.colorScheme);
    });

    testWidgets('a brightness the app gives no theme for is the preset', (
      tester,
    ) async {
      late ThemeData? dark;
      await tester.pumpWidget(
        CoUIApp(
          theme: _light,
          home: Builder(
            builder: (context) {
              dark = AppBrightnessThemes.maybeOf(context, .dark);

              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(dark?.coreBrightness, CoreBrightness.dark);
      expect(dark?.colorScheme.surface, _dark.colorScheme.surface);
    });

    testWidgets('the preset stand-in is folded like the active theme', (
      tester,
    ) async {
      // A style bends the palette; the stand-in for a missing brightness
      // takes the bend too, as the Web stylesheet's scope rules do.
      late ThemeData? light;
      await tester.pumpWidget(
        CoUIApp(
          theme: _dark,
          surfaceStyle: .neoBrutalism,
          home: Builder(
            builder: (context) {
              light = AppBrightnessThemes.maybeOf(context, .light);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(light?.coreBrightness, CoreBrightness.light);
      expect(light?.colorScheme, isNot(_light.colorScheme));
    });

    testWidgets('the published pair is the fold the app itself paints', (
      tester,
    ) async {
      // The active one is what the app renders; the other is folded by the
      // same function, so the two can only differ by brightness.
      late ThemeData active;
      late ThemeData? lightPublished;
      late ThemeData? darkPublished;
      await tester.pumpWidget(
        CoUIApp(
          theme: _light,
          darkTheme: _dark,
          themeMode: .dark,
          surfaceStyle: .neoBrutalism,
          home: Builder(
            builder: (context) {
              active = Theme.of(context);
              lightPublished = AppBrightnessThemes.maybeOf(context, .light);
              darkPublished = AppBrightnessThemes.maybeOf(context, .dark);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(darkPublished?.colorScheme, active.colorScheme);
      expect(darkPublished?.geometry, active.geometry);
      // The style reached the light one too — its geometry is the style's,
      // in the other brightness.
      expect(
        lightPublished?.geometry,
        active.geometry.copyWith(brightness: .light),
      );
    });
  });

  group('a panel opened inside it', () {
    // The panel is mounted on the overlay, outside the scope; it captures the
    // theme of the place it opened from (`InheritedTheme.capture`), so it
    // paints what the app paints in the scope's brightness. The Web twin
    // states the scope again around its portalled panel
    // (`packages/coui_web/test/base/brightness_scope_panel_test.dart`).

    /// The fills painted around the text [label], nearest first, up to the
    /// overlay it is mounted on.
    List<Color> fillsAround(WidgetTester tester, String label) {
      final fills = <Color>[];
      tester.element(find.text(label)).visitAncestorElements((element) {
        final widget = element.widget;
        if (widget is Overlay) return false;
        if (widget is DecoratedBox) {
          final decoration = widget.decoration;
          if (decoration is BoxDecoration && decoration.color != null) {
            fills.add(decoration.color!);
          }
        }
        if (widget is ColoredBox) fills.add(widget.color);

        return true;
      });

      return fills;
    }

    /// [child] in a `CoUIApp` in [mode], inside a scope when [scope] is set.
    Widget app(CoreThemeMode mode, CoreBrightness? scope, Widget child) =>
        CoUIApp(
          theme: _light,
          darkTheme: _dark,
          themeMode: mode,
          home: Center(
            child: scope == null
                ? child
                : BrightnessScope(brightness: scope, child: child),
          ),
        );

    /// The fills around an open popover's panel.
    Future<List<Color>> popoverFills(
      WidgetTester tester, {
      required CoreThemeMode mode,
      CoreBrightness? scope,
    }) async {
      final controller = PopoverController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        app(
          mode,
          scope,
          Popover(
            controller: controller,
            openTrigger: CorePopoverTrigger.manual,
            trigger: const Text('trigger'),
            content: const Text('panel'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      controller.show();
      // The panel follows its trigger every tick, so it never settles.
      await tester.pump();
      await tester.pump(_kPanelSettle);
      final fills = fillsAround(tester, 'panel');
      controller.close();
      await tester.pump(_kPanelSettle);

      return fills;
    }

    /// The fills around an open dialog's content.
    Future<List<Color>> dialogFills(
      WidgetTester tester, {
      required CoreThemeMode mode,
      CoreBrightness? scope,
    }) async {
      await tester.pumpWidget(app(mode, scope, const Text('anchor')));
      await tester.pumpAndSettle();
      unawaited(
        showDialog<void>(
          context: tester.element(find.text('anchor')),
          builder: (_) => const Dialog(content: Text('panel')),
        ),
      );
      await tester.pumpAndSettle();
      final fills = fillsAround(tester, 'panel');
      Navigator.of(tester.element(find.text('panel'))).pop();
      await tester.pumpAndSettle();

      return fills;
    }

    for (final opener in [
      (name: 'a popover', fills: popoverFills),
      (name: 'a dialog', fills: dialogFills),
    ]) {
      testWidgets('${opener.name} paints in the scope’s brightness', (
        tester,
      ) async {
        final light = await opener.fills(tester, mode: .light);
        final dark = await opener.fills(tester, mode: .dark);
        // The two brightnesses paint the panel differently, or a match
        // below would prove nothing.
        expect(dark, isNotEmpty);
        expect(dark, isNot(light));

        expect(
          await opener.fills(tester, mode: .light, scope: .dark),
          dark,
          reason: 'a dark scope in a light app paints the dark panel',
        );
        expect(
          await opener.fills(tester, mode: .dark, scope: .light),
          light,
          reason: 'a light scope in a dark app paints the light panel',
        );
      });
    }
    testWidgets('a drawer keeps the brightness around its navigator', (
      tester,
    ) async {
      // The drawer route captures no theme from the place it opened, so a
      // drawer opened inside a dark scope renders in the app's light — the
      // Web drawer does not pass through the capture either.
      late _Seen drawer;
      await tester.pumpWidget(app(.light, .dark, const Text('anchor')));
      await tester.pumpAndSettle();
      final opener = tester.element(find.text('anchor'));
      expect(Theme.of(opener).coreBrightness, CoreBrightness.dark);

      unawaited(
        openDrawer<void>(
          context: opener,
          side: .left,
          builder: (_) => _probe((seen) => drawer = seen),
        ),
      );
      await tester.pumpAndSettle();

      expect(drawer.theme.coreBrightness, CoreBrightness.light);
      expect(drawer.theme.colorScheme.surface, _light.colorScheme.surface);
    });
  });

  group('without CoUIApp', () {
    testWidgets('the brightness around it keeps its own colours', (
      tester,
    ) async {
      late _Seen inside;
      await tester.pumpWidget(
        buildTestApp(
          BrightnessScope(
            brightness: .light,
            child: _probe((seen) => inside = seen),
          ),
          theme: _light,
        ),
      );

      expect(inside.theme.colorScheme, _light.colorScheme);
    });

    testWidgets('the other brightness reads CoUI’s preset', (
      tester,
    ) async {
      late _Seen inside;
      await tester.pumpWidget(
        buildTestApp(
          BrightnessScope(
            brightness: .dark,
            child: _probe((seen) => inside = seen),
          ),
          theme: _light,
        ),
      );

      expect(inside.theme.coreBrightness, CoreBrightness.dark);
      expect(inside.theme.colorScheme.surface, _dark.colorScheme.surface);
    });

    testWidgets('what is not a colour stays the surroundings’', (
      tester,
    ) async {
      const componentTheme = CoreComponentTheme(
        chatBubble: CoreChatBubbleTheme(
          style: CoreChatBubbleStyle(tailEdge: .top),
        ),
      );
      late _Seen outside;
      late _Seen inside;
      await tester.pumpWidget(
        buildTestApp(
          Column(
            children: [
              _probe((seen) => outside = seen),
              BrightnessScope(
                brightness: .dark,
                child: _probe((seen) => inside = seen),
              ),
            ],
          ),
          theme: _light,
          componentTheme: componentTheme,
          density: .compact,
        ),
      );

      expect(inside.theme.coreComponentTheme, componentTheme);
      expect(inside.theme.typography, outside.theme.typography);
      expect(inside.theme.scaling, outside.theme.scaling);
      expect(
        inside.theme.geometry.density,
        outside.theme.geometry.density,
        reason: 'only the brightness of the geometry moves',
      );
    });
  });
}
