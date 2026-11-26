import 'package:coui_web/coui_web.dart';

class TagDefaultExample extends StatelessComponent {
  const TagDefaultExample({super.key});

  @override
  Component build(BuildContext context) {
    // Every default — gray, subtle, md.
    return Tag(child: Text('디자인'));
  }
}
