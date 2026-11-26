import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_app.dart';

const ValueKey<String> _title = ValueKey('title');
const ValueKey<String> _description = ValueKey('description');
const ValueKey<String> _content = ValueKey('content');
const ValueKey<String> _footer = ValueKey('footer');

/// The width the sheet is given.
const double _width = 390;

const double _handleWidth = CoreBottomSheetStyle.defaultHandleWidth;
const double _handleHeight = CoreBottomSheetStyle.defaultHandleHeight;
final double _handleArea =
    CoreBottomSheetStyle.defaultHandlePadding.top + _handleHeight;
const CoreEdgeInsets _header = CoreBottomSheetStyle.defaultHeaderPadding;
const CoreEdgeInsets _body = CoreBottomSheetStyle.defaultContentPadding;
const double _titleHeight = 28; // 20 px at the title's 140% line.
const double _titleGap = CoreSpace.space8;
const double _close = 32;

SizedBox _box(Key key, double height) => SizedBox(key: key, height: height);

BottomSheet _sheet({
  bool showHandle = true,
  bool showCloseButton = false,
  bool showDivider = false,
  bool description = false,
  bool content = true,
  bool footer = true,
  void Function()? onClose,
  CoreBottomSheetStyle? style,
}) => BottomSheet(
  title: _box(_title, _titleHeight),
  description: description ? _box(_description, 24) : null,
  content: content ? _box(_content, 100) : null,
  footer: footer ? _box(_footer, 80) : null,
  showHandle: showHandle,
  showCloseButton: showCloseButton,
  showDivider: showDivider,
  onClose: onClose,
  bottomSheetStyle: style,
);

Future<void> _pump(
  WidgetTester tester,
  Widget sheet, {
  TextDirection textDirection = .ltr,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    SizedBox(width: _width, child: sheet),
    theme: ThemeData.fromCore(CoreThemePresets.light),
    textDirection: textDirection,
  );
}

Rect _rectOf(WidgetTester tester, Key key) => tester.getRect(find.byKey(key));

Rect _sheetRect(WidgetTester tester) =>
    tester.getRect(find.byType(BottomSheet));

Finder get _handle => find.byWidgetPredicate(
  (w) => w is SizedBox && w.width == _handleWidth && w.height == _handleHeight,
);

