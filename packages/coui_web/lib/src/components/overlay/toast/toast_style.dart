import 'package:coui_web/src/base/style_type.dart';
import 'package:coui_web/src/base/styling.dart';
import 'package:coui_web/src/base/ui_prefix_modifier.dart';

/// Styling interface for Toast components.
abstract interface class ToastStyling implements Styling {}

/// Toast style class using Tailwind CSS.
class ToastStyle implements ToastStyling {
  const ToastStyle(
    this.cssClass, {
    this.modifiers,
    required this.type,
  });

  @override
  final String cssClass;

  @override
  final StyleType type;

  @override
  final List<PrefixModifier>? modifiers;

  @override
  String toString() {
    final currentModifiers = modifiers;
    if (currentModifiers == null || currentModifiers.isEmpty) {
      return cssClass;
    }
    final prefixesString = currentModifiers.map((m) => m.prefix).join();

    return '$prefixesString$cssClass';
  }
}

/// Toast variant style.
class ToastVariantStyle implements ToastStyling {
  const ToastVariantStyle({
    this.variant = ToastVariant.default_,
    this.additionalClasses,
  });

  /// Toast variant.
  final ToastVariant variant;

  /// Additional custom classes.
  final String? additionalClasses;

  @override
  String get cssClass {
    const baseClasses =
        'group pointer-events-auto relative flex w-full items-center justify-between space-x-4 overflow-hidden rounded-md border p-6 pr-8 shadow-lg transition-all';

    final variantClasses = switch (variant) {
      ToastVariant.default_ => 'border bg-background text-foreground',
      ToastVariant.destructive =>
        'destructive group border-destructive bg-destructive text-destructive-foreground',
    };

    return [
      baseClasses,
      variantClasses,
      additionalClasses,
    ].where((c) => c != null && c.isNotEmpty).join(' ');
  }

  @override
  StyleType get type => StyleType.layout;

  @override
  List<PrefixModifier>? get modifiers => null;

  @override
  String toString() => cssClass;
}

/// Toast variants.
enum ToastVariant {
  /// Default toast variant.
  default_,

  /// Destructive toast variant for errors.
  destructive,
}
