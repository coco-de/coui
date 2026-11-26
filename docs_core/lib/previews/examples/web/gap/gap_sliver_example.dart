import 'package:coui_web/coui_web.dart';

class GapSliverExample extends StatelessComponent {
  const GapSliverExample({super.key});

  @override
  Component build(BuildContext context) {
    final cs = context.colorScheme;
    final textClass = 'text-${CoreTextStyles.bodyMedium.name} text-${cs.onSurface}';
    return div(
      [
        div([Text('위 항목')], classes: textClass),
        SliverGap.space24(),
        div([Text('가운데 항목')], classes: textClass),
        SliverGap.space24(),
        div([Text('아래 항목')], classes: textClass),
      ],
      // `w-full` mirrors Flutter's `CustomScrollView`, which always
      // stretches to the cross-axis extent — without it the column
      // shrinks to fit and the preview centres it while Flutter's list
      // sits at the left edge.
      classes: 'flex flex-col items-start w-full',
      styles: Styles(raw: {'height': '${160 / 16}rem'}),
    );
  }
}
