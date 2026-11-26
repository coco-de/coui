/// Platform-independent contract for file input components.
///
/// Defines the interface that all file input implementations
/// (Flutter, Web) must satisfy.
library;

import 'package:coui_core/src/component/contracts/file_input/file_input_style.dart';
import 'package:coui_core/src/typography/text_overflow.dart';

/// Contract for a file input / file drop zone component.
///
/// [W] is the platform widget type (e.g., `Widget` for Flutter,
/// `Component` for Web).
/// [FilesCb] is the platform-specific files callback type.
abstract interface class CoreFileInputContract<W, FilesCb> {
  /// Callback when files are selected.
  FilesCb get onFilesSelected;

  /// Accepted file types (e.g., `['image/*', '.pdf']`).
  List<String>? get accept;

  /// Whether multiple file selection is allowed.
  bool get multiple;

  /// Whether the folder-pick affordance is offered.
  ///
  /// When true the drop zone gains a folder button that picks a directory
  /// and hands its files to [onFilesSelected] — the drop zone's `accept`
  /// list filters them the same way a pick or a drop is filtered.
  bool get allowDirectory;

  /// Whether the per-file save affordance is offered.
  ///
  /// When true, selected-file rows whose data the component holds gain a
  /// save button that writes the file to a location the user picks.
  bool get allowSave;

  /// Whether the input is enabled.
  bool get enabled;

  /// Primary label text.
  String? get label;

  /// Maximum number of lines for [label] before it overflows.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  int? get labelMaxLines;

  /// How [label] overflow is handled once [labelMaxLines] is reached.
  ///
  /// `null` (default) keeps the current wrap-forever behaviour.
  CoreTextOverflow? get labelOverflow;

  /// Hint text.
  String? get hint;

  /// Custom icon widget.
  W? get icon;

  /// Browse button text.
  String? get browseButtonText;

  /// Currently selected file names for display.
  List<String>? get selectedFiles;

  /// Form field name.
  String? get name;

  /// Per-instance composite chrome / dimensional / slot style.
  ///
  /// Resolves through the nested-merge chain:
  ///
  /// ```text
  /// design system default
  ///   → CoreFileInputTheme.style
  ///   → parent component slot override
  ///   → widget.fileInputStyle
  /// ```
  CoreFileInputStyle? get fileInputStyle;
}
