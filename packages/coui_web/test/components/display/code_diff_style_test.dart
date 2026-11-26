// The cell font sizes and pixel widths under test are the fixture data —
// naming each one would hide the number the assertion is about.

/// Read-back tests for the `CodeDiff` 21px grid and the opaque bands on Web.
///
/// The resolver turns the geometry and colour fields into class names and
/// inline declarations. A field that is declared and merged but never emitted
/// looks finished from the authoring side and changes nothing on screen, so
/// these assert the emitted markup. What the browser makes of that markup — the
/// 21px row, the x = 52 prefix — is measured in a real Chrome by
/// `tool/parity/test/web/code_diff_row_box_probe_test.dart`.
library;

// The retired alpha / colour fields stay declared so apps that state them still
// compile, and one test states them on purpose to pin that nothing they say is
// emitted — so this file names deprecated members deliberately.
// ignore_for_file: deprecated_member_use
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kLines = [
  CoreCodeDiffLine(text: 'unchanged', type: .unchanged, lineNumber: 1),
  CoreCodeDiffLine(text: 'removed', type: .removed, lineNumber: 2),
  CoreCodeDiffLine(text: 'added', type: .added, lineNumber: 3),
];

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

ResolvedCodeDiff _resolve(BuildContext context, {CoreCodeDiffStyle? style}) =>
    resolveCodeDiff(context, lines: _kLines, codeDiffStyle: style);

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles!.properties;

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

/// A colour token as the browser reads it: the CSS variable the theme
/// generator defines for it, drawn as an opaque `rgb(...)`.
String _rgb(String token) => 'rgb(var(--coui-$token))';

ResolvedCodeDiffRow _rowOfType(
  ResolvedCodeDiff resolved,
  CoreCodeDiffLineType type,
) => resolved.rows[_kLines.indexWhere((entry) => entry.type == type)];

