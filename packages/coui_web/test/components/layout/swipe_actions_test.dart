// Web `SwipeActions` — the markup a server renders, the resolver's numbers and
// the scope. `jaspr_test`'s `ComponentTester` has no real DOM events, so a
// swipe cannot be performed here: what the row does with a pointer is replayed
// on its model in `swipe_actions_row_test.dart` against the shared table, and
// the DOM half (listeners, capture, the measured layout, the settle) is read
// off a live page by the Chrome probe in `tool/parity`.
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

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

List<DomComponent> _doms() => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .toList();

Iterable<DomComponent> _withAttribute(String name, [String? value]) =>
    _doms().where((dom) {
      final attributes = dom.attributes;
      if (attributes == null || !attributes.containsKey(name)) return false;

      return value == null || attributes[name] == value;
    });

DomComponent _root() => _withAttribute('data-swipe-actions').single;

DomComponent _platter(String side) =>
    _withAttribute('data-swipe-platter', side).single;

String _classes(DomComponent dom) => dom.classes ?? '';

Map<String, String> _inline(DomComponent dom) =>
    dom.styles?.properties ?? const {};

/// The `aria-label` of every composed button, in document order.
List<String?> _buttonLabels() => _doms()
    .where((dom) => dom.tag == 'button')
    .map((dom) => dom.attributes?['aria-label'])
    .toList();

CoreSwipeAction<Component> _action(
  String label, {
  CoreSwipeActionVariant variant = CoreSwipeActionVariant.defaultVariant,
  bool enabled = true,
}) => CoreSwipeAction<Component>(
  label: label,
  icon: const Icon(LucideIcons.house),
  variant: variant,
  enabled: enabled,
  onPressed: () {},
);

SwipeActions _row({
  List<CoreSwipeAction<Component>> leading = const [],
  List<CoreSwipeAction<Component>> trailing = const [],
  bool showLabels = true,
  bool? enabled,
  CoreSwipeActionsStyle? style,
  String? id,
  String? classes,
}) => SwipeActions(
  id: id,
  classes: classes,
  leadingActions: leading,
  trailingActions: trailing,
  showLabels: showLabels,
  enabled: enabled,
  swipeActionsStyle: style,
  child: const Text('Row content'),
);

/// Shows one row and replaces it from its own `setState`, so the row reaches
/// `didUpdateComponent`.
///
/// `ComponentTester.pumpComponent` mounts a fresh root instead of updating the
/// tree, so a second pump runs `initState` again and an assertion about an
/// *update* would pass without that path ever running.
class _RowHost extends StatefulComponent {
  const _RowHost({required this.initial, required this.onState});

  final SwipeActions initial;

  /// Hands the live state back on every build, since `setState` is
  /// `@protected` and a test sits outside the component tree.
  final void Function(_RowHostState state) onState;

  @override
  State<_RowHost> createState() => _RowHostState();
}

class _RowHostState extends State<_RowHost> {
  late SwipeActions row = component.initial;

  void show(SwipeActions next) => setState(() => row = next);

  @override
  Component build(BuildContext context) {
    component.onState(this);

    return row;
  }
}

