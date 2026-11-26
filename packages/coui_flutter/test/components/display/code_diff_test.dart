// The retired alpha / colour fields stay declared so apps that state them still
// compile, and the tests below state them on purpose to pin that nothing they
// say is painted — so this file names deprecated members deliberately.
// ignore_for_file: deprecated_member_use
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

// Test constants.
const _kLineNumberWidth = 64.0;
const _kBorderWidth = 2.0;

// The 21px grid: the code roles' line box, and the gutter geometry.
const _kLineBox = 21.0;
const _kPrefixX = 52.0; // 12 row inset + 28 digit column + 12 gap
const _kGutterWidth = 40.0;
const _kGutterGap = 12.0;
const _kDigitColumn = 28.0;
const _kPanelRadius = 12.0;
const _kBodyFontSize = 13.0;
const _kGutterFontSize = 12.0;

const _kLines = [
  CoreCodeDiffLine(
    text: 'unchanged',
    type: .unchanged,
    lineNumber: 1,
  ),
  CoreCodeDiffLine(
    text: 'removed',
    type: .removed,
    lineNumber: 2,
  ),
  CoreCodeDiffLine(
    text: 'added',
    type: .added,
    lineNumber: 3,
  ),
];

Widget _buildApp(Widget child, {ThemeData? theme}) {
  return material.MaterialApp(
    home: Theme(
      data: theme ?? const ThemeData(),
      child: material.Material(child: child),
    ),
  );
}

/// The `Container` that paints one row (padding + background + the Row).
Finder _rowOf(String text) =>
    find.ancestor(of: find.text(text), matching: find.byType(Container));

/// A token resolved the way the app resolves it, against [theme]'s scheme.
Color _token(ThemeData theme, CoreColorToken token) =>
    theme.colorScheme.resolve(CoreColor.token(token)).toValue();

/// The band a row paints behind its content.
Color? _bandOf(WidgetTester tester, String text) =>
    tester.widget<Container>(_rowOf(text).first).color;

Color? _inkOf(WidgetTester tester, String text) =>
    tester.widget<Text>(find.text(text)).style?.color;

/// Whether [color] is fully opaque. A band that carried an alpha would let the
/// face behind it show through, which is what the retired tint did.
bool _isOpaque(Color? color) => color != null && color.a == 1.0;

