import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/util/core_to_css.dart';
import 'package:test/test.dart';

void main() {
  // The painted element cannot be the pointer target (a row of decorative
  // cells over a hidden input), so it follows the hover of a NAMED ancestor
  // group. The name is what keeps it from firing for an unrelated `.group`
  // container further up the page.
  group('emitGroupHoverColor', () {
    const fallback = CoreColor.token(CoreColors.onSurface);

    test('a token rides the named-group hover class — no rule', () {
      final emit = emitGroupHoverColor(
        null,
        fallback,
        ColorTarget.border,
        group: 'input-otp',
        scopeSelector: '.cell',
      );

      expect(emit.className, 'group-hover/input-otp:border-on-surface');
      expect(emit.rule, isEmpty);
    });

    test('the value wins over the fallback', () {
      final emit = emitGroupHoverColor(
        const CoreColor.token(CoreColors.error),
        fallback,
        ColorTarget.border,
        group: 'input-otp',
        scopeSelector: '.cell',
      );

      expect(emit.className, 'group-hover/input-otp:border-error');
    });

    test('the target picks the utility prefix', () {
      expect(
        emitGroupHoverColor(
          null,
          fallback,
          ColorTarget.background,
          group: 'g',
          scopeSelector: '.x',
        ).className,
        'group-hover/g:bg-on-surface',
      );
      expect(
        emitGroupHoverColor(
          null,
          fallback,
          ColorTarget.text,
          group: 'g',
          scopeSelector: '.x',
        ).className,
        'group-hover/g:text-on-surface',
      );
    });

    test('a RAW colour has no class: the scoped rule names the group', () {
      const raw = CoreColor(0xFFAA3366);
      final emit = emitGroupHoverColor(
        raw,
        fallback,
        ColorTarget.border,
        group: 'input-otp',
        scopeSelector: '.otp-1-cell',
      );

      expect(emit.className, isEmpty);
      const selector = r'.group\/input-otp:hover .otp-1-cell';
      expect(emit.rule, '$selector{border-color: ${raw.toValue()};}');
    });

    test('the group name is part of both spellings — never a bare `group`', () {
      final token = emitGroupHoverColor(
        null,
        fallback,
        ColorTarget.border,
        group: 'input-otp',
        scopeSelector: '.x',
      );
      final raw = emitGroupHoverColor(
        const CoreColor(0xFF112233),
        fallback,
        ColorTarget.border,
        group: 'input-otp',
        scopeSelector: '.x',
      );

      expect(token.className, startsWith('group-hover/input-otp:'));
      expect(raw.rule, startsWith(r'.group\/input-otp:hover '));
    });
  });
}
