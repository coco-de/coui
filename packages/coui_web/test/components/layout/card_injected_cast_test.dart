import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/card/card_style.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// Captures the ambient themed [BuildContext] so resolver-level tests can
/// call `resolveCard` directly.
class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return div([]);
  }
}

BuildContext _themedContext(ComponentTester tester) {
  late BuildContext context;
  pumpWithTheme(tester, _ContextCapture((c) => context = c));
  return context;
}

bool _takesCast(ResolvedCard resolved) =>
    resolved.root.className.split(' ').contains(kControlShadowRestMarker);

String? _rootShadow(ResolvedCard resolved) =>
    resolved.root.inlineStyles?.properties['box-shadow'];

void main() {
  group('the Web card carries the style-injected cast', () {
    testComponents('a plain card opts into the control shadow', (tester) async {
      // The Flutter twin composes `OutlinedContainer`, which takes
      // `theme.geometry.controlShadow` when the caller authors no shadow.
      // The Web card does not compose it — it draws its own box — so the
      // opt-in has to be restated here or the two platforms diverge under
      // any style whose whole signature IS the cast. That divergence is
      // silent: nothing throws, the card just renders flat on one side.
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: false,
      );

      expect(_takesCast(resolved), isTrue);
      // On a class, not inline: an inline declaration out-ranks every
      // selector, so inlining it would take the hover branch's feedback
      // away below.
      expect(_rootShadow(resolved), isNull);
    });

    testComponents('an authored shadow still wins', (tester) async {
      const List<CoreShadowLayer> explicit = [
        (
          offsetX: 0.0,
          offsetY: 2.0,
          blurRadius: 8.0,
          spreadRadius: 0.0,
          opacity: 1.0,
          inset: false,
        ),
      ];
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: false,
        cardStyle: const CoreCardStyle(boxShadow: explicit),
      );

      // The injected cast is a fallback for surfaces that state nothing,
      // never an override of one that does.
      expect(_takesCast(resolved), isFalse);
      expect(_rootShadow(resolved), isNotNull);
    });

    testComponents(
      'an explicit empty boxShadow opts out — not the same as authoring '
      'nothing',
      (tester) async {
        // `CoreCardStyle(boxShadow: CoreShadow.none)` is how a caller says
        // "no shadow, not even the active style's ambient cast" — the
        // Flutter twin needs the identical signal forwarded into
        // `OutlinedContainer` for the same reason (its own
        // `explicitShadow == null` check falls back to `controlShadow`
        // otherwise). Wrapping a card that opts out like this in
        // `Hover(effect: .shadow)` is how the effect's own added shadow
        // stays the only one, instead of stacking on the card's ambient
        // rest shadow.
        final resolved = resolveCard(
          _themedContext(tester),
          variant: .defaultVariant,
          hasMedia: false,
          interactive: false,
          cardStyle: const CoreCardStyle(boxShadow: CoreShadow.none),
        );

        expect(_takesCast(resolved), isFalse);
        expect(_rootShadow(resolved), isNotNull);
        expect(_rootShadow(resolved), startsWith('none,'));
      },
    );

    testComponents('a hoverable card takes it too', (tester) async {
      // The Flutter twin composes `OutlinedContainer` whether or not the
      // card is tappable, so gating this on interactivity would put the
      // divergence back — just on the other half of the cards. Riding a
      // class is what makes one rule serve both: `hover:shadow-*` is two
      // class-level selectors to this one, so the hover feedback still
      // wins while hovered.
      final resolved = resolveCard(
        _themedContext(tester),
        variant: .defaultVariant,
        hasMedia: false,
        interactive: true,
      );

      expect(_takesCast(resolved), isTrue);
      expect(_rootShadow(resolved), isNull);
    });
  });
}
