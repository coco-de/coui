import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the [BuildContext] a real component tree resolves under so the
/// resolvers can be called directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.text('ok');
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

/// The whole classes of a composed `className` — `contains` on the string
/// would read `hover:text-primary` inside `hover:text-primary/5`.
List<String> _classes(String className) => className.split(' ');

List<String> _hoverClasses(String className) =>
    _classes(className).where((c) => c.startsWith('hover:')).toList();

/// The `<style>` element carrying this zone's scoped hover rule. Other
/// parts of the zone (the composed `Button` / `Clickable`) ship their own
/// `<style>` blocks, so the tag alone says nothing about the hover rule.
Finder _hoverRuleStyle() => find.byComponentPredicate(
  (c) =>
      c is DomComponent &&
      c.tag == 'style' &&
      (c.children ?? const <Component>[]).whereType<RawText>().any(
        (t) => t.text.contains('-zone:hover'),
      ),
);

void main() {
  // The dashes stroke with `currentColor`, so the edge colour is the root's
  // text colour and its hover step is `hover:text-*`. Tailwind v3 emits
  // `hover:` after the plain `text-*` state classes, so the hover class wins
  // over the resting edge on its own. The ladder
  // `disabled > drag-over > hover > idle` is therefore decided by WHICH
  // states are allowed to wear a hover class at all — never by the cascade.
  group('FileInput instruction and hint tones (#5881)', () {
    testComponents('the title wears onSurface and the hint onSurfaceSubtle, '
        'as tokens without an opacity', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
      );
      expect(
        _classes(resolved.labelText.className),
        contains('text-on-surface'),
      );
      final hint = _classes(resolved.hintText.className);
      expect(hint, contains('text-on-surface-subtle'));
      expect(hint, isNot(contains('text-on-surface-variant')));
      expect(resolved.hintText.inlineStyles?.properties['color'], isNull);
    });
  });

  group('FileInput idle hover border', () {
    testComponents(
      'an idle zone rests on outlineVariant and steps to onSurface '
      'under the pointer',
      (tester) async {
        final context = _themedContext(tester);
        final resolved = resolveFileInput(
          context,
          enabled: true,
          isDragOver: false,
        );
        final classes = _classes(resolved.root.className);

        expect(classes, contains('text-outline-variant'));
        expect(_hoverClasses(resolved.root.className), [
          'hover:text-on-surface',
        ]);
        expect(
          resolveFileInputRules(context, enabled: true, isDragOver: false).css,
          isEmpty,
        );
      },
    );

    testComponents('the idle hover is not the drag-over tone', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
      );

      expect(
        _hoverClasses(resolved.root.className),
        isNot(contains('hover:text-primary')),
      );
    });

    testComponents('hover tints no fill — only a drag does', (tester) async {
      final context = _themedContext(tester);

      for (final (enabled, dragging) in [
        (true, false),
        (true, true),
        (false, false),
      ]) {
        final resolved = resolveFileInput(
          context,
          enabled: enabled,
          isDragOver: dragging,
        );
        expect(
          _classes(
            resolved.root.className,
          ).where((c) => c.contains('hover:bg')),
          isEmpty,
          reason: 'enabled=$enabled dragging=$dragging',
        );
      }
    });

    testComponents('a real drag keeps its primary edge: no hover class '
        'competes with it', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: true,
      );

      expect(_classes(resolved.root.className), contains('text-primary'));
      expect(_hoverClasses(resolved.root.className), isEmpty);
      expect(
        resolveFileInputRules(context, enabled: true, isDragOver: true).css,
        isEmpty,
      );
    });

    testComponents('a disabled zone has no hover step', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: false,
        isDragOver: false,
      );

      expect(_hoverClasses(resolved.root.className), isEmpty);
      expect(
        resolveFileInputRules(context, enabled: false, isDragOver: false).css,
        isEmpty,
      );
    });

    testComponents('a token hoverBorderColor rides the hover class', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreFileInputStyle(
        hoverBorderColor: CoreColor.token(CoreColors.tertiary),
      );
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
        fileInputStyle: style,
      );

      expect(_hoverClasses(resolved.root.className), ['hover:text-tertiary']);
      expect(
        resolveFileInputRules(
          context,
          enabled: true,
          isDragOver: false,
          fileInputStyle: style,
        ).css,
        isEmpty,
      );
    });

    testComponents('a RAW hoverBorderColor has no class to ride: the zone '
        'carries a per-instance scope class and the rule paints it', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const raw = CoreColor(0xFFAA3366);
      const style = CoreFileInputStyle(hoverBorderColor: raw);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
        scopeId: 'fi-3',
        fileInputStyle: style,
      );

      expect(_hoverClasses(resolved.root.className), isEmpty);
      expect(_classes(resolved.root.className), contains('fi-3-zone'));
      expect(
        resolveFileInputRules(
          context,
          enabled: true,
          isDragOver: false,
          scopeId: 'fi-3',
          fileInputStyle: style,
        ).css,
        '.fi-3-zone:hover{color: ${raw.toValue()};}',
      );
    });

    testComponents('a per-instance borderColor ships inline, which beats '
        'every class — the hover step states its rule !important', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const style = CoreFileInputStyle(
        borderColor: CoreColor.token(CoreColors.tertiary),
      );
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
        scopeId: 'fi-4',
        fileInputStyle: style,
      );
      final rules = resolveFileInputRules(
        context,
        enabled: true,
        isDragOver: false,
        scopeId: 'fi-4',
        fileInputStyle: style,
      );

      expect(
        resolved.root.inlineStyles?.properties['color'],
        const CoreColor.token(CoreColors.tertiary).toValue(),
      );
      expect(_hoverClasses(resolved.root.className), isEmpty);
      expect(
        rules.css,
        '.fi-4-zone:hover{color: '
        '${CoreFileInputStyle.defaultHoverBorderColor.toValue()} '
        '!important;}',
      );
    });

    testComponents('the default path ships no scope class and no <style>', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
      );

      expect(
        _classes(resolved.root.className).where((c) => c.endsWith('-zone')),
        isEmpty,
      );

      pumpWithTheme(tester, const FileInput());
      expect(_hoverRuleStyle(), findsNothing);
    });

    testComponents('a per-instance borderColor renders its hover rule in a '
        '<style> child', (tester) async {
      pumpWithTheme(
        tester,
        const FileInput(
          fileInputStyle: CoreFileInputStyle(
            borderColor: CoreColor.token(CoreColors.tertiary),
          ),
        ),
      );

      expect(_hoverRuleStyle(), findsOneComponent);
    });
  });
  group('FileInput drag-over edge shape', () {
    testComponents('the edge is solid while a file is over the zone and '
        'dashed otherwise — width unchanged', (tester) async {
      final context = _themedContext(tester);
      Map<String, String> rect({required bool enabled, required bool drag}) =>
          resolveFileInput(
            context,
            enabled: enabled,
            isDragOver: drag,
          ).dashRect.inlineStyles!.properties;

      final idle = rect(enabled: true, drag: false);
      final drag = rect(enabled: true, drag: true);
      final disabled = rect(enabled: false, drag: true);

      expect(drag['stroke-dasharray'], 'none');
      expect(idle['stroke-dasharray'], '6.0 4.0');
      expect(disabled['stroke-dasharray'], '6.0 4.0');
      expect(drag['stroke-width'], idle['stroke-width']);
    });
  });
  group('FileInput redesigned structure', () {
    testComponents('icon box is a 48 circle on surface-container-high, '
        'primary-container while a file is dragged over, disabled-container '
        'when disabled', (tester) async {
      final context = _themedContext(tester);
      final idle = resolveFileInput(context, enabled: true, isDragOver: false);
      final drag = resolveFileInput(context, enabled: true, isDragOver: true);
      final disabledDrag = resolveFileInput(
        context,
        enabled: false,
        isDragOver: true,
      );

      expect(
        _classes(idle.iconBox.className),
        contains('bg-surface-container-high'),
      );
      expect(
        _classes(drag.iconBox.className),
        contains('bg-primary-container'),
      );
      expect(
        _classes(disabledDrag.iconBox.className),
        contains('bg-disabled-container'),
      );
      final inline = idle.iconBox.inlineStyles!.properties;
      expect(inline['width'], '3.0rem');
      expect(inline['height'], '3.0rem');
    });

    testComponents('the upload glyph wears primary only while dragged over', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final idle = resolveFileInput(context, enabled: true, isDragOver: false);
      final drag = resolveFileInput(context, enabled: true, isDragOver: true);
      final disabledDrag = resolveFileInput(
        context,
        enabled: false,
        isDragOver: true,
      );
      expect(idle.iconStyle.color, CoreFileInputStyle.defaultSubtleIconColor);
      expect(
        drag.iconStyle.color,
        CoreFileInputStyle.defaultDragActiveIconColor,
      );
      expect(drag.iconStyle.color, const CoreColor.token(CoreColors.primary));
      expect(
        disabledDrag.iconStyle.color,
        CoreFileInputStyle.defaultDisabledContentColor,
      );
    });

    testComponents('spacing: 12 root, 4 inside the text, 16 before buttons', (
      tester,
    ) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
      );
      expect(resolved.root.inlineStyles!.properties['gap'], contains('12'));
      expect(resolved.textBlock.inlineStyles!.properties['gap'], contains('4'));
      expect(
        resolved.contentGroup.inlineStyles!.properties['gap'],
        contains('16'),
      );
    });
  });

  group('FileInput disabled paint', () {
    testComponents('the zone wears disabledContainer / disabledOutline and '
        'the content wears disabledContent, with no inline override', (
      tester,
    ) async {
      final context = _themedContext(tester);
      // A per-instance idle fill / edge must not outrank the disabled tokens.
      const style = CoreFileInputStyle(
        backgroundColor: CoreColor.token(CoreColors.tertiary),
        borderColor: CoreColor.token(CoreColors.tertiary),
      );
      final resolved = resolveFileInput(
        context,
        enabled: false,
        isDragOver: false,
        fileInputStyle: style,
      );

      final root = _classes(resolved.root.className);
      expect(root, contains('bg-disabled-container'));
      expect(root, contains('text-disabled-outline'));
      expect(root, isNot(contains('text-outline-variant')));
      final inline = resolved.root.inlineStyles?.properties ?? const {};
      expect(inline.containsKey('background-color'), isFalse);
      expect(inline.containsKey('color'), isFalse);
      // The disabled fill is opaque and takes no material marker.
      expect(root, isNot(contains('coui-surface')));

      expect(
        _classes(resolved.labelText.className),
        contains('text-disabled-content'),
      );
      expect(
        _classes(resolved.hintText.className),
        contains('text-disabled-content'),
      );
      // The hint is the Regular secondary line under the Medium title (#5881).
      expect(
        _classes(resolved.hintText.className),
        contains('text-body-small'),
      );
      expect(
        _classes(resolved.hintText.className),
        isNot(contains('text-label-medium')),
      );
      expect(
        _classes(resolved.fileName.className),
        contains('text-disabled-content'),
      );
      expect(
        _classes(resolved.fileIcon.className),
        contains('text-disabled-content'),
      );
      expect(
        _classes(resolved.iconBox.className),
        contains('bg-disabled-container'),
      );
      expect(
        resolved.iconStyle.color,
        CoreFileInputStyle.defaultDisabledContentColor,
      );
    });

    testComponents('an enabled zone keeps the enabled tones', (tester) async {
      final context = _themedContext(tester);
      final resolved = resolveFileInput(
        context,
        enabled: true,
        isDragOver: false,
      );
      expect(
        _classes(resolved.root.className),
        isNot(contains('bg-disabled-container')),
      );
      expect(
        resolved.iconStyle.color,
        CoreFileInputStyle.defaultSubtleIconColor,
      );
    });
  });
}