void main() {
  group('CodeDiff Web — the 21px row', () {
    testComponents('the row is start-aligned, never baseline-aligned', (
      tester,
    ) async {
      final root = _resolve(_themedContext(tester)).rows.first.root;

      expect(_classes(root), contains('items-start'));
      expect(_classes(root), isNot(contains('items-baseline')));
    });

    testComponents('the row adds no vertical padding, 12 on each side', (
      tester,
    ) async {
      final root = _resolve(_themedContext(tester)).rows.first.root;

      // Top and bottom 0, left and right the 12 step.
      expect(
        _inline(root)['padding'],
        '${spaceCss(0)} ${spaceCss(12)} ${spaceCss(0)} ${spaceCss(12)}',
      );
    });

    testComponents('the row keeps its inset inside its width', (tester) async {
      final root = _resolve(_themedContext(tester)).rows.first.root;

      expect(_inline(root)['box-sizing'], 'border-box');
    });

    testComponents('body cells ride the codeMd role, the gutter codeSm', (
      tester,
    ) async {
      final row = _resolve(_themedContext(tester)).rows.first;

      expect(_classes(row.prefix), contains('text-code-md'));
      expect(_classes(row.text), contains('text-code-md'));
      expect(_classes(row.lineNumber), contains('text-code-sm'));
      // The sans roles are gone from every cell.
      for (final chrome in [row.prefix, row.text, row.lineNumber]) {
        expect(chrome.className, isNot(contains('text-body-small')));
        expect(chrome.className, isNot(contains('text-label-small')));
      }
    });
  });

  group('CodeDiff Web — the x = 52 gutter', () {
    testComponents('the cell is 40 wide and border-box', (tester) async {
      final gutter = _resolve(_themedContext(tester)).rows.first.lineNumber;

      expect(_inline(gutter)['width'], '2.5rem');
      expect(_inline(gutter)['box-sizing'], 'border-box');
    });

    testComponents('the 12 gap is a logical end padding, nothing vertical', (
      tester,
    ) async {
      final gutter = _inline(
        _resolve(_themedContext(tester)).rows.first.lineNumber,
      );

      expect(gutter['padding-inline-end'], spaceCss(12));
      expect(gutter['padding-inline-start'], spaceCss(0));
      expect(gutter['padding-block-start'], spaceCss(0));
      expect(gutter['padding-block-end'], spaceCss(0));
      // The physical shorthand would put the gap on the wrong edge in RTL.
      expect(gutter.containsKey('padding'), isFalse);
    });

    testComponents('the number aligns to the end edge, not the right', (
      tester,
    ) async {
      final gutter = _resolve(_themedContext(tester)).rows.first.lineNumber;

      expect(_classes(gutter), contains('text-end'));
      expect(_classes(gutter), isNot(contains('text-right')));
    });

    testComponents('a symmetric override still emits the one-line shorthand', (
      tester,
    ) async {
      final gutter = _inline(
        _resolve(
          _themedContext(tester),
          style: const CoreCodeDiffStyle(
            lineNumberPadding: CoreEdgeInsets.symmetric(horizontal: 4),
          ),
        ).rows.first.lineNumber,
      );

      expect(gutter['padding'], isNotNull);
      expect(gutter.containsKey('padding-inline-end'), isFalse);
    });

    testComponents('the width override reaches the cell as a rem length', (
      tester,
    ) async {
      final gutter = _inline(
        _resolve(
          _themedContext(tester),
          style: const CoreCodeDiffStyle(lineNumberWidth: 64),
        ).rows.first.lineNumber,
      );

      expect(gutter['width'], '4.0rem');
    });
  });

  group('CodeDiff Web — opaque bands', () {
    testComponents('an added / removed row is a solid container band', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));

      expect(
        _inline(_rowOfType(resolved, .added).root)['background-color'],
        _rgb('success-container'),
      );
      expect(
        _inline(_rowOfType(resolved, .removed).root)['background-color'],
        _rgb('error-container'),
      );
      // No alpha anywhere in the band: it is the token, not a tint of it.
      for (final type in [
        CoreCodeDiffLineType.added,
        CoreCodeDiffLineType.removed,
      ]) {
        final band = _inline(
          _rowOfType(resolved, type).root,
        )['background-color'];
        expect(band, isNot(contains('/')));
        expect(band, isNot(contains('opacity')));
      }
    });

    testComponents('an unchanged row has no band', (tester) async {
      final resolved = _resolve(_themedContext(tester));

      expect(
        _inline(_rowOfType(resolved, .unchanged).root)['background-color'],
        'transparent',
      );
    });

    testComponents('the prefix wears the ink of the band it sits on', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));

      expect(
        _inline(_rowOfType(resolved, .added).prefix)['color'],
        _rgb('on-success-container'),
      );
      expect(
        _inline(_rowOfType(resolved, .removed).prefix)['color'],
        _rgb('on-error-container'),
      );
      // An unchanged row has no band: its blank prefix keeps the body ink.
      expect(
        _inline(_rowOfType(resolved, .unchanged).prefix)['color'],
        _rgb('on-surface'),
      );
    });

    testComponents('the code keeps the body ink on every row', (tester) async {
      final resolved = _resolve(_themedContext(tester));

      for (final type in CoreCodeDiffLineType.values) {
        expect(
          _inline(_rowOfType(resolved, type).text)['color'],
          _rgb('on-surface'),
          reason: '$type text ink',
        );
      }
    });

    testComponents('the gutter number is per row type, opaque, never dimmed', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));

      expect(
        _inline(_rowOfType(resolved, .added).lineNumber)['color'],
        _rgb('on-success-container'),
      );
      expect(
        _inline(_rowOfType(resolved, .removed).lineNumber)['color'],
        _rgb('on-error-container'),
      );
      expect(
        _inline(_rowOfType(resolved, .unchanged).lineNumber)['color'],
        _rgb('on-surface-variant'),
      );
      for (final type in CoreCodeDiffLineType.values) {
        final colour = _inline(_rowOfType(resolved, type).lineNumber)['color'];
        expect(colour, isNot(contains('/')), reason: '$type gutter alpha');
      }
    });

    testComponents('the four band fields reach the emitted CSS', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeDiffStyle(
          addedBackgroundColor: CoreColor.token(CoreColors.infoContainer),
          addedForegroundColor: CoreColor.token(CoreColors.onInfoContainer),
          removedBackgroundColor: CoreColor.token(CoreColors.warningContainer),
          removedForegroundColor: CoreColor.token(
            CoreColors.onWarningContainer,
          ),
        ),
      );
      final added = _rowOfType(resolved, .added);
      final removed = _rowOfType(resolved, .removed);

      expect(_inline(added.root)['background-color'], _rgb('info-container'));
      expect(_inline(added.prefix)['color'], _rgb('on-info-container'));
      expect(_inline(added.lineNumber)['color'], _rgb('on-info-container'));
      expect(
        _inline(removed.root)['background-color'],
        _rgb('warning-container'),
      );
      expect(_inline(removed.prefix)['color'], _rgb('on-warning-container'));
      expect(
        _inline(removed.lineNumber)['color'],
        _rgb('on-warning-container'),
      );
      // The code is still the body ink, whatever the band states.
      expect(_inline(added.text)['color'], _rgb('on-surface'));
    });

    testComponents('lineNumberColor reaches a plain row only', (tester) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeDiffStyle(
          lineNumberColor: CoreColor.token(CoreColors.primary),
        ),
      );

      expect(
        _inline(_rowOfType(resolved, .unchanged).lineNumber)['color'],
        _rgb('primary'),
      );
      expect(
        _inline(_rowOfType(resolved, .added).lineNumber)['color'],
        _rgb('on-success-container'),
      );
    });

    testComponents('the retired fields are inert: nothing they state is '
        'emitted', (tester) async {
      final retired = _resolve(
        _themedContext(tester),
        style: const CoreCodeDiffStyle(
          addedColor: CoreColor.token(CoreColors.info),
          removedColor: CoreColor.token(CoreColors.warning),
          rowTintAlpha: 0.3,
          lineNumberAlpha: 0.2,
        ),
      );
      final plain = _resolve(_themedContext(tester));

      for (final type in CoreCodeDiffLineType.values) {
        final a = _rowOfType(retired, type);
        final b = _rowOfType(plain, type);
        expect(_inline(a.root), _inline(b.root), reason: '$type row');
        expect(_inline(a.lineNumber), _inline(b.lineNumber), reason: '$type');
        expect(_inline(a.prefix), _inline(b.prefix), reason: '$type prefix');
        expect(_inline(a.text), _inline(b.text), reason: '$type text');
      }
    });
  });

  group('CodeDiff Web — the block face', () {
    testComponents('the face is surfaceContainerLow', (tester) async {
      final style = _resolve(_themedContext(tester)).containerStyle;

      expect(
        style.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    testComponents('the block states no border: zero width, transparent', (
      tester,
    ) async {
      final style = _resolve(_themedContext(tester)).containerStyle;

      expect(style.borderWidth, CoreStrokeWidth.stroke0);
      expect(style.borderColor, CoreColor.transparent);
    });

    testComponents('a raised width with a stated colour reaches the box', (
      tester,
    ) async {
      final style = _resolve(
        _themedContext(tester),
        style: const CoreCodeDiffStyle(
          borderWidth: CoreStrokeWidth.stroke2,
          outlineColor: CoreColor.token(CoreColors.outline),
        ),
      ).containerStyle;

      expect(style.borderWidth, CoreStrokeWidth.stroke2);
      expect(style.borderColor, const CoreColor.token(CoreColors.outline));
    });
  });

  group('CodeDiff Web — the outer corner', () {
    testComponents('the container corner is the 12 panel role', (tester) async {
      final style = _resolve(_themedContext(tester)).containerStyle;

      expect(
        style.borderRadius,
        const CoreBorderRadius.all(CoreRadiusRole.panel),
      );
    });
  });
}
