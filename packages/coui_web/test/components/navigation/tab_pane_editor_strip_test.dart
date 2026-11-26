// The `TabPane` editorStrip row's values, read off what the resolver emits
// and what the widget puts on the DOM: the 36 px strip whose chips fill it,
// the directional chip padding, the `codeSm` label, the bottom line and its
// colour, the strip band, the rule between tabs, the indicator bar, and the
// tab focus ring drawn inside its box.
import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/infra/clickable/clickable_style.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane.dart';
import 'package:coui_web/src/components/navigation/tabs/tab_pane_style.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// A raw colour, so a line that reads it can only have come from the stated
/// `borderColor`.
const _kLine = CoreColor(0xFFFF0000);

/// What the line emits for a token or colour [color] of [width] stroke.
String _line(String color, {String width = 'var(--coui-stroke-width-1)'}) =>
    'inset 0 calc($width * -1) 0 $color';

ResolvedTabPane _resolved(
  ComponentTester tester, {
  CoreTabPaneVariant variant = CoreTabPaneVariant.editorStrip,
  CoreTabPaneStyle? style,
  List<TabPaneTabState> states = const [
    TabPaneTabState(focused: true, enabled: true),
    TabPaneTabState(focused: false, enabled: true),
  ],
}) {
  late ResolvedTabPane out;
  pumpWithTheme(
    tester,
    Builder(
      builder: (context) {
        out = resolveTabPane(
          context,
          tabs: states,
          variant: variant,
          tabPaneStyle: style,
        );
        return const Component.text('ok');
      },
    ),
  );
  return out;
}

ResolvedTabPaneRules _rules(
  ComponentTester tester, {
  CoreTabPaneVariant variant = CoreTabPaneVariant.editorStrip,
  CoreTabPaneStyle? style,
}) {
  late ResolvedTabPaneRules out;
  pumpWithTheme(
    tester,
    Builder(
      builder: (context) {
        out = resolveTabPaneRules(
          context,
          variant: variant,
          tabPaneStyle: style,
        );
        return const Component.text('ok');
      },
    ),
  );
  return out;
}

/// The forced-colours rule for an indicator bar of [width] — what the
/// resolver is expected to write, spelled out once so a drift in any
/// declaration shows up as a diff against this string.
String _forcedBar(
  String scopeClass, {
  required String width,
  String edge = 'top:0;',
}) => [
  '@media (forced-colors:active){',
  '.$scopeClass{position:relative;}',
  '.$scopeClass::before{content:"";position:absolute;',
  '${edge}left:0;right:0;height:0;pointer-events:none;',
  'border-top:$width solid Highlight;}',
  '}',
].join();

