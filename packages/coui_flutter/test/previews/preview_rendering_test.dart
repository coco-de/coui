/// Preview rendering tests for CoUI Flutter components.
///
/// Verifies that key components render correctly for each variant,
/// matching the patterns used in docs_site/lib/previews/flutter_registry.dart.
import 'package:coui_flutter/coui_flutter.dart';
import 'package:flutter/material.dart'
    hide
        Badge,
        Banner,
        Card,
        Checkbox,
        Chip,
        CircularProgressIndicator,
        DataCell,
        DataColumn,
        DataRow,
        DataTable,
        Divider,
        NavigationBar,
        RadioGroup,
        Slider,
        Step,
        Stepper,
        Table,
        TableCell,
        TableRow,
        TextField,
        Tooltip;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

// Preview fixture constants.
const _kIconSize = 16.0;
const _kSkeletonHeight = 20.0;
const _kSkeletonWidthLong = 200.0;
const _kSkeletonWidthMedium = 180.0;
const _kSkeletonWidthShort = 150.0;
const _kSkeletonLineCount = 3;
const _kStarRounding = 0.5;
const _kStarValue = 3.5;
const _kPreviewTotalPages = 5;
const _kPreviewGap = 8.0;

void main() {
  // ─── Button ────────────────────────────────────────────────────────────────

  group('Button preview', () {
    for (final variant in [
      'primary',
      'secondary',
      'outline',
      'ghost',
      'destructive',
    ]) {
      testWidgets('renders $variant variant', (tester) async {
        const child = Text('Click Me');
        final button = switch (variant) {
          'secondary' => Button(
            variant: .secondary,
            onPressed: () {},
            child: child,
          ),
          'outline' => Button(
            variant: .outline,
            onPressed: () {},
            child: child,
          ),
          'ghost' => Button(
            variant: .ghost,
            onPressed: () {},
            child: child,
          ),
          'destructive' => Button(
            variant: .destructive,
            onPressed: () {},
            child: child,
          ),
          'primary' || _ => Button(
            variant: .primary,
            onPressed: () {},
            child: child,
          ),
        };
        await pumpTestApp(tester, button);
        expect(find.text('Click Me'), findsOneWidget);
        expect(find.byType(Button), findsOneWidget);
      });
    }
  });

  // ─── Input (TextField) ─────────────────────────────────────────────────────

  group('TextField preview', () {
    testWidgets('renders with placeholder', (tester) async {
      await pumpTestApp(
        tester,
        TextField(
          onChanged: (_) {},
          placeholder: const Text('Type something...'),
        ),
      );
      expect(find.byType(TextField), findsOneWidget);
    });
  });

  // ─── Checkbox ──────────────────────────────────────────────────────────────

  group('Checkbox preview', () {
    testWidgets('renders unchecked default', (tester) async {
      await pumpTestApp(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: false,
          label: 'Accept terms',
        ),
      );
      expect(find.text('Accept terms'), findsOneWidget);
    });

    testWidgets('renders checked variant', (tester) async {
      await pumpTestApp(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: true,
          label: 'Checked',
        ),
      );
      expect(find.text('Checked'), findsOneWidget);
    });

    testWidgets('renders indeterminate variant', (tester) async {
      await pumpTestApp(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: null,
          label: 'Indeterminate',
        ),
      );
      expect(find.text('Indeterminate'), findsOneWidget);
    });

    testWidgets('renders disabled variant', (tester) async {
      await pumpTestApp(
        tester,
        Checkbox(
          onChanged: (_) {},
          enabled: false,
          checked: false,
          label: 'Disabled',
        ),
      );
      expect(find.text('Disabled'), findsOneWidget);
    });
  });

  // ─── Toggle ────────────────────────────────────────────────────────────────

  group('Toggle preview', () {
    testWidgets('renders off state', (tester) async {
      await pumpTestApp(
        tester,
        Toggle(onChanged: (_) {}, value: false),
      );
      expect(find.byType(Toggle), findsOneWidget);
    });

    testWidgets('renders on state', (tester) async {
      await pumpTestApp(
        tester,
        Toggle(onChanged: (_) {}, value: true),
      );
      expect(find.byType(Toggle), findsOneWidget);
    });

    testWidgets('renders disabled state', (tester) async {
      await pumpTestApp(
        tester,
        Toggle(onChanged: (_) {}, value: false, enabled: false),
      );
      expect(find.byType(Toggle), findsOneWidget);
    });
  });

  // ─── Slider ────────────────────────────────────────────────────────────────

  group('Slider preview', () {
    testWidgets('renders default slider', (tester) async {
      await pumpTestApp(
        tester,
        Slider(
          onChanged: (_) {},
          value: 0.5,
          max: 1.0,
          min: 0.0,
        ),
      );
      expect(find.byType(Slider), findsOneWidget);
    });
  });

  // ─── Badge ─────────────────────────────────────────────────────────────────

  group('Badge preview', () {
    testWidgets('renders the default (neutral tonal label)', (tester) async {
      await pumpTestApp(tester, const Badge(child: Text('New')));
      expect(find.text('New'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('renders a status label with a leading dot', (tester) async {
      await pumpTestApp(
        tester,
        const Badge(tone: .success, showDot: true, child: Text('Done')),
      );
      expect(find.text('Done'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('renders a filled count', (tester) async {
      await pumpTestApp(
        tester,
        const Badge(
          tone: .destructive,
          variant: .filled,
          form: .count,
          child: Text('3'),
        ),
      );
      expect(find.text('3'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });

    testWidgets('renders an outlined label', (tester) async {
      await pumpTestApp(
        tester,
        const Badge(variant: .outlined, child: Text('Draft')),
      );
      expect(find.text('Draft'), findsOneWidget);
      expect(find.byType(Badge), findsOneWidget);
    });
  });

  // ─── Avatar ────────────────────────────────────────────────────────────────

  group('Avatar preview', () {
    testWidgets('renders initials', (tester) async {
      await pumpTestApp(tester, const Avatar(initials: 'AB'));
      expect(find.text('AB'), findsOneWidget);
      expect(find.byType(Avatar), findsOneWidget);
    });

    testWidgets('renders placeholder', (tester) async {
      await pumpTestApp(tester, const Avatar(initials: '?'));
      expect(find.text('?'), findsOneWidget);
    });
  });

  // ─── Card ──────────────────────────────────────────────────────────────────

  group('Card preview', () {
    testWidgets('renders card with content', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          child: Padding(
            padding: const .all(16),
            child: Column(
              mainAxisSize: .min,
              children: [
                const Text('Card Title'),
                const Text('Content here'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Card Title'), findsOneWidget);
      expect(find.text('Content here'), findsOneWidget);
    });
  });

  // ─── Alert ─────────────────────────────────────────────────────────────────

  group('Alert preview', () {
    testWidgets('renders default alert', (tester) async {
      await pumpTestApp(
        tester,
        const Alert(
          description: 'Important information.',
          title: 'Heads up!',
        ),
      );
      expect(find.text('Heads up!'), findsOneWidget);
    });

    testWidgets('renders destructive alert', (tester) async {
      await pumpTestApp(
        tester,
        const Alert.destructive(
          description: 'Something went wrong.',
          title: 'Error',
        ),
      );
      expect(find.text('Error'), findsOneWidget);
    });
  });

  // ─── Progress ──────────────────────────────────────────────────────────────

  group('Progress preview', () {
    testWidgets('renders default progress', (tester) async {
      await pumpTestApp(tester, const Progress(value: 0.65));
      expect(find.byType(Progress), findsOneWidget);
    });

    testWidgets('renders empty progress', (tester) async {
      await pumpTestApp(tester, const Progress(value: 0.0));
      expect(find.byType(Progress), findsOneWidget);
    });

    testWidgets('renders full progress', (tester) async {
      await pumpTestApp(tester, const Progress(value: 1.0));
      expect(find.byType(Progress), findsOneWidget);
    });
  });

  // ─── Toast (static mock — showToast requires BuildContext) ────────────────

  group('Toast preview', () {
    testWidgets('renders toast-like card', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          child: Padding(
            padding: const .all(12),
            child: Row(
              mainAxisSize: .min,
              spacing: _kPreviewGap,
              children: [
                material.Icon(
                  material.Icons.check_circle,
                  size: _kIconSize,
                  color: material.Colors.green,
                ),
                Column(
                  mainAxisSize: .min,
                  crossAxisAlignment: .start,
                  children: [
                    const Text(
                      'Success',
                      style: TextStyle(fontWeight: .bold),
                    ),
                    Text(
                      'Changes saved.',
                      style: TextStyle(color: material.Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Success'), findsOneWidget);
    });
  });

  // ─── Accordion ─────────────────────────────────────────────────────────────

  group('Accordion preview', () {
    testWidgets('renders accordion items', (tester) async {
      await pumpTestApp(
        tester,
        Accordion(
          items: [
            AccordionItem(
              content: const Text('Content here'),
              expanded: true,
              trigger: const AccordionTrigger(
                child: Text('Section 1'),
              ),
            ),
            AccordionItem(
              content: const Text('More content'),
              trigger: const AccordionTrigger(
                child: Text('Section 2'),
              ),
            ),
          ],
        ),
      );
      expect(find.text('Section 1'), findsOneWidget);
      expect(find.text('Section 2'), findsOneWidget);
    });
  });

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  group('Tabs preview', () {
    testWidgets('renders tab labels', (tester) async {
      await pumpTestApp(
        tester,
        const _TabsPreviewWidget(),
      );
      expect(find.text('Account'), findsOneWidget);
    });
  });

  // ─── Dialog (static mock — showDialog requires Navigator) ─────────────────

  group('Dialog preview', () {
    testWidgets('renders dialog-like card', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          variant: CoreCardVariant.filled,
          child: Padding(
            padding: const .all(24),
            child: Column(
              mainAxisSize: .min,
              children: [
                const Text(
                  'Are you sure?',
                  style: TextStyle(fontSize: 18, fontWeight: .bold),
                ),
                const SizedBox(height: 8),
                const Text('This action cannot be undone.'),
                const SizedBox(height: 16),
                Row(
                  mainAxisSize: .min,
                  spacing: _kPreviewGap,
                  children: [
                    Button(
                      variant: .outline,
                      onPressed: () {},
                      child: const Text('Cancel'),
                    ),
                    Button(
                      variant: .primary,
                      onPressed: () {},
                      child: const Text('Continue'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Are you sure?'), findsOneWidget);
      expect(find.text('This action cannot be undone.'), findsOneWidget);
    });
  });

  // ─── Loading ───────────────────────────────────────────────────────────────

  group('Loading preview', () {
    testWidgets('renders loading indicator', (tester) async {
      await pumpTestApp(
        tester,
        const SizedBox(
          width: 24,
          height: 24,
          child: material.CircularProgressIndicator(strokeWidth: 2),
        ),
      );
      expect(find.byType(material.CircularProgressIndicator), findsOneWidget);
    });
  });

  // ─── Skeleton ──────────────────────────────────────────────────────────────

  group('Skeleton preview', () {
    testWidgets('renders skeleton placeholder', (tester) async {
      await pumpTestApp(
        tester,
        Column(
          mainAxisSize: .min,
          crossAxisAlignment: .start,
          spacing: _kPreviewGap,
          children: [
            Container(
              color: material.Colors.grey[300],
              width: _kSkeletonWidthLong,
              height: _kSkeletonHeight,
            ),
            Container(
              color: material.Colors.grey[300],
              width: _kSkeletonWidthShort,
              height: _kSkeletonHeight,
            ),
            Container(
              color: material.Colors.grey[300],
              width: _kSkeletonWidthMedium,
              height: _kSkeletonHeight,
            ),
          ],
        ),
      );
      expect(find.byType(Container), findsNWidgets(_kSkeletonLineCount));
    });
  });

  // ─── Breadcrumb ─────────────────────────────────────────────────────────────

  group('Breadcrumb preview', () {
    testWidgets('renders breadcrumb items', (tester) async {
      await pumpTestApp(
        tester,
        const Breadcrumb(
          items: [
            CoreBreadcrumbItem(label: 'Home'),
            CoreBreadcrumbItem(label: 'Docs'),
            CoreBreadcrumbItem(label: 'Components'),
          ],
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Components'), findsOneWidget);
    });
  });

  // ─── Tooltip ────────────────────────────────────────────────────────────────

  group('Tooltip preview', () {
    testWidgets('renders tooltip trigger', (tester) async {
      await pumpTestApp(
        tester,
        Tooltip(
          tooltipChild: const Text('Tooltip text'),
          child: Button(
            variant: .outline,
            onPressed: () {},
            child: const Text('Hover me'),
          ),
        ),
      );
      expect(find.text('Hover me'), findsOneWidget);
    });
  });

  // ─── Select ─────────────────────────────────────────────────────────────────

  group('Select preview', () {
    testWidgets('renders select widget', (tester) async {
      await pumpTestApp(tester, const _SelectPreviewWidget());
      expect(find.text('apple'), findsOneWidget);
    });
  });

  // ─── Radio ──────────────────────────────────────────────────────────────────

  group('Radio preview', () {
    testWidgets('renders radio group', (tester) async {
      await pumpTestApp(
        tester,
        RadioGroup<String>(
          onChanged: (_) {},
          value: 'a',
          options: const [
            (value: 'a', label: 'Option A'),
            (value: 'b', label: 'Option B'),
          ],
        ),
      );
      expect(find.text('Option A'), findsOneWidget);
      expect(find.text('Option B'), findsOneWidget);
    });
  });

  // ─── Table ──────────────────────────────────────────────────────────────────

  group('Table preview', () {
    testWidgets('renders table with data', (tester) async {
      await pumpTestApp(
        tester,
        Table(
          rows: const [
            CoreTableRowData(
              kind: CoreTableRowKind.header,
              cells: [CoreTableCellData(child: Text('Name'))],
            ),
            CoreTableRowData(
              cells: [CoreTableCellData(child: Text('Alice'))],
            ),
          ],
        ),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
    });
  });

  // ─── Divider ────────────────────────────────────────────────────────────────

  group('Divider preview', () {
    testWidgets('renders divider', (tester) async {
      await pumpTestApp(tester, const Divider());
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  // ─── Gap ────────────────────────────────────────────────────────────────────

  group('Gap preview', () {
    testWidgets('renders gap inside column', (tester) async {
      await pumpTestApp(
        tester,
        const Column(
          mainAxisSize: .min,
          children: [
            Text('A'),
            Gap(gapStyle: CoreGapStyle(size: 16)),
            Text('B'),
          ],
        ),
      );
      expect(find.byType(Gap), findsOneWidget);
    });
  });

  // ─── ValidationBadge ────────────────────────────────────────────────────────

  group('ValidationBadge preview', () {
    testWidgets('renders valid badge', (tester) async {
      await pumpTestApp(
        tester,
        ValidationBadge.fromBool(label: 'Valid', isValid: true),
      );
      expect(find.text('Valid'), findsOneWidget);
    });
  });

  // ─── Kbd ────────────────────────────────────────────────────────────────────

  group('Kbd preview', () {
    testWidgets('renders a key combination', (tester) async {
      await pumpTestApp(tester, const Kbd(keys: ['Ctrl', 'K']));
      expect(find.byType(Kbd), findsOneWidget);
      expect(find.text('Ctrl'), findsOneWidget);
      expect(find.text('K'), findsOneWidget);
    });
  });

  // ─── Chip ───────────────────────────────────────────────────────────────────

  group('Chip preview', () {
    testWidgets('renders chip', (tester) async {
      await pumpTestApp(tester, const Chip(child: Text('Flutter')));
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });
  });

  // ─── DotIndicator ──────────────────────────────────────────────────────────

  group('DotIndicator preview', () {
    testWidgets('renders dot indicator', (tester) async {
      await pumpTestApp(tester, const DotIndicator(index: 2, length: 5));
      expect(find.byType(DotIndicator), findsOneWidget);
    });
  });

  // ─── Stat ───────────────────────────────────────────────────────────────────

  group('Stat preview', () {
    testWidgets('renders stat', (tester) async {
      await pumpTestApp(
        tester,
        const Stat(
          label: 'Total Users',
          value: '1,234',
        ),
      );
      expect(find.text('Total Users'), findsOneWidget);
      expect(find.text('1,234'), findsOneWidget);
    });
  });

  // ─── Banner ─────────────────────────────────────────────────────────────────

  group('Banner preview', () {
    testWidgets('renders info banner', (tester) async {
      await pumpTestApp(
        tester,
        const Banner(
          variant: CoreBannerVariant.info,
          message: Text('This is an informational message.'),
        ),
      );
      expect(find.text('This is an informational message.'), findsOneWidget);
    });

    testWidgets('renders warning banner', (tester) async {
      await pumpTestApp(
        tester,
        const Banner(
          variant: CoreBannerVariant.warning,
          message: Text('Please review your settings.'),
        ),
      );
      expect(find.text('Please review your settings.'), findsOneWidget);
    });
  });

  // ─── Steps ──────────────────────────────────────────────────────────────────

  group('Steps preview', () {
    testWidgets('renders steps', (tester) async {
      await pumpTestApp(
        tester,
        const Steps(
          items: [
            CoreStepData(title: 'Step 1'),
            CoreStepData(title: 'Step 2'),
            CoreStepData(title: 'Step 3'),
          ],
        ),
      );
      expect(find.text('Step 1'), findsOneWidget);
      expect(find.text('Step 3'), findsOneWidget);
    });
  });

  // ─── Countdown ──────────────────────────────────────────────────────────────

  group('Countdown preview', () {
    testWidgets('renders countdown', (tester) async {
      await pumpTestApp(
        tester,
        const Countdown(value: 42),
      );
      expect(find.byType(Countdown), findsOneWidget);
    });
  });

  // ─── FAB ────────────────────────────────────────────────────────────────────

  group('FAB preview', () {
    testWidgets('renders floating action button', (tester) async {
      await pumpTestApp(
        tester,
        FloatingActionButton(
          onPressed: () {},
          child: const material.Icon(material.Icons.add),
        ),
      );
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });

  // ─── StarRating ─────────────────────────────────────────────────────────────

  group('StarRating preview', () {
    testWidgets('renders star rating', (tester) async {
      await pumpTestApp(
        tester,
        StarRating(
          onChanged: (_) {},
          starPointRounding: _kStarRounding,
          value: _kStarValue,
        ),
      );
      expect(find.byType(StarRating), findsOneWidget);
    });
  });

  // ─── SwitchField ────────────────────────────────────────────────────────────

  group('SwitchField preview', () {
    testWidgets('renders switch field', (tester) async {
      await pumpTestApp(
        tester,
        SwitchField(
          onChanged: (_) {},
          label: 'Airplane Mode',
          value: true,
        ),
      );
      expect(find.text('Airplane Mode'), findsOneWidget);
    });
  });

  // ─── Menu ───────────────────────────────────────────────────────────────────

  group('Menu preview', () {
    testWidgets('renders menu-like card with text items', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Home'),
              ),
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('About'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
    });
  });

  // ─── NavigationBar ──────────────────────────────────────────────────────────

  group('NavigationBar preview', () {
    testWidgets('renders navigation items', (tester) async {
      await pumpTestApp(
        tester,
        NavigationBar(
          selectedIndex: 0,
          onSelected: (_) {},
          items: const [
            CoreNavigationBarItem.destination(label: 'Home'),
            CoreNavigationBarItem.destination(label: 'Settings'),
          ],
        ),
      );
      // Default bar labelMode hides labels (visible labels trip a pre-existing
      // lib layout defect), so assert the widget renders rather than text.
      expect(find.byType(NavigationBar), findsOneWidget);
    });
  });

  // ─── Popover (static snapshot) ──────────────────────────────────────────────

  group('Popover preview', () {
    testWidgets('renders static popover representation', (tester) async {
      await pumpTestApp(
        tester,
        Column(
          mainAxisSize: .min,
          spacing: _kPreviewGap,
          children: [
            Button(
              variant: .outline,
              onPressed: () {},
              child: const Text('Open Popover'),
            ),
            Card(
              variant: CoreCardVariant.filled,
              child: const Padding(
                padding: .all(12),
                child: Text('Popover content appears here.'),
              ),
            ),
          ],
        ),
      );
      expect(find.text('Open Popover'), findsOneWidget);
      expect(find.text('Popover content appears here.'), findsOneWidget);
    });
  });

  // ─── Drawer (static snapshot) ───────────────────────────────────────────────

  group('Drawer preview', () {
    testWidgets('renders static drawer representation', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          variant: CoreCardVariant.filled,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              const Text(
                'Drawer',
                style: TextStyle(fontWeight: .bold),
              ),
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Dashboard'),
              ),
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Settings'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Drawer'), findsOneWidget);
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  // ─── ContextMenu (static snapshot) ──────────────────────────────────────────

  group('ContextMenu preview', () {
    testWidgets('renders static context menu', (tester) async {
      await pumpTestApp(
        tester,
        Card(
          variant: CoreCardVariant.filled,
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .stretch,
            children: [
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Cut'),
              ),
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Copy'),
              ),
              Button(
                variant: .ghost,
                onPressed: () {},
                child: const Text('Paste'),
              ),
            ],
          ),
        ),
      );
      expect(find.text('Cut'), findsOneWidget);
      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Paste'), findsOneWidget);
    });
  });

  // ─── Stepper ────────────────────────────────────────────────────────────────

  group('Stepper preview', () {
    testWidgets('renders stepper', (tester) async {
      await pumpTestApp(
        tester,
        const Stepper(
          currentStep: 1,
          steps: [
            CoreStepItem(label: 'Account'),
            CoreStepItem(label: 'Address'),
          ],
        ),
      );
      // 3, not 1 — Stepper reserves label width by also painting two
      // invisible (opacity: 0, ExcludeSemantics) copies of each label
      // styled active/inactive, so the active⇄inactive bold toggle
      // repaints in place instead of resizing the step column (see
      // `stepper.dart`'s "Width-reservation stack" comment; mirrors the
      // Web twin's invisible grid layers).
      expect(find.text('Account'), findsNWidgets(3));
      expect(find.text('Address'), findsNWidgets(3));
    });
  });

  // ─── Pagination ─────────────────────────────────────────────────────────────

  group('Pagination preview', () {
    testWidgets('renders pagination', (tester) async {
      await pumpTestApp(
        tester,
        Pagination(
          onPageChanged: (_) {},
          page: 1,
          totalPages: _kPreviewTotalPages,
        ),
      );
      expect(find.byType(Pagination), findsOneWidget);
    });
  });

  // ─── TreeView ───────────────────────────────────────────────────────────────

  group('TreeView preview', () {
    testWidgets('renders tree nodes', (tester) async {
      await pumpTestApp(
        tester,
        const Tree(
          nodes: [
            CoreTreeNode(
              label: 'Documents',
              expanded: true,
              children: [
                CoreTreeNode(label: 'Resume.pdf'),
              ],
            ),
          ],
        ),
      );
      expect(find.text('Documents'), findsOneWidget);
      expect(find.text('Resume.pdf'), findsOneWidget);
    });
  });
}

/// Stateful widget for Select preview test.
class _SelectPreviewWidget extends StatefulWidget {
  const _SelectPreviewWidget();

  @override
  State<_SelectPreviewWidget> createState() => _SelectPreviewWidgetState();
}

class _SelectPreviewWidgetState extends State<_SelectPreviewWidget> {
  @override
  Widget build(BuildContext context) {
    return Select<String>(
      onChanged: (_) {},
      value: 'apple',
      placeholder: 'Select a fruit',
      items: const [
        CoreSelectItem(value: 'apple', label: 'apple'),
        CoreSelectItem(value: 'banana', label: 'banana'),
      ],
    );
  }
}

/// Stateful widget for Tabs preview test.
class _TabsPreviewWidget extends StatefulWidget {
  const _TabsPreviewWidget();

  @override
  State<_TabsPreviewWidget> createState() => _TabsPreviewWidgetState();
}

class _TabsPreviewWidgetState extends State<_TabsPreviewWidget> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Tabs.labels(
      onChanged: (i) => setState(() => _index = i),
      labels: const ['Account', 'Password'],
      selectedIndex: _index,
    );
  }
}
