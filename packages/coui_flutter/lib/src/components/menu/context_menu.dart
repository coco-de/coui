import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

/// Theme for [ContextMenuPopup] and context menu widgets.
class ContextMenuTheme {
  /// Creates a [ContextMenuTheme].
  const ContextMenuTheme({this.surfaceBlur, this.surfaceOpacity});

  /// Surface opacity for the popup container.
  final double? surfaceOpacity;

  /// Surface blur for the popup container.
  final double? surfaceBlur;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ContextMenuTheme &&
        other.surfaceOpacity == surfaceOpacity &&
        other.surfaceBlur == surfaceBlur;
  }

  @override
  int get hashCode => Object.hash(surfaceOpacity, surfaceBlur);
}

class DesktopEditableTextContextMenu extends StatelessWidget {
  const DesktopEditableTextContextMenu({
    required this.anchorContext,
    required this.editableTextState,
    super.key,
    this.undoHistoryController,
  });

  final BuildContext anchorContext;
  final EditableTextState editableTextState;

  final UndoHistoryController? undoHistoryController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final localizations = CoUILocalizations.of(context);
    final undoHistoryController = this.undoHistoryController;
    final contextMenuButtonItems = List.of(
      editableTextState.contextMenuButtonItems,
    );

    ContextMenuButtonItem? take(ContextMenuButtonType type) {
      final item = contextMenuButtonItems
          .where((element) => element.type == type)
          .firstOrNull;
      if (item != null) {
        contextMenuButtonItems.remove(item);
      }

      return item;
    }

    final cutButton = take(ContextMenuButtonType.cut);
    final copyButton = take(ContextMenuButtonType.copy);
    final pasteButton = take(ContextMenuButtonType.paste);
    final selectAllButton = take(ContextMenuButtonType.selectAll);
    final shareButton = take(ContextMenuButtonType.share);
    final searchWebButton = take(ContextMenuButtonType.searchWeb);
    final liveTextInput = take(ContextMenuButtonType.liveTextInput);
    final cutButtonWidget = MenuButton(
      onPressed: (context) {
        cutButton?.onPressed?.call();
      },
      enabled: cutButton != null,
      trailing: const MenuShortcut(
        activator: SingleActivator(LogicalKeyboardKey.keyX, control: true),
      ),
      child: Text(localizations.menuCut),
    );
    final copyButtonWidget = MenuButton(
      onPressed: (context) {
        copyButton?.onPressed?.call();
      },
      enabled: copyButton != null,
      trailing: const MenuShortcut(
        activator: SingleActivator(LogicalKeyboardKey.keyC, control: true),
      ),
      child: Text(localizations.menuCopy),
    );
    final pasteButtonWidget = MenuButton(
      onPressed: (context) {
        pasteButton?.onPressed?.call();
      },
      enabled: pasteButton != null,
      trailing: const MenuShortcut(
        activator: SingleActivator(LogicalKeyboardKey.keyV, control: true),
      ),
      child: Text(localizations.menuPaste),
    );
    final selectAllButtonWidget = MenuButton(
      onPressed: (context) {
        /// Somehow, we lost focus upon context menu open.
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          selectAllButton?.onPressed?.call();
        });
      },
      enabled: selectAllButton != null,
      trailing: const MenuShortcut(
        activator: SingleActivator(LogicalKeyboardKey.keyA, control: true),
      ),
      child: Text(localizations.menuSelectAll),
    );
    final extras = <MenuItem>[];
    if (shareButton != null) {
      extras.add(
        MenuButton(
          onPressed: (context) {
            shareButton.onPressed?.call();
          },
          child: Text(localizations.menuShare),
        ),
      );
    }
    if (searchWebButton != null) {
      extras.add(
        MenuButton(
          onPressed: (context) {
            searchWebButton.onPressed?.call();
          },
          child: Text(localizations.menuSearchWeb),
        ),
      );
    }
    if (liveTextInput != null) {
      extras.add(
        MenuButton(
          onPressed: (context) {
            liveTextInput.onPressed?.call();
          },
          child: Text(localizations.menuLiveTextInput),
        ),
      );
    }

    return undoHistoryController == null
        ? TextFieldTapRegion(
            child: CoUIUI(
              child: ContextMenuPopup(
                anchorContext: anchorContext,
                anchorSize: Size.zero,
                position:
                    editableTextState.contextMenuAnchors.primaryAnchor +
                    const Offset(8, -8) * scaling,
                children: [
                  cutButtonWidget,
                  copyButtonWidget,
                  pasteButtonWidget,
                  selectAllButtonWidget,
                  if (extras.isNotEmpty) const MenuDivider(),
                  ...extras,
                ],
              ),
            ),
          )
        : TextFieldTapRegion(
            child: CoUIUI(
              child: AnimatedBuilder(
                animation: undoHistoryController,
                builder: (context, child) {
                  return ContextMenuPopup(
                    anchorContext: anchorContext,
                    position:
                        editableTextState.contextMenuAnchors.primaryAnchor +
                        const Offset(8, -8) * scaling,
                    children: [
                      MenuButton(
                        onPressed: (context) {
                          undoHistoryController.undo();
                        },
                        enabled: undoHistoryController.value.canUndo,
                        trailing: const MenuShortcut(
                          activator: SingleActivator(
                            LogicalKeyboardKey.keyZ,
                            control: true,
                          ),
                        ),
                        child: const Text('Undo'),
                      ),
                      MenuButton(
                        onPressed: (context) {
                          undoHistoryController.redo();
                        },
                        enabled: undoHistoryController.value.canRedo,
                        trailing: const MenuShortcut(
                          activator: SingleActivator(
                            LogicalKeyboardKey.keyZ,
                            control: true,
                            shift: true,
                          ),
                        ),
                        child: const Text('Redo'),
                      ),
                      const MenuDivider(),
                      cutButtonWidget,
                      copyButtonWidget,
                      pasteButtonWidget,
                      selectAllButtonWidget,
                      if (extras.isNotEmpty) const MenuDivider(),
                      ...extras,
                    ],
                  );
                },
              ),
            ),
          );
  }
}

