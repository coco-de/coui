// ignore_for_file: empty_catches
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:coui_flutter/coui_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../main.dart';
import 'docs/sidebar_nav.dart';

const double breakpointWidth = 768;
const double breakpointWidth2 = 1024;

extension CustomWidgetExtension on Widget {
  Widget anchored(OnThisPage onThisPage) {
    return PageItemWidget(onThisPage: onThisPage, child: this);
  }
}

void openInNewTab(String url) {
  launchUrlString(url);
}

class OnThisPage extends LabeledGlobalKey {
  final ValueNotifier<bool> isVisible = ValueNotifier(false);

  OnThisPage([super.debugLabel]);
}

class PageItemWidget extends StatelessWidget {
  final OnThisPage onThisPage;
  final Widget child;

  const PageItemWidget({
    super.key,
    required this.onThisPage,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: onThisPage,
      child: child,
      onVisibilityChanged: (info) {
        onThisPage.isVisible.value = info.visibleFraction >= 1;
      },
    );
  }
}

class DocsPage extends StatefulWidget {
  final String name;
  final Widget child;
  final Map<String, OnThisPage> onThisPage;
  final List<Widget> navigationItems;
  final bool scrollable;
  const DocsPage({
    super.key,
    required this.name,
    required this.child,
    this.onThisPage = const {},
    this.navigationItems = const [],
    this.scrollable = true,
  });

  @override
  DocsPageState createState() => DocsPageState();
}

enum CouiFeatureTag {
  newFeature,
  updated,
  experimental,
  workInProgress;

  Widget buildBadge(BuildContext context) {
    ThemeData theme = Theme.of(context);
    ThemeData copy;
    String badgeText;
    switch (this) {
      case CouiFeatureTag.newFeature:
        copy = theme.copyWith(
          colorScheme: () =>
              theme.colorScheme.copyWith(primary: () => Colors.green),
        );
        badgeText = 'New';
        break;
      case CouiFeatureTag.updated:
        copy = theme.copyWith(
          colorScheme: () =>
              theme.colorScheme.copyWith(primary: () => Colors.blue),
        );
        badgeText = 'Updated';
        break;
      case CouiFeatureTag.workInProgress:
        copy = theme.copyWith(
          colorScheme: () =>
              theme.colorScheme.copyWith(primary: () => Colors.orange),
        );
        badgeText = 'WIP';
        break;
      case CouiFeatureTag.experimental:
        copy = theme.copyWith(
          colorScheme: () =>
              theme.colorScheme.copyWith(primary: () => Colors.purple),
        );
        badgeText = 'Experimental';
        break;
    }
    return Theme(
      data: copy,
      child: PrimaryBadge(child: Text(badgeText)),
    );
  }
}

class CouiDocsPage {
  final String title;
  final String name; // name for go_router
  final CouiFeatureTag? tag;

  CouiDocsPage(this.title, this.name, [this.tag]);
}

class CouiDocsSection {
  final String title;
  final List<CouiDocsPage> pages;
  final IconData icon;

  CouiDocsSection(this.title, this.pages, [this.icon = Icons.book]);
}

