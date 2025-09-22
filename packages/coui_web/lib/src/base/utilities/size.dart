// Ignoring format-comment for consistent CSS utility documentation style
// ignore_for_file: format-comment, avoid-long-files, lines_longer_than_80_chars, no-magic-string, lines_longer_than_80_chars
// Größen und Dimensionen
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Utilities for setting the width of an element.
class Size extends CommonStyle<Size> {
  const Size(super.cssClass, {super.modifiers, StyleType? type})
    : super(type: type ?? StyleType.sizing);

  // Base gap utilities - Control spacing in both directions
  Size.w(double value)
    : super('$_widthPrefix${_formatValue(value)}', type: StyleType.sizing);

  Size.h(double value)
    : super('$_heightPrefix${_formatValue(value)}', type: StyleType.sizing);

  Size.square(double value)
    : super(
        '$_widthPrefix${_formatValue(value)} $_heightPrefix${_formatValue(value)}',
        type: StyleType.sizing,
      );

  // Smallest viewport width

  // Container-based widths (follow Ui's container scale for
  // consistent layout widths)
  static const w3xs = Size(
    'w-3xs',
  ); // 16rem (256px)  - Smallest container width

  static const w2xs = Size(
    'w-2xs',
  ); // 18rem (288px)  - Very small container

  static const wxs = Size('w-xs'); // 20rem (320px)  - Extra small container

  static const wsm = Size('w-sm'); // 24rem (384px)  - Small container
  static const wmd = Size('w-md'); // 28rem (448px)  - Medium container
  static const wlg = Size('w-lg'); // 32rem (512px)  - Large container
  static const wxl = Size('w-xl'); // 36rem (576px)  - Extra large container
  static const w2xl = Size(
    'w-2xl',
  ); // 42rem (672px)  - 2x extra large container
  static const w3xl = Size(
    'w-3xl',
  ); // 48rem (768px)  - 3x extra large container
  static const w4xl = Size(
    'w-4xl',
  ); // 56rem (896px)  - 4x extra large container
  static const w5xl = Size(
    'w-5xl',
  ); // 64rem (1024px) - 5x extra large container
  static const w6xl = Size(
    'w-6xl',
  ); // 72rem (1152px) - 6x extra large container
  static const w7xl = Size(
    'w-7xl',
  ); // 80rem (1280px) - 7x extra large container

  // Fixed widths following a 4px (0.25rem) scale
  static const w0 = Size('w-0'); // 0px

  static const w1 = Size('w-1'); // 4px (0.25rem)

  static const w2 = Size('w-2'); // 8px (0.5rem)

  static const w3 = Size('w-3'); // 12px (0.75rem)

  static const w4 = Size('w-4'); // 16px (1rem)

  static const w5 = Size('w-5'); // 20px (1.25rem)
  static const w6 = Size('w-6'); // 24px (1.5rem)
  static const w8 = Size('w-8'); // 32px (2rem)
  static const w10 = Size('w-10'); // 40px (2.5rem)
  static const w12 = Size('w-12'); // 48px (3rem)
  static const w16 = Size('w-16'); // 64px (4rem)
  static const w20 = Size('w-20'); // 80px (5rem)
  static const w24 = Size('w-24'); // 96px (6rem)
  static const w32 = Size('w-32'); // 128px (8rem)
  static const w40 = Size('w-40'); // 160px (10rem)
  static const w48 = Size('w-48'); // 192px (12rem)
  static const w56 = Size('w-56'); // 224px (14rem)
  static const w64 = Size('w-64'); // 256px (16rem)
  static const w72 = Size('w-72'); // 288px (18rem)
  static const w80 = Size('w-80'); // 320px (20rem)
  static const w96 = Size('w-96'); // 384px (24rem)

  // Fractional widths
  static const w1_2 = Size('w-1/2'); // 50%

  static const w1_3 = Size('w-1/3'); // 33.333333%

  static const w2_3 = Size('w-2/3'); // 66.666667%

  static const w1_4 = Size('w-1/4'); // 25%

  static const w2_4 = Size('w-2/4'); // 50%

