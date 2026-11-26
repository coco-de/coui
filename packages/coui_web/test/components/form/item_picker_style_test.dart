import 'package:coui_web/coui_web.dart';
// item_picker_style.dart is not re-exported by the barrel (the resolver is
// internal chrome) — import it directly for resolver-level assertions.
import 'package:coui_web/src/components/form/item_picker/item_picker_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveItemPickerOption` / `resolveItemPickerRules` directly.
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
/// `token!.name` when routed onto a `hover:` pseudo-state Tailwind class.
const _kRawGreen = CoreColor(0xFF00FF00);

/// The frame's `className` as a set of whole classes. A substring assertion
/// cannot tell `hover:border-on-surface` from a class that merely contains
/// it, and this axis is exactly about which classes are present.
Set<String> _frameClasses(
  BuildContext context, {
  bool enabled = true,
  String scopeId = 'co-item-picker-frame-test',
  CoreItemPickerStyle? style,
}) => resolveItemPicker(
  context,
  enabled: enabled,
  scopeId: scopeId,
  itemPickerStyle: style,
).root.className.split(' ').where((c) => c.isNotEmpty).toSet();

/// Every `<div>` in the pumped tree, for class / child assertions.
Iterable<DomComponent> _divs(ComponentTester tester) =>
    find.tag('div').evaluate().map((e) => e.component as DomComponent);

/// The text of every `<style>` element in the pumped tree.
Iterable<String> _styleTexts(ComponentTester tester) => find
    .tag('style')
    .evaluate()
    .map((e) => e.component as DomComponent)
    .map((style) => (style.children?.first as RawText?)?.text ?? '');

