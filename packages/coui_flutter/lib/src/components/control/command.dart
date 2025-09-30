import 'package:flutter/services.dart';
import 'package:coui_flutter/coui_flutter.dart';

typedef CommandBuilder =
    Stream<List<Widget>> Function(
      BuildContext context,
      String? query,
    );

typedef ErrorWidgetBuilder =
    Widget Function(
      BuildContext context,
      Object error,
      StackTrace? stackTrace,
    );

class CommandEmpty extends StatelessWidget {
  const CommandEmpty({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = CoUILocalizations.of(context);

    return Center(
      child: Text(localizations.commandEmpty).withPadding(vertical: 24).small(),
    );
  }
}

Future<T?> showCommandDialog<T>({
  bool autofocus = true,
  required CommandBuilder builder,
  BoxConstraints? constraints,
  required BuildContext context,
  Duration debounceDuration = const Duration(milliseconds: 500),
  WidgetBuilder? emptyBuilder,
  ErrorWidgetBuilder? errorBuilder,
  WidgetBuilder? loadingBuilder,
  double? surfaceBlur,
  double? surfaceOpacity,
}) {
  return showDialog(
    builder: (context) {
      final theme = Theme.of(context);
      final scaling = theme.scaling;
      surfaceOpacity ??= theme.surfaceOpacity;
      surfaceBlur ??= theme.surfaceBlur;

      return ConstrainedBox(
        constraints:
            constraints ??
            const BoxConstraints.tightFor(height: 349, width: 510) * scaling,
        child: ModalBackdrop(
          borderRadius: subtractByBorder(theme.borderRadiusXxl, scaling * 1),
          surfaceClip: ModalBackdrop.shouldClipSurface(surfaceOpacity),
          child: Command(
            autofocus: autofocus,
            builder: builder,
            debounceDuration: debounceDuration,
            emptyBuilder: emptyBuilder,
            errorBuilder: errorBuilder,
            loadingBuilder: loadingBuilder,
            surfaceBlur: surfaceBlur,
            surfaceOpacity: surfaceOpacity,
          ),
        ),
      );
    },
    context: context,
  );
}

/// Interactive command palette with search functionality and dynamic results.
///
/// A powerful search and command interface that provides real-time filtering
/// of commands or items based on user input. Features debounced search,
/// keyboard navigation, and customizable result presentation.
///
/// ## Features
///
/// - **Real-time search**: Dynamic filtering with configurable debounce timing
/// - **Keyboard navigation**: Full arrow key and Enter/Escape support
/// - **Async data loading**: Stream-based results with loading and error states
/// - **Customizable states**: Custom builders for empty, loading, and error states
/// - **Auto-focus**: Optional automatic focus on the search input
/// - **Accessibility**: Screen reader friendly with proper focus management
///
/// The command palette is commonly used for:
/// - Quick action selection (Cmd+K style interfaces)
/// - Searchable option lists
/// - Dynamic content filtering
/// - Command-driven workflows
///
/// Example:
/// ```dart
/// Command(
///   autofocus: true,
///   debounceDuration: Duration(milliseconds: 300),
///   builder: (context, query) async* {
///     final results = await searchService.search(query);
///     yield results.map((item) => CommandItem(
///       onSelected: () => handleCommand(item),
///       child: Text(item.title),
///     )).toList();
///   },
///   emptyBuilder: (context) => Text('No results found'),
/// );
/// ```
class Command extends StatefulWidget {
  /// Creates a [Command] palette.
  ///
  /// The [builder] function receives the current search query and should return
  /// a stream of widgets representing the filtered results.
  ///
  /// Parameters:
  /// - [builder] (CommandBuilder, required): async builder for search results
  /// - [autofocus] (bool, default: true): whether to auto-focus search input
  /// - [debounceDuration] (Duration, default: 500ms): debounce delay for search
  /// - [emptyBuilder] (WidgetBuilder?, optional): custom widget for empty state
  /// - [errorBuilder] (ErrorWidgetBuilder?, optional): custom error display
  /// - [loadingBuilder] (WidgetBuilder?, optional): custom loading indicator
  /// - [surfaceOpacity] (double?, optional): surface opacity override
  /// - [surfaceBlur] (double?, optional): surface blur override
  /// - [searchPlaceholder] (Widget?, optional): placeholder text for search input
  ///
  /// Example:
  /// ```dart
  /// Command(
  ///   autofocus: false,
  ///   debounceDuration: Duration(milliseconds: 200),
  ///   searchPlaceholder: Text('Search commands...'),
  ///   builder: (context, query) async* {
  ///     final filtered = commands.where((cmd) =>
  ///       cmd.name.toLowerCase().contains(query?.toLowerCase() ?? '')
  ///     );
  ///     yield filtered.map((cmd) => CommandItem(
  ///       child: Text(cmd.name),
  ///       onSelected: () => cmd.execute(),
  ///     )).toList();
  ///   },
  /// )
  /// ```
  const Command({
    this.autofocus = true,
    required this.builder,
    this.debounceDuration = const Duration(milliseconds: 500),
    this.emptyBuilder,
    this.errorBuilder,
    super.key,
    this.loadingBuilder,
    this.searchPlaceholder,
    this.surfaceBlur,
    this.surfaceOpacity,
  });

