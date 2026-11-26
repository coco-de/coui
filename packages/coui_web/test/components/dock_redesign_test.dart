// The Dock redesign (#6463), row by row, as the Web resolver emits it.
//
// Every expectation reads the chrome the resolver hands the markup — the
// classes and inline declarations — never `CoreDockStyle` alone: a value the
// Core table states and the resolver drops would pass a test of the table.
// The Flutter twin (`coui_flutter/test/components/dock_redesign_test.dart`)
// reads the rendered widget tree against the same rows.
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/layout/dock/dock_style.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

T _read<T>(ComponentTester tester, T Function(BuildContext context) read) {
  late T value;
  pumpWithTheme(tester, _ContextCapture((context) => value = read(context)));
  return value;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles?.properties ?? const {};

List<String> _classes(WebElementChrome chrome) => chrome.className.split(' ');

String _rem(double px) => '${px / kRemDivisor}rem';

({ResolvedDock dock, ResolvedDockItem active, ResolvedDockItem idle}) _resolve(
  ComponentTester tester,
  CoreDockSize size,
) => _read(tester, (context) {
  final dock = resolveDock(context, size: size);
  ResolvedDockItem item({required bool isActive}) => resolveDockItem(
    context,
    resolved: dock,
    size: size,
    isActive: isActive,
    hasLabel: true,
    showIndicator: isActive,
    tappable: true,
  );

  return (
    dock: dock,
    active: item(isActive: true),
    idle: item(isActive: false),
  );
});

const List<CoreDockSize> _compact = [CoreDockSize.xs, CoreDockSize.sm];
const List<CoreDockSize> _labelled = [
  CoreDockSize.md,
  CoreDockSize.lg,
  CoreDockSize.xl,
];

void main() {
  group('the bar', () {
    testComponents('draws an outline-variant line on every edge', (
      tester,
    ) async {
      final dock = _resolve(tester, .md).dock;

      expect(_classes(dock.root), contains('border-outline-variant'));
      expect(
        _inline(dock.root)['border-width'],
        strokeWidthCss(CoreStrokeWidth.stroke1),
      );
      expect(_inline(dock.root)['border-style'], 'solid');
    });

    for (final (size, radius) in [
      (CoreDockSize.xs, 'radius10'),
      (CoreDockSize.sm, 'radius10'),
      (CoreDockSize.md, 'radius16'),
      (CoreDockSize.lg, 'radius16'),
      (CoreDockSize.xl, 'radius16'),
    ]) {
      testComponents('${size.name}: is rounded $radius', (tester) async {
        final classes = _classes(_resolve(tester, size).dock.root);
        for (final corner in ['tl', 'tr', 'bl', 'br']) {
          expect(classes, contains('rounded-$corner-$radius'));
        }
      });
    }

    for (final size in CoreDockSize.values) {
      final compact = _compact.contains(size);
      final side = compact ? 8.0 : 10.0;
      final rowInset = compact ? 6.0 : 10.0;
      final gap = compact ? 6.0 : 4.0;
      testComponents('${size.name}: padded $side beside and $rowInset above '
          'and below, apps $gap apart and centred', (tester) async {
        final r = _resolve(tester, size);
        final root = _inline(r.dock.root);
        expect(root['padding-left'], spaceCss(side));
        expect(root['padding-right'], spaceCss(side));
        expect(root['column-gap'], spaceCss(gap));
        expect(_classes(r.dock.root), contains('justify-center'));
        expect(_classes(r.dock.root), isNot(contains('justify-around')));
        // The room above and below rides the flex item.
        expect(_inline(r.active.clickable!)['margin-top'], spaceCss(rowInset));
        expect(
          _inline(r.active.clickable!)['margin-bottom'],
          spaceCss(rowInset),
        );
      });
    }

    testComponents('has no material and clips nothing by default', (
      tester,
    ) async {
      // Translucency and blur come from the surface style — never from a
      // Dock default.
      final r = _resolve(tester, .md);
      for (final chrome in [r.dock.root, r.active.root, r.active.icon]) {
        expect(_inline(chrome), isNot(contains('backdrop-filter')));
        expect(_classes(chrome), isNot(contains('overflow-hidden')));
      }
      for (final chrome in [r.active.root, r.active.icon]) {
        expect(_inline(chrome), isNot(contains('box-shadow')));
      }
    });

    testComponents('casts the md shadow through the shadow-strength path, '
        'with the rim beside it', (tester) async {
      // `var(--shadow-md)` is the stack whose alpha a dark theme multiplies
      // by `--coui-shadow-strength` and a surface style bends; a literal
      // would sit out of both.
      final r = _resolve(tester, .md);
      expect(
        _inline(r.dock.root)['box-shadow'],
        'var(--shadow-${CoreShadow.scale.md}), $kSurfaceRimVar',
      );
    });

    testComponents('a stated empty shadow casts none — and takes no rim', (
      tester,
    ) async {
      // A rim decorates a surface that casts; a flat bar gets none, the
      // way `resolveSurfaceRim` holds on Flutter.
      final root = _read(
        tester,
        (context) => resolveDock(
          context,
          dockStyle: const CoreDockStyle(boxShadow: []),
        ),
      ).root;
      expect(_inline(root)['box-shadow'], 'none');
    });
  });

  group('the app cell', () {
    for (final (size, width) in [
      (CoreDockSize.md, 48.0),
      (CoreDockSize.lg, 56.0),
      (CoreDockSize.xl, 64.0),
    ]) {
      testComponents('${size.name}: is $width wide, and so is its icon row', (
        tester,
      ) async {
        final r = _resolve(tester, size);
        expect(_inline(r.active.root)['width'], _rem(width));
        expect(_inline(r.idle.root)['width'], _rem(width));
        expect(_inline(r.active.icon)['width'], _rem(width));
        final icon = CoreDockStyle.defaultsBySize[size]!.iconStyle!.size!;
        expect(_inline(r.active.icon)['height'], _rem(icon));
      });
    }

    for (final size in _compact) {
      testComponents('${size.name}: is as wide as its icon', (tester) async {
        final r = _resolve(tester, size);
        final icon = CoreDockStyle.defaultsBySize[size]!.iconStyle!.size!;
        expect(_inline(r.active.root), isNot(contains('width')));
        expect(_inline(r.active.icon)['width'], _rem(icon));
      });
    }
  });

  group('the active plate', () {
    for (final size in CoreDockSize.values) {
      final compact = _compact.contains(size);
      final radius = compact ? 'radius8' : 'radius10';
      final side = compact ? 3.0 : 0.0;
      final above = compact ? 3.0 : 5.0;
      testComponents('${size.name}: surface-container-high, $radius, '
          'reaching $above above and below and $side beside the icon row', (
        tester,
      ) async {
        final r = _resolve(tester, size);
        final plate = r.active.indicator!;
        expect(_classes(plate), contains('bg-surface-container-high'));
        expect(_classes(plate), contains('rounded-tl-$radius'));
        expect(
          _inline(plate)['inset'],
          'calc(-1 * ${spaceCss(above)}) '
          'calc(-1 * ${spaceCss(side)}) '
          'calc(-1 * ${spaceCss(above)}) '
          'calc(-1 * ${spaceCss(side)})',
        );
        // Behind the icon row, not the whole item: the row is its box.
        expect(_classes(r.active.icon), containsAll(['relative', 'isolate']));
        expect(r.idle.indicator, isNull);
      });
    }

    testComponents('the flight reads the size the dock is at', (tester) async {
      final runtime = _read(
        tester,
        (context) => resolveDockIndicatorRuntime(
          context,
          resolved: resolveDock(context, size: CoreDockSize.xs),
          size: CoreDockSize.xs,
        ),
      );
      expect(runtime.padding, const CoreEdgeInsets.all(3));
      expect(runtime.radius, 8);
    });
  });

  group('the labels', () {
    for (final size in _labelled) {
      testComponents('${size.name}: the 11px role, SemiBold on-surface when '
          'active and Medium on-surface-variant otherwise', (tester) async {
        final r = _resolve(tester, size);
        final role = 'text-${CoreTextStyles.labelXs.name}';
        final active = r.active.label!;
        final idle = r.idle.label!;
        expect(_classes(active), containsAll([role, 'text-on-surface']));
        expect(
          _classes(idle),
          containsAll([role, 'text-on-surface-variant']),
        );
        expect(_inline(active)['font-weight'], '${CoreFontWeight.semiBold}');
        expect(_inline(idle)['font-weight'], '${CoreFontWeight.medium}');
      });
    }

    testComponents('the active icon keeps the primary tint', (tester) async {
      final r = _resolve(tester, .md);
      expect(_classes(r.active.root), contains('text-primary'));
      expect(_classes(r.idle.root), contains('text-on-surface-variant'));
    });
  });
}
