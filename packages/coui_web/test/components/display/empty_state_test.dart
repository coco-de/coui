import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

Iterable<Map<String, String>> _attributes(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((c) => c.attributes ?? const {});

Finder _divWithClass(String cls) => find.byComponentPredicate(
  (c) => c is div && (c.classes?.split(' ').contains(cls) ?? false),
);

Iterable<String?> _texts(ComponentTester tester) => find
    .byType(Text)
    .evaluate()
    .map((e) => e.component as Text)
    .map((t) => t.data);

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

String? _weightOf(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties['font-weight'];

void main() {
  group('EmptyState', () {
    test('default variant is normal', () {
      final emptyState = EmptyState(title: const Text('No results found'));
      expect(emptyState.variant, equals(CoreEmptyStateVariant.normal));
    });

    test('compact constructor sets compact variant', () {
      final emptyState = EmptyState.compact(title: const Text('No results'));
      expect(emptyState.variant, equals(CoreEmptyStateVariant.compact));
    });

    test('default tone is neutral', () {
      final emptyState = EmptyState(title: const Text('No results found'));
      expect(emptyState.tone, equals(CoreEmptyStateTone.neutral));
    });

    testComponents('renders with required title', (tester) async {
      pumpWithTheme(tester, EmptyState(title: const Text('No results found')));

      expect(_texts(tester), contains('No results found'));
    });

    testComponents('renders with icon, description, action', (tester) async {
      pumpWithTheme(
        tester,
        EmptyState(
          title: const Text('No results found'),
          icon: const Icon(LucideIcons.searchX),
          description: const Text('Try adjusting your search'),
          action: Button(
            onPressed: () {},
            child: const Text('Clear filters'),
          ),
        ),
      );

      expect(_texts(tester), contains('No results found'));
      expect(_texts(tester), contains('Try adjusting your search'));
      expect(_texts(tester), contains('Clear filters'));
    });

    testComponents('compact variant pumps without errors', (tester) async {
      pumpWithTheme(
        tester,
        EmptyState.compact(title: const Text('No results')),
      );
    });

    // The title role is a row of `defaultsByVariant`, not a choice the
    // resolver makes — the Figma export reads that table, so a role picked
    // anywhere else reaches the screen and never the canvas.
    group('title role', () {
      testComponents('normal reads titleMedium', (tester) async {
        pumpWithTheme(
          tester,
          EmptyState(
            title: const Text('No results'),
          ),
        );
        await tester.pump();

        expect(_divWithClass('text-title-medium'), findsOneComponent);
        expect(_divWithClass('text-title-small'), findsNothing);
      });

      testComponents('compact reads titleSmall', (tester) async {
        pumpWithTheme(
          tester,
          EmptyState.compact(title: const Text('No results')),
        );
        await tester.pump();

        expect(_divWithClass('text-title-small'), findsOneComponent);
        expect(_divWithClass('text-title-medium'), findsNothing);
      });
    });

    group('tone', () {
      // "No orders yet" and "Could not load orders" are the same box of
      // text to a screen reader unless something says otherwise — only
      // one of them is news. Routed through the same seat the alert
      // uses so the two components cannot answer this differently
      // (widget/failure-surfaces.md).
      testComponents('failure tone announces itself via role="alert"', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          EmptyState(
            title: const Text('Could not load results'),
            tone: .failure,
          ),
        );

        final withAlertRole = _attributes(
          tester,
        ).where((attrs) => attrs['role'] == 'alert');
        expect(withAlertRole, isNotEmpty);
      });

      testComponents('neutral tone does not announce', (tester) async {
        pumpWithTheme(tester, EmptyState(title: const Text('No results yet')));

        final withAlertRole = _attributes(
          tester,
        ).where((attrs) => attrs['role'] == 'alert');
        expect(withAlertRole, isEmpty);
      });
    });
  });

  group('EmptyState icon box', () {
    const sizes = {
      CoreEmptyStateVariant.normal: ('4.0rem', '1.75rem'),
      CoreEmptyStateVariant.compact: ('3.0rem', '1.25rem'),
      CoreEmptyStateVariant.large: ('4.5rem', '2.0rem'),
    };
    for (final MapEntry(key: variant, value: (box, glyph)) in sizes.entries) {
      testComponents('${variant.name} box is a circle of $box', (tester) async {
        final resolved = resolveEmptyState(
          _themedContext(tester),
          variant: variant,
        );
        expect(resolved.iconBox.inlineStyles!.properties['width'], box);
        expect(resolved.iconBox.inlineStyles!.properties['height'], box);
        expect(resolved.iconBox.className, contains('rounded-'));
        expect(
          resolved.iconWrapper.inlineStyles!.properties['width'],
          glyph,
        );
      });
    }

    testComponents('success tone fills the box success-container', (
      tester,
    ) async {
      final resolved = resolveEmptyState(
        _themedContext(tester),
        variant: CoreEmptyStateVariant.normal,
        tone: .success,
      );
      expect(resolved.iconBox.className, contains('bg-success-container'));
      expect(resolved.iconWrapper.className, contains('text-success'));
    });
  });

  // The title states no weight of its own, so only the `text-{role}` class is
  // emitted and the role's semibold applies — the rule Card's header and
  // Footer's section title follow too. A caller's weight arrives inline and
  // wins.
  //
  // The Flutter twin (`coui_flutter/test/components/display/
  // empty_state_test.dart`) pins the same weights on the painted text.
  group('EmptyState title weight', () {
    final roles = {
      CoreEmptyStateVariant.normal: 'text-title-medium',
      CoreEmptyStateVariant.compact: 'text-title-small',
      CoreEmptyStateVariant.large: 'text-title-large',
    };

    test('both title roles are semibold', () {
      expect(
        CoreTypography.coui.titleMedium.fontWeight,
        CoreFontWeight.semiBold,
      );
      expect(
        CoreTypography.coui.titleSmall.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    test('title-large is semibold', () {
      expect(
        CoreTypography.coui.titleLarge.fontWeight,
        CoreFontWeight.semiBold,
      );
    });

    for (final MapEntry(key: variant, value: roleClass) in roles.entries) {
      testComponents('${variant.name} emits the role class and no weight', (
        tester,
      ) async {
        final resolved = resolveEmptyState(
          _themedContext(tester),
          variant: variant,
        );

        expect(resolved.title.className.split(' '), contains(roleClass));
        expect(resolved.title.className, isNot(contains('font-')));
        expect(_weightOf(resolved.title), isNull);
      });

      testComponents('${variant.name}: a titleTextStyle weight still wins', (
        tester,
      ) async {
        final resolved = resolveEmptyState(
          _themedContext(tester),
          variant: variant,
          emptyStateStyle: const CoreEmptyStateStyle(
            titleTextStyle: CoreTextStyle(fontWeight: CoreFontWeight.regular),
          ),
        );

        expect(resolved.title.className.split(' '), contains(roleClass));
        expect(_weightOf(resolved.title), '400');
      });
    }
  });

  group('EmptyState compact redesign (#6468)', () {
    testComponents('gaps 12 / 6 / 16 and a body-small description', (
      tester,
    ) async {
      final resolved = resolveEmptyState(
        _themedContext(tester),
        variant: CoreEmptyStateVariant.compact,
      );
      expect(resolved.iconTitleGapStyle.size, CoreSpace.space12);
      expect(resolved.titleDescriptionGapStyle.size, CoreSpace.space6);
      expect(resolved.descriptionActionGapStyle.size, CoreSpace.space16);
      expect(
        resolved.description.className.split(' '),
        contains('text-body-small'),
      );
    });
  });
}
