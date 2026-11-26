import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The `Button` a toast rendered for its action — after the toast merged its
/// own action chrome under the caller's.
Button _renderedAction() =>
    find.byType(Button).evaluate().single.component as Button;

void main() {
  // Web emits token NAMES and the browser resolves them, so the thing to pin
  // here is which token reaches the button — the numeric ratio is Flutter's
  // test to make (both platforms read the same variant row). The pair
  // `inverse-on-surface` on `inverse-surface` is one the contrast guard
  // audits; a foreground the scheme never pairs with the slab is how an
  // action once shipped unreadable.
  group('Toast action foreground', () {
    testComponents('a plain Button action wears the variant foreground', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Saved',
          action: Button(
            variant: CoreButtonVariant.plain,
            child: Text('Undo'),
          ),
        ),
      );

      expect(
        _renderedAction().buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.inverseOnSurface),
      );
      expect(
        _renderedAction().buttonStyle?.hoverForegroundColor,
        const CoreColor.token(CoreColors.inverseOnSurface),
        reason: 'hover must not fall back to the page-surface foreground',
      );
    });

    testComponents('the caller still wins — slot over injection', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Saved',
          toastStyle: const CoreToastStyle(
            actionButtonStyle: CoreButtonStyle(
              foregroundColor: CoreColor.token(CoreColors.primary),
            ),
          ),
          action: Button(
            variant: CoreButtonVariant.plain,
            child: Text('Undo'),
          ),
        ),
      );

      expect(
        _renderedAction().buttonStyle?.foregroundColor,
        const CoreColor.token(CoreColors.primary),
      );
    });

    testComponents(
      "the caller still wins — the action's own style over the slot",
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          Toast(
            message: 'Saved',
            toastStyle: const CoreToastStyle(
              actionButtonStyle: CoreButtonStyle(
                foregroundColor: CoreColor.token(CoreColors.primary),
              ),
            ),
            action: Button(
              variant: CoreButtonVariant.plain,
              buttonStyle: const CoreButtonStyle(
                foregroundColor: CoreColor.token(CoreColors.error),
              ),
              child: Text('Undo'),
            ),
          ),
        );

        expect(
          _renderedAction().buttonStyle?.foregroundColor,
          const CoreColor.token(CoreColors.error),
        );
      },
    );
  });

  testComponents('a plain action gets 6 on each side', (tester) async {
    // `plain` sits flush with its label; on the slab the wash was the word
    // wide (#6214).
    pumpWithTheme(
      tester,
      Toast(
        message: 'Saved',
        action: Button(variant: CoreButtonVariant.plain, child: Text('Undo')),
      ),
    );
    expect(
      _renderedAction().buttonStyle?.padding,
      const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space6),
    );
  });

  testComponents('an outline action keeps its own inset', (tester) async {
    // The inline inset is `plain`'s alone (#6214) — an outline keeps the
    // size row's own, so the slot states no padding for it.
    pumpWithTheme(
      tester,
      Toast(
        message: 'Saved',
        action: Button(variant: CoreButtonVariant.outline, child: Text('Undo')),
      ),
    );
    expect(_renderedAction().buttonStyle?.padding, isNull);
  });

  testComponents('the close button composes the square shape', (
    tester,
  ) async {
    // Same affordance as Banner's dismiss — a 40 circle, not a tall pill
    // around the glyph (#6214).
    pumpWithTheme(tester, Toast(message: 'Saved', onDismiss: () {}));
    final close = find
        .byType(Button)
        .evaluate()
        .map((e) => e.component as Button)
        .single;
    expect(close.shape, CoreButtonShape.square);
    expect(
      close.buttonStyle?.borderRadius,
      const CoreBorderRadius.all(CoreRadius.radius9999),
    );
    expect(close.buttonStyle?.padding, isNull);
  });

  testComponents('the close wrapper centres the button on the block axis', (
    tester,
  ) async {
    // Pinned 8 below the top, the 40 circle sank under the message; the
    // wrapper spans the panel's height and centres its one child (#6214).
    pumpWithTheme(tester, Toast(message: 'Saved', onDismiss: () {}));
    final wrapper = find
        .tag('div')
        .evaluate()
        .map((e) => e.component)
        .whereType<DomComponent>()
        .firstWhere((c) => (c.classes ?? '').split(' ').contains('absolute'));
    expect(wrapper.classes!.split(' '), containsAll(['flex', 'items-center']));
    final css = wrapper.styles?.properties ?? const <String, String>{};
    expect(css.keys, containsAll(['top', 'bottom', 'right']));
  });
}
