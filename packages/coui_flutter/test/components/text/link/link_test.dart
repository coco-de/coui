import 'dart:ui' as ui;

import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart' as material;
import 'package:flutter/semantics.dart' show SemanticsNode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _kHref = 'https://example.com';
const _kRed = CoreColor(0xFFAA0000);
const _kBlue = CoreColor(0xFF0000AA);

material.Widget _buildApp(
  material.Widget child, {
  ThemeData data = const ThemeData(),
}) => material.MaterialApp(
  home: Theme(
    data: data,
    child: material.Scaffold(body: Center(child: child)),
  ),
);

/// What [resolveLink] returns for the arguments, with the painter that turns
/// a Core colour into the Flutter colour the active theme draws it as.
Future<({ResolvedLink resolved, Color Function(CoreColor) paint})> _resolve(
  WidgetTester tester, {
  CoreLinkVariant variant = CoreLinkVariant.defaultVariant,
  bool underline = false,
  CoreLinkStyle? linkStyle,
  ThemeData data = const ThemeData(),
}) async {
  late ResolvedLink resolved;
  late ColorScheme scheme;
  await tester.pumpWidget(
    _buildApp(
      Builder(
        builder: (context) {
          scheme = Theme.of(context).colorScheme;
          resolved = resolveLink(
            context,
            variant: variant,
            underline: underline,
            linkStyle: linkStyle,
          );
          return const SizedBox.shrink();
        },
      ),
      data: data,
    ),
  );

  return (
    resolved: resolved,
    paint: (CoreColor c) => scheme.resolve(c).toValue(),
  );
}

/// The decoration the link's label is painted with right now — read off the
/// rendered text, so it includes whatever style the widget chose for the
/// current interaction state.
TextDecoration? _decoration(WidgetTester tester) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.byType(Link), matching: find.byType(RichText)),
  );

  return richText.text.style?.decoration;
}

Finder _label() => find.text(_kHref);

