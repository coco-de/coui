import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/components/display/badge/badge.dart';
import 'package:coui_web/src/components/display/badge/badge_style.dart';
import 'package:coui_web/src/theme/icon_theme.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' show RawText;
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Every rendered `<span>`, root first (document order).
List<DomComponent> _spans() => find
    .tag('span')
    .evaluate()
    .map((element) => element.component as DomComponent)
    .toList();

/// The badge's root `<span>`.
DomComponent _root() => _spans().first;

/// The leading status dots — the `<span>`s hidden from assistive tech.
List<DomComponent> _leadingDots() => _spans()
    .where((span) => span.attributes?['aria-hidden'] == 'true')
    .toList();

/// What [resolveBadge] states for the pumped badge, read under the badge's
/// own context — the expectation the rendered root is held to.
ResolvedBadge _resolvedFor(Badge badge) => resolveBadge(
  find.byType(Badge).evaluate().single,
  tone: badge.tone,
  variant: badge.variant,
  form: badge.form,
  size: badge.size,
  interactive: badge.onPressed != null,
  badgeStyle: badge.badgeStyle,
);

/// The text of the badge's scoped `<style>`.
String _scopedCss() =>
    (find.byType(RawText).evaluate().single.component as RawText).text;

void main() {
  group('Badge defaults', () {
    test('a bare badge is the neutral tonal label at md, without a dot', () {
      const badge = Badge(child: Component.text('Tag'));

      expect(badge.tone, CoreBadgeTone.neutral);
      expect(badge.variant, CoreBadgeVariant.tonal);
      expect(badge.form, CoreBadgeForm.label);
      expect(badge.size, CoreComponentSize.md);
      expect(badge.showDot, isFalse);
    });

    test('the defaults are the Core contract defaults', () {
      const badge = Badge();

      expect(badge.tone, CoreBadgeTone.defaultTone);
      expect(badge.variant, CoreBadgeVariant.defaultVariant);
      expect(badge.form, CoreBadgeForm.defaultForm);
      expect(badge.size, CoreBadgeContract.defaultSize);
      expect(badge.showDot, CoreBadgeContract.defaultShowDot);
    });
  });

  group('bounded label layout', () {
    testComponents('label consumes the resolved wrapping slot', (tester) async {
      const badge = Badge(child: Component.text('A long review label'));
      pumpWithTheme(tester, badge);
      final spans = _spans();
      final resolved = _resolvedFor(badge);
      expect(spans, hasLength(2));
      expect(spans.last.classes, resolved.label.className);
      expect(spans.last.classes, contains('min-w-0'));
      expect(spans.last.classes, contains('whitespace-normal'));
      expect(spans.last.classes, contains('[overflow-wrap:anywhere]'));
      expect(spans.first.classes, contains('max-w-full'));
      expect(find.text('A long review label'), findsOneComponent);
    });
    testComponents('label adornments keep their own width', (tester) async {
      pumpWithTheme(
        tester,
        const Badge(
          leading: Component.text('L'),
          trailing: Component.text('R'),
          child: Component.text('A long review label'),
        ),
      );
      final fixedSlots = _spans().where(
        (span) => span.classes == 'inline-flex shrink-0',
      );
      expect(fixedSlots, hasLength(2));
      expect(find.text('L'), findsOneComponent);
      expect(find.text('R'), findsOneComponent);
    });
    testComponents('count keeps full DOM text in a bounded single line', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Badge(form: CoreBadgeForm.count, child: Component.text('123')),
      );
      expect(_spans(), hasLength(2));
      expect(_spans().last.classes, contains('overflow-hidden'));
      expect(_spans().last.classes, contains('text-ellipsis'));
      expect(_spans().last.classes, contains('whitespace-nowrap'));
      expect(_root().classes, contains('max-w-full'));
      expect(_root().classes, contains('box-border'));
      expect(find.text('123'), findsOneComponent);
    });
  });

  group('Badge rendering', () {
    for (final tone in CoreBadgeTone.values) {
      for (final variant in CoreBadgeVariant.values) {
        testComponents('renders $tone × $variant', (tester) async {
          final badge = Badge(
            tone: tone,
            variant: variant,
            child: const Component.text('Label'),
          );
          pumpWithTheme(tester, badge);

          expect(_spans(), hasLength(2));
          expect(find.text('Label'), findsOneComponent);
          // The root wears what the resolver states for this tone and
          // strength — a component that dropped either axis would paint
          // the default's chrome and fail here.
          final resolved = _resolvedFor(badge);
          expect(_root().classes, resolved.root.className);
          expect(
            _root().styles?.properties,
            resolved.root.inlineStyles?.properties,
          );
        });
      }
    }

    testComponents('renders the size it is given', (tester) async {
      const badge = Badge(
        size: CoreComponentSize.xs,
        form: CoreBadgeForm.count,
        child: Component.text('3'),
      );
      pumpWithTheme(tester, badge);

      final classes = _root().classes!.split(' ');
      expect(classes, containsAll(['min-h-size18', 'min-w-size18']));
      expect(_root().classes, _resolvedFor(badge).root.className);
    });

    testComponents('count form draws its content', (tester) async {
      pumpWithTheme(
        tester,
        const Badge(form: CoreBadgeForm.count, child: Component.text('12')),
      );

      expect(find.text('12'), findsOneComponent);
    });

    // The dot's whole claim is that its box is the step's size, not the
    // content's. Both halves are asserted because either alone passes
    // for the wrong reason.
    testComponents('dot form draws no content', (tester) async {
      pumpWithTheme(
        tester,
        const Badge(
          form: CoreBadgeForm.dot,
          child: Component.text('should not render'),
        ),
      );

      expect(find.text('should not render'), findsNothing);
      expect(_spans(), hasLength(1));
    });
  });

  group('Badge showDot', () {
    testComponents(
      'draws one decorative dot before the leading slot and the label',
      (tester) async {
        pumpWithTheme(
          tester,
          const Badge(
            showDot: true,
            leading: Component.element(tag: 'i', id: 'lead'),
            child: Component.text('Done'),
          ),
        );

        final dots = _leadingDots();
        expect(dots, hasLength(1));
        final rootChildren = _root().children ?? const <Component>[];
        // The dot is the first content child — before `leading`, which
        // sits inside the slot's `IconTheme`.
        final dotIndex = rootChildren.indexWhere(
          (component) =>
              component is DomComponent &&
              component.attributes?['aria-hidden'] == 'true',
        );
        final leadIndex = rootChildren.indexWhere(
          (component) =>
              component is IconTheme &&
              component.child is DomComponent &&
              ((component.child as DomComponent).children!.single
                          as DomComponent)
                      .id ==
                  'lead',
        );
        expect(dotIndex, greaterThanOrEqualTo(0));
        expect(leadIndex, greaterThan(dotIndex));
        expect(find.text('Done'), findsOneComponent);
      },
    );

    testComponents('draws no dot when off', (tester) async {
      pumpWithTheme(tester, const Badge(child: Component.text('Tag')));

      expect(_leadingDots(), isEmpty);
    });

    testComponents('a count draws the dot too', (tester) async {
      pumpWithTheme(
        tester,
        const Badge(
          form: CoreBadgeForm.count,
          showDot: true,
          child: Component.text('3'),
        ),
      );

      expect(_leadingDots(), hasLength(1));
    });

    testComponents('the dot form draws no leading dot — it is a dot already', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Badge(form: CoreBadgeForm.dot, showDot: true),
      );

      expect(_leadingDots(), isEmpty);
      expect(_spans(), hasLength(1));
    });
  });

  group('Badge press', () {
    testComponents(
      'a static badge is not a button and carries no scoped rule or id',
      (tester) async {
        pumpWithTheme(tester, const Badge(child: Component.text('Tag')));

        final root = _root();
        expect(root.attributes?['role'], isNull);
        expect(root.attributes?['tabindex'], isNull);
        expect(root.id, isNull);
        expect(find.tag('style'), findsNothing);
      },
    );

    testComponents(
      'a pressable badge is a focusable button that scopes its state layer '
      'to its own id',
      (tester) async {
        pumpWithTheme(
          tester,
          Badge(
            id: 'press-me',
            onPressed: () {},
            child: const Component.text('Tag'),
          ),
        );

        final root = _root();
        expect(root.attributes?['role'], 'button');
        expect(root.attributes?['tabindex'], '0');
        expect(root.id, 'press-me');
        expect(find.tag('style'), findsOneComponent);
        // The rule names this badge's own id.
        expect(
          _scopedCss(),
          contains(':where(#press-me).$kWebSurfaceMarker:hover{'),
        );
        // A click presses it, and so do Enter and Space on the focused
        // badge — the keys a `<span role="button">` does not get from the
        // browser; the key-up and the blur clear the keyboard press.
        expect(
          root.events?.keys,
          containsAll(['click', 'keydown', 'keyup', 'focusout']),
        );
      },
    );

    testComponents("a caller's click handler runs, then the press", (
      tester,
    ) async {
      final calls = <String>[];
      pumpWithTheme(
        tester,
        Badge(
          onPressed: () => calls.add('press'),
          eventHandlers: {
            'click': [(_) => calls.add('caller')],
          },
          child: const Component.text('Tag'),
        ),
      );

      await tester.click(find.byType(Badge));

      expect(calls, ['caller', 'press']);
    });

    testComponents(
      'the slots take the step icon size and a stated icon colour from the '
      'ambient IconTheme',
      (tester) async {
        const iconStyle = CoreIconStyle(
          color: CoreColor.token(CoreColors.primary),
        );
        pumpWithTheme(
          tester,
          const Badge(
            size: CoreComponentSize.lg,
            leading: Component.element(tag: 'i', id: 'lead'),
            trailing: Component.element(tag: 'i', id: 'trail'),
            badgeStyle: CoreBadgeStyle(iconStyle: iconStyle),
            child: Component.text('Tag'),
          ),
        );

        final themes = find
            .byType(IconTheme)
            .evaluate()
            .map((element) => (element.component as IconTheme).data)
            .toList();
        expect(themes, hasLength(2));
        for (final data in themes) {
          expect(
            data.size,
            CoreBadgeStyle
                .defaultsBySize[CoreComponentSize.lg]!
                .iconStyle!
                .size,
          );
          expect(data.color, iconStyle.color);
        }
      },
    );

    testComponents('caller attributes and event handlers reach the root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Badge(
          attributes: const {'data-testid': 'status'},
          eventHandlers: {
            'mouseenter': [(_) {}],
          },
          child: const Component.text('Tag'),
        ),
      );

      final root = _root();
      expect(root.attributes?['data-testid'], 'status');
      expect(root.events, contains('mouseenter'));
    });
  });

  group('Badge copyWith', () {
    test('preserves the axes and the caller chrome', () {
      final original = Badge(
        tone: CoreBadgeTone.success,
        variant: CoreBadgeVariant.outlined,
        form: CoreBadgeForm.count,
        size: CoreComponentSize.lg,
        showDot: true,
        attributes: const {'data-testid': 'status'},
        eventHandlers: {
          'mouseenter': [(_) {}],
        },
        child: const Component.text('Original'),
      );
      final copy = original.copyWith(id: 'new-id');

      expect(copy.id, 'new-id');
      expect(copy.tone, CoreBadgeTone.success);
      expect(copy.variant, CoreBadgeVariant.outlined);
      expect(copy.form, CoreBadgeForm.count);
      expect(copy.size, CoreComponentSize.lg);
      expect(copy.showDot, isTrue);
      expect(copy.userAttributes, {'data-testid': 'status'});
      expect(copy.eventHandlers.keys, contains('mouseenter'));
    });

    test('replaces tone and showDot', () {
      final copy = const Badge(
        child: Component.text('Tag'),
      ).copyWith(tone: CoreBadgeTone.warning, showDot: true);

      expect(copy.tone, CoreBadgeTone.warning);
      expect(copy.showDot, isTrue);
    });
  });

  group('BadgeStyleChain', () {
    test(
      'withStyle merges patch into badgeStyle and preserves other fields',
      () {
        const badge = Badge(
          tone: CoreBadgeTone.primary,
          size: CoreComponentSize.lg,
          child: Component.text('New'),
        );

        final patched = badge.withStyle(
          const CoreBadgeStyle(borderRadius: CoreBorderRadius.all(4)),
        );

        expect(patched.tone, CoreBadgeTone.primary);
        expect(patched.size, CoreComponentSize.lg);
        expect(patched.badgeStyle?.borderRadius, const CoreBorderRadius.all(4));
      },
    );

    test('later withStyle call wins on conflicting fields', () {
      const badge = Badge(child: Component.text('New'));

      final patched = badge
          .withStyle(const CoreBadgeStyle(borderWidth: 1))
          .withStyle(const CoreBadgeStyle(borderWidth: 2));

      expect(patched.badgeStyle?.borderWidth, 2);
    });
  });
}
