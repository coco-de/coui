import 'package:coui_flutter/coui_flutter.dart';

extension IconExtension on Widget {
  Widget iconX3Small() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.x3Small,
      child: this,
    );
  }

  Widget iconXSmall() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.xSmall,
      child: this,
    );
  }

  Widget iconSmall() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.small,
      child: this,
    );
  }

  Widget iconMedium() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.medium,
      child: this,
    );
  }

  Widget iconLarge() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.large,
      child: this,
    );
  }

  Widget iconXLarge() {
    return WrappedIcon(
      data: (context, theme) => theme.iconTheme.xLarge,
      child: this,
    );
  }

  Widget iconMutedForeground() {
    return WrappedIcon(
      data: (context, theme) =>
          IconThemeData(color: theme.colorScheme.mutedForeground),
      child: this,
    );
  }
}

typedef WrappedIconDataBuilder<T> =
    T Function(
      BuildContext context,
      ThemeData theme,
    );

class WrappedIcon extends StatelessWidget {
  const WrappedIcon({required this.child, required this.data, super.key});

  final WrappedIconDataBuilder<IconThemeData> data;

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final iconTheme = data(context, theme);

    return IconTheme.merge(data: iconTheme, child: child);
  }
}
