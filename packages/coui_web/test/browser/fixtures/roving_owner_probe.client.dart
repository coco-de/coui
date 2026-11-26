import 'dart:convert';

import 'package:jaspr/client.dart';
import 'package:web/web.dart' as web;

import 'roving_owner_probe.dart';

void main() {
  Jaspr.initializeApp();
  runApp(rovingOwnerProbe());
  rovingOwnerOnEvent = () => web.document.documentElement!.setAttribute(
    'data-roving-events',
    jsonEncode(rovingOwnerEvents),
  );
  web.document.documentElement!.setAttribute('data-roving-events', '[]');
  web.document.documentElement!.setAttribute('data-roving-ready', 'true');
}
