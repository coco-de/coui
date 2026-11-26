import 'package:coui_flutter/coui_flutter.dart';

class TagDefaultExample extends StatelessWidget {
  const TagDefaultExample({super.key});

  @override
  Widget build(BuildContext context) {
    // Every default — gray, subtle, md.
    return const Tag(child: Text('디자인'));
  }
}
