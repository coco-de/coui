// The parts a bottom sheet is drawn with — a description under the title,
// the header without its close button or its rule, and the grab handle on
// the edge facing the screen centre — and the pointer wiring of the drag.
//
// The drag itself needs a real `web.PointerEvent` and real layout, which
// the VM does not have, so this file reaches what is reachable here: which
// handlers are bound and what touch behaviour the panel and its body state.
// The release rule is the Core one (`CoreDrawerContract.dismissesOnRelease`,
// tested in `coui_core`), and the Flutter twin drives a real drag in
// `packages/coui_flutter/test/components/overlay/drawer_sheet_test.dart`.

import 'dart:async';

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/overlay/swiper/swiper_style.dart';
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

/// Opens [drawer] over a real [OverlayHost] the way a page does.
class _DrawerOpener extends StatefulComponent {
  const _DrawerOpener(this.drawer);

  final Drawer drawer;

  @override
  State<_DrawerOpener> createState() => _DrawerOpenerState();
}

class _DrawerOpenerState extends State<_DrawerOpener> {
  @override
  void initState() {
    super.initState();
    // Deferred like every real caller: mounting notifies the host, and a
    // host `setState` reached from inside build throws.
    unawaited(
      Future<void>.microtask(() {
        if (!mounted) return;
        unawaited(
          openDrawer<void>(
            context: context,
            side: component.drawer.side,
            builder: (close) => component.drawer,
          ),
        );
      }),
    );
  }

  @override
  Component build(BuildContext context) => const span([], id: 'opener');
}

/// Opens a bottom [Swiper] by flipping its controlled `open`, as a page does.
class _SwiperOpener extends StatefulComponent {
  const _SwiperOpener({required this.showDragHandle, this.swiperStyle});

  final bool showDragHandle;
  final CoreSwiperStyle? swiperStyle;

  @override
  State<_SwiperOpener> createState() => _SwiperOpenerState();
}

class _SwiperOpenerState extends State<_SwiperOpener> {
  bool _open = false;

  @override
  void initState() {
    super.initState();
    unawaited(
      Future<void>.microtask(() {
        if (mounted) setState(() => _open = true);
      }),
    );
  }

  @override
  Component build(BuildContext context) => Swiper(
    open: _open,
    position: .bottom,
    showDragHandle: component.showDragHandle,
    swiperStyle: component.swiperStyle,
    overlayContent: const Component.text('overlay'),
    child: const span([]),
  );
}

Future<void> _open(ComponentTester tester, Drawer drawer) async {
  tester.pumpComponent(
    Theme.defaults(child: OverlayHost(child: _DrawerOpener(drawer))),
  );
  await tester.pump();
}

