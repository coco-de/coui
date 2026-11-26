import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:widgetbook/widgetbook.dart';

part 'skeleton.stories.g.dart';

/// Spacing between the demo heading and its content.
const _kSpacing = 16.0;

/// Spacing between skeleton lines.
const _kSmallSpacing = 8.0;

/// Width of the basic / loading demo containers.
const _kContainerWidth = 300.0;

/// Width of the comparison demo cards.
const _kCardWidth = 200.0;

/// Spacing between the loading card lines.
const _kExtraSpacing = 12.0;

// A skeleton line takes the box of the line it stands in for — font size
// × the 1.6 line height in this catalogue's theme — so nothing moves when
// the copy arrives.

/// Box of a `bodyLarge` line (18 × 1.6).
const _kTitleLineHeight = 28.8;

/// Box of a body line (16 × 1.6).
const _kBodyLineHeight = 25.6;

/// Box of a `bodySmall` line (14 × 1.6).
const _kSmallLineHeight = 22.4;

/// Lines the article copy runs to at [_kContainerWidth].
const _kParagraphLines = 2;

/// Gap between the paragraph's bars — stated here rather than left to the
/// text variant's default, so the paragraph keeps the height of its copy
/// whatever that default is.
const _kParagraphBarSpacing = 12.0;

/// One bar of the article paragraph: its two body lines (2 × 25.6) drawn
/// as two bars [_kParagraphBarSpacing] apart.
const double _kParagraphBarHeight =
    (_kParagraphLines * _kBodyLineHeight - _kParagraphBarSpacing) /
    _kParagraphLines;

/// Width of the skeleton standing in for the basic demo's title.
const _kTitleLineWidth = 140.0;

/// Width of the skeleton standing in for a short line of copy.
const _kShortLineWidth = 90.0;

/// Width of the skeleton standing in for the comparison card's name.
const _kNameLineWidth = 100.0;

/// Width of the skeleton standing in for the comparison card's email.
const _kEmailLineWidth = 130.0;

/// Width of the skeleton standing in for the article title.
const _kArticleTitleWidth = 120.0;

/// Width of the skeleton standing in for the posted date.
const _kPostedDateWidth = 150.0;

/// Layout variants for [SkeletonDemo].
enum SkeletonDemoLayout {
  /// Three text lines, drawn as skeleton lines while loading.
  basic,

  /// A card next to the skeleton its caller draws for it.
  comparison,

  /// Article card that swaps between its skeleton and its content.
  loading,
}

/// Interactive demo host for [Skeleton] stories.
///
/// The caller knows the shape of what is loading, so it draws that shape
/// with [Skeleton]s and wraps the area in one [LoadingRegion] — the region
/// announces the load once, however many skeletons it holds.
class SkeletonDemo extends StatelessWidget {
  /// Creates a [SkeletonDemo].
  const SkeletonDemo({
    super.key,
    this.layout = SkeletonDemoLayout.basic,
    this.loading = true,
  });

  /// Which demo layout to render.
  final SkeletonDemoLayout layout;

  /// Whether the content is still loading (basic / loading layouts).
  final bool loading;

  @override
  Widget build(BuildContext context) => switch (layout) {
    .basic => _BasicLayout(loading: loading),
    .comparison => const _ComparisonLayout(),
    .loading => _LoadingLayout(loading: loading),
  };
}

