import 'package:coui_flutter/coui_flutter.dart';

void main() {
  runApp(
    CoUIApp(
      theme: ThemeData.fromCore(CoreThemePresets.light),
      home: Center(
        child: Button(
          variant: CoreButtonVariant.primary,
          onPressed: () {},
          child: const Text('Continue'),
        ),
      ),
    ),
  );
}