/// Mostly same as desktop, but direction is horizontal, and shows no menu shortcuts.
class MobileEditableTextContextMenu extends StatelessWidget {
  const MobileEditableTextContextMenu({
    required this.anchorContext,
    required this.editableTextState,
    super.key,
    this.undoHistoryController,
  });

  final BuildContext anchorContext;
  final EditableTextState editableTextState;

  final UndoHistoryController? undoHistoryController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    final localizations = CoUILocalizations.of(context);
    final undoHistoryController = this.undoHistoryController;
    final contextMenuButtonItems = List.of(
      editableTextState.contextMenuButtonItems,
    );

    ContextMenuButtonItem? take(ContextMenuButtonType type) {
      final item = contextMenuButtonItems
          .where((element) => element.type == type)
          .firstOrNull;
      if (item != null) {
        contextMenuButtonItems.remove(item);
      }

      return item;
    }

    final deleteButton = take(ContextMenuButtonType.delete);
    final cutButton = take(ContextMenuButtonType.cut);
    final copyButton = take(ContextMenuButtonType.copy);
    final pasteButton = take(ContextMenuButtonType.paste);
    final selectAllButton = take(ContextMenuButtonType.selectAll);
    final shareButton = take(ContextMenuButtonType.share);
    final searchWebButton = take(ContextMenuButtonType.searchWeb);
    final liveTextInput = take(ContextMenuButtonType.liveTextInput);

    final modificationCategory = <MenuItem>[];
    if (cutButton != null) {
      modificationCategory.add(
        MenuButton(
          onPressed: (context) {
            cutButton.onPressed?.call();
          },
          child: Text(localizations.menuCut),
        ),
      );
    }
    if (copyButton != null) {
      modificationCategory.add(
        MenuButton(
          onPressed: (context) {
            copyButton.onPressed?.call();
          },
          child: Text(localizations.menuCopy),
        ),
      );
    }
    if (pasteButton != null) {
      modificationCategory.add(
        MenuButton(
          onPressed: (context) {
            pasteButton.onPressed?.call();
          },
          child: Text(localizations.menuPaste),
        ),
      );
    }
    if (selectAllButton != null) {
      modificationCategory.add(
        MenuButton(
          onPressed: (context) {
            selectAllButton.onPressed?.call();
          },
          child: Text(localizations.menuSelectAll),
        ),
      );
    }

    final destructiveCategory = <MenuItem>[];
    if (deleteButton != null) {
      destructiveCategory.add(
        MenuButton(
          onPressed: (context) {
            deleteButton.onPressed?.call();
          },
          child: Text(localizations.menuDelete),
        ),
      );
    }