void main() {
  group('CodeDiff', () {
    testWidgets('renders text + prefix span per line', (tester) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      expect(find.text('unchanged'), findsOneWidget);
      expect(find.text('removed'), findsOneWidget);
      expect(find.text('added'), findsOneWidget);
      // Prefix spans render as separate Text widgets.
      expect(find.text('+ '), findsOneWidget);
      expect(find.text('- '), findsOneWidget);
    });

    testWidgets('shows line numbers by default, hides when disabled', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines, showLineNumbers: false)),
      );
      expect(find.text('1'), findsNothing);
      expect(find.text('2'), findsNothing);
      expect(find.text('3'), findsNothing);
    });

    testWidgets('resolves theme colours in dark mode without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(lines: _kLines),
          theme: const ThemeData.dark(),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('added'), findsOneWidget);
    });

    testWidgets('applies per-instance style override (gutter width)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(
              borderWidth: _kBorderWidth,
              lineNumberWidth: _kLineNumberWidth,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);

      final gutter = tester.widget<SizedBox>(
        find
            .ancestor(of: find.text('1'), matching: find.byType(SizedBox))
            .first,
      );
      expect(gutter.width, _kLineNumberWidth);
    });

    testWidgets('onLineTap fires for the tapped row and is silent when null', (
      tester,
    ) async {
      CoreCodeDiffLine? tapped;

      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));
      await tester.tap(find.text('added'));
      await tester.pump();
      expect(tapped, isNull);

      await tester.pumpWidget(
        _buildApp(
          CodeDiff(
            lines: _kLines,
            onLineTap: (line) => tapped = line,
          ),
        ),
      );
      await tester.tap(find.text('added'));
      await tester.pump();
      expect(tapped?.text, equals('added'));
      expect(tapped?.type, equals(CoreCodeDiffLineType.added));
    });
  });

  group('CodeDiff rendered geometry — the 21px grid', () {
    testWidgets('every row is exactly one 21px line box tall, rows abut', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      // The painted row is the Container around each Row.
      final unchanged = tester.getRect(_rowOf('unchanged').first);
      final removed = tester.getRect(_rowOf('removed').first);
      final added = tester.getRect(_rowOf('added').first);

      expect(unchanged.height, closeTo(_kLineBox, 0.01));
      expect(removed.height, closeTo(_kLineBox, 0.01));
      expect(added.height, closeTo(_kLineBox, 0.01));
      // Rows abut: no gap and no overlap between neighbours.
      expect(removed.top, closeTo(unchanged.bottom, 0.01));
      expect(added.top, closeTo(removed.bottom, 0.01));
    });

    testWidgets('gutter and body text are the 12 / 13 code roles on 21px', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      final gutter = tester.widget<Text>(find.text('1')).style!;
      final body = tester.widget<Text>(find.text('unchanged')).style!;
      final prefix = tester.widget<Text>(find.text('+ ')).style!;

      expect(gutter.fontSize, _kGutterFontSize);
      expect(body.fontSize, _kBodyFontSize);
      expect(prefix.fontSize, _kBodyFontSize);
      // A fixed 21px line box: height multiplier x size lands on 21.
      expect(gutter.height! * gutter.fontSize!, closeTo(_kLineBox, 0.01));
      expect(body.height! * body.fontSize!, closeTo(_kLineBox, 0.01));
      // Monospace family on both, and no tracking.
      expect(gutter.fontFamily, contains('Mono'));
      expect(body.fontFamily, contains('Mono'));
      expect(gutter.letterSpacing ?? 0, 0);
      expect(body.letterSpacing ?? 0, 0);
    });

    testWidgets('the gutter cell is 40 wide with a 28 digit column', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      final cell = find
          .ancestor(of: find.text('1'), matching: find.byType(SizedBox))
          .first;
      expect(tester.getSize(cell).width, _kGutterWidth);
      // The number's own box is the cell minus the end-side gap.
      expect(tester.getSize(find.text('1')).width, _kDigitColumn);
    });

    testWidgets('the prefix starts at x = 52 from the row edge', (
      tester,
    ) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      final row = tester.getTopLeft(_rowOf('removed').first);
      final prefix = tester.getTopLeft(find.text('- '));
      final gutter = tester.getTopLeft(
        find
            .ancestor(of: find.text('2'), matching: find.byType(SizedBox))
            .first,
      );

      expect(prefix.dx - row.dx, closeTo(_kPrefixX, 0.01));
      // The gutter cell starts after the row's 12px inset.
      expect(gutter.dx - row.dx, closeTo(_kGutterGap, 0.01));
    });

    testWidgets('the outer corner is the 12 panel role', (tester) async {
      await tester.pumpWidget(_buildApp(const CodeDiff(lines: _kLines)));

      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(CodeDiff),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;

      expect(decoration.borderRadius, BorderRadius.circular(_kPanelRadius));
    });

    testWidgets('a wrapped text keeps the number and prefix on line one', (
      tester,
    ) async {
      final longLine = List.filled(40, 'word').join(' ');
      await tester.pumpWidget(
        _buildApp(
          SizedBox(
            width: 240,
            child: CodeDiff(
              lines: [
                CoreCodeDiffLine(
                  text: longLine,
                  type: .added,
                  lineNumber: 7,
                ),
              ],
            ),
          ),
        ),
      );

      final row = tester.getRect(_rowOf(longLine).first);
      final number = tester.getRect(find.text('7'));
      final prefix = tester.getRect(find.text('+ '));
      final body = tester.getRect(find.text(longLine));

      // The text wraps onto several 21px lines, so the row is taller ...
      expect(row.height, greaterThan(_kLineBox * 2));
      // ... and the number and prefix stay on the first line instead of
      // centring against the wrapped block.
      expect(number.top, closeTo(body.top, 0.01));
      expect(prefix.top, closeTo(body.top, 0.01));
      expect(number.height, closeTo(_kLineBox, 0.01));
    });
  });

  group('CodeDiff painted colours — opaque bands', () {
    // Real resolved schemes, not the tokenized default: only a scheme with
    // concrete values can tell light from dark.
    final light = ThemeData.fromCore(CoreThemePresets.light);
    final dark = ThemeData.fromCore(CoreThemePresets.dark);

    testWidgets('an added / removed row is an opaque container band', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      final added = _bandOf(tester, 'added');
      final removed = _bandOf(tester, 'removed');

      expect(added, _token(light, CoreColors.successContainer));
      expect(removed, _token(light, CoreColors.errorContainer));
      expect(_isOpaque(added), isTrue);
      expect(_isOpaque(removed), isTrue);
      // The two bands are different faces, not one tint of one colour.
      expect(added, isNot(removed));
    });

    testWidgets('an unchanged row has no band', (tester) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      expect(_bandOf(tester, 'unchanged'), Colors.transparent);
    });

    testWidgets('the prefix wears the ink of the band it sits on', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      expect(
        _inkOf(tester, '+ '),
        _token(light, CoreColors.onSuccessContainer),
      );
      expect(_inkOf(tester, '- '), _token(light, CoreColors.onErrorContainer));
      // An unchanged row has no band: its blank prefix keeps the body ink.
      expect(_inkOf(tester, '  '), _token(light, CoreColors.onSurface));
    });

    testWidgets('the code keeps the body ink on every row', (tester) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      final onSurface = _token(light, CoreColors.onSurface);
      expect(_inkOf(tester, 'unchanged'), onSurface);
      expect(_inkOf(tester, 'removed'), onSurface);
      expect(_inkOf(tester, 'added'), onSurface);
    });

    testWidgets('the gutter number is the band ink on a band, onSurfaceVariant '
        'on a plain row, and never dimmed', (tester) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      final plain = _inkOf(tester, '1');
      final removed = _inkOf(tester, '2');
      final added = _inkOf(tester, '3');

      expect(plain, _token(light, CoreColors.onSurfaceVariant));
      expect(removed, _token(light, CoreColors.onErrorContainer));
      expect(added, _token(light, CoreColors.onSuccessContainer));
      // Hierarchy is the token, not an alpha: all three are fully opaque.
      expect(_isOpaque(plain), isTrue);
      expect(_isOpaque(removed), isTrue);
      expect(_isOpaque(added), isTrue);
    });

    testWidgets('dark mode resolves the same tokens against the dark scheme', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: dark),
      );

      expect(
        _bandOf(tester, 'added'),
        _token(dark, CoreColors.successContainer),
      );
      expect(
        _bandOf(tester, 'removed'),
        _token(dark, CoreColors.errorContainer),
      );
      expect(
        _inkOf(tester, '+ '),
        _token(dark, CoreColors.onSuccessContainer),
      );
      expect(_inkOf(tester, '2'), _token(dark, CoreColors.onErrorContainer));
      expect(_inkOf(tester, '1'), _token(dark, CoreColors.onSurfaceVariant));
      // The scheme actually moved: a theme-blind colour would match light.
      expect(
        _token(dark, CoreColors.successContainer),
        isNot(_token(light, CoreColors.successContainer)),
      );
    });

    testWidgets('the four band fields reach the paint', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(
              addedBackgroundColor: CoreColor.token(CoreColors.infoContainer),
              addedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
              removedBackgroundColor: CoreColor.token(
                CoreColors.warningContainer,
              ),
              removedForegroundColor: CoreColor.token(
                CoreColors.onWarningContainer,
              ),
            ),
          ),
          theme: light,
        ),
      );

      expect(_bandOf(tester, 'added'), _token(light, CoreColors.infoContainer));
      expect(
        _bandOf(tester, 'removed'),
        _token(light, CoreColors.warningContainer),
      );
      expect(_inkOf(tester, '+ '), _token(light, CoreColors.onInfoContainer));
      expect(_inkOf(tester, '3'), _token(light, CoreColors.onInfoContainer));
      expect(
        _inkOf(tester, '- '),
        _token(light, CoreColors.onWarningContainer),
      );
      expect(_inkOf(tester, '2'), _token(light, CoreColors.onWarningContainer));
      // The code is still the body ink, whatever the band states.
      expect(_inkOf(tester, 'added'), _token(light, CoreColors.onSurface));
    });

    testWidgets('lineNumberColor reaches a plain row only', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(
              lineNumberColor: CoreColor.token(CoreColors.primary),
            ),
          ),
          theme: light,
        ),
      );

      expect(_inkOf(tester, '1'), _token(light, CoreColors.primary));
      // A band's number is its own ink, not the plain-row colour.
      expect(_inkOf(tester, '2'), _token(light, CoreColors.onErrorContainer));
      expect(_inkOf(tester, '3'), _token(light, CoreColors.onSuccessContainer));
    });

    testWidgets('the retired fields are inert: nothing they state is painted', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(
              addedColor: CoreColor.token(CoreColors.info),
              removedColor: CoreColor.token(CoreColors.warning),
              rowTintAlpha: 0.3,
              lineNumberAlpha: 0.2,
            ),
          ),
          theme: light,
        ),
      );

      // Same paint as with none of them stated.
      expect(
        _bandOf(tester, 'added'),
        _token(light, CoreColors.successContainer),
      );
      expect(
        _bandOf(tester, 'removed'),
        _token(light, CoreColors.errorContainer),
      );
      expect(
        _inkOf(tester, '+ '),
        _token(light, CoreColors.onSuccessContainer),
      );
      expect(_isOpaque(_inkOf(tester, '1')), isTrue);
    });
  });

  group('CodeDiff painted colours — the block face', () {
    final light = ThemeData.fromCore(CoreThemePresets.light);

    BoxDecoration blockOf(WidgetTester tester) {
      final box = tester.widget<AnimatedContainer>(
        find
            .descendant(
              of: find.byType(CodeDiff),
              matching: find.byType(AnimatedContainer),
            )
            .first,
      );
      return box.decoration! as BoxDecoration;
    }

    testWidgets('the face is surfaceContainerLow', (tester) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      expect(
        blockOf(tester).color,
        _token(light, CoreColors.surfaceContainerLow),
      );
    });

    testWidgets('the block paints no border: width 0 and no visible colour', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const CodeDiff(lines: _kLines), theme: light),
      );

      final border = blockOf(tester).border;
      // No stroke at all, or a stroke of zero width in a transparent colour —
      // never a hairline in a visible colour, which is what a bare width of
      // 0 paints on Flutter.
      if (border != null) {
        expect(border.top.width, 0);
        expect(border.top.color.a, 0);
      }
    });

    testWidgets('a caller who raises the width and states a colour gets a '
        'border', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(
              borderWidth: _kBorderWidth,
              outlineColor: CoreColor.token(CoreColors.outline),
            ),
          ),
          theme: light,
        ),
      );

      final border = blockOf(tester).border! as Border;
      expect(border.top.width, _kBorderWidth);
      expect(border.top.color, _token(light, CoreColors.outline));
    });

    testWidgets('a width alone stays invisible: the transparent colour '
        'collapses it', (tester) async {
      await tester.pumpWidget(
        _buildApp(
          const CodeDiff(
            lines: _kLines,
            codeDiffStyle: CoreCodeDiffStyle(borderWidth: _kBorderWidth),
          ),
          theme: light,
        ),
      );

      final border = blockOf(tester).border;
      if (border != null) {
        expect(border.top.width, 0);
      }
    });
  });

  group('CodeDiff under neo-brutalism — the unboxed block is accepted', () {
    testWidgets('the stroke floor cannot lift a zero: no border is painted', (
      tester,
    ) async {
      // A floor raises a width that is already painted; zero is the absence
      // of a border. So the block stays unboxed under this preset — the
      // accepted outcome, the same one Web draws.
      await tester.pumpWidget(
        CoUIApp(
          theme: ThemeData.fromCore(CoreThemePresets.light),
          surfaceStyle: CoreSurfaceStyleId.neoBrutalism,
          home: const Center(child: CodeDiff(lines: _kLines)),
        ),
      );

      final widths = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: find.byType(CodeDiff),
              matching: find.byType(AnimatedContainer),
            ),
          )
          .map((box) => box.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border?.top.width ?? 0);

      expect(widths, isNotEmpty);
      expect(widths.every((width) => width == 0), isTrue, reason: '$widths');
    });
  });

  group('CodeDiff rendered geometry — reading direction', () {
    Widget directional(TextDirection direction) => _buildApp(
      Directionality(
        textDirection: direction,
        child: const CodeDiff(lines: _kLines),
      ),
    );

    testWidgets('the gap sits on the right in LTR, on the left in RTL', (
      tester,
    ) async {
      await tester.pumpWidget(directional(.ltr));
      final ltrCell = tester.getRect(
        find
            .ancestor(of: find.text('1'), matching: find.byType(SizedBox))
            .first,
      );
      final ltrNumber = tester.getRect(find.text('1'));
      // LTR: the number box starts at the cell's left edge ...
      expect(ltrNumber.left, closeTo(ltrCell.left, 0.01));
      // ... and the 12px gap is what remains on its right.
      expect(ltrCell.right - ltrNumber.right, closeTo(_kGutterGap, 0.01));

      await tester.pumpWidget(directional(.rtl));
      final rtlCell = tester.getRect(
        find
            .ancestor(of: find.text('1'), matching: find.byType(SizedBox))
            .first,
      );
      final rtlNumber = tester.getRect(find.text('1'));
      // RTL: the gap is on the left, the number box ends at the cell edge.
      expect(rtlNumber.left - rtlCell.left, closeTo(_kGutterGap, 0.01));
      expect(rtlCell.right, closeTo(rtlNumber.right, 0.01));
    });

    testWidgets('the number hugs the gap edge (text align end)', (
      tester,
    ) async {
      await tester.pumpWidget(directional(.ltr));
      expect(tester.widget<Text>(find.text('1')).textAlign, TextAlign.end);
    });
  });
}
