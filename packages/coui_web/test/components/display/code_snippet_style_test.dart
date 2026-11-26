// The cap values under test are the fixture data — naming each one would hide
// the number the assertion is about.

/// Read-back tests for `CodeSnippet` on Web: the emitted geometry, the code
/// role, the colours (the quiet face, the borderless pair, the code ink, the
/// gutter ink and the copy glyph, which states none) and the code-area size
/// caps.
///
/// The four caps (`minWidth` / `maxWidth` / `minHeight` / `maxHeight`)
/// replaced a Flutter-only `constraints: BoxConstraints?` widget parameter.
/// A field that is declared, merged and compared but never emitted looks
/// finished from the authoring side and changes nothing on screen, so these
/// assert the emitted CSS rather than the field's presence.
library;

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

ResolvedCodeSnippet _resolve(
  BuildContext context, {
  CoreCodeSnippetStyle? style,
}) => resolveCodeSnippet(
  context,
  lineCount: 3,
  codeSnippetStyle: style,
);

/// The `<pre>` scroll wrapper's inline CSS, rendered to a single string so
/// assertions read the declarations the browser will actually receive.
String _preCss(ResolvedCodeSnippet resolved) => resolved
    .pre
    .inlineStyles!
    .properties
    .entries
    .map((e) => '${e.key}: ${e.value}')
    .join('; ');