void main() {
  group('TabPane editorStrip row', () {
    DomComponent domWhere(bool Function(DomComponent c) test) => find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .firstWhere(test);

    Map<String, String> inline(DomComponent c) =>
        c.styles?.properties ?? const {};

    List<String> classesOf(DomComponent c) => (c.classes ?? '').split(' ');

    void pumpStrip(ComponentTester tester, {CoreTabPaneStyle? style}) =>
        pumpWithTheme(
          tester,
          TabPane(
            variant: .editorStrip,
            tabs: [
              CoreTabItem<Component>(label: 'main.dart', onClose: () {}),
              const CoreTabItem<Component>(label: 'pubspec.yaml'),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
            tabPaneStyle: style,
          ),
        );

    group('36 px strip, chips fill it', () {
      testComponents('the bar is 2.25rem; boxed is 2.75rem', (tester) async {
        final strip = _resolved(tester);
        expect(
          strip.bar.inlineStyles?.properties['height'],
          '${CoreSize.size36 / kRemDivisor}rem',
        );

        final boxed = _resolved(tester, variant: .boxed);
        expect(
          boxed.bar.inlineStyles?.properties['height'],
          '${CoreSize.size44 / kRemDivisor}rem',
        );
      });

      testComponents('the bar stretches its tabs, boxed too', (tester) async {
        final strip = _resolved(tester);
        expect(
          strip.bar.className.split(' '),
          contains(WebLayout.itemsStretch),
        );
        expect(
          strip.bar.className.split(' '),
          isNot(contains(WebLayout.itemsEnd)),
        );

        final boxed = _resolved(tester, variant: .boxed);
        expect(
          boxed.bar.className.split(' '),
          contains(WebLayout.itemsStretch),
        );
        expect(
          boxed.bar.className.split(' '),
          isNot(contains(WebLayout.itemsEnd)),
        );
      });

      testComponents('each tab wrapper is a flex box and each chip '
          'self-stretches, so the chip is as tall as the bar', (tester) async {
        final strip = _resolved(tester);
        for (final wrapper in strip.tabWrappers) {
          expect(wrapper.className.split(' '), contains(WebLayout.flex));
        }
        for (final chip in strip.tabs) {
          expect(chip.className.split(' '), contains(WebLayout.selfStretch));
          // …and the label / close × stay centred inside it.
          expect(chip.className.split(' '), contains(WebLayout.itemsCenter));
        }

        final boxed = _resolved(tester, variant: .boxed);
        for (final wrapper in boxed.tabWrappers) {
          expect(wrapper.className.split(' '), contains(WebLayout.flex));
        }
        for (final chip in boxed.tabs) {
          expect(chip.className.split(' '), contains(WebLayout.selfStretch));
        }
      });

      testComponents('the select region stretches with the chip, so the '
          'whole chip height selects', (tester) async {
        final strip = _resolved(tester);
        for (final select in strip.tabSelects) {
          expect(select.className, WebLayout.selfStretch);
        }
        expect(_resolved(tester, variant: .boxed).tabSelects.length, 2);
        for (final select in _resolved(tester, variant: .boxed).tabSelects) {
          expect(select.className, WebLayout.selfStretch);
        }

        // …and the class reaches the select `Clickable` in the DOM.
        pumpStrip(tester);
        final selects = find.byComponentPredicate(
          (c) => c is Clickable && c.userAttributes?['role'] == 'tab',
        );
        expect(selects.evaluate(), hasLength(2));
        for (final element in selects.evaluate()) {
          expect(
            ((element.component as Clickable).classes ?? '').split(' '),
            contains(WebLayout.selfStretch),
          );
        }
      });

      testComponents('the close × is not a stretch child of the chip', (
        tester,
      ) async {
        pumpStrip(tester);

        // The chip centres its children (`items-center`); the Button is a
        // direct child with no stretch class of its own, so it keeps its
        // own size and sits in the middle of the strip.
        final chip = domWhere(
          (c) =>
              c.tag == 'span' &&
              classesOf(c).contains(WebLayout.selfStretch) &&
              classesOf(c).contains(WebLayout.itemsCenter),
        );
        expect(classesOf(chip), contains(WebLayout.itemsCenter));
        final close = find.byType(Button).evaluate().single.component as Button;
        expect(
          (close.classes ?? '').split(' '),
          isNot(contains(WebLayout.selfStretch)),
        );
        expect(
          find.descendant(of: find.byType(Button), matching: find.byType(Icon)),
          findsOneComponent,
        );
      });
    });

    group('chip padding is directional start 12 / end 8', () {
      testComponents('emitted as logical longhands, never the shorthand', (
        tester,
      ) async {
        final strip = _resolved(tester);

        for (final chip in strip.tabs) {
          final styles = chip.inlineStyles!.properties;
          expect(styles['padding-inline-start'], spaceCss(CoreSpace.space12));
          expect(styles['padding-inline-end'], spaceCss(CoreSpace.space8));
          expect(styles['padding-block-start'], spaceCss(0));
          expect(styles['padding-block-end'], spaceCss(0));
          expect(styles.containsKey('padding'), isFalse);
        }
      });

      testComponents('boxed keeps the one-line symmetric shorthand', (
        tester,
      ) async {
        final boxed = _resolved(tester, variant: .boxed);

        for (final chip in boxed.tabs) {
          final styles = chip.inlineStyles!.properties;
          expect(
            styles['padding'],
            CoreTabPaneStyle.boxed.tabPadding!.toValue(),
          );
          expect(styles.containsKey('padding-inline-start'), isFalse);
        }
      });

      testComponents('the padded chip holds the label, the trailing slot and '
          'the close ×', (tester) async {
        pumpStrip(tester);

        final chips = find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              c.tag == 'span' &&
              (c.styles?.properties ?? const {}).containsKey(
                'padding-inline-start',
              ),
        );
        expect(chips.evaluate(), hasLength(2));
        expect(
          find.descendant(
            of: chips.first,
            matching: find.byType(Button),
          ),
          findsOneComponent,
        );
      });
    });

    group('label is codeSm', () {
      testComponents('the chip carries the code-sm role, not body-medium', (
        tester,
      ) async {
        final strip = _resolved(tester);

        for (final chip in strip.tabs) {
          final classes = chip.className.split(' ');
          expect(classes, contains('text-code-sm'));
          expect(classes, isNot(contains('text-body-medium')));
          // A pure role: the family, size and 21 px line box ride the
          // class, so nothing is overlaid inline.
          final styles = chip.inlineStyles!.properties;
          expect(styles.containsKey('font-size'), isFalse);
          expect(styles.containsKey('line-height'), isFalse);
          expect(styles.containsKey('font-family'), isFalse);
        }
      });

      testComponents('boxed states label-large', (tester) async {
        final boxed = _resolved(tester, variant: .boxed);

        for (final chip in boxed.tabs) {
          expect(chip.className.split(' '), contains('text-label-large'));
          expect(
            chip.className.split(' '),
            isNot(contains('text-body-medium')),
          );
        }
      });

      testComponents('a per-instance contentTextStyle still wins over the '
          'row', (tester) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(
            contentTextStyle: CoreTextStyle.token(CoreTextStyles.labelLarge),
          ),
        );

        for (final chip in strip.tabs) {
          final classes = chip.className.split(' ');
          expect(classes, contains('text-label-large'));
          expect(classes, isNot(contains('text-code-sm')));
        }
      });
    });

    group('bottom line', () {
      testComponents('the row states stroke1 in outlineVariant: the bar emits '
          'the line, inside its own height', (tester) async {
        final strip = _resolved(tester);

        expect(
          strip.bar.inlineStyles?.properties['box-shadow'],
          _line('rgb(var(--coui-outline-variant))'),
        );
        // The line takes no layout height.
        expect(
          strip.bar.inlineStyles?.properties['height'],
          '${CoreSize.size36 / kRemDivisor}rem',
        );

        pumpStrip(tester);
        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(
          inline(bar)['box-shadow'],
          _line('rgb(var(--coui-outline-variant))'),
        );
      });

      testComponents('a transparent borderColor override emits no line', (
        tester,
      ) async {
        const style = CoreTabPaneStyle(borderColor: CoreColor.transparent);
        final strip = _resolved(tester, style: style);

        expect(
          strip.bar.inlineStyles?.properties.containsKey('box-shadow'),
          isFalse,
        );
        pumpStrip(tester, style: style);
        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(inline(bar).containsKey('box-shadow'), isFalse);
      });

      testComponents('the line is drawn on the bar under the chips and is '
          "covered only by the focused chip's surface", (tester) async {
        final strip = _resolved(tester);

        const surface = CoreColor.token(CoreColors.surface);
        expect(
          strip.tabs[0].className.split(' '),
          contains('bg-${surface.tailwindColor}'),
        );
        expect(
          strip.tabs[1].className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
      });

      testComponents('a token borderColor draws an inset line on the bar', (
        tester,
      ) async {
        const style = CoreTabPaneStyle(
          borderColor: CoreColor.token(CoreColors.primary),
        );
        final strip = _resolved(tester, style: style);

        // Inset: inside the bar's own 2.25rem, beneath the chips (so the
        // focused chip's fill covers it), taking no layout height.
        expect(
          strip.bar.inlineStyles?.properties['box-shadow'],
          _line('rgb(var(--coui-primary))'),
        );
        // The height is unchanged by the line.
        expect(
          strip.bar.inlineStyles?.properties['height'],
          '${CoreSize.size36 / kRemDivisor}rem',
        );

        pumpStrip(tester, style: style);
        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(inline(bar)['box-shadow'], _line('rgb(var(--coui-primary))'));
      });

      testComponents('a raw borderColor is emitted as its colour', (
        tester,
      ) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(borderColor: _kLine),
        );

        expect(
          strip.bar.inlineStyles?.properties['box-shadow'],
          _line(_kLine.toValue()),
        );
      });

      testComponents('borderWidth is the line thickness', (tester) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(borderColor: _kLine, borderWidth: 3),
        );

        expect(
          strip.bar.inlineStyles?.properties['box-shadow'],
          _line(_kLine.toValue(), width: 'var(--coui-stroke-width-3)'),
        );
      });

      testComponents('a zero borderWidth draws nothing even with a colour', (
        tester,
      ) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(borderColor: _kLine, borderWidth: 0),
        );

        expect(
          strip.bar.inlineStyles?.properties.containsKey('box-shadow'),
          isFalse,
        );
      });

      testComponents('boxed states the same hairline under its bar', (
        tester,
      ) async {
        final boxed = _resolved(tester, variant: .boxed);
        expect(
          boxed.bar.inlineStyles?.properties['box-shadow'],
          _line('rgb(var(--coui-outline-variant))'),
        );

        final off = _resolved(
          tester,
          variant: .boxed,
          style: const CoreTabPaneStyle(borderColor: CoreColor.transparent),
        );
        expect(
          off.bar.inlineStyles?.properties.containsKey('box-shadow'),
          isFalse,
        );
      });

      testComponents('only the focused chip is filled, so the unfocused tabs '
          'leave the line visible', (tester) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(borderColor: _kLine),
        );

        // The line lives on the bar, under its children; a chip covers it
        // only where it paints a background — the focused one.
        const surface = CoreColor.token(CoreColors.surface);
        expect(
          strip.tabs[0].className.split(' '),
          contains('bg-${surface.tailwindColor}'),
        );
        expect(
          strip.tabs[1].className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
        expect(
          strip.tabs[1].inlineStyles?.properties.containsKey(
            'background-color',
          ),
          isFalse,
        );
      });
    });

    group('strip band is surfaceContainerLow', () {
      testComponents('the bar takes the surface-container-low class', (
        tester,
      ) async {
        final strip = _resolved(tester);

        const low = CoreColor.token(CoreColors.surfaceContainerLow);
        const regular = CoreColor.token(CoreColors.surfaceContainer);
        final classes = strip.bar.className.split(' ');
        expect(classes, contains('bg-${low.tailwindColor}'));
        expect(classes, isNot(contains('bg-${regular.tailwindColor}')));

        pumpStrip(tester);
        final bar = domWhere((c) => c.attributes?['role'] == 'tablist');
        expect(classesOf(bar), contains('bg-${low.tailwindColor}'));
      });

      testComponents('the focused chip stays the surface', (tester) async {
        final strip = _resolved(tester);

        const surface = CoreColor.token(CoreColors.surface);
        expect(
          strip.tabs[0].className.split(' '),
          contains('bg-${surface.tailwindColor}'),
        );
      });

      testComponents('boxed emits no band', (tester) async {
        final boxed = _resolved(tester, variant: .boxed);

        expect(
          boxed.bar.className.split(' ').where((c) => c.startsWith('bg-')),
          isEmpty,
        );
      });
    });

    group('a rule between tabs', () {
      testComponents('the wrappers draw outline-variant on their end edge', (
        tester,
      ) async {
        final strip = _resolved(tester);

        for (final wrapper in strip.tabWrappers) {
          final styles = wrapper.inlineStyles!.properties;
          expect(
            styles['border-inline-end'],
            '${strokeWidthCss(CoreTabPaneStyle.defaultTabSeparatorWidth)} '
            'solid rgb(var(--coui-outline-variant))',
          );
          expect(styles.containsKey('border-right'), isFalse);
          expect(styles['margin-right'], spaceCss(0));
        }

        pumpStrip(tester);
        final wrappers = find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              c.tag == 'span' &&
              classesOf(c).contains(WebLayout.flex) &&
              (c.styles?.properties ?? const {}).containsKey('margin-right'),
        );
        expect(wrappers.evaluate(), hasLength(2));
        for (final element in wrappers.evaluate()) {
          final styles = (element.component as DomComponent).styles!.properties;
          expect(styles.containsKey('border-inline-end'), isTrue);
        }
      });

      testComponents('a transparent separator takes the rule away', (
        tester,
      ) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(
            tabSeparatorColor: CoreColor.transparent,
          ),
        );

        for (final wrapper in strip.tabWrappers) {
          expect(
            wrapper.inlineStyles!.properties.containsKey('border-inline-end'),
            isFalse,
          );
        }
      });
    });

    group('the tab focus ring is inside the tab box', () {
      late ResolvedClickable seenRoot;
      late ResolvedClickableRules seenRules;

      void resolveRing(ComponentTester tester, ResolvedTabPane strip) =>
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                seenRoot = resolveClickable(
                  context,
                  enabled: true,
                  focusOutline: true,
                  enableFeedback: true,
                  clickableStyle: strip.clickableStyle,
                );
                seenRules = resolveClickableRules(
                  context,
                  scopeId: 'co-tab-ring',
                  enabled: true,
                  focusOutline: true,
                  enableFeedback: true,
                  clickableStyle: strip.clickableStyle,
                );
                return const Component.text('ok');
              },
            ),
          );

      testComponents('the scoped rule offsets the outline by minus its width, '
          'so the ring lies inside the box', (tester) async {
        resolveRing(tester, _resolved(tester));

        // Width 2, offset -2: the outline's outer edge is the border edge.
        expect(
          seenRules.css,
          contains('#co-tab-ring:focus-visible{outline-color:'),
        );
        expect(
          seenRules.css,
          contains('outline-width:var(--coui-stroke-width-2);'),
        );
        expect(
          seenRules.css,
          contains('outline-offset:calc(0.0px - var(--coui-stroke-width-2));'),
        );
        // Same ring colour as every other control: the focusRing token.
        expect(
          seenRules.css,
          contains('outline-color:rgb(var(--coui-focus-ring))'),
        );
        // No band: the focused rule declares no box-shadow layer (the
        // transition list names the property, which is not a declaration).
        expect(seenRules.css, isNot(contains('box-shadow:')));
        // …and no outside-ring class competing with the rule.
        final classes = seenRoot.root.className.split(' ');
        expect(
          classes.where((c) => c.startsWith('focus-visible:outline')),
          isEmpty,
        );
      });

      testComponents('boxed keeps the outside ring on the class path', (
        tester,
      ) async {
        resolveRing(tester, _resolved(tester, variant: .boxed));

        final classes = seenRoot.root.className.split(' ');
        expect(classes, contains('focus-visible:outline-2'));
        expect(classes, contains('focus-visible:outline-offset-2'));
        expect(seenRules.css, isEmpty);
      });

      testComponents('the rendered select Clickable carries the inset rule '
          'under its own id', (tester) async {
        pumpStrip(tester);

        final styleBlocks = find
            .byComponentPredicate((c) => c is RawText)
            .evaluate()
            .map((e) => (e.component as RawText).text)
            .where((t) => t.contains(':focus-visible{'))
            .toList();
        // One rule block per tab: each select Clickable states its own.
        expect(styleBlocks, hasLength(2));
        for (final css in styleBlocks) {
          expect(
            css,
            contains(
              'outline-offset:calc(0.0px - var(--coui-stroke-width-2));',
            ),
          );
        }
      });

      testComponents('a per-instance ring still wins over the row', (
        tester,
      ) async {
        final strip = _resolved(
          tester,
          style: const CoreTabPaneStyle(
            clickableStyle: CoreClickableStyle(
              focusOutlineStyle: CoreFocusOutlineStyle(
                align: CoreFocusOutlineStyle.defaultAlign,
              ),
            ),
          ),
        );
        resolveRing(tester, strip);

        expect(seenRules.css, isEmpty);
        expect(
          seenRoot.root.className.split(' '),
          contains('focus-visible:outline-offset-2'),
        );
      });
    });
  });

  group('TabPane editorStrip row — indicator bar and close box', () {
    const primary = CoreColor.token(CoreColors.primary);
    DomComponent domWhere(bool Function(DomComponent c) test) => find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .firstWhere(test);

    void pumpStrip(
      ComponentTester tester, {
      CoreTabPaneVariant variant = CoreTabPaneVariant.editorStrip,
      CoreTabPaneStyle? style,
    }) => pumpWithTheme(
      tester,
      TabPane(
        variant: variant,
        tabs: [
          CoreTabItem<Component>(label: 'main.dart', onClose: () {}),
          const CoreTabItem<Component>(label: 'pubspec.yaml'),
        ],
        selectedIndex: 0,
        onChanged: (index) {},
        tabPaneStyle: style,
      ),
    );

    testComponents('the selected chip carries a primary bar span along its '
        'top edge; boxed carries it along the bottom', (tester) async {
      final strip = _resolved(tester);
      final indicator = strip.indicator!;
      final classes = indicator.className.split(' ');
      expect(classes, contains(WebLayout.absolute));
      expect(classes, contains(WebLayout.pointerEventsNone));
      expect(classes, contains('bg-${primary.tailwindColor}'));
      final inlineBar = indicator.inlineStyles!.properties;
      expect(inlineBar['left'], '0');
      expect(inlineBar['right'], '0');
      expect(inlineBar['top'], '0');
      expect(inlineBar.containsKey('bottom'), isFalse);
      expect(inlineBar['height'], 'var(--coui-stroke-width-2)');
      // No inset shadow any more: the bar is a box of its own.
      for (final chip in strip.tabs) {
        expect(
          chip.inlineStyles!.properties.containsKey('box-shadow'),
          isFalse,
        );
      }
      expect(strip.tabs[0].className.split(' '), contains(WebLayout.relative));
      expect(
        strip.tabs[1].className.split(' '),
        isNot(contains(WebLayout.relative)),
      );

      final boxed = _resolved(tester, variant: .boxed).indicator!;
      final boxedInline = boxed.inlineStyles!.properties;
      expect(boxedInline['bottom'], '0');
      expect(boxedInline.containsKey('top'), isFalse);
      expect(boxedInline['left'], '0');
      expect(boxedInline['right'], '0');
      expect(
        boxedInline['border-radius'],
        const CoreBorderRadius.only(
          topLeft: CoreRadius.radius2,
          topRight: CoreRadius.radius2,
        ).toValue(),
      );

      // The DOM: exactly one bar span, inside the selected chip.
      pumpStrip(tester);
      final bars = find.byComponentPredicate(
        (c) =>
            c is DomComponent &&
            c.tag == 'span' &&
            c.attributes?['aria-hidden'] == 'true' &&
            (c.classes ?? '').split(' ').contains(WebLayout.absolute),
      );
      expect(bars.evaluate(), hasLength(1));
    });

    testComponents('paint only: the selected chip gains no border, padding '
        'or height', (tester) async {
      final strip = _resolved(tester);
      final selected = strip.tabs[0].inlineStyles!.properties;
      final unselected = strip.tabs[1].inlineStyles!.properties;

      for (final key in [
        'padding-inline-start',
        'padding-inline-end',
        'padding-block-start',
        'padding-block-end',
      ]) {
        expect(selected[key], unselected[key], reason: key);
      }
      expect(selected.containsKey('border-width'), isFalse);
      expect(selected.containsKey('height'), isFalse);
      expect(
        strip.tabs[0].className.split(' '),
        isNot(contains('border')),
      );
    });

    testComponents('a width and colour override reach the bar; transparent '
        'switches it off', (tester) async {
      final stated = _resolved(
        tester,
        style: const CoreTabPaneStyle(
          indicatorColor: _kLine,
          indicatorWidth: 3,
        ),
      );
      final statedInline = stated.indicator!.inlineStyles!.properties;
      expect(statedInline['height'], 'var(--coui-stroke-width-3)');
      expect(statedInline['background-color'], _kLine.toValue());
      expect(
        stated.indicator!.className
            .split(' ')
            .where((c) => c.startsWith('bg-')),
        isEmpty,
        reason: 'a raw colour rides inline, the token class is dropped',
      );

      final off = _resolved(
        tester,
        style: const CoreTabPaneStyle(indicatorColor: CoreColor.transparent),
      );
      expect(off.indicator, isNull);
      expect(
        off.tabs[0].className.split(' '),
        isNot(contains(WebLayout.relative)),
      );

      final boxed = _resolved(
        tester,
        variant: .boxed,
        style: const CoreTabPaneStyle(indicatorColor: _kLine),
      );
      final boxedInline = boxed.indicator!.inlineStyles!.properties;
      expect(boxedInline['height'], 'var(--coui-stroke-width-2)');
      expect(boxedInline['background-color'], _kLine.toValue());
    });

    group('the bar survives forced colours', () {
      List<String> forcedRules() => find
          .byComponentPredicate((c) => c is RawText)
          .evaluate()
          .map((e) => (e.component as RawText).text)
          .where((t) => t.contains('forced-colors'))
          .toList();

      testComponents('the rule is a real border on a zero-height '
          'pseudo-element, written only inside the media query', (
        tester,
      ) async {
        final rules = _rules(tester);

        expect(
          rules.css,
          _forcedBar(
            'co-tab-pane-indicator-2',
            width: 'var(--coui-stroke-width-2)',
          ),
        );
        // Nothing is declared outside `@media (forced-colors:active)`, so
        // normal rendering is untouched.
        expect(rules.css, startsWith('@media (forced-colors:active){'));
        expect(rules.css.indexOf('@media'), rules.css.lastIndexOf('@media'));
        // Paint only: no declaration that could cost the chip layout height.
        expect(rules.css, contains('height:0;'));
        expect(rules.css, contains('position:absolute;'));
        expect(rules.css, isNot(contains('padding')));
        expect(rules.css, isNot(contains('margin')));
        // A system colour the mode keeps, not a token the mode recolours.
        expect(rules.css, contains('solid Highlight'));
      });

      testComponents('only the selected chip wears the class the rule '
          'selects on', (tester) async {
        final strip = _resolved(tester);

        expect(
          strip.tabs[0].className.split(' '),
          contains('co-tab-pane-indicator-2'),
        );
        expect(
          strip.tabs[1].className.split(' '),
          isNot(contains('co-tab-pane-indicator-2')),
        );
        // The chip's rule and the class agree: the rule selects exactly the
        // class the chip wears.
        expect(_rules(tester).css, contains('.co-tab-pane-indicator-2{'));
      });

      testComponents('a width override moves the class and the rule '
          'together; an integral width spells no fraction', (tester) async {
        const style = CoreTabPaneStyle(
          indicatorColor: _kLine,
          indicatorWidth: 3,
        );
        final strip = _resolved(tester, style: style);

        expect(
          strip.tabs[0].className.split(' '),
          contains('co-tab-pane-indicator-3'),
        );
        expect(
          _rules(tester, style: style).css,
          _forcedBar(
            'co-tab-pane-indicator-3',
            width: 'var(--coui-stroke-width-3)',
          ),
        );
        expect(tabPaneIndicatorScopeClass(2), 'co-tab-pane-indicator-2');
        expect(tabPaneIndicatorScopeClass(1.5), 'co-tab-pane-indicator-1_5');
      });

      testComponents('no bar, no class and no rule: transparent and zero '
          'width', (tester) async {
        for (final style in const [
          CoreTabPaneStyle(indicatorColor: CoreColor.transparent),
          CoreTabPaneStyle(indicatorWidth: 0),
        ]) {
          final strip = _resolved(tester, style: style);
          expect(
            strip.tabs[0].className,
            isNot(contains('co-tab-pane-indicator')),
          );
          expect(_rules(tester, style: style).css, isEmpty);
        }
      });

      testComponents('boxed writes the same rule on the bottom edge', (
        tester,
      ) async {
        final boxed = _resolved(tester, variant: .boxed);
        expect(
          boxed.tabs[0].className.split(' '),
          contains('co-tab-pane-indicator-2'),
        );
        expect(
          _rules(tester, variant: .boxed).css,
          _forcedBar(
            'co-tab-pane-indicator-2',
            width: 'var(--coui-stroke-width-2)',
            edge: 'bottom:0;',
          ),
        );
      });

      testComponents('the rendered strip carries one <style> block, and the '
          'selected chip wears the class it selects', (tester) async {
        pumpStrip(tester);

        final blocks = forcedRules();
        expect(blocks, hasLength(1));
        expect(
          blocks.single,
          _forcedBar(
            'co-tab-pane-indicator-2',
            width: 'var(--coui-stroke-width-2)',
          ),
        );
        final styleTags = find.byComponentPredicate(
          (c) => c is DomComponent && c.tag == 'style',
        );
        expect(
          styleTags.evaluate().where(
            (e) =>
                (e.component as DomComponent).children?.any(
                  (c) => c is RawText && c.text.contains('forced-colors'),
                ) ??
                false,
          ),
          hasLength(1),
        );

        final withClass = find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              (c.classes ?? '').split(' ').contains('co-tab-pane-indicator-2'),
        );
        expect(withClass.evaluate(), hasLength(1));
      });

      testComponents('a transparent bar renders no forced-colours block', (
        tester,
      ) async {
        pumpStrip(
          tester,
          style: const CoreTabPaneStyle(indicatorColor: CoreColor.transparent),
        );

        expect(forcedRules(), isEmpty);
      });

      testComponents('boxed renders one block by default', (tester) async {
        pumpStrip(tester, variant: .boxed);

        expect(forcedRules(), hasLength(1));
      });
    });

    testComponents('the close Button is a 20 box with a 12 glyph', (
      tester,
    ) async {
      final strip = _resolved(tester);
      expect(strip.closeButtonStyle.width, 20);
      expect(strip.closeButtonStyle.height, 20);
      expect(strip.closeButtonStyle.padding, CoreEdgeInsets.zero);
      expect(
        strip.closeButtonStyle.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      expect(strip.closeIconStyle.size, 12);

      pumpStrip(tester);
      final close = find.byType(Button).evaluate().single.component as Button;
      expect(close.buttonStyle, strip.closeButtonStyle);
      final icon =
          find
                  .descendant(
                    of: find.byType(Button),
                    matching: find.byType(Icon),
                  )
                  .evaluate()
                  .single
                  .component
              as Icon;
      expect(icon.iconStyle, strip.closeIconStyle);

      final button = domWhere((c) => c.tag == 'button');
      final inline = button.styles!.properties;
      expect(inline['width'], '${CoreSize.size20 / kRemDivisor}rem');
      expect(inline['min-height'], '${CoreSize.size20 / kRemDivisor}rem');
      expect(
        (button.classes ?? '').split(' ').where((c) => c.startsWith('h-')),
        isEmpty,
        reason: 'a stated height drops the size row class',
      );
    });

    group('the close glyph is onSurfaceSubtle in every button state', () {
      const subtle = CoreColor.token(CoreColors.onSurfaceSubtle);
      final subtleClass = 'text-${subtle.tailwindColor}';

      DomComponent glyphSvg() => find
          .descendant(
            of: find.byType(Button),
            matching: find.byType(DomComponent),
          )
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere((c) => c.tag == 'svg');

      testComponents('resolver states it and the svg carries its own text '
          'colour class', (tester) async {
        expect(_resolved(tester).closeIconStyle.color, subtle);

        pumpWithTheme(
          tester,
          TabPane(
            variant: .editorStrip,
            tabs: [CoreTabItem<Component>(label: 'main.dart', onClose: () {})],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );
        final svg = glyphSvg();
        final svgClasses = (svg.classes ?? '').split(' ');
        expect(svgClasses, contains(subtleClass));

        // The glyph's colour is its own, so the ghost button's foreground
        // (set on the <button> element, and its hover variant) only reaches
        // it by inheritance — which an own `text-*` class on the svg beats.
        final buttonClasses = (domWhere((c) => c.tag == 'button').classes ?? '')
            .split(' ');
        expect(
          buttonClasses,
          isNot(contains(subtleClass)),
          reason: 'the button keeps its own foreground; the glyph differs',
        );
        expect(
          svgClasses.where((c) => c.contains('hover:')),
          isEmpty,
          reason: 'no hover colour on the glyph itself: it stays pinned',
        );
      });

      testComponents('a disabled tab keeps the same glyph class', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          TabPane(
            variant: .editorStrip,
            tabs: [
              CoreTabItem<Component>(
                label: 'pubspec.yaml',
                enabled: false,
                onClose: () {},
              ),
            ],
            selectedIndex: 0,
            onChanged: (index) {},
          ),
        );
        expect((glyphSvg().classes ?? '').split(' '), contains(subtleClass));
      });
    });

    testComponents('boxed states no glyph colour: the svg inherits its '
        "button's", (tester) async {
      expect(_resolved(tester, variant: .boxed).closeIconStyle.color, isNull);
      pumpStrip(tester, variant: .boxed);
      final svg = find
          .descendant(
            of: find.byType(Button),
            matching: find.byType(DomComponent),
          )
          .evaluate()
          .map((e) => e.component as DomComponent)
          .firstWhere((c) => c.tag == 'svg');
      expect(
        (svg.classes ?? '').split(' ').where((c) => c.startsWith('text-')),
        isEmpty,
      );
    });

    testComponents('boxed states no close box: the Button keeps its size '
        'row', (tester) async {
      final boxed = _resolved(tester, variant: .boxed);
      expect(boxed.closeButtonStyle, const CoreButtonStyle());
      expect(boxed.closeIconStyle, const CoreIconStyle());

      pumpStrip(tester, variant: .boxed);
      final button = domWhere((c) => c.tag == 'button');
      expect(button.styles?.properties.containsKey('width'), isFalse);
      expect(button.styles?.properties.containsKey('min-height'), isFalse);
      expect(
        (button.classes ?? '').split(' ').where((c) => c.startsWith('h-')),
        isNotEmpty,
      );
    });

    testComponents('a colour-only closeIconStyle keeps the row size 12', (
      tester,
    ) async {
      final strip = _resolved(
        tester,
        style: const CoreTabPaneStyle(
          closeIconStyle: CoreIconStyle(color: _kLine),
        ),
      );
      expect(strip.closeIconStyle.size, 12);
      expect(strip.closeIconStyle.color, _kLine);
    });
  });
}