    if (shareButton != null) {
      destructiveCategory.add(
        MenuButton(
          onPressed: (context) {
            shareButton.onPressed?.call();
          },
          child: Text(localizations.menuShare),
        ),
      );
    }

    if (searchWebButton != null) {
      destructiveCategory.add(
        MenuButton(
          onPressed: (context) {
            searchWebButton.onPressed?.call();
          },
          child: Text(localizations.menuSearchWeb),
        ),
      );
    }

    if (liveTextInput != null) {
      destructiveCategory.add(
        MenuButton(
          onPressed: (context) {
            liveTextInput.onPressed?.call();
          },
          child: Text(localizations.menuLiveTextInput),
        ),
      );
    }

    final primaryAnchor =
        (editableTextState.contextMenuAnchors.secondaryAnchor ??
            editableTextState.contextMenuAnchors.primaryAnchor) +
        const Offset(-8, 8) * scaling;
    if (undoHistoryController == null) {
      final categories = <List<MenuItem>>[
        if (modificationCategory.isNotEmpty) modificationCategory,
        if (destructiveCategory.isNotEmpty) destructiveCategory,
      ];

      return TextFieldTapRegion(
        child: CoUIUI(
          child: ContextMenuPopup(
            anchorContext: anchorContext,
            anchorSize: Size.zero,
            direction: Axis.horizontal,
            position: primaryAnchor,
            children: categories
                .expand((element) => [...element])
                .toList()
                .joinSeparator(const MenuDivider()),
          ),
        ),
      );
    }

    return TextFieldTapRegion(
      child: CoUIUI(
        child: AnimatedBuilder(
          animation: undoHistoryController,
          builder: (context, child) {
            final historyCategory = <MenuItem>[];
            if (undoHistoryController.value.canUndo) {
              historyCategory.add(
                MenuButton(
                  onPressed: (context) {
                    undoHistoryController.undo();
                  },
                  enabled: undoHistoryController.value.canUndo,
                  child: Text(localizations.menuUndo),
                ),
              );
            }
            if (undoHistoryController.value.canRedo) {
              historyCategory.add(
                MenuButton(
                  onPressed: (context) {
                    undoHistoryController.redo();
                  },
                  enabled: undoHistoryController.value.canRedo,
                  child: Text(localizations.menuRedo),
                ),
              );
            }
            final categories = <List<MenuItem>>[
              if (historyCategory.isNotEmpty) historyCategory,
              if (modificationCategory.isNotEmpty) modificationCategory,
              if (destructiveCategory.isNotEmpty) destructiveCategory,
            ];

            return ContextMenuPopup(
              anchorContext: anchorContext,
              anchorSize: Size.zero,
              direction: Axis.horizontal,
              position: primaryAnchor,
              children: categories
                  .expand((element) => [...element])
                  .toList()
                  .joinSeparator(const MenuDivider()),
            );
          },
        ),
      ),
    );
  }
}

Widget buildEditableTextContextMenu(
  BuildContext innerContext,
  EditableTextState editableTextState, [
  UndoHistoryController? undoHistoryController,
]) {
  final platform = Theme.of(innerContext).platform;

  switch (platform) {
    case TargetPlatform.android:
    case TargetPlatform.iOS:
      return MobileEditableTextContextMenu(
        anchorContext: innerContext,
        editableTextState: editableTextState,
        undoHistoryController: undoHistoryController,
      );

    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return DesktopEditableTextContextMenu(
        anchorContext: innerContext,
        editableTextState: editableTextState,
        undoHistoryController: undoHistoryController,
      );
  }
}

class ContextMenu extends StatefulWidget {
  const ContextMenu({
    this.behavior = HitTestBehavior.translucent,
    required this.child,
    this.direction = Axis.vertical,
    this.enabled = true,
    required this.items,
    super.key,
  });

  final Widget child;
  final List<MenuItem> items;
  final HitTestBehavior behavior;
  final Axis direction;

  final bool enabled;

  @override
  State<ContextMenu> createState() => _ContextMenuState();
}

class _ContextMenuState extends State<ContextMenu> {
  late ValueNotifier<List<MenuItem>> _children;

  @override
  void initState() {
    super.initState();
    _children = ValueNotifier(widget.items);
  }