void main() {
  group('markup', () {
    testComponents('the root clips the travel and leaves vertical pan alone', (
      tester,
    ) async {
      pumpWithTheme(tester, _row(trailing: [_action('Delete')]));

      final root = _root();
      expect(
        _classes(root).split(' '),
        containsAll(['relative', 'overflow-x-clip']),
      );
      expect(
        _classes(root).split(' '),
        isNot(contains('overflow-hidden')),
        reason: 'a focus ring over the row edge must stay visible',
      );
      expect(_inline(root)['touch-action'], 'pan-y');
      expect(root.attributes?['data-swipe-state'], 'closed');
      expect(root.attributes?['tabindex'], '-1');
    });

    testComponents(
      'a closed row is at rest and its platters are as wide as nothing',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          _row(leading: [_action('Pin')], trailing: [_action('Delete')]),
        );

        final row = _withAttribute('data-swipe-row').single;
        expect(_inline(row)['transform'], 'none');
        expect(_inline(_platter('leading'))['width'], '0px');
        expect(_inline(_platter('trailing'))['width'], '0px');
      },
    );

    testComponents('only a side with actions has a platter', (tester) async {
      pumpWithTheme(tester, _row(trailing: [_action('Delete')]));

      expect(_withAttribute('data-swipe-platter', 'leading'), isEmpty);
      expect(_withAttribute('data-swipe-platter', 'trailing'), hasLength(1));
    });

    testComponents('a platter hugs its own edge, whatever way the text runs', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(leading: [_action('Pin')], trailing: [_action('Delete')]),
      );

      final leading = _classes(_platter('leading')).split(' ');
      final trailing = _classes(_platter('trailing')).split(' ');
      // Logical edges and logical justification: they follow `dir` by
      // themselves, which is what lets the model stay physical.
      expect(
        leading,
        containsAll(['absolute', 'inset-y-0', 'start-0', 'justify-start']),
      );
      expect(
        trailing,
        containsAll(['absolute', 'inset-y-0', 'end-0', 'justify-end']),
      );
      expect(leading, isNot(contains('end-0')));
      expect(trailing, isNot(contains('start-0')));
    });

    testComponents('DOM order is visual order: the first action is outermost', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(
          leading: [_action('A'), _action('B')],
          trailing: [_action('C'), _action('D')],
        ),
      );

      // Leading, as declared (A at the start edge); trailing backwards (C,
      // the first, at the end edge).
      expect(_buttonLabels(), ['A', 'B', 'D', 'C']);
    });

    testComponents('each action is a button named by its label', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(
          trailing: [
            _action('Archive'),
            _action('Delete', variant: CoreSwipeActionVariant.destructive),
          ],
        ),
      );

      expect(_buttonLabels(), ['Delete', 'Archive']);
    });

    testComponents('the visible label is hidden from assistive technology', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(trailing: [_action('Archive'), _action('Delete')]),
      );

      final labels = _withAttribute(
        'aria-hidden',
        'true',
      ).where((dom) => _classes(dom).contains('truncate')).toList();
      expect(labels, hasLength(2), reason: 'one visible label per action');
      for (final label in labels) {
        expect(_inline(label)['text-align'], 'center');
        expect(_classes(label).split(' '), contains('w-full'));
      }
      expect(find.text('Archive'), findsOneComponent);
      expect(find.text('Delete'), findsOneComponent);
    });

    testComponents('showLabels: false draws no label, and keeps the name', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(trailing: [_action('Delete')], showLabels: false),
      );

      expect(
        _withAttribute(
          'aria-hidden',
          'true',
        ).where((dom) => _classes(dom).contains('truncate')),
        isEmpty,
      );
      expect(find.text('Delete'), findsNothing);
      expect(_buttonLabels(), ['Delete']);
    });

    testComponents(
      'the actions stay reachable: nothing is hidden from layout or the tree',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          _row(leading: [_action('Pin')], trailing: [_action('Delete')]),
        );

        for (final side in ['leading', 'trailing']) {
          final platter = _platter(side);
          final within = [
            platter,
            ..._withAttribute('data-swipe-strip'),
            ..._withAttribute('data-swipe-cell'),
          ];
          for (final dom in within) {
            final inline = _inline(dom);
            expect(inline['display'], isNot('none'));
            expect(inline['visibility'], isNot('hidden'));
            expect(_classes(dom).split(' '), isNot(contains('hidden')));
            expect(_classes(dom).split(' '), isNot(contains('invisible')));
            expect(dom.attributes?['aria-hidden'], isNull);
            expect(dom.attributes?.containsKey('hidden'), isNot(true));
          }
          // Clipped, not scrollable: a focused action cannot scroll its strip
          // out of place.
          expect(_classes(platter).split(' '), contains('overflow-clip'));
          expect(
            _classes(platter).split(' '),
            isNot(contains('overflow-hidden')),
          );
        }
      },
    );

    testComponents('a strip is its natural width and its cells are fixed', (
      tester,
    ) async {
      pumpWithTheme(tester, _row(trailing: [_action('A'), _action('B')]));

      final strip = _withAttribute('data-swipe-strip').single;
      expect(
        _classes(strip).split(' '),
        containsAll(['flex', 'shrink-0', 'w-max', 'h-full']),
      );
      expect(_inline(strip)['padding-inline'], 'var(--coui-space-12)');
      expect(_inline(strip)['gap'], 'var(--coui-space-12)');
      for (final cell in _withAttribute('data-swipe-cell')) {
        expect(_inline(cell)['width'], 'var(--coui-control-height-48)');
        expect(_classes(cell).split(' '), contains('shrink-0'));
      }
    });

    testComponents(
      'each button is a circle of the lg rung in its action’s variant',
      (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          _row(
            trailing: [
              _action('Archive'),
              _action('Delete', variant: CoreSwipeActionVariant.destructive),
            ],
          ),
        );

        final buttons = find
            .byType(Button)
            .evaluate()
            .map((e) => e.component as Button)
            .toList();
        expect(buttons, hasLength(2));
        for (final button in buttons) {
          expect(button.shape, CoreButtonShape.circle);
          expect(button.size, CoreComponentSize.lg);
        }
        // DOM order: Delete, then Archive.
        expect(buttons.map((composed) => composed.variant), [
          CoreButtonVariant.destructive,
          CoreButtonVariant.secondary,
        ]);
      },
    );

    testComponents(
      'the composed buttons get the stated button style, and none otherwise',
      (tester) async {
        const stated = CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        );
        List<CoreButtonStyle?> styles() => find
            .byType(Button)
            .evaluate()
            .map((e) => (e.component as Button).buttonStyle)
            .toList();

        pumpWithTheme(tester, _row(trailing: [_action('A'), _action('B')]));
        expect(styles(), [null, null]);

        pumpWithTheme(
          tester,
          _row(
            trailing: [_action('A'), _action('B')],
            style: const CoreSwipeActionsStyle(actionButtonStyle: stated),
          ),
        );
        expect(styles(), hasLength(2));
        for (final style in styles()) {
          expect(style, same(stated));
        }
      },
    );

    testComponents('a disabled action is a disabled button', (tester) async {
      pumpWithTheme(
        tester,
        _row(trailing: [_action('Archive', enabled: false), _action('Delete')]),
      );

      final buttons = find
          .byType(Button)
          .evaluate()
          .map((e) => e.component as Button)
          .toList();
      // Delete first in the DOM, Archive (the first action, disabled) last.
      expect(buttons.map((composed) => composed.enabled), [true, false]);
    });

    testComponents('a disabled row exposes no action at all', (tester) async {
      pumpWithTheme(
        tester,
        _row(
          leading: [_action('Pin')],
          trailing: [_action('Delete')],
          enabled: false,
        ),
      );

      expect(_buttonLabels(), isEmpty);
      expect(_withAttribute('data-swipe-platter'), isEmpty);
      expect(_inline(_root()).containsKey('touch-action'), isFalse);
      expect(find.text('Row content'), findsOneComponent);
    });

    // An action that goes away hands its focus to the root, and an attribute
    // dropped by the same update would drop the focus with it.
    for (final (name, row) in <(String, SwipeActions)>[
      ('a row that can be swiped', _row(trailing: [_action('Delete')])),
      (
        'a disabled row',
        _row(trailing: [_action('Delete')], enabled: false),
      ),
      ('a row with no actions', _row()),
    ]) {
      testComponents(
        'the root of $name is a place focus can be sent to, never a Tab stop',
        (tester) async {
          pumpWithTheme(tester, row);

          expect(_root().attributes?['tabindex'], '-1');
        },
      );
    }

    testComponents('a row with no actions is just its content', (tester) async {
      pumpWithTheme(tester, _row());

      expect(_withAttribute('data-swipe-platter'), isEmpty);
      expect(_buttonLabels(), isEmpty);
      expect(_inline(_root()).containsKey('touch-action'), isFalse);
      expect(find.text('Row content'), findsOneComponent);
    });

    testComponents('a closed row has no tap catcher over its content', (
      tester,
    ) async {
      pumpWithTheme(tester, _row(trailing: [_action('Delete')]));

      expect(_withAttribute('data-swipe-tap-catcher'), isEmpty);
    });

    testComponents('identity, classes and css pass through to the root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        SwipeActions(
          id: 'row-7',
          classes: 'caller-class',
          css: const Styles(raw: {'margin': '0'}),
          attributes: const {'aria-label': 'Order 7', 'data-extra': 'x'},
          trailingActions: [_action('Delete')],
          child: const Text('Row content'),
        ),
      );

      final root = _root();
      expect(root.id, 'row-7');
      expect(
        _classes(root).split(' '),
        containsAll(['caller-class', 'relative']),
      );
      expect(_inline(root)['margin'], '0');
      expect(_inline(root)['touch-action'], 'pan-y', reason: 'kept beside css');
      expect(root.attributes?['aria-label'], 'Order 7');
      expect(root.attributes?['data-extra'], 'x');
    });

    testComponents('an instance style reaches the rendered numbers', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        _row(
          trailing: [_action('Delete')],
          style: const CoreSwipeActionsStyle(
            actionSpacing: 16,
            platterInset: 8,
            actionWidth: 56,
          ),
        ),
      );

      final strip = _withAttribute('data-swipe-strip').single;
      expect(_inline(strip)['padding-inline'], 'var(--coui-space-8)');
      expect(_inline(strip)['gap'], 'var(--coui-space-16)');
      expect(
        _inline(_withAttribute('data-swipe-cell').single)['width'],
        'var(--coui-control-height-56)',
      );
    });
  });

  group('resolver', () {
    testComponents('a closed, resting row has no transform and no reveal', (
      tester,
    ) async {
      final resolved = resolveSwipeActions(
        _themedContext(tester),
        offset: 0,
        revealedSide: null,
        dragging: false,
        inFullSwipeZone: false,
        interactive: true,
      );

      expect(resolved.row.inlineStyles?.properties['transform'], 'none');
      expect(resolved.leadingPlatter.inlineStyles?.properties['width'], '0px');
      expect(resolved.trailingPlatter.inlineStyles?.properties['width'], '0px');
    });

    testComponents(
      'the row moves by the physical offset and the platter by its size',
      (
        tester,
      ) async {
        final context = _themedContext(tester);

        final trailing = resolveSwipeActions(
          context,
          offset: -80,
          revealedSide: CoreSwipeSide.trailing,
          dragging: true,
          inFullSwipeZone: false,
          interactive: true,
        );
        expect(
          trailing.row.inlineStyles?.properties['transform'],
          'translateX(-80px)',
        );
        expect(
          trailing.trailingPlatter.inlineStyles?.properties['width'],
          '80px',
        );
        expect(
          trailing.leadingPlatter.inlineStyles?.properties['width'],
          '0px',
        );

        // Right to left puts the leading platter on the left of a row moved
        // left: the model hands the side, the resolver only reads it.
        final leading = resolveSwipeActions(
          context,
          offset: 72,
          revealedSide: CoreSwipeSide.leading,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
        );
        expect(
          leading.row.inlineStyles?.properties['transform'],
          'translateX(72px)',
        );
        expect(
          leading.leadingPlatter.inlineStyles?.properties['width'],
          '72px',
        );
        expect(
          leading.trailingPlatter.inlineStyles?.properties['width'],
          '0px',
        );
      },
    );

    testComponents('a fractional offset keeps its two decimals', (
      tester,
    ) async {
      final resolved = resolveSwipeActions(
        _themedContext(tester),
        offset: -151.5,
        revealedSide: CoreSwipeSide.trailing,
        dragging: true,
        inFullSwipeZone: false,
        interactive: true,
      );

      expect(
        resolved.row.inlineStyles?.properties['transform'],
        'translateX(-151.50px)',
      );
      expect(
        resolved.trailingPlatter.inlineStyles?.properties['width'],
        '151.50px',
      );
    });

    testComponents(
      'the settle is a token-routed transition, and none while dragging',
      (
        tester,
      ) async {
        final context = _themedContext(tester);

        final settling = resolveSwipeActions(
          context,
          offset: -132,
          revealedSide: CoreSwipeSide.trailing,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
        );
        final dragging = resolveSwipeActions(
          context,
          offset: -60,
          revealedSide: CoreSwipeSide.trailing,
          dragging: true,
          inFullSwipeZone: false,
          interactive: true,
        );

        // The duration is the Core contract's, through the variable that
        // `prefers-reduced-motion` zeroes; the curve is the `enter` alias.
        final ms =
            CoreSwipeActionsContract.defaultSettleDuration.inMilliseconds;
        expect(ms, CoreDuration.normal);
        const curve = 'var(--easing-ease-out)';
        expect(
          settling.row.inlineStyles?.properties['transition'],
          'transform var(--coui-duration-$ms) $curve',
        );
        expect(
          settling.trailingPlatter.inlineStyles?.properties['transition'],
          'width var(--coui-duration-$ms) $curve',
        );
        expect(dragging.row.inlineStyles?.properties['transition'], 'none');
        expect(
          dragging.trailingPlatter.inlineStyles?.properties['transition'],
          'none',
        );
        expect(
          dragging.leadingPlatter.inlineStyles?.properties['transition'],
          'none',
        );
        expect(dragging.root.className.split(' '), contains('select-none'));
        expect(
          settling.root.className.split(' '),
          isNot(contains('select-none')),
        );
      },
    );

    testComponents(
      'the default numbers are the Core defaults, through the variables',
      (
        tester,
      ) async {
        final resolved = resolveSwipeActions(
          _themedContext(tester),
          offset: 0,
          revealedSide: null,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
        );

        expect(
          resolved.strip.inlineStyles?.properties['padding-inline'],
          'var(--coui-space-12)',
        );
        expect(
          resolved.strip.inlineStyles?.properties['gap'],
          'var(--coui-space-12)',
        );
        expect(
          resolved.cell.inlineStyles?.properties['width'],
          'var(--coui-control-height-48)',
        );
        expect(CoreSwipeActionsStyle.defaultActionWidth, 48);
        expect(CoreSwipeActionsStyle.defaultActionSpacing, 12);
        expect(CoreSwipeActionsStyle.defaultPlatterInset, 12);
        expect(
          resolved.labelGapStyle.size,
          CoreSwipeActionsStyle.defaultLabelGapStyle.size,
        );
        expect(
          resolved.actionButtonStyle,
          isNull,
          reason: 'default-less by design: the button resolves its own chrome',
        );
      },
    );

    testComponents(
      'a transparent platter paints nothing; a coloured one a token class',
      (
        tester,
      ) async {
        final context = _themedContext(tester);

        final bare = resolveSwipeActions(
          context,
          offset: -50,
          revealedSide: CoreSwipeSide.trailing,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
        );
        expect(
          bare.trailingPlatter.className.split(' '),
          everyElement(isNot(startsWith('bg-'))),
        );
        expect(
          bare.trailingPlatter.inlineStyles?.properties.containsKey(
            'background-color',
          ),
          isFalse,
        );

        final tinted = resolveSwipeActions(
          context,
          offset: -50,
          revealedSide: CoreSwipeSide.trailing,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
          swipeActionsStyle: const CoreSwipeActionsStyle(
            platterColor: CoreColor.token(CoreColors.surfaceContainer),
          ),
        );
        expect(
          tinted.trailingPlatter.className
              .split(' ')
              .where((cls) => cls.startsWith('bg-')),
          hasLength(1),
        );
      },
    );

    testComponents(
      'the label carries the label role and sits on one centred line',
      (
        tester,
      ) async {
        final resolved = resolveSwipeActions(
          _themedContext(tester),
          offset: 0,
          revealedSide: null,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
        );

        final classes = resolved.label.className.split(' ');
        expect(classes, containsAll(['truncate', 'w-full']));
        expect(classes.any((cls) => cls.startsWith('text-')), isTrue);
        expect(resolved.label.inlineStyles?.properties['text-align'], 'center');
      },
    );

    group('the full-swipe cue', () {
      testComponents('no cue at the default scale of 1', (tester) async {
        final resolved = resolveSwipeActions(
          _themedContext(tester),
          offset: -270,
          revealedSide: CoreSwipeSide.trailing,
          dragging: true,
          inFullSwipeZone: true,
          interactive: true,
        );

        expect(
          resolved.outerCell.inlineStyles?.properties.containsKey('transform'),
          isFalse,
        );
        expect(
          resolved.cell.inlineStyles?.properties.containsKey('transform'),
          isFalse,
        );
      });

      testComponents(
        'a scale grows the first cell, only in the zone, and only it',
        (
          tester,
        ) async {
          final context = _themedContext(tester);
          const style = CoreSwipeActionsStyle(fullSwipeScale: 1.08);

          final inZone = resolveSwipeActions(
            context,
            offset: -270,
            revealedSide: CoreSwipeSide.trailing,
            dragging: true,
            inFullSwipeZone: true,
            interactive: true,
            swipeActionsStyle: style,
          );
          final outside = resolveSwipeActions(
            context,
            offset: -100,
            revealedSide: CoreSwipeSide.trailing,
            dragging: true,
            inFullSwipeZone: false,
            interactive: true,
            swipeActionsStyle: style,
          );

          expect(
            inZone.outerCell.inlineStyles?.properties['transform'],
            'scale(1.08)',
          );
          expect(
            outside.outerCell.inlineStyles?.properties['transform'],
            'none',
          );
          expect(
            inZone.cell.inlineStyles?.properties.containsKey('transform'),
            isFalse,
          );
          // The cue happens during the drag, so it keeps a transition of its
          // own when the row's is off: the settle's duration (through the
          // variable reduced motion zeroes) on the `move` curve — the one
          // Flutter's AnimatedScale rides — while the row's settle stays on
          // `enter`.
          final ms =
              CoreSwipeActionsContract.defaultSettleDuration.inMilliseconds;
          expect(
            inZone.outerCell.inlineStyles?.properties['transition'],
            'transform var(--coui-duration-$ms) var(--easing-ease-in-out)',
          );
          expect(
            outside.outerCell.inlineStyles?.properties['transition'],
            'transform var(--coui-duration-$ms) var(--easing-ease-in-out)',
            reason: 'the cue also animates back out',
          );
          final settling = resolveSwipeActions(
            context,
            offset: -132,
            revealedSide: CoreSwipeSide.trailing,
            dragging: false,
            inFullSwipeZone: false,
            interactive: true,
            swipeActionsStyle: style,
          );
          expect(
            settling.row.inlineStyles?.properties['transition'],
            'transform var(--coui-duration-$ms) var(--easing-ease-out)',
            reason: 'the settle keeps its own curve',
          );
          expect(inZone.row.inlineStyles?.properties['transition'], 'none');
        },
      );
    });

    testComponents(
      'only an interactive row claims vertical pan for the browser',
      (
        tester,
      ) async {
        final context = _themedContext(tester);
        ResolvedSwipeActions resolve({required bool interactive}) =>
            resolveSwipeActions(
              context,
              offset: 0,
              revealedSide: null,
              dragging: false,
              inFullSwipeZone: false,
              interactive: interactive,
            );

        expect(
          resolve(
            interactive: true,
          ).root.inlineStyles?.properties['touch-action'],
          'pan-y',
        );
        expect(resolve(interactive: false).root.inlineStyles, isNull);
      },
    );

    testComponents('the instance style wins over the theme, field by field', (
      tester,
    ) async {
      final themedData = ThemeData.coui.copyWith(
        coreComponentTheme: const CoreComponentTheme(
          swipeActions: CoreSwipeActionsTheme(
            style: CoreSwipeActionsStyle(actionSpacing: 20, platterInset: 4),
          ),
        ),
      );
      late BuildContext context;
      tester.pumpComponent(
        Theme(data: themedData, child: _ContextCapture((c) => context = c)),
      );

      final themed = resolveSwipeActions(
        context,
        offset: 0,
        revealedSide: null,
        dragging: false,
        inFullSwipeZone: false,
        interactive: true,
      );
      expect(
        themed.strip.inlineStyles?.properties['gap'],
        'var(--coui-space-20)',
      );
      expect(
        themed.strip.inlineStyles?.properties['padding-inline'],
        'var(--coui-space-4)',
      );

      final instance = resolveSwipeActions(
        context,
        offset: 0,
        revealedSide: null,
        dragging: false,
        inFullSwipeZone: false,
        interactive: true,
        swipeActionsStyle: const CoreSwipeActionsStyle(platterInset: 16),
      );
      expect(
        instance.strip.inlineStyles?.properties['gap'],
        'var(--coui-space-20)',
      );
      expect(
        instance.strip.inlineStyles?.properties['padding-inline'],
        'var(--coui-space-16)',
      );
    });

    testComponents(
      'a stated button style is forwarded unchanged; a stated gap merges',
      (tester) async {
        const stated = CoreButtonStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        );
        final resolved = resolveSwipeActions(
          _themedContext(tester),
          offset: 0,
          revealedSide: null,
          dragging: false,
          inFullSwipeZone: false,
          interactive: true,
          swipeActionsStyle: const CoreSwipeActionsStyle(
            labelGapStyle: CoreGapStyle(size: 8),
            actionButtonStyle: stated,
          ),
        );

        expect(resolved.actionButtonStyle, same(stated));
        expect(resolved.labelGapStyle.size, 8);
      },
    );
  });

  group('SwipeActionScope', () {
    testComponents('rows below it share one scope; rows outside it have none', (
      tester,
    ) async {
      CoreSwipeExclusivity? inFirst;
      CoreSwipeExclusivity? inSecond;
      CoreSwipeExclusivity? outside;

      tester.pumpComponent(
        div([
          SwipeActionScope(
            child: div([
              _ContextCapture((c) => inFirst = SwipeActionScope.maybeOf(c)),
              _ContextCapture((c) => inSecond = SwipeActionScope.maybeOf(c)),
            ]),
          ),
          _ContextCapture((c) => outside = SwipeActionScope.maybeOf(c)),
        ]),
      );

      expect(inFirst, isNotNull);
      expect(inSecond, same(inFirst));
      expect(outside, isNull);
    });

    testComponents('two scopes are two claims', (tester) async {
      CoreSwipeExclusivity? first;
      CoreSwipeExclusivity? second;

      tester.pumpComponent(
        div([
          SwipeActionScope(
            child: _ContextCapture((c) => first = SwipeActionScope.maybeOf(c)),
          ),
          SwipeActionScope(
            child: _ContextCapture((c) => second = SwipeActionScope.maybeOf(c)),
          ),
        ]),
      );

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, isNot(same(second)));
    });

    testComponents('rows render the same inside a scope', (tester) async {
      pumpWithTheme(
        tester,
        SwipeActionScope(
          child: div([
            _row(trailing: [_action('Delete')], id: 'one'),
            _row(trailing: [_action('Delete')], id: 'two'),
          ]),
        ),
      );

      expect(_withAttribute('data-swipe-actions'), hasLength(2));
      expect(_withAttribute('data-swipe-state', 'closed'), hasLength(2));
    });
  });

  // Where focus goes when an update takes the actions away is read off a live
  // page by the Chrome probe: the VM has no document. What it can show is that
  // the update path runs there, without one, and leaves the markup right.
  group('an update to a mounted row', () {
    testComponents('a different number of actions rebuilds the platters', (
      tester,
    ) async {
      late _RowHostState host;
      pumpWithTheme(
        tester,
        _RowHost(
          onState: (state) => host = state,
          initial: _row(trailing: [_action('Archive'), _action('Delete')]),
        ),
      );
      expect(_buttonLabels(), ['Delete', 'Archive']);

      host.show(_row(trailing: [_action('Archive')]));
      await tester.pump();
      expect(_buttonLabels(), ['Archive']);

      host.show(
        _row(leading: [_action('Pin')], trailing: [_action('Archive')]),
      );
      await tester.pump();
      expect(_buttonLabels(), ['Pin', 'Archive']);
    });

    testComponents(
      'a row disabled in place loses its platters and keeps its root; '
      'enabled again it gets them back',
      (tester) async {
        late _RowHostState host;
        SwipeActions row({required bool enabled}) => _row(
          leading: [_action('Pin')],
          trailing: [_action('Delete')],
          enabled: enabled,
        );
        pumpWithTheme(
          tester,
          _RowHost(
            onState: (state) => host = state,
            initial: row(enabled: true),
          ),
        );
        expect(_buttonLabels(), ['Pin', 'Delete']);

        host.show(row(enabled: false));
        await tester.pump();
        expect(_buttonLabels(), isEmpty);
        expect(_withAttribute('data-swipe-platter'), isEmpty);
        expect(_root().attributes?['tabindex'], '-1');

        host.show(row(enabled: true));
        await tester.pump();
        expect(_buttonLabels(), ['Pin', 'Delete']);
      },
    );

    testComponents('a row left with no actions keeps its root', (tester) async {
      late _RowHostState host;
      pumpWithTheme(
        tester,
        _RowHost(
          onState: (state) => host = state,
          initial: _row(trailing: [_action('Delete')]),
        ),
      );
      expect(_buttonLabels(), ['Delete']);

      host.show(_row());
      await tester.pump();
      expect(_buttonLabels(), isEmpty);
      expect(_withAttribute('data-swipe-platter'), isEmpty);
      expect(_root().attributes?['tabindex'], '-1');
    });

    testComponents('an update that changes neither leaves the platters alone', (
      tester,
    ) async {
      late _RowHostState host;
      pumpWithTheme(
        tester,
        _RowHost(
          onState: (state) => host = state,
          initial: _row(trailing: [_action('Archive'), _action('Delete')]),
        ),
      );

      host.show(
        _row(
          trailing: [_action('Archive'), _action('Delete')],
          showLabels: false,
        ),
      );
      await tester.pump();
      expect(_buttonLabels(), ['Delete', 'Archive']);
    });
  });

  group('chain sugar', () {
    test('copyWith replaces only what it is given', () {
      final original = _row(
        leading: [_action('Pin')],
        trailing: [_action('Delete')],
        id: 'row-1',
      );

      final copy = original.copyWith(showLabels: false, id: 'row-2');

      expect(copy.showLabels, isFalse);
      expect(copy.id, 'row-2');
      expect(copy.leadingActions, same(original.leadingActions));
      expect(copy.trailingActions, same(original.trailingActions));
      expect(copy.child, same(original.child));
      expect(copy.allowsFullSwipe, original.allowsFullSwipe);
      expect(copy.fullSwipeThreshold, original.fullSwipeThreshold);
    });

    test('withStyle merges a patch into the instance style', () {
      final original = _row(
        style: const CoreSwipeActionsStyle(actionSpacing: 16, platterInset: 8),
      );

      final patched = original.withStyle(
        const CoreSwipeActionsStyle(platterInset: 4, fullSwipeScale: 1.1),
      );

      expect(patched.swipeActionsStyle?.actionSpacing, 16);
      expect(patched.swipeActionsStyle?.platterInset, 4);
      expect(patched.swipeActionsStyle?.fullSwipeScale, 1.1);
      expect(original.swipeActionsStyle?.platterInset, 8, reason: 'unchanged');
    });

    test('withStyle on a row with no style starts from the patch', () {
      final patched = _row().withStyle(
        const CoreSwipeActionsStyle(actionWidth: 56),
      );

      expect(patched.swipeActionsStyle?.actionWidth, 56);
    });

    test('the defaults are the contract’s', () {
      final row = _row();

      expect(
        row.allowsFullSwipe,
        CoreSwipeActionsContract.defaultAllowsFullSwipe,
      );
      expect(
        row.fullSwipeThreshold,
        CoreSwipeActionsContract.defaultFullSwipeThreshold,
      );
      expect(row.showLabels, CoreSwipeActionsContract.defaultShowLabels);
      expect(row.enabled, isNull);
    });

    test('a threshold outside (0, 1] is refused', () {
      expect(
        () => SwipeActions(fullSwipeThreshold: 0, child: const Text('x')),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => SwipeActions(fullSwipeThreshold: 1.01, child: const Text('x')),
        throwsA(isA<AssertionError>()),
      );
      expect(
        const SwipeActions(fullSwipeThreshold: 1, child: Text('x')),
        isNotNull,
      );
    });
  });
}
