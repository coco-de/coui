import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

// The demo locales the regression was reported against (#5352). Each now
// ships its own chrome translation, and several (fr · es · pt) are wider
// than the English labels.
const _kLocales = [
  Locale('ko'),
  Locale('en'),
  Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans'),
  Locale('ja'),
  Locale('de'),
  Locale('fr'),
  Locale('es'),
  Locale('pt'),
  Locale('it'),
  Locale('ru'),
  Locale('ar'),
];

const _kTextScales = [1.0, 1.3, 2.0];

// The text scale from which a label's LINE BOX (font × scale × 1.5 line, times
// the phone-density 1.25) is taller than the 36-high button it sits in. Below
// it the line box fits and is asserted; from it the glyphs still sit inside the
// button (asserted instead, against the glyph height) but the extra leading
// does not — the cell is a fixed 36 row, so the 150% line of `bodyMedium` is
// the first thing to overrun it.
const _kLineBoxOverrunsFrom = 2.0;

// A phone-density theme: every box is 1.25× its logical size.
const _kScaling = AdaptiveScaling(1.25);

void main() {
  group('Pagination showLabel (#5352)', () {
    for (final locale in _kLocales) {
      for (final scale in _kTextScales) {
        testWidgets(
          'previous / next fit their label — ${locale.toLanguageTag()} '
          '× textScaler $scale × scaling 1.25',
          (tester) async {
            // Wide enough that the whole row fits — the claim is about each
            // button, not about the row against the screen edge (the widest
            // translations at 2× text overrun an 800 px test view).
            tester.view
              ..physicalSize = const Size(3200, 600)
              ..devicePixelRatio = 1;
            addTearDown(tester.view.reset);
            await tester.pumpWidget(_app(locale: locale, textScale: scale));
            await tester.pump();

            expect(tester.takeException(), isNull);
            final localizations = CoUILocalizations.of(
              tester.element(find.byType(Pagination)),
            );
            _expectFits(
              tester,
              localizations.buttonPrevious,
              textScale: scale,
            );
            _expectFits(tester, localizations.buttonNext, textScale: scale);
          },
        );
      }
    }

    testWidgets(
      'a label longer than any shipped one still widens its button',
      (tester) async {
        // Wide enough that the whole row fits — the claim is about each
        // button, not about the row against the screen edge.
        tester.view
          ..physicalSize = const Size(3200, 600)
          ..devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        await tester.pumpWidget(
          _app(
            locale: const Locale('en'),
            textScale: 2,
            localizations: const _LongLabels(),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        _expectFits(tester, _LongLabels.previous, textScale: 2);
        _expectFits(tester, _LongLabels.next, textScale: 2);
      },
    );

    testWidgets('page buttons stay square and as tall as the label buttons', (
      tester,
    ) async {
      await tester.pumpWidget(_app(locale: const Locale('en'), textScale: 1));
      await tester.pump();

      final page = tester.getSize(_buttonFace(find.text('2')));
      expect(page.width, page.height);
      final previous = tester.getSize(_buttonFace(find.text('Previous')));
      expect(previous.height, page.height);
      // Content-driven, not the square page box.
      expect(previous.width, greaterThan(page.width));
    });

    testWidgets('without a label the previous / next buttons stay square', (
      tester,
    ) async {
      await tester.pumpWidget(
        _app(locale: const Locale('en'), textScale: 1, showLabel: false),
      );
      await tester.pump();

      final page = tester.getSize(_buttonFace(find.text('2')));
      final previous = tester.getSize(
        // The previous button is the row's first child.
        _buttonFace(find.byType(Icon).first),
      );
      expect(previous, page);
    });
  });
}

Widget _app({
  required Locale locale,
  required double textScale,
  bool showLabel = true,
  CoUILocalizations? localizations,
}) {
  final pagination = Pagination(
    page: 2,
    totalPages: 3,
    showLabel: showLabel,
    onPageChanged: (_) {},
  );

  return CoUIApp(
    theme: const ThemeData(),
    scaling: _kScaling,
    locale: locale,
    supportedLocales: _kLocales,
    // Consumer delegates resolve ahead of CoUI's own.
    localizationsDelegates: [
      if (localizations != null) _FixedLocalizationsDelegate(localizations),
    ],
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: Center(child: pagination),
      ),
    ),
  );
}

/// The box a pagination button paints — the `OutlinedContainer` the
/// [content] sits in.
Finder _buttonFace(Finder content) =>
    find.ancestor(of: content, matching: find.byType(OutlinedContainer)).first;

/// The label renders at its full intrinsic size, and inside its button.
void _expectFits(WidgetTester tester, String label, {double textScale = 1}) {
  final text = find.text(label);
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)),
  );
  expect(paragraph.didExceedMaxLines, isFalse, reason: '"$label" wrapped');
  final intrinsicWidth = paragraph.getMaxIntrinsicWidth(double.infinity);
  expect(
    paragraph.size.width + 0.5,
    greaterThanOrEqualTo(intrinsicWidth),
    reason:
        '"$label" squeezed (${paragraph.size.width} < intrinsic '
        '$intrinsicWidth)',
  );
  final intrinsicHeight = paragraph.getMaxIntrinsicHeight(
    paragraph.size.width,
  );
  if (textScale < _kLineBoxOverrunsFrom) {
    expect(
      paragraph.size.height + 0.5,
      greaterThanOrEqualTo(intrinsicHeight),
      reason: '"$label" clipped vertically',
    );
  } else {
    // Past the overrun the line box is taller than the button; what must
    // still hold is the glyph row: the button is at least as tall as the text
    // at its scaled size (font 14 × the text scale × the 1.25 density).
    final glyphHeight = 14 * textScale * _kScaling.sizeScaling;
    final buttonHeight = tester.getRect(_buttonFace(text)).height;
    expect(
      buttonHeight + 0.5,
      greaterThanOrEqualTo(glyphHeight),
      reason: '"$label" glyphs ($glyphHeight) taller than the button',
    );
  }

  final face = tester.getRect(_buttonFace(text));
  final label_ = tester.getRect(text);
  expect(
    face.left <= label_.left + 0.5 && label_.right <= face.right + 0.5,
    isTrue,
    reason: '"$label" $label_ spills out of its button $face',
  );
}

class _FixedLocalizationsDelegate
    extends LocalizationsDelegate<CoUILocalizations> {
  const _FixedLocalizationsDelegate(this.localizations);

  final CoUILocalizations localizations;

  @override
  bool isSupported(Locale locale) => true;

  @override
  Future<CoUILocalizations> load(Locale locale) =>
      SynchronousFuture(localizations);

  @override
  bool shouldReload(_FixedLocalizationsDelegate old) => false;
}

class _LongLabels extends DefaultCoUILocalizations {
  const _LongLabels();

  static const previous = 'Vorherige Ergebnisseite';
  static const next = 'Nächste Ergebnisseite';

  @override
  String get buttonPrevious => previous;

  @override
  String get buttonNext => next;
}
