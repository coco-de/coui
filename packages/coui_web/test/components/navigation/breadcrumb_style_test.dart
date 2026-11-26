import 'package:coui_web/coui_web.dart';
// breadcrumb_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/navigation/breadcrumb/breadcrumb_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveBreadcrumb` / `resolveBreadcrumbRules` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// A raw (token-less) colour — the exact case that used to throw
/// `token!.name` when routed onto a `hover:text-*` Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

void main() {
  group('Breadcrumb hover colour — default (token) path', () {
    testComponents(
      'interactive item keeps the hover:text-* utility class and emits no '
      'scoped rule (output-equivalent to pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveBreadcrumb(
          context,
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
        );
        expect(resolved.itemInteractive.className, contains('hover:text-'));
        expect(
          resolved.itemInteractive.className,
          contains('transition-colors'),
        );
        expect(
          resolved.itemInteractive.className,
          isNot(contains('co-breadcrumb-h-')),
        );

        final rules = resolveBreadcrumbRules(
          context,
          variant: CoreBreadcrumbVariant.defaultVariant,
          scopeId: 'co-breadcrumb-test',
        );
        expect(rules.css, isEmpty);
      },
    );
  });

  group('Breadcrumb hover colour — raw override (scoped-rule) path', () {
    testComponents(
      'a raw itemHoverColor override no longer throws — the hover:text-* '
      'class is dropped, a shared scope class is added, and the colour '
      'paints via a class-scoped :hover rule instead',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreBreadcrumbStyle(itemHoverColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final resolved = resolveBreadcrumb(
          context,
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-raw',
          breadcrumbStyle: style,
        );
        // The colour class cannot carry a raw colour, so `hover:text-*` is
        // dropped in favour of the scope class targeted by the scoped rule.
        expect(
          resolved.itemInteractive.className,
          isNot(contains('hover:text-')),
        );
        expect(
          resolved.itemInteractive.className,
          contains('co-breadcrumb-h-co-breadcrumb-raw'),
        );

        final rules = resolveBreadcrumbRules(
          context,
          variant: CoreBreadcrumbVariant.defaultVariant,
          scopeId: 'co-breadcrumb-raw',
          breadcrumbStyle: style,
        );
        expect(rules.css, contains('.co-breadcrumb-h-co-breadcrumb-raw:hover'));
        expect(rules.css, contains('color'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );
  });

  group('Breadcrumb item text style — colour stripped, box kept', () {
    testComponents(
      'a stated line box survives the colour strip and reaches the item',
      (tester) async {
        // The overlay is rebuilt field by field to drop its colour; a field
        // the rebuild forgets is silently lost on Web only.
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
          breadcrumbStyle: const CoreBreadcrumbStyle(
            itemTextStyle: CoreTextStyle(
              color: _kRawGreen,
              lineHeightPx: CoreLineBox.px21,
            ),
          ),
        );
        expect(
          resolved.itemInteractive.inlineStyles!.properties['line-height'],
          CssVariableGenerator.roundToPixelCss('1.3125rem'),
        );
      },
    );
  });

  group('Breadcrumb redesign defaults (#5965)', () {
    testComponents(
      'link items are body-medium (Regular), the current item stays '
      'label-large (Medium), and both carry the 2 / 4 inset',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
        );
        expect(
          resolved.itemInteractive.className,
          contains('text-body-medium'),
        );
        expect(resolved.itemPlain.className, contains('text-body-medium'));
        expect(resolved.itemCurrent.className, contains('text-label-large'));
        expect(
          resolved.itemCurrent.className,
          isNot(contains('text-body-medium')),
        );
        for (final chrome in [
          resolved.itemInteractive,
          resolved.itemPlain,
          resolved.itemCurrent,
        ]) {
          // Default inset is a token class, never inline.
          expect(chrome.className, contains('pt-space2'));
          expect(chrome.className, contains('pb-space2'));
          expect(chrome.className, contains('pl-space4'));
          expect(chrome.className, contains('pr-space4'));
          expect(chrome.inlineStyles?.properties['padding'], isNull);
        }
      },
    );

    testComponents(
      'the separator is the decorative step and the gap is 4',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
        );
        expect(
          resolved.separatorIconStyle.color,
          const CoreColor.token(CoreColors.onSurfaceSubtle),
        );
        expect(resolved.itemSeparatorGapStyle.size, CoreSpace.space4);
      },
    );

    testComponents(
      'the focus ring is drawn around a radius-6 item (ring corner 10)',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
        );
        expect(
          resolved.clickableStyle.borderRadius,
          const CoreBorderRadius.all(CoreRadius.radius6),
        );
        // Press-shrink stays off for inline links.
        expect(resolved.clickableStyle.pressedScale, 1);
      },
    );

    testComponents(
      'a caller-stated inset goes inline instead of the token class',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: true,
          scopeId: 'co-breadcrumb-test',
          breadcrumbStyle: const CoreBreadcrumbStyle(
            itemPadding: CoreEdgeInsets.all(CoreSpace.space8),
          ),
        );
        expect(resolved.itemInteractive.className, isNot(contains('pt-')));
        expect(
          resolved.itemInteractive.inlineStyles!.properties['padding'],
          isNotNull,
        );
      },
    );
  });

  group('Breadcrumb disabled (#5965)', () {
    testComponents(
      'every item and the separator take the disabled content colour',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: false,
          scopeId: 'co-breadcrumb-test',
        );
        for (final chrome in [resolved.itemPlain, resolved.itemCurrent]) {
          expect(chrome.className, contains('text-disabled-content'));
          expect(chrome.className, isNot(contains('text-on-surface')));
        }
        expect(
          resolved.separatorIconStyle.color,
          const CoreColor.token(CoreColors.disabledContent),
        );
      },
    );

    testComponents(
      'a caller colour does not survive disabled',
      (tester) async {
        final resolved = resolveBreadcrumb(
          _themedContext(tester),
          variant: CoreBreadcrumbVariant.defaultVariant,
          enabled: false,
          scopeId: 'co-breadcrumb-test',
          breadcrumbStyle: const CoreBreadcrumbStyle(
            itemColor: _kRawGreen,
            currentItemColor: _kRawGreen,
            separatorIconStyle: CoreIconStyle(color: _kRawGreen),
          ),
        );
        expect(resolved.itemPlain.className, contains('text-disabled-content'));
        expect(resolved.itemPlain.inlineStyles, isNull);
        expect(
          resolved.separatorIconStyle.color,
          const CoreColor.token(CoreColors.disabledContent),
        );
      },
    );

    testComponents(
      'enabled follows the handler when unstated, and the widget renders '
      'no link for a disabled trail',
      (tester) async {
        pumpWithTheme(
          tester,
          const Breadcrumb(
            items: [
              CoreBreadcrumbItem(label: 'Home'),
              CoreBreadcrumbItem(label: 'Data'),
            ],
          ),
        );
        // No handler → disabled → no `role="link"` and the nav says so.
        expect(_domAttributes(tester, 'role', 'link'), isEmpty);
        expect(_domAttributes(tester, 'aria-disabled', 'true'), hasLength(1));
      },
    );

    testComponents(
      'an explicit enabled: true keeps a handler-less trail coloured',
      (tester) async {
        pumpWithTheme(
          tester,
          const Breadcrumb(
            enabled: true,
            items: [
              CoreBreadcrumbItem(label: 'Home'),
              CoreBreadcrumbItem(label: 'Data'),
            ],
          ),
        );
        expect(_domAttributes(tester, 'aria-disabled', 'true'), isEmpty);
      },
    );

    testComponents(
      'an enabled trail with a handler renders the links',
      (tester) async {
        pumpWithTheme(
          tester,
          Breadcrumb(
            onItemTap: (_) {},
            items: const [
              CoreBreadcrumbItem(label: 'Home'),
              CoreBreadcrumbItem(label: 'Data'),
            ],
          ),
        );
        expect(_domAttributes(tester, 'role', 'link'), hasLength(1));
        expect(_domAttributes(tester, 'aria-disabled', 'true'), isEmpty);
      },
    );
  });
}

/// DOM nodes in the pumped tree whose [attribute] equals [value].
List<DomComponent> _domAttributes(
  ComponentTester tester,
  String attribute,
  String value,
) {
  return find
      .byComponentPredicate((c) => c is DomComponent)
      .evaluate()
      .map((element) => element.component as DomComponent)
      .where((dom) => dom.attributes?[attribute] == value)
      .toList();
}
