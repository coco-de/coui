import 'package:coui_web/coui_web.dart';
import 'package:jaspr/jaspr.dart' as jaspr show Text;
import 'package:jaspr_test/jaspr_test.dart';

import '../../helpers/pump_with_theme.dart';

/// The DOM children of [element] — the nearest element nodes under it, past
/// the components (`Text`, `Button`) that only wrap one.
List<Element> _domChildren(Element element) {
  final out = <Element>[];
  void visit(Element child) {
    if (child.component is DomComponent) {
      out.add(child);
    } else {
      child.visitChildren(visit);
    }
  }

  element.visitChildren(visit);
  return out;
}

DomComponent _dom(Element element) => element.component as DomComponent;

/// The root element of the first [T] on the page.
Element _root<T extends Component>() =>
    _domChildren(find.byType(T).evaluate().single).single;

String _text(Element element) {
  final out = StringBuffer();
  void visit(Element child) {
    if (child.component case jaspr.Text(:final text)) out.write(text);
    child.visitChildren(visit);
  }

  visit(element);
  return out.toString();
}

/// The class tokens of [element].
List<String> _classes(Element element) => (_dom(element).classes ?? '')
    .split(' ')
    .where((c) => c.isNotEmpty)
    .toList();

/// An action that is plain markup, so a test can read its place by its class.
Component _marker(String name) =>
    div([Component.text(name)], classes: 'action-$name');

const _plum = CoreColor.fromARGB(255, 10, 20, 30);

/// The root classes of a default bar — the same in both layouts: a functional
/// surface, the full width, one column, the fill and the hairline colour as
/// token classes.
const _rootClasses =
    'coui-surface coui-surface-functional w-full box-border flex flex-col '
    'bg-surface border-outline-variant';

