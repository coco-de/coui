import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// [.reverse]'s Web twin of `chip_cast_motion_test.dart`
/// (Flutter). Chip has no authored-shadow slot (unlike Button), so this
/// is a direct read of `castMotion` with nothing to gate it on.
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

void main() {
  group('a chip in reverse motion', () {
    testComponents(
      'withholds the rest marker and states its ghost inline instead',
      (tester) async {
        final resolved = resolveChip(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: .defaultColor,
          size: .md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
          chipStyle: const CoreChipStyle(castMotion: .reverse),
        );

        expect(
          resolved.root.className.split(' '),
          isNot(contains(kControlShadowRestMarker)),
          reason:
              "the marker's global rule always points at the real "
              "cast — a reverse chip's rest value is the ghost twin "
              'instead',
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};
        expect(
          raw['box-shadow'],
          kControlShadowGhostVar,
          reason:
              'a reverse chip at rest states no stack of its own — it '
              'takes only the contributed ghost, and the rim rides only a '
              'stack the surface states (the Flutter Chip draws none)',
        );
      },
    );

    testComponents('still carries the press marker', (tester) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: .defaultColor,
        size: .md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
        chipStyle: const CoreChipStyle(castMotion: .reverse),
      );

      expect(
        resolved.root.className.split(' '),
        contains(kControlShadowPressMarker),
        reason:
            'reverse still engages — only which half of the pair is '
            'visible flips',
      );
    });

    testComponents(
      'engage overrides grow the real cast and travel the negated '
      'diagonal',
      (tester) async {
        final resolved = resolveChip(
          _themedContext(tester),
          variant: CoreChipVariant.outlined,
          chipColor: .defaultColor,
          size: .md,
          selected: false,
          emphasis: .defaultEmphasis,
          enabled: true,
          chipStyle: const CoreChipStyle(castMotion: .reverse),
        );
        final raw = resolved.root.inlineStyles?.properties ?? const {};

        expect(
          raw['--coui-control-shadow-press'],
          'var(--coui-control-shadow, none)',
        );
        expect(
          raw['--coui-control-shadow-offset-x'],
          'var(--coui-control-shadow-offset-x-reverse, 0px)',
        );
        expect(
          raw['--coui-control-shadow-offset-y'],
          'var(--coui-control-shadow-offset-y-reverse, 0px)',
        );
        expect(raw['--coui-button-rest-shadow'], kControlShadowGhostVar);
      },
    );

    testComponents('a disabled reverse chip states no engage override', (
      tester,
    ) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: .defaultColor,
        size: .md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: false,
        chipStyle: const CoreChipStyle(castMotion: .reverse),
      );
      final raw = resolved.root.inlineStyles?.properties ?? const {};

      expect(raw.containsKey('--coui-control-shadow-press'), isFalse);
    });
  });

  group('defaultMotion is unaffected — same values as before reverse', () {
    testComponents('rest shadow stays the marker class + kControlShadowVar', (
      tester,
    ) async {
      final resolved = resolveChip(
        _themedContext(tester),
        variant: CoreChipVariant.outlined,
        chipColor: .defaultColor,
        size: .md,
        selected: false,
        emphasis: .defaultEmphasis,
        enabled: true,
      );

      expect(
        resolved.root.className.split(' '),
        contains(kControlShadowRestMarker),
      );
      final raw = resolved.root.inlineStyles?.properties ?? const {};
      expect(raw.containsKey('box-shadow'), isFalse);
      expect(raw['--coui-button-rest-shadow'], kControlShadowVar);
      expect(raw.containsKey('--coui-control-shadow-press'), isFalse);
    });
  });
}
