// How tall the Dock bar is on Web: `CoreDockStyle.height` is its *minimum*.
//
// The root states `min-height` and never `height`: a flex row whose
// `items-center` centres the items in the minimum while they fit, and that
// grows with them once they do not. The room above and below the row — the
// bar's padding, never less than the active plate's reach — is each item's
// own vertical margin — on the flex item, so the bar's padding stays
// horizontal — and it rides the spacing variables so a density moves it.
//
// A VM test reads what the resolver emits, not what a browser lays out. The
// last group reads the declarations the way CSS lays a border-box flex
// container out and holds them against the vector table coui_core shares with
// the Flutter widget test; the real-Chrome probe
// (`tool/parity/test/web/dock_bar_height_probe_test.dart`) measures the
// browser against the same table.
import 'dart:convert';
import 'dart:io';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// The vector table shared with the Core reference test, the Flutter widget
/// test and the Chrome probe (cwd is `packages/coui_web` under `dart test`).
const String _kVectorsPath =
    '../coui_core/test/fixtures/dock_bar_height_vectors.json';

class _ContextCapture extends StatelessComponent {
  const _ContextCapture(this.onBuild);

  final void Function(BuildContext context) onBuild;

  @override
  Component build(BuildContext context) {
    onBuild(context);
    return const Component.empty();
  }
}

/// Runs [read] against a themed build context and returns what it read.
T _read<T>(ComponentTester tester, T Function(BuildContext context) read) {
  late T value;
  pumpWithTheme(tester, _ContextCapture((context) => value = read(context)));
  return value;
}

Map<String, String> _inline(WebElementChrome chrome) =>
    chrome.inlineStyles!.properties;

/// A length the resolver emits as `<n>rem`, in px at the browser's 16px root.
double _remPx(String value) {
  final match = RegExp(r'^(-?[0-9.]+)rem$').firstMatch(value);
  expect(match, isNotNull, reason: 'not a rem length: $value');

  return double.parse(match!.group(1)!) * kRemDivisor;
}

/// A spacing length the resolver emits through `spaceCss` — a step's
/// `var(--coui-space-<n>)`, or the `<n>rem` of a value off the scale — in px.
double _spacePx(String value) {
  final match = RegExp(r'^var\(--coui-space-([0-9]+)\)$').firstMatch(value);
  if (match == null) return _remPx(value);

  return double.parse(match.group(1)!);
}

