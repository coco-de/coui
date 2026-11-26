// The host half of the frame-timing scenes: carries the result the test reports
// (`binding.reportData`) off the device and writes it as JSON.
//
// `FT_OUT` (environment) is the directory it goes to; `build/` when unset. See
// `integration_test/frame_timing_test.dart` for how the scenes are run.
import 'dart:io';

import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
  responseDataCallback: (data) async {
    final out = Platform.environment['FT_OUT'] ?? 'build';
    Directory(out).createSync(recursive: true);
    await writeResponseData(
      data,
      testOutputFilename: 'frame_timing_flutter',
      destinationDirectory: out,
    );
  },
);