void main() {
  group('Link — callback accessibility', () {
    testWidgets('owns one accessible control for its label', (tester) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildApp(Link(href: _kHref, onPressed: () {})),
        );
        var root = tester.getSemantics(find.bySemanticsLabel(_kHref));
        while (root.parent != null) {
          root = root.parent!;
        }
        final controls = <SemanticsNode>[];
        void collect(SemanticsNode node) {
          final flags = node.getSemanticsData().flagsCollection;
          if (flags.isButton || flags.isLink) controls.add(node);
          node.visitChildren((child) {
            collect(child);
            return true;
          });
        }

        collect(root);
        expect(controls, hasLength(1));
        expect(controls.single.getSemanticsData().label, _kHref);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('exposes an action without browser-owned navigation', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      try {
        await tester.pumpWidget(
          _buildApp(Link(href: _kHref, onPressed: () {})),
        );
        final data = tester
            .getSemantics(find.bySemanticsLabel(_kHref))
            .getSemanticsData();

        expect(data.flagsCollection.isButton, isTrue);
        expect(data.flagsCollection.isLink, !kIsWeb);
        expect(data.hasAction(ui.SemanticsAction.tap), isTrue);
        expect(data.linkUrl, isNull);
      } finally {
        semantics.dispose();
      }
    });

    testWidgets('a pointer tap invokes the host callback once', (tester) async {
      var calls = 0;
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () => calls++)),
      );

      await tester.tap(_label());
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('Tab focus activates the host callback with Enter and Space', (
      tester,
    ) async {
      var calls = 0;
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () => calls++)),
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(calls, 2);
    });
  });

  group('resolveLink — variant colour', () {
    testWidgets('standard reads the link colour, text and underline', (
      tester,
    ) async {
      final (:resolved, :paint) = await _resolve(tester);
      final link = paint(const CoreColor.token(CoreColors.link));

      expect(resolved.labelStyle.color, link);
      expect(resolved.labelStyle.decorationColor, link);
    });

    testWidgets('muted reads on-surface-variant, text and underline', (
      tester,
    ) async {
      final (:resolved, :paint) = await _resolve(
        tester,
        variant: CoreLinkVariant.muted,
      );
      final muted = paint(const CoreColor.token(CoreColors.onSurfaceVariant));

      expect(resolved.labelStyle.color, muted);
      expect(resolved.labelStyle.decorationColor, muted);
    });

    testWidgets('the two variants are different colours', (tester) async {
      final standard = await _resolve(tester);
      final muted = await _resolve(tester, variant: CoreLinkVariant.muted);

      expect(
        standard.resolved.labelStyle.color,
        isNot(muted.resolved.labelStyle.color),
      );
    });

    testWidgets('the theme overrides one variant and leaves the other', (
      tester,
    ) async {
      const data = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          link: CoreLinkTheme(
            variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kRed)},
          ),
        ),
      );
      final muted = await _resolve(
        tester,
        variant: CoreLinkVariant.muted,
        data: data,
      );
      final standard = await _resolve(tester, data: data);

      expect(muted.resolved.labelStyle.color, const Color(0xFFAA0000));
      expect(
        standard.resolved.labelStyle.color,
        standard.paint(const CoreColor.token(CoreColors.link)),
      );
    });

    testWidgets('the instance wins over the theme variant layer', (
      tester,
    ) async {
      const data = ThemeData(
        coreComponentTheme: CoreComponentTheme(
          link: CoreLinkTheme(
            variantStyles: {CoreLinkVariant.muted: CoreLinkStyle(color: _kRed)},
          ),
        ),
      );
      final (:resolved, paint: _) = await _resolve(
        tester,
        variant: CoreLinkVariant.muted,
        linkStyle: const CoreLinkStyle(color: _kBlue),
        data: data,
      );

      expect(resolved.labelStyle.color, const Color(0xFF0000AA));
    });
  });

  group('resolveLink — the underline follows the text', () {
    testWidgets('a text colour override carries the underline with it', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(
        tester,
        linkStyle: const CoreLinkStyle(color: _kRed),
      );

      expect(resolved.labelStyle.color, const Color(0xFFAA0000));
      expect(resolved.labelStyle.decorationColor, const Color(0xFFAA0000));
    });

    testWidgets('an explicit underline colour wins over the text colour', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(
        tester,
        linkStyle: const CoreLinkStyle(color: _kRed, underlineColor: _kBlue),
      );

      expect(resolved.labelStyle.color, const Color(0xFFAA0000));
      expect(resolved.labelStyle.decorationColor, const Color(0xFF0000AA));
    });

    testWidgets('the nested label colour is more specific than the flat one', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(
        tester,
        linkStyle: const CoreLinkStyle(
          color: _kRed,
          labelStyle: CoreTextStyle(color: _kBlue),
        ),
      );

      expect(resolved.labelStyle.color, const Color(0xFF0000AA));
    });
  });

  group('resolveLink — decoration', () {
    testWidgets('by default the underline waits for an interaction', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(tester);

      expect(resolved.labelStyle.decoration, TextDecoration.none);
      expect(
        resolved.interactionLabelStyle.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('underline: true is underlined at rest and in interaction', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(tester, underline: true);

      expect(resolved.labelStyle.decoration, TextDecoration.underline);
      expect(
        resolved.interactionLabelStyle.decoration,
        TextDecoration.underline,
      );
    });

    testWidgets('the interaction decoration is a style field', (tester) async {
      final (:resolved, paint: _) = await _resolve(
        tester,
        linkStyle: const CoreLinkStyle(
          interactionTextDecoration: CoreTextDecoration.lineThrough,
        ),
      );

      expect(resolved.labelStyle.decoration, TextDecoration.none);
      expect(
        resolved.interactionLabelStyle.decoration,
        TextDecoration.lineThrough,
      );
    });

    testWidgets('only the decoration differs between the two label styles', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(tester);

      expect(
        resolved.interactionLabelStyle.copyWith(
          decoration: TextDecoration.none,
        ),
        resolved.labelStyle,
      );
    });

    testWidgets('the inline span is always underlined', (tester) async {
      final (:resolved, paint: _) = await _resolve(tester);

      expect(resolved.spanTextStyle.decoration, TextDecoration.underline);
    });

    testWidgets("the underline is the font's own — no thickness is stated", (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(tester, underline: true);

      expect(resolved.labelStyle.decorationThickness, isNull);
      expect(resolved.interactionLabelStyle.decorationThickness, isNull);
      expect(resolved.spanTextStyle.decorationThickness, isNull);
    });
  });

  group('Link — interaction underline', () {
    // A desktop pointer shows hover feedback from the first move; a test
    // platform starts in touch mode, where hover highlights are withheld
    // until the mode flips — after the enter event that carried the hover.
    setUp(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
    });
    tearDown(() {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.automatic;
    });

    testWidgets('is not underlined while idle', (tester) async {
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () {})),
      );
      await tester.pumpAndSettle();

      expect(_decoration(tester), TextDecoration.none);
    });

    testWidgets('is underlined while hovered, and not after', (tester) async {
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () {})),
      );
      await tester.pumpAndSettle();

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_label()));
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.underline);

      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.none);
    });

    testWidgets('is underlined while pressed, and not after', (tester) async {
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () {})),
      );
      await tester.pumpAndSettle();

      final press = await tester.startGesture(tester.getCenter(_label()));
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.underline);

      await press.up();
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.none);
    });

    testWidgets('is underlined while keyboard-focused', (tester) async {
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, onPressed: () {})),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.none);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(_decoration(tester), TextDecoration.underline);
    });

    testWidgets('an always-underlined link stays underlined throughout', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(Link(href: _kHref, underline: true, onPressed: () {})),
      );
      await tester.pumpAndSettle();
      expect(_decoration(tester), TextDecoration.underline);

      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(_label()));
      await tester.pumpAndSettle();
      await mouse.moveTo(Offset.zero);
      await tester.pumpAndSettle();

      expect(_decoration(tester), TextDecoration.underline);
    });
  });

  group('Link — layout', () {
    testWidgets('reserves no gap below the text for the underline', (
      tester,
    ) async {
      // The underline is the font's own line inside the text box; nothing
      // is added beneath it.
      await tester.pumpWidget(
        _buildApp(const Link(href: _kHref, underline: true)),
      );
      await tester.pumpAndSettle();

      final box = tester.getSize(
        find.descendant(
          of: find.byType(Link),
          matching: find.byType(AnimatedDefaultTextStyle),
        ),
      );
      expect(box.height, tester.getSize(_label()).height);
    });

    testWidgets('underline does not change the box', (tester) async {
      await tester.pumpWidget(
        _buildApp(const Link(href: _kHref, underline: true)),
      );
      await tester.pumpAndSettle();
      final underlined = tester.getSize(find.byType(Link));

      await tester.pumpWidget(_buildApp(const Link(href: _kHref)));
      await tester.pumpAndSettle();

      expect(tester.getSize(find.byType(Link)), underlined);
    });
  });

  // The widget form hands its label style to `AnimatedDefaultTextStyle`, which
  // *replaces* the ambient default rather than merging into it. A label that
  // states no family therefore has none to inherit and falls to the system
  // font — tofu for Hangul in an environment without one, and the wrong
  // typeface everywhere else.
  group('Link — typeface', () {
    testWidgets('the label names the CoUI font stack', (tester) async {
      final (:resolved, paint: _) = await _resolve(tester);

      for (final style in [
        resolved.labelStyle,
        resolved.interactionLabelStyle,
      ]) {
        expect(style.fontFamily, CoreFontFamily.sans);
        expect(style.fontFamilyFallback, isNotEmpty);
      }
    });

    testWidgets('the text under a link is drawn in that stack', (
      tester,
    ) async {
      await tester.pumpWidget(
        _buildApp(const Link(href: _kHref, child: Text('자세히 보기'))),
      );

      final style = DefaultTextStyle.of(
        tester.element(find.text('자세히 보기')),
      ).style;
      expect(style.fontFamily, CoreFontFamily.sans);
      expect(style.fontFamilyFallback, isNotEmpty);
    });

    testWidgets('an inline link still takes the surrounding paragraph’s', (
      tester,
    ) async {
      final (:resolved, paint: _) = await _resolve(tester);

      // The span form flows inside someone else's paragraph on purpose.
      expect(resolved.spanTextStyle.fontFamily, isNull);
    });
  });

  group('Link — constructor', () {
    test('defaults to the standard variant without a permanent underline', () {
      const link = Link(href: _kHref);

      expect(link.variant, CoreLinkVariant.standard);
      expect(link.underline, isFalse);
    });

    test('copyWith carries the variant', () {
      const link = Link(href: _kHref, variant: CoreLinkVariant.muted);

      expect(link.copyWith(underline: true).variant, CoreLinkVariant.muted);
      expect(
        link.copyWith(variant: CoreLinkVariant.standard).variant,
        CoreLinkVariant.standard,
      );
    });
  });
}