  final bool autofocus;
  final CommandBuilder builder;
  final Duration
  debounceDuration; // debounce is used to prevent too many requests
  final WidgetBuilder? emptyBuilder;
  final ErrorWidgetBuilder? errorBuilder;
  final WidgetBuilder? loadingBuilder;
  final double? surfaceOpacity;
  final double? surfaceBlur;

  final Widget? searchPlaceholder;

  @override
  State<Command> createState() => _CommandState();
}

class _Query {
  const _Query({this.query, required this.stream});
  final Stream<List<Widget>> stream;

  final String? query;
}

class _CommandState extends State<Command> {
  final _controller = TextEditingController();
  _Query _currentRequest;

  int requestCount = 0;

  @override
  void initState() {
    super.initState();
    _currentRequest = _Query(stream: _request(context, null));
    _controller.addListener(() {
      String? newQuery = _controller.text;
      if (newQuery.isEmpty) newQuery = null;
      if (newQuery != _currentRequest.query) {
        setState(() {
          _currentRequest = _Query(
            query: newQuery,
            stream: _request(context, newQuery),
          );
        });
      }
    });
  }

  Stream<List<Widget>> _request(BuildContext context, String? query) async* {
    final currentRequest = requestCount += 1;
    yield [];
    await Future.delayed(widget.debounceDuration);
    if (!context.mounted || currentRequest != requestCount) return;
    final resultItems = <Widget>[];
    await for (final items in widget.builder(context, query)) {
      if (currentRequest != requestCount) continue;
      // append items
      resultItems.addAll(items);
      yield resultItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    final localization = CoUILocalizations.of(context);

    return SubFocusScope(
      builder: (context, state) {
        return Actions(
          actions: {
            NextItemIntent: CallbackAction<NextItemIntent>(
              onInvoke: (intent) {
                state.nextFocus();

                return null;
              },
            ),
            PreviousItemIntent: CallbackAction<PreviousItemIntent>(
              onInvoke: (intent) {
                state.nextFocus(TraversalDirection.up);

                return null;
              },
            ),
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                state.invokeActionOnFocused(intent);

                return null;
              },
            ),
          },
          child: Shortcuts(
            shortcuts: {
              LogicalKeySet(LogicalKeyboardKey.arrowUp):
                  const PreviousItemIntent(),
              LogicalKeySet(LogicalKeyboardKey.arrowDown):
                  const NextItemIntent(),
              LogicalKeySet(LogicalKeyboardKey.enter): const ActivateIntent(),
            },
            child: IntrinsicWidth(
              child: OutlinedContainer(
                clipBehavior: Clip.hardEdge,
                surfaceBlur: widget.surfaceBlur ?? theme.surfaceBlur,
                surfaceOpacity: widget.surfaceOpacity ?? theme.surfaceOpacity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ComponentTheme(
                      data: const FocusOutlineTheme(
                        border: Border.fromBorderSide(BorderSide.none),
                      ),
                      child: TextField(
                        autofocus: widget.autofocus,
                        border: const Border.fromBorderSide(BorderSide.none),
                        borderRadius: BorderRadius.zero,
                        controller: _controller,
                        features: [
                          InputFeature.leading(
                            const Icon(
                              LucideIcons.search,
                            ).iconSmall().iconMutedForeground(),
                          ),
                          if (canPop)
                            InputFeature.trailing(
                              GhostButton(
                                density: ButtonDensity.iconDense,
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Icon(LucideIcons.x).iconSmall(),
                              ),
                            ),
                        ],
                        placeholder:
                            widget.searchPlaceholder ??
                            Text(CoUILocalizations.of(context).commandSearch),
                      ),
                    ),
                    const Divider(),
                    Expanded(
                      child: StreamBuilder(
                        builder: (context, snapshot) {
                          if (snapshot.hasData) {
                            final items = List<Widget>.of(snapshot.data!);
                            if (snapshot.connectionState ==
                                ConnectionState.active) {
                              items.add(
                                IconTheme.merge(
                                  data: IconThemeData(
                                    color: theme.colorScheme.mutedForeground,
                                  ),
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ).withPadding(vertical: theme.scaling * 24),
                                ),
                              );
                            } else if (items.isEmpty) {
                              return widget.emptyBuilder?.call(context) ??
                                  const CommandEmpty();
                            }

                            return ListView.separated(
                              itemBuilder: (context, index) {
                                return items[index];
                              },
                              itemCount: items.length,
                              padding: EdgeInsets.symmetric(
                                vertical: theme.scaling * 2,
                              ),
                              separatorBuilder: (context, index) =>
                                  const Divider(),
                              shrinkWrap: true,
                            );
                          }

                          return widget.loadingBuilder?.call(context) ??
                              const Center(
                                child: CircularProgressIndicator(),
                              ).withPadding(vertical: theme.scaling * 24);
                        },
                        stream: _currentRequest.stream,
                      ),
                    ),
                    const Divider(),
                    Container(
                      color: theme.colorScheme.card,
                      padding: EdgeInsets.symmetric(
                        horizontal: theme.scaling * 12,
                        vertical: theme.scaling * 6,
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          spacing: theme.scaling * 8,
                          children: [
                            const KeyboardDisplay.fromActivator(
                              activator: SingleActivator(
                                LogicalKeyboardKey.arrowUp,
                              ),
                            ).xSmall,
                            Text(localization.commandMoveUp).muted.small,
                            const VerticalDivider(),
                            const KeyboardDisplay.fromActivator(
                              activator: SingleActivator(
                                LogicalKeyboardKey.arrowDown,
                              ),
                            ).xSmall,
                            Text(localization.commandMoveDown).muted.small,
                            const VerticalDivider(),
                            const KeyboardDisplay.fromActivator(
                              activator: SingleActivator(
                                LogicalKeyboardKey.enter,
                              ),
                            ).xSmall,
                            Text(localization.commandActivate).muted.small,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class CommandCategory extends StatelessWidget {
  const CommandCategory({required this.children, super.key, this.title});

  final List<Widget> children;

  final Widget? title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          title!
              .withPadding(
                horizontal: theme.scaling * 8,
                vertical: theme.scaling * 6,
              )
              .medium()
              .xSmall()
              .muted(),
        ...children,
      ],
    ).withPadding(all: theme.scaling * 4);
  }
}

class CommandItem extends StatefulWidget {
  const CommandItem({
    super.key,
    this.leading,
    this.onTap,
    required this.title,
    this.trailing,
  });

  final Widget? leading;
  final Widget title;
  final Widget? trailing;

  final VoidCallback? onTap;

  @override
  State<CommandItem> createState() => _CommandItemState();
}

class _CommandItemState extends State<CommandItem> {
  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);

    return Actions(
      actions: {
        ActivateIntent: CallbackAction<Intent>(
          onInvoke: (intent) {
            widget.onTap?.call();

            return null;
          },
        ),
      },
      child: SubFocus(
        builder: (context, state) {
          return Clickable(
            onHover: (hovered) {
              setState(() {
                if (hovered) {
                  state.requestFocus();
                }
              });
            },
            onPressed: widget.onTap,
            child: AnimatedContainer(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(themeData.radiusSm),
                color: state.isFocused
                    ? themeData.colorScheme.accent
                    : themeData.colorScheme.accent.withValues(alpha: 0),
              ),
              duration: kDefaultDuration,
              padding: EdgeInsets.symmetric(
                horizontal: themeData.scaling * 8,
                vertical: themeData.scaling * 6,
              ),
              child: IconTheme(
                data: themeData.iconTheme.small.copyWith(
                  color: widget.onTap == null
                      ? themeData.colorScheme.accentForeground.scaleAlpha(0.5)
                      : themeData.colorScheme.accentForeground,
                ),
                child: DefaultTextStyle(
                  style: TextStyle(
                    color: widget.onTap == null
                        ? themeData.colorScheme.accentForeground.scaleAlpha(0.5)
                        : themeData.colorScheme.accentForeground,
                  ),
                  child: Row(
                    children: [
                      if (widget.leading != null) widget.leading!,
                      if (widget.leading != null) Gap(themeData.scaling * 8),
                      Expanded(child: widget.title),
                      if (widget.trailing != null) Gap(themeData.scaling * 8),
                      if (widget.trailing != null)
                        widget.trailing!.muted().xSmall(),
                    ],
                  ).small(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
