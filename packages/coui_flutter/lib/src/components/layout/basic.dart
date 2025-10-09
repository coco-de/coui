import 'package:coui_flutter/coui_flutter.dart';

class BasicTheme {
  const BasicTheme({
    this.contentAlignment,
    this.contentSpacing,
    this.leadingAlignment,
    this.mainAxisAlignment,
    this.padding,
    this.subtitleAlignment,
    this.titleAlignment,
    this.titleSpacing,
    this.trailingAlignment,
  });

  final AlignmentGeometry? leadingAlignment;
  final AlignmentGeometry? trailingAlignment;
  final AlignmentGeometry? titleAlignment;
  final AlignmentGeometry? subtitleAlignment;
  final AlignmentGeometry? contentAlignment;
  final double? contentSpacing;
  final double? titleSpacing;
  final MainAxisAlignment? mainAxisAlignment;

  final EdgeInsetsGeometry? padding;

  @override
  bool operator ==(Object other) {
    return other is BasicTheme &&
        other.leadingAlignment == leadingAlignment &&
        other.trailingAlignment == trailingAlignment &&
        other.titleAlignment == titleAlignment &&
        other.subtitleAlignment == subtitleAlignment &&
        other.contentAlignment == contentAlignment &&
        other.contentSpacing == contentSpacing &&
        other.titleSpacing == titleSpacing &&
        other.mainAxisAlignment == mainAxisAlignment &&
        other.padding == padding;
  }

  @override
  int get hashCode => Object.hash(
    leadingAlignment,
    trailingAlignment,
    titleAlignment,
    subtitleAlignment,
    contentAlignment,
    contentSpacing,
    titleSpacing,
    mainAxisAlignment,
    padding,
  );
}

