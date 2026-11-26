import 'package:flutter_test/flutter_test.dart';

/// Runs parity captures with the app's real shadow masks while retaining
/// the automated test clock. Initialize before registering testWidgets.
///
/// The SDK's automated binding normally disables shadow masks for goldens.
/// Its supported getter also supplies the painting-invariant expectation,
/// unlike assigning debugDisableShadows after a test has started. Only the
/// capture entrypoints opt in; ordinary widget/golden tests keep their SDK
/// binding policy.
class ParityCaptureBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  bool get disableShadows => false;
}
