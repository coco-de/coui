import 'package:coui_flutter/coui_flutter.dart';

/// Unified cross-platform option list — a vertical stack of [OptionItem]s.
///
/// Uses [CoreOptionListContract] from `coui_core`, so the Web `OptionList`
/// takes the same named properties. The list owns the arrangement only: the
/// rows in order, [CoreOptionListStyle.spacing] apart, each as wide as the
/// list. Which rows are chosen is the caller's — each row states its own
/// `selection` and `selected`.
///
/// ```dart
/// OptionList(
///   children: [
///     OptionItem(label: Text('Newest'), selected: true, onPressed: () {}),
///     OptionItem(label: Text('Oldest'), onPressed: () {}),
///   ],
/// )
/// ```
class OptionList extends StatelessWidget
    implements CoreOptionListContract<Widget> {
  /// Creates an [OptionList].
  const OptionList({
    required this.children,
    super.key,
    this.optionListStyle,
  });

  @override
  final List<Widget> children;

  @override
  final CoreOptionListStyle? optionListStyle;

  /// Returns a copy of this [OptionList] with the given fields replaced.
  OptionList copyWith({
    Key? key,
    List<Widget>? children,
    CoreOptionListStyle? optionListStyle,
  }) {
    return OptionList(
      key: key ?? this.key,
      optionListStyle: optionListStyle ?? this.optionListStyle,
      children: children ?? this.children,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveOptionList(
      context,
      optionListStyle: optionListStyle,
    );
    return CoUISemantics(
      role: .group,
      container: true,
      child: Column(
        crossAxisAlignment: .stretch,
        mainAxisSize: .min,
        spacing: resolved.spacing,
        children: children,
      ),
    );
  }
}

/// Chain sugar for merging a [CoreOptionListStyle] patch into
/// [OptionList.optionListStyle]. Mirrors the Web `OptionList.withStyle`
/// extension so both platforms read identically.
extension OptionListStyleChain on OptionList {
  /// Returns a copy of this [OptionList] with [patch] merged into
  /// [optionListStyle] (patch fields win on conflict).
  OptionList withStyle(CoreOptionListStyle patch) => copyWith(
    optionListStyle: (optionListStyle ?? const CoreOptionListStyle()).merge(
      patch,
    ),
  );
}
