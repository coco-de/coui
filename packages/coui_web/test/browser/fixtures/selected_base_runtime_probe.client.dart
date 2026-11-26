import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;
import '../../../../../tool/parity/test/fixtures/selected_base_runtime_probe.dart';

void main() {
  Jaspr.initializeApp();
  runApp(selectedBaseRuntimeProbe());
  web.document.documentElement!.setAttribute(
    'data-selected-runtime-ready',
    'true',
  );
}
