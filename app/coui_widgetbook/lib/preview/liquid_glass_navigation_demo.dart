import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

/// Scrollable content under independently configured navigation materials.
class LiquidGlassNavigationDemo extends StatefulWidget {
  /// Creates the preview with independently configurable material axes.
  const LiquidGlassNavigationDemo({
    this.appBarMaterial = CoreSurfaceStyleId.liquidGlass,
    this.navigationMaterial = CoreSurfaceStyleId.liquidGlass,
    this.groupedToolbar = false,
    this.dark = false,
    this.reduceTransparency = false,
    this.reduceMotion = false,
    this.compactOnScroll = true,
    super.key,
  });

  /// Header material.
  final CoreSurfaceStyleId appBarMaterial;

  /// Bottom navigation material.
  final CoreSurfaceStyleId navigationMaterial;

  /// Show separate toolbar groups and an action menu.
  final bool groupedToolbar;

  /// Whether to use the dark palette.
  final bool dark;

  /// Whether to use opaque accessibility fallbacks.
  final bool reduceTransparency;

  /// Whether to disable selection and press transitions.
  final bool reduceMotion;

  /// Whether the bottom navigation steps back — is drawn compact — while
  /// the collections are scrolled toward their end.
  final bool compactOnScroll;

  @override
  State<LiquidGlassNavigationDemo> createState() =>
      _LiquidGlassNavigationState();
}

class _LiquidGlassNavigationState extends State<LiquidGlassNavigationDemo> {
  final _scroll = ScrollController();
  int _selected = 0;
  bool _saved = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Widget _action(String label, IconName icon, VoidCallback onPressed) =>
      Semantics(
        label: label,
        child: Button(
          variant: .ghost,
          shape: .circle,
          size: .lg,
          buttonStyle: const CoreButtonStyle(height: 44),
          onPressed: onPressed,
          child: Icon(icon),
        ),
      );

  void _handleScrollToTop() {
    if (widget.reduceMotion) {
      _scroll.jumpTo(0);
    } else {
      _scroll.animateTo(
        0,
        duration: const Duration(milliseconds: CoreDuration.ms300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<Widget> _toolbarActions() {
    final panel = CorePopupStyle(surfaceStyle: widget.appBarMaterial);
    return [
      ToolbarGroup(
        ariaLabel: 'Collection navigation',
        popupStyle: panel,
        children: [
          _action('Scroll to top', LucideIcons.arrowUp, _handleScrollToTop),
        ],
      ),
      ToolbarGroup(
        ariaLabel: 'Collection actions',
        popupStyle: panel,
        children: [
          _action(
            _saved ? 'Remove from saved' : 'Save collection',
            LucideIcons.heart,
            () => setState(() => _saved = !_saved),
          ),
          DropdownMenu(
            dropdownMenuStyle: CoreDropdownMenuStyle(
              menuStyle: CoreMenuStyle(
                popupStyle: panel.copyWith(
                  borderRadius: const CoreBorderRadius.all(CoreRadius.radius24),
                  padding: const CoreEdgeInsets.all(CoreSpace.space8),
                ),
              ),
            ),
            trigger: _action(
              'More collection actions',
              LucideIcons.ellipsis,
              () {},
            ),
            items: [
              CoreMenuItem.action(
                _saved ? 'Remove from saved' : 'Save collection',
                leading: const Icon(LucideIcons.heart),
                onPressed: () => setState(() => _saved = !_saved),
              ),
              const CoreMenuItem.divider(),
              CoreMenuItem.action(
                'Copy title',
                standardAction: .copy,
                onPressed: () =>
                    Clipboard.setData(const ClipboardData(text: 'Discover')),
              ),
            ],
          ),
        ],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData.fromCore(
      widget.dark ? CoreThemePresets.dark : CoreThemePresets.light,
      coreComponentTheme: CoreComponentTheme(
        appBar: CoreAppBarTheme(
          style: CoreAppBarStyle(
            surfaceStyle: widget.appBarMaterial,
          ),
        ),
        navigationBar: CoreNavigationBarTheme(
          style: CoreNavigationBarStyle(
            surfaceStyle: widget.navigationMaterial,
          ),
        ),
      ),
    ).copyWith(reduceTransparency: () => widget.reduceTransparency);
    return Theme(
      data: theme,
      child: MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(disableAnimations: widget.reduceMotion),
        child: Scaffold(
          floatingHeader: true,
          floatingFooter: true,
          headers: [
            AppBar(
              title: Text(_saved ? 'Saved collection' : 'Discover'),
              appBarStyle: widget.groupedToolbar
                  ? const CoreAppBarStyle(
                      surfaceStyle: .defaultStyle,
                      backgroundColor: .transparent,
                    )
                  : null,
              centerTitle: true,
              scrollController: _scroll,
              trailing: widget.groupedToolbar
                  ? _toolbarActions()
                  : [
                      _action(
                        'Scroll to top',
                        LucideIcons.arrowUp,
                        _handleScrollToTop,
                      ),
                    ],
            ),
          ],
          footers: [
            NavigationBar(
              selectedIndex: _selected,
              onSelected: (index) => setState(() => _selected = index),
              labelMode: .all,
              compact: widget.compactOnScroll ? .onScroll : .never,
              items: const [
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.house),
                  label: 'Home',
                ),
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.search),
                  label: 'Search',
                ),
                CoreNavigationBarItem.destination(
                  icon: Icon(LucideIcons.heart),
                  label: 'Saved',
                ),
              ],
            ),
          ],
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.fromLTRB(
              CoreSpace.space16,
              CoreSpace.space80,
              CoreSpace.space16,
              CoreSpace.space104,
            ),
            itemCount: 24,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: CoreSpace.space16),
              child: Container(
                height: 160,
                alignment: Alignment.bottomLeft,
                padding: const EdgeInsets.all(CoreSpace.space20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(CoreRadius.radius24),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: index.isEven
                        ? const [Color(0xFF245A84), Color(0xFF51A59D)]
                        : const [Color(0xFF8D465D), Color(0xFFC58C67)],
                  ),
                ),
                child: Text(
                  'Collection ${index + 1}',
                  style: const TextStyle(
                    color: Color(0xFFFFFFFF),
                    fontSize: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
