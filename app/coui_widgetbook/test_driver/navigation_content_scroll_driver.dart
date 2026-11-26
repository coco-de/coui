import 'dart:io';

import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final out =
      Platform.environment['NAV_SCROLL_OUT'] ?? 'build/navigation-scroll';
  Directory(out).createSync(recursive: true);
  await integrationDriver(
    onScreenshot: (name, bytes, [args]) async {
      await File('$out/$name.png').writeAsBytes(bytes);
      // Capture delivery only; there is no golden comparison here.
      return true;
    },
    responseDataCallback: (data) async {
      await writeResponseData(
        {'measurements': data?['measurements']},
        testOutputFilename: 'navigation_content_scroll',
        destinationDirectory: out,
      );
    },
  );
}
