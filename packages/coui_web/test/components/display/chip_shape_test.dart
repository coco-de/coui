// The Web half of the chip shape axis: `rounded` (the default) keeps the
// size row's corner — the exact `var(--coui-radius-6|8|10)` it emitted
// before the axis existed — and `pill` states the full rung,
// `var(--coui-radius-9999)` on every corner, which the browser scales down to
// half the face's height. The composed `Clickable` is handed the same corner,
// so the focus ring follows the pill. A corner the caller or the theme states
// wins over both shapes. The rendered markup is read back too: a chip that
// names no shape draws byte for byte what an explicit `rounded` draws, and a
// pill differs from it in the corner and nothing else.
import 'package:coui_web/coui_web.dart';
// chip_style.dart is not re-exported by the barrel past the resolver — the
// face marker and the state-layer rules come from it directly.
import 'package:coui_web/src/components/display/chip/chip_style.dart'
    show ResolvedChipRules, kChipBodyMarker, resolveChipRules;
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show ServerTester, testServer;

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

BuildContext _themedContext(ComponentTester tester, {ThemeData? theme}) {
  late BuildContext context;
  final capture = _ContextCapture((c) => context = c);
  if (theme == null) {
    pumpWithTheme(tester, capture);
  } else {
    tester.pumpComponent(Theme(data: theme, child: capture));
  }

  return context;
}

/// Resolves a resting neutral chip — omitting [shape] is the call every
/// caller that predates the axis makes.
ResolvedChip _resolve(
  BuildContext context,
  CoreChipSize size, {
  CoreChipShape? shape,
  CoreChipStyle? chipStyle,
}) => shape == null
    ? resolveChip(
        context,
        chipColor: CoreChipColor.neutral,
        variant: CoreChipVariant.outlined,
        size: size,
        selected: false,
        emphasis: CoreChipEmphasis.high,
        enabled: true,
        chipStyle: chipStyle,
      )
    : resolveChip(
        context,
        chipColor: CoreChipColor.neutral,
        variant: CoreChipVariant.outlined,
        size: size,
        selected: false,
        emphasis: CoreChipEmphasis.high,
        enabled: true,
        shape: shape,
        chipStyle: chipStyle,
      );

/// The four-corner `border-radius` a face states when every corner is the
/// `CoreRadius` rung [step].
String _corners(int step) =>
    List.filled(4, 'var(--coui-radius-$step)').join(' ');

/// The corner each size row drew before the shape axis existed.
const Map<CoreChipSize, int> _rowSteps = {
  CoreChipSize.sm: 6,
  CoreChipSize.md: 8,
  CoreChipSize.lg: 10,
};

/// The rendered elements whose classes contain [marker].
List<DomComponent> _wearing(String marker) => [
  for (final element in find.tag('div').evaluate())
    if ((element.component as DomComponent).classes
            ?.split(' ')
            .contains(
              marker,
            ) ??
        false)
      element.component as DomComponent,
];

/// The chip face: the element wearing the border, radius and padding.
DomComponent _face() => _wearing(kChipBodyMarker).single;

/// The composed `Clickable` root — the element the focus ring is drawn on.
DomComponent _ring() => _wearing(kWebTouchTargetMarker).single;

/// Renders [chip] through the real SSR binding and returns the chip's own
/// markup: the `Clickable` root for a tappable chip, else the face.
Future<String> _markup(ServerTester tester, Chip chip) async {
  tester.pumpComponent(CoUIWeb(theme: .coui, child: chip));
  final response = await tester.request('/');
  final face = response.document!.querySelector('.$kChipBodyMarker')!;
  final root = chip.onTap == null ? face : face.parent!;

  return root.outerHtml;
}

