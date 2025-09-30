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
      defaultValue: EdgeInsets.zero,
      themeValue: compTheme?.padding,
      widgetValue: this.padding,
    );
    final contentSpacing = styleValue(
      defaultValue: scaling * 16,
      themeValue: compTheme?.contentSpacing,
      widgetValue: this.contentSpacing,
    );
    final titleSpacing = styleValue(
      defaultValue: scaling * 4,
      themeValue: compTheme?.titleSpacing,
      widgetValue: this.titleSpacing,
    );
    final leadingAlignment = styleValue(
      defaultValue: Alignment.topCenter,
      themeValue: compTheme?.leadingAlignment,
      widgetValue: this.leadingAlignment,
    );
    final trailingAlignment = styleValue(
      defaultValue: Alignment.topCenter,
      themeValue: compTheme?.trailingAlignment,
      widgetValue: this.trailingAlignment,
    );
    final titleAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.titleAlignment,
      widgetValue: this.titleAlignment,
    );
    final subtitleAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.subtitleAlignment,
      widgetValue: this.subtitleAlignment,
    );
    final contentAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.contentAlignment,
      widgetValue: this.contentAlignment,
    );
    final mainAxisAlignment = styleValue(
      defaultValue: MainAxisAlignment.center,
      themeValue: compTheme?.mainAxisAlignment,
      widgetValue: this.mainAxisAlignment,
    );

    return Padding(
      padding: padding,
      child: IntrinsicWidth(
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: mainAxisAlignment,
            children: [
              if (leading != null)
                Align(alignment: leadingAlignment, child: leading),
              if (leading != null &&
                  (title != null || content != null || subtitle != null))
                SizedBox(width: contentSpacing),
              if (title != null || content != null || subtitle != null)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisAlignment: mainAxisAlignment,
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
      defaultValue: scaling * 16,
      themeValue: compTheme?.contentSpacing,
      widgetValue: this.contentSpacing,
    );
    final titleSpacing = styleValue(
      defaultValue: scaling * 4,
      themeValue: compTheme?.titleSpacing,
      widgetValue: this.titleSpacing,
    );
    final leadingAlignment = styleValue(
      defaultValue: Alignment.topCenter,
      themeValue: compTheme?.leadingAlignment,
      widgetValue: this.leadingAlignment,
    );
    final trailingAlignment = styleValue(
      defaultValue: Alignment.topCenter,
      themeValue: compTheme?.trailingAlignment,
      widgetValue: this.trailingAlignment,
    );
    final titleAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.titleAlignment,
      widgetValue: this.titleAlignment,
    );
    final subtitleAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.subtitleAlignment,
      widgetValue: this.subtitleAlignment,
    );
    final contentAlignment = styleValue(
      defaultValue: Alignment.topLeft,
      themeValue: compTheme?.contentAlignment,
      widgetValue: this.contentAlignment,
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
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