  static const w3_4 = Size('w-3/4'); // 75%
  static const w1_5 = Size('w-1/5'); // 20%
  static const w2_5 = Size('w-2/5'); // 40%
  static const w3_5 = Size('w-3/5'); // 60%
  static const w4_5 = Size('w-4/5'); // 80%
  static const w1_6 = Size('w-1/6'); // 16.666667%
  static const w2_6 = Size('w-2/6'); // 33.333333%
  static const w3_6 = Size('w-3/6'); // 50%
  static const w4_6 = Size('w-4/6'); // 66.666667%
  static const w5_6 = Size('w-5/6'); // 83.333333%
  static const w1_12 = Size('w-1/12'); // 8.333333%
  static const w2_12 = Size('w-2/12'); // 16.666667%
  static const w3_12 = Size('w-3/12'); // 25%
  static const w4_12 = Size('w-4/12'); // 33.333333%
  static const w5_12 = Size('w-5/12'); // 41.666667%
  static const w6_12 = Size('w-6/12'); // 50%
  static const w7_12 = Size('w-7/12'); // 58.333333%
  static const w8_12 = Size('w-8/12'); // 66.666667%
  static const w9_12 = Size('w-9/12'); // 75%
  static const w10_12 = Size('w-10/12'); // 83.333333%
  static const w11_12 = Size('w-11/12'); // 91.666667%

  // Special width values
  static const wAuto = Size('w-auto'); // auto

  static const wFull = Size('w-full'); // 100%

  static const wScreen = Size('w-screen'); // 100vw

  static const wMin = Size('w-min'); // min-content

  static const wMax = Size('w-max'); // max-content

  static const wFit = Size('w-fit'); // fit-content

  // Dynamic viewport units
  // These respond to viewport changes including dynamic UI elements
  // like address bars
  static const wDvw = Size('w-dvw'); // 100% of the dynamic viewport width

  static const wDvh = Size('w-dvh'); // 100% of the dynamic viewport height

  // Large viewport units
  // These use the largest possible viewport size, ignoring dynamic UI elements
  static const wLvw = Size('w-lvw'); // 100% of the largest viewport width

  static const wLvh = Size('w-lvh'); // 100% of the largest viewport height

  // Small viewport units
  // These use the smallest possible viewport size, accounting for
  // all UI elements
  static const wSvw = Size('w-svw'); // 100% of the smallest viewport width

  static const wSvh = Size('w-svh'); // 100% of the smallest viewport height

  // Fixed minimum widths following the standard 4px (0.25rem) scale
  // These are useful for ensuring elements maintain a minimal size
  // while still being able to grow
  static const minW0 = Size(
    'min-w-0',
  ); // 0px - Useful for overriding defaults

  static const minW1 = Size('min-w-1'); // 4px (0.25rem)

  static const minW2 = Size('min-w-2'); // 8px (0.5rem)

  static const minW3 = Size('min-w-3'); // 12px (0.75rem)

  static const minW4 = Size('min-w-4'); // 16px (1rem)

  static const minW5 = Size('min-w-5'); // 20px (1.25rem)
  static const minW6 = Size('min-w-6'); // 24px (1.5rem)
  static const minW8 = Size('min-w-8'); // 32px (2rem)
  static const minW10 = Size('min-w-10'); // 40px (2.5rem)
  static const minW12 = Size('min-w-12'); // 48px (3rem)
  static const minW16 = Size('min-w-16'); // 64px (4rem)
  static const minW20 = Size('min-w-20'); // 80px (5rem)
  static const minW24 = Size('min-w-24'); // 96px (6rem)
  static const minW32 = Size('min-w-32'); // 128px (8rem)
  static const minW40 = Size('min-w-40'); // 160px (10rem)
  static const minW48 = Size('min-w-48'); // 192px (12rem)
  static const minW56 = Size('min-w-56'); // 224px (14rem)
  static const minW64 = Size('min-w-64'); // 256px (16rem)
  static const minW72 = Size('min-w-72'); // 288px (18rem)
  static const minW80 = Size('min-w-80'); // 320px (20rem)
  static const minW96 = Size('min-w-96'); // 384px (24rem)

  // Ui container-based minimum widths
  // These follow the container scale and are useful for responsive layouts
  static const minW3xs = Size('min-w-3xs'); // 16rem (256px)

  static const minW2xs = Size('min-w-2xs'); // 18rem (288px)

  static const minWxs = Size('min-w-xs'); // 20rem (320px)

  static const minWsm = Size('min-w-sm'); // 24rem (384px)

  static const minWmd = Size('min-w-md'); // 28rem (448px)

