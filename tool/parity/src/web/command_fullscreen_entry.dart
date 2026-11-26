/// Hydrated shipped Command fixture for geometry, paint and caller callbacks.
library;

import 'dart:js_interop';

import 'package:coui_web/coui_web.dart';
import 'package:jaspr/client.dart' as client show runApp;

@JS('couiCommandDismissals')
external set _dismissals(JSFunction value);

void main() {
  final counts = <String, int>{};
  _dismissals = ((String key) => counts[key] ?? 0).toJS;
  client.runApp(
    CoUIWeb(
      theme: .coui,
      child: div([
        for (final brightness in CoreBrightness.values)
          BrightnessScope(
            brightness: brightness,
            child: div([
              for (final size in CoreCommandSize.values)
                div(
                  [
                    Command(
                      groups: const [],
                      emptyLabel: '',
                      emptyDescription: '',
                      presentation: .fullscreen,
                      size: size,
                      autofocus: false,
                      onDismiss: () => counts.update(
                        '${brightness.name}-${size.name}',
                        (count) => count + 1,
                        ifAbsent: () => 1,
                      ),
                    ),
                  ],
                  id: '${brightness.name}-${size.name}',
                  styles: const Styles(raw: {'height': '90px'}),
                ),
            ]),
          ),
        div(
          [
            Command(
              groups: const [],
              emptyLabel: '',
              emptyDescription: '',
              presentation: .fullscreen,
              autofocus: false,
              onDismiss: () {},
              commandStyle: const CoreCommandStyle(
                backIconStyle: CoreIconStyle(
                  size: 22,
                  color: CoreColor(0xff123456),
                ),
              ),
            ),
          ],
          id: 'override',
          styles: const Styles(raw: {'height': '90px'}),
        ),
      ]),
    ),
  );
}
