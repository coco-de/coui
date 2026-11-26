import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/display/banner/banner.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The inline width of the `lucide:x` glyph (#6214) — the close affordance
/// states no glyph size, so it is the `md` square button's (18 → 1.125rem).
String? _closeGlyphWidth() => find
    .tag('svg')
    .evaluate()
    .map((element) => element.component)
    .whereType<DomComponent>()
    .firstWhere((c) => c.attributes?['data-icon'] == 'lucide:x')
    .styles
    ?.properties['width'];

void main() {
  testComponents(
    '#6214: the dismiss glyph is the md square button glyph (18)',
    (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Banner(message: const Component.text('Dismissible'), onDismiss: () {}),
      );
      expect(_closeGlyphWidth(), '1.125rem');
    },
  );

  group('Banner', () {
    testComponents('zero-width border remains zero in CSS', (tester) async {
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('Visible safety notice'),
          bannerStyle: const CoreBannerStyle(
            borderWidth: 0,
            borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
          ),
        ),
      );
      final root = find.tag('div').evaluate().first.component as DomComponent;
      expect(
        root.styles?.properties['border-bottom-width'],
        equals('var(--coui-stroke-width-0)'),
      );
      expect(find.text('Visible safety notice'), findsOneComponent);
    });

    testComponents('renders message text', (tester) async {
      pumpWithTheme(tester, Banner(message: const Component.text('Heads up!')));

      expect(find.text('Heads up!'), findsOneComponent);
    });

    testComponents('renders message and description', (tester) async {
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('Message'),
          description: const Component.text('Description'),
        ),
      );

      expect(find.text('Message'), findsOneComponent);
      expect(find.text('Description'), findsOneComponent);
    });

    testComponents('sets role=banner on the root element', (tester) async {
      pumpWithTheme(tester, Banner(message: const Component.text('Body')));

      final banner = find.tag('div').evaluate().first.component as DomComponent;
      expect(banner.attributes?['role'], equals('banner'));
    });

    testComponents('renders an action slot', (tester) async {
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('Body'),
          action: const Component.text('Undo'),
        ),
      );

      expect(find.text('Undo'), findsOneComponent);
    });

    test('accepts custom id', () {
      final banner = Banner(
        message: const Component.text('Body'),
        id: 'banner-1',
      );
      expect(banner.id, equals('banner-1'));
    });

    test('copyWith preserves properties', () {
      final original = Banner(
        message: const Component.text('Body'),
        variant: CoreBannerVariant.info,
        showIcon: false,
        id: 'banner-orig',
      );

      final copy = original.copyWith(id: 'banner-new');

      expect(copy.id, equals('banner-new'));
      expect(copy.variant, equals(CoreBannerVariant.info));
      expect(copy.showIcon, isFalse);
    });

    testComponents('a Button action wears the variant foreground', (
      tester,
    ) async {
      // The message, description, icon and dismiss glyph all track the
      // variant. The action used to be the one thing that did not — it
      // kept `plain`'s own label colour, picked for a light neutral
      // surface, which on a solid banner is a dark word on a saturated
      // fill.
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('Solid'),
          variant: CoreBannerVariant.destructive,
          emphasis: CoreBannerEmphasis.solid,
          action: Button(child: const Component.text('Retry')),
        ),
      );
      final rendered = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .firstWhere((b) => b.buttonStyle?.foregroundColor != null);

      expect(
        rendered.buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.onError),
      );
      expect(
        rendered.buttonStyle?.hoverForegroundColor,
        const CoreColor.token(CoreColors.onError),
      );
    });

    testComponents('a caller colour on the action still wins', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('Solid'),
          variant: CoreBannerVariant.success,
          emphasis: CoreBannerEmphasis.solid,
          action: Button(
            buttonStyle: const CoreButtonStyle(
              foregroundColor: CoreColor.token(CoreColors.surface),
            ),
            child: const Component.text('Undo'),
          ),
        ),
      );

      final rendered = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .firstWhere((b) => b.buttonStyle?.foregroundColor != null);
      expect(
        rendered.buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.surface),
      );
    });

    testComponents('the dismiss button composes the square shape', (
      tester,
    ) async {
      // An icon-only affordance is square — on the rectangle shape the
      // inset around the glyph drew the wash as a tall pill (#6214).
      pumpWithTheme(
        tester,
        Banner(message: const Component.text('Dismissible'), onDismiss: () {}),
      );
      final dismiss = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .single;
      expect(dismiss.shape, CoreButtonShape.square);
      final el = find.tag('button').evaluate().first.component as DomComponent;
      expect(el.classes, contains('aspect-square'));
    });

    testComponents('a plain action gets 8 on each side', (tester) async {
      // `plain` sits flush with its label; on a banner the wash was the word
      // wide (#6214).
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('With action'),
          action: Button(
            variant: CoreButtonVariant.plain,
            child: const Component.text('Retry'),
          ),
        ),
      );
      final action = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .firstWhere((b) => b.buttonStyle?.padding != null);
      expect(
        action.buttonStyle?.padding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space8),
      );
    });

    testComponents('an outline action keeps its own inset', (tester) async {
      // The inline inset is `plain`'s alone (#6214): an `sm` outline keeps
      // its size row's 12, so the slot states no padding for it.
      pumpWithTheme(
        tester,
        Banner(
          message: const Component.text('With action'),
          action: Button(
            variant: CoreButtonVariant.outline,
            child: const Component.text('Retry'),
          ),
        ),
      );
      final action = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .firstWhere((b) => b.variant == CoreButtonVariant.outline);
      expect(action.buttonStyle?.padding, isNull);
    });

    test('implements CoreBannerContract', () {
      final banner = Banner(
        message: const Component.text('Body'),
        variant: CoreBannerVariant.success,
      );

      expect(banner.variant, equals(CoreBannerVariant.success));
    });
  });
}