  static const minWlg = Size('min-w-lg'); // 32rem (512px)
  static const minWxl = Size('min-w-xl'); // 36rem (576px)
  static const minW2xl = Size('min-w-2xl'); // 42rem (672px)
  static const minW3xl = Size('min-w-3xl'); // 48rem (768px)
  static const minW4xl = Size('min-w-4xl'); // 56rem (896px)
  static const minW5xl = Size('min-w-5xl'); // 64rem (1024px)
  static const minW6xl = Size('min-w-6xl'); // 72rem (1152px)
  static const minW7xl = Size('min-w-7xl'); // 80rem (1280px)

  // Special minimum width values
  // These provide different ways to handle content and viewport-based minimums
  static const minWFull = Size('min-w-full'); // 100% of parent width

  static const minWMin = Size('min-w-min'); // min-content

  static const minWMax = Size('min-w-max'); // max-content

  static const minWFit = Size('min-w-fit'); // fit-content

  // Viewport-based minimum widths
  static const minWScreen = Size('min-w-screen'); // 100vw

  static const minWDvw = Size('min-w-dvw'); // 100dvw

  static const minWLvw = Size('min-w-lvw'); // 100lvw

  static const minWSvw = Size('min-w-svw'); // 100svw

  // Fixed maximum widths following the standard 4px (0.25rem) scale
  // These provide precise control over maximum element sizes
  static const maxW0 = Size(
    'max-w-0',
  ); // 0px - Useful for collapsing elements

  static const maxW1 = Size('max-w-1'); // 4px (0.25rem)

  static const maxW2 = Size('max-w-2'); // 8px (0.5rem)

  static const maxW3 = Size('max-w-3'); // 12px (0.75rem)

  static const maxW4 = Size('max-w-4'); // 16px (1rem)

  static const maxW5 = Size('max-w-5'); // 20px (1.25rem)
  static const maxW6 = Size('max-w-6'); // 24px (1.5rem)
  static const maxW8 = Size('max-w-8'); // 32px (2rem)
  static const maxW10 = Size('max-w-10'); // 40px (2.5rem)
  static const maxW12 = Size('max-w-12'); // 48px (3rem)
  static const maxW16 = Size('max-w-16'); // 64px (4rem)
  static const maxW20 = Size('max-w-20'); // 80px (5rem)
  static const maxW24 = Size('max-w-24'); // 96px (6rem)
  static const maxW32 = Size('max-w-32'); // 128px (8rem)
  static const maxW40 = Size('max-w-40'); // 160px (10rem)
  static const maxW48 = Size('max-w-48'); // 192px (12rem)
  static const maxW56 = Size('max-w-56'); // 224px (14rem)
  static const maxW64 = Size('max-w-64'); // 256px (16rem)
  static const maxW72 = Size('max-w-72'); // 288px (18rem)
  static const maxW80 = Size('max-w-80'); // 320px (20rem)
  static const maxW96 = Size('max-w-96'); // 384px (24rem)

  // Ui container-based maximum widths
  // These provide consistent maximum widths that align with the design system
  static const maxW3xs = Size('max-w-3xs'); // 16rem (256px)

  static const maxW2xs = Size('max-w-2xs'); // 18rem (288px)

  static const maxWxs = Size('max-w-xs'); // 20rem (320px)

  static const maxWsm = Size('max-w-sm'); // 24rem (384px)

  static const maxWmd = Size('max-w-md'); // 28rem (448px)

  static const maxWlg = Size('max-w-lg'); // 32rem (512px)
  static const maxWxl = Size('max-w-xl'); // 36rem (576px)
  static const maxW2xl = Size('max-w-2xl'); // 42rem (672px)
  static const maxW3xl = Size('max-w-3xl'); // 48rem (768px)
  static const maxW4xl = Size('max-w-4xl'); // 56rem (896px)
  static const maxW5xl = Size('max-w-5xl'); // 64rem (1024px)
  static const maxW6xl = Size('max-w-6xl'); // 72rem (1152px)
  static const maxW7xl = Size('max-w-7xl'); // 80rem (1280px)

  // Special maximum width values
  // These handle various content and viewport-based maximums
  static const maxWFull = Size('max-w-full'); // 100% of parent width

  static const maxWMin = Size('max-w-min'); // min-content

  static const maxWMax = Size('max-w-max'); // max-content

  static const maxWFit = Size('max-w-fit'); // fit-content

  static const maxWProse = Size('max-w-prose'); // 65 characters (approx)

