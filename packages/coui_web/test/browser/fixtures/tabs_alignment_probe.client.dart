import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'tabs_alignment_probe.dart';

void main() {
  Jaspr.initializeApp();
  runApp(tabsAlignmentProbe());
  web.document.documentElement!.setAttribute('data-tabs-hydrated', 'true');
}
