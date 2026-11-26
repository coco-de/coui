import 'package:coui_flutter/coui_flutter.dart';
import '../../shared/size_spec.dart';
import 'flutter_selection.dart';
import 'selection.dart';

const double kDocsStageMinHeight = 140;
const double kDocsStageCompactMinHeight = 88;

class DocsStage extends StatelessWidget {
  /// 무대를 만든다.
  const DocsStage({
    required this.attributes,
    this.compact = false,
    this.flatBottom = false,
    super.key,
  });

  /// 태그 속성 — `component` · `props` · `label` · `example` · `height`.
  final Map<String, String> attributes;

  /// Variant 행의 작은 무대인지.
  final bool compact;

  /// 카드 위쪽처럼 아래 모서리를 둥글리지 않을지.
  final bool flatBottom;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = double.tryParse(attributes['height'] ?? '');
    final minHeight = attributes['height'] == 'hug'
        ? 0.0
        : height ?? (compact ? kDocsStageCompactMinHeight : kDocsStageMinHeight);
    const radius = Radius.circular(CoreRadiusRole.surface);
    // Card tone owns only its preview's bottom border. Container reserves the
    // decoration's border padding inside the existing outer min-height.
    final borderColor = switch (flatBottom ? attributes['tone'] : null) {
      'do' => const CoreColor.token(CoreColors.success),
      'dont' => const CoreColor.token(CoreColors.error),
      _ => null,
    };

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainer)).toValue(),
          borderRadius: flatBottom ? const BorderRadius.vertical(top: radius) : const BorderRadius.all(radius),
          border: borderColor == null
              ? null
              : Border(
                  bottom: BorderSide(
                    color: theme.colorScheme.resolve(borderColor).toValue(),
                    width: theme.geometry.stroke(CoreStrokeWidth.stroke2, scaling: theme.scaling),
                  ),
                ),
        ),
        padding: const EdgeInsets.all(CoreSpace.space24),
        child: Center(child: docsPreviewFor(attributes)),
      ),
    );
  }
}

Widget docsPreviewFor(
  Map<String, String> attributes, {
  Map<String, String> extraProps = const {},
}) {
  final selection = PreviewSelection.attributes(
    attributes,
    extraProps: extraProps,
  );
  final result = renderFlutterSelection(selection);
  if (result != null) return result;
  if (selection.kind == PreviewSelectionKind.example) return const SizedBox.shrink();
  return Text(
    selection.kind == PreviewSelectionKind.demo
        ? 'Demo not available: "${selection.name}"'
        : 'Preview not available for "${selection.component}"',
  ).bodySmall.onSurfaceVariant;
}

class FlutterDocsSizeSpec extends StatelessWidget {
  const FlutterDocsSizeSpec({
    required this.component,
    required this.spec,
    required this.attributes,
  });

  final String component;
  final DocsSizeSpec spec;
  final Map<String, String> attributes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: .stretch,
      spacing: CoreSpace.space16,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainer)).toValue(),
            borderRadius: const BorderRadius.all(
              Radius.circular(CoreRadiusRole.surface),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(CoreSpace.space24),
            child: Wrap(
              alignment: .center,
              crossAxisAlignment: .end,
              spacing: CoreSpace.space32,
              runSpacing: CoreSpace.space24,
              children: [
                for (final row in spec.rows)
                  Column(
                    mainAxisSize: .min,
                    spacing: CoreSpace.space12,
                    children: [
                      docsPreviewFor(
                        attributes,
                        extraProps: {'size': row.size.name},
                      ),
                      Text(row.size.name).codeSm.onSurfaceVariant,
                    ],
                  ),
              ],
            ),
          ),
        ),
        // 표 — 열 폭을 나눠 쓰는 단순한 행들. (`Table` 은 CoUI 의 표 컴포넌트와
        // 이름이 겹친다.)
        Column(
          crossAxisAlignment: .stretch,
          children: [
            _row([
              for (final column in spec.columns) Text(column).labelSmall.onSurfaceVariant,
            ]),
            for (final row in spec.rows)
              _row([
                Text(row.size.name).codeSm.onSurface,
                for (final cell in row.cells) Text(cell).bodySmall.onSurface,
              ]),
          ],
        ),
      ],
    );
  }

  Widget _row(List<Widget> cells) => Row(
    children: [for (final cell in cells) Expanded(child: _cell(cell))],
  );

  Widget _cell(Widget child) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: CoreSpace.space8,
      vertical: CoreSpace.space10,
    ),
    child: child,
  );
}

Widget buildFlutterPlaygroundStage(BuildContext context, Widget child) => ConstrainedBox(
  constraints: const BoxConstraints(minHeight: 200),
  child: DecoratedBox(
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.resolve(const CoreColor.token(CoreColors.surfaceContainer)).toValue(),
      borderRadius: const BorderRadius.all(
        Radius.circular(CoreRadiusRole.surface),
      ),
    ),
    child: Center(child: child),
  ),
);
