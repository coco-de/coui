import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/web_layout.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/layout/gap/gap.dart';
import 'package:coui_web/src/components/overlay/alert/alert.dart';
import 'package:coui_web/src/components/overlay/alert/alert_style.dart';
import 'package:coui_web/src/components/text/text.dart' as coui;
import 'package:coui_web/src/theme/coui_theme.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/theme/theme_data.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The `role` on the alert's own root element.
String? _role(ComponentTester tester) =>
    (find.tag('div').evaluate().first.component as DomComponent)
        .attributes?['role'];

/// The leading glyph's own box — the `leading-none` slot.
DomComponent _iconBox() => find
    .tag('div')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .firstWhere(
      (div) => (div.classes ?? '').split(' ').contains('leading-none'),
    );

/// The box a caller's `leading` sits in — the one that holds the ambient
/// icon theme.
DomComponent _leadingBox() => find
    .tag('div')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .firstWhere(
      (div) => (div.children ?? const <Component>[]).any((c) => c is IconTheme),
    );

/// The row that arranges glyph, content, action and dismiss.
DomComponent _row() => find
    .tag('div')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .firstWhere(
      (div) => (div.classes ?? '').contains(WebLayout.flexRowItemsCenterFull),
    );

void main() {
  group('the row centres its parts', () {
    testComponents('the row aligns to the middle, not to the title line', (
      tester,
    ) async {
      pumpWithTheme(tester, const Alert(title: 'Body', description: 'More'));

      expect(_row().classes, contains('items-center'));
      expect(_row().classes, isNot(contains('items-start')));
    });

    testComponents('the glyph box states no height of its own', (
      tester,
    ) async {
      // A box one title line tall only makes sense for a row that aligns to
      // the top. In a centred row the glyph sits at the middle of the
      // whole block, so a stated height would pull it back up.
      pumpWithTheme(tester, const Alert(title: 'Body', description: 'More'));

      expect(_iconBox().styles?.properties['height'], isNull);
    });

    testComponents('a destructive alert draws the circle-alert glyph', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Alert(variant: .destructive, title: 'Body'),
      );

      final icons = find
          .tag('svg')
          .evaluate()
          .map((element) => element.component)
          .whereType<DomComponent>()
          .map((c) => c.attributes?['data-icon'])
          .whereType<String>();
      expect(icons, contains('lucide:circle-alert'));
      expect(icons, isNot(contains('lucide:circle-x')));
    });
  });

  group('layout', () {
    /// The `<div>` that holds [text] directly.
    DomComponent textBox(String text) => find
        .tag('div')
        .evaluate()
        .map((element) => element.component as DomComponent)
        .lastWhere(
          (div) => (div.children ?? const <Component>[]).any(
            (c) => c is coui.Text && c.data == text,
          ),
        );

    DomComponent root() =>
        find.tag('div').evaluate().first.component as DomComponent;

    testComponents('the inline strip does not draw the description', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Alert(
          layout: CoreAlertLayout.inline,
          title: 'Strip title',
          description: 'Never drawn inline',
        ),
      );

      expect(find.text('Strip title'), findsOneComponent);
      expect(find.text('Never drawn inline'), findsNothing);
    });

    testComponents('the inline title is one truncated line', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Strip title'),
      );

      expect(textBox('Strip title').classes?.split(' '), contains('truncate'));
    });

    testComponents('a stacked title is free to wrap', (tester) async {
      pumpWithTheme(tester, const Alert(title: 'Panel title'));

      expect(
        textBox('Panel title').classes?.split(' '),
        isNot(contains('truncate')),
      );
    });

    testComponents('the inline title is body text in on-surface-variant', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Strip title'),
      );

      final classes = textBox('Strip title').classes?.split(' ');
      expect(classes, contains('text-on-surface-variant'));
      expect(classes, contains('text-body-small'));
    });

    testComponents('the inline strip states no floor', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Strip title'),
      );

      expect(root().styles?.properties['min-height'], isNull);
    });

    testComponents('the inline strip pads 10 / 14', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(layout: CoreAlertLayout.inline, title: 'Strip title'),
      );

      // Symmetric, so the one physical shorthand — top/bottom 10, sides 14.
      expect(
        root().styles?.properties['padding'],
        '${spaceCss(CoreSpace.space10)} ${spaceCss(CoreSpace.space14)} '
        '${spaceCss(CoreSpace.space10)} ${spaceCss(CoreSpace.space14)}',
      );
    });

    testComponents(
      'the title-to-description gap sits on the description, not the title',
      (tester) async {
        // A gap under the title is a gap under every title-only alert too,
        // which nudges the row off-centre on this platform alone — the
        // Flutter twin pads the description.
        pumpWithTheme(
          tester,
          const Alert(title: 'Panel title', description: 'More'),
        );

        expect(
          textBox('Panel title').styles?.properties['margin-bottom'],
          isNull,
        );
        expect(
          textBox('More').styles?.properties['margin-top'],
          spaceCss(CoreAlertStyle.defaultTitleBottomMargin),
        );
      },
    );
  });

  group('leading', () {
    Iterable<String> glyphs() => find
        .tag('svg')
        .evaluate()
        .map((element) => element.component)
        .whereType<DomComponent>()
        .map((c) => c.attributes?['data-icon'])
        .whereType<String>();

    testComponents('replaces the tone glyph', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(
          variant: CoreAlertVariant.info,
          title: 'Body',
          leading: Component.text('LEAD'),
        ),
      );

      expect(find.text('LEAD'), findsOneComponent);
      // Drawn instead of the glyph, not beside it.
      expect(glyphs(), isNot(contains('lucide:info')));
      // In its own structural box, not the glyph's: the glyph box hands its
      // colour and its line height of 1 to everything inside it, which would
      // recolour a text `leading` here and not on Flutter, where the slot is
      // wrapped in an `IconTheme` and nothing more.
      expect(
        find
            .tag('div')
            .evaluate()
            .map((element) => element.component as DomComponent)
            .where(
              (div) => (div.classes ?? '').split(' ').contains('leading-none'),
            ),
        isEmpty,
      );
      final box = _leadingBox();
      final classes = box.classes?.split(' ');
      expect(classes, isNot(contains('text-on-info-container')));
      expect(classes, isNot(contains('leading-none')));
      // The colour and size travel as the ambient icon theme instead.
      final ambient = (box.children ?? const <Component>[])
          .whereType<IconTheme>()
          .single
          .data;
      expect(
        ambient.color,
        CoreAlertStyle.defaultsByVariant[CoreAlertVariant.info]!.iconColor,
      );
      expect(ambient.size, CoreAlertStyle.defaultIconStyle.size);
    });

    testComponents('a bare icon as leading is drawn in the glyph colour', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Alert(
          variant: CoreAlertVariant.info,
          title: 'Body',
          leading: Icon(LucideIcons.circleCheck),
        ),
      );

      final svg = find
          .tag('svg')
          .evaluate()
          .map((element) => element.component as DomComponent)
          .single;
      final want = CoreAlertStyle
          .defaultsByVariant[CoreAlertVariant.info]!
          .iconColor
          .tailwindColor;
      expect(svg.classes?.split(' '), contains('text-$want'));
    });

    testComponents('a badge goes in the same place', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(
          layout: CoreAlertLayout.inline,
          title: 'All changes saved',
          leading: Badge(
            tone: CoreBadgeTone.success,
            showDot: true,
            child: coui.Text('Done'),
          ),
        ),
      );

      expect(find.text('Done'), findsOneComponent);
      expect(glyphs(), isNot(contains('lucide:info')));
    });

    for (final (layout, size) in [
      (CoreAlertLayout.stacked, CoreAlertStyle.defaultIconStyle.size!),
      (
        CoreAlertLayout.inline,
        CoreAlertStyle
            .defaultsByLayout[CoreAlertLayout.inline]!
            .iconStyle!
            .size!,
      ),
    ]) {
      testComponents(
        'a bare icon as leading takes the ${layout.name} glyph size',
        (tester) async {
          pumpWithTheme(
            tester,
            Alert(
              variant: CoreAlertVariant.info,
              layout: layout,
              title: 'Body',
              leading: const Icon(LucideIcons.circleCheck),
            ),
          );

          final svg = find
              .tag('svg')
              .evaluate()
              .map((element) => element.component as DomComponent)
              .single;
          expect(svg.attributes?['data-icon'], 'lucide:circle-check');
          expect(svg.styles?.properties['width'], '${size / kRemDivisor}rem');
        },
      );
    }

    test('copyWith carries layout and leading', () {
      const leading = Component.text('LEAD');
      final copy = const Alert(
        title: 'Title',
        layout: CoreAlertLayout.inline,
        leading: leading,
      ).copyWith(title: 'New');

      expect(copy.layout, CoreAlertLayout.inline);
      expect(copy.leading, same(leading));
    });
  });

  group('showIcon', () {
    Iterable<String> glyphs() => find
        .tag('svg')
        .evaluate()
        .map((element) => element.component)
        .whereType<DomComponent>()
        .map((c) => c.attributes?['data-icon'])
        .whereType<String>();

    testComponents('is on by default, from the contract', (tester) async {
      expect(const Alert(title: 'Title').showIcon, isTrue);
      expect(CoreAlertContract.defaultShowIcon, isTrue);
      pumpWithTheme(
        tester,
        const Alert(variant: CoreAlertVariant.success, title: 'Body'),
      );

      expect(glyphs(), contains('lucide:circle-check'));
      // Glyph box, then the gap, then the text.
      final row = _row().children!;
      expect(row[1], isA<Gap>());
    });

    for (final layout in CoreAlertLayout.values) {
      testComponents('false drops the ${layout.name} glyph and the gap after '
          'it — the text block opens the row', (tester) async {
        pumpWithTheme(
          tester,
          Alert(
            variant: CoreAlertVariant.success,
            layout: layout,
            title: 'Text only',
            showIcon: false,
          ),
        );

        expect(glyphs(), isEmpty);
        expect(find.byType(Gap), findsNothing);
        final row = _row().children!;
        expect(row.first, isNot(isA<Gap>()));
        expect(
          find.descendant(
            of: find.byComponent(row.first),
            matching: find.text('Text only'),
          ),
          findsOneComponent,
        );
      });
    }

    testComponents('false hides a caller\'s leading too — it is the same '
        'slot', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(
          title: 'Body',
          showIcon: false,
          leading: Component.text('LEAD'),
        ),
      );

      expect(find.text('LEAD'), findsNothing);
    });

    testComponents('false keeps the dismiss mark', (tester) async {
      pumpWithTheme(
        tester,
        Alert(title: 'Body', showIcon: false, onDismiss: () {}),
      );

      expect(glyphs(), contains('lucide:x'));
      expect(glyphs(), hasLength(1));
    });

    testComponents('a theme variantStyles titleColor carries the tone into '
        'the title', (tester) async {
      tester.pumpComponent(
        const Theme(
          data: ThemeData(
            coreComponentTheme: CoreComponentTheme(
              alert: CoreAlertTheme(
                variantStyles: {
                  CoreAlertVariant.success: CoreAlertStyle(
                    titleColor: CoreColor.token(CoreColors.onSuccessContainer),
                  ),
                },
              ),
            ),
          ),
          child: Alert.success(title: 'Toned', showIcon: false),
        ),
      );

      // The title box — an ancestor of the text that carries the title's
      // colour class (the nearest one is the `Text` span, which inherits).
      final toned = find
          .ancestor(
            of: find.text('Toned'),
            matching: find.byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  (c.classes ?? '')
                      .split(' ')
                      .contains(
                        'text-on-success-container',
                      ),
            ),
          )
          .evaluate();
      expect(toned, isNotEmpty);
    });
  });

  group('title colour precedence', () {
    testComponents('titleColor outranks foregroundColor', (tester) async {
      // The two platforms used to answer this the opposite way round —
      // Web painted the title in `foregroundColor`, Flutter in
      // `titleColor`. Both now let the title-specific field win.
      final resolved = <ResolvedAlert>[];
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved.add(
              resolveAlert(
                context,
                variant: CoreAlertVariant.neutral,
                alertStyle: const CoreAlertStyle(
                  titleColor: CoreColor.token(CoreColors.primary),
                  foregroundColor: CoreColor.token(CoreColors.error),
                ),
              ),
            );
            return const Alert(title: 'Body');
          },
        ),
      );

      final classes = resolved.single.title.className.split(' ');
      expect(classes, contains('text-primary'));
      expect(classes, isNot(contains('text-error')));
    });
  });

  group('Alert', () {
    testComponents('renders description text', (tester) async {
      pumpWithTheme(tester, const Alert(title: 'Heads up!'));

      expect(find.text('Heads up!'), findsOneComponent);
    });

    testComponents('renders title and description', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(title: 'Title', description: 'Description'),
      );

      expect(find.text('Title'), findsOneComponent);
      expect(find.text('Description'), findsOneComponent);
    });

    testComponents('a failure interrupts', (tester) async {
      // `role="alert"` is assertive: it cuts off whatever the screen
      // reader is currently saying. A failure has earned that.
      pumpWithTheme(tester, const Alert.destructive(title: 'Body'));

      expect(_role(tester), equals('alert'));
    });

    testComponents('a confirmation waits its turn', (tester) async {
      // And nothing else has. This component used to emit `role="alert"`
      // for every variant, so a "Saved" banner interrupted the sentence
      // the user was listening to, every time one rendered.
      pumpWithTheme(
        tester,
        const Alert(variant: CoreAlertVariant.success, title: 'Body'),
      );

      expect(_role(tester), equals('status'));
    });

    testComponents('an untoned alert announces nothing', (tester) async {
      // The neutral variant carries no tone: it is a container holding a
      // message, not a report that something just happened. A live
      // region here would announce ordinary page content on load.
      pumpWithTheme(tester, const Alert(title: 'Body'));

      expect(_role(tester), isNull);
    });

    testComponents('renders an action slot', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(title: 'Body', action: Component.text('Undo')),
      );

      expect(find.text('Undo'), findsOneComponent);
    });

    test('accepts custom id', () {
      const alert = Alert(title: 'Body', id: 'alert-1');
      expect(alert.id, equals('alert-1'));
    });

    test('copyWith preserves properties', () {
      const original = Alert(
        title: 'Body',
        variant: CoreAlertVariant.info,
        id: 'alert-orig',
      );

      final copy = original.copyWith(id: 'alert-new');

      expect(copy.id, equals('alert-new'));
      expect(copy.variant, equals(CoreAlertVariant.info));
    });

    test('implements CoreAlertContract', () {
      const alert = Alert(title: 'Body', variant: CoreAlertVariant.info);

      expect(alert.variant, equals(CoreAlertVariant.info));
    });
  });

  group('the action-button slot', () {
    // The same promise as the Flutter half
    // (`alert_action_button_style_test.dart`): the slot reaches a `Button`
    // action under the button's own style, which still wins.
    testComponents('a Button action takes the slot under its own style', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Alert(
          title: 'Could not save',
          action: Button(
            onPressed: () {},
            buttonStyle: const CoreButtonStyle(
              padding: CoreEdgeInsets.all(CoreSpace.space12),
            ),
            child: const coui.Text('Retry'),
          ),
          alertStyle: const CoreAlertStyle(
            actionButtonStyle: CoreButtonStyle(
              backgroundColor: CoreColor.token(CoreColors.primaryContainer),
              padding: CoreEdgeInsets.all(CoreSpace.space4),
            ),
          ),
        ),
      );

      final drawn = (find.byType(Button).evaluate().single.component as Button)
          .buttonStyle;
      expect(
        drawn?.backgroundColor,
        const CoreColor.token(CoreColors.primaryContainer),
      );
      expect(drawn?.padding, const CoreEdgeInsets.all(CoreSpace.space12));
    });

    testComponents(
      'without the slot the action is the component it was handed',
      (
        tester,
      ) async {
        final action = Button(
          onPressed: () {},
          child: const coui.Text('Retry'),
        );
        pumpWithTheme(tester, Alert(title: 'Could not save', action: action));

        expect(find.byType(Button).evaluate().single.component, same(action));
      },
    );
  });
}
