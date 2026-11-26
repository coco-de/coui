import 'dart:async';

import 'package:coui_flutter/coui_flutter.dart';
import 'package:coui_flutter/src/components/form/file_input/file_input_directory.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:dir_picker/dir_picker.dart';
import 'package:file_picker/file_picker.dart';

/// A unified cross-platform file input / drop zone component.
///
/// Displays a dashed-border drop area with an upload icon, instructional text,
/// and a file-browse button. Works on all platforms.
///
/// Per Epic #1302, every chrome / dimensional / nested-slot override
/// flows through the single [fileInputStyle] (a [CoreFileInputStyle]).
///
/// Example:
/// ```dart
/// FileInput(
///   onFilesSelected: (files) => print('Selected: ${files.length}'),
///   accept: ['image/*', '.pdf'],
///   multiple: true,
/// )
/// ```
///
/// surface:behind — the drop zone paints its own box directly rather
/// than composing `OutlinedContainer`, so what shows through it is the
/// page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class FileInput extends StatefulWidget
    implements CoreFileInputContract<Widget, ValueChanged<List<XFile>>?> {
  /// Creates a [FileInput].
  const FileInput({
    super.key,
    this.onFilesSelected,
    this.accept,
    this.multiple = false,
    this.allowDirectory = false,
    this.allowSave = false,
    this.enabled = true,
    this.label,
    this.labelMaxLines,
    this.labelOverflow,
    this.hint,
    this.icon,
    this.browseButtonText,
    this.selectedFiles,
    this.name,
    this.fileInputStyle,
  });

  @override
  final ValueChanged<List<XFile>>? onFilesSelected;

  @override
  final List<String>? accept;

  @override
  final bool multiple;

  @override
  final bool allowDirectory;

  @override
  final bool allowSave;

  @override
  final bool enabled;

  @override
  final String? label;

  @override
  final int? labelMaxLines;

  @override
  final CoreTextOverflow? labelOverflow;

  @override
  final String? hint;

  @override
  final Widget? icon;

  @override
  final String? browseButtonText;

  @override
  final List<String>? selectedFiles;

  @override
  final String? name;

  @override
  final CoreFileInputStyle? fileInputStyle;

  /// Returns a copy of this [FileInput] with the given fields replaced.
  /// All fields default to this instance's current value when omitted.
  FileInput copyWith({
    Key? key,
    ValueChanged<List<XFile>>? onFilesSelected,
    List<String>? accept,
    bool? multiple,
    bool? allowDirectory,
    bool? allowSave,
    bool? enabled,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? hint,
    Widget? icon,
    String? browseButtonText,
    List<String>? selectedFiles,
    String? name,
    CoreFileInputStyle? fileInputStyle,
  }) {
    return FileInput(
      key: key ?? this.key,
      onFilesSelected: onFilesSelected ?? this.onFilesSelected,
      accept: accept ?? this.accept,
      multiple: multiple ?? this.multiple,
      allowDirectory: allowDirectory ?? this.allowDirectory,
      allowSave: allowSave ?? this.allowSave,
      enabled: enabled ?? this.enabled,
      label: label ?? this.label,
      labelMaxLines: labelMaxLines ?? this.labelMaxLines,
      labelOverflow: labelOverflow ?? this.labelOverflow,
      hint: hint ?? this.hint,
      icon: icon ?? this.icon,
      browseButtonText: browseButtonText ?? this.browseButtonText,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      name: name ?? this.name,
      fileInputStyle: fileInputStyle ?? this.fileInputStyle,
    );
  }

  @override
  State<FileInput> createState() => _FileInputState();
}

class _FileInputState extends State<FileInput> {
  bool _isDragOver = false;

  /// Whether the pointer is over the drop zone — plain pointer hover, not a
  /// drag: a real file drag is [_isDragOver], which the OS reports through
  /// `DropTarget` and which outranks this.
  bool _isHovered = false;

