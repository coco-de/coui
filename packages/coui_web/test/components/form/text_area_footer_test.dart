// Pins the `TextArea.footer` slot on the web — one line of actions under
// the text, inside the area's box (a chat input's send button).
//
// A footer shares the box with the text, so the box moves off the
// `<textarea>` onto a frame that holds the text row, the gap and the
// footer. These cases read that DOM shape from the server-rendered markup
// (only the SSR binding hands back markup) and the chrome the resolver
// puts on each element: the frame draws the border, fill and padding, the
// `<textarea>` none of them, and the footer stays outside the editing
// surface.

// text_area_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/text_area/text_area_style.dart';
import 'package:coui_web/src/internal/text_area_boundary_paint.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

const _kSendId = 'send';

Component _footer() => const span([Text('Send')], id: _kSendId);

void _pump(ServerTester tester, Component area) =>
    tester.pumpComponent(CoUIWeb(theme: .coui, child: area));

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveTextArea` directly.
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

ResolvedTextArea _resolve(
  BuildContext context, {
  bool hasFooter = false,
  CoreTextAreaStyle? textAreaStyle,
}) => resolveTextArea(
  context,
  size: CoreComponentSize.md,
  expandableHeight: false,
  expandableWidth: false,
  hasError: false,
  obscureText: false,
  obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
  hasFooter: hasFooter,
  textAreaStyle: textAreaStyle,
);

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

void main() {
  group('TextArea footer — DOM shape', () {
    testServer('the footer sits in the box, after the text row and the gap', (
      tester,
    ) async {
      _pump(tester, TextArea(rows: 2, footer: _footer()));
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final textRow = textarea.parent!;
      final frame = textRow.parent!;

      // frame > [text row, gap, footer] — the order the Flutter twin's
      // column lays out.
      expect(frame.children, hasLength(3));
      expect(frame.children[0], same(textRow));
      expect(
        frame.children[1].attributes['style'],
        contains('flex-basis: var(--coui-space-12)'),
      );
      expect(frame.children[2].querySelector('#$_kSendId'), isNotNull);
    });

    testServer('the count sits 12 after the description, at the row end '
        '(#5747)', (tester) async {
      _pump(
        tester,
        const TextArea(description: 'Notes', showCounter: true, maxLength: 20),
      );
      final document = (await tester.request('/')).document!;
      final description = document
          .querySelectorAll('p')
          .singleWhere((e) => e.text == 'Notes');
      final row = description.parent!;

      // row > [description, gap, count] — the Flutter twin's
      // `Row(Expanded(helper), Gap(counterGapStyle), count)`.
      expect(row.children, hasLength(3));
      expect(row.children[0], same(description));
      expect(
        row.children[1].attributes['style'],
        contains('flex-basis: var(--coui-space-12)'),
      );
      expect(row.children[2].text, '0 / 20');
    });

    testServer('the footer is outside the <textarea> — not the editing '
        'surface', (tester) async {
      _pump(tester, TextArea(rows: 2, footer: _footer()));
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final send = document.querySelector('#$_kSendId')!;

      expect(textarea.children, isEmpty);
      expect(textarea.parent!.querySelector('#$_kSendId'), isNull);
      expect(send.parent!.parent, same(textarea.parent!.parent));
    });

    testServer('the frame is the box; the <textarea> draws none of it', (
      tester,
    ) async {
      _pump(tester, TextArea(rows: 2, footer: _footer()));
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final frame = textarea.parent!.parent!;
      final frameStyle = frame.attributes['style']!;
      final textareaStyle = textarea.attributes['style']!;

      expect(frame.className, contains('coui-surface'));
      expect(frameStyle, contains('border-style: solid'));
      // The area's inset is the same on every edge (#5747).
      expect(frameStyle, contains('padding: var(--coui-space-12)'));
      expect(frameStyle, contains('min-height'));

      expect(textarea.className, isNot(contains('coui-surface')));
      expect(textareaStyle, contains('border-width: 0'));
      expect(textareaStyle, contains('padding: 0'));
      expect(textareaStyle, isNot(contains('min-height')));
    });

    testServer('absent when null — the wrapper is the box', (tester) async {
      _pump(tester, const TextArea(rows: 2));
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final wrapper = textarea.parent!;

      expect(document.querySelector('#$_kSendId'), isNull);
      // The box is the wrapper, never the native `<textarea>` (a replaced
      // element cannot carry the box's pseudo-element layers).
      expect(wrapper.className, contains('coui-surface'));
      expect(wrapper.attributes['style'], contains('border-style: solid'));
      expect(textarea.className, isNot(contains('coui-surface')));
      expect(textarea.attributes['style'], contains('border-width: 0'));
      // No text row between the wrapper and the ring wrapper.
      expect(wrapper.className, isNot(contains('grow')));
    });

    testServer('the resize handle anchors to the text row, not the box', (
      tester,
    ) async {
      _pump(tester, TextArea(expandableHeight: true, footer: _footer()));
      final document = (await tester.request('/')).document!;
      final textRow = document.querySelector('textarea')!.parent!;
      final handle = document.querySelector('.pointer-events-none')!;

      // The `<textarea>`'s corner, where the native grip sits — the box's
      // corner is where the footer's trailing action sits.
      expect(handle.parent, same(textRow));
      expect(textRow.className, contains('relative'));
    });

    testServer('a resize callback reads the frame, triggered by the '
        '<textarea>', (tester) async {
      _pump(
        tester,
        TextArea(
          expandableHeight: true,
          onHeightChanged: (_) {},
          footer: _footer(),
        ),
      );
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final frame = textarea.parent!.parent!;

      // The reported border box is the frame's, footer included — the
      // quantity the Flutter twin's `SizedBox` reports.
      expect(frame.id, endsWith('-frame'));
      // The observer watches the `<textarea>`, which only the native grip
      // moves — a footer whose own content grows is not a resize.
      expect(textarea.id, isNotEmpty);
      expect(frame.id, '${textarea.id}-frame');
    });

    testServer('no resize callback — neither element carries an id', (
      tester,
    ) async {
      _pump(tester, TextArea(expandableHeight: true, footer: _footer()));
      final document = (await tester.request('/')).document!;
      final textarea = document.querySelector('textarea')!;
      final frame = textarea.parent!.parent!;

      expect(textarea.id, isEmpty);
      expect(frame.id, isEmpty);
    });
  });

  group('TextArea footer — resolver', () {
    testComponents('footerGapStyle defaults to 12', (tester) async {
      final resolved = _resolve(_themedContext(tester), hasFooter: true);

      expect(
        resolved.footerGapStyle,
        CoreTextAreaStyle.defaultFooterGapStyle,
      );
      expect(resolved.footerGapStyle.size, CoreSpace.space12);
    });

    testComponents('a footerGapStyle override reaches the gap', (
      tester,
    ) async {
      final resolved = _resolve(
        _themedContext(tester),
        hasFooter: true,
        textAreaStyle: const CoreTextAreaStyle(
          footerGapStyle: CoreGapStyle(size: CoreSpace.space16),
        ),
      );

      expect(resolved.footerGapStyle.size, CoreSpace.space16);
    });

    testComponents('footed, the box chrome is on the frame', (tester) async {
      final resolved = _resolve(_themedContext(tester), hasFooter: true);
      final frame = _inline(resolved.frame);
      final textarea = _inline(resolved.textarea);

      expect(frame['padding'], isNotNull);
      expect(frame['min-height'], isNotNull);
      expect(frame['background-color'], isNotNull);
      expect(resolved.frame.className, contains('coui-surface'));

      expect(textarea['padding'], '0');
      expect(textarea['border-width'], '0');
      expect(textarea.containsKey('min-height'), isFalse);
      expect(textarea.containsKey('background-color'), isFalse);
      expect(resolved.textarea.className, isNot(contains('coui-surface')));
    });

    testComponents('footed, the frame keys its focus on the <textarea> '
        'alone — a footer control taking focus leaves the box at rest', (
      tester,
    ) async {
      // A caller who states the wider active boundary (#5747 made the
      // default the resting 1, which adds nothing).
      final resolved = _resolve(
        _themedContext(tester),
        hasFooter: true,
        textAreaStyle: const CoreTextAreaStyle(
          activeBorderWidth: CoreStrokeWidth.stroke1_5,
        ),
      );
      final frameClasses = resolved.frame.className.split(' ');
      const textFocus = '[&:has(>:first-child>textarea:focus-visible)]:';
      final focusRing = CoreTextAreaStyle.defaultNormalVariant.focusRingColor;

      expect(frameClasses, contains('${textFocus}border-$focusRing'));
      expect(
        frameClasses,
        contains(kTextAreaFrameBoundaryMarker),
      );
      expect(
        ThemeConfig.defaults().cssVariables,
        contains(
          '.$kTextAreaFrameBoundaryMarker$kTextAreaFrameFocusSelector{'
          'box-shadow:var($kActiveBoundaryVar);}',
        ),
      );
      expect(
        frameClasses,
        contains(
          '[&:hover:not(:has(>:first-child>textarea:focus-visible))]:'
          'border-${CoreTextAreaStyle.defaultNormalVariant.hoverBorderColor}',
        ),
      );
      // Nothing keyed on `:focus-within`, which a footer control also
      // satisfies.
      expect(
        frameClasses.where((cls) => cls.contains('focus-within')),
        isEmpty,
      );
      expect(frameClasses, isNot(contains(kActiveBoundaryWithinMarker)));
      // The layer the focus class reads is still published inline.
      expect(_inline(resolved.frame)[kActiveBoundaryVar], isNotNull);
    });

    testComponents('affixed without a footer, the wrapper keeps '
        '`:focus-within`', (tester) async {
      final resolved = resolveTextArea(
        _themedContext(tester),
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: false,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
        textAreaStyle: const CoreTextAreaStyle(
          activeBorderWidth: CoreStrokeWidth.stroke1_5,
        ),
      );
      final wrapperClasses = resolved.affixWrapper.className.split(' ');

      expect(
        wrapperClasses,
        contains(
          'focus-within:border-'
          '${CoreTextAreaStyle.defaultNormalVariant.focusRingColor}',
        ),
      );
      expect(wrapperClasses, contains(kActiveBoundaryWithinMarker));
    });

    testComponents('footed and disabled, the frame states the disabled '
        'fill, border and cursor over the whole box', (tester) async {
      final resolved = resolveTextArea(
        _themedContext(tester),
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: false,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
        hasFooter: true,
        enabled: false,
      );
      const variant = CoreTextAreaStyle.defaultNormalVariant;
      final frameClasses = resolved.frame.className.split(' ');
      final textareaClasses = resolved.textarea.className.split(' ');

      expect(
        _inline(resolved.frame)['background-color'],
        variant.disabledBackgroundColor.toValue(),
      );
      expect(frameClasses, contains('border-${variant.disabledBorderColor}'));
      expect(frameClasses, isNot(contains('border-${variant.borderColor}')));
      expect(frameClasses, contains('cursor-not-allowed'));
      // No focus or hover step while disabled — `disabled > focus > hover`.
      expect(frameClasses.where((cls) => cls.startsWith('[&')), isEmpty);
      // The `<textarea>` stays clear, so no tinted block sits inside the
      // frame.
      expect(textareaClasses, contains('bg-transparent'));
      expect(
        textareaClasses.where((cls) => cls.startsWith('disabled:bg-')),
        isEmpty,
      );
    });

    testComponents('footed and disabled, a caller fill and border win', (
      tester,
    ) async {
      const fill = CoreColor.token(CoreColors.surfaceContainer);
      const border = CoreColor.token(CoreColors.outlineVariant);
      final resolved = resolveTextArea(
        _themedContext(tester),
        size: CoreComponentSize.md,
        expandableHeight: false,
        expandableWidth: false,
        hasError: false,
        obscureText: false,
        obscuringCharacter: CoreTextAreaContract.defaultObscuringCharacter,
        hasFooter: true,
        enabled: false,
        textAreaStyle: const CoreTextAreaStyle(
          backgroundColor: fill,
          borderColor: border,
        ),
      );

      expect(_inline(resolved.frame)['background-color'], fill.toValue());
      expect(resolved.frame.className.split(' '), contains('border-$border'));
    });

    testComponents('footed and enabled, the frame keeps the rest fill and '
        'states no cursor', (tester) async {
      final resolved = _resolve(_themedContext(tester), hasFooter: true);

      expect(
        _inline(resolved.frame)['background-color'],
        CoreTextAreaStyle.defaultNormalVariant.backgroundColor.toValue(),
      );
      expect(
        resolved.frame.className.split(' '),
        isNot(contains('cursor-not-allowed')),
      );
    });

    testComponents('unfooted, the wrapper is the box and the <textarea> keeps '
        'the padding and the dimensions', (tester) async {
      final resolved = _resolve(_themedContext(tester));
      final textarea = _inline(resolved.textarea);
      final wrapper = _inline(resolved.affixWrapper);

      expect(textarea['padding'], isNot('0'));
      expect(textarea['min-height'], isNotNull);
      expect(textarea['border-width'], '0');
      expect(wrapper['background-color'], isNotNull);
      expect(wrapper['border-style'], 'solid');
      expect(resolved.affixWrapper.className, contains('coui-surface'));
      expect(resolved.textarea.className, isNot(contains('coui-surface')));
      // The box paints the fill, so the `<textarea>` is clear at rest — a
      // browser field fill would show white inside a dark box — and takes
      // the disabled tint, which fills the wrapper.
      final classes = resolved.textarea.className.split(' ');
      expect(classes, contains('bg-transparent'));
      expect(classes.any((c) => c.startsWith('disabled:bg-')), isTrue);
    });

    testComponents('footed, the <textarea> is clear in every state', (
      tester,
    ) async {
      final resolved = _resolve(_themedContext(tester), hasFooter: true);
      final classes = resolved.textarea.className.split(' ');

      expect(classes, contains('bg-transparent'));
      expect(classes.any((c) => c.startsWith('disabled:bg-')), isFalse);
    });
  });
}
