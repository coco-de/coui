import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_i10n/coui_i10n.dart';
import 'package:coui_widgetbook/widgetbook_config.dart';
import 'package:widgetbook/widgetbook.dart';

Future<void> main() async {
  final _ = WidgetsFlutterBinding.ensureInitialized();
  await LocaleSettings.useDeviceLocale();

  runWidgetbook(createWidgetbookConfig());
}