  static const maxWNone = Size('max-w-none'); // No maximum width

  // Viewport-based maximum widths
  static const maxWScreen = Size('max-w-screen'); // 100vw

  static const maxWDvw = Size('max-w-dvw'); // 100dvw

  static const maxWLvw = Size('max-w-lvw'); // 100lvw

  static const maxWSvw = Size('max-w-svw'); // 100svw

  // Additional viewport-specific heights for Ui containers
  static const h3xs = Size('h-3xs'); // 16rem (256px)

  static const h2xs = Size('h-2xs'); // 18rem (288px)

  static const hxs = Size('h-xs'); // 20rem (320px)

  static const hsm = Size('h-sm'); // 24rem (384px)

  static const hmd = Size('h-md'); // 28rem (448px)

  static const hlg = Size('h-lg'); // 32rem (512px)
  static const hxl = Size('h-xl'); // 36rem (576px)
  static const h2xl = Size('h-2xl'); // 42rem (672px)
  static const h3xl = Size('h-3xl'); // 48rem (768px)
  static const h4xl = Size('h-4xl'); // 56rem (896px)
  static const h5xl = Size('h-5xl'); // 64rem (1024px)
  static const h6xl = Size('h-6xl'); // 72rem (1152px)
  static const h7xl = Size('h-7xl'); // 80rem (1280px)

  // Fixed heights following the standard 4px (0.25rem) scale
  // These provide precise control for smaller UI elements
  static const h0 = Size('h-0'); // 0px - Useful for collapsing elements

  static const h1 = Size('h-1'); // 4px (0.25rem)

  static const h2 = Size('h-2'); // 8px (0.5rem)

  static const h3 = Size('h-3'); // 12px (0.75rem)

  static const h4 = Size('h-4'); // 16px (1rem) - Common line height

  static const h5 = Size('h-5'); // 20px (1.25rem)
  static const h6 = Size('h-6'); // 24px (1.5rem)
  static const h8 = Size('h-8'); // 32px (2rem)
  static const h10 = Size('h-10'); // 40px (2.5rem)
  static const h12 = Size('h-12'); // 48px (3rem)
  static const h16 = Size('h-16'); // 64px (4rem)
  static const h20 = Size('h-20'); // 80px (5rem)
  static const h24 = Size('h-24'); // 96px (6rem)
  static const h32 = Size('h-32'); // 128px (8rem)
  static const h40 = Size('h-40'); // 160px (10rem)
  static const h48 = Size('h-48'); // 192px (12rem)
  static const h56 = Size('h-56'); // 224px (14rem)
  static const h64 = Size('h-64'); // 256px (16rem)
  static const h72 = Size('h-72'); // 288px (18rem)
  static const h80 = Size('h-80'); // 320px (20rem)
  static const h96 = Size('h-96'); // 384px (24rem)

  // Fractional heights
  // These are particularly useful for responsive layouts and vertical splits
  static const h1_2 = Size('h-1/2'); // 50%

  static const h1_3 = Size('h-1/3'); // 33.333333%

  static const h2_3 = Size('h-2/3'); // 66.666667%

  static const h1_4 = Size('h-1/4'); // 25%

  static const h2_4 = Size('h-2/4'); // 50%

  static const h3_4 = Size('h-3/4'); // 75%
  static const h1_5 = Size('h-1/5'); // 20%
  static const h2_5 = Size('h-2/5'); // 40%
  static const h3_5 = Size('h-3/5'); // 60%
  static const h4_5 = Size('h-4/5'); // 80%
  static const h1_6 = Size('h-1/6'); // 16.666667%
  static const h2_6 = Size('h-2/6'); // 33.333333%
  static const h3_6 = Size('h-3/6'); // 50%
  static const h4_6 = Size('h-4/6'); // 66.666667%
  static const h5_6 = Size('h-5/6'); // 83.333333%

  // Special height values
  // These provide different ways to handle viewport and content-based heights
  static const hAuto = Size('h-auto'); // Let the browser determine height

  static const hFull = Size('h-full'); // 100% of parent's height

  static const hScreen = Size('h-screen'); // 100vh - Full viewport height

  static const hMin = Size('h-min'); // Fit content, minimum height

  static const hMax = Size('h-max'); // Fit content, maximum height

  static const hFit = Size('h-fit'); // Fit content

