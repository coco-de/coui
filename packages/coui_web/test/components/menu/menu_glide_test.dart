// What a ContextMenu hands a menu that a finger may glide over, and what the
// pieces around the glide put on the page. The judgements of the glide are
// Core's and the shared table's (`context_menu_press_test.dart` replays it);
// this file pins the markup that carries them to the page:
//
// * the lit row reaches the page as a mark on the row (`MenuGlideScope`), since
//   anything written onto an element from outside is overwritten by the next
//   render, and the row paints the mark as the weight of a press;
// * a menu that does not glide is laid out exactly as it always was;
// * the preview's wrapper ignores the pointer, is placed where the Core rule
//   says, and is lifted into the top layer with the panel;
// * the haptic cue is dropped where there is no navigator.
//
// The rows being measured, the click that activates one, and a real browser's
// reading of the mark are read off a live page by a real Chrome
// (`tool/parity/test/web/context_menu_glide_probe_test.dart`).
import 'package:coui_web/coui_web.dart';
import 'package:coui_web/src/components/menu/context_menu/context_menu_preview.dart';
import 'package:coui_web/src/components/menu/menu/menu_glide_scope.dart';
import 'package:coui_web/src/overlay/overlay_motion.dart';
import 'package:coui_web/src/util/haptics.dart';
import 'package:jaspr_test/jaspr_test.dart';
import 'package:jaspr_test/server_test.dart' show testServer;

import '../../helpers/pump_with_theme.dart';

/// The mark a lit row carries, and the attribute the roving focus gives a row.
const String _kMark = 'data-coui-glide';
const String _kRoving = 'data-roving-item';

Map<String, String> _css(Styles? styles) => styles?.properties ?? const {};

/// Every row of the pumped menu, in document order.
Iterable<DomComponent> _rows() => [
  for (final element
      in find
          .byComponentPredicate(
            (c) => c is DomComponent && c.attributes?[_kRoving] != null,
            description: 'a roving row',
          )
          .evaluate())
    element.component as DomComponent,
];

Iterable<DomComponent> _lit() =>
    _rows().where((row) => row.attributes?[_kMark] == 'true');

Component _menu({String? litRow}) => MenuGlideScope(
  highlightedRow: litRow,
  child: const Menu(
    id: 'm',
    items: [
      CoreMenuItem<Component>.action('Copy'),
      CoreMenuItem<Component>.divider(),
      CoreMenuItem<Component>.action('Cut'),
      CoreMenuItem<Component>.checkbox('Show grid'),
    ],
  ),
);

/// A scope whose lit row the test changes from outside, so the menu below it
/// is updated in place the way a `ContextMenu` updates it — not mounted again.
class _Lit extends StatefulComponent {
  const _Lit({required this.menu});

  final Component menu;

  @override
  State<_Lit> createState() => _LitState();
}

class _LitState extends State<_Lit> {
  String? lit;

  void light(String? row) => setState(() => lit = row);

  @override
  Component build(BuildContext context) =>
      MenuGlideScope(highlightedRow: lit, child: component.menu);
}

