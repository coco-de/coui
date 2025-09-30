import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

/// A default [coui.Tooltip] use case.
@UseCase(
  name: 'default',
  type: coui.Tooltip,
)
Widget buildTooltipDefaultUseCase(BuildContext context) {
  return Center(
    child: coui.Tooltip(
      tooltip: (ctx) => coui.TooltipContainer(
        child: Text(
          context.knobs.string(
            initialValue: 'This is a tooltip',
            label: 'message',
          ),
        ),
      ),
      child: coui.Button.primary(
        onPressed: () {
          debugPrint('pressed');
        },
        child: const Text('Hover me'),
      ),
    ),
  );
}

/// A [coui.Tooltip] with rich content use case.
@UseCase(
  name: 'rich content',
  type: coui.Tooltip,
)
Widget buildTooltipRichContentUseCase(BuildContext _) {
  return Center(
    child: coui.Tooltip(
      tooltip: (ctx) => const coui.TooltipContainer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rich Tooltip',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 4),
            Text('This tooltip contains multiple lines'),
            Text('and rich formatted content'),
          ],
        ),
      ),
      child: coui.Button.outline(
        onPressed: () {
          debugPrint('pressed');
        },
        child: const Text('Hover for rich tooltip'),
      ),
    ),
  );
}

/// A [coui.Tooltip] with different positions use case.
@UseCase(
  name: 'positions',
  type: coui.Tooltip,
)
Widget buildTooltipPositionsUseCase(BuildContext _) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        coui.Tooltip(
          tooltip: (ctx) => const coui.TooltipContainer(
            child: Text('Top tooltip'),
          ),
          child: coui.Button.secondary(
            onPressed: () {
              debugPrint('Top');
            },
            child: const Text('Top'),
          ),
        ),
        const SizedBox(height: 16),
        coui.Tooltip(
          tooltip: (ctx) => const coui.TooltipContainer(
            child: Text('Bottom tooltip'),
          ),
          child: coui.Button.secondary(
            onPressed: () {
              debugPrint('Bottom');
            },
            child: const Text('Bottom'),
          ),
        ),
        const SizedBox(height: 16),
        coui.Tooltip(
          tooltip: (ctx) => const coui.TooltipContainer(
            child: Text('Left tooltip'),
          ),
          child: coui.Button.secondary(
            onPressed: () {
              debugPrint('Left');
            },
            child: const Text('Left'),
          ),
        ),
        const SizedBox(height: 16),
        coui.Tooltip(
          tooltip: (ctx) => const coui.TooltipContainer(
            child: Text('Right tooltip'),
          ),
          child: coui.Button.secondary(
            onPressed: () {
              debugPrint('Right');
            },
            child: const Text('Right'),
          ),
        ),
      ],
    ),
  );
}

/// A [coui.Tooltip] with icon use case.
@UseCase(
  name: 'with icon',
  type: coui.Tooltip,
)
Widget buildTooltipWithIconUseCase(BuildContext _) {
  return Center(
    child: coui.Tooltip(
      tooltip: (ctx) => const coui.TooltipContainer(
        child: Text('Information tooltip'),
      ),
      child: const Icon(
        Icons.info_outline,
        size: 32,
      ),
    ),
  );
}