  // Modern viewport height units
  // These provide better control over viewport heights, especially on mobile
  static const hDvh = Size('h-dvh'); // Dynamic viewport height

  static const hLvh = Size('h-lvh'); // Largest viewport height

  static const hSvh = Size('h-svh'); // Smallest viewport height

  static const hDvw = Size('h-dvw'); // Dynamic viewport width as height

  static const hLvw = Size('h-lvw'); // Largest viewport width as height

  static const hSvw = Size('h-svw'); // Smallest viewport width as height

  // Fixed minimum heights using the standard spacing scale
  // These ensure elements maintain at least a certain height
  // while allowing for expansion
  static const minH0 = Size('min-h-0'); // 0px - Removes any minimum height

  static const minH1 = Size('min-h-1'); // 4px (0.25rem)

  static const minH2 = Size('min-h-2'); // 8px (0.5rem)

  static const minH3 = Size('min-h-3'); // 12px (0.75rem)

  static const minH4 = Size('min-h-4'); // 16px (1rem)

  static const minH5 = Size('min-h-5'); // 20px (1.25rem)
  static const minH6 = Size('min-h-6'); // 24px (1.5rem)
  static const minH8 = Size('min-h-8'); // 32px (2rem)
  static const minH10 = Size('min-h-10'); // 40px (2.5rem)
  static const minH12 = Size('min-h-12'); // 48px (3rem)
  static const minH16 = Size('min-h-16'); // 64px (4rem)
  static const minH20 = Size('min-h-20'); // 80px (5rem)
  static const minH24 = Size('min-h-24'); // 96px (6rem)
  static const minH32 = Size('min-h-32'); // 128px (8rem)
  static const minH40 = Size('min-h-40'); // 160px (10rem)
  static const minH48 = Size('min-h-48'); // 192px (12rem)
  static const minH56 = Size('min-h-56'); // 224px (14rem)
  static const minH64 = Size('min-h-64'); // 256px (16rem)
  static const minH72 = Size('min-h-72'); // 288px (18rem)
  static const minH80 = Size('min-h-80'); // 320px (20rem)
  static const minH96 = Size('min-h-96'); // 384px (24rem)

  // Ui container-based minimum heights
  // These match the container scale for consistent vertical spacing
  static const minH3xs = Size('min-h-3xs'); // 16rem (256px)

  static const minH2xs = Size('min-h-2xs'); // 18rem (288px)

  static const minHxs = Size('min-h-xs'); // 20rem (320px)

  static const minHsm = Size('min-h-sm'); // 24rem (384px)

  static const minHmd = Size('min-h-md'); // 28rem (448px)

  static const minHlg = Size('min-h-lg'); // 32rem (512px)
  static const minHxl = Size('min-h-xl'); // 36rem (576px)
  static const minH2xl = Size('min-h-2xl'); // 42rem (672px)
  static const minH3xl = Size('min-h-3xl'); // 48rem (768px)
  static const minH4xl = Size('min-h-4xl'); // 56rem (896px)
  static const minH5xl = Size('min-h-5xl'); // 64rem (1024px)
  static const minH6xl = Size('min-h-6xl'); // 72rem (1152px)
  static const minH7xl = Size('min-h-7xl'); // 80rem (1280px)

  // Special minimum height values
  // These handle various content and viewport-based minimums
  static const minHFull = Size('min-h-full'); // 100% of parent height

  static const minHScreen = Size(
    'min-h-screen',
  ); // 100vh - Traditional viewport height

  static const minHMin = Size('min-h-min'); // min-content

  static const minHMax = Size('min-h-max'); // max-content

  static const minHFit = Size('min-h-fit'); // fit-content

  // Modern viewport-based minimum heights
  // These provide better control over viewport heights on mobile devices
  static const minHDvh = Size('min-h-dvh'); // Dynamic viewport height

  static const minHLvh = Size('min-h-lvh'); // Largest viewport height

  static const minHSvh = Size('min-h-svh'); // Smallest viewport height

  // Viewport width as minimum height
  // Useful for maintaining aspect ratios
  static const minHDvw = Size('min-h-dvw'); // Dynamic viewport width

  static const minHLvw = Size('min-h-lvw'); // Largest viewport width

  static const minHSvw = Size('min-h-svw'); // Smallest viewport width

  // Fixed maximum heights using the standard spacing scale
  // These utilities help constrain elements to specific maximum heights
  // while still allowing them to be smaller if their content
  // requires less space
  static const maxH0 = Size(
    'max-h-0',
  ); // 0px - Completely collapses the element

