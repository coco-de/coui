// ignore_for_file: format-comment, no-magic-string
// TODO(dongwoo): Add remaining layout utilities
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';
// - gap
// - order

class Layout extends CommonStyle<Layout> {
  const Layout(super.cssClass, {super.modifiers})
    : super(type: StyleType.layout);

  // Base gap utilities - Control spacing in both directions
  Layout.gap(double value)
    : super('gap-${_formatValue(value)}', type: StyleType.layout);

  Layout.gapX(double value)
    : super('gap-x-${_formatValue(value)}', type: StyleType.layout);

  Layout.gapY(double value)
    : super('gap-y-${_formatValue(value)}', type: StyleType.layout);

  Layout.order(int value) : super('order-$value', type: StyleType.layout);

  Layout.orderNeg(int value) : super('-order-$value', type: StyleType.layout);

  /// `display: block`
  static const block = Layout('block');

  /// `display: inline-block`
  static const inlineBlock = Layout('inline-block');

  /// `display: inline`
  static const inline = Layout('inline');

  /// `display: flex`
  static const flex = Layout('flex');

  /// `display: inline-flex`
  static const inlineFlex = Layout('inline-flex');

  /// `display: table`
  static const table = Layout('table');

  /// `display: inline-table`
  static const inlineTable = Layout('inline-table');

  /// `display: table-caption`
  static const tableCaption = Layout('table-caption');

  /// `display: grid`
  static const grid = Layout('grid');

  /// `display: inline-grid`
  static const inlineGrid = Layout('inline-grid');

  /// `display: contents`
  static const contents = Layout('contents');

  /// `display: list-item`
  static const listItem = Layout('list-item');

  /// `display: hidden` (same as `hidden` in Tailwind,
  /// effectively `display: none`)
  static const hidden = Layout('hidden');

  // --- Flex Direction (from flex.dart, could be consolidated here
  // or kept separate) ---
  // Assuming Flex specific utilities (grow, shrink, basis) remain in flex.dart
  // but basic direction and wrap can be here for general layout.
  static const flexRow = Layout('flex-row');

  static const flexRowReverse = Layout('flex-row-reverse');

  static const flexCol = Layout('flex-col');

  static const flexColReverse = Layout('flex-col-reverse'); // --- Flex Wrap ---

  static const flexNoWrap = Layout('flex-nowrap');

  static const flexWrap = Layout('flex-wrap');
  static const flexWrapReverse = Layout(
    'flex-wrap-reverse',
  ); // Base gap utilities - Control spacing in both directions
  // These follow the standard 0.25rem (4px) scale pattern
  static const gap0 = Layout('gap-0'); // 0px

  static const gap1 = Layout('gap-1'); // 0.25rem (4px)

  static const gap2 = Layout('gap-2'); // 0.5rem (8px)

  static const gap3 = Layout('gap-3'); // 0.75rem (12px)

  static const gap4 = Layout('gap-4'); // 1rem (16px)

  static const gap5 = Layout('gap-5'); // 1.25rem (20px)

  static const gap6 = Layout('gap-6'); // 1.5rem (24px)

  static const gap8 = Layout('gap-8'); // 2rem (32px)

  static const gap10 = Layout('gap-10'); // 2.5rem (40px)
  static const gap12 = Layout('gap-12'); // 3rem (48px)
  static const gap14 = Layout('gap-14'); // 3.5rem (56px)
  static const gap16 = Layout('gap-16'); // 4rem (64px)
  static const gap20 = Layout('gap-20'); // 5rem (80px)
  static const gap24 = Layout('gap-24'); // 6rem (96px)
  static const gap28 = Layout('gap-28'); // 7rem (112px)
  static const gap32 = Layout('gap-32'); // 8rem (128px)
  static const gap36 = Layout('gap-36'); // 9rem (144px)
  static const gap40 = Layout('gap-40'); // 10rem (160px)
  static const gap44 = Layout('gap-44'); // 11rem (176px)
  static const gap48 = Layout('gap-48'); // 12rem (192px)
  static const gap52 = Layout('gap-52'); // 13rem (208px)
  static const gap56 = Layout('gap-56'); // 14rem (224px)
  static const gap60 = Layout('gap-60'); // 15rem (240px)
  static const gap64 = Layout('gap-64'); // 16rem (256px)
  static const gap72 = Layout('gap-72'); // 18rem (288px)
  static const gap80 = Layout('gap-80'); // 20rem (320px)
  static const gap96 = Layout('gap-96'); // 24rem (384px)
  // Horizontal gap utilities - Control spacing between columns
  // These follow the same scale but only affect horizontal spacing
  static const gapX0 = Layout('gap-x-0');

  static const gapX1 = Layout('gap-x-1');

