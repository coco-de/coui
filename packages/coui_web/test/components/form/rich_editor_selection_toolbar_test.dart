// Pins the Web `RichEditorSelectionToolbar` — the toolbar a `RichEditor`
// floats over selected text: what it holds (the editor's own buttons and
// block-type menu, no image button), the `Popup` it sits on and that panel's
// chrome, where the engine is asked to put it, and its name.
//
// What this file cannot see: when the toolbar shows and where it lands. The
// selection, the focus and every box are the browser's, and the VM has no
// DOM — the bridge it runs against reports no selection, so an editor here
// never opens the toolbar. Those claims are read in a real Chrome by
// `tool/parity/test/web/rich_editor_selection_toolbar_probe_test.dart`; the
// rule that decides them is `CoreRichEditorContract.showsSelectionToolbar`,
// pinned in `coui_core`.

import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_selection_toolbar.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_style.dart';
import 'package:coui_web/src/components/form/rich_editor/rich_editor_toolbar.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' as server;

const String _kPanelId = 'probe-selection-toolbar';
const String _kSurfaceId = 'probe-surface';

/// The toolbar as the editor builds it, open and placed at (120, 48).
class _Floating extends StatelessComponent {
  const _Floating({
    this.active = const {},
    this.enabled = true,
    this.direction,
    this.richEditorStyle,
    this.onFormat,
    this.foldSteps = 0,
  });

  final Set<CoreRichEditorFormat> active;
  final bool enabled;
  final String? direction;
  final CoreRichEditorStyle? richEditorStyle;
  final void Function(CoreRichEditorFormat format)? onFormat;
  final int foldSteps;

  static final PopoverController menu = PopoverController();
  static final PopoverController moreMenu = PopoverController();

  @override
  Component build(BuildContext context) => RichEditorSelectionToolbar(
    panelId: _kPanelId,
    chrome: resolveRichEditorSelectionToolbar(
      context,
      closing: false,
      left: 120,
      top: 48,
      richEditorStyle: richEditorStyle,
    ),
    resolved: resolveRichEditor(
      context,
      enabled: true,
      richEditorStyle: richEditorStyle,
    ),
    active: active,
    enabled: enabled,
    apple: false,
    surfaceId: _kSurfaceId,
    onFormat: onFormat ?? (_) {},
    blockTypeMenu: menu,
    moreMenu: moreMenu,
    foldSteps: foldSteps,
    direction: direction,
  );
}

/// The element marked `data-fold=[tag]`.
Finder _fold(String tag) => find.byComponentPredicate(
  (c) => c is div && c.attributes?['data-fold'] == tag,
  description: 'data-fold=$tag',
);

/// Whether the unit [tag] is folded away — out of the flow and out of
/// sight, not read. A unit of several elements (a group's line and its last
/// button) folds as one.
bool _hidden(String tag) {
  final units = _fold(tag).evaluate().map((e) => e.component as div);
  expect(units, isNotEmpty, reason: tag);
  final answers = <bool>{};
  for (final unit in units) {
    final classes = unit.classes!.split(' ');
    final hidden = unit.attributes?['aria-hidden'] == 'true';
    expect(classes.contains('absolute'), hidden, reason: '$tag: absolute');
    expect(classes.contains('invisible'), hidden, reason: '$tag: invisible');
    answers.add(hidden);
  }
  expect(answers, hasLength(1), reason: '$tag folds as one');
  return answers.single;
}

Component _hosted(Component child) =>
    Theme.defaults(child: OverlayHost(child: child));

/// The single component [finder] finds.
T _component<T extends Component>(Finder finder) =>
    finder.evaluate().single.component as T;

Finder get _root => find.byComponentPredicate(
  (c) => c is div && c.id == _kPanelId,
  description: 'the positioning wrapper',
);

Finder get _floatingButtons => find.descendant(
  of: find.byType(RichEditorSelectionToolbar),
  matching: find.byType(Button),
);

/// Runs [body] with a `BuildContext` under the default theme.
Future<void> _withContext(
  ComponentTester tester,
  void Function(BuildContext context) body,
) async {
  late BuildContext captured;
  tester.pumpComponent(
    Theme.defaults(
      child: Builder(
        builder: (context) {
          captured = context;
          return const div([]);
        },
      ),
    ),
  );
  await tester.pump();
  body(captured);
}