class Basic extends StatelessWidget {
  const Basic({
    this.content,
    this.contentAlignment,
    this.contentSpacing, // 16
    super.key,
    this.leading,
    this.leadingAlignment,
    //4
    this.mainAxisAlignment,
    this.padding,
    this.subtitle,
    this.subtitleAlignment,
    this.title,
    this.titleAlignment,
    this.titleSpacing,
    this.trailing,
    this.trailingAlignment,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? content;
  final Widget? trailing;
  final AlignmentGeometry? leadingAlignment;
  final AlignmentGeometry? trailingAlignment;
  final AlignmentGeometry? titleAlignment;
  final AlignmentGeometry? subtitleAlignment;
  final AlignmentGeometry? contentAlignment;
  final double? contentSpacing;
  final double? titleSpacing;
  final MainAxisAlignment? mainAxisAlignment;

  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<BasicTheme>(context);
    final padding = styleValue(
      widgetValue: this.padding,
      themeValue: compTheme?.padding,
      defaultValue: EdgeInsets.zero,
    );
    final contentSpacing = styleValue(
      widgetValue: this.contentSpacing,
      themeValue: compTheme?.contentSpacing,
      defaultValue: scaling * 16,
    );
    final titleSpacing = styleValue(
      widgetValue: this.titleSpacing,
      themeValue: compTheme?.titleSpacing,
      defaultValue: scaling * 4,
    );
    final leadingAlignment = styleValue(
      widgetValue: this.leadingAlignment,
      themeValue: compTheme?.leadingAlignment,
      defaultValue: Alignment.topCenter,
    );
    final trailingAlignment = styleValue(
      widgetValue: this.trailingAlignment,
      themeValue: compTheme?.trailingAlignment,
      defaultValue: Alignment.topCenter,
    );
    final titleAlignment = styleValue(
      widgetValue: this.titleAlignment,
      themeValue: compTheme?.titleAlignment,
      defaultValue: Alignment.topLeft,
    );
    final subtitleAlignment = styleValue(
      widgetValue: this.subtitleAlignment,
      themeValue: compTheme?.subtitleAlignment,
      defaultValue: Alignment.topLeft,
    );
    final contentAlignment = styleValue(
      widgetValue: this.contentAlignment,
      themeValue: compTheme?.contentAlignment,
      defaultValue: Alignment.topLeft,
    );
    final mainAxisAlignment = styleValue(
      widgetValue: this.mainAxisAlignment,
      themeValue: compTheme?.mainAxisAlignment,
      defaultValue: MainAxisAlignment.center,
    );

    return Padding(
      padding: padding,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            mainAxisAlignment: mainAxisAlignment,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (leading != null)
                Align(alignment: leadingAlignment, child: leading),
              if (leading != null &&
                  (title != null || content != null || subtitle != null))
                SizedBox(width: contentSpacing),
              if (title != null || content != null || subtitle != null)
                Expanded(
                  child: Column(
                    mainAxisAlignment: mainAxisAlignment,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (title != null)
                        Align(
                          alignment: titleAlignment,
                          child: title,
                        ).small().medium(),
                      if (title != null && subtitle != null)
                        SizedBox(height: scaling * 2),
                      if (subtitle != null)
                        Align(
                          alignment: subtitleAlignment,
                          child: subtitle,
                        ).xSmall().muted(),
                      if ((title != null || subtitle != null) &&
                          content != null)
                        SizedBox(height: titleSpacing),
                      if (content != null)
                        Align(
                          alignment: contentAlignment,
                          child: content,
                        ).small(),
                    ],
                  ),
                ),
              if (trailing != null &&
                  (title != null ||
                      content != null ||
                      leading != null ||
                      subtitle != null))
                SizedBox(width: contentSpacing),
              // if (trailing != null) trailing!,
              if (trailing != null)
                Align(alignment: trailingAlignment, child: trailing),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same as basic, but without forcing the text style
class BasicLayout extends StatelessWidget {
  const BasicLayout({
    this.content,
    this.contentAlignment,
    this.contentSpacing,
    super.key,
    this.leading,
    this.leadingAlignment,
    this.subtitle,
    this.subtitleAlignment,
    this.title,
    this.titleAlignment,
    this.titleSpacing,
    this.trailing,
    this.trailingAlignment,
  });

  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? content;
  final Widget? trailing;
  final AlignmentGeometry? leadingAlignment;
  final AlignmentGeometry? trailingAlignment;
  final AlignmentGeometry? titleAlignment;
  final AlignmentGeometry? subtitleAlignment;
  final AlignmentGeometry? contentAlignment;
  final double? contentSpacing;
  final double? titleSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final compTheme = ComponentTheme.maybeOf<BasicTheme>(context);
    final contentSpacing = styleValue(
      widgetValue: this.contentSpacing,
      themeValue: compTheme?.contentSpacing,
      defaultValue: scaling * 16,
    );
    final titleSpacing = styleValue(
      widgetValue: this.titleSpacing,
      themeValue: compTheme?.titleSpacing,
      defaultValue: scaling * 4,
    );
    final leadingAlignment = styleValue(
      widgetValue: this.leadingAlignment,
      themeValue: compTheme?.leadingAlignment,
      defaultValue: Alignment.topCenter,
    );
    final trailingAlignment = styleValue(
      widgetValue: this.trailingAlignment,
      themeValue: compTheme?.trailingAlignment,
      defaultValue: Alignment.topCenter,
    );
    final titleAlignment = styleValue(
      widgetValue: this.titleAlignment,
      themeValue: compTheme?.titleAlignment,
      defaultValue: Alignment.topLeft,
    );
    final subtitleAlignment = styleValue(
      widgetValue: this.subtitleAlignment,
      themeValue: compTheme?.subtitleAlignment,
      defaultValue: Alignment.topLeft,
    );
    final contentAlignment = styleValue(
      widgetValue: this.contentAlignment,
      themeValue: compTheme?.contentAlignment,
      defaultValue: Alignment.topLeft,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leading != null) Align(alignment: leadingAlignment, child: leading),
        if (leading != null &&
            (title != null || content != null || subtitle != null))
          SizedBox(width: contentSpacing),
        if (title != null || content != null || subtitle != null)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title != null)
                  Align(alignment: titleAlignment, child: title),
                if (title != null && subtitle != null)
                  SizedBox(height: scaling * 2),
                if (subtitle != null)
                  Align(alignment: subtitleAlignment, child: subtitle),
                if ((title != null || subtitle != null) && content != null)
                  SizedBox(height: titleSpacing),
                if (content != null)
                  Align(alignment: contentAlignment, child: content),
              ],
            ),
          ),
        if (trailing != null &&
            (title != null ||
                content != null ||
                leading != null ||
                subtitle != null))
          SizedBox(width: contentSpacing),
        if (trailing != null)
          Align(alignment: trailingAlignment, child: trailing),
      ],
    );
  }
}

class Label extends StatelessWidget {
  const Label({required this.child, super.key, this.leading, this.trailing});

  final Widget? leading;
  final Widget child;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;

    return IntrinsicWidth(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) leading!,
          if (leading != null) SizedBox(width: scaling * 8),
          Expanded(child: child),
          if (trailing != null) SizedBox(width: scaling * 8),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}