void main() {
  group('ItemPicker option hover — default (token) path', () {
    testComponents(
      'an enabled, unselected option keeps the hover:bg-* / hover:text-* '
      'utility classes and emits no scoped rule (output-equivalent to '
      'pre-change)',
      (tester) async {
        final context = _themedContext(tester);
        final option = resolveItemPickerOption(
          context,
          selected: false,
          enabled: true,
          scopeId: 'co-item-picker-test',
        );
        expect(
          option.root.className,
          contains('hover:bg-surface-container-high'),
        );
        expect(option.root.className, contains('hover:text-on-surface'));
        expect(
          option.root.className,
          isNot(contains('co-item-picker-h-')),
        );

        final rules = resolveItemPickerRules(
          context,
          scopeId: 'co-item-picker-test',
          enabled: true,
        );
        expect(rules.css, isEmpty);
      },
    );

    testComponents('a disabled picker emits no hover class + no scoped rule', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final option = resolveItemPickerOption(
        context,
        selected: false,
        enabled: false,
        scopeId: 'co-item-picker-test',
      );
      expect(option.root.className, isNot(contains('hover:bg-')));
      expect(option.root.className, isNot(contains('hover:text-')));

      final rules = resolveItemPickerRules(
        context,
        scopeId: 'co-item-picker-test',
        enabled: false,
      );
      expect(rules.css, isEmpty);
    });

    testComponents('a disabled option draws its text and check in the disabled '
        'foreground; an enabled one keeps its own', (tester) async {
      final context = _themedContext(tester);
      final disabled = resolveItemPickerOption(
        context,
        selected: true,
        enabled: false,
        scopeId: 'co-item-picker-test',
      );
      final resting = resolveItemPickerOption(
        context,
        selected: false,
        enabled: false,
        scopeId: 'co-item-picker-test',
      );
      final enabled = resolveItemPickerOption(
        context,
        selected: false,
        enabled: true,
        scopeId: 'co-item-picker-test',
      );

      expect(resting.root.className, contains('text-disabled-content'));
      expect(resting.root.className, isNot(contains('text-on-surface')));
      expect(disabled.root.className, contains('text-disabled-content'));
      expect(
        disabled.checkIconStyle.color,
        CoreItemPickerStyle.defaultDisabledForegroundColor,
      );
      expect(enabled.root.className, contains('text-on-surface'));
      expect(
        enabled.checkIconStyle.color,
        CoreItemPickerStyle.defaultCheckColor,
      );
    });

    testComponents('a disabled picker draws its title and empty-state line in '
        'the disabled foreground; an enabled one keeps their own', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final enabled = resolveItemPicker(context);
      final disabled = resolveItemPicker(context, enabled: false);

      final disabledTitle = disabled.title.className.split(' ');
      final disabledEmpty = disabled.empty.className.split(' ');
      expect(disabledTitle, contains('text-disabled-content'));
      expect(disabledTitle, isNot(contains('text-on-surface')));
      expect(disabledEmpty, contains('text-disabled-content'));
      expect(disabledEmpty, isNot(contains('text-on-surface-variant')));
      expect(
        enabled.title.className.split(' '),
        contains('text-on-surface-subtle'),
      );
      expect(
        enabled.empty.className.split(' '),
        contains('text-on-surface-variant'),
      );
    });

    testComponents('the section label is labelSmall in onSurfaceSubtle at '
        'its own weight, inset 6 / 4 / 8, spanning the list (#5884)', (
      tester,
    ) async {
      final resolved = resolveItemPicker(_themedContext(tester));

      // Exactly the role and colour classes — no weight overlay.
      expect(resolved.title.className.split(' ').toSet(), {
        'text-label-small',
        'text-on-surface-subtle',
      });
      final inline = resolved.title.inlineStyles!.properties;
      expect(
        inline['padding'],
        CoreItemPickerStyle.defaultTitlePadding.toValue(),
      );
      expect(inline['grid-column'], '1 / -1');
      expect(inline.containsKey('font-weight'), isFalse);
      expect(inline.containsKey('font-size'), isFalse);
    });
  });

  group('ItemPicker option hover — raw override (scoped-rule) path', () {
    testComponents(
      'a raw optionHoverColor override no longer throws — the hover:bg-* '
      'class is dropped, the option carries the shared scope class, and the '
      'hover background paints via a scoped .co-item-picker-h:hover rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreItemPickerStyle(optionHoverColor: _kRawGreen);

        // Before the fix this call threw a null-check on `token!.name`.
        final option = resolveItemPickerOption(
          context,
          selected: false,
          enabled: true,
          scopeId: 'co-item-picker-raw',
          itemPickerStyle: style,
        );
        // The raw background colour cannot ride a Tailwind class, so the
        // `hover:bg-*` utility is dropped in favour of the scoped rule…
        expect(option.root.className, isNot(contains('hover:bg-')));
        // …while the still-token hover text keeps its class…
        expect(option.root.className, contains('hover:text-on-surface'));
        // …and the option carries the shared scope class.
        expect(
          option.root.className,
          contains('co-item-picker-h-co-item-picker-raw'),
        );

        final rules = resolveItemPickerRules(
          context,
          scopeId: 'co-item-picker-raw',
          enabled: true,
          itemPickerStyle: style,
        );
        expect(
          rules.css,
          contains('.co-item-picker-h-co-item-picker-raw:hover'),
        );
        expect(rules.css, contains('background-color'));
        expect(rules.css, contains('rgb(0, 255, 0)'));
      },
    );

    testComponents(
      'a raw optionHoverTextStyle.color override also drops its class and '
      'routes the text colour to the scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreItemPickerStyle(
          optionHoverTextStyle: CoreTextStyle(color: _kRawGreen),
        );

        final option = resolveItemPickerOption(
          context,
          selected: false,
          enabled: true,
          scopeId: 'co-item-picker-txt',
          itemPickerStyle: style,
        );
        expect(option.root.className, isNot(contains('hover:text-')));
        expect(
          option.root.className,
          contains('hover:bg-surface-container-high'),
        );
        expect(
          option.root.className,
          contains('co-item-picker-h-co-item-picker-txt'),
        );

        final rules = resolveItemPickerRules(
          context,
          scopeId: 'co-item-picker-txt',
          enabled: true,
          itemPickerStyle: style,
        );
        expect(rules.css, contains('color: rgb(0, 255, 0)'));
      },
    );
  });

  // The picker frame is a box of its own around the title, the search field
  // and the options; hover steps its border: `disabled > hover > rest`. The
  // frame has no container-level focus or error state (the search field is a
  // composed `TextField` that owns its own), so there is no `focus-within:`
  // utility whose cascade order against `hover:` needs guarding.
  group('ItemPicker frame hover border — default (class) path', () {
    testComponents(
      'the frame steps via hover:border-outline and emits no scoped rule',
      (tester) async {
        final context = _themedContext(tester);
        final classes = _frameClasses(context);

        expect(classes, contains('border-outline-variant'));
        expect(classes, contains('hover:border-outline'));
        expect(
          classes.where((c) => c.startsWith('co-item-picker-frame-')),
          isEmpty,
          reason: 'no scope class when nothing is scoped',
        );
        expect(
          resolveItemPickerRules(
            context,
            scopeId: 'co-item-picker-frame-test',
            enabled: true,
          ).css,
          isEmpty,
        );
      },
    );

    testComponents('a disabled picker has no frame hover step at all', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreItemPickerStyle(hoverBorderColor: _kRawGreen);

      expect(
        _frameClasses(context, enabled: false).where(
          (c) => c.contains('hover:') || c.startsWith('co-item-picker-frame-'),
        ),
        isEmpty,
      );
      expect(
        resolveItemPickerRules(
          context,
          scopeId: 'co-item-picker-frame-test',
          enabled: false,
          itemPickerStyle: style,
        ).css,
        isEmpty,
      );
    });

    testComponents('a token hoverBorderColor override rides its own class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreItemPickerStyle(
        hoverBorderColor: CoreColor.token(CoreColors.error),
      );
      final classes = _frameClasses(context, style: style);

      expect(classes, contains('hover:border-error'));
      expect(classes, isNot(contains('hover:border-on-surface')));
    });

    testComponents('a theme-level hoverBorderColor reaches the frame', (
      tester,
    ) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          itemPicker: CoreItemPickerTheme(
            style: CoreItemPickerStyle(
              hoverBorderColor: CoreColor.token(CoreColors.success),
            ),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themedData, child: _ContextCapture((c) => context = c)),
      );

      expect(_frameClasses(context), contains('hover:border-success'));
    });

    testComponents('the option hover utilities are untouched by the frame', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final option = resolveItemPickerOption(
        context,
        selected: false,
        enabled: true,
        scopeId: 'co-item-picker-frame-test',
      );

      // The panel's border step and an option's background step are
      // different properties on different elements — neither may leak into
      // the other.
      expect(option.root.className, isNot(contains('hover:border-')));
      expect(
        option.root.className,
        contains('hover:bg-surface-container-high'),
      );
    });
  });

  group('ItemPicker frame hover border — raw override (scoped-rule) path', () {
    testComponents(
      'a raw hoverBorderColor no longer throws — the hover class is dropped, '
      'the frame carries its scope class and the border steps via a scoped '
      'rule',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreItemPickerStyle(hoverBorderColor: _kRawGreen);

        // Before the emit family this was a render-time null check on
        // `token!.name`.
        final classes = _frameClasses(
          context,
          scopeId: 'co-item-picker-raw',
          style: style,
        );
        expect(classes.where((c) => c.contains('hover:')), isEmpty);
        expect(classes, contains('co-item-picker-frame-co-item-picker-raw'));

        final rules = resolveItemPickerRules(
          context,
          scopeId: 'co-item-picker-raw',
          enabled: true,
          itemPickerStyle: style,
        );
        expect(
          rules.css,
          contains(
            '.co-item-picker-frame-co-item-picker-raw:hover'
            '{border-color: rgb(0, 255, 0);}',
          ),
        );
        // The resting border is a class here, so the rule needs no help.
        expect(rules.css, isNot(contains('!important')));
      },
    );

    testComponents(
      'a raw resting borderColor is inline, so the hover step has to be '
      '!important or it never shows',
      (tester) async {
        final context = _themedContext(tester);
        const style = CoreItemPickerStyle(borderColor: _kRawGreen);

        // Nothing for a class to step: the inline border beats every class.
        final classes = _frameClasses(
          context,
          scopeId: 'co-item-picker-rawrest',
          style: style,
        );
        expect(classes.where((c) => c.contains('hover:')), isEmpty);
        expect(
          classes,
          contains('co-item-picker-frame-co-item-picker-rawrest'),
        );

        expect(
          resolveItemPickerRules(
            context,
            scopeId: 'co-item-picker-rawrest',
            enabled: true,
            itemPickerStyle: style,
          ).css,
          contains(
            '.co-item-picker-frame-co-item-picker-rawrest:hover'
            '{border-color: rgb(var(--coui-outline)) !important;}',
          ),
        );
      },
    );

    testComponents('the frame rule shares its <style> with the option rules', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final rules = resolveItemPickerRules(
        context,
        scopeId: 'co-item-picker-both',
        enabled: true,
        itemPickerStyle: const CoreItemPickerStyle(
          hoverBorderColor: _kRawGreen,
          optionHoverColor: _kRawGreen,
        ),
      );

      expect(
        rules.css,
        contains('.co-item-picker-frame-co-item-picker-both:hover'),
      );
      expect(
        rules.css,
        contains('.co-item-picker-h-co-item-picker-both:hover'),
      );
    });
  });

  group('ItemPicker frame hover border — scoped-rule wiring', () {
    testComponents('the default path renders no frame <style> and no frame '
        'scope class', (tester) async {
      pumpWithTheme(tester, const ItemPicker(items: ['a']));

      // The search field inside the picker carries its own `<style>` (the
      // focused boundary's rule); none of them is the frame's hover rule.
      expect(
        _styleTexts(tester),
        everyElement(isNot(contains('.co-item-picker-frame-'))),
      );
      expect(
        _divs(tester).map((d) => d.classes ?? ''),
        everyElement(isNot(contains('co-item-picker-frame-'))),
      );
    });

    testComponents(
      'a raw hover override renders the <style> child and the frame carries '
      'the class the rule targets',
      (tester) async {
        pumpWithTheme(
          tester,
          const ItemPicker(
            items: ['a'],
            itemPickerStyle: CoreItemPickerStyle(hoverBorderColor: _kRawGreen),
          ),
        );

        final frameStyles = _styleTexts(
          tester,
        ).where((css) => css.contains('.co-item-picker-frame-'));
        expect(frameStyles, hasLength(1));

        final frames = _divs(
          tester,
        ).where((d) => (d.classes ?? '').contains('co-item-picker-frame-'));
        expect(frames, hasLength(1));
        // The selector and the element have to agree — a rule that names a
        // class nothing carries paints nothing, and it looks fine in the
        // resolver test.
        final frameClass = frames.single.classes!
            .split(' ')
            .singleWhere((c) => c.startsWith('co-item-picker-frame-'));
        expect(frameStyles.single, contains('.$frameClass:hover'));
      },
    );

    testComponents('a disabled picker renders no hover <style> at all', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const ItemPicker(
          items: ['a'],
          enabled: false,
          itemPickerStyle: CoreItemPickerStyle(hoverBorderColor: _kRawGreen),
        ),
      );

      expect(find.tag('style'), findsNothing);
    });
  });

  group('ItemPicker redesign (#5831) — the floating panel', () {
    testComponents('the frame is the bright face with the quiet line, '
        'corner 12 and the strong cast', (tester) async {
      final root = resolveItemPicker(_themedContext(tester)).root;
      final classes = root.className.split(' ');

      expect(classes, contains('bg-surface-bright'));
      expect(classes, contains('border-outline-variant'));
      expect(classes, contains('shadow-lg'));
      expect(classes, isNot(contains(kControlShadowRestMarker)));
      expect(
        root.inlineStyles!.properties['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.panel).toValue(),
      );
    });

    testComponents('the search is the bare field with a quiet search glyph '
        'and a hairline divider', (tester) async {
      final resolved = resolveItemPicker(_themedContext(tester));

      expect(resolved.searchIconStyle.size, 16);
      expect(
        resolved.searchIconStyle.color,
        const CoreColor.token(CoreColors.onSurfaceSubtle),
      );
      expect(resolved.searchDividerStyle, const CoreDividerStyle());
      expect(
        resolved.searchFieldStyle.padding,
        const CoreEdgeInsets.symmetric(
          horizontal: CoreSpace.space14,
          vertical: CoreSpace.space8,
        ),
      );
    });

    testComponents('a disabled picker greys the search glyph', (
      tester,
    ) async {
      final resolved = resolveItemPicker(
        _themedContext(tester),
        enabled: false,
      );

      expect(
        resolved.searchIconStyle.color,
        const CoreColor.token(CoreColors.disabledContent),
      );
    });

    testComponents(
      'a disabled picker preserves an explicit nested icon color',
      (
        tester,
      ) async {
        final resolved = resolveItemPicker(
          _themedContext(tester),
          enabled: false,
          itemPickerStyle: const CoreItemPickerStyle(
            searchIconStyle: CoreIconStyle(color: _kRawGreen),
          ),
        );

        expect(resolved.searchIconStyle.color, _kRawGreen);
      },
    );

    testComponents('the list is inset 6; rows are 8 padded with corner 8, '
        'in bodyMedium', (tester) async {
      final context = _themedContext(tester);
      final items = resolveItemPickerItems(
        context,
        layout: CoreItemPickerLayout.list,
        gridColumns: 3,
      );
      expect(
        items.root.inlineStyles!.properties['padding'],
        const CoreEdgeInsets.all(CoreSpace.space6).toValue(),
      );

      final option = resolveItemPickerOption(
        context,
        selected: false,
        enabled: true,
        scopeId: 'co-item-picker-test',
      );
      final inline = option.root.inlineStyles!.properties;
      expect(
        inline['padding'],
        const CoreEdgeInsets.all(CoreSpace.space8).toValue(),
      );
      expect(
        inline['border-radius'],
        const CoreBorderRadius.all(CoreRadiusRole.control).toValue(),
      );
      expect(option.root.className, contains('text-body-medium'));
    });

    testComponents('the selected row has no fill, and its check is primary', (
      tester,
    ) async {
      final option = resolveItemPickerOption(
        _themedContext(tester),
        selected: true,
        enabled: true,
        scopeId: 'co-item-picker-test',
      );

      expect(option.root.className, isNot(contains('bg-surface-container')));
      expect(
        option.checkIconStyle.color,
        const CoreColor.token(CoreColors.primary),
      );
    });
  });
}
