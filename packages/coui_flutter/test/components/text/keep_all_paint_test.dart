import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart' as material;
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../parity/parity_fonts.dart';

const _kBoundaryKey = ValueKey<String>('keep-all-paint');

Future<Uint8List> _capture(
  WidgetTester tester, {
  required bool dark,
  required bool keepAll,
}) async {
  final theme = ThemeData.fromCore(
    dark ? CoreThemePresets.dark : CoreThemePresets.light,
  );
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: theme,
        child: Builder(
          builder: (context) {
            final scheme = Theme.of(context).colorScheme;
            return Align(
              alignment: .topLeft,
              child: RepaintBoundary(
                key: _kBoundaryKey,
                child: ColoredBox(
                  color: scheme.surface.toValue(),
                  child: SizedBox(
                    width: 420,
                    height: 100,
                    child: Align(
                      alignment: .topLeft,
                      child: DefaultTextStyle(
                        style: TextStyle(
                          fontFamily: CoreFontFamily.sans,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                          letterSpacing: -0.4,
                          color: scheme.onSurface.toValue(),
                        ),
                        child: WrappedText(
                          wordBreakKeepAll: keepAll,
                          child: const Text(
                            '한글 제목 A한B',
                            textScaler: TextScaler.linear(1.7),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(_kBoundaryKey),
  );
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage();
    try {
      final rgba = await image.toByteData();
      final directory = Platform.environment['COUI_KEEP_ALL_EVIDENCE'];
      if (directory != null) {
        await Directory(directory).create(recursive: true);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(
          '$directory/${dark ? 'dark' : 'light'}-'
          '${keepAll ? 'keep-all' : 'plain'}.png',
        ).writeAsBytes(png!.buffer.asUint8List());
      }
      return rgba!.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  });
  return bytes!;
}

void main() {
  setUpAll(loadParityFonts);

  testWidgets('keep-all preserves glyph paint in real light and dark themes', (
    tester,
  ) async {
    Uint8List? light;
    for (final dark in [false, true]) {
      final plain = await _capture(tester, dark: dark, keepAll: false);
      final kept = await _capture(tester, dark: dark, keepAll: true);
      expect(kept.length, plain.length);
      var differentPixels = 0;
      for (var i = 0; i < plain.length; i += 4) {
        if (plain[i] != kept[i] ||
            plain[i + 1] != kept[i + 1] ||
            plain[i + 2] != kept[i + 2] ||
            plain[i + 3] != kept[i + 3]) {
          differentPixels += 1;
        }
      }
      expect(differentPixels, 0, reason: dark ? 'dark' : 'light');
      if (dark) {
        expect(listEquals(plain, light), isFalse);
      } else {
        light = plain;
      }
    }
  });
}