Future<void> _openSwiper(
  ComponentTester tester, {
  required bool showDragHandle,
  CoreSwiperStyle? swiperStyle,
}) async {
  tester.pumpComponent(
    Theme.defaults(
      child: OverlayHost(
        child: _SwiperOpener(
          showDragHandle: showDragHandle,
          swiperStyle: swiperStyle,
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump();
}

/// The rendered drawer panel — the only element carrying `role="dialog"`.
DomComponent _panel() =>
    find
            .byComponentPredicate(
              (c) => c is DomComponent && c.attributes?['role'] == 'dialog',
            )
            .evaluate()
            .single
            .component
        as DomComponent;

/// Whether [c] is the grab-handle box — decorative, so hidden from
/// assistive technology. The drawer builds its markup from `div`
/// components, so that is what the panel's children are.
bool _isHandle(Component c) =>
    (c is div && c.attributes?['aria-hidden'] == 'true') ||
    (c is DomComponent && c.attributes?['aria-hidden'] == 'true');

div _pillOf(Component handle) => (handle as div).children.single as div;

/// The panel's element children, with the empty header placeholder dropped.
List<div> _panelChildren() => _panel().children!.whereType<div>().toList();

Finder _closeButton() => find.byComponentPredicate(
  (c) =>
      c is DomComponent &&
      c.attributes?['aria-label'] ==
          DefaultCouiLocalizations.instance.buttonClose,
);

/// The header element — the one whose classes carry the header layout.
DomComponent _header() =>
    find
            .byComponentPredicate(
              (c) =>
                  c is DomComponent &&
                  (c.classes ?? '').contains('justify-between'),
            )
            .evaluate()
            .single
            .component
        as DomComponent;

void main() {
  group('DrawerScrubController public reuse', () {
    test('an explicit update can start another scrub after settling open', () {
      final controller = DrawerScrubController()
        ..update(.3)
        ..settle(open: true);
      expect(controller.progress, isNull);
      controller.update(.7);
      expect(controller.progress, .7);
    });

    test(
      'an explicit update can start another scrub after settling closed',
      () {
        final controller = DrawerScrubController()
          ..update(.3)
          ..settle(open: false)
          ..update(.7);
        expect(controller.progress, .7);
        controller.update(2);
        expect(controller.progress, 1);
        controller.update(-1);
        expect(controller.progress, 0);
      },
    );
  });

  group('Drawer sheet parts — defaults', () {
    test('match the contract, so nothing already on screen changes', () {
      const drawer = Drawer(content: Component.text('x'));

      expect(drawer.description, isNull);
      expect(drawer.showDragHandle, CoreDrawerContract.defaultShowDragHandle);
      expect(drawer.showDragHandle, isFalse);
      expect(drawer.showCloseButton, CoreDrawerContract.defaultShowCloseButton);
      expect(drawer.showCloseButton, isTrue);
    });

    test('copyWith carries the new fields', () {
      final copy = const Drawer(content: Component.text('x')).copyWith(
        description: 'desc',
        showDragHandle: true,
        showCloseButton: false,
      );

      expect(copy.description, 'desc');
      expect(copy.showDragHandle, isTrue);
      expect(copy.showCloseButton, isFalse);
    });
  });

  group('Drawer description', () {
    testComponents('sits under the title in the supporting-text style', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Choose a currency',
          description: 'The currency you will receive',
          content: Component.text('body'),
        ),
      );

      expect(find.text('Choose a currency'), findsOneComponent);
      expect(find.text('The currency you will receive'), findsOneComponent);
      expect(find.byType(Gap), findsOneComponent);

      final expected = emitTypography(
        null,
        CoreDrawerStyle.defaultDescriptionStyle,
      ).className;
      expect(
        find.byComponentPredicate(
          (c) =>
              c is DomComponent &&
              (c.classes ?? '').contains(expected) &&
              c.children?.length == 1,
        ),
        findsOneComponent,
        reason: 'the description cell carries the role and tone classes',
      );
    });

    testComponents('a description alone still draws the header', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          description: 'Only a description',
          content: Component.text('body'),
        ),
      );

      expect(find.text('Only a description'), findsOneComponent);
      expect(find.byType(Gap), findsNothing);
      expect(_closeButton(), findsOneComponent);
    });

    testComponents('no title and no description → no header', (tester) async {
      await _open(
        tester,
        const Drawer(side: .bottom, content: Component.text('body')),
      );

      expect(_closeButton(), findsNothing);
    });
  });

  group('Drawer showCloseButton', () {
    testComponents('is on by default', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          content: Component.text('body'),
        ),
      );

      expect(_closeButton(), findsOneComponent);
    });

    testComponents('off — the title stays, the button goes', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          showCloseButton: false,
          content: Component.text('body'),
        ),
      );

      expect(find.text('Title'), findsOneComponent);
      expect(_closeButton(), findsNothing);
    });
  });

  group('Drawer header rule', () {
    testComponents('is the 1px border class by default', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          content: Component.text('body'),
        ),
      );

      final header = _header();
      expect(header.classes!.split(' '), contains('border-b'));
      expect(
        header.styles?.properties ?? const {},
        isNot(contains('border-bottom-width')),
      );
    });

    testComponents('follows a stated thickness — 0 draws no rule', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          content: Component.text('body'),
          drawerStyle: CoreDrawerStyle(
            dividerStyle: CoreDividerStyle(thickness: 0),
          ),
        ),
      );

      final header = _header();
      expect(header.classes!.split(' '), isNot(contains('border-b')));
      expect(
        header.styles!.properties['border-bottom-width'],
        strokeWidthCss(0),
      );
    });
  });

  group('Drawer showDragHandle', () {
    testComponents('is off by default — no handle', (tester) async {
      await _open(
        tester,
        const Drawer(side: .bottom, content: Component.text('body')),
      );

      expect(_panelChildren().where(_isHandle), isEmpty);
    });

    testComponents('bottom — a horizontal pill leading the panel', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          title: 'Title',
          showDragHandle: true,
          content: Component.text('body'),
        ),
      );

      final children = _panelChildren();
      expect(_isHandle(children.first), isTrue);
      final pill = _pillOf(children.first).styles!.properties;
      expect(
        pill['width'],
        '${CoreDrawerStyle.defaultDragHandleWidth / 16}rem',
      );
      expect(
        pill['height'],
        '${CoreDrawerStyle.defaultDragHandleThickness / 16}rem',
      );
      expect(
        children.first.styles!.properties['padding'],
        spaceCss(CoreDrawerStyle.defaultDragHandleInset),
      );
    });

    testComponents('top — the pill trails the content', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .top,
          showDragHandle: true,
          content: Component.text('body'),
        ),
      );

      final children = _panelChildren();
      expect(_isHandle(children.last), isTrue);
      expect(children.where(_isHandle), hasLength(1));
    });

    testComponents('left — an upright pill on the inner (right) edge', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(showDragHandle: true, content: Component.text('body')),
      );

      final row = _panelChildren().single;
      final cells = row.children.whereType<div>().toList();
      expect(cells, hasLength(2));
      expect(_isHandle(cells.last), isTrue);
      final pill = _pillOf(cells.last).styles!.properties;
      expect(
        pill['width'],
        '${CoreDrawerStyle.defaultDragHandleThickness / 16}rem',
      );
      expect(
        pill['height'],
        '${CoreDrawerStyle.defaultDragHandleWidth / 16}rem',
      );
    });

    testComponents('right — the pill on the inner (left) edge', (tester) async {
      await _open(
        tester,
        const Drawer(
          side: .right,
          showDragHandle: true,
          content: Component.text('body'),
        ),
      );

      final cells = _panelChildren().single.children.whereType<div>().toList();
      expect(_isHandle(cells.first), isTrue);
    });

    testComponents('paints the handle chrome the drawer style states', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          showDragHandle: true,
          content: Component.text('body'),
          drawerStyle: CoreDrawerStyle(dragHandleWidth: 40),
        ),
      );

      final handle = _panelChildren().first;
      expect(_pillOf(handle).styles!.properties['width'], '${40 / 16}rem');
    });
  });

  group('Drawer drag wiring', () {
    testComponents('a draggable panel takes the pointer, mouse and touch', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(side: .bottom, content: Component.text('body')),
      );

      final panel = _panel();
      expect(
        panel.events!.keys,
        containsAll(<String>[
          'pointerdown',
          'pointermove',
          'pointerup',
          'pointercancel',
        ]),
      );
      expect(
        panel.events!.keys.where((name) => name.startsWith('mouse')),
        isEmpty,
        reason: 'mouse-only handlers would leave touch without a drag',
      );
      expect(panel.styles!.properties['touch-action'], 'none');
    });

    testComponents('a panel that is not draggable binds only the press', (
      tester,
    ) async {
      await _open(
        tester,
        const Drawer(
          side: .bottom,
          draggable: false,
          content: Component.text('body'),
        ),
      );

      final panel = _panel();
      expect(panel.events!.keys, ['pointerdown']);
      expect(panel.styles!.properties, isNot(contains('touch-action')));
    });

    testComponents('the body hands a touch to the drag only once it fits', (
      tester,
    ) async {
      final context = _themedContext(tester);
      ResolvedDrawer resolve({required bool draggable, required bool fits}) =>
          resolveDrawer(
            context,
            side: .bottom,
            open: true,
            dragDelta: 0,
            draggable: draggable,
            bodyFits: fits,
          );

      expect(
        resolve(
          draggable: true,
          fits: true,
        ).content.inlineStyles!.properties['touch-action'],
        'none',
      );
      expect(
        resolve(draggable: true, fits: false).content.inlineStyles!.properties,
        isNot(contains('touch-action')),
        reason: 'a body with something to scroll keeps scrolling',
      );
      expect(
        resolve(draggable: false, fits: true).content.inlineStyles!.properties,
        isNot(contains('touch-action')),
      );
    });
  });

  group('Swiper draws its handle through the drawer', () {
    testComponents("exactly one handle — the drawer's", (tester) async {
      await _openSwiper(tester, showDragHandle: true);

      expect(find.text('overlay'), findsOneComponent);
      final handles = find
          .byComponentPredicate((c) => c is div && _isHandle(c))
          .evaluate();
      expect(handles, hasLength(1));
      expect(_isHandle(_panelChildren().first), isTrue);
    });

    testComponents('no handle when the swiper turns it off', (tester) async {
      await _openSwiper(tester, showDragHandle: false);

      expect(find.text('overlay'), findsOneComponent);
      expect(
        find.byComponentPredicate((c) => c is div && _isHandle(c)),
        findsNothing,
      );
    });

    testComponents('the deprecated flat fields fold under the drawer style', (
      tester,
    ) async {
      final context = _themedContext(tester);

      final legacy = resolveSwiper(
        context,
        variant: CoreSwiperVariant.defaultVariant,
        position: .bottom,
        // The old spelling stays readable until it is removed.
        // ignore: deprecated_member_use
        swiperStyle: const CoreSwiperStyle(dragHandleWidth: 40),
      );
      expect(legacy.drawerStyle.dragHandleWidth, 40);

      final both = resolveSwiper(
        context,
        variant: CoreSwiperVariant.defaultVariant,
        position: .bottom,
        swiperStyle: const CoreSwiperStyle(
          // The old spelling stays readable until it is removed.
          // ignore: deprecated_member_use
          dragHandleWidth: 40,
          drawerStyle: CoreDrawerStyle(dragHandleWidth: 56),
        ),
      );
      expect(
        both.drawerStyle.dragHandleWidth,
        56,
        reason: 'the drawer style wins over the deprecated spelling',
      );
    });
  });
}