  @override
  void didUpdateWidget(covariant ContextMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(widget.items, oldWidget.items)) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        if (mounted) _children.value = widget.items;
      });
    }
  }

  @override
  void dispose() {
    _children.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final platform = Theme.of(context).platform;
    final enableLongPress =
        platform == TargetPlatform.iOS ||
        platform == TargetPlatform.android ||
        platform == TargetPlatform.fuchsia;

    return GestureDetector(
      onSecondaryTapDown: widget.enabled
          ? (details) {
              _showContextMenu(
                context,
                details.globalPosition,
                _children,
                widget.direction,
              );
            }
          : null,
      onLongPressStart: enableLongPress && widget.enabled
          ? (details) {
              _showContextMenu(
                context,
                details.globalPosition,
                _children,
                widget.direction,
              );
            }
          : null,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

Future<void> _showContextMenu(
  BuildContext context,
  Offset position,
  ValueListenable<List<MenuItem>> children,
  Axis direction,
) {
  final key = GlobalKey<OverlayHandlerStateMixin>();
  final theme = Theme.of(context);
  final overlayManager = OverlayManager.of(context);

  return overlayManager
      .showMenu<void>(
        key: key,
        alignment: Alignment.topLeft,
        anchorAlignment: Alignment.topRight,
        consumeOutsideTaps: false,
        context: context,
        dismissBackdropFocus: false,
        follow: false,
        overlayBarrier: OverlayBarrier(
          barrierColor: const Color(0xB2000000),
          borderRadius: BorderRadius.circular(theme.radiusMd),
        ),
        position: position + const Offset(8, 0),
        regionGroupId: key,
        builder: (context) {
          return AnimatedBuilder(
            animation: children,
            builder: (context, child) {
              final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(
                context,
              );

              return ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 192),
                child: MenuGroup(
                  direction: direction,
                  itemPadding: isSheetOverlay
                      ? const EdgeInsets.symmetric(horizontal: 8) *
                            theme.scaling
                      : EdgeInsets.zero,
                  onDismissed: () {
                    closeOverlay<void>(context);
                  },
                  regionGroupId: key,
                  subMenuOffset: const Offset(8, -4),
                  builder: (context, children) {
                    final compTheme = ComponentTheme.maybeOf<ContextMenuTheme>(
                      context,
                    );

                    return MenuPopup(
                      surfaceOpacity: compTheme?.surfaceOpacity,
                      surfaceBlur: compTheme?.surfaceBlur,
                      children: children,
                    );
                  },
                  children: children.value,
                ),
              );
            },
          );
        },
      )
      .future;
}

class ContextMenuPopup extends StatelessWidget {
  const ContextMenuPopup({
    required this.anchorContext,
    this.anchorSize,
    required this.children,
    this.direction = Axis.vertical,
    super.key,
    this.onTickFollow,
    required this.position,
    this.themes,
  });

  final BuildContext anchorContext;
  final Offset position;
  final List<MenuItem> children;
  final CapturedThemes? themes;
  final Axis direction;
  final ValueChanged<PopoverOverlayWidgetState>? onTickFollow;
  final Size? anchorSize;

  @override
  Widget build(BuildContext context) {
    return AnimatedValueBuilder<double>.animation(
      initialValue: 0.0,
      value: 1.0,
      duration: const Duration(milliseconds: 100),
      builder: (context, animation) {
        final isSheetOverlay = SheetOverlayHandler.isSheetOverlay(context);

        return PopoverOverlayWidget(
          alignment: Alignment.topLeft,
          anchorAlignment: Alignment.topRight,
          anchorContext: anchorContext,
          anchorSize: anchorSize,
          animation: animation,
          follow: onTickFollow != null,
          onTickFollow: onTickFollow,
          position: position,
          themes: themes,
          builder: (context) {
            final theme = Theme.of(context);

            return LimitedBox(
              maxWidth: theme.scaling * 192,
              child: MenuGroup(
                direction: direction,
                itemPadding: isSheetOverlay
                    ? const EdgeInsets.symmetric(horizontal: 8) * theme.scaling
                    : EdgeInsets.zero,
                builder: (context, children) {
                  final compTheme = ComponentTheme.maybeOf<ContextMenuTheme>(
                    context,
                  );

                  return MenuPopup(
                    surfaceOpacity: compTheme?.surfaceOpacity,
                    surfaceBlur: compTheme?.surfaceBlur,
                    children: children,
                  );
                },
                children: children,
              ),
            );
          },
        );
      },
    );
  }
}
