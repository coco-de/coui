import 'package:coui_web/coui_web.dart';

class IndexedSwitcherDefaultExample extends StatefulComponent {
  const IndexedSwitcherDefaultExample({super.key});

  @override
  State<IndexedSwitcherDefaultExample> createState() => _IndexedSwitcherDefaultExampleState();
}

class _IndexedSwitcherDefaultExampleState extends State<IndexedSwitcherDefaultExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Component build(BuildContext context) {
    return div(
      [
        div(
          [
            IndexedSwitcher(
              index: _index,
              children: [
                for (final label in _labels) _CountedView(label: label),
              ],
            ),
          ],
          styles: const Styles(
            raw: {'width': '16rem', 'height': '6rem'},
          ),
        ),
        Gap.space16(),
        div(
          [
            for (var idx = 0; idx < _labels.length; idx++)
              Button(
                variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                onPressed: () => setState(() => _index = idx),
                child: Text(_labels[idx]),
              ),
          ],
          classes: 'flex flex-row flex-wrap justify-center gap-${CoreSpace.scale.space8}',
        ),
      ],
      classes: 'inline-flex flex-col items-center',
    );
  }
}

/// A view that counts its own presses — the count lives in this view, so
/// it is still there when the switcher comes back to it.
class _CountedView extends StatefulComponent {
  const _CountedView({required this.label});

  final String label;

  @override
  State<_CountedView> createState() => _CountedViewState();
}

class _CountedViewState extends State<_CountedView> {
  int _count = 0;

  @override
  Component build(BuildContext context) {
    return div(
      [
        Button(
          variant: CoreButtonVariant.secondary,
          onPressed: () => setState(() => _count++),
          child: Text('${component.label} · $_count'),
        ),
      ],
      classes: 'flex items-center justify-center h-full',
    );
  }
}