void main() {
  group('RichEditor.showSelectionToolbar', () {
    test("defaults to the contract's, on", () {
      expect(CoreRichEditorContract.defaultShowSelectionToolbar, isTrue);
      expect(const RichEditor().showSelectionToolbar, isTrue);
      expect(
        const RichEditor(showSelectionToolbar: false).showSelectionToolbar,
        isFalse,
      );
    });

    server.testServer('nothing floats in the server markup', (tester) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const RichEditor(initialValue: 'hello'),
        ),
      );
      final document = (await tester.request('/')).document!;
      // One toolbar: the one in the box.
      final toolbars = document.querySelectorAll('[role=toolbar]');
      expect(toolbars, hasLength(1));
      expect(toolbars.single.attributes['aria-label'], 'Formatting');
      expect(document.querySelector('[popover]'), isNull);
    });

    testComponents('an editor with no selection mounts no toolbar', (
      tester,
    ) async {
      tester.pumpComponent(_hosted(const RichEditor(initialValue: 'hello')));
      await tester.pump();
      expect(find.byType(RichEditorSelectionToolbar), findsNothing);
    });
  });

  group('RichEditorSelectionToolbar — what it holds', () {
    testComponents('the block-type button and nine buttons, no image', (
      tester,
    ) async {
      tester.pumpComponent(_hosted(const _Floating()));
      await tester.pump();
      final bar = _component<RichEditorToolbarBar>(
        find.byType(RichEditorToolbarBar),
      );
      expect(bar.groups, CoreRichEditorFormat.selectionToolbar);
      expect(bar.groups, const [
        [CoreRichEditorFormat.blockType],
        [
          CoreRichEditorFormat.bold,
          CoreRichEditorFormat.italic,
          CoreRichEditorFormat.strikethrough,
          CoreRichEditorFormat.code,
          CoreRichEditorFormat.link,
        ],
        [
          CoreRichEditorFormat.bulletedList,
          CoreRichEditorFormat.numberedList,
          CoreRichEditorFormat.taskList,
        ],
        [CoreRichEditorFormat.quote],
      ]);
      // Ten, and the "more" button after them — out of sight with room for
      // every button, in the DOM so its width is known.
      expect(_floatingButtons, findsNComponents(11));
      final labels = [
        for (final element in _floatingButtons.evaluate())
          (element.component as Button).componentAttributes['aria-label'],
      ];
      expect(labels, [
        'Block type: Text',
        'Bold',
        'Italic',
        'Strikethrough',
        'Code',
        'Link',
        'Bulleted list',
        'Numbered list',
        'Checklist',
        'Quote',
        'More',
      ]);
      expect(labels, isNot(contains('Image')));
      // Three lines between the four groups, and the one before the "more"
      // button.
      expect(
        find.descendant(
          of: find.byType(RichEditorSelectionToolbar),
          matching: find.byType(Divider),
        ),
        findsNComponents(4),
      );
      expect(_hidden(RichEditorToolbarBar.foldMoreTag), isTrue);
      expect(_hidden(RichEditorToolbarBar.foldPinnedTag), isFalse);
      for (var i = 0; i < 7; i++) {
        expect(_hidden(RichEditorToolbarBar.foldUnitTag(i)), isFalse);
      }
    });

    testComponents('never wraps: one row, every unit marked for measuring', (
      tester,
    ) async {
      tester.pumpComponent(_hosted(const _Floating()));
      await tester.pump();
      final bar = _component<div>(_fold(RichEditorToolbarBar.foldBarTag));
      expect(bar.classes!.split(' '), containsAll(['flex', 'flex-nowrap']));
      expect(bar.classes!.split(' '), isNot(contains('flex-wrap')));
      expect(
        bar.attributes!['role'],
        isNull,
        reason: 'the Popup is the toolbar',
      );
      // The block-type menu is pinned; the quote is unit 0, the lists unit
      // 1, the inline formats units 2 … 6 from the link back.
      String? tagOf(String label) {
        final button = find.byComponentPredicate(
          (c) => c is Button && c.componentAttributes['aria-label'] == label,
        );
        final unit = find.ancestor(
          of: button,
          matching: find.byComponentPredicate(
            (c) => c is div && (c.attributes?['data-fold'] ?? '') != '',
          ),
        );
        return _component<div>(unit.first).attributes!['data-fold'];
      }

      expect(tagOf('Block type: Text'), 'pinned');
      expect(tagOf('Quote'), 'u0');
      expect(tagOf('Bulleted list'), 'u1');
      expect(tagOf('Checklist'), 'u1');
      expect(tagOf('Link'), 'u2');
      expect(tagOf('Code'), 'u3');
      expect(tagOf('Strikethrough'), 'u4');
      expect(tagOf('Italic'), 'u5');
      expect(tagOf('Bold'), 'u6');
      expect(tagOf('More'), 'more');
      // The inline group's line goes with the bold — the last of its
      // buttons to fold; a button after another of its group stands the
      // button spacing from it, carried by the unit so it folds with it.
      final tagged = _fold('u6');
      expect(tagged, findsNComponents(2), reason: 'the line and the bold');
      final italic = find.ancestor(
        of: find.byComponentPredicate(
          (c) => c is Button && c.componentAttributes['aria-label'] == 'Italic',
        ),
        matching: _fold('u5'),
      );
      expect(
        _component<div>(italic).styles!.properties['margin-inline-start'],
        spaceCss(CoreRichEditorStyle.defaultToolbarItemSpacing),
      );
    });

    testComponents(
      'folded units go out of the flow, into a more menu of checkbox rows',
      (tester) async {
        // Two steps: the quote and the lists are folded.
        tester.pumpComponent(
          _hosted(
            const _Floating(
              foldSteps: 2,
              active: {CoreRichEditorFormat.quote},
            ),
          ),
        );
        await tester.pump();
        expect(_hidden('u0'), isTrue);
        expect(_hidden('u1'), isTrue);
        for (var i = 2; i < 7; i++) {
          expect(_hidden('u$i'), isFalse, reason: 'u$i shows');
        }
        expect(_hidden('pinned'), isFalse);
        expect(_hidden('more'), isFalse);
        // The more button is one of the toolbar's own, opening the same kind
        // of menu as the block-type button.
        final more = find.ancestor(
          of: find.byComponentPredicate(
            (c) => c is Button && c.componentAttributes['aria-label'] == 'More',
          ),
          matching: find.byType(DropdownMenu),
        );
        expect(more, findsOneComponent);
        final menu = _component<DropdownMenu>(more);
        expect(
          menu.items.map((item) => item.kind),
          everyElement(CoreMenuItemKind.checkbox),
        );
        expect(menu.items.map((item) => item.label), [
          'Bulleted list',
          'Numbered list',
          'Checklist',
          'Quote',
        ]);
        expect(menu.items.map((item) => item.checked), [
          false,
          false,
          false,
          true,
        ]);
        expect(
          menu.dropdownMenuStyle,
          _component<RichEditorToolbarBar>(
            find.byType(RichEditorToolbarBar),
          ).resolved.blockTypeMenuStyle,
        );
        final button = _component<Button>(
          find.byComponentPredicate(
            (c) => c is Button && c.componentAttributes['aria-label'] == 'More',
          ),
        );
        final bold = _component<Button>(
          find.byComponentPredicate(
            (c) => c is Button && c.componentAttributes['aria-label'] == 'Bold',
          ),
        );
        expect(button.variant, bold.variant);
        expect(button.buttonStyle, bold.buttonStyle);
        expect(
          find.descendant(
            of: find.byComponent(button),
            matching: find.byComponentPredicate(
              (c) => c is Icon && c.icon == LucideIcons.ellipsis,
            ),
          ),
          findsOneComponent,
        );
      },
    );

    testComponents('a pick from the more menu applies the format', (
      tester,
    ) async {
      final picked = <CoreRichEditorFormat>[];
      tester.pumpComponent(
        _hosted(_Floating(foldSteps: 1, onFormat: picked.add)),
      );
      await tester.pump();
      final more = find.ancestor(
        of: find.byComponentPredicate(
          (c) => c is Button && c.componentAttributes['aria-label'] == 'More',
        ),
        matching: find.byType(DropdownMenu),
      );
      final menu = _component<DropdownMenu>(more);
      expect(menu.items.map((item) => item.label), ['Quote']);
      menu.items.single.onChanged!(true);
      expect(picked, [CoreRichEditorFormat.quote]);
    });

    testComponents('a bar that is not told to fold wraps, as in the box', (
      tester,
    ) async {
      tester.pumpComponent(
        _hosted(const RichEditor(initialValue: 'hello')),
      );
      await tester.pump();
      expect(_fold(RichEditorToolbarBar.foldBarTag), findsNothing);
      expect(
        find.byComponentPredicate(
          (c) => c is Button && c.componentAttributes['aria-label'] == 'More',
        ),
        findsNothing,
      );
    });

    testComponents('the buttons are the ones the toolbar in the box draws', (
      tester,
    ) async {
      // The editor's own toolbar and the floating one, side by side: the
      // same component draws both from the same resolved chrome.
      tester.pumpComponent(
        _hosted(
          const div([
            RichEditor(),
            _Floating(active: {CoreRichEditorFormat.bold}),
          ]),
        ),
      );
      await tester.pump();
      final bars = find.byType(RichEditorToolbarBar).evaluate().toList();
      expect(bars, hasLength(2));
      List<Button> buttonsOf(Element bar) => [
        for (final element
            in find
                .descendant(
                  of: find.byElementPredicate((e) => e == bar),
                  matching: find.byType(Button),
                )
                .evaluate())
          element.component as Button,
      ];
      final own = buttonsOf(bars.first);
      // The floating one is the box's without the image button — and with
      // the "more" button after them, which only the folding toolbar has.
      final floating = buttonsOf(bars.last)
        ..removeWhere(
          (candidate) => candidate.componentAttributes['aria-label'] == 'More',
        );
      expect(floating, hasLength(10));
      expect(own, hasLength(10));
      for (var i = 0; i < floating.length; i++) {
        final a = own[i];
        final b = floating[i];
        final label = b.componentAttributes['aria-label'];
        expect(b.variant, a.variant, reason: label);
        expect(b.size, a.size, reason: label);
        expect(b.shape, a.shape, reason: label);
        // Bold is held down in the floating one only.
        if (label == 'Bold') {
          expect(b.buttonStyle, isNot(a.buttonStyle));
          expect(b.componentAttributes['aria-pressed'], 'true');
        } else {
          expect(b.buttonStyle, a.buttonStyle, reason: label);
        }
      }
      // And the same menu: Text and the headings, radio rows with a check.
      final menus = [
        for (final element in find.byType(DropdownMenu).evaluate())
          element.component as DropdownMenu,
      ];
      expect(menus, hasLength(2));
      for (final menu in menus) {
        expect(
          [for (final item in menu.items) item.label],
          ['Text', 'Heading 1', 'Heading 2', 'Heading 3'],
        );
        expect(
          [for (final item in menu.items) item.kind],
          List.filled(4, CoreMenuItemKind.radio),
        );
        expect(
          [for (final item in menu.items) item.radioMark],
          List.filled(4, CoreMenuRadioMark.check),
        );
        expect(
          [for (final item in menu.items) item.shortcut],
          [null, '#', '##', '###'],
        );
      }
      // Each toolbar opens a menu of its own.
      expect(menus.first.controller, isNot(same(menus.last.controller)));
    });

    testComponents('a press reports the format; a menu row its heading', (
      tester,
    ) async {
      final formats = <CoreRichEditorFormat>[];
      tester.pumpComponent(_hosted(_Floating(onFormat: formats.add)));
      await tester.pump();
      final buttons = [
        for (final element in _floatingButtons.evaluate())
          element.component as Button,
      ];
      buttons[1].onPressed!();
      expect(formats, [CoreRichEditorFormat.bold]);
      final menu = _component<DropdownMenu>(find.byType(DropdownMenu));
      menu.items[2].onChanged!(true);
      expect(formats.last, CoreRichEditorFormat.heading2);
    });

    testComponents('a disabled toolbar disables every button', (tester) async {
      tester.pumpComponent(_hosted(const _Floating(enabled: false)));
      await tester.pump();
      for (final element in _floatingButtons.evaluate()) {
        expect((element.component as Button).enabled, isFalse);
      }
      expect(find.byType(DropdownMenu), findsNothing);
    });
  });

  group('RichEditorSelectionToolbar — panel', () {
    testComponents('a Popup named as a toolbar apart from the one in the box', (
      tester,
    ) async {
      tester.pumpComponent(_hosted(const _Floating()));
      await tester.pump();
      final popup = _component<Popup>(find.byType(Popup));
      expect(popup.componentAttributes['role'], 'toolbar');
      expect(
        popup.componentAttributes['aria-label'],
        'Selection formatting',
      );
      expect(popup.componentAttributes['aria-controls'], _kSurfaceId);
      // What the panel states differently from a plain `Popup`: its corner
      // and its inset. The rest — fill, line, cast — is the `Popup`'s own.
      expect(
        popup.popupStyle,
        CoreRichEditorStyle.defaultSelectionToolbarPanelStyle,
      );
      expect(
        CoreRichEditorStyle.defaultSelectionToolbarPanelStyle,
        const CorePopupStyle(
          padding: CoreEdgeInsets.directional(
            start: CoreSpace.space12,
            top: CoreSpace.space4,
            end: CoreSpace.space4,
            bottom: CoreSpace.space4,
          ),
          borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
        ),
      );
    });

    testComponents(
      'bright face, panel line, 10 corner, lg cast, 4 · 12 inset',
      (tester) async {
        await _withContext(tester, (context) {
          final panel = resolvePopup(
            context,
            direction: CoreAxis.vertical,
            popupStyle: CoreRichEditorStyle.defaultSelectionToolbarPanelStyle,
          );
          final plain = resolvePopup(context, direction: CoreAxis.vertical);
          final inline = panel.root.inlineStyles!.properties;
          // The inset follows the reading direction: logical longhands, each
          // less the line the panel draws over it.
          String inside(double side) =>
              'calc(${spaceCss(side)} - '
              '${surfaceClipKeptBorder(
                strokeWidthCss(CoreStrokeWidth.stroke1),
              )})';
          expect(inline['padding-inline-start'], inside(CoreSpace.space12));
          expect(inline['padding-inline-end'], inside(CoreSpace.space4));
          expect(inline['padding-block-start'], inside(CoreSpace.space4));
          expect(inline['padding-block-end'], inside(CoreSpace.space4));
          expect(inline.containsKey('padding'), isFalse);
          expect(
            inline['border-radius'],
            const CoreBorderRadius.all(CoreRadius.radius10).toValue(),
          );
          expect(
            inline['border-width'],
            strokeWidthCss(CoreStrokeWidth.stroke1),
          );
          // Fill, line and cast are the plain `Popup`'s: surface-bright,
          // outline-variant, the floating-panel rung.
          expect(panel.root.className, plain.root.className);
          const face = CoreColor.token(CoreColors.surfaceBright);
          const line = CoreColor.token(CoreColors.outlineVariant);
          expect(
            panel.root.className.split(' '),
            containsAll([
              'bg-${face.tailwindColor}',
              'border-${line.tailwindColor}',
            ]),
          );
          expect(
            inline['box-shadow'],
            plain.root.inlineStyles!.properties['box-shadow'],
          );
          expect(CorePopupStyle.defaultBoxShadow, CoreShadow.lg);
        });
      },
    );

    testComponents('a symmetric Popup inset stays the one-line shorthand', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final inline = resolvePopup(
          context,
          direction: CoreAxis.vertical,
        ).root.inlineStyles!.properties;
        expect(
          inline['padding'],
          CorePopupStyle.defaultPadding.toDeclarationsWithinBorder(
            'padding',
            surfaceClipKeptBorder(
              strokeWidthCss(CorePopupStyle.defaultBorderWidth),
            ),
          )['padding'],
        );
        expect(inline.containsKey('padding-inline-start'), isFalse);
      });
    });

    testComponents('the Style slot reaches the panel', (tester) async {
      const style = CoreRichEditorStyle(
        selectionToolbarPanelStyle: CorePopupStyle(
          borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
        ),
      );
      tester.pumpComponent(_hosted(const _Floating(richEditorStyle: style)));
      await tester.pump();
      final popup = _component<Popup>(find.byType(Popup));
      expect(
        popup.popupStyle!.borderRadius,
        const CoreBorderRadius.all(CoreRadius.radius4),
      );
      // The inset it did not state is still the default's.
      expect(
        popup.popupStyle!.padding,
        CoreRichEditorStyle.defaultSelectionToolbarPanelStyle.padding,
      );
    });

    testComponents('40 tall: the line lies over the inset, not outside it', (
      tester,
    ) async {
      // The Flutter panel and the canvas draw the 1 line over the 4 inset, so
      // the panel is 4 + 32 + 4 = 40 with its line and its text starts 12 in.
      // The `Popup` takes the line out of every side of its own inset, so the
      // panel adds nothing of its own to give it back.
      tester.pumpComponent(_hosted(const _Floating()));
      await tester.pump();
      final popup = _component<Popup>(find.byType(Popup));
      expect(popup.css, isNull, reason: 'the Popup does it for every panel');
      await _withContext(tester, (context) {
        final inline = resolvePopup(
          context,
          direction: CoreAxis.vertical,
          popupStyle: CoreRichEditorStyle.defaultSelectionToolbarPanelStyle,
        ).root.inlineStyles!.properties;
        final line = surfaceClipKeptBorder(
          strokeWidthCss(CoreStrokeWidth.stroke1),
        );
        expect(
          inline['padding-block-start'],
          'calc(${spaceCss(CoreSpace.space4)} - $line)',
        );
        expect(inline['padding-block-end'], inline['padding-block-start']);
        expect(
          inline['padding-inline-start'],
          'calc(${spaceCss(CoreSpace.space12)} - $line)',
        );
        expect(
          inline['border-width'],
          strokeWidthCss(CoreStrokeWidth.stroke1),
          reason: 'line kept',
        );
      });
    });
  });

  group('RichEditorSelectionToolbar — placement', () {
    testComponents(
      'fixed at the origin the engine resolved, in the top layer',
      (
        tester,
      ) async {
        tester.pumpComponent(_hosted(const _Floating()));
        await tester.pump();
        final root = _component<div>(_root);
        expect(root.classes!.split(' '), contains('fixed'));
        final inline = root.styles!.properties;
        expect(inline['left'], '${120 / kRemDivisor}rem');
        expect(inline['top'], '${48 / kRemDivisor}rem');
        expect(root.attributes, containsPair('popover', 'manual'));
        expect(root.attributes!.containsKey(kTopLayerPanelAttribute), isTrue);
      },
    );

    testComponents('carries no top-layer marker without a host', (
      tester,
    ) async {
      // Nothing would promote it, and the browser hides an unpromoted
      // `[popover]`.
      tester.pumpComponent(Theme.defaults(child: const _Floating()));
      await tester.pump();
      final root = _component<div>(_root);
      expect(root.attributes!.containsKey('popover'), isFalse);
    });

    testComponents('hidden until placed, then enters; exits when closing', (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final unplaced = resolveRichEditorSelectionToolbar(
          context,
          closing: false,
        );
        expect(unplaced.root.inlineStyles, isNull);
        expect(unplaced.motion.className.split(' '), contains('opacity-0'));
        final placed = resolveRichEditorSelectionToolbar(
          context,
          closing: false,
          left: 10,
          top: 20,
        );
        expect(
          placed.motion.inlineStyles!.properties['animation'],
          startsWith('co-overlay-enter '),
        );
        final closing = resolveRichEditorSelectionToolbar(
          context,
          closing: true,
          left: 10,
          top: 20,
        );
        expect(
          closing.motion.inlineStyles!.properties['animation'],
          startsWith('co-overlay-exit '),
        );
      });
    });

    testComponents("carries the editor's direction onto the panel", (
      tester,
    ) async {
      tester.pumpComponent(_hosted(const _Floating(direction: 'rtl')));
      await tester.pump();
      expect(_component<div>(_root).attributes, containsPair('dir', 'rtl'));
    });

    testComponents("asks the engine for above, the style's distance away", (
      tester,
    ) async {
      await _withContext(tester, (context) {
        final config = resolveRichEditorSelectionToolbarConfig(context);
        expect(config.placement, CorePopoverPlacement.top);
        expect(config.gap, CoreSpace.space8);
        expect(
          config.gap,
          CoreRichEditorStyle.defaultSelectionToolbarOffset,
        );
        expect(
          resolveRichEditorSelectionToolbarConfig(
            context,
            richEditorStyle: const CoreRichEditorStyle(
              selectionToolbarOffset: CoreSpace.space16,
            ),
          ).gap,
          CoreSpace.space16,
        );
      });
    });

    group('what the engine does with that request', () {
      const viewport = OverlayViewport.all(
        width: 1024,
        height: 768,
        padding: 8,
      );
      const panel = OverlaySize(width: 411, height: 40);

      OverlayPositionResolution place(OverlayRect selection) =>
          resolveOverlayCollision(
            trigger: selection,
            popover: panel,
            placement: CorePopoverPlacement.top,
            viewport: viewport,
            gap: CoreRichEditorStyle.defaultSelectionToolbarOffset,
          );

      test('centred over the selection, 8 above it', () {
        const selection = OverlayRect(
          left: 400,
          top: 300,
          width: 120,
          height: 20,
        );
        final r = place(selection);
        expect(r.placement, CorePopoverPlacement.top);
        expect(r.position.top, 300 - 8 - 40);
        expect(r.position.left + panel.width / 2, selection.centerX);
      });

      test('below it when there is no room above', () {
        const selection = OverlayRect(
          left: 400,
          top: 20,
          width: 120,
          height: 20,
        );
        final r = place(selection);
        expect(r.placement, CorePopoverPlacement.bottom);
        expect(r.position.top, selection.bottom + 8);
        expect(r.position.left + panel.width / 2, selection.centerX);
      });

      test(
        'a selection on the first line, under the toolbar in the box, '
        'gets the panel below it: the room above ends at the surface',
        () {
          // The editor's surface begins at 300; its first line is 10 below.
          // The screen has room above, the editing area has not.
          const selection = OverlayRect(
            left: 400,
            top: 310,
            width: 120,
            height: 20,
          );
          final r = resolveOverlayCollision(
            trigger: selection,
            popover: panel,
            placement: CorePopoverPlacement.top,
            viewport: const OverlayViewport(
              width: 1024,
              height: 768,
              paddingLeft: 8,
              paddingTop: 300,
              paddingRight: 8,
              paddingBottom: 8,
            ),
            gap: CoreRichEditorStyle.defaultSelectionToolbarOffset,
          );
          expect(r.placement, CorePopoverPlacement.bottom);
          expect(r.position.top, selection.bottom + 8);
          expect(r.position.top, greaterThan(300));
          // The same selection with the room the viewport's: above.
          expect(place(selection).placement, CorePopoverPlacement.top);
          // A line with the panel and its distance of room above it inside
          // the surface keeps the panel above.
          const lower = OverlayRect(
            left: 400,
            top: 300 + 40 + 8,
            width: 120,
            height: 20,
          );
          final above = resolveOverlayCollision(
            trigger: lower,
            popover: panel,
            placement: CorePopoverPlacement.top,
            viewport: const OverlayViewport(
              width: 1024,
              height: 768,
              paddingLeft: 8,
              paddingTop: 300,
              paddingRight: 8,
              paddingBottom: 8,
            ),
            gap: CoreRichEditorStyle.defaultSelectionToolbarOffset,
          );
          expect(above.placement, CorePopoverPlacement.top);
          expect(above.position.top, 300);
        },
      );

      test('the engine config names the room the bar folds to', () async {
        // The same viewport padding the positioner is given, so the bar
        // folds to the room the panel is placed in.
        expect(
          CorePopoverStyle.defaultViewportPadding,
          const CoreEdgeInsets.all(CoreSpace.space8),
        );
      });

      test('moved inwards at the edges of the viewport', () {
        final left = place(
          const OverlayRect(left: 4, top: 300, width: 40, height: 20),
        );
        expect(left.position.left, 8);
        expect(left.position.top, 300 - 8 - 40);
        final right = place(
          const OverlayRect(left: 980, top: 300, width: 40, height: 20),
        );
        expect(right.position.left, 1024 - 8 - 411);
      });
    });
  });
}