  static const maxH1 = Size('max-h-1'); // 4px (0.25rem)

  static const maxH2 = Size('max-h-2'); // 8px (0.5rem)

  static const maxH3 = Size('max-h-3'); // 12px (0.75rem)

  static const maxH4 = Size('max-h-4'); // 16px (1rem)

  static const maxH5 = Size('max-h-5'); // 20px (1.25rem)
  static const maxH6 = Size('max-h-6'); // 24px (1.5rem)
  static const maxH8 = Size('max-h-8'); // 32px (2rem)
  static const maxH10 = Size('max-h-10'); // 40px (2.5rem)
  static const maxH12 = Size('max-h-12'); // 48px (3rem)
  static const maxH16 = Size('max-h-16'); // 64px (4rem)
  static const maxH20 = Size('max-h-20'); // 80px (5rem)
  static const maxH24 = Size('max-h-24'); // 96px (6rem)
  static const maxH32 = Size('max-h-32'); // 128px (8rem)
  static const maxH40 = Size('max-h-40'); // 160px (10rem)
  static const maxH48 = Size('max-h-48'); // 192px (12rem)
  static const maxH56 = Size('max-h-56'); // 224px (14rem)
  static const maxH64 = Size('max-h-64'); // 256px (16rem)
  static const maxH72 = Size('max-h-72'); // 288px (18rem)
  static const maxH80 = Size('max-h-80'); // 320px (20rem)
  static const maxH96 = Size('max-h-96'); // 384px (24rem)

  // Ui container-based maximum heights
  // These match the container scale for consistent vertical constraints
  // across your application's components
  static const maxH3xs = Size('max-h-3xs'); // 16rem (256px)

  static const maxH2xs = Size('max-h-2xs'); // 18rem (288px)

  static const maxHxs = Size('max-h-xs'); // 20rem (320px)

  static const maxHsm = Size('max-h-sm'); // 24rem (384px)

  static const maxHmd = Size('max-h-md'); // 28rem (448px)

  static const maxHlg = Size('max-h-lg'); // 32rem (512px)
  static const maxHxl = Size('max-h-xl'); // 36rem (576px)
  static const maxH2xl = Size('max-h-2xl'); // 42rem (672px)
  static const maxH3xl = Size('max-h-3xl'); // 48rem (768px)
  static const maxH4xl = Size('max-h-4xl'); // 56rem (896px)
  static const maxH5xl = Size('max-h-5xl'); // 64rem (1024px)
  static const maxH6xl = Size('max-h-6xl'); // 72rem (1152px)
  static const maxH7xl = Size('max-h-7xl'); // 80rem (1280px)

  // Special maximum height values
  // These provide different ways to handle content and viewport-based maximums,
  // giving you flexibility in how your elements respond to their content
  static const maxHFull = Size('max-h-full'); // 100% of parent height

  static const maxHScreen = Size(
    'max-h-screen',
  ); // 100vh - Traditional viewport height

  static const maxHMin = Size('max-h-min'); // min-content

  static const maxHMax = Size('max-h-max'); // max-content

  static const maxHFit = Size('max-h-fit'); // fit-content

  static const maxHNone = Size(
    'max-h-none',
  ); // No maximum height constraint

  // Modern viewport-based maximum heights
  // These new viewport units provide better control over sizing,
  // especially on mobile devices where browser UI can affect the viewport
  static const maxHDvh = Size('max-h-dvh'); // Dynamic viewport height

  static const maxHLvh = Size('max-h-lvh'); // Largest viewport height

  static const maxHSvh = Size('max-h-svh'); // Smallest viewport height

  // Viewport width as maximum height
  // These can be useful for maintaining aspect ratios
  // or creating height constraints based on viewport width
  static const maxHDvw = Size('max-h-dvw'); // Dynamic viewport width

  static const maxHLvw = Size('max-h-lvw'); // Largest viewport width

  static const maxHSvw = Size('max-h-svw');

  static const _widthPrefix = 'w-';
  static const _heightPrefix = 'h-';

  @override
  Size create(List<PrefixModifier> modifiers) {
    return Size(cssClass, modifiers: modifiers);
  }

  static String _formatValue(double value) {
    return value == value.truncate()
        ? value.truncate().toString()
        : value.toString();
  }
}
