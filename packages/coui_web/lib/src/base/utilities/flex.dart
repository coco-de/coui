// ignore_for_file: format-comment
// TODO(dev): Implement flex utilities
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class Flex extends CommonStyle<Flex> {
  const Flex(super.cssClass, {super.modifiers}) : super(type: StyleType.layout);

  // Shrinks six times as fast

  // Standard flex values that control how flex items grow and shrink
  static const flex1 = Flex(
    'flex-1',
  ); // flex: 1 1 0% - Allows flex item to grow and shrink

  static const flex2 = Flex(
    'flex-2',
  ); // flex: 2 2 0% - Grows/shrinks twice as much as flex-1

  static const flex3 = Flex(
    'flex-3',
  ); // flex: 3 3 0% - Grows/shrinks three times as much as flex-1

  static const flex4 = Flex(
    'flex-4',
  ); // flex: 4 4 0% - Grows/shrinks four times as much as flex-1
  static const flex5 = Flex(
    'flex-5',
  ); // flex: 5 5 0% - Grows/shrinks five times as much as flex-1
  static const flex6 = Flex(
    'flex-6',
  ); // flex: 6 6 0% - Grows/shrinks six times as much as flex-1

  // Fractional flex values for more precise control
  static const flexHalf = Flex('flex-1/2'); // flex: 0.5 0.5 0%

  static const flexThird = Flex('flex-1/3'); // flex: 0.33333 0.33333 0%

  static const flexQuarter = Flex('flex-1/4'); // flex: 0.25 0.25 0%

  // Predefined flex behavior keywords
  static const flexAuto = Flex(
    'flex-auto',
  ); // flex: 1 1 auto - Grow and shrink, taking initial size into account

  static const flexInitial = Flex(
    'flex-initial',
  ); // flex: 0 1 auto - Only shrink if needed

  static const flexNone = Flex(
    'flex-none',
  ); // flex: none - Prevent growing or shrinking

  // Numeric flex-basis values following the 4px (0.25rem) scale
  static const basis0 = Flex(
    'basis-0',
  ); // 0px - Useful for collapsing initial size

  static const basis1 = Flex('basis-1'); // 0.25rem (4px)

  static const basis2 = Flex('basis-2'); // 0.5rem (8px)

  static const basis3 = Flex('basis-3'); // 0.75rem (12px)
  static const basis4 = Flex('basis-4'); // 1rem (16px)
  static const basis5 = Flex('basis-5'); // 1.25rem (20px)
  static const basis6 = Flex('basis-6'); // 1.5rem (24px)
  static const basis8 = Flex('basis-8'); // 2rem (32px)
  static const basis10 = Flex('basis-10'); // 2.5rem (40px)
  static const basis12 = Flex('basis-12'); // 3rem (48px)
  static const basis16 = Flex('basis-16'); // 4rem (64px)
  static const basis20 = Flex('basis-20'); // 5rem (80px)
  static const basis24 = Flex('basis-24'); // 6rem (96px)
  static const basis32 = Flex('basis-32'); // 8rem (128px)
  static const basis40 = Flex('basis-40'); // 10rem (160px)
  static const basis48 = Flex('basis-48'); // 12rem (192px)
  static const basis56 = Flex('basis-56'); // 14rem (224px)
  static const basis64 = Flex('basis-64'); // 16rem (256px)
  static const basis72 = Flex('basis-72'); // 18rem (288px)
  static const basis80 = Flex('basis-80'); // 20rem (320px)
  static const basis96 = Flex('basis-96'); // 24rem (384px)

  // Fractional flex-basis values for responsive layouts
  static const basis1_2 = Flex('basis-1/2'); // 50%

  static const basis1_3 = Flex('basis-1/3'); // 33.333333%

  static const basis2_3 = Flex('basis-2/3'); // 66.666667%

  static const basis1_4 = Flex('basis-1/4'); // 25%
  static const basis2_4 = Flex('basis-2/4'); // 50%
  static const basis3_4 = Flex('basis-3/4'); // 75%
  static const basis1_5 = Flex('basis-1/5'); // 20%
  static const basis2_5 = Flex('basis-2/5'); // 40%
  static const basis3_5 = Flex('basis-3/5'); // 60%
  static const basis4_5 = Flex('basis-4/5'); // 80%
  static const basis1_6 = Flex('basis-1/6'); // 16.666667%
  static const basis2_6 = Flex('basis-2/6'); // 33.333333%
  static const basis3_6 = Flex('basis-3/6'); // 50%
  static const basis4_6 = Flex('basis-4/6'); // 66.666667%
  static const basis5_6 = Flex('basis-5/6'); // 83.333333%

  // Ui container-based flex-basis sizes
  // These provide consistent sizing that aligns with the design system
  static const basis3xs = Flex('basis-3xs'); // 16rem (256px)

  static const basis2xs = Flex('basis-2xs'); // 18rem (288px)

  static const basisXs = Flex('basis-xs'); // 20rem (320px)

  static const basisSm = Flex('basis-sm'); // 24rem (384px)
  static const basisMd = Flex('basis-md'); // 28rem (448px)
  static const basisLg = Flex('basis-lg'); // 32rem (512px)
  static const basisXl = Flex('basis-xl'); // 36rem (576px)
  static const basis2xl = Flex('basis-2xl'); // 42rem (672px)
  static const basis3xl = Flex('basis-3xl'); // 48rem (768px)
  static const basis4xl = Flex('basis-4xl'); // 56rem (896px)
  static const basis5xl = Flex('basis-5xl'); // 64rem (1024px)
  static const basis6xl = Flex('basis-6xl'); // 72rem (1152px)
  static const basis7xl = Flex('basis-7xl'); // 80rem (1280px)

  // Special values for common use cases
  static const basisAuto = Flex('basis-auto'); // Use item's content size

  static const basisFull = Flex('basis-full'); // 100% of container

  // Flex Direction Utilities
  // These control the main axis of the flex container, determining
  // how flex items are placed within the container

  // Items flow left to right (default browser behavior)
  static const flexRow = Flex('flex-row');

  // Items flow right to left, reversing their order
  static const flexRowReverse = Flex('flex-row-reverse');

  // Items flow top to bottom, creating a vertical layout
  static const flexCol = Flex('flex-col');

  // Items flow bottom to top, reversing their vertical order
  static const flexColReverse = Flex('flex-col-reverse');

  // Flex Wrap Utilities
  // These determine whether and how flex items wrap when they
  // exceed the container's dimensions

  // Items remain on a single line, potentially overflowing
  static const flexNowrap = Flex('flex-nowrap');

  // Items wrap onto multiple lines when needed, from top to bottom
  static const flexWrap = Flex('flex-wrap');

  // Items wrap onto multiple lines when needed, from bottom to top
  static const flexWrapReverse = Flex('flex-wrap-reverse');

  // Flex Grow Utilities
  // These control how flex items expand to fill available space

  // Basic grow utility - enables growing with a factor of 1
  // This is equivalent to 'flex-grow: 1' and allows the item
  // to grow proportionally with other items
  static const grow = Flex('grow');

  // Numeric grow factors provide more precise control over growth ratios
  // Each number represents how much more the item should grow compared
  // to other items. For example, grow2 will grow twice as fast as grow1
  static const grow0 = Flex('grow-0'); // Prevents growing

  static const grow1 = Flex('grow-1'); // Standard growth rate

  static const grow2 = Flex('grow-2'); // Grows twice as fast

  static const grow3 = Flex('grow-3'); // Grows three times as fast
  static const grow4 = Flex('grow-4'); // Grows four times as fast
  static const grow5 = Flex('grow-5'); // Grows five times as fast
  static const grow6 = Flex('grow-6'); // Grows six times as fast

  // Flex Shrink Utilities
  // These control how flex items reduce their size when the container
  // becomes too small to fit all items at their natural size.

  // Basic shrink utility - enables shrinking with a factor of 1
  // This is equivalent to 'flex-shrink: 1' and allows the item
  // to shrink proportionally with other items when space is limited
  static const shrink = Flex('shrink');

  // Numeric shrink factors provide fine-grained control over how
  // quickly items shrink relative to each other. An item with
  // shrink-2 will give up space twice as fast as one with shrink-1
  static const shrink0 = Flex('shrink-0'); // Prevents shrinking entirely

  static const shrink1 = Flex('shrink-1'); // Standard shrink rate

  static const shrink2 = Flex('shrink-2'); // Shrinks twice as fast

  static const shrink3 = Flex('shrink-3'); // Shrinks three times as fast
  static const shrink4 = Flex('shrink-4'); // Shrinks four times as fast
  static const shrink5 = Flex('shrink-5'); // Shrinks five times as fast
  static const shrink6 = Flex('shrink-6');

  @override
  Flex create(List<PrefixModifier> modifiers) {
    return Flex(cssClass, modifiers: modifiers);
  }
}
