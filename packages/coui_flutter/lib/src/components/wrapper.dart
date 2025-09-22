import 'package:coui_flutter/coui_flutter.dart';

typedef WrapperBuilder = Widget Function(
  Widget child,
  BuildContext context,
);

class Wrapper extends StatefulWidget {
  const Wrapper({
    this.builder,
    required this.child,
    super.key,
    this.maintainStructure = false,
    this.wrap = true,
  });

  final Widget child;
  final WrapperBuilder? builder;
  final bool wrap;

  final bool maintainStructure;

  @override
  State<Wrapper> createState() => _WrapperState();
}

class _WrapperState extends State<Wrapper> {
  final _key = GlobalKey();

  @override
  Widget build(BuildContext context) {
    Widget wrappedChild = widget.child;
    if (widget.maintainStructure) {
      wrappedChild = KeyedSubtree(key: _key, child: wrappedChild);
    }
    if (widget.wrap && widget.builder != null) {
      wrappedChild = widget.builder!(context, wrappedChild);
    }

    return wrappedChild;
  }
}
