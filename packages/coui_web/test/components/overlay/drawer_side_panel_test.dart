// The side panel the Drawer is drawn as — 400 wide, square, one line on the
// edge that faces the page, no shadow, a header that starts at the top with
// a gap before its close button, and an optional footer under its own rule.
// A top / bottom sheet keeps its rounded corners and has no line.
//
// The Flutter twin's rendered geometry is in
// `packages/coui_flutter/test/components/overlay/drawer_side_panel_test.dart`.

import 'dart:async';

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

ResolvedDrawer _resolve(
  ComponentTester tester,
  CoreDrawerSide side, {
  CoreDrawerStyle? style,
}) => resolveDrawer(
  _themedContext(tester),
  side: side,
  open: true,
  dragDelta: 0,
  drawerStyle: style,
);

void main() {
  group('side panel', () {
    testComponents('is 400 wide', (tester) async {
      final panel = _resolve(tester, .left).panel.inlineStyles!.properties;
      expect(panel['width'], '25.0rem');
    });

    testComponents('is square', (tester) async {
      final panel = _resolve(tester, .left).panel.inlineStyles!.properties;
      expect(panel['border-radius'], CoreBorderRadius.zero.toValue());
    });

    testComponents('has one 1px line, on the edge facing the page', (
      tester,
    ) async {
      final left = _resolve(tester, .left);
      expect(left.panel.className, contains('border-r'));
      expect(
        left.panel.inlineStyles!.properties['border-right-width'],
        'var(--coui-stroke-width-1)',
      );
      final right = _resolve(tester, .right);
      expect(right.panel.className, contains('border-l'));
      expect(
        right.panel.inlineStyles!.properties['border-left-width'],
        'var(--coui-stroke-width-1)',
      );
      expect(left.panel.className, contains('border-outline-variant'));
    });

    testComponents('casts no shadow', (tester) async {
      final panel = _resolve(tester, .left).panel.inlineStyles!.properties;
      expect(panel.containsKey('box-shadow'), isFalse);
    });

    testComponents('a stated shadow is still drawn', (tester) async {
      final panel = _resolve(
        tester,
        .left,
        style: const CoreDrawerStyle(panelBoxShadow: CoreShadow.md),
      ).panel.inlineStyles!.properties;
      expect(panel['box-shadow'], contains('var(--coui-surface-rim'));
    });

    testComponents('header starts at the top and spaces its close button 16', (
      tester,
    ) async {
      final header = _resolve(tester, .left).header;
      expect(header.className, contains('items-start'));
      expect(header.className, contains('justify-between'));
      expect(
        header.inlineStyles!.properties['gap'],
        spaceCss(CoreSpace.space16),
      );
    });

    testComponents('content is padded 20 / 24', (tester) async {
      final content = _resolve(tester, .left).content.inlineStyles!.properties;
      expect(content['padding'], CoreDrawerStyle.defaultPanelPadding.toValue());
    });
  });

  group('top / bottom sheet', () {
    testComponents('keeps the 16 corners facing the page and has no line', (
      tester,
    ) async {
      final bottom = _resolve(tester, .bottom).panel.inlineStyles!.properties;
      expect(
        bottom['border-radius'],
        const CoreBorderRadius.all(CoreRadius.radius16).toValue(),
      );
      expect(bottom['border-bottom-left-radius'], '0');
      expect(bottom['border-top-width'], 'var(--coui-stroke-width-0)');
      expect(bottom.containsKey('box-shadow'), isFalse);
    });
  });

  group('footer', () {
    testComponents('is pushed to the end under its own 16 / 24 rule', (
      tester,
    ) async {
      final footer = _resolve(tester, .left).footer;
      expect(footer.className, contains('justify-end'));
      expect(footer.className, contains('border-t'));
      expect(
        footer.inlineStyles!.properties['padding'],
        CoreDrawerStyle.defaultFooterPadding.toValue(),
      );
    });

    testComponents('renders only when stated', (tester) async {
      Finder footerRow() => find.byComponentPredicate(
        (c) => c is DomComponent && (c.classes ?? '').contains('justify-end'),
      );

      pumpWithTheme(
        tester,
        OverlayHost(
          child: Builder(
            builder: (context) {
              unawaited(
                Future<void>.microtask(
                  () => openDrawer<void>(
                    context: context,
                    side: .left,
                    builder: (close) => const Drawer(
                      content: Component.text('body'),
                      footer: Component.text('actions'),
                    ),
                  ),
                ),
              );
              return const span([]);
            },
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      expect(find.text('actions'), findsOneComponent);
      expect(footerRow(), findsOneComponent);
    });
  });
}
