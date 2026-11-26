import 'package:coui_flutter/coui_flutter.dart';
import 'package:widgetbook/widgetbook.dart';

part 'category_breakdown.stories.g.dart';

/// Default preview width for the category breakdown.
const _kCategoryBreakdownWidth = 360.0;

/// Knob input for [CategoryBreakdown] stories.
class CategoryBreakdownInput {
  /// Creates a [CategoryBreakdownInput].
  const CategoryBreakdownInput({
    this.width = _kCategoryBreakdownWidth,
    this.variant = CoreCategoryBreakdownVariant.bar,
  });

  /// Horizontal size of the preview — narrow it to watch the donut legend
  /// wrap below the ring.
  final double width;

  /// Bars or donut.
  final CoreCategoryBreakdownVariant variant;
}

/// Navigation metadata for the CategoryBreakdown component.
const kComponentMeta = ComponentMeta(
  name: 'CategoryBreakdown',
  path: 'display',
);

/// Story metadata for [CategoryBreakdown].
const kMeta = Meta(
  CategoryBreakdown.new,
  argsType: CategoryBreakdownInput.new,
);

/// Default builder mapping [CategoryBreakdownInput] args to a
/// [CategoryBreakdown].
final CategoryBreakdownDefaults defaults = _Defaults(
  setup: (context, child, args) => SizedBox(
    width: args.width,
    child: child,
  ),
  builder: (context, args) => CategoryBreakdown(
    variant: args.variant,
    semanticLabel: '문의 유형별 분포',
    center: const Text('234건'),
    items: const [
      CoreCategoryBreakdownItem(label: '결제 문의', value: 128, valueLabel: '128건'),
      CoreCategoryBreakdownItem(label: '배송 문의', value: 61, valueLabel: '61건'),
      CoreCategoryBreakdownItem(
        label: '계정 · 로그인',
        value: 33,
        valueLabel: '33건',
      ),
      CoreCategoryBreakdownItem(label: '기타', value: 12, valueLabel: '12건'),
    ],
  ),
);

/// Inquiry types as horizontal bars.
final $Default = _Story();
