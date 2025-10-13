/// Variant system for shadcn-ui style component variants.
///
/// This provides a type-safe way to define and combine Tailwind CSS classes
/// for different component variants following the shadcn-ui pattern.

/// Base class for component variant configurations.
///
/// Variants define different visual styles for a component (e.g., primary,
/// secondary, outline) and are composed of Tailwind CSS utility classes.
abstract class ComponentVariant {
  const ComponentVariant();

  /// Returns the combined Tailwind CSS classes for this variant.
  String get classes;

  /// Merges this variant with additional classes.
  String mergeWith(String? additionalClasses) {
    return additionalClasses == null || additionalClasses.isEmpty
        ? classes
        : '$classes $additionalClasses';
  }
}

/// Button variants following shadcn-ui button patterns.
class ButtonVariant extends ComponentVariant {
  const ButtonVariant(this.classes);

  @override
  final String classes;

  /// Default button variant with transparent background.
  static const defaultVariant = ButtonVariant(
    'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
  );

  /// Primary button variant.
  static const primary = ButtonVariant(
    'bg-primary text-primary-foreground hover:bg-primary/90',
  );

  /// Destructive button variant for dangerous actions.
  static const destructive = ButtonVariant(
    'bg-destructive text-destructive-foreground hover:bg-destructive/90',
  );

  /// Outline button variant with border.
  static const outline = ButtonVariant(
    'border border-input bg-background hover:bg-accent hover:text-accent-foreground',
  );

  /// Secondary button variant with subtle styling.
  static const secondary = ButtonVariant(
    'bg-secondary text-secondary-foreground hover:bg-secondary/80',
  );

  /// Ghost button variant with transparent background.
  static const ghost = ButtonVariant(
    'hover:bg-accent hover:text-accent-foreground',
  );

  /// Link button variant styled as hyperlink.
  static const link = ButtonVariant(
    'text-primary underline-offset-4 hover:underline',
  );
}

/// Button size variants.
class ButtonSize extends ComponentVariant {
  const ButtonSize(this.classes);

  @override
  final String classes;

  /// Default medium size.
  static const md = ButtonSize('h-10 px-4 py-2');

  /// Small size.
  static const sm = ButtonSize('h-9 rounded-md px-3');

  /// Large size.
  static const lg = ButtonSize('h-11 rounded-md px-8');

  /// Extra small size.
  static const xs = ButtonSize('h-8 rounded-md px-2 text-xs');

  /// Extra large size.
  static const xl = ButtonSize('h-12 rounded-md px-10 text-lg');

  /// Icon button size.
  static const icon = ButtonSize('h-10 w-10');
}

/// Input variants following shadcn-ui input patterns.
class InputVariant extends ComponentVariant {
  const InputVariant(this.classes);

  @override
  final String classes;

  /// Default input variant.
  static const defaultVariant = InputVariant(
    'flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50',
  );

  /// Input with error state.
  static const error = InputVariant(
    'flex h-10 w-full rounded-md border border-destructive bg-background px-3 py-2 text-sm ring-offset-background focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-destructive placeholder:text-muted-foreground disabled:cursor-not-allowed disabled:opacity-50',
  );
}

/// Card variants.
class CardVariant extends ComponentVariant {
  const CardVariant(this.classes);

  @override
  final String classes;

  /// Default card variant.
  static const defaultVariant = CardVariant(
    'rounded-lg border bg-card text-card-foreground shadow-sm',
  );

  /// Card with hover effect.
  static const hoverable = CardVariant(
    'rounded-lg border bg-card text-card-foreground shadow-sm hover:shadow-md transition-shadow',
  );
}

/// Badge variants.
class BadgeVariant extends ComponentVariant {
  const BadgeVariant(this.classes);

  @override
  final String classes;

  /// Default badge variant.
  static const defaultVariant = BadgeVariant(
    'inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2',
  );

  /// Primary badge variant.
  static const primary = BadgeVariant(
    'border-transparent bg-primary text-primary-foreground hover:bg-primary/80',
  );

  /// Secondary badge variant.
  static const secondary = BadgeVariant(
    'border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80',
  );

  /// Destructive badge variant.
  static const destructive = BadgeVariant(
    'border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80',
  );

  /// Outline badge variant.
  static const outline = BadgeVariant(
    'text-foreground',
  );
}

/// Alert variants.
class AlertVariant extends ComponentVariant {
  const AlertVariant(this.classes);

  @override
  final String classes;

  /// Default alert variant.
  static const defaultVariant = AlertVariant(
    'relative w-full rounded-lg border p-4',
  );

  /// Destructive alert variant.
  static const destructive = AlertVariant(
    'border-destructive/50 text-destructive dark:border-destructive',
  );
}

/// Dialog/Modal variants.
class DialogVariant extends ComponentVariant {
  const DialogVariant(this.classes);

  @override
  final String classes;

  /// Dialog overlay.
  static const overlay = DialogVariant(
    'fixed inset-0 z-50 bg-background/80 backdrop-blur-sm',
  );

  /// Dialog content.
  static const content = DialogVariant(
    'fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-lg duration-200 sm:rounded-lg',
  );
}

/// Progress variants.
class ProgressVariant extends ComponentVariant {
  const ProgressVariant(this.classes);

  @override
  final String classes;

  /// Default progress variant.
  static const defaultVariant = ProgressVariant(
    'relative h-4 w-full overflow-hidden rounded-full bg-secondary',
  );

  /// Progress indicator.
  static const indicator = ProgressVariant(
    'h-full w-full flex-1 bg-primary transition-all',
  );
}

/// Skeleton variants.
class SkeletonVariant extends ComponentVariant {
  const SkeletonVariant(this.classes);

  @override
  final String classes;

  /// Default skeleton variant.
  static const defaultVariant = SkeletonVariant(
    'animate-pulse rounded-md bg-muted',
  );
}

/// Utility class for building complex class strings.
class ClassBuilder {
  const ClassBuilder();

  /// Combines multiple class strings, removing duplicates and empty strings.
  static String combine(List<String?> classes) {
    return [
      for (String? cls in classes)
        if (cls?.isNotEmpty ?? false) ...cls.split(' '),
    ].where((cls) => cls.isNotEmpty).toSet().join(' ');
  }

  /// Conditionally adds a class.
  static String conditional(bool condition, String classes) {
    return condition ? classes : '';
  }

  /// Merges base classes with variant and additional classes.
  static String merge({
    required String base,
    ComponentVariant? variant,
    String? additional,
  }) {
    return combine([
      base,
      variant?.classes,
      additional,
    ]);
  }
}
