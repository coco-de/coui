/// Tests for [CoreMockupBrowserStyle] and the `MockupBrowser` contract
/// defaults — the window body / content card split.
library;

import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

const _kRadius = CoreBorderRadius.all(12);
const _kBg = CoreColor(0xFF3B82F6);
const _kIcon = CoreIconStyle(size: 20);
const _kIconColor = CoreColor(0xFF112233);

void main() {
  group('CoreMockupBrowserContract behaviour defaults', () {
    test('the controls render and the address bar reads as a web page', () {
      expect(CoreMockupBrowserContract.defaultShowControls, isTrue);
      expect(CoreMockupBrowserContract.defaultAddressBar, 'example.com');
    });
  });

  group('CoreMockupBrowserStyle design-system defaults', () {
    test('the body is one step darker than the card and the pill', () {
      expect(
        CoreMockupBrowserStyle.defaultBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainerLow),
      );
      expect(
        CoreMockupBrowserStyle.defaultContentBackgroundColor,
        const CoreColor.token(CoreColors.surface),
      );
      expect(
        CoreMockupBrowserStyle.defaultAddressBarBackgroundColor,
        const CoreColor.token(CoreColors.surfaceContainer, opacity: .7),
      );
    });

    test('the outline and the modal-rung shadow match the redesign', () {
      expect(
        CoreMockupBrowserStyle.defaultBorderColor,
        const CoreColor.token(CoreColors.outlineVariant),
      );
      expect(CoreMockupBrowserStyle.defaultBoxShadow, [
        (
          offsetX: 0.0,
          offsetY: 24.0,
          blurRadius: 64.0,
          spreadRadius: 0.0,
          opacity: .125,
          inset: false,
        ),
      ]);
    });

    test('the window thickness and toolbar metrics', () {
      expect(CoreMockupBrowserStyle.defaultChromeWidth, CoreSpace.space0);
      expect(CoreMockupBrowserStyle.defaultToolbarHeight, CoreSpace.space44);
      expect(CoreMockupBrowserStyle.defaultToolbarSpacing, CoreSpace.space8);
      expect(
        CoreMockupBrowserStyle.defaultToolbarPadding,
        const CoreEdgeInsets.symmetric(horizontal: CoreSpace.space12),
      );
    });

    test('the window controls are 8px dots, 6px apart, fully round', () {
      expect(CoreMockupBrowserStyle.defaultControlSize, CoreSize.size8);
      expect(CoreMockupBrowserStyle.defaultControlSpacing, CoreSpace.space6);
      expect(
        CoreMockupBrowserStyle.defaultControlBorderRadius,
        const CoreBorderRadius.all(CoreRadius.radius9999),
      );
    });

    test('the controls use semantic status colours', () {
      expect(
        CoreMockupBrowserStyle.defaultControlCloseColor.token,
        CoreColors.error,
      );
      expect(
        CoreMockupBrowserStyle.defaultControlMinimizeColor.token,
        CoreColors.warning,
      );
      expect(
        CoreMockupBrowserStyle.defaultControlMaximizeColor.token,
        CoreColors.success,
      );
    });

    test('navigation and action glyphs are 12px, forward reads disabled', () {
      expect(CoreMockupBrowserStyle.defaultNavSpacing, CoreSpace.space8);
      expect(
        CoreMockupBrowserStyle.defaultNavIconStyle,
        const CoreIconStyle(
          size: CoreIconSize.size12,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
      expect(
        CoreMockupBrowserStyle.defaultNavDisabledIconStyle,
        const CoreIconStyle(
          size: CoreIconSize.size12,
          color: CoreColor.token(CoreColors.disabledContent),
        ),
      );
      expect(
        CoreMockupBrowserStyle.defaultActionIconStyle,
        const CoreIconStyle(
          size: CoreIconSize.size12,
          color: CoreColor.token(CoreColors.onSurfaceVariant),
        ),
      );
    });

    test('the address bar text is centred', () {
      expect(
        CoreMockupBrowserStyle.defaultAddressBarTextAlign,
        CoreTextAlign.center,
      );
    });

    test('the content card radius has no default — it is derived', () {
      // `borderRadius − chromeWidth` lives in the resolvers; a constant
      // here would decouple the card from the body it sits in.
      const style = CoreMockupBrowserStyle();
      expect(style.contentBorderRadius, isNull);
    });
  });

  group('CoreMockupBrowserStyle.merge', () {
    test('null other returns this', () {
      const base = CoreMockupBrowserStyle(chromeWidth: 4);
      expect(base.merge(null), same(base));
    });

    test('non-null fields in other override receiver', () {
      const base = CoreMockupBrowserStyle(chromeWidth: 4, controlSize: 10);
      const override = CoreMockupBrowserStyle(chromeWidth: 8);
      final merged = base.merge(override);
      expect(merged.chromeWidth, 8);
      expect(merged.controlSize, 10);
    });

    test('every new slot survives a round trip', () {
      const style = CoreMockupBrowserStyle(
        toolbarBackgroundColor: _kBg,
        toolbarBorderColor: _kBg,
        toolbarBorderWidth: 2,
        toolbarBlur: 12,
        capsuleBackgroundColor: _kBg,
        capsuleBorderRadius: _kRadius,
        capsulePadding: CoreEdgeInsets.all(4),
        capsuleHeight: 24,
        actionSpacing: 6,
        addressBarSpacing: 2,
        domainSpacing: 4,
        addressIconStyle: _kIcon,
        contentTextStyle: CoreTextStyle(fontSize: 18),
        highlightColor: _kBg,
        highlightWidth: 2,
        boxShadow: CoreShadow.sm,
        chromeWidth: 4,
        contentBackgroundColor: _kBg,
        contentBorderRadius: _kRadius,
        toolbarSpacing: 8,
        controlSize: 10,
        controlSpacing: 5,
        controlBorderRadius: _kRadius,
        controlCloseColor: _kBg,
        controlMinimizeColor: _kBg,
        controlMaximizeColor: _kBg,
        navSpacing: 2,
        navIconStyle: _kIcon,
        navDisabledIconStyle: _kIcon,
        actionIconStyle: _kIcon,
        addressBarTextAlign: .start,
      );
      final merged = const CoreMockupBrowserStyle().merge(style);
      expect(merged, style);
      expect(merged.hashCode, style.hashCode);
    });

    test('nested icon slots merge field-wise, not whole-slot', () {
      const base = CoreMockupBrowserStyle(navIconStyle: _kIcon);
      const override = CoreMockupBrowserStyle(
        navIconStyle: CoreIconStyle(color: _kIconColor),
      );
      final merged = base.merge(override);
      // A caller overriding only the colour keeps the base size.
      expect(
        merged.navIconStyle,
        const CoreIconStyle(size: 20, color: _kIconColor),
      );
    });
  });

  group('CoreMockupBrowserStyle.copyWith', () {
    test('overrides only the supplied fields', () {
      const base = CoreMockupBrowserStyle(chromeWidth: 4, toolbarSpacing: 8);
      final copy = base.copyWith(contentBackgroundColor: _kBg);
      expect(copy.chromeWidth, 4);
      expect(copy.toolbarSpacing, 8);
      expect(copy.contentBackgroundColor, _kBg);
    });
  });

  group('CoreMockupBrowserStyle equality', () {
    test('a structurally equal shadow stack compares equal', () {
      const a = CoreMockupBrowserStyle(
        boxShadow: [
          (
            offsetX: 0,
            offsetY: 2,
            blurRadius: 4,
            spreadRadius: 0,
            opacity: 0.1,
            inset: false,
          ),
        ],
      );
      const b = CoreMockupBrowserStyle(
        boxShadow: [
          (
            offsetX: 0,
            offsetY: 2,
            blurRadius: 4,
            spreadRadius: 0,
            opacity: 0.1,
            inset: false,
          ),
        ],
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
    });

    test('a different chromeWidth is not equal', () {
      const a = CoreMockupBrowserStyle(chromeWidth: 4);
      const b = CoreMockupBrowserStyle(chromeWidth: 6);
      expect(a, isNot(equals(b)));
    });
  });
}
