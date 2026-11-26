import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Every element in the tree that carries the surface marker.
Iterable<DomComponent> _surfaces(ComponentTester tester) => find
    .byType(DomComponent)
    .evaluate()
    .map((e) => e.component as DomComponent)
    .where((c) => (c.classes ?? '').split(' ').contains(kWebSurfaceMarker));

/// Whether the marked surfaces publish the fill a preset needs.
bool _publishesFill(ComponentTester tester) => _surfaces(tester).any(
  (c) => (c.styles?.properties ?? const {}).containsKey(kWebSurfaceFillVar),
);

void main() {
  group('a surface publishes the fill it chose', () {
    // Why both halves are needed: the preset rule restates the fill as
    // `rgb(var(--coui-surface-rgb) / calc(var(--coui-surface-alpha, 1) *
    // 70%))`. If a surface carries the
    // marker but never sets that variable, the rule matches and resolves
    // to an invalid colour — the background disappears rather than
    // turning translucent. Marker and variable are one contract.
    testComponents('a card', (tester) async {
      pumpWithTheme(tester, Card(body: const Text('Body')));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a dialog panel', (tester) async {
      pumpWithTheme(
        tester,
        const Dialog(title: Text('Title'), content: Text('Body')),
      );

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a popup panel (#3464)', (tester) async {
      // The floating anchored panel behind menu/dropdown/context-menu/
      // menubar/navigation-menu/popover — before #3464 it carried
      // neither the marker nor the fill, so Liquid Glass reached
      // Dialog/Tooltip but not any of the six components that compose
      // this one.
      pumpWithTheme(tester, const Popup(children: [Text('Item')]));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });
  });

  group('and states it as a triplet reference', () {
    testComponents('so the preset can add its own alpha', (tester) async {
      // The value has to be the bare `R G B` variable, not a composed
      // `rgb(...)`: alpha cannot be added to a colour that is already
      // composed, which is the reason the component publishes the
      // triplet rather than the finished fill.
      pumpWithTheme(tester, Card(body: const Text('Body')));

      final published = _surfaces(tester)
          .map((c) => (c.styles?.properties ?? const {})[kWebSurfaceFillVar])
          .whereType<String>();

      expect(published, isNotEmpty);
      for (final value in published) {
        expect(value, startsWith('var(--coui-'));
        expect(value, isNot(contains('rgb(')));
      }
    });
  });

  group('the overlay panel group publishes too', () {
    // These four drew their own panel and carried neither half of the
    // contract, so a material preset reached `Dialog` and `Tooltip` and
    // stopped there. Marker and fill variable are one contract: the
    // marker alone resolves the preset's restated colour to nothing and
    // the background disappears rather than turning translucent.

    // The drawer is asserted at the resolver rather than the tree: its
    // panel is mounted into the overlay host by `openDrawer`, and
    // `Drawer(...)` on its own renders empty on purpose so a stray
    // instance in a normal subtree draws nothing. The contract is the
    // same one — marker on the panel class list, fill on its styles.
    testComponents('a drawer panel', (tester) async {
      late ResolvedDrawer resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveDrawer(
              context,
              side: CoreDrawerSide.left,
              open: true,
              dragDelta: 0,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(resolved.panel.className, contains(kWebSurfaceMarker));
      expect(
        resolved.panel.inlineStyles?.properties ?? const {},
        contains(kWebSurfaceFillVar),
      );
    });

    testComponents('a toast', (tester) async {
      pumpWithTheme(tester, Toast(message: 'Saved'));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a command palette', (tester) async {
      pumpWithTheme(tester, const Command(groups: []));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('an item picker', (tester) async {
      pumpWithTheme(tester, const ItemPicker(showSearch: false));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });
  });

  group('the form field group publishes too (#4356)', () {
    // These draw their own box directly on the native `<input>` (or the
    // affix wrapper, once framed) rather than composing
    // `OutlinedContainer` — wrapping would move the framed body to a
    // different element than the one `FocusOutline` rings, offsetting
    // the ring.

    testComponents('a text field with no prefix / suffix', (tester) async {
      pumpWithTheme(tester, const TextField());

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a text field framed by a prefix', (tester) async {
      // Framed, the affix wrapper is the box and the input carries
      // `border-0` / transparent — the pair moves with it rather than
      // doubling up on both elements.
      pumpWithTheme(tester, const TextField(prefix: Text(r'$')));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a text area with no prefix / suffix', (tester) async {
      pumpWithTheme(tester, const TextArea());

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a text area framed by a prefix', (tester) async {
      pumpWithTheme(tester, const TextArea(prefix: Text(r'$')));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a phone input', (tester) async {
      pumpWithTheme(tester, const PhoneInput());

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a chip input', (tester) async {
      pumpWithTheme(tester, const ChipInput());

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    // FileInput's idle state states no fill of its own by design (the
    // dashed border alone reads as a drop zone, mirroring Table #4359) —
    // asserted in the fill-less group below. Only drag-active always
    // states one, and that state is internal component state rather than
    // a widget prop, so — like the drawer panel above — it is asserted
    // at the resolver directly.
    testComponents('a file input, drag-active', (tester) async {
      late ResolvedFileInput resolved;
      pumpWithTheme(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveFileInput(
              context,
              enabled: true,
              isDragOver: true,
            );
            return const Component.text('ok');
          },
        ),
      );

      expect(resolved.root.className, contains(kWebSurfaceMarker));
      expect(
        resolved.root.inlineStyles?.properties ?? const {},
        contains(kWebSurfaceFillVar),
      );
    });

    testComponents('a sortable list', (tester) async {
      pumpWithTheme(
        tester,
        Sortable(
          itemCount: 2,
          itemBuilder: (index, handle, remove) =>
              div([handle, Text('Item $index')]),
        ),
      );

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });
  });

  group('the nav-overlay group publishes too (#4357)', () {
    testComponents('a menubar bar (bordered by default)', (tester) async {
      pumpWithTheme(tester, const Menubar(menus: []));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a menubar bar with border:false carries no marker', (
      tester,
    ) async {
      // A borderless bar never reaches the bordered branch that carries
      // the marker + fill pair at all — see `menubar_style.dart`.
      pumpWithTheme(tester, const Menubar(menus: [], border: false));

      expect(_surfaces(tester), isEmpty);
    });

    testComponents('a tabs bar (pill variant)', (tester) async {
      pumpWithTheme(
        tester,
        const Tabs(
          tabs: [CoreTabItem<Component>(label: 'One')],
          selectedIndex: 0,
        ),
      );

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a tabs bar (underline variant) carries no marker', (
      tester,
    ) async {
      // The underline variant paints no fill at all — only a bottom rule
      // — so there is nothing for a material preset to make translucent.
      pumpWithTheme(
        tester,
        const Tabs(
          tabs: [CoreTabItem<Component>(label: 'One')],
          selectedIndex: 0,
          variant: .underline,
        ),
      );

      expect(_surfaces(tester), isEmpty);
    });

    testComponents(
      'a tab-pane content panel — not its boxed-tab affordance',
      (tester) async {
        // The content panel always paints a fill and carries the marker.
        // The boxed-tab span next to it shares the same background token
        // but stays a plain highlight and carries no marker of its own
        // (mirrors the Flutter resolver keeping a separate panel-only
        // material fold). Exactly one marked surface pins that down —
        // two would mean the affordance got marked too.
        pumpWithTheme(
          tester,
          const TabPane(
            tabs: [CoreTabItem<Component>(label: 'One')],
            selectedIndex: 0,
          ),
        );

        final surfaces = _surfaces(tester);
        expect(surfaces, hasLength(1));
        expect(_publishesFill(tester), isTrue);
      },
    );
  });

  group('the display group publishes too (#4358)', () {
    // Badge / ValidationBadge / ChatBubble / Kbd don't compose
    // `OutlinedContainer` — the first two's root is a fixed `<span>`
    // (wrapping it in a `<div>` breaks the inline flow they sit in),
    // and the bubble cuts a concave tail path the container has no
    // slot for — so each restates the marker+fill pair on its own
    // surface element directly.

    testComponents('a badge', (tester) async {
      pumpWithTheme(tester, const Badge(child: Text('New')));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a validation badge', (tester) async {
      pumpWithTheme(
        tester,
        const ValidationBadge(
          label: 'Valid',
          state: CoreValidationState.valid,
        ),
      );

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents('a chat bubble', (tester) async {
      pumpWithTheme(tester, const ChatBubble(child: Text('Hello')));

      expect(_surfaces(tester), isNotEmpty);
      expect(_publishesFill(tester), isTrue);
    });

    testComponents(
      'a kbd marks each key cap — not its row container',
      (tester) async {
        pumpWithTheme(tester, const Kbd(keys: ['Ctrl', 'C']));

        // Two keys, each its own marked surface — the row that lays
        // them out carries no marker of its own.
        final surfaces = _surfaces(tester);
        expect(surfaces, hasLength(2));
        expect(_publishesFill(tester), isTrue);
      },
    );
  });

  group('a fill-less surface is left alone (#4359)', () {
    // Table states no fill of its own by design (see the comment on
    // `containerFillCore` in table_style.dart), so marking it as a surface
    // is gated on the same `CoreColor` that decides whether
    // `background-color` is painted at all — exactly like the fill-less
    // panels above.
    testComponents('a table with no background carries no marker', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const Table(
          rows: [
            CoreTableRowData(cells: [CoreTableCellData(child: Text('Cell'))]),
          ],
        ),
      );

      expect(_surfaces(tester), isEmpty);
    });

    testComponents(
      'a table with an explicit background carries the marker and '
      'publishes its fill',
      (tester) async {
        pumpWithTheme(
          tester,
          const Table(
            rows: [
              CoreTableRowData(
                cells: [CoreTableCellData(child: Text('Cell'))],
              ),
            ],
            tableStyle: CoreTableStyle(
              backgroundColor: CoreColor.token(CoreColors.surface),
            ),
          ),
        );

        final surfaces = _surfaces(tester);
        expect(surfaces, isNotEmpty);
        expect(_publishesFill(tester), isTrue);
      },
    );

    testComponents(
      'a text field with an explicit transparent override carries no '
      'marker (#4356)',
      (tester) async {
        // Unlike Table, the field always states a fill by design — this
        // only turns off once a caller explicitly overrides it.
        pumpWithTheme(
          tester,
          const TextField(
            textFieldStyle: CoreTextFieldStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(_surfaces(tester), isEmpty);
      },
    );

    testComponents(
      'a text area with an explicit transparent override carries no '
      'marker (#4356)',
      (tester) async {
        pumpWithTheme(
          tester,
          const TextArea(
            textAreaStyle: CoreTextAreaStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(_surfaces(tester), isEmpty);
      },
    );

    testComponents(
      'a phone input with an explicit transparent override carries no '
      'marker (#4356)',
      (tester) async {
        pumpWithTheme(
          tester,
          const PhoneInput(
            phoneInputStyle: CorePhoneInputStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(_surfaces(tester), isEmpty);
      },
    );

    testComponents(
      'a chip input with an explicit transparent override carries no '
      'marker (#4356)',
      (tester) async {
        pumpWithTheme(
          tester,
          const ChipInput(
            chipInputStyle: CoreChipInputStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(_surfaces(tester), isEmpty);
      },
    );

    testComponents(
      'a file input idle with no background carries no marker (#4356)',
      (tester) async {
        // Resolved directly rather than through `_surfaces(tester)` — the
        // widget composes a `Button` for "browse" (#4360, outline variant),
        // which is itself a registered surface and marks unconditionally.
        // A whole-subtree scan would see that child marker and misread it
        // as the drop zone's own; this asserts the drop zone's root chrome
        // specifically, mirroring the drag-active resolver check below.
        late ResolvedFileInput resolved;
        pumpWithTheme(
          tester,
          Builder(
            builder: (context) {
              resolved = resolveFileInput(
                context,
                enabled: true,
                isDragOver: false,
              );
              return const Component.text('ok');
            },
          ),
        );

        expect(resolved.root.className, isNot(contains(kWebSurfaceMarker)));
        expect(
          resolved.root.inlineStyles?.properties ?? const {},
          isNot(contains(kWebSurfaceFillVar)),
        );
      },
    );

    testComponents(
      'a sortable item with an explicit transparent override carries no '
      'marker (#4356)',
      (tester) async {
        pumpWithTheme(
          tester,
          Sortable(
            itemCount: 2,
            itemBuilder: (index, handle, remove) =>
                div([handle, Text('Item $index')]),
            sortableStyle: const CoreSortableStyle(
              itemBackgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(_surfaces(tester), isEmpty);
      },
    );
  });
}
