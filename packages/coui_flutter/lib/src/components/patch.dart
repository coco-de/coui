import 'package:coui_flutter/coui_flutter.dart';

class ClickDetails {
  const ClickDetails({required this.clickCount});
  final int clickCount;
}

typedef ClickCallback<T> = void Function(T details);

class ClickDetector extends StatefulWidget {
  const ClickDetector({
    this.behavior = HitTestBehavior.deferToChild,
    required this.child,
    super.key,
    this.onClick,
    this.threshold = const Duration(milliseconds: 300),
  });

  final ClickCallback<ClickDetails>? onClick;
  final Widget child;
  final HitTestBehavior behavior;

  final Duration threshold;

  @override
  State<ClickDetector> createState() => _ClickDetectorState();
}

class _ClickDetectorState extends State<ClickDetector> {
  DateTime? lastClick;
  int count = 0;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTap: widget.onClick == null
          ? null
          : () {
              final now = DateTime.now();
              if (lastClick == null ||
                  (now.difference(lastClick!) > widget.threshold)) {
                count = 1;
              } else {
                count += 1;
              }
              widget.onClick?.call(ClickDetails(clickCount: count));
              lastClick = now;
            },
      child: widget.child,
    );
  }
}
