import 'package:coui_web/coui_web.dart';
// pagination_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/pagination/pagination_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolvePagination` / `resolvePaginationRules` directly.
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

/// A raw (token-less) colour — the exact case that used to throw
/// `token!.name` when routed onto a pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

void main() {
  group('Pagination hover colour — default (class-safe) path', () {
    testComponents(
      'inactive-enabled button keeps the hover:bg-* / hover:text-* utility '
      'classes and emits no scoped rule (output-equivalent to pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePagination(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('hover:bg-surface-container-high'),
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('hover:text-on-surface'),
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          isNot(contains('co-pagination-h-')),
        );

        final rules = resolvePaginationRules(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );
        expect(rules.css, isEmpty);
      },
    );
  });

  group('Pagination hover colour — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverBackgroundColor override no longer throws — the hover:bg-* '
      'class is dropped, the shared scope class is added, and the colour '
      'paints via a scoped .co-pagination-h:hover rule instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePaginationStyle(hoverBackgroundColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final resolved = resolvePagination(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-raw',
          paginationStyle: style,
        );
        // The raw background cannot ride a class, so `hover:bg-*` is
        // dropped and the shared scope class carries the rule instead.
        expect(
          resolved.buttonInactiveEnabled.className,
          isNot(contains('hover:bg-')),
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('co-pagination-h-co-pagination-raw'),
        );
        // The untouched hover text colour stays on its token class.
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('hover:text-on-surface'),
        );

        final rules = resolvePaginationRules(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-raw',
          paginationStyle: style,
        );
        expect(rules.css, contains('.co-pagination-h-co-pagination-raw:hover'));
        expect(rules.css, contains('background-color'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );

    testComponents(
      'a raw hoverTextStyle.color override also routes to the scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CorePaginationStyle(
          hoverTextStyle: CoreTextStyle(color: _kRawGreen),
        );
        final resolved = resolvePagination(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-fg',
          paginationStyle: style,
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          isNot(contains('hover:text-')),
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('co-pagination-h-co-pagination-fg'),
        );

        final rules = resolvePaginationRules(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-fg',
          paginationStyle: style,
        );
        expect(rules.css, contains('color'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );
  });

  group('Pagination label mode (#5352)', () {
    testComponents(
      'previous / next chrome for showLabel drops the square width for '
      'the label padding and keeps the page-button height',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePagination(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );
        final square = resolved.buttonInactiveEnabled.inlineStyles!.properties;
        for (final label in [
          resolved.labelButtonInactiveEnabled,
          resolved.labelButtonInactiveDisabled,
        ]) {
          final properties = label.inlineStyles!.properties;
          expect(properties, isNot(contains('width')));
          expect(properties['height'], square['height']);
          expect(
            properties['padding'],
            CorePaginationStyle.defaultLabelButtonPadding.toValue(),
          );
        }
        // Same state classes as the square bundles — only the box differs.
        expect(
          resolved.labelButtonInactiveEnabled.className,
          resolved.buttonInactiveEnabled.className,
        );
        expect(
          resolved.labelButtonInactiveDisabled.className,
          resolved.buttonInactiveDisabled.className,
        );
      },
    );

    testComponents('a labelButtonPadding override reaches the label chrome', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const padding = CoreEdgeInsets.symmetric(horizontal: CoreSpace.space16);
      final resolved = resolvePagination(
        context,
        variant: CorePaginationVariant.defaultVariant,
        scopeId: 'co-pagination-test',
        paginationStyle: const CorePaginationStyle(labelButtonPadding: padding),
      );
      expect(
        resolved.labelButtonInactiveEnabled.inlineStyles!.properties['padding'],
        padding.toValue(),
      );
    });
  });

  group('Pagination fit probe (#5364)', () {
    testComponents(
      'the probe is out of flow, zero-size, clipped and never painted; '
      'each probe row is the root row at its max-content width',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolvePagination(
          context,
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );
        final probe = resolved.fitProbe.className.split(' ');
        expect(
          probe,
          containsAll(['absolute', 'invisible', 'overflow-hidden']),
        );
        expect(resolved.fitProbe.inlineStyles?.properties, {
          'width': '0',
          'height': '0',
        });
        expect(
          resolved.fitProbeRow.className,
          '${resolved.root.className} w-max',
        );
        expect(
          resolved.fitProbeRow.inlineStyles?.properties,
          resolved.root.inlineStyles?.properties,
        );
      },
    );

    testComponents(
      'the server render is the full row with no probe',
      (tester) async {
        pumpWithTheme(
          tester,
          const Pagination(page: 5, totalPages: 10, showLabel: true),
        );
        expect(find.text('Previous'), findsOneComponent);
        expect(find.text('Next'), findsOneComponent);
        for (final page in ['1', '4', '5', '6', '10']) {
          expect(find.text(page), findsOneComponent, reason: 'page $page');
        }
      },
    );
  });

  group('Pagination button text style — colour stripped, box kept', () {
    testComponents(
      'a stated line box survives the colour strip and reaches the button',
      (tester) async {
        // The overlay is rebuilt field by field to drop its colour; a field
        // the rebuild forgets is silently lost on Web only.
        final resolved = resolvePagination(
          _themedContext(tester),
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
          paginationStyle: const CorePaginationStyle(
            buttonTextStyle: CoreTextStyle(
              color: _kRawGreen,
              lineHeightPx: CoreLineBox.px21,
            ),
          ),
        );
        expect(
          resolved.buttonActive.inlineStyles!.properties['line-height'],
          CssVariableGenerator.roundToPixelCss('1.3125rem'),
        );
      },
    );
  });

  group('Pagination redesign (#5965)', () {
    ResolvedPagination resolveDefault(ComponentTester tester) =>
        resolvePagination(
          _themedContext(tester),
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );

    testComponents(
      'numbers are body-medium on-surface-variant, the current page '
      'label-large semibold on-primary',
      (tester) async {
        final resolved = resolveDefault(tester);
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('text-body-medium'),
        );
        expect(
          resolved.buttonInactiveEnabled.className,
          contains('text-on-surface-variant'),
        );
        expect(resolved.buttonActive.className, contains('text-label-large'));
        expect(
          resolved.buttonActive.className,
          isNot(contains('text-body-medium')),
        );
        expect(resolved.buttonActive.className, contains('text-on-primary'));
        expect(
          resolved.buttonActive.inlineStyles!.properties['font-weight'],
          '600',
        );
        // The other numbers state no weight of their own.
        expect(
          resolved
              .buttonInactiveEnabled
              .inlineStyles!
              .properties['font-weight'],
          isNull,
        );
      },
    );

    testComponents(
      'the ellipsis shares the button typography and is on-surface-subtle',
      (tester) async {
        final resolved = resolveDefault(tester);
        expect(resolved.ellipsis.className, contains('text-body-medium'));
        expect(resolved.ellipsis.className, contains('text-on-surface-subtle'));
      },
    );

    testComponents(
      'a cell is 36 square, the row gap is 4, the chevron is 16',
      (tester) async {
        final resolved = resolveDefault(tester);
        expect(
          resolved.buttonActive.inlineStyles!.properties['width'],
          '2.25rem',
        );
        expect(
          resolved.buttonActive.inlineStyles!.properties['height'],
          '2.25rem',
        );
        expect(
          resolved.root.inlineStyles!.properties['gap'],
          contains('space-4'),
        );
        expect(resolved.iconStyle.size, 16);
      },
    );

    testComponents(
      'the focus ring is drawn around a radius-8 cell',
      (tester) async {
        final resolved = resolveDefault(tester);
        expect(
          resolved.clickableStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius8),
        );
      },
    );

    testComponents(
      'a stated size on buttonTextStyle reaches the current page too',
      (tester) async {
        final resolved = resolvePagination(
          _themedContext(tester),
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
          paginationStyle: const CorePaginationStyle(
            buttonTextStyle: CoreTextStyle(fontSize: 16),
          ),
        );
        expect(
          resolved.buttonInactiveEnabled.inlineStyles!.properties['font-size'],
          isNotNull,
        );
        expect(
          resolved.buttonActive.inlineStyles!.properties['font-size'],
          resolved.buttonInactiveEnabled.inlineStyles!.properties['font-size'],
        );
      },
    );
  });

  group('Pagination disabled (#5965)', () {
    testComponents(
      'every button takes the disabled content colour, the current page sits '
      'on the disabled container, and none has a hover class',
      (tester) async {
        final resolved = resolvePagination(
          _themedContext(tester),
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
        );
        for (final chrome in [
          resolved.buttonActiveDisabled,
          resolved.buttonDisabled,
          resolved.labelButtonDisabled,
          resolved.ellipsisDisabled,
        ]) {
          expect(chrome.className, contains('text-disabled-content'));
          expect(chrome.className, isNot(contains('hover:')));
          expect(chrome.className, isNot(contains('text-on-surface')));
        }
        expect(
          resolved.buttonActiveDisabled.className,
          contains('bg-disabled-container'),
        );
        expect(
          resolved.buttonActiveDisabled.className,
          isNot(contains('bg-primary')),
        );
      },
    );

    testComponents(
      'a caller colour does not survive disabled',
      (tester) async {
        final resolved = resolvePagination(
          _themedContext(tester),
          variant: CorePaginationVariant.defaultVariant,
          scopeId: 'co-pagination-test',
          paginationStyle: const CorePaginationStyle(
            textStyle: CoreTextStyle(color: _kRawGreen),
            ellipsisStyle: CoreTextStyle(color: _kRawGreen),
          ),
        );
        expect(
          resolved.buttonDisabled.className,
          contains('text-disabled-content'),
        );
        expect(
          resolved.buttonDisabled.inlineStyles!.properties['color'],
          isNull,
        );
        expect(
          resolved.ellipsisDisabled.className,
          contains('text-disabled-content'),
        );
      },
    );

    List<DomComponent> byAttribute(
      ComponentTester tester,
      String attribute,
      String value,
    ) => find
        .byComponentPredicate((c) => c is DomComponent)
        .evaluate()
        .map((element) => element.component as DomComponent)
        .where((dom) => dom.attributes?[attribute] == value)
        .toList();

    testComponents(
      'enabled follows the handler: no handler → no Clickable, '
      'aria-disabled on the buttons and the root',
      (tester) async {
        pumpWithTheme(
          tester,
          const Pagination(page: 5, totalPages: 10),
        );
        // Root + every button — and nothing is a live `tabindex` button.
        expect(byAttribute(tester, 'aria-disabled', 'true'), isNotEmpty);
        expect(byAttribute(tester, 'tabindex', '0'), isEmpty);
        expect(
          byAttribute(tester, 'aria-current', 'page'),
          hasLength(1),
          reason: 'the current page still says so',
        );
      },
    );

    testComponents(
      'an enabled pagination with a handler renders live buttons',
      (tester) async {
        pumpWithTheme(
          tester,
          Pagination(page: 5, totalPages: 10, onPageChanged: (_) {}),
        );
        expect(byAttribute(tester, 'aria-disabled', 'true'), isEmpty);
      },
    );

    testComponents(
      'an explicit enabled: false disables even with a handler',
      (tester) async {
        pumpWithTheme(
          tester,
          Pagination(
            page: 5,
            totalPages: 10,
            enabled: false,
            onPageChanged: (_) {},
          ),
        );
        expect(byAttribute(tester, 'tabindex', '0'), isEmpty);
        expect(byAttribute(tester, 'aria-disabled', 'true'), isNotEmpty);
      },
    );
  });
}
