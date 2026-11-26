import 'package:coui_flutter/coui_flutter.dart';

class MockupCodeTonesExample extends StatelessWidget {
  const MockupCodeTonesExample({super.key});

  @override
  Widget build(BuildContext context) {
    return MockupCode.fromList(const [
      CoreCodeLine(text: '> flutter run', prefix: '1', tone: .muted),
      CoreCodeLine(text: 'Building web application...', prefix: '2'),
      CoreCodeLine(text: 'http://localhost:8080', prefix: '3', tone: .link),
      CoreCodeLine(text: 'Built in 12.4s', prefix: '4', tone: .success),
      CoreCodeLine(text: '2 unused imports', prefix: '5', tone: .warning),
      CoreCodeLine(text: 'lib/main.dart:12 failed', prefix: '6', tone: .error),
    ]);
  }
}
