/// The entrypoint for the **client** environment.
library;

import 'package:file_drop/file_drop.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding;
import 'package:jaspr/client.dart';

import 'main.client.options.dart';

void main() {
  Jaspr.initializeApp(
    options: defaultClientOptions,
  );

  // Web plugin registration starts window-level drag events immediately.
  // Install the real receiver before any deferred DropTarget is mounted.
  WidgetsFlutterBinding.ensureInitialized();
  DesktopDrop.instance.init();

  runApp(
    const ClientApp(),
  );
}