  /// The files this input received, by name — the data behind the save
  /// affordance.
  ///
  /// [FileInput.selectedFiles] is a display list the caller owns and may
  /// hold names the component never saw (a server-side attachment); only
  /// what actually came through a pick, a drop, or a folder pick is
  /// savable, so it is remembered here. A name that arrives twice keeps
  /// the latest file.
  Map<String, XFile> _received = {};

  void handleBrowse() {
    if (!widget.enabled) return;
    unawaited(_pickFiles());
  }

  /// Opens the native OS file picker dialog and forwards selected files to
  /// [FileInput.onFilesSelected] as [XFile] instances.
  Future<void> _pickFiles() async {
    final extensions = CoreFileInputAccept.extensions(widget.accept);
    final hasExtensionFilter = extensions.isNotEmpty;

    final List<PlatformFile> result;
    if (widget.multiple) {
      result = await FilePicker.pickFiles(
        type: hasExtensionFilter ? .custom : .any,
        allowedExtensions: hasExtensionFilter ? extensions : null,
      );
    } else {
      final file = await FilePicker.pickFile(
        type: hasExtensionFilter ? .custom : .any,
        allowedExtensions: hasExtensionFilter ? extensions : null,
      );
      result = [?file];
    }

    if (!mounted || result.isEmpty) return;

    // The platform owns conversion, including browser blob URLs and lazy I/O.
    _deliverFiles(result.map((file) => file.xFile).toList());
  }

  void _handleHoverChanged(bool hovered) {
    if (_isHovered == hovered) return;
    setState(() => _isHovered = hovered);
  }

  void handleDragEnter() {
    if (!widget.enabled) return;
    setState(() => _isDragOver = true);
  }

  void handleDragExit() {
    setState(() => _isDragOver = false);
  }

  /// Receives OS-dropped files and forwards the ones [FileInput.accept]
  /// admits.
  void handleDrop(List<XFile> files) {
    if (!widget.enabled || files.isEmpty) return;
    setState(() => _isDragOver = false);
    _deliverFiles(files);
  }

  void handlePickDirectory() {
    if (!widget.enabled) return;
    unawaited(_pickDirectory());
  }

  /// Opens the system directory picker and forwards the files it holds to
  /// [FileInput.onFilesSelected].
  Future<void> _pickDirectory() async {
    // Browsers without the File System Access API have no directory dialog
    // and the folder button is disabled there — this guards the path rather
    // than serving it.
    if (!supportsDirectoryPicker) return;

    final location = await DirPicker.pick();
    if (!mounted || location == null) return;

    final files = await filesOfPickedDirectory(location);
    if (!mounted || files.isEmpty) return;

    _deliverFiles(files);
  }

  /// Forwards [files] to [FileInput.onFilesSelected], dropping the ones
  /// [FileInput.accept] does not admit.
  ///
  /// Every intake path — pick, drop, folder — runs through here: the OS
  /// picker enforces `accept` at the dialog, and a drop or a folder pick
  /// has no equivalent gate, so the same rule is applied to all of them.
  /// An intake that admits nothing leaves the selection untouched,
  /// mirroring a cancelled picker.
  void _deliverFiles(List<XFile> files) {
    final accept = widget.accept ?? const <String>[];
    final accepted = <XFile>[
      for (final file in files)
        if (CoreFileInputAccept.matches(
          fileName: file.name,
          accept: accept,
          mimeType: file.mimeType,
        ))
          file,
    ];
    if (accepted.isEmpty) return;

    setState(() {
      _received = {
        ..._received,
        for (final file in accepted) file.name: file,
      };
    });
    widget.onFilesSelected?.call(accepted);
  }

  /// Writes one received file to a location the user picks.
  Future<void> _saveFile(String name) async {
    final file = _received[name];
    if (file == null) return;

    final _ = await CoFileSaver.saveBytes(
      bytes: await file.readAsBytes(),
      fileName: name,
      mimeType: file.mimeType,
    );
  }

