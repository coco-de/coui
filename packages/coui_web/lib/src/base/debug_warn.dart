import 'package:coui_web/src/base/web_dom_utils.dart';

/// Where CoUI's debug-only misuse warnings go.
///
/// The Web counterpart of Flutter reporting a non-fatal `FlutterError`: a
/// warning that names the misuse without tearing the tree down, which an
/// assertion thrown from a lifecycle method would do. It is a replaceable
/// function, like Flutter's `debugPrint`, so a test can collect what would
/// have reached the console.
///
/// Callers invoke it inside `assert(() { … }())`, so release builds never
/// reach it. It carries no per-request state, which is what makes one
/// shared hook safe under concurrent server renders. Defaults to
/// `console.warn` in the browser and to nothing on the server.
void Function(String message) debugWarn = consoleWarn;
