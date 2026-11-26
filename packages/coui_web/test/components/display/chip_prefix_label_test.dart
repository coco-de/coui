// The Web half of the key a filter chip draws in front of its value ("필터"
// before "전체").
//
// Web emits token names, not resolved colours, so the resolver half reads the
// classes on the key's own `<span>`: its role class per size and its colour
// class per state. The rendered half reads the markup — the key before the
// value, nothing at all when absent, and the remove button's name.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/server_test.dart';

import '../../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext) onBuild;

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

ResolvedChip _resolve(
  BuildContext context, {
  CoreChipSize size = CoreChipSize.md,
  CoreChipColor chipColor = CoreChipColor.neutral,
  CoreChipVariant variant = CoreChipVariant.outlined,
  CoreChipEmphasis emphasis = CoreChipEmphasis.high,
  bool selected = false,
  bool enabled = true,
  CoreColor? seedColor,
  CoreChipStyle? chipStyle,
}) => resolveChip(
  context,
  chipColor: chipColor,
  variant: variant,
  size: size,
  selected: selected,
  emphasis: emphasis,
  enabled: enabled,
  seedColor: seedColor,
  chipStyle: chipStyle,
);

/// The key `<span>`'s classes as a set — `contains` on the joined string
/// would let `text-on-surface` match inside `text-on-surface-variant`.
Set<String> _keyClasses(ResolvedChip resolved) =>
    resolved.prefixLabel.className.split(' ').toSet();

String _text(CoreColorToken token) => 'text-${token.name}';

Future<DocumentResponse> _render(ServerTester tester, Component chip) {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: chip));

  return tester.request('/');
}

void main() {
  group('Chip prefix label (Web) — resolved key chrome', () {
    testComponents('each size emits its key role class — 11 / 12 / 13', (
      tester,
    ) async {
      final context = _themedContext(tester);
      const roles = {
        CoreChipSize.sm: CoreTextStyles.labelXs,
        CoreChipSize.md: CoreTextStyles.labelSmall,
        CoreChipSize.lg: CoreTextStyles.labelMedium,
      };
      for (final size in CoreChipSize.values) {
        final resolved = _resolve(context, size: size);
        expect(
          _keyClasses(resolved),
          contains('text-${roles[size]!.name}'),
          reason: '${size.name} role class',
        );
        // The role's own 500 and its own size — no overlay rides inline,
        // on the key or on the label.
        expect(
          resolved.prefixLabel.inlineStyles,
          isNull,
          reason: '${size.name} nothing inline',
        );
        expect(
          resolved.label.inlineStyles?.properties ?? const <String, String>{},
          isNot(contains('font-weight')),
          reason: "${size.name} the value keeps its role's 500",
        );
      }
    });

    testComponents('holds one line at full width', (tester) async {
      final classes = _keyClasses(_resolve(_themedContext(tester)));
      expect(classes, contains('shrink-0'));
      expect(classes, contains('whitespace-nowrap'));
      expect(classes, isNot(contains('truncate')));
    });

    testComponents('a resting key reads its own column — outlined and '
        'filled, either emphasis', (tester) async {
      final context = _themedContext(tester);
      for (final variant in CoreChipVariant.values) {
        for (final emphasis in CoreChipEmphasis.values) {
          final classes = _keyClasses(
            _resolve(context, variant: variant, emphasis: emphasis),
          );
          expect(
            classes,
            contains(_text(CoreColors.onSurfaceVariant)),
            reason: '$variant $emphasis',
          );
          expect(classes, isNot(contains(_text(CoreColors.onSurface))));
        }
      }
    });

    testComponents('a selected key takes the label colour of its emphasis', (
      tester,
    ) async {
      final context = _themedContext(tester);
      expect(
        _keyClasses(_resolve(context, selected: true)),
        contains(_text(CoreColors.inverseOnSurface)),
      );
      expect(
        _keyClasses(
          _resolve(context, selected: true, emphasis: CoreChipEmphasis.low),
        ),
        contains(_text(CoreColors.onSurface)),
      );
      expect(
        _keyClasses(
          _resolve(context, selected: true, chipColor: CoreChipColor.primary),
        ),
        contains(_text(CoreColors.onPrimary)),
      );
      // A custom seed's derived on-colour — `success` pairs with
      // `on-success`.
      expect(
        _keyClasses(
          _resolve(
            context,
            selected: true,
            chipColor: CoreChipColor.custom,
            seedColor: const CoreColor.token(CoreColors.success),
          ),
        ),
        contains(_text(CoreColors.onSuccess)),
      );
    });

    testComponents('a disabled key takes the disabled content colour', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final selected in [false, true]) {
        expect(
          _keyClasses(_resolve(context, enabled: false, selected: selected)),
          contains(_text(CoreColors.disabledContent)),
          reason: 'selected=$selected',
        );
      }
    });

    testComponents('foregroundColor wins across states, its own slot wins '
        'over that', (tester) async {
      final context = _themedContext(tester);
      final forced = _keyClasses(
        _resolve(
          context,
          chipStyle: const CoreChipStyle(
            foregroundColor: CoreColor.token(CoreColors.error),
          ),
        ),
      );
      expect(forced, contains(_text(CoreColors.error)));
      expect(forced, isNot(contains(_text(CoreColors.onSurfaceVariant))));

      final slot = _keyClasses(
        _resolve(
          context,
          chipStyle: const CoreChipStyle(
            foregroundColor: CoreColor.token(CoreColors.error),
            prefixLabelStyle: CoreTextStyle(
              color: CoreColor.token(CoreColors.primary),
            ),
          ),
        ),
      );
      expect(slot, contains(_text(CoreColors.primary)));
      // One colour class on the span — the slot replaces the state colour
      // rather than racing it.
      expect(slot, isNot(contains(_text(CoreColors.error))));
    });
  });

  group('Chip prefix label (Web) — rendered markup', () {
    testServer('draws the key before the value', (tester) async {
      final doc = (await _render(
        tester,
        Chip(prefixLabel: '필터', label: '전체'),
      )).document!;
      final body = doc.querySelector('.co-chip-body')!;
      final text = body.text;
      expect(text, contains('필터'));
      expect(text, contains('전체'));
      expect(text.indexOf('필터'), lessThan(text.indexOf('전체')));

      final keySpan = body
          .querySelectorAll('span')
          .firstWhere(
            (el) => el.className.split(' ').contains('whitespace-nowrap'),
          );
      expect(keySpan.text, '필터');
      expect(
        keySpan.className.split(' '),
        contains('text-${CoreTextStyles.labelSmall.name}'),
      );
    });

    testServer('draws nothing when absent', (tester) async {
      final doc = (await _render(tester, Chip(label: '전체'))).document!;
      final body = doc.querySelector('.co-chip-body')!;
      expect(
        body
            .querySelectorAll('span')
            .where(
              (el) => el.className.split(' ').contains('whitespace-nowrap'),
            ),
        isEmpty,
      );
      expect(body.text.trim(), '전체');
    });

    testServer('the remove button names the chip key first', (tester) async {
      final doc = (await _render(
        tester,
        Chip(prefixLabel: '필터', label: '전체', onRemove: () {}),
      )).document!;
      expect(doc.querySelectorAll('[aria-label="Remove 필터 전체"]'), hasLength(1));
    });
  });

  group('Chip prefix label (Web) — component', () {
    test('copyWith carries the key', () {
      final chip = Chip(prefixLabel: '필터', label: '전체');
      expect(chip.copyWith(label: '진행 중').prefixLabel, '필터');
      expect(chip.copyWith(prefixLabel: '상태').prefixLabel, '상태');
    });
  });
}