void main() {
  group('Web BottomActionBar', () {
    BottomActionBar bar({
      Component? secondaryAction = const Text('Cancel'),
      Component? description,
      Component? summaryLabel,
      Component? summaryValue,
      CoreBottomActionBarLayout layout = CoreBottomActionBarLayout.vertical,
      bool showDivider = true,
      CoreBottomActionBarStyle? style,
      Component primaryAction = const Text('Reserve'),
    }) => BottomActionBar(
      primaryAction: primaryAction,
      secondaryAction: secondaryAction,
      description: description,
      summaryLabel: summaryLabel,
      summaryValue: summaryValue,
      layout: layout,
      showDivider: showDivider,
      bottomActionBarStyle: style,
    );

    testComponents('the default bar: one filled column, the hairline on top', (
      tester,
    ) async {
      pumpWithTheme(tester, bar());

      final root = _root<BottomActionBar>();
      expect(_dom(root).tag, 'div');
      // A surface of the functional role, the full width, one column, the
      // fill and the hairline colour as token classes. No border-width class
      // — the width and the style are inline, so the line does not depend on
      // Tailwind's preflight.
      expect(
        _dom(root).classes,
        'coui-surface coui-surface-functional w-full box-border flex flex-col '
        'bg-surface border-outline-variant',
      );
      expect(_dom(root).classes, _rootClasses);
      expect(_dom(root).styles?.properties, {
        // top right bottom left — the side padding is the style's.
        'padding':
            '${spaceCss(CoreBottomActionBarStyle.defaultPadding.top)} '
            '${spaceCss(CoreBottomActionBarStyle.defaultPadding.right)} '
            '${spaceCss(CoreBottomActionBarStyle.defaultPadding.bottom)} '
            '${spaceCss(CoreBottomActionBarStyle.defaultPadding.left)}',
        'padding-bottom':
            'calc('
            '${spaceCss(CoreBottomActionBarStyle.defaultPadding.bottom)}'
            ' + env(safe-area-inset-bottom))',
        'gap': spaceCss(CoreBottomActionBarStyle.defaultSpacing),
        'border-top-width': strokeWidthCss(
          CoreBottomActionBarStyle.defaultDividerWidth,
        ),
        'border-top-style': 'solid',
        '--coui-surface-rgb': 'var(--coui-surface)',
        // The hairline's width, so the material's band reaches over it on the
        // top edge — the one edge that keeps a line.
        kWebSurfaceBleedTopVar: strokeWidthCss(
          CoreBottomActionBarStyle.defaultDividerWidth,
        ),
      });
    });

    testComponents('no wrapper and no note: the root holds the actions', (
      tester,
    ) async {
      pumpWithTheme(tester, bar());

      final root = _root<BottomActionBar>();
      // The hairline is the root's own border, not an element.
      expect(_domChildren(root), hasLength(1));
      expect(_text(root), 'ReserveCancel');
    });

    testComponents('the root is a div with role group and no name', (
      tester,
    ) async {
      pumpWithTheme(tester, bar());

      final root = _dom(_root<BottomActionBar>());
      expect(root.tag, 'div');
      expect(root.attributes?['role'], 'group');
      expect(root.attributes?.containsKey('aria-label'), isFalse);
    });

    testComponents('a caller attribute rides beside the role', (tester) async {
      pumpWithTheme(
        tester,
        const BottomActionBar(
          primaryAction: Text('Reserve'),
          attributes: {'aria-label': 'Booking actions'},
        ),
      );

      final root = _dom(_root<BottomActionBar>());
      expect(root.attributes?['role'], 'group');
      expect(root.attributes?['aria-label'], 'Booking actions');
    });

    testComponents('caller id, classes and css reach the root', (
      tester,
    ) async {
      pumpWithTheme(
        tester,
        const BottomActionBar(
          primaryAction: Text('Reserve'),
          id: 'booking-bar',
          classes: 'sticky',
          css: Styles(raw: {'z-index': '10'}),
        ),
      );

      final root = _dom(_root<BottomActionBar>());
      expect(root.id, 'booking-bar');
      expect(_classes(_root<BottomActionBar>()), contains('sticky'));
      expect(root.styles?.properties['z-index'], '10');
      expect(root.styles?.properties['padding-bottom'], isNotNull);
    });

    group('vertical', () {
      testComponents('the actions are flex items of one column, in order', (
        tester,
      ) async {
        pumpWithTheme(tester, bar());

        final [actions] = _domChildren(_root<BottomActionBar>());
        // No `items-*`: the default (stretch) is what widens each action.
        expect(_dom(actions).classes, 'flex flex-col');
        expect(_dom(actions).styles?.properties, {
          'gap': spaceCss(CoreBottomActionBarStyle.defaultSpacing),
        });
        final [primary, secondary] = _domChildren(actions);
        expect(_text(primary), 'Reserve');
        expect(_text(secondary), 'Cancel');
      });

      testComponents('a lone primary is the only item', (tester) async {
        pumpWithTheme(tester, bar(secondaryAction: null));

        final [actions] = _domChildren(_root<BottomActionBar>());
        expect(_domChildren(actions), hasLength(1));
        expect(_text(actions), 'Reserve');
      });

      testComponents('a real Button is a direct flex item, so it stretches', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            primaryAction: Button(child: const Text('Pay')),
            secondaryAction: Button(
              variant: .ghost,
              child: const Text('Cancel'),
            ),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        // A `Button` is inline-flex: only as a flex item is it blockified and
        // widened by the column — a block wrapper would leave it at its
        // content width.
        expect(_domChildren(actions).map((e) => _dom(e).tag), [
          'button',
          'button',
        ]);
      });

      testComponents('the note comes first, above the actions', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(description: const Text('Free cancellation')),
        );

        final [note, actions] = _domChildren(_root<BottomActionBar>());
        expect(_text(note), 'Free cancellation');
        expect(_dom(actions).classes, 'flex flex-col');
      });
    });

    group('weighted · icon · summary', () {
      for (final layout in [
        CoreBottomActionBarLayout.weighted,
        CoreBottomActionBarLayout.icon,
      ]) {
        testComponents('$layout keeps the secondary cell at its own width and '
            'lets the primary cell grow', (tester) async {
          pumpWithTheme(
            tester,
            bar(
              layout: layout,
              primaryAction: _marker('primary'),
              secondaryAction: _marker('secondary'),
            ),
          );

          final [actions] = _domChildren(_root<BottomActionBar>());
          expect(_dom(actions).classes, 'flex flex-row items-center');
          final [secondaryCell, primaryCell] = _domChildren(actions);
          // `shrink-0` and no `flex-1`: the cell keeps the action's own width.
          expect(_dom(secondaryCell).classes, 'flex flex-col shrink-0');
          expect(_dom(primaryCell).classes, 'flex flex-col flex-1 min-w-0');
        });
      }

      testComponents('summary sets the caption over the figure at their own '
          'width, then the primary cell; no secondary', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.summary,
            primaryAction: _marker('primary'),
            secondaryAction: _marker('secondary'),
            summaryLabel: _marker('label'),
            summaryValue: _marker('value'),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        expect(_dom(actions).classes, 'flex flex-row items-center');
        final [summary, primaryCell] = _domChildren(actions);
        expect(_dom(summary).classes, 'flex flex-col shrink-0');
        expect(_dom(primaryCell).classes, 'flex flex-col flex-1 min-w-0');
        final [labelWrap, valueWrap] = _domChildren(summary);
        expect(_dom(labelWrap).classes, contains('text-body-small'));
        expect(_dom(valueWrap).classes, contains('text-title-medium'));
        expect(_domChildren(actions), hasLength(2));
      });

      testComponents('summaryCompact grows the summary cell and keeps the '
          'primary at its own width at the end; no secondary', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.summaryCompact,
            primaryAction: _marker('primary'),
            secondaryAction: _marker('secondary'),
            summaryLabel: _marker('label'),
            summaryValue: _marker('value'),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        expect(_dom(actions).classes, 'flex flex-row items-center');
        final [summaryCell, primaryCell] = _domChildren(actions);
        expect(_dom(summaryCell).classes, 'flex flex-col flex-1 min-w-0');
        expect(_dom(primaryCell).classes, 'flex flex-col shrink-0');
        final [summary] = _domChildren(summaryCell);
        final [labelWrap, valueWrap] = _domChildren(summary);
        expect(_dom(labelWrap).classes, contains('text-body-small'));
        expect(_dom(valueWrap).classes, contains('text-title-medium'));
      });

      testComponents('summaryCompact without a summary keeps the grown cell, '
          'so the primary still ends the row', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.summaryCompact,
            primaryAction: _marker('primary'),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        final [summaryCell, primaryCell] = _domChildren(actions);
        expect(_domChildren(summaryCell), isEmpty);
        expect(_dom(primaryCell).classes, 'flex flex-col shrink-0');
      });
    });

    group('horizontal', () {
      testComponents('one centred row of equal-width cells, secondary first', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.horizontal,
            primaryAction: _marker('primary'),
            secondaryAction: _marker('secondary'),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        // Centred across explicitly: a flex row stretches by default and the
        // Flutter twin's `Row` centres.
        expect(_dom(actions).classes, 'flex flex-row items-center');
        expect(_dom(actions).styles?.properties, {
          'gap': spaceCss(CoreBottomActionBarStyle.defaultSpacing),
        });
        final [secondaryCell, primaryCell] = _domChildren(actions);
        for (final cell in [secondaryCell, primaryCell]) {
          // flex-1 from a zero basis makes the cells the same width; the
          // column makes the action inside stretch to it.
          expect(_dom(cell).classes, 'flex flex-col flex-1 min-w-0');
          expect(_dom(cell).styles, isNull);
        }
        expect(
          _dom(_domChildren(secondaryCell).single).classes,
          'action-secondary',
        );
        expect(
          _dom(_domChildren(primaryCell).single).classes,
          'action-primary',
        );
      });

      testComponents('a lone primary fills the row', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.horizontal,
            secondaryAction: null,
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        final cells = _domChildren(actions);
        expect(cells, hasLength(1));
        expect(_dom(cells.single).classes, 'flex flex-col flex-1 min-w-0');
        expect(_text(cells.single), 'Reserve');
      });

      testComponents('a real Button sits directly in its flex-column cell', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.horizontal,
            primaryAction: Button(child: const Text('Pay')),
            secondaryAction: Button(
              variant: .ghost,
              child: const Text('Cancel'),
            ),
          ),
        );

        final [actions] = _domChildren(_root<BottomActionBar>());
        for (final cell in _domChildren(actions)) {
          expect(_domChildren(cell).map((e) => _dom(e).tag), ['button']);
        }
      });

      testComponents('the note sits above the row', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.horizontal,
            description: const Text('Free cancellation'),
          ),
        );

        final [note, actions] = _domChildren(_root<BottomActionBar>());
        expect(_text(note), 'Free cancellation');
        expect(_dom(actions).classes, 'flex flex-row items-center');
      });

      testComponents('the root is the same column in both layouts', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(layout: CoreBottomActionBarLayout.horizontal),
        );

        final root = _root<BottomActionBar>();
        expect(_dom(root).classes, _rootClasses);
      });
    });

    group('the hairline', () {
      testComponents('showDivider off draws no border at all', (tester) async {
        pumpWithTheme(tester, bar(showDivider: false));

        final root = _root<BottomActionBar>();
        expect(
          _dom(root).classes,
          _rootClasses.replaceFirst(' border-outline-variant', ''),
        );
        final properties = _dom(root).styles!.properties;
        expect(properties.keys.where((k) => k.startsWith('border')), isEmpty);
      });

      testComponents('is a top border: width and style inline, colour class', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar().withStyle(
            const CoreBottomActionBarStyle(
              dividerWidth: CoreStrokeWidth.stroke2,
            ),
          ),
        );

        final root = _root<BottomActionBar>();
        final properties = _dom(root).styles!.properties;
        expect(properties['border-top-width'], strokeWidthCss(2));
        expect(properties['border-top-style'], 'solid');
        // The width never rides a class: `border-t` would lean on the style
        // Tailwind's preflight supplies.
        expect(
          _classes(
            root,
          ).where((c) => c == 'border' || c.startsWith('border-t')),
          isEmpty,
        );
        expect(_classes(root), contains('border-outline-variant'));
      });

      testComponents(
        'a raw colour goes inline on the top edge, its class drops',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            bar(style: const CoreBottomActionBarStyle(dividerColor: _plum)),
          );

          final root = _root<BottomActionBar>();
          expect(_classes(root), isNot(contains('border-outline-variant')));
          expect(
            _dom(root).styles?.properties['border-top-color'],
            _plum.toValue(),
          );
        },
      );

      testComponents('a token colour stays a class', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              dividerColor: CoreColor.token(CoreColors.outline),
            ),
          ),
        );

        final root = _root<BottomActionBar>();
        expect(_classes(root), contains('border-outline'));
        expect(_classes(root), isNot(contains('border-outline-variant')));
        expect(
          _dom(root).styles?.properties.containsKey('border-top-color'),
          isFalse,
        );
      });
    });

    group('the bottom edge', () {
      testComponents('adds the device safe area to the bottom padding', (
        tester,
      ) async {
        pumpWithTheme(tester, bar());

        final properties = _dom(_root<BottomActionBar>()).styles!.properties;
        expect(
          properties['padding-bottom'],
          'calc(${spaceCss(CoreBottomActionBarStyle.defaultPadding.bottom)} '
          '+ env(safe-area-inset-bottom))',
        );
        // The other edges are the style's own, each a spacing variable. No
        // inset on the sides or the top.
        expect(properties['padding'], contains('var(--coui-space-'));
        expect(properties['padding'], isNot(contains('env(')));
      });

      testComponents('the bottom longhand follows the shorthand', (
        tester,
      ) async {
        pumpWithTheme(tester, bar());

        final keys = _dom(
          _root<BottomActionBar>(),
        ).styles!.properties.keys.toList();
        expect(
          keys.indexOf('padding-bottom'),
          greaterThan(keys.indexOf('padding')),
        );
      });

      testComponents('a stated bottom padding is the one the inset adds to', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              padding: CoreEdgeInsets.fromLTRB(
                CoreSpace.space16,
                CoreSpace.space8,
                CoreSpace.space16,
                CoreSpace.space24,
              ),
            ),
          ),
        );

        final properties = _dom(_root<BottomActionBar>()).styles!.properties;
        expect(
          properties['padding-bottom'],
          'calc(${spaceCss(CoreSpace.space24)} + env(safe-area-inset-bottom))',
        );
      });

      testComponents('a directional padding emits logical sides, no throw', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              padding: CoreEdgeInsets.directional(
                start: CoreSpace.space24,
                end: CoreSpace.space16,
                top: CoreSpace.space8,
                bottom: CoreSpace.space12,
              ),
            ),
          ),
        );

        final properties = _dom(_root<BottomActionBar>()).styles!.properties;
        expect(properties.containsKey('padding'), isFalse);
        expect(
          properties['padding-inline-start'],
          spaceCss(CoreSpace.space24),
        );
        expect(properties['padding-inline-end'], spaceCss(CoreSpace.space16));
        expect(properties['padding-block-start'], spaceCss(CoreSpace.space8));
        final keys = properties.keys.toList();
        // The physical bottom comes after the logical one, so it wins.
        expect(
          keys.indexOf('padding-bottom'),
          greaterThan(keys.indexOf('padding-block-end')),
        );
        expect(
          properties['padding-bottom'],
          'calc(${spaceCss(CoreSpace.space12)} + env(safe-area-inset-bottom))',
        );
      });
    });

    group('the surface', () {
      testComponents('carries the functional marker and publishes its fill', (
        tester,
      ) async {
        pumpWithTheme(tester, bar());

        final root = _root<BottomActionBar>();
        expect(
          _classes(root),
          containsAll(webSurfaceMarkerFor(CoreSurfaceRole.functional)),
        );
        expect(
          _dom(root).styles?.properties[kWebSurfaceFillVar],
          'var(--coui-surface)',
        );
        // An opaque fill states no alpha — it reads the reset every marked
        // surface starts from.
        expect(
          _dom(root).styles?.properties.containsKey(kWebSurfaceFillAlphaVar),
          isFalse,
        );
      });

      testComponents('a translucent token fill publishes its alpha too', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              backgroundColor: CoreColor.token(
                CoreColors.surface,
                opacity: 0.5,
              ),
            ),
          ),
        );

        final properties = _dom(_root<BottomActionBar>()).styles!.properties;
        expect(properties[kWebSurfaceFillVar], 'var(--coui-surface)');
        expect(properties[kWebSurfaceFillAlphaVar], '0.5');
      });

      testComponents('a token fill override is a class and still a surface', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
            ),
          ),
        );

        final root = _root<BottomActionBar>();
        expect(_classes(root), contains('bg-surface-container'));
        expect(_classes(root), isNot(contains('bg-surface')));
        expect(
          _dom(root).styles?.properties[kWebSurfaceFillVar],
          'var(--coui-surface-container)',
        );
      });

      testComponents(
        'a raw fill goes inline, its class drops, none published',
        (
          tester,
        ) async {
          pumpWithTheme(
            tester,
            bar(style: const CoreBottomActionBarStyle(backgroundColor: _plum)),
          );

          final root = _root<BottomActionBar>();
          expect(_classes(root), isNot(contains('bg-surface')));
          expect(
            _dom(root).styles?.properties['background-color'],
            _plum.toValue(),
          );
          // A raw colour was stated, not given — a preset does not overrule it.
          expect(
            _dom(root).styles?.properties.containsKey(kWebSurfaceFillVar),
            isFalse,
          );
        },
      );

      testComponents('a fill that paints nothing is not a surface', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            style: const CoreBottomActionBarStyle(
              backgroundColor: CoreColor.transparent,
            ),
          ),
        );

        final root = _root<BottomActionBar>();
        expect(_classes(root), isNot(contains(kWebSurfaceMarker)));
        expect(_classes(root), isNot(contains(kWebSurfaceRoleFunctional)));
        expect(
          _dom(root).styles?.properties.containsKey(kWebSurfaceFillVar),
          isFalse,
        );
        // With no marker no preset rule restates the edge, so the hairline
        // keeps the colour it states — as the Flutter twin's does, which gets
        // no material edge to take its place either.
        final divider =
            CoreBottomActionBarStyle.defaultDividerColor.tailwindColor;
        expect(_classes(root), contains('border-$divider'));
      });
    });

    group('the note', () {
      testComponents('wraps in its role, colour and centred alignment', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(description: const Text('Free cancellation')),
        );

        final [note, _] = _domChildren(_root<BottomActionBar>());
        // The slot's `Text` inherits all of it.
        expect(
          _dom(note).classes,
          'text-body-small text-on-surface-variant text-center',
        );
        expect(_dom(note).styles, isNull);
        expect(_text(note), 'Free cancellation');
      });

      testComponents('a stated alignment is its own class', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            description: const Text('Free cancellation'),
            style: const CoreBottomActionBarStyle(
              descriptionTextAlign: CoreTextAlign.start,
            ),
          ),
        );

        final [note, _] = _domChildren(_root<BottomActionBar>());
        expect(
          _dom(note).classes,
          'text-body-small text-on-surface-variant text-start',
        );
      });

      testComponents('a stated typography keeps the role and overlays inline', (
        tester,
      ) async {
        pumpWithTheme(
          tester,
          bar(
            description: const Text('Free cancellation'),
            style: const CoreBottomActionBarStyle(
              descriptionTextStyle: CoreTextStyle(
                color: _plum,
                fontSize: CoreFontSize.s14,
              ),
            ),
          ),
        );

        final [note, _] = _domChildren(_root<BottomActionBar>());
        // The role stays a class, a raw colour has none.
        expect(_dom(note).classes, 'text-body-small text-center');
        expect(_dom(note).styles?.properties['color'], _plum.toValue());
        expect(_dom(note).styles?.properties['font-size'], isNotNull);
      });
    });

    group('the style chain', () {
      testComponents('a stated spacing reaches both gaps', (tester) async {
        pumpWithTheme(
          tester,
          bar(
            layout: CoreBottomActionBarLayout.horizontal,
            style: const CoreBottomActionBarStyle(spacing: CoreSpace.space16),
          ),
        );

        final root = _root<BottomActionBar>();
        expect(
          _dom(root).styles?.properties['gap'],
          spaceCss(CoreSpace.space16),
        );
        final [actions] = _domChildren(root);
        expect(
          _dom(actions).styles?.properties['gap'],
          spaceCss(CoreSpace.space16),
        );
      });

      testComponents('the project theme reaches, the instance wins', (
        tester,
      ) async {
        tester.pumpComponent(
          Theme(
            data: ThemeData.coui.copyWith(
              coreComponentTheme: const CoreComponentTheme(
                bottomActionBar: CoreBottomActionBarTheme(
                  style: CoreBottomActionBarStyle(
                    spacing: CoreSpace.space12,
                    dividerWidth: CoreStrokeWidth.stroke2,
                  ),
                ),
              ),
            ),
            child: bar().withStyle(
              const CoreBottomActionBarStyle(spacing: CoreSpace.space16),
            ),
          ),
        );

        final properties = _dom(_root<BottomActionBar>()).styles!.properties;
        // The theme's divider width, the instance's spacing.
        expect(properties['border-top-width'], strokeWidthCss(2));
        expect(properties['gap'], spaceCss(CoreSpace.space16));
      });

      testComponents('withStyle merges field by field, later wins', (
        tester,
      ) async {
        final chained = bar()
            .withStyle(
              const CoreBottomActionBarStyle(
                spacing: CoreSpace.space12,
                backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
              ),
            )
            .withStyle(
              const CoreBottomActionBarStyle(spacing: CoreSpace.space16),
            );

        expect(
          chained.bottomActionBarStyle,
          const CoreBottomActionBarStyle(
            spacing: CoreSpace.space16,
            backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
          ),
        );
        // The slots and the other fields come through the copy.
        expect(chained.layout, CoreBottomActionBarLayout.vertical);
        expect(chained.showDivider, isTrue);
      });
    });
  });
}
