import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:cupertino_ui/cupertino_ui.dart' as cupertino;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart' show GlobalKey, Widget;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;

import 'capture_host.dart';
import 'capture_localizations.dart';
import 'parity_fonts.dart';

Widget _host(Widget child, coui.ThemeData theme) => coui.Theme(
  data: theme,
  child: material.Directionality(
    textDirection: .ltr,
    child: material.MediaQuery(
      data: const material.MediaQueryData(
        size: ui.Size(800, 600),
        devicePixelRatio: 1,
      ),
      child: material.Material(
        color: material.Colors.transparent,
        textStyle: theme.typography.bodyMedium
            .toValue(theme: theme)
            .copyWith(color: theme.colorScheme.onSurface.toValue()),
        child: material.Overlay(
          initialEntries: [
            material.OverlayEntry(builder: (_) => captureHost(child: child)),
          ],
        ),
      ),
    ),
  ),
);

Future<Uint8List> _pixels(WidgetTester tester, GlobalKey boundaryKey) async {
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final image = (await tester.runAsync(() => boundary.toImage()))!;
  try {
    final data = (await tester.runAsync(
      () => image.toByteData(format: ui.ImageByteFormat.rawRgba),
    ))!;
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  } finally {
    image.dispose();
  }
}

void main() {
  setUpAll(loadParityFonts);

  testWidgets('publishes the canonical docs locale and public resources', (
    tester,
  ) async {
    final theme = coui.ThemeData.fromCore(coui.CoreThemePresets.light);
    material.BuildContext? seen;
    await tester.pumpWidget(
      captureLocalizations(
        child: _host(
          material.Builder(
            builder: (context) {
              seen = context;
              return const material.SizedBox(width: 10, height: 10);
            },
          ),
          theme,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final context = seen!;
    const canonical = coui.CoUIApp(theme: coui.ThemeData());
    expect(canonical.supportedLocales, const [ui.Locale('en', 'US')]);
    expect(
      material.Localizations.localeOf(context),
      canonical.supportedLocales.single,
    );
    expect(
      material.WidgetsLocalizations.of(context).textDirection,
      ui.TextDirection.ltr,
    );
    expect(
      material.MaterialLocalizations.of(context).okButtonLabel,
      isNotEmpty,
    );
    expect(
      cupertino.CupertinoLocalizations.of(context).copyButtonLabel,
      isNotEmpty,
    );
    expect(coui.CoUILocalizations.of(context), isNotNull);
    final localizations = tester.widget<material.Localizations>(
      find.byType(material.Localizations),
    );
    expect(localizations.isApplicationLevel, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'RichEditor renders non-English document text in the capture host',
    (
      tester,
    ) async {
      await tester.pumpWidget(
        captureLocalizations(
          child: _host(
            const material.SizedBox(
              width: 384,
              child: coui.RichEditor(initialValue: '# 안녕하세요\n\nمرحبا'),
            ),
            coui.ThemeData.fromCore(coui.CoreThemePresets.light),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final text = tester
          .widgetList<material.RichText>(find.byType(material.RichText))
          .map((widget) => widget.text.toPlainText())
          .join('\n');
      expect(text, contains('안녕하세요'));
      expect(text, contains('مرحبا'));
      expect(tester.takeException(), isNull);
    },
  );

  for (final dark in [false, true]) {
    testWidgets(
      'localization preserves the ${dark ? 'dark' : 'light'} host and paint',
      (
        tester,
      ) async {
        final theme = coui.ThemeData.fromCore(
          dark ? coui.CoreThemePresets.dark : coui.CoreThemePresets.light,
        );
        const media = material.MediaQueryData(
          size: ui.Size(800, 600),
          devicePixelRatio: 1,
        );
        final root = GlobalKey();
        final boundary = GlobalKey();
        late coui.ThemeData seenTheme;
        late ui.TextDirection seenDirection;
        late material.MediaQueryData seenMedia;
        Widget app() => _host(
          material.RepaintBoundary(
            key: boundary,
            child: material.Builder(
              key: root,
              builder: (context) {
                seenTheme = coui.Theme.of(context);
                seenDirection = material.Directionality.of(context);
                seenMedia = material.MediaQuery.of(context);
                return material.Column(
                  mainAxisSize: .min,
                  children: [
                    coui.Button(onPressed: () {}, child: const coui.Text('기본')),
                    const coui.Text('한국어 مرحبا'),
                  ],
                );
              },
            ),
          ),
          theme,
        );

        await tester.pumpWidget(app());
        await tester.pumpAndSettle();
        expect(identical(seenTheme, theme), isTrue);
        expect(seenDirection, ui.TextDirection.ltr);
        expect(seenMedia, media);
        final oldRootSize = tester.getSize(find.byKey(root));
        final oldBoundarySize = tester.getSize(find.byKey(boundary));
        final oldPixels = await _pixels(tester, boundary);

        await tester.pumpWidget(const material.SizedBox.shrink());
        await tester.pumpWidget(captureLocalizations(child: app()));
        await tester.pumpAndSettle();
        expect(identical(seenTheme, theme), isTrue);
        expect(seenDirection, ui.TextDirection.ltr);
        expect(seenMedia, media);
        expect(tester.getSize(find.byKey(root)), oldRootSize);
        expect(tester.getSize(find.byKey(boundary)), oldBoundarySize);
        expect(await _pixels(tester, boundary), orderedEquals(oldPixels));
        expect(tester.takeException(), isNull);
      },
    );
  }
}