DecoratedBox _panel(WidgetTester tester) => tester.widget<DecoratedBox>(
  find
      .descendant(
        of: find.byType(BottomSheet),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

void main() {
  group('BottomSheet defaults', () {
    testWidgets('resolve to the Core default constants', (tester) async {
      late ResolvedBottomSheet resolved;
      late ColorScheme scheme;
      await pumpTestApp(
        tester,
        Builder(
          builder: (context) {
            resolved = resolveBottomSheet(context);
            scheme = Theme.of(context).colorScheme;
            return const SizedBox();
          },
        ),
      );

      expect(
        resolved.backgroundColor,
        scheme.resolve(CoreBottomSheetStyle.defaultBackgroundColor).toValue(),
      );
      expect(
        resolved.borderRadius,
        const BorderRadius.vertical(
          top: Radius.circular(CoreRadius.radius24),
        ),
      );
      expect(resolved.handleWidth, _handleWidth);
      expect(resolved.handleHeight, _handleHeight);
      expect(
        resolved.handleColor,
        scheme.resolve(CoreBottomSheetStyle.defaultHandleColor).toValue(),
      );
      expect(resolved.headerSpacing, CoreBottomSheetStyle.defaultHeaderSpacing);
      expect(resolved.dividerStyle, isNull);
    });
  });

  group('BottomSheet', () {
    testWidgets('the panel has two rounded top corners and a square bottom', (
      tester,
    ) async {
      await _pump(tester, _sheet());

      final decoration = _panel(tester).decoration as BoxDecoration;
      final radius = decoration.borderRadius! as BorderRadius;
      expect(radius.topLeft, const Radius.circular(CoreRadius.radius24));
      expect(radius.topRight, const Radius.circular(CoreRadius.radius24));
      expect(radius.bottomLeft, Radius.zero);
      expect(radius.bottomRight, Radius.zero);
      // No border and no shadow of its own.
      expect(decoration.border, isNull);
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('the handle is a 36 x 4 bar centred 8 below the top edge', (
      tester,
    ) async {
      await _pump(tester, _sheet());

      final sheet = _sheetRect(tester);
      final handle = tester.getRect(_handle);
      expect(handle.size, const Size(_handleWidth, _handleHeight));
      expect(handle.center.dx, sheet.center.dx);
      expect(
        handle.top - sheet.top,
        CoreBottomSheetStyle.defaultHandlePadding.top,
      );
      // The handle's area is 12 tall — the title starts 20 below it.
      expect(_handleArea, 12);
      expect(
        _rectOf(tester, _title).top - sheet.top,
        _handleArea + _header.top,
      );
    });

    testWidgets('the handle bar is the outline colour, pill-cornered', (
      tester,
    ) async {
      await _pump(tester, _sheet());

      final bar = tester.widget<DecoratedBox>(
        find.ancestor(of: _handle, matching: find.byType(DecoratedBox)).first,
      );
      final decoration = bar.decoration as BoxDecoration;
      final scheme = Theme.of(
        tester.element(find.byType(BottomSheet)),
      ).colorScheme;
      expect(
        decoration.color,
        scheme.resolve(CoreBottomSheetStyle.defaultHandleColor).toValue(),
      );
      expect(
        (decoration.borderRadius! as BorderRadius).topLeft,
        const Radius.circular(CoreRadius.radius9999),
      );
    });

    testWidgets('showHandle: false leaves out the bar and its area', (
      tester,
    ) async {
      await _pump(tester, _sheet(showHandle: false));

      expect(_handle, findsNothing);
      expect(
        _rectOf(tester, _title).top - _sheetRect(tester).top,
        _header.top,
      );
    });

    testWidgets('the slots stack: title, content, footer — with the insets', (
      tester,
    ) async {
      await _pump(tester, _sheet());

      final sheet = _sheetRect(tester);
      final title = _rectOf(tester, _title);
      final content = _rectOf(tester, _content);
      final footer = _rectOf(tester, _footer);

      expect(title.left - sheet.left, _header.left);
      expect(sheet.right - title.right, _header.right);
      expect(content.left - sheet.left, _body.left);
      expect(sheet.right - content.right, _body.right);
      // Header's bottom inset, then the content's top inset.
      expect(
        content.top - title.bottom,
        _header.bottom + _body.top,
      );
      // The footer sits flush under the content's bottom inset, edge to edge.
      expect(footer.top - content.bottom, _body.bottom);
      expect(footer.left, sheet.left);
      expect(footer.right, sheet.right);
      expect(sheet.bottom, footer.bottom);
    });

    testWidgets('without content or footer the sheet ends with the header', (
      tester,
    ) async {
      await _pump(tester, _sheet(content: false, footer: false));

      expect(find.byKey(_content), findsNothing);
      expect(find.byKey(_footer), findsNothing);
      final sheet = _sheetRect(tester);
      expect(
        sheet.bottom - _rectOf(tester, _title).bottom,
        _header.bottom,
      );
    });

    testWidgets('the description sits 8 under the title row', (tester) async {
      await _pump(tester, _sheet(description: true));

      expect(
        _rectOf(tester, _description).top - _rectOf(tester, _title).bottom,
        _titleGap,
      );
    });

    testWidgets('the close button is a 32 square, 12 past the title', (
      tester,
    ) async {
      var closed = 0;
      await _pump(
        tester,
        _sheet(showCloseButton: true, onClose: () => closed++),
      );

      final button = tester.getRect(find.byType(Button));
      final title = _rectOf(tester, _title);
      expect(button.size, const Size(_close, _close));
      expect(_sheetRect(tester).right - button.right, _header.right);
      expect(
        button.left - title.right,
        CoreBottomSheetStyle.defaultHeaderSpacing,
      );
      // Title and button share a centre line.
      expect(title.center.dy, button.center.dy);

      await tester.tap(find.byType(Button));
      expect(closed, 1);
    });

    testWidgets('the close button is absent by default', (tester) async {
      await _pump(tester, _sheet());

      expect(find.byType(Button), findsNothing);
    });

    testWidgets('showDivider: true draws a hairline between header and body', (
      tester,
    ) async {
      await _pump(tester, _sheet());
      expect(find.byType(Divider), findsNothing);

      await _pump(tester, _sheet(showDivider: true));
      expect(find.byType(Divider), findsOneWidget);
      expect(
        tester.getRect(find.byType(Divider)).top,
        greaterThanOrEqualTo(_rectOf(tester, _title).bottom),
      );
      expect(
        tester.getRect(find.byType(Divider)).bottom,
        lessThanOrEqualTo(_rectOf(tester, _content).top),
      );
    });

    testWidgets('a start / end header inset mirrors under rtl', (tester) async {
      const style = CoreBottomSheetStyle(
        headerPadding: CoreEdgeInsets.directional(
          start: 30,
          top: 20,
          end: 10,
          bottom: 8,
        ),
      );
      await _pump(tester, _sheet(style: style), textDirection: .rtl);

      final sheet = _sheetRect(tester);
      final title = _rectOf(tester, _title);
      expect(sheet.right - title.right, 30);
      expect(title.left - sheet.left, 10);
    });

    testWidgets('withStyle merges the patch into the sheet style', (
      tester,
    ) async {
      final sheet = _sheet().withStyle(
        const CoreBottomSheetStyle(handleWidth: 50),
      );
      expect(sheet.bottomSheetStyle?.handleWidth, 50);
      await _pump(tester, sheet);
      expect(tester.getRect(_handleWith(50)).width, 50);
    });
  });

  group('BottomSheet action area', () {
    final outlineVariant = ThemeData.fromCore(CoreThemePresets.light)
        .colorScheme
        .resolve(CoreBottomSheetStyle.defaultFooterDividerColor)
        .toValue();

    testWidgets('short content: no scroll, no footer hairline', (
      tester,
    ) async {
      await _pumpInViewport(tester, _sheet(), height: 800);

      expect(_footerLine(tester), BorderSide.none);
      expect(_sheetRect(tester).bottom, _rectOf(tester, _footer).bottom);
    });

    testWidgets(
      'tall content stops at 90 % of the viewport and scrolls above the '
      'pinned footer; the hairline shows while more lies below',
      (tester) async {
        await _pumpInViewport(
          tester,
          BottomSheet(
            title: _box(_title, _titleHeight),
            content: _box(_content, 1000),
            footer: _box(_footer, 80),
          ),
        );

        final sheet = _sheetRect(tester);
        expect(sheet.height, 600 * CoreBottomSheetStyle.defaultMaxHeightFactor);
        // The footer is pinned at the sheet's bottom edge …
        final footer = _rectOf(tester, _footer);
        expect(footer.bottom, sheet.bottom);
        // … and the content is clipped above it, never behind it.
        final viewport = tester.getRect(find.byType(SingleChildScrollView));
        expect(viewport.bottom, footer.top);

        final line = _footerLine(tester);
        expect(line.color, outlineVariant);
        expect(line.width, CoreBottomSheetStyle.defaultFooterDividerWidth);

        // Scrolled to the end, the content ends in view: no hairline.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, -2000),
        );
        await tester.pumpAndSettle();
        expect(_footerLine(tester), BorderSide.none);

        // Back up a little, more lies below again.
        await tester.drag(
          find.byType(SingleChildScrollView),
          const Offset(0, 100),
        );
        await tester.pumpAndSettle();
        expect(_footerLine(tester).color, outlineVariant);
      },
    );

    testWidgets('the hairline takes no layout height', (tester) async {
      await _pumpInViewport(
        tester,
        BottomSheet(
          title: _box(_title, _titleHeight),
          content: _box(_content, 1000),
          footer: _box(_footer, 80),
        ),
      );

      expect(_rectOf(tester, _footer).height, 80);
    });

    testWidgets('maxHeightFactor sets the ceiling', (tester) async {
      await _pumpInViewport(
        tester,
        BottomSheet(
          title: _box(_title, _titleHeight),
          content: _box(_content, 1000),
          bottomSheetStyle: const CoreBottomSheetStyle(maxHeightFactor: 0.5),
        ),
      );

      expect(_sheetRect(tester).height, 300);
    });

    testWidgets('an unbounded parent still lays out and scrolls', (
      tester,
    ) async {
      await _pumpInViewport(
        tester,
        SingleChildScrollView(
          child: BottomSheet(
            title: _box(_title, _titleHeight),
            content: _box(_content, 1000),
            footer: _box(_footer, 80),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(
        _sheetRect(tester).height,
        600 * CoreBottomSheetStyle.defaultMaxHeightFactor,
      );
    });

    testWidgets('a BottomActionBar in the footer paints no fill and no line', (
      tester,
    ) async {
      await _pumpInViewport(
        tester,
        BottomSheet(title: _box(_title, _titleHeight), footer: _bar()),
      );

      final decoration = _barDecoration(tester);
      expect(decoration.color?.a, 0);
      expect(decoration.border, isNull);
    });

    testWidgets('a standalone BottomActionBar keeps its fill and line', (
      tester,
    ) async {
      await _pumpInViewport(tester, _bar());

      final decoration = _barDecoration(tester);
      expect(decoration.color?.a, greaterThan(0));
      expect(decoration.border, isNotNull);
    });

    testWidgets("the bar's own style still wins inside the sheet", (
      tester,
    ) async {
      await _pumpInViewport(
        tester,
        BottomSheet(
          title: _box(_title, _titleHeight),
          footer: _bar(
            style: const CoreBottomActionBarStyle(
              backgroundColor: CoreColor.token(CoreColors.surface),
            ),
          ),
        ),
      );

      expect(_barDecoration(tester).color?.a, greaterThan(0));
    });
  });
}

Finder _handleWith(double width) => find.byWidgetPredicate(
  (w) => w is SizedBox && w.width == width && w.height == _handleHeight,
);

/// Pumps [child] under a viewport [height] tall — the test app's bare
/// `MediaQueryData()` reports a zero size, which the sheet reads as no
/// viewport (no ceiling).
Future<void> _pumpInViewport(
  WidgetTester tester,
  Widget child, {
  double height = 600,
}) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await pumpTestApp(
    tester,
    Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(size: Size(_width, height)),
        child: SizedBox(width: _width, child: child),
      ),
    ),
    theme: ThemeData.fromCore(CoreThemePresets.light),
  );
  // The first frame's metrics arrive after layout.
  await tester.pump();
}

/// The hairline the sheet paints over the footer's top edge.
BorderSide _footerLine(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(BottomSheet),
          matching: find.byWidgetPredicate(
            (w) => w is DecoratedBox && w.position == .foreground,
          ),
        )
        .first,
  );
  return ((box.decoration as BoxDecoration).border! as Border).top;
}

/// The bar's own fill-and-hairline box.
BoxDecoration _barDecoration(WidgetTester tester) =>
    tester
            .widget<Container>(
              find
                  .descendant(
                    of: find.byType(BottomActionBar),
                    matching: find.byType(Container),
                  )
                  .first,
            )
            .decoration!
        as BoxDecoration;

BottomActionBar _bar({CoreBottomActionBarStyle? style}) => BottomActionBar(
  primaryAction: Button(onPressed: () {}, child: const Text('Apply')),
  bottomActionBarStyle: style,
);
