/// Client fixture for the Web half of the frame-timing harness: the shipped
/// `CoUIWeb` drawing glass scenes at a tier the page states, so a browser can
/// be asked how steadily it delivers frames for each.
///
/// The Flutter half is
/// `app/coui_widgetbook/integration_test/frame_timing_test.dart` and the scenes
/// are the same ones by name: a number of glass cards, glass cards laid over
/// one another, `SwipeActions` rows scrolling under a glass header, a drawer
/// left open, a context menu left open — each over a backdrop that moves every
/// frame, because glass over a still picture re-blurs nothing.
///
/// Nothing here measures. The page draws what it is told to and reports where
/// the pieces are; the orchestrator (`tool/frame_timing/frame_timing.dart`)
/// records the browser's frame intervals around it.
///
/// Page API (all on `window`):
///
///   couiFtMount(json)   draws a scene: `{scene, n, tier}` — `scene` is
///                       `glass-grid`, `glass-chain`, `swipe-list`,
///                       `drawer-open` or `menu-open`; `n` how many cards or
///                       rows; `tier` the quality tier stated (forced)
///   couiFtDrawer()      opens the drawer of the `drawer-open` scene
///
/// DOM ids the orchestrator drives: `ft-list` (the scroller of
/// `swipe-list`), `ft-menu-target` (right-click it for `menu-open`).
library;

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiFtMount')
external set _mount(JSFunction value);
@JS('couiFtDrawer')
external set _drawer(JSFunction value);

void main() => client.runApp(const _Root());

/// The page's own stylesheet: the backdrop's drift.
const String _kCss =
    '@keyframes ft-drift {'
    ' from { transform: translate(0, 0); }'
    ' to { transform: translate(var(--dx), var(--dy)); } }';

const List<String> _kColors = [
  '#e8334a',
  '#3b82f6',
  '#22c55e',
  '#f59e0b',
  '#a855f7',
];

class _Root extends StatefulComponent {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  Map<String, Object?> _spec = const {'scene': 'glass-grid', 'n': 1};
  BuildContext? _below;

  @override
  void initState() {
    super.initState();
    _mount = ((String json) {
      setState(() => _spec = jsonDecode(json) as Map<String, Object?>);
    }).toJS;
    _drawer = (() {
      final below = _below;
      if (below == null) return;
      unawaited(
        openDrawer<void>(
          context: below,
          side: CoreDrawerSide.bottom,
          builder: (close) => Drawer(
            side: CoreDrawerSide.bottom,
            title: 'Frame timing',
            content: div([
              for (var i = 0; i < 6; i++) Text('Row ${i + 1}'),
            ]),
          ),
        ),
      );
    }).toJS;
  }

  @override
  Component build(BuildContext context) {
    final tier = CoreQualityTier.values.byName(
      (_spec['tier'] as String?) ?? 'full',
    );

    return CoUIWeb(
      theme: .coui,
      adaptiveQuality: CoreAdaptiveQuality(forced: tier),
      child: _Stage(spec: _spec, onBuilt: (context) => _below = context),
    );
  }
}

class _Stage extends StatelessComponent {
  const _Stage({required this.spec, required this.onBuilt});

  final Map<String, Object?> spec;
  final void Function(BuildContext context) onBuilt;

  @override
  Component build(BuildContext context) {
    onBuilt(context);
    final n = (spec['n'] as num?)?.toInt() ?? 1;

    return div(
      [
        const Component.element(tag: 'style', children: [RawText(_kCss)]),
        const _Backdrop(),
        switch (spec['scene']) {
          'glass-grid' => _cards(
            n,
            (index) => (16.0 + (index % 8) * 96, 16.0 + (index ~/ 8) * 56),
            (88, 48),
          ),
          'glass-chain' => _cards(
            n,
            (index) => (24.0 + index * 28, 24.0 + index * 14),
            (220, 130),
          ),
          'swipe-list' => _swipeList(n),
          'menu-open' => _menu(),
          _ => const div([]),
        },
      ],
      styles: const Styles(
        raw: {'position': 'fixed', 'inset': '0', 'overflow': 'hidden'},
      ),
    );
  }
}

