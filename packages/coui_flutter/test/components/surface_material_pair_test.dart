import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

/// A theme whose surface states glass — blur *and* translucency.
///
/// The pair is the whole point. A preset that supplies only the blur
/// leaves every panel opaque and the backdrop pass is painted and then
/// covered, which renders identically to no material at all.
ThemeData _glassTheme() => ThemeData.fromCore(
  CoreThemeData(
    colorScheme: CouiColorPresets.source.light(),
    brightness: CoreBrightness.light,
    designSystem: DesignSystem.coui,
    // The unnamed constructor rather than `.glass()`: that one still
    // requires the deprecated colour model, and this test has no use
    // for it — the pair under test is blur and opacity.
    defaultSurface: const CoreSurfaceToken(
      type: SurfaceType.glass,
      opacity: CoreSurfaceOpacity.same(0.6),
      blurRadius: 24,
    ),
  ),
);

Future<T> _underTheme<T>(
  WidgetTester tester,
  ThemeData theme,
  T Function(material.BuildContext context) resolve,
) async {
  late T out;
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: theme,
        child: material.Builder(
          builder: (context) {
            out = resolve(context);
            return const material.SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  return out;
}

void main() {
  group('a surface that reads the material makes its fill translucent', () {
    // Each of these read the blur off the theme and folded only the
    // component-level opacity, so a preset reached them with one half of
    // the pair. Nothing was red: the axis was read, the wrapper was
    // there, and the panel rendered exactly as opaque as before.

    testWidgets('Dialog', (tester) async {
      final theme = _glassTheme();
      final resolved = await _underTheme(
        tester,
        theme,
        resolveDialog,
      );

      expect(
        resolved.panelBackgroundColor.a,
        lessThan(1.0),
        reason: 'a blur behind an opaque panel is painted and then covered',
      );
      expect(resolved.surfaceBlur, isNotNull);
    });

    testWidgets('Tooltip', (tester) async {
      final theme = _glassTheme();
      final resolved = await _underTheme(
        tester,
        theme,
        resolveTooltip,
      );

      expect(resolved.surfaceOpacity, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);
    });
  });

  group('a theme that states no surface leaves fills alone', () {
    testWidgets('Dialog stays opaque under the default preset', (
      tester,
    ) async {
      final resolved = await _underTheme(
        tester,
        ThemeData.fromCore(CoreThemePresets.light),
        resolveDialog,
      );

      // The fallback must not invent translucency where the theme asked
      // for none — every existing preset is in this case.
      expect(resolved.panelBackgroundColor.a, 1.0);
    });
  });

  group('and the widget half of the pair is painted, not just resolved', () {
    // `ModalContainer` paints its fill in the widget rather than through
    // a resolver, so the re-read above cannot see it. It read the blur
    // off the theme, declared `surfaceOpacity`, and used that field only
    // to decide whether to clip — the fill itself was fully opaque.
    testWidgets('ModalContainer fills translucent under a glass theme', (
      tester,
    ) async {
      await tester.pumpWidget(
        material.MaterialApp(
          home: Theme(
            data: _glassTheme(),
            child: const ModalContainer(
              filled: true,
              child: material.Text('modal body'),
            ),
          ),
        ),
      );

      final box = tester.widget<material.AnimatedContainer>(
        find.byType(material.AnimatedContainer).first,
      );
      final fill = (box.decoration! as material.BoxDecoration).color!;

      expect(
        fill.a,
        lessThan(1.0),
        reason: 'the backdrop pass below is covered by an opaque fill',
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });
  });

  group('the overlay panel group reaches the material — both halves', () {
    // Two assertions per component on purpose. A resolver re-read alone
    // passes while the widget never wraps anything, and a widget-tree
    // search alone passes while the resolver never reads the axis —
    // each half is blind to the other's absence.
    //
    // Fixtures avoid `Card` — and, as of #4361, `ItemPicker` — and, as of
    // #4364, `Command` — all three compose `OutlinedContainer`, which is
    // already wired, so any of them inside the tree would satisfy the
    // `SurfaceBlur` search even with the component's own wiring removed.
    // `ItemPicker` and `Command` used to draw their own panel +
    // hand-rolled `SurfaceBlur` wrap and belonged in this group; #4361
    // and #4364 replaced that with composing `OutlinedContainer`, so
    // both left the group the same way `Card` never joined it.

    testWidgets('Drawer', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveDrawer(context, side: CoreDrawerSide.left),
      );
      expect(resolved.panelBackgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        const Drawer(content: material.SizedBox(width: 10, height: 10)),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('Toast', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveToast(
          context,
          variant: CoreToastVariant.defaultVariant,
          dismissible: false,
        ),
      );
      expect(resolved.backgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, const Toast(message: 'saved'));
      expect(find.byType(SurfaceBlur), findsWidgets);
    });
  });

  group('the container chrome group reaches it too', () {
    testWidgets('DraggablePanel', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        resolveDraggablePanel,
      );
      expect(resolved.panelBackgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);
    });

    testWidgets('DescriptionCard', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveDescriptionCard(
          context,
          variant: CoreDescriptionCardVariant.outlined,
          size: CoreDescriptionCardSize.md,
        ),
      );
      expect(resolved.backgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        const DescriptionCard(rows: []),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('Table (#4359)', (tester) async {
      // Table states no fill of its own by design, so the material only
      // has something to make translucent once a caller opts into a
      // background — the fixture below does exactly that.
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveTable(
          context,
          tableStyle: const CoreTableStyle(
            backgroundColor: CoreColor.token(CoreColors.surface),
          ),
        ),
      );
      expect(resolved.backgroundColor?.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        const Table(
          rows: [],
          tableStyle: CoreTableStyle(
            backgroundColor: CoreColor.token(CoreColors.surface),
          ),
        ),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });
  });

  group('the form field group reaches it too (#4356)', () {
    // These draw their own box directly on the native input element (Web)
    // / a `Container` (Flutter) rather than composing `OutlinedContainer`
    // — wrapping would move the framed body to a different element than
    // the one `FocusOutline` rings, offsetting the ring.

    testWidgets('TextField', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveTextField(
          context,
          hasError: false,
          enabled: true,
          size: CoreComponentSize.md,
        ),
      );
      expect(resolved.decoration.resolve(const {}).color!.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, TextField());
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('TextArea', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveTextArea(
          context,
          hasError: false,
          size: CoreComponentSize.md,
        ),
      );
      expect(resolved.decoration.resolve(const {}).color!.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, TextArea());
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('PhoneInput', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        resolvePhoneInput,
      );
      expect(resolved.backgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, const PhoneInput());
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('ChipInput', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        resolveChipInput,
      );
      expect(resolved.backgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, const ChipInput());
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets(
      'FileInput — idle states no fill, drag-active always does (#4356)',
      (tester) async {
        // Unlike the rest of this group, the drop zone's idle state
        // states no fill of its own by design (the dashed border alone
        // reads as a drop zone, mirroring Table #4359) — only its
        // drag-active branch always states one.
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          resolveFileInput,
        );
        expect(resolved.backgroundColorIdle.a, 0);
        expect(resolved.surfaceBlurIdle, isNull);
        expect(resolved.backgroundColorDragActive.a, lessThan(1.0));
        expect(resolved.surfaceBlurDragActive, isNotNull);

        await _pumpUnderGlass(tester, const FileInput());
        expect(find.byType(SurfaceBlur), findsWidgets);
      },
    );

    testWidgets('Sortable', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        resolveSortable,
      );
      expect(resolved.itemBackgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        Sortable(
          itemCount: 2,
          itemBuilder: (context, index, dragHandle, removeButton) =>
              material.Text('Item $index'),
        ),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });
  });

  group('the nav-overlay group reaches it too (#4357)', () {
    testWidgets('Menubar', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveMenubar(context, variant: .defaultVariant),
      );
      expect(resolved.barBackgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(tester, const Menubar(menus: []));
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('Tabs (pill variant)', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveTabs(
          context,
          variant: .pill,
          size: .md,
        ),
      );
      expect(resolved.backgroundColor?.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        Tabs.labels(labels: const ['One', 'Two'], selectedIndex: 0),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });

    testWidgets('TabPane', (tester) async {
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        resolveTabPane,
      );
      expect(resolved.panelBackgroundColor.a, lessThan(1.0));
      expect(resolved.surfaceBlur, isNotNull);

      await _pumpUnderGlass(
        tester,
        const TabPane(
          tabs: [CoreTabItem<Widget>(label: 'One')],
          selectedIndex: 0,
        ),
      );
      expect(find.byType(SurfaceBlur), findsWidgets);
    });
  });

  group(
    'the display group restates the opacity-only seat too (#4358)',
    () {
      // Badge / ValidationBadge / Chat / Kbd are label-sized chips, not
      // panels — each restates Button's (#4360) lighter opacity-only
      // seat (fold the material's opacity into whichever fill each
      // resolves, suppress the stroke colour) rather than the full
      // blur/sheen material, so none of them carry a `surfaceBlur`
      // field or a `SurfaceBlur` wrap.

      testWidgets(
        'Badge folds material opacity into resting, hover and pressed fills',
        (tester) async {
          final resolved = await _underTheme(
            tester,
            _glassTheme(),
            (context) => resolveBadge(
              context,
              tone: .primary,
              variant: .filled,
              form: .count,
              size: .sm,
            ),
          );
          expect(resolved.backgroundColor.a, lessThan(1.0));
          expect(resolved.hoverBackgroundColor.a, lessThan(1.0));
          expect(resolved.pressedBackgroundColor.a, lessThan(1.0));
          // The share folds into the wash, not over it: an opaque fill's
          // wash is opaque, so it lands at the share alone — the alpha the
          // Web twin's material rule gives the wash it publishes through
          // the surface vars (`calc(1 × share)`).
          expect(
            resolved.hoverBackgroundColor.a,
            closeTo(resolved.backgroundColor.a, 0.01),
          );
          expect(
            resolved.pressedBackgroundColor.a,
            closeTo(resolved.backgroundColor.a, 0.01),
          );
        },
      );

      testWidgets(
        'Badge outlined variant stays at 0 alpha — scaling zero is still '
        'zero',
        (tester) async {
          final resolved = await _underTheme(
            tester,
            _glassTheme(),
            (context) => resolveBadge(
              context,
              tone: .neutral,
              variant: .outlined,
              form: .count,
              size: .sm,
            ),
          );
          expect(resolved.backgroundColor.a, 0.0);
        },
      );

      testWidgets('ValidationBadge folds material opacity into its fill', (
        tester,
      ) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveValidationBadge(
            context,
            state: .valid,
            size: CoreValidationBadgeStyle.defaultSize,
            pendingIcon: null,
            validIcon: null,
            invalidIcon: null,
          ),
        );
        expect(resolved.backgroundColor.a, lessThan(1.0));
      });

      testWidgets('ChatBubble folds material opacity into its fill', (
        tester,
      ) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveChatBubble(
            context,
            variant: .neutral,
            alignment: .start,
            tail: false,
          ),
        );
        expect(resolved.backgroundColor.a, lessThan(1.0));
      });

      testWidgets('Kbd folds material opacity into the key cap fill', (
        tester,
      ) async {
        final resolved = await _underTheme(tester, _glassTheme(), resolveKbd);
        expect(resolved.keyBackgroundColor.a, lessThan(1.0));
      });
    },
  );

  group('a fill-less panel is left alone', () {
    testWidgets(
      'Menubar with no border states no fill, so it takes no material (#4357)',
      (
        tester,
      ) async {
        // A borderless bar never reaches the decorated box at all (see
        // `menubar.dart`), so the material has nothing to attach to.
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveMenubar(
            context,
            variant: .defaultVariant,
          ),
        );
        expect(
          resolved.surfaceBlur,
          isNotNull,
        ); // the resolver still settles a value...

        await _pumpUnderGlass(tester, const Menubar(menus: [], border: false));
        // ...but the widget never wraps it, because the `if (widget.border)`
        // branch that owns `SurfaceBlur` never runs.
        expect(find.byType(SurfaceBlur), findsNothing);
      },
    );

    testWidgets(
      'Tabs underline variant states no fill, so it takes no material (#4357)',
      (
        tester,
      ) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveTabs(
            context,
            variant: .underline,
            size: .md,
          ),
        );

        expect(resolved.backgroundColor, isNull);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets('the material is gated on the fill, not handed out flat', (
      tester,
    ) async {
      // A panel that states a transparent background reads as a group
      // inside its parent rather than as a second panel. Handing that
      // one a material stacks a backdrop pass inside the pass already
      // running and draws a squared band around a box that is not
      // there — both visible, and measured once already.
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveToast(
          context,
          variant: CoreToastVariant.defaultVariant,
          dismissible: false,
          toastStyle: const CoreToastStyle(
            panelBackgroundColor: CoreColor.transparent,
          ),
        ),
      );

      expect(resolved.surfaceBlur, isNull);
      expect(resolved.surfaceSheen, isNull);
    });

    testWidgets('a ghost card states no fill, so it takes no material', (
      tester,
    ) async {
      // Not a hypothetical: this variant ships with a null background,
      // which is why the card marks conditionally rather than always.
      final resolved = await _underTheme(
        tester,
        _glassTheme(),
        (context) => resolveDescriptionCard(
          context,
          variant: CoreDescriptionCardVariant.ghost,
          size: CoreDescriptionCardSize.md,
        ),
      );

      expect(resolved.backgroundColor.a, 0);
      expect(resolved.surfaceBlur, isNull);
      expect(resolved.surfaceSheen, isNull);
    });

    testWidgets(
      'a table with no background states no fill, so it takes no material '
      '(#4359)',
      (tester) async {
        // The default: no caller-supplied `backgroundColor` at all, not
        // even a transparent one — the table's own designed-in state.
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          resolveTable,
        );

        expect(resolved.backgroundColor, isNull);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets(
      'a text field with an explicit transparent override takes no '
      'material (#4356)',
      (tester) async {
        // Unlike Table, the field always states a fill by design — this
        // only turns off once a caller explicitly overrides it.
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveTextField(
            context,
            hasError: false,
            enabled: true,
            size: CoreComponentSize.md,
            textFieldStyle: const CoreTextFieldStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.decoration.resolve(const {}).color!.a, 0);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets(
      'a text area with an explicit transparent override takes no '
      'material (#4356)',
      (tester) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveTextArea(
            context,
            hasError: false,
            size: CoreComponentSize.md,
            textAreaStyle: const CoreTextAreaStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.decoration.resolve(const {}).color!.a, 0);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets(
      'a phone input with an explicit transparent override takes no '
      'material (#4356)',
      (tester) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolvePhoneInput(
            context,
            phoneInputStyle: const CorePhoneInputStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.backgroundColor.a, 0);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets(
      'a chip input with an explicit transparent override takes no '
      'material (#4356)',
      (tester) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveChipInput(
            context,
            chipInputStyle: const CoreChipInputStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.backgroundColor.a, 0);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );

    testWidgets(
      'a file input idle with no background states no fill, so it takes '
      'no material (#4356)',
      (tester) async {
        // The default: no caller-supplied `backgroundColor` at all, not
        // even a transparent one — the drop zone's own designed-in
        // state (mirrors Table #4359).
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          resolveFileInput,
        );

        expect(resolved.backgroundColorIdle.a, 0);
        expect(resolved.surfaceBlurIdle, isNull);
        expect(resolved.surfaceSheenIdle, isNull);
      },
    );

    testWidgets(
      'a file input drag-active with an explicit transparent override '
      'takes no material (#4356)',
      (tester) async {
        // Unlike idle, drag-active always states a fill by design — this
        // only turns off once a caller explicitly overrides it.
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveFileInput(
            context,
            fileInputStyle: const CoreFileInputStyle(
              dragActiveBackgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.backgroundColorDragActive.a, 0);
        expect(resolved.surfaceBlurDragActive, isNull);
        expect(resolved.surfaceSheenDragActive, isNull);
      },
    );

    testWidgets(
      'a sortable item with an explicit transparent override takes no '
      'material (#4356)',
      (tester) async {
        final resolved = await _underTheme(
          tester,
          _glassTheme(),
          (context) => resolveSortable(
            context,
            sortableStyle: const CoreSortableStyle(
              itemBackgroundColor: CoreColor.transparent,
            ),
          ),
        );

        expect(resolved.itemBackgroundColor.a, 0);
        expect(resolved.surfaceBlur, isNull);
        expect(resolved.surfaceSheen, isNull);
      },
    );
  });
}

/// Pumps [child] under a glass theme, sized so overlay panels lay out.
Future<void> _pumpUnderGlass(
  WidgetTester tester,
  material.Widget child,
) async {
  await tester.pumpWidget(
    material.MaterialApp(
      home: Theme(
        data: _glassTheme(),
        child: material.Directionality(
          textDirection: material.TextDirection.ltr,
          child: material.Center(child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}
