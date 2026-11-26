/// Opt-in engine diagnostics.
library;

import 'package:meta/meta.dart';

/// What the engine does when it spots a registration that cannot do what
/// its author intended.
///
/// Silent by default. A design system that printed warnings into every
/// consumer's console would be making a decision that belongs to the app —
/// and the failure it reports is one the app's own author is the only
/// person who can fix. A scope that wants them wires [onWarning] once.
@immutable
class CoreDragDiagnosticsConfig {
  /// Creates a diagnostics configuration.
  const CoreDragDiagnosticsConfig({this.onWarning});

  /// No warnings — the shipped default.
  static const CoreDragDiagnosticsConfig silent = CoreDragDiagnosticsConfig();

  /// Called with a sentence naming what is wrong and what it costs.
  final void Function(String message)? onWarning;

  /// Whether anything would be reported.
  bool get isSilent => onWarning == null;

  /// Reports [message], if anyone is listening.
  void warn(String message) => onWarning?.call(message);

  @override
  bool operator ==(Object other) =>
      other is CoreDragDiagnosticsConfig && other.onWarning == onWarning;

  @override
  int get hashCode => Object.hash(CoreDragDiagnosticsConfig, onWarning);

  @override
  String toString() =>
      'CoreDragDiagnosticsConfig(${isSilent ? 'silent' : 'onWarning'})';
}