class DocsPageState extends State<DocsPage> {
  static final List<CouiDocsSection> sections = [
    CouiDocsSection(
      'Getting Started',
      List.unmodifiable([
        CouiDocsPage('Introduction', 'introduction'),
        CouiDocsPage('Installation', 'installation'),
        CouiDocsPage('Theme', 'theme'),
        CouiDocsPage('Typography', 'typography'),
        CouiDocsPage('Layout', 'layout'),
        CouiDocsPage('Web Preloader', 'web_preloader'),
        CouiDocsPage('Components', 'components'),
        CouiDocsPage('Icons', 'icons'),
        CouiDocsPage('Colors', 'colors'),
        CouiDocsPage('Material/Cupertino', 'external'),
        CouiDocsPage('State Management', 'state'),
      ]),
      Icons.book,
    ),
    // COMPONENTS BEGIN
    CouiDocsSection('Animation', [
      CouiDocsPage('Animated Value', 'animated_value_builder'),
      // https://nyxbui.design/docs/components/number-ticker
      CouiDocsPage('Number Ticker', 'number_ticker'),
      CouiDocsPage('Repeated Animation', 'repeated_animation_builder'),
      CouiDocsPage('Timeline Animation', 'timeline_animation'),
    ]),
    CouiDocsSection('Control', [
      CouiDocsPage('Button', 'button'),
      CouiDocsPage(
        'Audio Control',
        'audio_control',
        CouiFeatureTag.workInProgress,
      ),
      CouiDocsPage(
        'Video Control',
        'video_control',
        CouiFeatureTag.workInProgress,
      ),
    ]),
    CouiDocsSection('Disclosure', [
      CouiDocsPage('Accordion', 'accordion'),
      CouiDocsPage('Collapsible', 'collapsible'),
    ]),
    CouiDocsSection('Display', [
      CouiDocsPage('Avatar', 'avatar'),
      CouiDocsPage('Avatar Group', 'avatar_group'),
      // CouiDocsPage(
      // 'Data Table', 'data_table', CouiFeatureTag.experimental),
      // TODO also make it zoomable like: https://zoom-chart-demo.vercel.app/
      // CouiDocsPage('Chart', 'chart', CouiFeatureTag.workInProgress),
      CouiDocsPage('Code Snippet', 'code_snippet'),
      CouiDocsPage('Table', 'table'),
      CouiDocsPage('Tracker', 'tracker'),
    ]),
    CouiDocsSection('Feedback', [
      CouiDocsPage('Alert', 'alert'),
      CouiDocsPage('Alert Dialog', 'alert_dialog'),
      CouiDocsPage('Circular Progress', 'circular_progress'),
      CouiDocsPage('Progress', 'progress'),
      CouiDocsPage('Linear Progress', 'linear_progress'),
      CouiDocsPage('Skeleton', 'skeleton'),
      CouiDocsPage('Toast', 'toast'),
    ]),
    CouiDocsSection('Form', [
      // mostly same as file input, except it only accepts audio file
      // and adds the ability to play the audio
      // CouiDocsPage(
      //     'Audio Input', 'audio_input', CouiFeatureTag.workInProgress),
      // update: NVM, merge the component with file input
      // CouiDocsPage('Button', 'button'),
      // moved to control
      CouiDocsPage('Checkbox', 'checkbox'),
      CouiDocsPage('Chip Input', 'chip_input'),
      CouiDocsPage('Color Picker', 'color_picker'),
      CouiDocsPage('Date Picker', 'date_picker'),
      // TODO: https://file-vault-delta.vercel.app/ also https://uploader.sadmn.com/
      CouiDocsPage(
        'File Picker',
        'file_picker',
        CouiFeatureTag.workInProgress,
      ),
      CouiDocsPage('Form', 'form'),
      CouiDocsPage(
        'Formatted Input',
        'formatted_input',
        CouiFeatureTag.newFeature,
      ),
      // TODO: Image Input (with cropper and rotate tool, upload from file or take photo from camera)
      // CouiDocsPage(
      // 'Image Input', 'image_input', CouiFeatureTag.workInProgress),
      // replaced with File Input
      CouiDocsPage('Text Input', 'input'),
      // TODO: same as text input, but has dropdown autocomplete like chip input, the difference is, it does not convert
      // the value into chips
      CouiDocsPage('AutoComplete', 'autocomplete'),
      // TODO: same as input, except it only accepts number, and can be increased or decreased
      // using scroll, also has increment and decrement button
      // in between increment and decrement button, theres
      // a divider that can be dragged to increase or decrease the value
      CouiDocsPage('Number Input', 'number_input'),
      CouiDocsPage('Input OTP', 'input_otp'),
      CouiDocsPage('Phone Input', 'phone_input'),
      CouiDocsPage('Radio Group', 'radio_group'),
      //https://www.radix-ui.com/themes/docs/components/radio-cards
      CouiDocsPage('Radio Card', 'radio_card'),
      CouiDocsPage('Select', 'select'),
      CouiDocsPage('Slider', 'slider'),
      CouiDocsPage('Star Rating', 'star_rating'),
      CouiDocsPage('Switch', 'switch'),
      CouiDocsPage('Text Area', 'text_area'),
      CouiDocsPage('Time Picker', 'time_picker'),
      CouiDocsPage('Toggle', 'toggle'),
      CouiDocsPage('Multi Select', 'multiselect'),
      CouiDocsPage('Item Picker', 'item_picker', CouiFeatureTag.newFeature),
    ]),
    CouiDocsSection('Layout', [
      CouiDocsPage('Card', 'card'),
      CouiDocsPage('Carousel', 'carousel'),
      CouiDocsPage('Divider', 'divider'),
      CouiDocsPage('Resizable', 'resizable'),
      // https://nextjs-coui-dnd.vercel.app/ (make it headless)
      CouiDocsPage('Sortable', 'sortable'),
      CouiDocsPage('Steps', 'steps'),
      CouiDocsPage('Stepper', 'stepper'),
      CouiDocsPage('Timeline', 'timeline'),
      CouiDocsPage('Scaffold', 'scaffold'),
      CouiDocsPage('App Bar', 'app_bar'),
      CouiDocsPage('Card Image', 'card_image'),
    ]),
    CouiDocsSection('Navigation', [
      CouiDocsPage('Breadcrumb', 'breadcrumb'),
      CouiDocsPage('Menubar', 'menubar'),
      CouiDocsPage('Navigation Menu', 'navigation_menu'),
      CouiDocsPage('Pagination', 'pagination'),
      CouiDocsPage('Tabs', 'tabs'),
      CouiDocsPage('Tab List', 'tab_list'),
      // TODO: like a chrome tab, complete with its view
      CouiDocsPage('Tab Pane', 'tab_pane'),
      CouiDocsPage('Tree', 'tree'),
      // aka Bottom Navigation Bar
      CouiDocsPage('Navigation Bar', 'navigation_bar'),
      CouiDocsPage('Navigation Rail', 'navigation_rail'),
      CouiDocsPage('Expandable Sidebar', 'expandable_sidebar'),
      // aka Drawer
      CouiDocsPage('Navigation Sidebar', 'navigation_sidebar'),
      CouiDocsPage('Dot Indicator', 'dot_indicator'),
      //
      CouiDocsPage('Switcher', 'switcher', CouiFeatureTag.experimental),
    ]),
    CouiDocsSection('Overlay', [
      CouiDocsPage('Dialog', 'dialog'),
      CouiDocsPage('Drawer', 'drawer'),
      CouiDocsPage('Hover Card', 'hover_card'),
      CouiDocsPage('Popover', 'popover'),
      CouiDocsPage('Sheet', 'sheet'),
      CouiDocsPage('Swiper', 'swiper', CouiFeatureTag.newFeature),
      CouiDocsPage('Tooltip', 'tooltip'),
      // TODO: window as in like a window in desktop
      CouiDocsPage('Window', 'window', CouiFeatureTag.experimental),
    ]),

    CouiDocsSection('Utility', [
      CouiDocsPage('Badge', 'badge'),
      CouiDocsPage('Chip', 'chip'),
      CouiDocsPage('Calendar', 'calendar'),
      CouiDocsPage('Command', 'command'),
      CouiDocsPage('Context Menu', 'context_menu'),
      CouiDocsPage('Dropdown Menu', 'dropdown_menu'),
      // TODO https://www.radix-ui.com/themes/docs/components/kbd
      CouiDocsPage('Keyboard Display', 'keyboard_display'),
      // TODO: Same progress as image input
      CouiDocsPage(
        'Image Tools',
        'image_tools',
        CouiFeatureTag.workInProgress,
      ),
      // TODO: Mostly same as refresh indicator, but it does not provide indicator
      // the indicator itself is provided by scaffold
      CouiDocsPage('Refresh Trigger', 'refresh_trigger'),
      CouiDocsPage('Overflow Marquee', 'overflow_marquee'),
    ]),
    // COMPONENTS END
  ];

