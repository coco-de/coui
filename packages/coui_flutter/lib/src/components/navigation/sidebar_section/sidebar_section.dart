import 'package:coui_flutter/coui_flutter.dart';

/// A quiet heading above a run of [Sidebar] rows, with an optional action
/// at its far end.
///
/// A heading, not a destination: it takes no focus of its own.
///
/// ```dart
/// SidebarSection(
///   label: const Text('프로젝트'),
///   action: Button(
///     variant: CoreButtonVariant.plain,
///     onPressed: () {},
///     child: const Icon(LucideIcons.plus),
///   ),
/// )
/// ```
class SidebarSection extends StatelessWidget
    implements CoreSidebarSectionContract<Widget> {
  /// Creates a [SidebarSection].
  const SidebarSection({
    required this.label,
    super.key,
    this.action,
    this.sidebarSectionStyle,
  });

  @override
  final Widget label;

  @override
  final Widget? action;

  @override
  final CoreSidebarSectionStyle? sidebarSectionStyle;

  /// Returns a copy with the given fields replaced.
  SidebarSection copyWith({
    Key? key,
    Widget? label,
    Widget? action,
    CoreSidebarSectionStyle? sidebarSectionStyle,
  }) {
    return SidebarSection(
      key: key ?? this.key,
      label: label ?? this.label,
      action: action ?? this.action,
      sidebarSectionStyle: sidebarSectionStyle ?? this.sidebarSectionStyle,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveSidebarSection(
      context,
      sidebarSectionStyle: sidebarSectionStyle,
    );
    final action = this.action;
    return Semantics(
      header: true,
      child: Padding(
        padding: resolved.padding,
        child: Row(
          spacing: resolved.contentSpacing,
          children: [
            Expanded(
              child: DefaultTextStyle.merge(
                style: resolved.labelTextStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: label,
              ),
            ),
            if (action != null)
              IconTheme.merge(data: resolved.actionIconTheme, child: action),
          ],
        ),
      ),
    );
  }
}

/// Chain sugar for merging a [CoreSidebarSectionStyle] patch into
/// [SidebarSection.sidebarSectionStyle]. Mirrors the Web extension.
extension SidebarSectionStyleChain on SidebarSection {
  /// Returns a copy with [patch] merged into [sidebarSectionStyle] (patch
  /// fields win on conflict).
  SidebarSection withStyle(CoreSidebarSectionStyle patch) => copyWith(
    sidebarSectionStyle:
        (sidebarSectionStyle ?? const CoreSidebarSectionStyle()).merge(patch),
  );
}
