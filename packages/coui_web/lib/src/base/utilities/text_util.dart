// ignore_for_file: format-comment
import 'package:coui_web/src/base/common_style.dart';
import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

class TextUtil extends CommonStyle<TextUtil> {
  const TextUtil(super.cssClass, {super.modifiers})
    : super(type: StyleType.typography);
  // --- Font Size ---
  // https://tailwindcss.com/docs/font-size
  static const xs = TextUtil('text-xs');

  static const sm = TextUtil('text-sm');

  static const base = TextUtil('text-base');
  static const lg = TextUtil('text-lg');
  static const xl = TextUtil('text-xl');
  static const xl2 = TextUtil('text-2xl');
  static const xl3 = TextUtil('text-3xl');
  static const xl4 = TextUtil('text-4xl');
  static const xl5 = TextUtil('text-5xl');
  static const xl6 = TextUtil('text-6xl');
  static const xl7 = TextUtil('text-7xl');
  static const xl8 = TextUtil('text-8xl');

  static const xl9 = TextUtil('text-9xl'); // --- Font Weight ---

  // Todo move to FontUtil
  // https://tailwindcss.com/docs/font-weight
  static const thin = TextUtil('font-thin'); // 100

  static const extralight = TextUtil('font-extralight'); // 200

  static const light = TextUtil('font-light'); // 300

  static const normal = TextUtil('font-normal'); // 400 (Default)
  static const medium = TextUtil('font-medium'); // 500
  static const semibold = TextUtil('font-semibold'); // 600
  static const bold = TextUtil('font-bold'); // 700
  static const extrabold = TextUtil('font-extrabold'); // 800

  static const black = TextUtil('font-black'); // 900

  // --- Text Alignment ---
  // https://tailwindcss.com/docs/text-align
  static const left = TextUtil('text-left');

  static const center = TextUtil('text-center');

  static const right = TextUtil('text-right');
  static const justify = TextUtil('text-justify'); // Respects LTR/RTL
  static const start = TextUtil('text-start'); // Respects LTR/RTL
  static const end = TextUtil('text-end'); // --- Text Decoration ---

  /// `text-decoration-line: underline`
  static const underline = TextUtil('underline');

  /// `text-decoration-line: overline`
  static const overline = TextUtil('overline');

  /// `text-decoration-line: line-through`
  static const lineThrough = TextUtil('line-through');

  /// `text-decoration-line: none`
  static const noUnderline = TextUtil(
    'no-underline',
  ); // Effectively text-decoration: none

  // --- Text Transform ---
  /// `text-transform: uppercase`
  static const uppercase = TextUtil('uppercase');

  /// `text-transform: lowercase`
  static const lowercase = TextUtil('lowercase');

  /// `text-transform: capitalize`
  static const capitalize = TextUtil('capitalize');

  /// `text-transform: none`
  static const normalCase = TextUtil('normal-case');

  // Aliases for common text colors
  static const primary = TextUtil('text-primary');

  static const primaryContent = TextUtil('text-primary-content');

  static const secondary = TextUtil('text-secondary');
  static const secondaryContent = TextUtil('text-secondary-content');
  static const accent = TextUtil('text-accent');
  static const accentContent = TextUtil('text-accent-content');
  static const neutral = TextUtil('text-neutral');
  static const neutralContent = TextUtil('text-neutral-content');
  static const base100 = TextUtil('text-base-100');
  static const base200 = TextUtil('text-base-200');
  static const base300 = TextUtil('text-base-300');
  static const baseContent = TextUtil('text-base-content');
  static const info = TextUtil('text-info');
  static const infoContent = TextUtil('text-info-content');
  static const success = TextUtil('text-success');
  static const successContent = TextUtil('text-success-content');
  static const warning = TextUtil('text-warning');
  static const warningContent = TextUtil('text-warning-content');
  static const error = TextUtil('text-error');
  static const errorContent = TextUtil('text-error-content');

  // TODO: Add utilities for text opacity, font smoothing, font style (italic), font variant numeric,
  // letter spacing, line height, list style type/position, text decoration color/style/thickness,
  // text underline offset, text overflow, text indent, vertical align, whitespace, word break, hyphens, content.

  @override
  TextUtil create(List<PrefixModifier> modifiers) {
    // Create a new instance with the original cssClass and new modifiers
    return TextUtil(cssClass, modifiers: modifiers);
  }
}