  List<String> componentCategories = [
    'Animation',
    'Disclosure',
    'Feedback',
    'Control',
    'Form',
    'Layout',
    'Navigation',
    'Overlay',
    'Display',
    'Utility',
  ];
  List<OnThisPage> currentlyVisible = [];
  final ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    for (final child in widget.onThisPage.values) {
      child.isVisible.addListener(_onVisibilityChanged);
    }
    // count compoents
    int count = 0;
    int workInProgress = 0;
    for (var section in sections) {
      if (componentCategories.contains(section.title)) {
        count += section.pages.length;
        for (var page in section.pages) {
          if (page.tag == CouiFeatureTag.workInProgress) {
            workInProgress++;
          }
        }
      }
    }
    // sort every components category
    for (var section in sections) {
      if (componentCategories.contains(section.title)) {
        section.pages.sort((a, b) => a.title.compareTo(b.title));
      }
    }
    if (kDebugMode) {
      print('Total components: $count');
      print('Work in Progress: $workInProgress');
    }
  }

  @override
  void didUpdateWidget(covariant DocsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!mapEquals(oldWidget.onThisPage, widget.onThisPage)) {
      for (final child in widget.onThisPage.values) {
        child.isVisible.addListener(_onVisibilityChanged);
      }
    }
  }

  @override
  void dispose() {
    for (final child in widget.onThisPage.values) {
      child.isVisible.removeListener(_onVisibilityChanged);
    }
    super.dispose();
  }

  void _onVisibilityChanged() {
    if (!mounted) return;
    setState(() {
      currentlyVisible = widget.onThisPage.values
          .where((element) => element.isVisible.value)
          .toList();
    });
  }

  bool isVisible(OnThisPage onThisPage) {
    return currentlyVisible.isNotEmpty && currentlyVisible[0] == onThisPage;
  }

  void showSearchBar() {
    showCommandDialog(
      builder: (context, query) async* {
        for (final section in sections) {
          final List<Widget> resultItems = [];
          for (final page in section.pages) {
            if (query == null ||
                page.title.toLowerCase().contains(query.toLowerCase())) {
              resultItems.add(
                CommandItem(
                  onTap: () {
                    context.goNamed(page.name);
                  },
                  title: Text(page.title),
                  trailing: Icon(section.icon),
                ),
              );
            }
          }
          if (resultItems.isNotEmpty) {
            yield [
              CommandCategory(
                title: Text(section.title),
                children: resultItems,
              ),
            ];
          }
        }
      },
      context: context,
    );
  }

  Widget buildFlavorTag() {
    String text = 'UKNOWN';
    Color color = Colors.green;
    switch (flavor) {
      case 'local':
        text = 'Local';
        color = Colors.red;
        break;
      case 'experimental':
        text = 'Experimental';
        color = Colors.orange;
        break;
      case 'release':
        text = getReleaseTagName();
        color = Colors.green;
        break;
    }
    return Builder(
      builder: (context) {
        return PrimaryBadge(
          onPressed: () {
            showDropdown(
              builder: (context) {
                return DropdownMenu(
                  children: [
                    MenuButton(
                      child: Text(getReleaseTagName()),
                      onPressed: (context) {
                        launchUrlString(
                          'https://sunarya-thito.github.io/coui_flutter/',
                        );
                      },
                    ),
                    MenuButton(
                      child: const Text('Experimental'),
                      onPressed: (context) {
                        launchUrlString(
                          'https://sunarya-thito.github.io/coui_flutter/experimental/',
                        );
                      },
                    ),
                  ],
                );
              },
              context: context,
              offset: const Offset(0, 8) * Theme.of(context).scaling,
            );
          },
          style: const ButtonStyle.primary(
            size: ButtonSize.small,
            density: ButtonDensity.dense,
          ).copyWith(
            decoration: (context, states, value) {
              return (value as BoxDecoration).copyWith(color: color);
            },
            textStyle: (context, states, value) {
              return value.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              );
            },
          ),
          child: Text(text),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Map<String, OnThisPage> onThisPage = widget.onThisPage;
    CouiDocsPage? page = sections
        .expand((e) => e.pages)
        .where((e) => e.name == widget.name)
        .firstOrNull;

    final theme = Theme.of(context);

    var hasOnThisPage = onThisPage.isNotEmpty;
    return FocusableActionDetector(
      autofocus: true,
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyF, control: true):
            OpenSearchCommandIntent(),
      },
      actions: {
        OpenSearchCommandIntent: CallbackAction<OpenSearchCommandIntent>(
          onInvoke: (intent) {
            showSearchBar();
            return null;
          },
        ),
      },
      child: ClipRect(
        child: PageStorage(
          bucket: docsBucket,
          child: Builder(
            builder: (context) {
              return StageContainer(
                builder: (context, padding) {
                  return Scaffold(
                    headers: [
                      Container(
                        color: theme.colorScheme.background.scaleAlpha(0.3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            MediaQueryVisibility(
                              alternateChild: AppBar(
                                leading: [
                                  GhostButton(
                                    onPressed: () {
                                      _openDrawer(context);
                                    },
                                    density: ButtonDensity.icon,
                                    child: const Icon(Icons.menu),
                                  ),
                                ],
                                padding: EdgeInsets.symmetric(
                                  vertical: 12 * theme.scaling,
                                  horizontal: 18 * theme.scaling,
                                ),
                                trailing: [
                                  Semantics(
                                    link: true,
                                    linkUrl: Uri.tryParse(
                                      'https://github.com/coco-de/coui',
                                    ),
                                    child: GhostButton(
                                      onPressed: () {
                                        openInNewTab(
                                          'https://github.com/coco-de/coui',
                                        );
                                      },
                                      density: ButtonDensity.icon,
                                      child: FaIcon(
                                        FontAwesomeIcons.github,
                                        color: theme
                                            .colorScheme.secondaryForeground,
                                      ).iconLarge(),
                                    ),
                                  ),
                                  // pub.dev icon
                                  GhostButton(
                                    onPressed: () {
                                      openInNewTab(
                                        'https://pub.dev/packages/coui_flutter',
                                      );
                                    },
                                    density: ButtonDensity.icon,
                                    child: ColorFiltered(
                                      // turns into white
                                      colorFilter: ColorFilter.mode(
                                        theme.colorScheme.secondaryForeground,
                                        BlendMode.srcIn,
                                      ),
                                      child: FlutterLogo(
                                        size: 24 * theme.scaling,
                                      ),
                                    ),
                                  ),
                                ],
                                child: Center(
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: OutlineButton(
                                      onPressed: () {
                                        showSearchBar();
                                      },
                                      trailing: const Icon(
                                        Icons.search,
                                      ).iconSmall().iconMutedForeground(),
                                      child: Row(
                                        spacing: 8,
                                        children: [
                                          const Text(
                                            'Search documentation...',
                                          ).muted().normal(),
                                          const KeyboardDisplay.fromActivator(
                                            activator: SingleActivator(
                                              LogicalKeyboardKey.keyF,
                                              control: true,
                                            ),
                                          ).xSmall.withOpacity(0.8),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              minWidth: breakpointWidth,
                              child: MediaQueryVisibility(
                                alternateChild: _buildAppBar(
                                  padding.copyWith(
                                        top: 12,
                                        right: 32,
                                        bottom: 12,
                                      ) *
                                      theme.scaling,
                                  theme,
                                ),
                                minWidth: breakpointWidth2,
                                child: _buildAppBar(
                                  padding.copyWith(top: 12, bottom: 12) *
                                      theme.scaling,
                                  theme,
                                ),
                              ),
                            ),
                            const Divider(),
                          ],
                        ),
                      ),
                    ],
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MediaQueryVisibility(
                          minWidth: breakpointWidth,
                          child: FocusTraversalGroup(
                            child: SingleChildScrollView(
                              key: const PageStorageKey('sidebar'),
                              padding: EdgeInsets.only(
                                    left: 24 + padding.left,
                                    top: 32,
                                    bottom: 32,
                                  ) *
                                  theme.scaling,
                              child: _DocsSidebar(
                                sections: sections,
                                pageName: widget.name,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: FocusTraversalGroup(
                            child: widget.scrollable
                                ? Builder(
                                    builder: (context) {
                                      var mq = MediaQuery.of(context);
                                      return SingleChildScrollView(
                                        padding: !hasOnThisPage
                                            ? const EdgeInsets.symmetric(
                                                      vertical: 32,
                                                      horizontal: 40,
                                                    ).copyWith(
                                                      right: padding.right + 32,
                                                    ) *
                                                    theme.scaling +
                                                mq.padding
                                            : const EdgeInsets.symmetric(
                                                      vertical: 32,
                                                      horizontal: 40,
                                                    ).copyWith(right: 24) *
                                                    theme.scaling +
                                                mq.padding,
                                        controller: scrollController,
                                        clipBehavior: Clip.none,
                                        child: MediaQuery(
                                          data: mq.copyWith(
                                            padding: EdgeInsets.zero,
                                          ),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.stretch,
                                            children: [
                                              Breadcrumb(
                                                separator:
                                                    Breadcrumb.arrowSeparator,
                                                children: [
                                                  TextButton(
                                                    onPressed: () {
                                                      context.goNamed(
                                                        'introduction',
                                                      );
                                                    },
                                                    density:
                                                        ButtonDensity.compact,
                                                    child: const Text('Docs'),
                                                  ),
                                                  ...widget.navigationItems,
                                                  if (page != null)
                                                    Text(page.title),
                                                ],
                                              ),
                                              Gap(16 * theme.scaling),
                                              widget.child,
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : Container(
                                    padding: !hasOnThisPage
                                        ? const EdgeInsets.symmetric(
                                              vertical: 32,
                                              horizontal: 40,
                                            ).copyWith(
                                              right: padding.right + 32,
                                              bottom: 0,
                                            ) *
                                            theme.scaling
                                        : const EdgeInsets.symmetric(
                                              vertical: 32,
                                              horizontal: 40,
                                            ).copyWith(right: 24, bottom: 0) *
                                            theme.scaling,
                                    clipBehavior: Clip.none,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Breadcrumb(
                                          separator: Breadcrumb.arrowSeparator,
                                          children: [
                                            TextButton(
                                              onPressed: () {
                                                context.goNamed('introduction');
                                              },
                                              density: ButtonDensity.compact,
                                              child: const Text('Docs'),
                                            ),
                                            ...widget.navigationItems,
                                            if (page != null) Text(page.title),
                                          ],
                                        ),
                                        Gap(16 * theme.scaling),
                                        Expanded(child: widget.child),
                                      ],
                                    ),
                                  ),
                          ),
                        ),
                        if (hasOnThisPage)
                          MediaQueryVisibility(
                            minWidth: breakpointWidth2,
                            child: _DocsSecondarySidebar(
                              onThisPage: onThisPage,
                              isVisible: isVisible,
                              padding: padding,
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(EdgeInsets padding, ThemeData theme) {
    return AppBar(
      // padding: (breakpointWidth2 < mediaQuerySize.width
      //         ? padding * theme.scaling
      //         : padding.copyWith(
      //               right: 32,
      //             ) *
      //             theme.scaling)
      //     .copyWith(
      //   top: 12 * theme.scaling,
      //   bottom: 12 * theme.scaling,
      // ),
      padding: padding,
      title: Basic(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('coui_flutter').textLarge().mono(),
            Gap(16 * theme.scaling),
            buildFlavorTag(),
          ],
        ),
        leading: FlutterLogo(size: 32 * theme.scaling),
      ),
      trailing: [
        Align(
          alignment: AlignmentDirectional.centerEnd,
          child: SizedBox(
            width: 320 - 18,
            child: OutlineButton(
              onPressed: () {
                showSearchBar();
              },
              trailing: const Icon(
                Icons.search,
              ).iconSmall().iconMutedForeground(),
              child: Row(
                spacing: 16,
                children: [
                  const Text('Search documentation...').muted().normal(),
                  const KeyboardDisplay.fromActivator(
                    activator: SingleActivator(
                      LogicalKeyboardKey.keyF,
                      control: true,
                    ),
                  ).xSmall.withOpacity(0.8),
                ],
              ),
            ),
          ),
        ),
        Gap(8 * theme.scaling),
        GhostButton(
          onPressed: () {
            openInNewTab('https://github.com/coco-de/coui');
          },
          density: ButtonDensity.icon,
          child: FaIcon(
            FontAwesomeIcons.github,
            color: theme.colorScheme.secondaryForeground,
          ).iconLarge(),
        ),
        // pub.dev icon
        GhostButton(
          onPressed: () {
            openInNewTab('https://pub.dev/packages/coui_flutter');
          },
          density: ButtonDensity.icon,
          child: ColorFiltered(
            // turns into white
            colorFilter: ColorFilter.mode(
              theme.colorScheme.secondaryForeground,
              BlendMode.srcIn,
            ),
            child: FlutterLogo(size: 24 * theme.scaling),
          ),
        ),
      ],
    );
  }

  void _openDrawer(BuildContext context) {
    final theme = Theme.of(context);
    final scaling = theme.scaling;
    openSheet(
      builder: (context) {
        return Container(
          padding: const EdgeInsets.only(top: 32) * scaling,
          constraints: const BoxConstraints(maxWidth: 400) * scaling,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  FlutterLogo(size: 24 * scaling),
                  Gap(18 * scaling),
                  const Text('coui_flutter').medium().mono(),
                  Gap(12 * scaling),
                  buildFlavorTag(),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      closeDrawer(context);
                    },
                    size: ButtonSize.small,
                    density: ButtonDensity.icon,
                    child: const Icon(Icons.close),
                  ),
                ],
              ).withPadding(left: 32 * scaling, right: 32 * scaling),
              Gap(32 * scaling),
              Expanded(
                child: FocusTraversalGroup(
                  child: SingleChildScrollView(
                    key: const PageStorageKey('sidebar'),
                    padding:
                        const EdgeInsets.only(left: 32, right: 32, bottom: 48) *
                            scaling,
                    child: SidebarNav(
                      children: [
                        for (var section in sections)
                          SidebarSection(
                            header: Text(section.title),
                            children: [
                              for (var page in section.pages)
                                Semantics(
                                  link: true,
                                  linkUrl: Uri.tryParse(
                                    'https://sunarya-thito.github.io/coui_flutter${_goRouterNamedLocation(context, page.name)}',
                                  ),
                                  child: DocsNavigationButton(
                                    onPressed: () {
                                      if (page.tag ==
                                          CouiFeatureTag.workInProgress) {
                                        showDialog(
                                          builder: (context) {
                                            return AlertDialog(
                                              actions: [
                                                PrimaryButton(
                                                  child: const Text('Close'),
                                                  onPressed: () {
                                                    Navigator.of(context).pop();
                                                  },
                                                ),
                                              ],
                                              content: const Text(
                                                'This page is still under development. Please come back later.',
                                              ),
                                              title: const Text(
                                                'Work in Progress',
                                              ),
                                            );
                                          },
                                          context: context,
                                        );
                                        return;
                                      }
                                      context.goNamed(page.name);
                                    },
                                    selected: page.name == widget.name,
                                    child: Basic(
                                      content: Text(page.title),
                                      trailing: page.tag?.buildBadge(context),
                                      trailingAlignment:
                                          AlignmentDirectional.centerStart,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      context: context,
      position: OverlayPosition.left,
    );
  }
}

class OpenSearchCommandIntent extends Intent {
  const OpenSearchCommandIntent();
}

class _DocsSidebar extends StatefulWidget {
  const _DocsSidebar({required this.sections, required this.pageName});

  final List<CouiDocsSection> sections;
  final String pageName;

  @override
  State<_DocsSidebar> createState() => _DocsSidebarState();
}

class _DocsSidebarState extends State<_DocsSidebar> {
  late List<Widget> children;

  @override
  void initState() {
    super.initState();
    children = [
      for (var section in widget.sections)
        _DocsSidebarSection(section: section, pageName: widget.pageName),
    ];
    // do we need didUpdateWidget? nope
    // we don't update the children anyway
  }

  @override
  Widget build(BuildContext context) {
    return SidebarNav(children: children);
  }
}

class _DocsSecondarySidebar extends StatefulWidget {
  final Map<String, OnThisPage> onThisPage;
  final bool Function(OnThisPage) isVisible;
  final EdgeInsets padding;

  const _DocsSecondarySidebar({
    required this.onThisPage,
    required this.isVisible,
    required this.padding,
  });

  @override
  State<_DocsSecondarySidebar> createState() => _DocsSecondarySidebarState();
}

class _DocsSecondarySidebarState extends State<_DocsSecondarySidebar> {
  final List<Widget> _sideChildren = [];
  @override
  void initState() {
    super.initState();
    var side = <Widget>[];
    for (var key in widget.onThisPage.keys) {
      side.add(
        SidebarButton(
          onPressed: () {
            Scrollable.ensureVisible(
              widget.onThisPage[key]!.currentContext!,
              duration: kDefaultDuration,
              alignmentPolicy: ScrollPositionAlignmentPolicy.explicit,
            );
          },
          selected: widget.isVisible(widget.onThisPage[key]!),
          child: Text(key),
        ),
      );
    }
    _sideChildren.add(
      SidebarSection(header: const Text('On This Page'), children: side),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      alignment: Alignment.topLeft,
      width: (widget.padding.right + 180) * theme.scaling,
      child: FocusTraversalGroup(
        child: SingleChildScrollView(
          padding:
              const EdgeInsets.only(left: 24, top: 32, right: 24, bottom: 32) *
                  theme.scaling,
          child: SidebarNav(children: _sideChildren),
        ),
      ),
    );
  }
}

class _DocsSidebarSection extends StatefulWidget {
  const _DocsSidebarSection({required this.section, required this.pageName});

  final CouiDocsSection section;
  final String pageName;

  @override
  State<_DocsSidebarSection> createState() => _DocsSidebarSectionState();
}

class _DocsSidebarSectionState extends State<_DocsSidebarSection> {
  late List<Widget> pages;

  @override
  void initState() {
    super.initState();
    pages = [
      for (var page in widget.section.pages)
        _DocsSidebarButton(page: page, pageName: widget.pageName),
    ];
    // do we need didUpdateWidget? nope
    // we don't update the pages anyway
  }

  @override
  Widget build(BuildContext context) {
    return SidebarSection(header: Text(widget.section.title), children: pages);
  }
}

class _DocsSidebarButton extends StatefulWidget {
  const _DocsSidebarButton({required this.page, required this.pageName});

  final CouiDocsPage page;
  final String pageName;

  @override
  State<_DocsSidebarButton> createState() => _DocsSidebarButtonState();
}

String? _goRouterNamedLocation(BuildContext context, String name) {
  try {
    return '/#${GoRouter.of(context).namedLocation(name)}';
  } catch (e) {}
  return '';
}

class _DocsSidebarButtonState extends State<_DocsSidebarButton> {
  @override
  Widget build(BuildContext context) {
    return Semantics(
      link: true,
      linkUrl: Uri.tryParse(
        'https://sunarya-thito.github.io/coui_flutter${_goRouterNamedLocation(context, widget.page.name)}',
      ),
      label: widget.page.title,
      child: DocsNavigationButton(
        trailing: DefaultTextStyle.merge(
          style: const TextStyle(decoration: TextDecoration.none),
          child: widget.page.tag?.buildBadge(context) ?? const SizedBox(),
        ),
        onPressed: _onPressed,
        selected: widget.page.name == widget.pageName,
        child: Text(widget.page.title),
      ),
    );
  }

  void _onPressed() {
    if (widget.page.tag == CouiFeatureTag.workInProgress) {
      showDialog(
        builder: (context) {
          return AlertDialog(
            actions: [
              PrimaryButton(
                child: const Text('Close'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
            content: const Text(
              'This page is still under development. Please come back later.',
            ),
            title: const Text('Work in Progress'),
          );
        },
        context: context,
      );
      return;
    }
    context.goNamed(widget.page.name);
  }
}