/// Soft saturated blobs drifting over a dark field — content that changes every
/// frame, which is what a backdrop filter has to re-read.
class _Backdrop extends StatelessComponent {
  const _Backdrop();

  @override
  Component build(BuildContext context) => div(
    [
      for (var i = 0; i < 14; i++)
        div(
          const [],
          styles: Styles(
            raw: {
              'position': 'absolute',
              'left': '${(i * 53) % 90}%',
              'top': '${(i * 37) % 80}%',
              'width': '${92 + (i % 3) * 24}px',
              'height': '${92 + (i % 3) * 24}px',
              'border-radius': '50%',
              'background': _kColors[i % _kColors.length],
              '--dx': '${(i.isEven ? 1 : -1) * (120 + i * 9)}px',
              '--dy': '${(i % 3 == 0 ? 1 : -1) * (90 + i * 7)}px',
              'animation':
                  'ft-drift ${3 + i % 4}s ease-in-out infinite '
                  'alternate',
            },
          ),
        ),
    ],
    styles: const Styles(
      raw: {
        'position': 'absolute',
        'inset': '0',
        'background-color': '#0e0e10',
        'background-image':
            'repeating-linear-gradient(90deg, #ffffff 0 2px, transparent 2px '
            '40px)',
      },
    ),
  );
}

Component _cards(
  int count,
  (double, double) Function(int index) place,
  (double, double) size,
) => div([
  for (var i = 0; i < count; i++)
    Card(
      css: Styles(
        raw: {
          'position': 'absolute',
          'left': '${place(i).$1}px',
          'top': '${place(i).$2}px',
          'width': '${size.$1}px',
          'height': '${size.$2}px',
        },
      ),
      child: div(
        [Text('${i + 1}')],
        styles: const Styles(
          raw: {
            'display': 'flex',
            'align-items': 'center',
            'justify-content': 'center',
            'height': '100%',
          },
        ),
      ),
    ),
]);

Component _swipeList(int rows) => div([
  div(
    [
      for (var i = 0; i < rows; i++)
        SwipeActions(
          trailingActions: [
            CoreSwipeAction<Component>(
              label: 'Archive',
              icon: const Icon(LucideIcons.archive),
              onPressed: () {},
            ),
          ],
          child: div(
            [Text('Row ${i + 1}')],
            styles: const Styles(
              raw: {
                'height': '72px',
                'display': 'flex',
                'align-items': 'center',
                'padding': '0 16px',
              },
            ),
          ),
        ),
    ],
    id: 'ft-list',
    styles: const Styles(
      raw: {
        'position': 'absolute',
        'inset': '0',
        'overflow-y': 'auto',
        'padding-top': '88px',
      },
    ),
  ),
  Card(
    css: const Styles(
      raw: {
        'position': 'absolute',
        'left': '16px',
        'right': '16px',
        'top': '16px',
        'height': '56px',
      },
    ),
    child: const div(
      [Text('Glass header')],
      styles: Styles(
        raw: {
          'display': 'flex',
          'align-items': 'center',
          'justify-content': 'center',
          'height': '100%',
        },
      ),
    ),
  ),
]);

Component _menu() => div(
  [
    ContextMenu(
      items: [
        CoreMenuItem.action('Copy', onPressed: () {}),
        CoreMenuItem.action('Paste', onPressed: () {}),
        const CoreMenuItem.divider(),
        CoreMenuItem.action('Delete', onPressed: () {}),
      ],
      child: const div(
        [],
        id: 'ft-menu-target',
        styles: Styles(raw: {'width': '240px', 'height': '120px'}),
      ),
    ),
  ],
  styles: const Styles(
    raw: {
      'position': 'absolute',
      'inset': '0',
      'display': 'flex',
      'align-items': 'center',
      'justify-content': 'center',
    },
  ),
);
