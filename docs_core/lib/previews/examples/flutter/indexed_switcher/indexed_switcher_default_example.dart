import 'package:coui_flutter/coui_flutter.dart';

class IndexedSwitcherDefaultExample extends StatefulWidget {
  const IndexedSwitcherDefaultExample({super.key});

  @override
  State<IndexedSwitcherDefaultExample> createState() => _IndexedSwitcherDefaultExampleState();
}

class _IndexedSwitcherDefaultExampleState extends State<IndexedSwitcherDefaultExample> {
  int _index = 0;

  static const List<String> _labels = ['홈', '검색', '프로필'];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: CoreSpace.space256,
          height: CoreSize.size96,
          child: IndexedSwitcher(
            index: _index,
            children: [
              for (final label in _labels) _CountedView(label: label),
            ],
          ),
        ),
        const Gap.space16(),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            for (var idx = 0; idx < _labels.length; idx++)
              Padding(
                padding: const CoreEdgeInsets.symmetric(
                  horizontal: CoreSpace.space4,
                ).toValue(geometry: Theme.of(context).geometry),
                child: Button(
                  variant: idx == _index ? CoreButtonVariant.primary : CoreButtonVariant.outline,
                  onPressed: () => setState(() => _index = idx),
                  child: Text(_labels[idx]),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// A view that counts its own presses — the count lives in this view, so
/// it is still there when the switcher comes back to it.
class _CountedView extends StatefulWidget {
  const _CountedView({required this.label});

  final String label;

  @override
  State<_CountedView> createState() => _CountedViewState();
}

class _CountedViewState extends State<_CountedView> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Button(
        variant: CoreButtonVariant.secondary,
        onPressed: () => setState(() => _count++),
        child: Text('${widget.label} · $_count'),
      ),
    );
  }
}
