import 'dart:convert';
import 'dart:io';

import 'package:coui_core/coui_core.dart';
import 'package:coui_flutter/coui_flutter.dart'
    show CoreColorToFlutter, CoreTextStyleToFlutter, ThemeData;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

final _observations = <Map<String, Object?>>[];

CoreColor _floatOpacity() => CoreThemePresets.lightColorScheme.resolve(
  const CoreColor.token(CoreColors.primary, opacity: .3),
);

void _record(String name, CoreColor input, Color value, Color canonical) {
  _observations.add({
    'case': name,
    'inputARGB32': input.argb,
    'inputOpacity': input.opacity,
    'inputIsResolved': input.isResolved,
    'inputToken': input.token?.name,
    'styleA': value.a,
    'canonicalA': canonical.a,
    'styleARGB32': value.toARGB32(),
    'canonicalARGB32': canonical.toARGB32(),
    'difference': value.a - canonical.a,
  });
}

Object? _errorOf(void Function() action) {
  try {
    action();
    return null;
  } on Object catch (error) {
    return error;
  }
}

void main() {
  tearDownAll(() {
    final path = Platform.environment['CORE_TEXT_ALPHA_OBSERVATIONS'];
    if (path != null) File(path).writeAsStringSync(jsonEncode(_observations));
  });

  test('raw CoreTextStyle preserves the float opacity of its CoreColor', () {
    final input = _floatOpacity();
    final canonical = input.toValue();
    final value = CoreTextStyle(color: input).toValue().color!;
    _record('raw float opacity', input, value, canonical);
    expect(canonical.a, .3);
    expect(value.a, .3);
  });

  test('stored ARGB alpha and float opacity compose without a new lattice', () {
    final input = CoreThemePresets.lightColorScheme
        .copyWith(primary: const CoreColor(0x8019334D))
        .resolve(const CoreColor.token(CoreColors.primary, opacity: .3));
    final canonical = input.toValue();
    final value = CoreTextStyle(color: input).toValue().color!;
    _record('packed alpha times float opacity', input, value, canonical);
    expect(canonical.a, (128 / 255) * .3);
    expect(value.a, (128 / 255) * .3);
  });

  test('the public partial overlay conversion preserves the same opacity', () {
    final input = _floatOpacity();
    final converted = CoreTextStyle(color: input).toOverlayValue();
    final canonical = input.toValue();
    _record(
      'partial overlay float opacity',
      input,
      converted.color!,
      canonical,
    );
    expect(converted.fontSize, isNull);
    expect(converted.fontWeight, isNull);
    expect(converted.color!.a, .3);
  });

  for (final (name, input, expectedAlpha) in [
    ('opaque ARGB', const CoreColor(0xFF19334D), 1.0),
    ('already packed ARGB alpha', const CoreColor(0x8019334D), 128 / 255),
    ('transparent ARGB', CoreColor.transparent, 0.0),
  ]) {
    test('existing $name interpretation is retained', () {
      final canonical = input.toValue();
      final value = CoreTextStyle(color: input).toValue().color!;
      _record(name, input, value, canonical);
      expect(value.a, expectedAlpha);
      expect(canonical.a, expectedAlpha);
      expect(value.toARGB32(), input.argb);
    });
  }

  test(
    'an explicit Flutter color overrides the style color without packing',
    () {
      final input = _floatOpacity();
      const override = Color.from(alpha: .27, red: .1, green: .2, blue: .3);
      final value = CoreTextStyle(color: input).toValue(color: override).color!;
      _record('explicit Flutter color override', input, value, override);
      expect(identical(value, override), isTrue);
      expect(value.a, .27);
    },
  );

  test('the existing theme-aware path retains float opacity', () {
    final input = _floatOpacity();
    final value = CoreTextStyle(color: input).toValue(theme: const ThemeData());
    _record('theme-aware conversion', input, value.color!, input.toValue());
    expect(value.color!.a, .3);
  });

  test('unmaterialised typography tokens still require a theme', () {
    const style = CoreTextStyle.token(CoreTextStyles.bodyMedium);
    final errors = [
      _errorOf(() => style.toValue()),
      _errorOf(() => style.toValue(color: const Color(0xFF19334D))),
    ];
    _observations.add({
      'case': 'unresolved typography token without theme',
      'errors': [for (final error in errors) error.toString()],
    });
    for (final error in errors) {
      expect(error, isA<StateError>());
    }
  });

  test('unresolved own-color retains the existing canonical fallback', () {
    const input = CoreColor.token(CoreColors.primary, opacity: .3);
    final canonical = input.toValue();
    final value = const CoreTextStyle(color: input).toValue().color!;
    _record('unresolved own-color canonical fallback', input, value, canonical);
    expect(canonical.a, .3);
    expect(value.a, .3);
  });

  test('raw withOpacity intentionally remains an already packed color', () {
    final input = const CoreColor(0xFF19334D).withOpacity(.3);
    final canonical = input.toValue();
    final value = CoreTextStyle(color: input).toValue().color!;
    _record('raw withOpacity packed control', input, value, canonical);
    expect(input.opacity, 1);
    expect(canonical.a, 77 / 255);
    expect(value.a, 77 / 255);
  });

  testWidgets(
    'actual RenderParagraph retains the converted versus canonical alpha',
    (
      tester,
    ) async {
      final input = _floatOpacity();
      final converted = CoreTextStyle(color: input, fontSize: 16).toValue();
      final canonical = input.toValue();
      const convertedKey = ValueKey('converted text');
      const canonicalKey = ValueKey('canonical text');
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Column(
            children: [
              Text('alpha', key: convertedKey, style: converted),
              Text(
                'alpha',
                key: canonicalKey,
                style: converted.copyWith(color: canonical),
              ),
            ],
          ),
        ),
      );
      RenderParagraph paragraph(Key key) =>
          tester.renderObject<RenderParagraph>(
            find.descendant(
              of: find.byKey(key),
              matching: find.byType(RichText),
            ),
          );
      final actual = paragraph(convertedKey);
      final reference = paragraph(canonicalKey);
      final actualColor = actual.text.style!.color!;
      final referenceColor = reference.text.style!.color!;
      _record(
        'actual RenderParagraph style',
        input,
        actualColor,
        referenceColor,
      );
      _observations.add({
        'case': 'paragraph renderer evidence',
        'convertedAttached': actual.attached,
        'canonicalAttached': reference.attached,
        'sameSize': actual.size == reference.size,
        'convertedText': actual.text.toPlainText(),
        'canonicalText': reference.text.toPlainText(),
        'samePackedARGB32': actualColor.toARGB32() == referenceColor.toARGB32(),
        'pixelCaptureOrVisibleDifferenceClaim': false,
      });
      expect(actual.attached && reference.attached, isTrue);
      expect(actual.size, reference.size);
      expect(referenceColor.a, .3);
      expect(actualColor.a, .3);
    },
  );
}