void main() {
  group('a Menu in a glide scope', () {
    testComponents('outside any scope marks no row', (tester) async {
      pumpWithTheme(
        tester,
        const Menu(
          id: 'm',
          items: [
            CoreMenuItem<Component>.action('Copy'),
            CoreMenuItem<Component>.action('Cut'),
          ],
        ),
      );
      await tester.pump();

      expect(_rows().map((row) => row.attributes![_kRoving]), ['m:0', 'm:1']);
      expect(_lit(), isEmpty);
    });

    testComponents('marks the row whose roving id is lit, and only it', (
      tester,
    ) async {
      pumpWithTheme(tester, _menu(litRow: 'm:1'));
      await tester.pump();

      final lit = _lit().toList();
      expect(lit, hasLength(1));
      expect(lit.single.attributes![_kRoving], 'm:1');
      expect(_rows().map((row) => row.attributes![_kRoving]), [
        'm:0',
        'm:1',
        'm:2',
      ], reason: 'the divider is not a row');
    });

    testComponents('marks a toggle row like any other', (tester) async {
      pumpWithTheme(tester, _menu(litRow: 'm:2'));
      await tester.pump();

      expect(_lit().single.attributes!['role'], 'menuitemcheckbox');
    });

    testComponents('marks nothing when no row is lit', (tester) async {
      pumpWithTheme(tester, _menu());
      await tester.pump();

      expect(_lit(), isEmpty);
    });

    testComponents('marks nothing for an id that is not a row of the menu', (
      tester,
    ) async {
      pumpWithTheme(tester, _menu(litRow: 'other:1'));
      await tester.pump();

      expect(_lit(), isEmpty);
    });

    testComponents('moves the mark when the lit row changes', (tester) async {
      pumpWithTheme(
        tester,
        const _Lit(
          menu: Menu(
            id: 'm',
            items: [
              CoreMenuItem<Component>.action('Copy'),
              CoreMenuItem<Component>.action('Cut'),
              CoreMenuItem<Component>.action('Paste'),
            ],
          ),
        ),
      );
      await tester.pump();
      final holder = find.byType(_Lit).evaluate().single as StatefulElement;
      final state = holder.state as _LitState..light('m:0');
      await tester.pump();
      expect(_lit().single.attributes![_kRoving], 'm:0');

      state.light('m:2');
      await tester.pump();
      expect(_lit().single.attributes![_kRoving], 'm:2');

      state.light(null);
      await tester.pump();
      expect(_lit(), isEmpty);
    });

    testComponents('reaches a row of a nested menu by its own roving id', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const _Lit(
          menu: Menu(
            id: 'm',
            items: [
              CoreMenuItem<Component>.action(
                'Share',
                submenu: [
                  CoreMenuItem<Component>.action('Mail'),
                  CoreMenuItem<Component>.action('Copy link'),
                ],
              ),
              CoreMenuItem<Component>.action('Delete'),
            ],
          ),
        ),
      );
      await tester.pump();
      final state =
          (find.byType(_Lit).evaluate().single as StatefulElement).state
              as _LitState;

      final ids = _rows().map((row) => row.attributes![_kRoving]!).toList();
      expect(ids, hasLength(4), reason: 'the parent row, two nested, one more');
      expect(ids.toSet(), hasLength(4), reason: 'and no id is used twice');
      final nested = ids[2];
      expect(
        nested.startsWith('m:'),
        isFalse,
        reason: 'a nested menu numbers its own rows',
      );

      state.light(nested);
      await tester.pump();
      expect(_lit().single.attributes![_kRoving], nested);
      expect(
        _lit().single.attributes![_kRoving],
        ids[2],
        reason: 'the same row: the nested menu was updated, not mounted again',
      );
    });
  });

  group('the rules of a row in a glide scope', () {
    /// The rules [resolveMenuItemRules] gives a row of [tone].
    String rules(
      ComponentTester tester, {
      required CoreMenuItemTone tone,
      required bool selected,
      required bool glide,
      bool enabled = true,
      CoreMenuItemStyle? menuItemStyle,
    }) {
      late String css;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            css = resolveMenuItemRules(
              context,
              scopeClass: 'row',
              tone: tone,
              selected: selected,
              enabled: enabled,
              glide: glide,
              menuItemStyle: menuItemStyle,
            ).css;

            return const div([]);
          },
        ),
      );

      return css;
    }

    /// The selectors a glide adds to a row's rules, and nothing else.
    final added = RegExp(r',\.row\[data-coui-glide\](?: [^,{]+)?');

    for (final tone in CoreMenuItemTone.values) {
      for (final selected in [false, true]) {
        final which = '${tone.name} tone, ${selected ? 'selected' : 'at rest'}';

        testComponents('$which: a row outside a scope has no rule for the '
            'mark', (tester) async {
          final css = rules(
            tester,
            tone: tone,
            selected: selected,
            glide: false,
          );

          expect(css, isNotEmpty);
          expect(css, isNot(contains(_kMark)));
        });

        testComponents('$which: the mark is the pressed weight and nothing '
            'else changes', (tester) async {
          final plain = rules(
            tester,
            tone: tone,
            selected: selected,
            glide: false,
          );
          final gliding = rules(
            tester,
            tone: tone,
            selected: selected,
            glide: true,
          );

          expect(gliding, contains('.row[$_kMark] > .co-menu-item-wash'));
          // The added selectors are the whole difference.
          expect(gliding.replaceAll(added, ''), plain);
          // They sit in the pressed rule, so the lit row is washed as a
          // pressed one is.
          final pressed = [
            '.row:active > .co-menu-item-wash',
            '.row[$_kMark] > .co-menu-item-wash{',
          ].join(',');
          expect(gliding, contains(pressed));
        });

        testComponents('$which: the mark is written after hover and focus so '
            'it wins', (tester) async {
          final css = rules(
            tester,
            tone: tone,
            selected: selected,
            glide: true,
          );
          final lit = css.indexOf('.row[$_kMark] > ');

          expect(lit, greaterThan(css.indexOf('.row:hover > ')));
          expect(lit, greaterThan(css.indexOf('.row:focus-visible > ')));
        });
      }
    }

    testComponents('a row whose active state is a fill lights it under the '
        'mark, and its stated ink with it', (tester) async {
      // The fill replaces the wash for a critical row and follows the mark
      // the way it follows a press. The default critical row states no ink
      // (designer decision 2026-11-05, #6012), so no colour rule is written.
      final css = rules(
        tester,
        tone: CoreMenuItemTone.critical,
        selected: false,
        glide: true,
      );
      expect(css, contains('.row[$_kMark] > .co-menu-item-wash{'));
      expect(css, isNot(contains('.row[$_kMark]{color:')));

      // An ink a caller states follows the mark too.
      final inked = rules(
        tester,
        tone: CoreMenuItemTone.critical,
        selected: false,
        glide: true,
        menuItemStyle: const CoreMenuItemStyle(
          activeForegroundColor: CoreColor.token(CoreColors.onErrorContainer),
        ),
      );
      expect(inked, contains('.row[$_kMark]{color:'));
      expect(inked, contains('.row[$_kMark] .co-menu-item-ink{color:'));
    });

    testComponents('a disabled row has no rules at all, scope or not', (
      tester,
    ) async {
      for (final glide in [false, true]) {
        expect(
          rules(
            tester,
            tone: CoreMenuItemTone.defaultTone,
            selected: false,
            glide: glide,
            enabled: false,
          ),
          isEmpty,
        );
      }
    });

    testServer('a row of a Menu outside a scope emits no rule for the mark', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: const Menu(
            id: 'm',
            items: [CoreMenuItem<Component>.action('Copy')],
          ),
        ),
      );
      final response = await tester.request('/');
      final styles = response.document!
          .querySelectorAll('style')
          .map((style) => style.text)
          .where((text) => text.contains('co-menu-item-wash'));

      expect(styles, isNotEmpty);
      expect(styles.join(), isNot(contains(_kMark)));
    });

    testServer('a row of a Menu in a scope emits the rule for the mark', (
      tester,
    ) async {
      tester.pumpComponent(
        CoUIWeb(
          theme: .coui,
          child: _menu(litRow: 'm:1'),
        ),
      );
      final response = await tester.request('/');
      final styles = response.document!
          .querySelectorAll('style')
          .map((style) => style.text)
          .where((text) => text.contains('co-menu-item-wash'))
          .join();

      expect(styles, contains('[$_kMark] > .co-menu-item-wash'));
      final marked = response.document!.querySelectorAll('[$_kMark]');
      expect(marked, hasLength(1));
      expect(marked.single.attributes[_kRoving], 'm:1');
    });
  });

  group('the preview of a ContextMenu', () {
    /// The chrome [resolveContextMenu] gives a preview placed at [placement].
    ResolvedContextMenu resolved(
      ComponentTester tester, {
      CorePreviewPlacement? placement,
      double? left,
      double? top,
    }) {
      late ResolvedContextMenu result;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            result = resolveContextMenu(
              context,
              previewPlacement: placement,
              left: left,
              top: top,
            );

            return const div([]);
          },
        ),
      );

      return result;
    }

    const placed = CorePreviewPlacement(
      side: CorePreviewSide.above,
      box: CoreMenuBox(left: 100, top: 272, right: 300, bottom: 392),
      capped: false,
    );

    testComponents('ignores the pointer, in the panel wrapper layer', (
      tester,
    ) async {
      final chrome = resolved(tester).preview;
      final classes = chrome.className.split(' ');

      expect(classes, containsAll(['fixed', 'pointer-events-none']));
      expect(classes, contains('z-60'), reason: 'the layer the panel is in');
    });

    testComponents('carries no offset until it is placed', (tester) async {
      expect(resolved(tester).preview.inlineStyles, isNull);
      expect(
        resolved(tester, left: 10, top: 10).preview.inlineStyles,
        isNull,
        reason: 'a placed menu is not a placed preview',
      );
    });

    testComponents('carries the corner and the largest size it may take', (
      tester,
    ) async {
      expect(_css(resolved(tester, placement: placed).preview.inlineStyles), {
        'left': '100px',
        'top': '272px',
        'max-width': '200px',
        'max-height': '120px',
        'overflow': 'hidden',
      });
    });

    testComponents('keeps a fractional box the browser measured', (
      tester,
    ) async {
      final css = _css(
        resolved(
          tester,
          placement: const CorePreviewPlacement(
            side: CorePreviewSide.below,
            box: CoreMenuBox(left: 8.5, top: 100.25, right: 208.5, bottom: 220),
            capped: false,
          ),
        ).preview.inlineStyles,
      );

      expect(css['left'], '8.50px');
      expect(css['top'], '100.25px');
    });

    testComponents('carries no offset when there is no room for it', (
      tester,
    ) async {
      final chrome = resolved(
        tester,
        placement: const CorePreviewPlacement(
          side: CorePreviewSide.below,
          box: CoreMenuBox(left: 8, top: 100, right: 8, bottom: 100),
          capped: true,
        ),
      ).preview;

      expect(chrome.inlineStyles, isNull);
    });

    testComponents('leaves the panel wrapper as it was', (tester) async {
      final without = resolved(tester, left: 10, top: 20).positioner;
      final with_ = resolved(
        tester,
        left: 10,
        top: 20,
        placement: placed,
      ).positioner;

      expect(with_.className, without.className);
      expect(_css(with_.inlineStyles), _css(without.inlineStyles));
    });

    WebElementChrome motion({required bool placed, bool closing = false}) =>
        resolveOverlayMotion(
          positioned: placed,
          closing: closing,
          openDuration: const Duration(milliseconds: 200),
          closeDuration: const Duration(milliseconds: 150),
        );

    Component layer({bool placed = false}) {
      return Builder(
        builder: (context) {
          final chrome = resolveContextMenu(
            context,
            previewPlacement: placed
                ? const CorePreviewPlacement(
                    side: CorePreviewSide.end,
                    box: CoreMenuBox(
                      left: 372,
                      top: 20,
                      right: 572,
                      bottom: 140,
                    ),
                    capped: false,
                  )
                : null,
          ).preview;

          return ContextMenuPreviewLayer(
            id: 'p',
            chrome: chrome,
            motion: motion(placed: placed),
            child: const div([Text('Preview')], id: 'content'),
          );
        },
      );
    }

    testServer('is a fixed wrapper that ignores the pointer, in the top '
        'layer', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: layer(placed: true)));
      final response = await tester.request('/');
      final wrapper = response.document!.querySelector('#p')!;

      expect(
        wrapper.attributes['class']!.split(' '),
        containsAll(['fixed', 'pointer-events-none']),
      );
      expect(wrapper.attributes['popover'], 'manual');
      expect(wrapper.attributes.containsKey('data-coui-overlay-panel'), isTrue);
      final style = wrapper.attributes['style']!;
      expect(style, contains('left: 372px'));
      expect(style, contains('top: 20px'));
      expect(style, contains('max-width: 200px'));
      expect(style, contains('max-height: 120px'));
      expect(style, contains('overflow: hidden'));
    });

    testServer('draws the preview in the floating-panel chrome, not as a '
        'menu', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: layer(placed: true)));
      final response = await tester.request('/');
      final content = response.document!.querySelector('#p #content')!;
      final popup = content.parent!;

      expect(content.text, 'Preview');
      expect(popup.attributes['role'], 'presentation');
      expect(
        popup.attributes['style'],
        contains('box-shadow'),
        reason: 'the Popup chrome the menu panel is drawn in',
      );
      expect(
        response.document!.querySelectorAll('#p [role="menu"]'),
        isEmpty,
      );
    });

    testServer('is transparent until it is placed', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: layer()));
      final response = await tester.request('/');
      final wrapper = response.document!.querySelector('#p')!;
      final motionBox = wrapper.children.single;

      expect(wrapper.attributes['style'], isNull, reason: 'no offset yet');
      expect(
        motionBox.attributes['class']!.split(' '),
        containsAll(['opacity-0', 'pointer-events-none']),
      );
      expect(motionBox.attributes['style'], isNull, reason: 'and no motion');
    });

    testServer('fades in with the panel once it is placed', (tester) async {
      tester.pumpComponent(CoUIWeb(theme: .coui, child: layer(placed: true)));
      final response = await tester.request('/');
      final motionBox = response.document!.querySelector('#p')!.children.single;

      expect(
        motionBox.attributes['style'],
        contains('co-overlay-enter'),
        reason: 'the animation the panel plays',
      );
    });

    testComponents('outside a host it is not a popover', (tester) async {
      pumpWithTheme(tester, layer(placed: true));
      await tester.pump();
      final wrapper =
          find
                  .byComponentPredicate((c) => c is div && c.id == 'p')
                  .evaluate()
                  .first
                  .component
              as div;

      expect(wrapper.attributes?['popover'], isNull);
    });
  });

  group('ContextMenu', () {
    ContextMenu menu() => const ContextMenu(items: [], child: div([]));

    test('is the contract its Flutter twin implements', () {
      expect(menu(), isA<CoreContextMenuContract<Component>>());
    });

    test('opts in to nothing until asked', () {
      final plain = menu();

      expect(plain.preview, isNull);
      expect(plain.glideToSelect, isFalse);
      expect(plain.haptics, isFalse);
      expect(plain.enabled, isTrue);
    });

    test('copyWith carries the preview, the glide and the haptics', () {
      const preview = Text('Preview');
      final copy = menu().copyWith(
        preview: preview,
        glideToSelect: true,
        haptics: true,
      );

      expect(copy.preview, same(preview));
      expect(copy.glideToSelect, isTrue);
      expect(copy.haptics, isTrue);
    });

    test('copyWith keeps them when something else is replaced', () {
      const preview = Text('Preview');
      final copy = menu()
          .copyWith(preview: preview, glideToSelect: true, haptics: true)
          .copyWith(enabled: false);

      expect(copy.preview, same(preview));
      expect(copy.glideToSelect, isTrue);
      expect(copy.haptics, isTrue);
      expect(copy.enabled, isFalse);
    });
  });

  group('playHapticCue', () {
    test('drops a cue where there is no navigator', () {
      // The server-rendered build has nothing to vibrate; the call must be
      // safe there, since a component that asked for a cue does not know.
      playHapticCue(CoreHapticCue.selectionTick);
    });
  });
}