  @override
  Widget build(BuildContext context) {
    final resolved = resolveFileInput(
      context,
      fileInputStyle: widget.fileInputStyle,
    );

    final enabled = widget.enabled;
    final borderRadius = resolved.borderRadius;

    // Render-only state selection — the resolver baked every per-state
    // colour / typography / icon slot; this build only picks by the
    // runtime `enabled` / `_isDragOver` / `_isHovered` flags. The border
    // ladder is `disabled > drag-over > hover > idle`: a real drag keeps
    // its `primary` edge under the pointer, and hover never tints the fill
    // (only a drag does).
    final borderColor = !enabled
        ? resolved.borderColorDisabled
        : _isDragOver
        ? resolved.borderColorDragOver
        : _isHovered
        ? resolved.borderColorHover
        : resolved.borderColorIdle;
    final isDragActive = enabled && _isDragOver;
    // A disabled zone paints its opaque `disabledContainer` fill and takes
    // no material (blur / saturation / sheen stay off).
    final backgroundColor = !enabled
        ? resolved.backgroundColorDisabled
        : isDragActive
        ? resolved.backgroundColorDragActive
        : resolved.backgroundColorIdle;
    final surfaceBlur = !enabled
        ? null
        : isDragActive
        ? resolved.surfaceBlurDragActive
        : resolved.surfaceBlurIdle;
    final surfaceSaturation = !enabled
        ? null
        : isDragActive
        ? resolved.surfaceSaturationDragActive
        : resolved.surfaceSaturationIdle;
    final surfaceBackdropBrightness = !enabled
        ? null
        : isDragActive
        ? resolved.surfaceBackdropBrightnessDragActive
        : resolved.surfaceBackdropBrightnessIdle;
    final surfaceSheen = !enabled
        ? null
        : isDragActive
        ? resolved.surfaceSheenDragActive
        : resolved.surfaceSheenIdle;

    // `DropTarget` is the OS-level file drop source — it reports drag
    // enter / exit / done from the platform, so the drop-zone highlight
    // follows a real drag instead of a pointer hover. It is a no-op on
    // platforms without drop support (iOS), and `enable` follows
    // `enabled` so a disabled zone ignores drags entirely.
    return DropTarget(
      onDragEntered: (_) => handleDragEnter(),
      onDragExited: (_) => handleDragExit(),
      onDragDone: (details) => handleDrop(details.files),
      enable: enabled,
      child: Clickable(
        onPressed: enabled ? handleBrowse : null,
        onHover: _handleHoverChanged,
        enabled: enabled,
        clickableStyle: resolved.clickableStyle,
        // `SurfaceBlur` sits inside the click target rather than around it
        // — a no-op when the active branch paints no fill (idle, by
        // design) or the active style states no material.
        child: SurfaceBlur(
          borderRadius: borderRadius,
          surfaceBlur: surfaceBlur,
          surfaceSaturation: surfaceSaturation,
          surfaceBackdropBrightness: surfaceBackdropBrightness,
          surfaceSheen: surfaceSheen,
          refraction: Theme.of(context).surfaceRefraction,
          child: AnimatedContainer(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: borderRadius,
            ),
            curve: resolved.curve,
            duration: resolved.transitionDuration,
            child: CustomPaint(
              painter: _DashedBorderPainter(
                color: borderColor,
                strokeWidth: resolved.borderWidth,
                borderRadius: borderRadius,
                dashLength: resolved.dashLength,
                dashGap: resolved.dashSpacing,
                // A file over the zone turns the dashes solid — the "you
                // can drop here" signal says itself by shape as well as by
                // the `primary` colour. Colour and width stay as they are.
                solid: isDragActive,
              ),
              child: Padding(
                padding: resolved.padding,
                child: Column(
                  mainAxisSize: .min,
                  spacing: resolved.itemSpacing,
                  children: [
                    // Circular icon box — fill follows the drag state.
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: !enabled
                            ? resolved.iconBoxColorDisabled
                            : isDragActive
                            ? resolved.iconBoxColorDragActive
                            : resolved.iconBoxColorIdle,
                        borderRadius: resolved.iconBoxBorderRadius,
                      ),
                      child: SizedBox.square(
                        dimension: resolved.iconBoxSize,
                        child: Center(
                          child:
                              widget.icon ??
                              Icon(
                                LucideIcons.upload,
                                iconStyle: !enabled
                                    ? resolved.iconStyleDisabled
                                    : isDragActive
                                    ? resolved.iconStyleDragActive
                                    : resolved.iconStyleEnabled,
                              ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: .min,
                      spacing: resolved.actionSpacing,
                      children: [
                        Column(
                          mainAxisSize: .min,
                          spacing: resolved.textSpacing,
                          children: [
                            Text(
                              widget.label ??
                                  CoUILocalizations.of(
                                    context,
                                  ).fileInputDropLabel,
                              style: enabled
                                  ? resolved.labelTextStyleEnabled
                                  : resolved.labelTextStyleDisabled,
                              maxLines: widget.labelMaxLines,
                              overflow: widget.labelOverflow?.toValue(),
                            ),
                            if (widget.hint != null)
                              Text(
                                widget.hint!,
                                style: enabled
                                    ? resolved.hintTextStyleEnabled
                                    : resolved.hintTextStyleDisabled,
                              ),
                          ],
                        ),
                        Row(
                          mainAxisSize: .min,
                          spacing: resolved.itemSpacing,
                          children: [
                            Button(
                              onPressed: enabled ? handleBrowse : null,
                              variant: .outline,
                              child: Text(
                                widget.browseButtonText ??
                                    CoUILocalizations.of(
                                      context,
                                    ).fileInputBrowseButton,
                              ),
                            ),
                            if (widget.allowDirectory)
                              Button(
                                onPressed: enabled && supportsDirectoryPicker
                                    ? handlePickDirectory
                                    : null,
                                variant: .outline,
                                child: Text(
                                  CoUILocalizations.of(
                                    context,
                                  ).fileInputFolderButton,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                    if (widget.selectedFiles != null &&
                        widget.selectedFiles!.isNotEmpty)
                      Column(
                        mainAxisSize: .min,
                        children: [
                          for (final file in widget.selectedFiles!)
                            Padding(
                              padding: .only(bottom: resolved.fileItemSpacing),
                              child: Row(
                                mainAxisSize: .min,
                                spacing: resolved.fileItemSpacing,
                                children: [
                                  Icon(
                                    LucideIcons.file,
                                    iconStyle: enabled
                                        ? resolved.fileIconStyleEnabled
                                        : resolved.fileIconStyleDisabled,
                                  ),
                                  Flexible(
                                    child: Text(
                                      file,
                                      style: enabled
                                          ? resolved.fileTextStyleEnabled
                                          : resolved.fileTextStyleDisabled,
                                      overflow: .ellipsis,
                                    ),
                                  ),
                                  if (widget.allowSave &&
                                      _received.containsKey(file))
                                    // The save button draws at 16×16 so
                                    // the glyph sits inside the file row;
                                    // the pointer target still reaches
                                    // the WCAG floor. A miss here lands on
                                    // the drop zone and opens the picker,
                                    // which is the wrong thing entirely.
                                    TouchTarget(
                                      child: Semantics(
                                        button: true,
                                        label: CoUILocalizations.of(
                                          context,
                                        ).fileInputSaveButton,
                                        child: Button(
                                          onPressed: enabled
                                              ? () => unawaited(_saveFile(file))
                                              : null,
                                          variant: .plain,
                                          buttonStyle: resolved.saveButtonStyle,
                                          child: Icon(
                                            LucideIcons.download,
                                            iconStyle: resolved
                                                .saveButtonStyle
                                                .leadingIconStyle,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints a dashed rounded-rect border — or, with [solid], the same
/// rounded rect as one unbroken stroke.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.borderRadius,
    required this.dashLength,
    required this.dashGap,
    required this.solid,
  });

  final Color color;
  final double strokeWidth;
  final BorderRadius borderRadius;
  final double dashLength;
  final double dashGap;
  final bool solid;

  @override
  void paint(Canvas canvas, Size size) {
    // A stroke is centred on its path. Keep the complete declared width
    // inside the allocated border box, as Border.all and the Web SVG do.
    final rrect = RRect.fromRectAndCorners(
      Rect.fromLTWH(0, 0, size.width, size.height),
      topLeft: borderRadius.topLeft,
      topRight: borderRadius.topRight,
      bottomRight: borderRadius.bottomRight,
      bottomLeft: borderRadius.bottomLeft,
    ).deflate(strokeWidth / 2);
    final r = rrect.scaleRadii();
    if (solid) {
      canvas.drawRRect(
        r,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth
          ..style = .stroke,
      );
      return;
    }
    // SVG rect starts at the top-left tangent and travels clockwise.
    // addRRect starts elsewhere, which shifts every dash despite equal tokens.
    final path = Path()
      ..moveTo(r.left + r.tlRadiusX, r.top)
      ..lineTo(r.right - r.trRadiusX, r.top)
      ..arcToPoint(Offset(r.right, r.top + r.trRadiusY), radius: r.trRadius)
      ..lineTo(r.right, r.bottom - r.brRadiusY)
      ..arcToPoint(Offset(r.right - r.brRadiusX, r.bottom), radius: r.brRadius)
      ..lineTo(r.left + r.blRadiusX, r.bottom)
      ..arcToPoint(Offset(r.left, r.bottom - r.blRadiusY), radius: r.blRadius)
      ..lineTo(r.left, r.top + r.tlRadiusY)
      ..arcToPoint(Offset(r.left + r.tlRadiusX, r.top), radius: r.tlRadius)
      ..close();
    final draw = Path();
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = .butt
      ..style = .stroke;
    for (final metric in path.computeMetrics()) {
      var i = 0.0;
      while (i < metric.length) {
        final end = (i + dashLength).clamp(0.0, metric.length);
        final a = metric.getTangentForOffset(i)!;
        final b = metric.getTangentForOffset(end)!;
        final delta = b.position - a.position;
        // Straight dashes have no joins. Use the line primitive for them;
        // keep the extracted contour whenever a dash crosses a corner.
        final straight =
            a.vector == b.vector &&
            ((delta.dy == 0 &&
                    a.vector.dy == 0 &&
                    end - i <= r.width &&
                    delta.dx * a.vector.dx > 0) ||
                (delta.dx == 0 &&
                    a.vector.dx == 0 &&
                    end - i <= r.height &&
                    delta.dy * a.vector.dy > 0));
        if (straight) {
          canvas.drawLine(a.position, b.position, paint);
        } else {
          draw.addPath(metric.extractPath(i, end), .zero);
        }
        i += dashLength + dashGap;
      }
    }
    canvas.drawPath(
      draw,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return color != oldDelegate.color ||
        strokeWidth != oldDelegate.strokeWidth ||
        borderRadius != oldDelegate.borderRadius ||
        dashLength != oldDelegate.dashLength ||
        dashGap != oldDelegate.dashGap ||
        solid != oldDelegate.solid;
  }
}

/// Chain sugar for merging a [CoreFileInputStyle] patch into
/// [FileInput.fileInputStyle] without hand-reconstructing every field.
/// Mirrors the Web `FileInput.withStyle` extension so both platforms read
/// identically.
///
/// Later `.withStyle(...)` calls in a chain win on conflicting fields
/// (matches `CoreFileInputStyle.merge` right-side-wins semantics).
///
/// The getters below are shorter sugar for the same [withStyle] call.
/// Each one is a direct 1:1 alias for a `CoreRadius` / `CoreColors`
/// primitive — the getter *name* is the token name, so `.radius4`
/// always means `CoreRadius.radius4` and `.primary` always means
/// `CoreColors.primary`, no matter which component it's called on.
/// That fixed name-to-value mapping is what makes a short getter safe
/// to reuse across components — a curated nickname (`.rounded`,
/// `.compact`) would silently map to a different value per component,
/// but a primitive-token getter cannot.
///
/// These are intentionally primitive (not semantic) for now: `.radius4`
/// sets [CoreFileInputStyle.borderRadius] and `.primary` sets
/// [CoreFileInputStyle.backgroundColor]. A semantic layer that names
/// these after component-specific intent (decided together with
/// design) is a follow-up once more components adopt this pattern.
///
/// ```dart
/// FileInput(onFilesSelected: onFiles).radius4.surface
/// ```
extension FileInputStyleChain on FileInput {
  /// Returns a copy of this [FileInput] with [patch] merged into
  /// [fileInputStyle] (patch fields win on conflict).
  FileInput withStyle(CoreFileInputStyle patch) => copyWith(
    fileInputStyle: (fileInputStyle ?? const CoreFileInputStyle()).merge(patch),
  );

  // ─── borderRadius (CoreRadius primitive scale) ───────────────────

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius0)`.
  FileInput get radius0 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.zero,
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius2)`.
  FileInput get radius2 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius2),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius4)`.
  FileInput get radius4 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius4),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius6)`.
  FileInput get radius6 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius6),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius8)`.
  FileInput get radius8 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius8),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius10)`.
  FileInput get radius10 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius10),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius12)`.
  FileInput get radius12 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius12),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius14)`.
  FileInput get radius14 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius14),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius16)`.
  FileInput get radius16 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius16),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius20)`.
  FileInput get radius20 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius20),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius24)`.
  FileInput get radius24 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius24),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius28)`.
  FileInput get radius28 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius28),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius32)`.
  FileInput get radius32 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius32),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius36)`.
  FileInput get radius36 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius36),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius40)`.
  FileInput get radius40 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius40),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius48)`.
  FileInput get radius48 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius48),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius56)`.
  FileInput get radius56 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius56),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius64)`.
  FileInput get radius64 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius64),
    ),
  );

  /// `borderRadius: CoreBorderRadius.all(CoreRadius.radius9999)` (pill / full).
  FileInput get radius9999 => withStyle(
    const CoreFileInputStyle(
      borderRadius: CoreBorderRadius.all(CoreRadius.radius9999),
    ),
  );

  // ─── backgroundColor (CoreColors base palette) ───────────────────

  /// `backgroundColor: CoreColor.token(CoreColors.primary)`.
  FileInput get primary => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.primary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.secondary)`.
  FileInput get secondary => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.secondary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.tertiary)`.
  FileInput get tertiary => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.tertiary),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surface)`.
  FileInput get surface => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surface),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.surfaceContainer)`.
  FileInput get surfaceContainer => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.surfaceContainer),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.error)`.
  FileInput get error => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.error),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.success)`.
  FileInput get success => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.success),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.warning)`.
  FileInput get warning => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.warning),
    ),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.info)`.
  FileInput get info => withStyle(
    const CoreFileInputStyle(backgroundColor: CoreColor.token(CoreColors.info)),
  );

  /// `backgroundColor: CoreColor.token(CoreColors.outline)`.
  FileInput get outline => withStyle(
    const CoreFileInputStyle(
      backgroundColor: CoreColor.token(CoreColors.outline),
    ),
  );

  /// `backgroundColor: CoreColor.transparent`.
  FileInput get transparent => withStyle(
    const CoreFileInputStyle(backgroundColor: .transparent),
  );
}