/// The dock root's own element in the rendered markup.
DomComponent _root(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .firstWhere((c) => c.attributes?['role'] == 'navigation');

Dock _dock({CoreDockSize? size, CoreDockStyle? style}) => Dock(
  size: size,
  dockStyle: style,
  items: const [
    CoreDockItemData<Component>(
      label: 'Home',
      icon: Icon(LucideIcons.house),
      isActive: true,
    ),
  ],
);

void main() {
  group('the root states a minimum height and no height', () {
    for (final size in CoreDockSize.values) {
      testComponents('${size.name}: the Core height, as min-height', (
        tester,
      ) async {
        final dock = _read(
          tester,
          (context) => resolveDock(context, size: size),
        );

        final style = _inline(dock.root);
        expect(style, isNot(contains('height')));
        expect(
          style['min-height'],
          '${CoreDockStyle.defaultsBySize[size]!.height! / kRemDivisor}rem',
        );
      });
    }

    testComponents('a height the caller states is a minimum too', (
      tester,
    ) async {
      final dock = _read(
        tester,
        (context) => resolveDock(
          context,
          dockStyle: const CoreDockStyle(height: 100),
        ),
      );

      expect(_inline(dock.root), isNot(contains('height')));
      expect(_inline(dock.root)['min-height'], '6.25rem');
    });

    testComponents('and so does the rendered root', (tester) async {
      pumpWithTheme(tester, _dock());

      final style = _root(tester).styles!.properties;
      expect(style, contains('min-height'));
      expect(style, isNot(contains('height')));
    });

    testComponents('no class fixes a height either', (tester) async {
      final dock = _read(tester, resolveDock);

      // `h-*` / `max-h-*` utilities: the bar would stop growing the moment one
      // sized it, whatever the inline style says.
      final classes = dock.root.className.split(' ');
      expect(classes.where((c) => RegExp('^(max-)?h-').hasMatch(c)), isEmpty);
    });

    testComponents('the items stay centred in the minimum', (tester) async {
      final dock = _read(tester, resolveDock);

      // `items-center` centres each item in the flex line, and a single-line
      // flex container clamps the line to its min-height — so the items sit
      // at the middle of the minimum while they fit.
      final classes = dock.root.className.split(' ');
      expect(classes, containsAll(['flex', 'flex-row', 'items-center']));
    });
  });

  group('the room kept above and below the row', () {
    ResolvedDockItem item(
      BuildContext context, {
      CoreDockStyle? style,
      bool isActive = true,
      bool tappable = true,
    }) => resolveDockItem(
      context,
      resolved: resolveDock(context, dockStyle: style),
      size: CoreDockSize.md,
      isActive: isActive,
      hasLabel: true,
      tappable: tappable,
    );

    testComponents(
      "is the size's padding, as margins through the spacing variable",
      (tester) async {
        final cell = _read(tester, item).clickable!;

        final style = _inline(cell);
        // md: the 10 above and below — larger than the plate's reach of 5.
        expect(style['margin-top'], 'var(--coui-space-10)');
        expect(style['margin-bottom'], 'var(--coui-space-10)');
      },
    );

    testComponents("is the plate's reach where that is larger, on both edges", (
      tester,
    ) async {
      final cell = _read(
        tester,
        (context) => item(
          context,
          style: const CoreDockStyle(
            indicatorPadding: CoreEdgeInsets.only(top: 4, bottom: 12),
          ),
        ),
      ).clickable!;

      expect(_inline(cell)['margin-top'], 'var(--coui-space-12)');
      expect(_inline(cell)['margin-bottom'], 'var(--coui-space-12)');
    });

    testComponents("is every item's, not the active one's alone", (
      tester,
    ) async {
      // The bar must not change height when the selection moves, so the room
      // is reserved for every item, active or not.
      final idle = _read(tester, (context) => item(context, isActive: false));
      final active = _read(tester, item);

      expect(_inline(idle.clickable!), _inline(active.clickable!));
    });

    testComponents('is on the item wrapper itself when nothing wraps it', (
      tester,
    ) async {
      // No `Clickable`, so the item wrapper is the flex item: it carries the
      // margins, and there is no `Clickable` chrome to carry them twice.
      final inert = _read(tester, (context) => item(context, tappable: false));
      final tappable = _read(tester, item);

      expect(inert.clickable, isNull);
      expect(_inline(inert.root)['margin-top'], 'var(--coui-space-10)');
      expect(_inline(inert.root)['margin-bottom'], 'var(--coui-space-10)');
      // And a tappable item's wrapper sits inside the `Clickable`, whose root
      // carries them: the wrapper adds none, or the room would be doubled.
      final wrapper = tappable.root.inlineStyles?.properties ?? const {};
      expect(wrapper, isNot(contains('margin-top')));
      expect(wrapper, isNot(contains('margin-bottom')));
    });

    testComponents("rides the flex item, never the bar's own padding", (
      tester,
    ) async {
      final dock = _read(tester, resolveDock);

      // The bar's own padding is its sides; above and below, the room is on
      // the items.
      final padding = CoreDockStyle.defaultsBySize[CoreDockSize.md]!.padding!;
      final style = _inline(dock.root);
      expect(style['padding-left'], spaceCss(padding.left));
      expect(style['padding-right'], spaceCss(padding.right));
      expect(style, isNot(contains('padding-top')));
      expect(style, isNot(contains('padding-bottom')));
      expect(style, isNot(contains('padding')));
    });

    testComponents('reaches the flex item of a tappable item, and of an inert '
        'one', (tester) async {
      // The `Clickable` root is the flex item of a tappable item and the item
      // wrapper is the flex item of an inert one: the margin goes on exactly
      // one element of each, so it is neither lost nor doubled.
      pumpWithTheme(
        tester,
        Dock(
          items: [
            CoreDockItemData<Component>(
              label: 'Tap',
              icon: const Icon(LucideIcons.house),
              onPressed: () {},
            ),
            const CoreDockItemData<Component>(
              label: 'Inert',
              icon: Icon(LucideIcons.house),
            ),
          ],
        ),
      );

      final withMargin = find
          .byType(DomComponent)
          .evaluate()
          .map((e) => e.component as DomComponent)
          .where(
            (c) => c.styles?.properties.containsKey('margin-top') ?? false,
          )
          .toList();
      expect(withMargin, hasLength(2));
      // The tappable one is the Clickable's root (a button); the inert one is
      // the item wrapper itself, not inside a Clickable.
      expect(
        withMargin.where((c) => c.attributes?['role'] == 'button'),
        hasLength(1),
      );
      expect(
        withMargin.where((c) => (c.classes ?? '').contains('flex-col')),
        hasLength(1),
      );
    });
  });

  group('the declarations against the shared vector table', () {
    final doc =
        jsonDecode(File(_kVectorsPath).readAsStringSync())
            as Map<String, Object?>;
    final cases = (doc['cases']! as List).cast<Map<String, Object?>>();

    test('the vector table is not empty', () => expect(cases, isNotEmpty));

    for (final c in cases) {
      // The room kept for the pill is on the `Clickable` of a tappable item
      // and on the wrapper of an inert one: the bar is the same either way.
      for (final tappable in [true, false]) {
        testComponents('${c['name']}${tappable ? '' : ' (items inert)'}', (
          tester,
        ) async {
          final size = CoreDockSize.values.byName(c['size']! as String);
          final iconSize = (c['iconSize']! as num).toDouble();
          CoreEdgeInsets? vertical(String key) {
            final padding = c[key] as Map<String, Object?>?;
            if (padding == null) return null;
            final own = CoreDockStyle.defaultsBySize[size]!.padding!;

            return CoreEdgeInsets.fromLTRB(
              key == 'padding' ? own.left : 0,
              (padding['top']! as num).toDouble(),
              key == 'padding' ? own.right : 0,
              (padding['bottom']! as num).toDouble(),
            );
          }

          final style = CoreDockStyle(
            padding: vertical('padding'),
            indicatorPadding: vertical('indicatorPadding'),
            iconStyle: CoreIconStyle(size: iconSize),
          );
          late ResolvedDock dock;
          late ResolvedDockItem item;
          pumpWithTheme(
            tester,
            Builder(
              builder: (context) {
                dock = resolveDock(context, size: size, dockStyle: style);
                item = resolveDockItem(
                  context,
                  resolved: dock,
                  size: size,
                  isActive: true,
                  hasLabel: false,
                  tappable: tappable,
                );

                return const Text('probe');
              },
            ),
          );

          // What CSS makes of a border-box flex container with a min-height:
          // the line is clamped to the minimum, and the box is the larger of
          // that and what the items (their margins included), the padding and
          // the border ask.
          final rootStyle = _inline(dock.root);
          final minimum = _remPx(rootStyle['min-height']!);
          final flexItem = tappable ? item.clickable! : item.root;
          final margins =
              _spacePx(_inline(flexItem)['margin-top']!) +
              _spacePx(_inline(flexItem)['margin-bottom']!);
          // The line is on both edges.
          expect(
            _inline(dock.root)['border-width'],
            strokeWidthCss(CoreDockStyle.defaultBorderWidth),
          );
          final border = 2 * (doc['border']! as num).toDouble();
          final holder = _remPx(_inline(item.icon)['height']!);
          expect(holder, iconSize);

          final bar = holder + margins + border;
          expect(bar > minimum ? bar : minimum, (c['bar']! as num).toDouble());
        });
      }
    }
  });

  group('the other chrome of the bar', () {
    testComponents('the line is drawn all round, docked or floating', (
      tester,
    ) async {
      final docked = _read(tester, resolveDock);
      final floating = _read(
        tester,
        (context) => resolveDock(
          context,
          dockStyle: const CoreDockStyle(
            barMargin: CoreEdgeInsets.all(CoreSpace.space16),
          ),
        ),
      );

      for (final dock in [docked, floating]) {
        expect(_inline(dock.root)['border-width'], isNotNull);
        expect(_inline(dock.root)['border-style'], 'solid');
        expect(_inline(dock.root), isNot(contains('border-top-width')));
      }
      // A floating bar still states its minimum, and the floating margin.
      expect(_inline(floating.root), contains('min-height'));
      expect(_inline(floating.root), contains('margin'));
    });
  });
}