  static const gapX2 = Layout('gap-x-2');

  static const gapX3 = Layout('gap-x-3');

  static const gapX4 = Layout('gap-x-4');
  static const gapX5 = Layout('gap-x-5');
  static const gapX6 = Layout('gap-x-6');
  static const gapX8 = Layout('gap-x-8');

  static const gapX10 = Layout('gap-x-10');
  static const gapX12 = Layout('gap-x-12');
  static const gapX14 = Layout('gap-x-14');
  static const gapX16 = Layout('gap-x-16');
  static const gapX20 = Layout('gap-x-20');
  static const gapX24 = Layout('gap-x-24');
  static const gapX28 = Layout('gap-x-28');
  static const gapX32 = Layout('gap-x-32');
  static const gapX36 = Layout('gap-x-36');
  static const gapX40 = Layout('gap-x-40');
  static const gapX44 = Layout('gap-x-44');
  static const gapX48 = Layout('gap-x-48');
  static const gapX52 = Layout('gap-x-52');
  static const gapX56 = Layout('gap-x-56');
  static const gapX60 = Layout('gap-x-60');
  static const gapX64 = Layout('gap-x-64');
  static const gapX72 = Layout('gap-x-72');
  static const gapX80 = Layout('gap-x-80');
  static const gapX96 = Layout(
    'gap-x-96',
  ); // Vertical gap utilities - Control spacing between rows
  // These follow the same scale but only affect vertical spacing
  static const gapY0 = Layout('gap-y-0');

  static const gapY1 = Layout('gap-y-1');

  static const gapY2 = Layout('gap-y-2');

  static const gapY3 = Layout('gap-y-3');

  static const gapY4 = Layout('gap-y-4');
  static const gapY5 = Layout('gap-y-5');
  static const gapY6 = Layout('gap-y-6');
  static const gapY8 = Layout('gap-y-8');

  static const gapY10 = Layout('gap-y-10');
  static const gapY12 = Layout('gap-y-12');
  static const gapY14 = Layout('gap-y-14');
  static const gapY16 = Layout('gap-y-16');
  static const gapY20 = Layout('gap-y-20');
  static const gapY24 = Layout('gap-y-24');
  static const gapY28 = Layout('gap-y-28');
  static const gapY32 = Layout('gap-y-32');
  static const gapY36 = Layout('gap-y-36');
  static const gapY40 = Layout('gap-y-40');
  static const gapY44 = Layout('gap-y-44');
  static const gapY48 = Layout('gap-y-48');
  static const gapY52 = Layout('gap-y-52');
  static const gapY56 = Layout('gap-y-56');
  static const gapY60 = Layout('gap-y-60');
  static const gapY64 = Layout('gap-y-64');
  static const gapY72 = Layout('gap-y-72');
  static const gapY80 = Layout('gap-y-80');
  static const gapY96 = Layout(
    'gap-y-96',
  ); // Order utilities for controlling the visual order of flex/grid items
  // Special order values that provide semantic meaning
  // --- Order ---
  // Order utilities for controlling the visual order of flex/grid items
  static const orderFirst = Layout('order-first');

  static const orderLast = Layout('order-last');

  // ... (add more specific order values if desired, e.g., order1, order2) ...
  static const orderNone = Layout('order-none');

  // Positive order values for standard ordering
  static const order1 = Layout('order-1');

  static const order2 = Layout('order-2');

  static const order3 = Layout('order-3');

  static const order4 = Layout('order-4');

  static const order5 = Layout('order-5');

  static const order6 = Layout('order-6');
  static const order7 = Layout('order-7');
  static const order8 = Layout('order-8');
  static const order9 = Layout('order-9');
  static const order10 = Layout('order-10');

  static const order11 = Layout('order-11');
  static const order12 = Layout(
    'order-12',
  ); // Negative order values for placing items before others
  static const orderNeg1 = Layout('-order-1');
  static const orderNeg2 = Layout('-order-2');
  static const orderNeg3 = Layout('-order-3');
  static const orderNeg4 = Layout('-order-4');
  static const orderNeg5 = Layout('-order-5');
  static const orderNeg6 = Layout('-order-6');
  static const orderNeg7 = Layout('-order-7');
  static const orderNeg8 = Layout('-order-8');
  static const orderNeg9 = Layout('-order-9');
  static const orderNeg10 = Layout('-order-10');

  static const orderNeg11 = Layout('-order-11');
  static const orderNeg12 = Layout('-order-12');

  @override
  Layout create(List<PrefixModifier> modifiers) {
    return Layout(cssClass, modifiers: modifiers);
  }

  static String _formatValue(double value) {
    return value == value.truncate()
        ? value.truncate().toString()
        : value.toString();
  }
}