/// Any chrome slot's inline CSS as one `prop: value; …` string — `''` when
/// the slot emits no inline CSS at all.
String _css(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties.entries
        .map((e) => '${e.key}: ${e.value}')
        .join('; ') ??
    '';

void main() {
  group('CodeSnippet defaults — emitted geometry', () {
    testComponents('the corner is radius8 on the composed container', (
      tester,
    ) async {
      final container = _resolve(_themedContext(tester)).containerStyle;
      expect(container.borderRadius, const CoreBorderRadius.all(8));
      // The container's own resolver turns the radius into its CSS; here the
      // resolver's job is to hand it the 8, not the old 16.
      expect(
        container.borderRadius,
        isNot(const CoreBorderRadius.all(CoreRadius.radius16)),
      );
    });

    testComponents('the padding is 10 vertical and 12 horizontal, inline', (
      tester,
    ) async {
      // `top right bottom left` — the shorthand reads back as the two steps.
      expect(
        _css(_resolve(_themedContext(tester)).pre),
        contains(
          'padding: var(--coui-space-10) var(--coui-space-12) '
          'var(--coui-space-10) var(--coui-space-12)',
        ),
      );
    });

    testComponents('a stated padding replaces the default shorthand', (
      tester,
    ) async {
      final css = _css(
        _resolve(
          _themedContext(tester),
          style: const CoreCodeSnippetStyle(
            padding: CoreEdgeInsets.all(CoreSpace.space24),
          ),
        ).pre,
      );
      expect(
        css,
        contains(
          'padding: var(--coui-space-24) var(--coui-space-24) '
          'var(--coui-space-24) var(--coui-space-24)',
        ),
      );
      expect(css, isNot(contains('--coui-space-10')));
    });

    testComponents('the gutter gap is space12', (tester) async {
      final gutter = _resolve(_themedContext(tester)).lineNumber;
      expect(gutter.inlineStyles!.properties['margin-right'], spaceCss(12));
      expect(
        gutter.inlineStyles!.properties['margin-right'],
        'var(--coui-space-12)',
      );
    });

    testComponents('the copy button sits at space6 from the top and right', (
      tester,
    ) async {
      // Pinned, not density-moved: it positions against the block's corner.
      final actions = _resolve(_themedContext(tester)).actionWrapper;
      expect(actions.inlineStyles!.properties['top'], pinnedLengthCss(6));
      expect(actions.inlineStyles!.properties['right'], pinnedLengthCss(6));
      expect(actions.inlineStyles!.properties['top'], '0.375rem');
    });
  });

  group('CodeSnippet defaults — colour', () {
    testComponents('the face is surfaceContainerLow', (tester) async {
      expect(
        _resolve(_themedContext(tester)).containerStyle.backgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
    });

    testComponents('the block has no border: transparent colour, width 0', (
      tester,
    ) async {
      final container = _resolve(_themedContext(tester)).containerStyle;
      expect(container.borderColor, CoreColor.transparent);
      expect(container.borderWidth, 0);
    });

    testComponents('the code ink is the onSurface class on the wrapper', (
      tester,
    ) async {
      final wrapper = _resolve(_themedContext(tester)).contentWrapper;
      expect(wrapper.className.split(' '), contains('text-on-surface'));
      expect(_css(wrapper), isNot(contains('color')));
    });

    testComponents('a restated code colour goes inline and drops the class', (
      tester,
    ) async {
      final wrapper = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      ).contentWrapper;
      expect(wrapper.className.split(' '), isNot(contains('text-on-surface')));
      expect(_css(wrapper), contains('color: rgb(var(--coui-on-primary))'));
    });

    testComponents('the gutter ink is the onSurfaceVariant class, opaque', (
      tester,
    ) async {
      final gutter = _resolve(_themedContext(tester)).lineNumber;
      expect(
        gutter.className.split(' '),
        contains('text-on-surface-variant'),
      );
      // A token colour rides the class: nothing inline, so no alpha either.
      expect(gutter.inlineStyles!.properties, isNot(contains('color')));
      expect(gutter.className, isNot(contains('/')));
    });

    testComponents('the gutter does not follow a restated code colour', (
      tester,
    ) async {
      final gutter = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      ).lineNumber;
      expect(
        gutter.className.split(' '),
        contains('text-on-surface-variant'),
      );
      expect(_css(gutter), isNot(contains('on-primary')));
    });

    testComponents('a stated gutter token replaces the class', (tester) async {
      final gutter = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          lineNumberTextStyle: CoreTextStyle(
            color: CoreColor.token(CoreColors.primary),
          ),
        ),
      ).lineNumber;
      expect(gutter.className.split(' '), contains('text-primary'));
      expect(
        gutter.className.split(' '),
        isNot(contains('text-on-surface-variant')),
      );
      expect(gutter.inlineStyles!.properties, isNot(contains('color')));
    });

    testComponents('a stated raw gutter colour goes inline, once', (
      tester,
    ) async {
      final gutter = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          lineNumberTextStyle: CoreTextStyle(color: CoreColor(0xFF336699)),
        ),
      ).lineNumber;
      expect(gutter.className, isNot(contains('text-on-surface-variant')));
      expect(
        gutter.inlineStyles!.properties['color'],
        const CoreColor(0xFF336699).toValue(),
      );
    });

    testComponents('the copy glyph states a size and no colour', (
      tester,
    ) async {
      final icon = _resolve(_themedContext(tester)).iconStyle;
      expect(icon.color, isNull);
      expect(icon.size, CoreIconSize.size16);
    });

    testComponents('a glyph colour stated on the instance is forwarded', (
      tester,
    ) async {
      final icon = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          copyIconStyle: CoreIconStyle(
            color: CoreColor.token(CoreColors.onPrimary),
          ),
        ),
      ).iconStyle;
      expect(icon.color, const CoreColor.token(CoreColors.onPrimary));
      expect(icon.size, CoreIconSize.size16);
    });

    testComponents('the copy button states no ring of its own', (tester) async {
      expect(
        _resolve(_themedContext(tester)).copyButtonStyle.focusOutlineStyle,
        isNull,
      );
    });

    testComponents('each syntax role resolves to its slot, as a variable', (
      tester,
    ) async {
      final syntax = _resolve(_themedContext(tester)).syntax;
      expect(syntax, hasLength(CoreSyntaxRole.values.length));
      for (final role in CoreSyntaxRole.values) {
        final chrome = syntax[role.index];
        final token = role.token;
        if (token == null) {
          // Plain text inherits the code colour: nothing to state.
          expect(chrome.className, isEmpty);
          expect(chrome.inlineStyles, isNull);
          continue;
        }
        expect(
          chrome.inlineStyles!.properties['color'],
          'rgb(var(--coui-${token.name}))',
          reason: role.name,
        );
        expect(chrome.className, isEmpty, reason: role.name);
      }
      expect(
        syntax[CoreSyntaxRole.keyword.index].inlineStyles!.properties['color'],
        'rgb(var(--coui-syntax-keyword))',
      );
    });
  });

  group('CodeSnippet defaults — code role', () {
    testComponents('the wrapper, <pre> and <code> carry the code-sm class', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester));
      for (final chrome in [
        resolved.contentWrapper,
        resolved.pre,
        resolved.code,
      ]) {
        expect(chrome.className.split(' '), contains('text-code-sm'));
        expect(chrome.className, isNot(contains('text-body-small')));
      }
    });

    testComponents('a pure role emits no typography inline CSS', (
      tester,
    ) async {
      // The role's size, box and family ride its class; any inline here would
      // be a caller overlay that nobody stated.
      final resolved = _resolve(_themedContext(tester));
      expect(resolved.code.inlineStyles, isNull);
      expect(resolved.contentWrapper.inlineStyles, isNull);
      final css = _css(resolved.pre);
      expect(css, isNot(contains('font-size')));
      expect(css, isNot(contains('line-height')));
      expect(css, isNot(contains('font-family')));
      expect(css, isNot(contains('letter-spacing')));
    });

    testComponents('the gutter takes size and box from the code element', (
      tester,
    ) async {
      // The gutter states no typography of its own, so it inherits the
      // `<code>` element's — the same codeSm size and 21px box — and the rows
      // line up with the code lines.
      final css = _css(_resolve(_themedContext(tester)).lineNumber);
      expect(css, isNot(contains('font-size')));
      expect(css, isNot(contains('line-height')));
    });

    test('the class resolves to 12px, a 21px box and the mono face', () {
      final variables = CssVariableGenerator.typographyVars(.coui);
      expect(variables['--coui-text-code-sm-size'], '0.75rem');
      // 21 / 16 — a rem length, so the box follows the browser's text size.
      expect(variables['--coui-text-code-sm-line-height'], '1.3125rem');
      expect(variables['--coui-text-code-sm-family'], isNotNull);
      expect(
        ThemeConfig.typographyCssBlock(.coui),
        contains(':where(.text-code-sm)'),
      );
    });

    testComponents('a code role stated by the caller replaces the class', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTypography: CoreTextStyle.token(CoreTextStyles.codeMd),
        ),
      );
      expect(resolved.code.className.split(' '), contains('text-code-md'));
      expect(resolved.pre.className.split(' '), contains('text-code-md'));
      expect(resolved.code.className, isNot(contains('text-code-sm')));
    });

    testComponents('a size stated on the role goes inline beside the class', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTypography: CoreTextStyle(fontSize: CoreFontSize.s14),
        ),
      );
      // Every element that carries the role class carries the overlay, so
      // their struts agree.
      for (final chrome in [
        resolved.contentWrapper,
        resolved.pre,
        resolved.code,
      ]) {
        expect(chrome.className.split(' '), contains('text-code-sm'));
        expect(_css(chrome), contains('font-size: 0.875rem'));
      }
    });

    testComponents('a raw scale role from a caller no longer throws', (
      tester,
    ) async {
      // The previous spelling read the role by identity and threw for
      // anything that was not an exact `CoreTypography.coui.X`; the emit
      // family takes any style.
      final resolved = _resolve(
        _themedContext(tester),
        style: CoreCodeSnippetStyle(
          codeTypography: CoreTypography.coui.codeMd,
        ),
      );
      expect(resolved.code.className.split(' '), contains('text-code-sm'));
      expect(_css(resolved.code), contains('font-size: 0.8125rem'));
    });

    testComponents('a code text-style box still wins over the role box', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(lineHeight: CoreLineHeight.h140),
        ),
      );
      expect(resolved.code.className.split(' '), contains('text-code-sm'));
      expect(
        resolved.code.inlineStyles!.properties['line-height'],
        CssVariableGenerator.lineHeightCss(CoreLineHeight.h140),
      );
    });
  });

  // The Flutter twin draws the code in the framework's `SelectableText`,
  // which lays it out the cursor width plus the caret gap wider than the
  // glyphs. The `<pre>` keeps that room after the code, past its own end
  // padding, so the code area is as wide on both platforms.
  group('CodeSnippet caret room', () {
    testComponents('the end padding carries the 3px after the code', (
      tester,
    ) async {
      final pre = _resolve(_themedContext(tester)).pre.inlineStyles!;
      expect(
        pre.properties['padding-inline-end'],
        'calc(var(--coui-space-12) + 0.1875rem)',
      );
    });
  });

  group('CodeSnippet code-area caps — unset (default markup)', () {
    testComponents('no cap emits no min/max declaration', (tester) async {
      final css = _preCss(_resolve(_themedContext(tester)));
      expect(css, isNot(contains('min-width')));
      expect(css, isNot(contains('max-width')));
      expect(css, isNot(contains('min-height')));
      expect(css, isNot(contains('max-height')));
    });

    testComponents('no height cap leaves overflow-y alone', (tester) async {
      expect(
        _preCss(_resolve(_themedContext(tester))),
        isNot(contains('overflow-y')),
      );
    });
  });

  group('CodeSnippet code-area caps — set', () {
    testComponents('each cap reaches the <pre> wrapper as a rem length', (
      tester,
    ) async {
      final css = _preCss(
        _resolve(
          _themedContext(tester),
          // 16 logical px per rem, so these read back as whole rem values —
          // an arithmetic slip would surface as the wrong number, not as a
          // missing declaration.
          style: const CoreCodeSnippetStyle(
            minWidth: 160,
            maxWidth: 640,
            minHeight: 32,
            maxHeight: 320,
          ),
        ),
      );
      expect(css, contains('min-width: 10.0rem'));
      expect(css, contains('max-width: 40.0rem'));
      expect(css, contains('min-height: 2.0rem'));
      expect(css, contains('max-height: 20.0rem'));
    });

    testComponents('a height cap brings vertical scrolling with it', (
      tester,
    ) async {
      // Without this the clamped area would spill instead of scrolling,
      // diverging from the Flutter twin's enclosing SingleChildScrollView.
      final css = _preCss(
        _resolve(
          _themedContext(tester),
          style: const CoreCodeSnippetStyle(maxHeight: 320),
        ),
      );
      expect(css, contains('overflow-y: auto'));
    });

    testComponents('a width-only cap does not add vertical scrolling', (
      tester,
    ) async {
      final css = _preCss(
        _resolve(
          _themedContext(tester),
          style: const CoreCodeSnippetStyle(maxWidth: 640),
        ),
      );
      expect(css, contains('max-width: 40.0rem'));
      expect(css, isNot(contains('overflow-y')));
    });

    testComponents('a per-instance cap wins over the theme-level one', (
      tester,
    ) async {
      // Proves the caps ride the same merge chain as the rest of the style
      // rather than being read straight off the widget.
      const themeStyle = CoreCodeSnippetStyle(maxHeight: 160);
      const instanceStyle = CoreCodeSnippetStyle(maxHeight: 320);
      expect(
        const CoreCodeSnippetStyle()
            .merge(themeStyle)
            .merge(instanceStyle)
            .maxHeight,
        320,
      );
    });
  });

  group('CodeSnippet text-style line box', () {
    // A fixed box on the code or gutter text is exactly where a caller
    // puts code on the shared line grid; dropping it would leave the two
    // columns on different lines on Web only.
    testComponents('a stated box reaches the code as a rem length', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(
            lineHeight: CoreLineHeight.h140,
            lineHeightPx: CoreLineBox.px21,
          ),
          lineNumberTextStyle: CoreTextStyle(lineHeightPx: CoreLineBox.px21),
        ),
      );
      // The box Flutter lays the line out in — the rem box, on a whole
      // pixel.
      expect(
        resolved.code.inlineStyles!.properties['line-height'],
        CssVariableGenerator.roundToPixelCss('1.3125rem'),
      );
      expect(
        resolved.lineNumber.inlineStyles!.properties['line-height'],
        CssVariableGenerator.roundToPixelCss('1.3125rem'),
      );
    });

    // A multiplier draws the box it makes at the element's own size, on a
    // whole pixel as Flutter lays the line out, and hands the multiplier to
    // the text below it.
    testComponents('a multiplier alone draws its box and hands it down', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        style: const CoreCodeSnippetStyle(
          codeTextStyle: CoreTextStyle(lineHeight: CoreLineHeight.h140),
        ),
      );
      final code = resolved.code.inlineStyles!.properties;
      expect(
        code['line-height'],
        CssVariableGenerator.lineHeightCss(CoreLineHeight.h140),
      );
      expect(code[CssVariableGenerator.leadingVar], '${CoreLineHeight.h140}');
    });
  });
}