void main() {
  const pill = CoreBorderRadius.all(CoreRadius.radius9999);
  const radius4 = CoreBorderRadius.all(CoreRadius.radius4);

  test('rounded is the default shape and states nothing over the row', () {
    expect(CoreChipShape.defaultShape, CoreChipShape.rounded);
    expect(
      CoreChipStyle.defaultsByShape[CoreChipShape.rounded],
      const CoreChipStyle(),
    );
    expect(
      CoreChipStyle.defaultsByShape[CoreChipShape.pill],
      const CoreChipStyle(borderRadius: pill),
    );
    expect(Chip(label: 'Tag').shape, CoreChipShape.rounded);
    expect(
      Chip(label: 'Tag').copyWith(shape: CoreChipShape.pill).shape,
      CoreChipShape.pill,
    );
    expect(
      Chip(label: 'Tag', shape: CoreChipShape.pill).copyWith(label: 'X').shape,
      CoreChipShape.pill,
    );
  });

  group('rounded keeps the corner every size drew before (Web)', () {
    testComponents('an omitted shape emits var(--coui-radius-6|8|10)', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final MapEntry(key: size, value: step) in _rowSteps.entries) {
        expect(
          _resolve(
            context,
            size,
          ).root.inlineStyles?.properties['border-radius'],
          _corners(step),
          reason: '${size.name} face',
        );
      }
    });

    testComponents('an explicit rounded emits the same corner', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final MapEntry(key: size, value: step) in _rowSteps.entries) {
        expect(
          _resolve(
            context,
            size,
            shape: CoreChipShape.rounded,
          ).root.inlineStyles?.properties['border-radius'],
          _corners(step),
          reason: '${size.name} face',
        );
      }
    });

    testComponents('an explicit rounded resolves every slot the omitted '
        'shape does', (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final omitted = _resolve(context, size);
        final rounded = _resolve(context, size, shape: CoreChipShape.rounded);
        expect(rounded.root.className, omitted.root.className);
        expect(
          rounded.root.inlineStyles?.properties,
          omitted.root.inlineStyles?.properties,
          reason: '${size.name} face',
        );
        expect(rounded.clickableStyle, omitted.clickableStyle);
        expect(rounded.closeButtonStyle, omitted.closeButtonStyle);
      }
    });
  });

  group('pill states the full corner on every size (Web)', () {
    testComponents('the face states var(--coui-radius-9999) on sm · md · lg', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        expect(
          _resolve(
            context,
            size,
            shape: CoreChipShape.pill,
          ).root.inlineStyles?.properties['border-radius'],
          _corners(9999),
          reason: '${size.name} face',
        );
      }
    });

    testComponents('the corner is the only thing the pill changes', (
      tester,
    ) async {
      // Padding, the height floor, the colours and the transition are the
      // size row's — a shape row that leaked any other field would show here.
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        final rounded = _resolve(context, size);
        final pillChip = _resolve(context, size, shape: CoreChipShape.pill);
        expect(pillChip.root.className, rounded.root.className);
        expect(
          {...?pillChip.root.inlineStyles?.properties}..remove('border-radius'),
          {...?rounded.root.inlineStyles?.properties}..remove('border-radius'),
          reason: '${size.name} face',
        );
        expect(
          pillChip.label.className,
          rounded.label.className,
          reason: '${size.name} label',
        );
        expect(pillChip.iconLabelGapStyle, rounded.iconLabelGapStyle);
      }
    });

    testComponents('the focus ring follows the pill', (tester) async {
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        expect(
          _resolve(
            context,
            size,
            shape: CoreChipShape.pill,
          ).clickableStyle.borderRadius,
          pill,
          reason: '${size.name} ring',
        );
      }
    });

    testComponents('the close button keeps the corner its row states', (
      tester,
    ) async {
      // A pill is rounder than any close button corner, so none outgrows
      // the face around it — the small row's 6 stays, md / lg state none.
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        expect(
          _resolve(
            context,
            size,
            shape: CoreChipShape.pill,
          ).closeButtonStyle?.borderRadius,
          CoreChipStyle.defaultsBySize[size]!.closeButtonStyle?.borderRadius,
          reason: size.name,
        );
      }
    });

    testComponents('the state-layer rules are the ones a rounded chip gets', (
      tester,
    ) async {
      // The rules re-walk the same chain, shape row included, and read no
      // corner — so the pill washes toward the fill a rounded chip wears.
      final context = _themedContext(tester);
      for (final size in CoreChipSize.values) {
        ResolvedChipRules rules(CoreChipShape shape) => resolveChipRules(
          context,
          chipColor: CoreChipColor.neutral,
          variant: CoreChipVariant.outlined,
          size: size,
          selected: false,
          emphasis: CoreChipEmphasis.high,
          enabled: true,
          shape: shape,
        );
        final rounded = rules(CoreChipShape.rounded);
        final pillRules = rules(CoreChipShape.pill);
        expect(pillRules.scopeClass, rounded.scopeClass, reason: size.name);
        expect(pillRules.css, rounded.css, reason: size.name);
        expect(pillRules.css, isNot(contains('radius')), reason: size.name);
      }
    });
  });

  group('a stated corner wins over both shapes (Web)', () {
    testComponents('the caller chipStyle.borderRadius wins over the pill', (
      tester,
    ) async {
      final context = _themedContext(tester);
      for (final shape in CoreChipShape.values) {
        for (final size in CoreChipSize.values) {
          final resolved = _resolve(
            context,
            size,
            shape: shape,
            chipStyle: const CoreChipStyle(borderRadius: radius4),
          );
          expect(
            resolved.root.inlineStyles?.properties['border-radius'],
            _corners(4),
            reason: '${shape.name} ${size.name} face',
          );
          expect(
            resolved.clickableStyle.borderRadius,
            radius4,
            reason: '${shape.name} ${size.name} ring',
          );
        }
      }
    });

    testComponents('the theme style.borderRadius wins over the pill', (
      tester,
    ) async {
      final context = _themedContext(
        tester,
        theme: ThemeData.coui.copyWith(
          coreComponentTheme: const CoreComponentTheme(
            chip: CoreChipTheme(style: CoreChipStyle(borderRadius: radius4)),
          ),
        ),
      );
      for (final shape in CoreChipShape.values) {
        for (final size in CoreChipSize.values) {
          final resolved = _resolve(context, size, shape: shape);
          expect(
            resolved.root.inlineStyles?.properties['border-radius'],
            _corners(4),
            reason: '${shape.name} ${size.name} face',
          );
          expect(
            resolved.clickableStyle.borderRadius,
            radius4,
            reason: '${shape.name} ${size.name} ring',
          );
        }
      }
    });
  });

  group('Chip carries its shape to the rendered tree (Web render)', () {
    for (final size in CoreChipSize.values) {
      testComponents('a ${size.name} pill draws the full corner on the face '
          'and on the ring', (tester) async {
        pumpWithTheme(
          tester,
          Chip(
            label: 'Tag',
            size: size,
            shape: CoreChipShape.pill,
            onTap: () {},
          ),
        );

        expect(_face().styles?.properties['border-radius'], _corners(9999));
        expect(_ring().styles?.properties['border-radius'], _corners(9999));
      });

      testComponents('a ${size.name} chip that names no shape draws the row '
          'corner on the face and on the ring', (tester) async {
        pumpWithTheme(tester, Chip(label: 'Tag', size: size, onTap: () {}));

        final corner = _corners(_rowSteps[size]!);
        expect(_face().styles?.properties['border-radius'], corner);
        expect(_ring().styles?.properties['border-radius'], corner);
      });
    }
  });

  group('Chip markup (SSR)', () {
    for (final size in CoreChipSize.values) {
      for (final tappable in [false, true]) {
        final kind = tappable ? 'tappable' : 'display-only';
        Chip chip({CoreChipShape? shape}) => shape == null
            ? Chip(label: 'Tag', size: size, onTap: tappable ? () {} : null)
            : Chip(
                label: 'Tag',
                size: size,
                shape: shape,
                onTap: tappable ? () {} : null,
              );

        testServer('a $kind ${size.name} chip that names no shape is byte '
            'for byte an explicit rounded one', (tester) async {
          final omitted = await _markup(tester, chip());
          final rounded = await _markup(
            tester,
            chip(shape: CoreChipShape.rounded),
          );

          expect(omitted, rounded);
          expect(omitted, contains(_corners(_rowSteps[size]!)));
          expect(omitted, isNot(contains('--coui-radius-9999')));
        });

        testServer('a $kind ${size.name} pill differs from rounded in the '
            'corner alone', (tester) async {
          final rounded = await _markup(tester, chip());
          final pillMarkup = await _markup(
            tester,
            chip(shape: CoreChipShape.pill),
          );

          expect(pillMarkup, isNot(rounded));
          expect(
            pillMarkup.replaceAll(
              _corners(9999),
              _corners(_rowSteps[size]!),
            ),
            rounded,
          );
        });
      }
    }
  });
}
