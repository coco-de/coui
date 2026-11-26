import 'dart:async';

import 'package:coui_core/coui_core.dart';
import 'package:coui_web/src/base/ui_events.dart';
import 'package:coui_web/src/base/ui_stateful_component.dart';
import 'package:coui_web/src/components/control/button/button.dart';
import 'package:coui_web/src/components/form/file_input/file_input_dom.dart';
import 'package:coui_web/src/components/form/file_input/file_input_style.dart';
import 'package:coui_web/src/components/icon/icon.dart';
import 'package:coui_web/src/components/infra/clickable/clickable.dart';
import 'package:coui_web/src/components/locale/coui_localizations/coui_localizations.dart';
import 'package:coui_web/src/components/text/text.dart';
import 'package:coui_web/src/util/co_file_saver.dart';
import 'package:coui_web/src/util/web_constants.dart';
import 'package:jaspr/dom.dart' hide Gap, Position, css, events;
import 'package:jaspr/jaspr.dart' hide Text;
import 'package:universal_web/web.dart' as web;

/// Unified cross-platform file input for CoUI Web
/// with token-based rendering.
///
/// Renders a drop zone with upload icon, label, browse button, and hint text
/// for visual parity with Flutter FileInput.
///
/// Resolve priority: widget parameter > CoreFileInputTheme > defaults.
///
/// Example:
/// ```dart
/// FileInput(
///   onFilesSelected: (fileList) => print('Files: ${fileList.length}'),
///   accept: ['image/*', '.pdf'],
///   multiple: true,
/// )
/// ```
///
/// surface:behind — the drop zone paints its own box directly on the
/// root `<div>` rather than composing `OutlinedContainer`, so what shows
/// through it is the page it is laid on.
///
/// surface:content — a face in the content layer alongside cards and
/// body panels.
class FileInput extends UiStatefulComponent
    implements CoreFileInputContract<Component, void Function(web.FileList)?> {
  /// Creates a [FileInput].
  const FileInput({
    super.attributes,
    super.classes,
    super.css,
    super.eventHandlers,
    super.id,
    super.key,
    super.onChange,
    super.onClick,
    super.onInput,
    super.onKeyDown,
    super.onKeyUp,
    super.onMouseEnter,
    super.onMouseLeave,
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
  final void Function(web.FileList)? onFilesSelected;

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
  final Component? icon;

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
    UiMouseEventHandler? onClick,
    Map<String, String>? attributes,
    String? classes,
    Styles? css,
    Map<String, List<UiEventHandler>>? eventHandlers,
    String? id,
    UiInputEventHandler? onChange,
    UiInputEventHandler? onInput,
    UiKeyboardEventHandler? onKeyDown,
    UiKeyboardEventHandler? onKeyUp,
    UiMouseEventHandler? onMouseEnter,
    UiMouseEventHandler? onMouseLeave,
    void Function(web.FileList)? onFilesSelected,
    List<String>? accept,
    bool? multiple,
    bool? allowDirectory,
    bool? allowSave,
    bool? enabled,
    String? label,
    int? labelMaxLines,
    CoreTextOverflow? labelOverflow,
    String? hint,
    Component? icon,
    String? browseButtonText,
    List<String>? selectedFiles,
    String? name,
    CoreFileInputStyle? fileInputStyle,
  }) {
    return FileInput(
      key: key ?? this.key,
      onClick: onClick ?? this.onClick,
      attributes: attributes ?? userAttributes,
      classes: classes ?? this.classes,
      css: css ?? this.css,
      eventHandlers: eventHandlers ?? this.eventHandlers,
      id: id ?? this.id,
      onChange: onChange ?? this.onChange,
      onInput: onInput ?? this.onInput,
      onKeyDown: onKeyDown ?? this.onKeyDown,
      onKeyUp: onKeyUp ?? this.onKeyUp,
      onMouseEnter: onMouseEnter ?? this.onMouseEnter,
      onMouseLeave: onMouseLeave ?? this.onMouseLeave,
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

// Page-level counter that yields a stable, unique id per State instance.
int _inputIdCounter = 0;

class _FileInputState extends State<FileInput> {
  bool _isDragOver = false;

  /// The files this input received, by name — the data behind the save
  /// affordance.
  ///
  /// [FileInput.selectedFiles] is a display list the caller owns and may
  /// hold names the component never saw (a server-side attachment); only
  /// what actually came through a pick, a drop, or a folder pick is
  /// savable, so it is remembered here. A name that arrives twice keeps
  /// the latest file.
  Map<String, web.File> _received = {};

  /// Nesting-depth counter for the HTML5 drag. `dragenter` / `dragleave`
  /// bubble up from every descendant (icon / label / button), so a naive
  /// `dragleave → false` flickers the drop-zone highlight whenever the
  /// pointer crosses an inner child boundary. Counting enters (+1) and
  /// leaves (−1) and only clearing at zero keeps `_isDragOver` steady for
  /// the whole time the pointer is anywhere inside the drop zone.
  int _dragDepth = 0;

  late final String _inputId = 'coui-file-input-${_inputIdCounter++}';

  void handleDragEnter(web.Event event) {
    event.preventDefault();
    if (!component.enabled) return;
    _dragDepth++;
    if (_isDragOver) return;
    setState(() {
      _isDragOver = true;
    });
  }

  void handleDragOver(web.Event event) {
    // Must preventDefault to allow drop.
    event.preventDefault();
  }

  void handleDragLeave(web.Event event) {
    event.preventDefault();
    if (!component.enabled) return;
    _dragDepth = _dragDepth > 0 ? _dragDepth - 1 : 0;
    // Still inside a nested child — keep the highlight until the pointer
    // truly leaves the drop zone (depth returns to zero).
    if (_dragDepth > 0) return;
    if (!_isDragOver) return;
    setState(() {
      _isDragOver = false;
    });
  }

  /// Drop handler. Receives the raw `Object` event from jaspr so the
  /// `Object → web.DragEvent` case pattern is a genuine runtime
  /// narrowing (extension-type subtypes can't be narrowed from a
  /// statically-typed `web.Event` — see cautions.md § dart2js).
  void handleDrop(Object event) {
    if (event case final web.DragEvent dragEvent) {
      dragEvent.preventDefault();
      if (!component.enabled || !kIsWeb) return;
      _dragDepth = 0;
      setState(() {
        _isDragOver = false;
      });

      final dataTransfer = dragEvent.dataTransfer;
      if (dataTransfer == null) return;

      unawaited(
        collectAcceptedFiles(
          dataTransfer,
          component.accept ?? const [],
        ).then((files) {
          if (!mounted || files == null) return;
          _remember(files);
          component.onFilesSelected?.call(files);
        }),
      );
    }
  }

  void handleInputChange(web.Event event) {
    if (!component.enabled || !kIsWeb) return;
    if (event.target case final web.HTMLInputElement target) {
      final files = target.files;
      if (files == null) return;
      final accepted = filterFileList(
        files,
        component.accept ?? const [],
      );
      if (accepted == null) return;
      _remember(accepted);
      component.onFilesSelected?.call(accepted);
    }
  }

  /// Handles the composed `Clickable`'s tap / keyboard activation.
  void handleBrowse() {
    if (!kIsWeb) return;
    _openNativeFilePicker();
  }

  /// Opens the system directory picker and forwards the files it holds to
  /// [FileInput.onFilesSelected].
  void handlePickDirectory() {
    if (!kIsWeb) return;
    unawaited(
      pickDirectoryFiles(
        component.accept ?? const [],
      ).then((files) {
        if (!mounted || files == null) return;
        component.onFilesSelected?.call(files);
      }),
    );
  }

  /// Remembers the files an intake delivered so the save affordance has
  /// something to write out.
  void _remember(web.FileList files) {
    setState(() {
      _received = {
        ..._received,
        for (final file in _filesOf(files)) file.name: file,
      };
    });
  }

  /// The files in [files], skipping holes.
  List<web.File> _filesOf(web.FileList files) => [
    for (var i = 0; i < files.length; i++) ?files.item(i),
  ];

  /// Writes one received file out through the browser's download.
  void handleSaveFile(String name) {
    if (!kIsWeb) return;
    final file = _received[name];
    if (file == null) return;

    unawaited(
      bytesOfFile(file).then(
        (bytes) => CoFileSaver.saveBytes(
          bytes: bytes,
          fileName: name,
          mimeType: file.type,
        ),
      ),
    );
  }

  /// Locates the hidden native `<input type="file">` by id and triggers
  /// its picker dialog. Uses case-pattern narrowing so the element cast
  /// stays lint-clean.
  void _openNativeFilePicker() {
    final element = web.window.document.getElementById(_inputId);
    if (element case final web.HTMLInputElement input) {
      input.click();
    }
  }

  @override
  Component build(BuildContext context) {
    final enabled = component.enabled;
    final resolved = resolveFileInput(
      context,
      enabled: enabled,
      isDragOver: _isDragOver,
      scopeId: _inputId,
      fileInputStyle: component.fileInputStyle,
    );
    final rules = resolveFileInputRules(
      context,
      enabled: enabled,
      isDragOver: _isDragOver,
      scopeId: _inputId,
      fileInputStyle: component.fileInputStyle,
    );

    final l10n = CouiLocalizations.of(context);
    final displayLabel = component.label ?? l10n.fileInputDropLabel;
    final displayHint = component.hint;
    final displayButton =
        component.browseButtonText ?? l10n.fileInputBrowseButton;
    final acceptStr = component.accept != null
        ? component.accept!.join(',')
        : null;

    // Hidden native file input for actual file selection.
    final hiddenInput = Component.element(
      tag: 'input',
      attributes: {
        'id': _inputId,
        'type': 'file',
        'class': resolved.hiddenInput.className,
        'tabindex': '-1',
        'aria-hidden': 'true',
        'name': ?component.name,
        if (!enabled) 'disabled': '',
        'accept': ?acceptStr,
        if (component.multiple) 'multiple': '',
      },
      events: {'change': handleInputChange},
    );

    // Upload icon — the unified Icon component (colour + size flow
    // through the resolver's `iconStyle` slot; Icon's own resolver
    // emits them), mirroring the Flutter twin's `LucideIcons.upload`.
    final uploadIcon = div(
      [
        component.icon ??
            Icon(LucideIcons.upload, iconStyle: resolved.iconStyle),
      ],
      classes: resolved.iconBox.className,
      styles: resolved.iconBox.inlineStyles,
    );

    // Label text.
    final labelText = span(
      [
        Text(
          displayLabel,
          maxLines: component.labelMaxLines,
          overflow: component.labelOverflow,
        ),
      ],
      classes: resolved.labelText.className,
      styles: resolved.labelText.inlineStyles,
    );

    // Browse button — uses Button (unified Co component). Its own press is
    // a no-op: the click bubbles to the drop-zone Clickable, which owns the
    // picker, so the button stays the visible half of one affordance.
    final browseButton = Button(
      onPressed: enabled ? () {} : null,
      variant: .outline,
      child: Text(displayButton),
    );

    // Folder button — a real press handler, so its click must not also
    // reach the drop-zone Clickable (that would open the file picker on
    // top of the folder picker). The wrapper is an event boundary, not
    // chrome.
    final folderButton = component.allowDirectory
        ? div(
            [
              Button(
                onPressed: enabled && supportsDirectoryPicker
                    ? handlePickDirectory
                    : null,
                variant: .outline,
                child: Text(l10n.fileInputFolderButton),
              ),
            ],
            events: {
              'click': EventHandlers.createMouseEventHandler(
                (event) => event.stopPropagation(),
              ),
            },
          )
        : null;

    // Hint text.
    final hintWidget = displayHint != null
        ? span(
            [Text(displayHint)],
            classes: resolved.hintText.className,
            styles: resolved.hintText.inlineStyles,
          )
        : null;

    // Selected files list.
    final selectedFilesList =
        component.selectedFiles != null && component.selectedFiles!.isNotEmpty
        ? div(
            [
              for (final file in component.selectedFiles!)
                div(
                  [
                    Icon(
                      LucideIcons.file,
                      iconStyle: resolved.fileIconStyle,
                    ),
                    span(
                      [Text(file)],
                      classes: resolved.fileName.className,
                      styles: resolved.fileName.inlineStyles,
                    ),
                    if (component.allowSave && _received.containsKey(file))
                      // Event boundary: the save press must not also reach
                      // the drop-zone Clickable, which would open the file
                      // picker on top of the download.
                      div(
                        [
                          Button(
                            onPressed: enabled
                                ? () => handleSaveFile(file)
                                : null,
                            variant: .plain,
                            buttonStyle: resolved.saveButtonStyle,
                            // Drawn at 16×16 so the glyph sits inside the
                            // file row; the pointer target still reaches
                            // the WCAG floor. A miss here would land on the
                            // drop zone and open the picker instead.
                            classes: kWebTouchTargetMarker,
                            attributes: {
                              'aria-label': l10n.fileInputSaveButton,
                            },
                            child: Icon(
                              LucideIcons.download,
                              iconStyle:
                                  resolved.saveButtonStyle.leadingIconStyle,
                            ),
                          ),
                        ],
                        events: {
                          'click': EventHandlers.createMouseEventHandler(
                            (event) => event.stopPropagation(),
                          ),
                        },
                      ),
                  ],
                  classes: resolved.fileItem.className,
                  styles: resolved.fileItem.inlineStyles,
                ),
            ],
            classes: resolved.selectedFiles.className,
            styles: resolved.selectedFiles.inlineStyles,
          )
        : null;

    // The drop-zone Clickable owns tap / keyboard activation / cursor /
    // focus ring — mirrors the Swap / large-surface composition
    // (press-shrink and the disabled fade stay off via the drop-zone's
    // partial clickableStyle, since this component already paints
    // dedicated disabled colour tokens). HTML5 drag-and-drop stays
    // native — `dragenter` / `dragover` / `dragleave` / `drop` pass
    // through via `eventHandlers`. The drop-zone visual box (border /
    // background / hover border) lives on the inner `<div>`.
    return Clickable(
      onPressed: enabled ? handleBrowse : null,
      onClick: component.onClick,
      attributes: {
        'aria-label': displayLabel,
        if (!enabled) 'data-disabled': '',
        ...component.componentAttributes,
      },
      classes: component.classes,
      css: component.css,
      eventHandlers: {
        ...component.eventHandlers,
        'dragenter': [handleDragEnter],
        'dragover': [handleDragOver],
        'dragleave': [handleDragLeave],
        'drop': [handleDrop],
      },
      id: component.id,
      onChange: component.onChange,
      onInput: component.onInput,
      onKeyDown: component.onKeyDown,
      onKeyUp: component.onKeyUp,
      onMouseEnter: component.onMouseEnter,
      onMouseLeave: component.onMouseLeave,
      enabled: enabled,
      clickableStyle: resolved.clickableStyle,
      child: div(
        [
          // `<style>` is `display: none`, so it creates no flex item and
          // never picks up the zone gap. Present only when the hover edge
          // cannot ride a class; the default path's markup is unchanged.
          if (rules.css.isNotEmpty)
            Component.element(tag: 'style', children: [RawText(rules.css)]),
          // Dashed border — an SVG overlay stroking with `currentColor`
          // (the root's state / hover text-colour classes recolour it),
          // deterministic across browsers and pattern-tunable through
          // the `dashLength` / `dashSpacing` style slots, unlike CSS
          // `border-dashed` whose pattern is engine-defined.
          Component.element(
            tag: 'svg',
            classes: resolved.dashOverlay.className,
            styles: resolved.dashOverlay.inlineStyles,
            attributes: const {'aria-hidden': 'true'},
            children: [
              Component.element(
                tag: 'rect',
                styles: resolved.dashRect.inlineStyles,
                children: const [],
              ),
            ],
          ),
          hiddenInput,
          uploadIcon,
          div(
            [
              div(
                [labelText, ?hintWidget],
                classes: resolved.textBlock.className,
                styles: resolved.textBlock.inlineStyles,
              ),
              div(
                [browseButton, ?folderButton],
                classes: resolved.buttonsRow.className,
                styles: resolved.buttonsRow.inlineStyles,
              ),
            ],
            classes: resolved.contentGroup.className,
            styles: resolved.contentGroup.inlineStyles,
          ),
          ?selectedFilesList,
        ],
        classes: resolved.root.className,
        styles: resolved.root.inlineStyles,
      ),
    );
  }
}

/// Chain sugar mirroring the Flutter `FileInput.withStyle` extension —
/// merges a [CoreFileInputStyle] patch into [FileInput.fileInputStyle] via
/// the existing [FileInput.copyWith].
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
      borderRadius: CoreBorderRadius.all(CoreRadius.radius0),
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