class _BasicLayout extends StatelessWidget {
  const _BasicLayout({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final skeletonLabels = t.widgetbook.skeleton;

    return Center(
      child: Column(
        mainAxisSize: .min,
        crossAxisAlignment: .start,
        spacing: _kSpacing,
        children: [
          Text(
            loading
                ? skeletonLabels.skeleton_enabled
                : skeletonLabels.without_skeleton,
          ).semiBold,
          SizedBox(
            width: _kContainerWidth,
            child: loading
                ? const LoadingRegion(
                    child: Column(
                      crossAxisAlignment: .start,
                      spacing: _kSmallSpacing,
                      children: [
                        Skeleton(
                          width: _kTitleLineWidth,
                          height: _kTitleLineHeight,
                        ),
                        Skeleton(
                          width: _kContainerWidth,
                          height: _kBodyLineHeight,
                        ),
                        Skeleton(
                          width: _kShortLineWidth,
                          height: _kBodyLineHeight,
                        ),
                      ],
                    ),
                  )
                : Column(
                    crossAxisAlignment: .start,
                    spacing: _kSmallSpacing,
                    children: [
                      Text(skeletonLabels.title_text).bodyLarge,
                      Text(skeletonLabels.description_text),
                      Text(skeletonLabels.short_text),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ComparisonLayout extends StatelessWidget {
  const _ComparisonLayout();

  @override
  Widget build(BuildContext context) {
    final skeletonLabels = t.widgetbook.skeleton;

    return Center(
      child: Row(
        mainAxisAlignment: .spaceEvenly,
        crossAxisAlignment: .start,
        children: [
          Column(
            mainAxisSize: .min,
            spacing: _kSmallSpacing,
            children: [
              Text(skeletonLabels.without_skeleton).semiBold,
              const Card(
                child: SizedBox(
                  width: _kCardWidth,
                  child: _ComparisonCardContent(),
                ),
              ),
            ],
          ),
          Column(
            mainAxisSize: .min,
            spacing: _kSmallSpacing,
            children: [
              Text(skeletonLabels.with_skeleton).semiBold,
              const Card(
                child: SizedBox(
                  width: _kCardWidth,
                  child: LoadingRegion(child: _ComparisonCardSkeleton()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ComparisonCardContent extends StatelessWidget {
  const _ComparisonCardContent();

  @override
  Widget build(BuildContext context) {
    final skeletonLabels = t.widgetbook.skeleton;

    return Column(
      crossAxisAlignment: .start,
      spacing: _kSmallSpacing,
      children: [
        Text(skeletonLabels.user_name).bodyLarge.semiBold,
        Text(skeletonLabels.user_email).bodySmall.onSurface,
        const SizedBox(height: _kSmallSpacing),
        Text(skeletonLabels.bio_description).bodySmall,
      ],
    );
  }
}

/// The shape [_ComparisonCardContent] takes while it loads — one skeleton
/// per line, in the same column and spacing.
class _ComparisonCardSkeleton extends StatelessWidget {
  const _ComparisonCardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: .start,
      spacing: _kSmallSpacing,
      children: [
        Skeleton(width: _kNameLineWidth, height: _kTitleLineHeight),
        Skeleton(width: _kEmailLineWidth, height: _kSmallLineHeight),
        SizedBox(height: _kSmallSpacing),
        Skeleton(width: _kCardWidth, height: _kSmallLineHeight),
      ],
    );
  }
}

class _LoadingLayout extends StatelessWidget {
  const _LoadingLayout({required this.loading});

  final bool loading;

  @override
  Widget build(BuildContext context) {
    final skeletonLabels = t.widgetbook.skeleton;

    // The divider is the card's own chrome, so it stays in both states —
    // only the copy it separates is loading.
    final content = Column(
      crossAxisAlignment: .start,
      spacing: _kExtraSpacing,
      children: [
        if (loading)
          const Skeleton(
            width: _kArticleTitleWidth,
            height: _kTitleLineHeight,
          )
        else
          Text(skeletonLabels.article_title).bodyLarge.semiBold,
        if (loading)
          const Skeleton(
            width: _kPostedDateWidth,
            height: _kSmallLineHeight,
          )
        else
          Text(skeletonLabels.posted_date).bodySmall.onSurface,
        const Divider(),
        if (loading)
          const Skeleton.text(
            skeletonStyle: CoreSkeletonStyle(
              lines: _kParagraphLines,
              lineHeight: _kParagraphBarHeight,
              lineSpacing: _kParagraphBarSpacing,
            ),
          )
        else
          Text(skeletonLabels.article_content).medium,
      ],
    );

    return Center(
      child: Card(
        child: SizedBox(
          width: _kContainerWidth,
          child: loading ? LoadingRegion(child: content) : content,
        ),
      ),
    );
  }
}

/// Navigation metadata for the Skeleton component.
const kComponentMeta = ComponentMeta(name: 'Skeleton', path: 'display');

/// Story metadata for [SkeletonDemo].
const kMeta = Meta(SkeletonDemo.new);

/// Text lines drawn as skeletons while loading, with a loading knob.
final $Default = _Story();

/// A card next to the skeleton its caller draws for it.
final $ContentComparison = _Story(
  name: 'Content Comparison',
  args: _Args(
    layout: EnumArg(
      SkeletonDemoLayout.comparison,
      values: SkeletonDemoLayout.values,
    ),
  ),
);

/// Article card swapping between its skeleton and its content.
final $LoadingState = _Story(
  name: 'Loading State',
  args: _Args(
    layout: EnumArg(
      SkeletonDemoLayout.loading,
      values: SkeletonDemoLayout.values,
    ),
  ),
);
