import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Maximum value for [Progress] / [Slider] previews.
const _kMaxValue = 100.0;

/// Minimum value for [Slider] previews.
const _kMinValue = 0.0;

/// A partial progress value used for the default progress preview.
const _kPartialProgressValue = 65.0;

/// A mid-range value used for [Slider] previews.
const _kMidValue = 50.0;

/// Number of `<div>` components rendered by [Progress] (track + fill).
const _kProgressDivCount = 2;

/// Number of `<div>` components rendered by [Slider] — root, the
/// composed `FocusOutline` that draws the keyboard ring, the interior box
/// that ring wraps, then track, fill and thumb.
const _kSliderDivCount = 6;

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
      testComponents('renders $variant variant', (tester) async {
        final child = Component.text('Click Me');
        final button = switch (variant) {
          'secondary' => Button(
            onPressed: () {},
            variant: .secondary,
            child: child,
          ),
          'outline' => Button(
            onPressed: () {},
            variant: .outline,
            child: child,
          ),
          'ghost' => Button(
            onPressed: () {},
            variant: .ghost,
            child: child,
          ),
          'destructive' => Button(
            onPressed: () {},
            variant: .destructive,
            child: child,
          ),
          'primary' || _ => Button(
            onPressed: () {},
            variant: .primary,
            child: child,
          ),
        };
        pumpWithTheme(tester, button);
        expect(find.tag('button'), findsOneComponent);
        expect(find.text('Click Me'), findsOneComponent);
      });
    }
  });

  // ─── TextField ───────────────────────────────────────────────────────────

  group('TextField preview', () {
    testComponents('renders default variant', (tester) async {
      pumpWithTheme(
        tester,
        TextField(onChanged: (_) {}, hintText: 'Type something...'),
      );
      expect(find.tag('input'), findsOneComponent);
    });

    testComponents('renders error variant', (tester) async {
      pumpWithTheme(
        tester,
        TextField(
          onChanged: (_) {},
          errorText: 'Invalid input',
          hintText: 'Invalid input',
        ),
      );
      expect(find.tag('input'), findsOneComponent);
    });
  });

  // ─── Checkbox ──────────────────────────────────────────────────────────────

  group('Checkbox preview', () {
    testComponents('renders unchecked default', (tester) async {
      pumpWithTheme(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: false,
          label: 'Accept terms',
        ),
      );
      expect(find.tag('div'), findsComponents);
      expect(find.text('Accept terms'), findsOneComponent);
    });

    testComponents('renders checked variant', (tester) async {
      pumpWithTheme(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: true,
          label: 'Checked',
        ),
      );
      expect(find.tag('div'), findsComponents);
    });

    testComponents('renders disabled variant', (tester) async {
      pumpWithTheme(
        tester,
        Checkbox(
          onChanged: (_) {},
          checked: false,
          enabled: false,
          label: 'Disabled',
        ),
      );
      // Checkbox renders a <div>-based structure (not a native <input>).
      expect(find.tag('div'), findsComponents);
    });
  });

  // ─── Toggle ────────────────────────────────────────────────────────────────

  group('Toggle preview', () {
    // Asserted on the rendered state rather than on a tag: the track is
    // decoration and which element it is drawn with is not what these
    // tests are about. Reading `data-state` also makes "renders off" and
    // "renders on" different assertions, which a tag count never was.
    String? trackState(ComponentTester tester) => find
        .byType(DomComponent)
        .evaluate()
        .map((e) => e.component as DomComponent)
        .firstWhere((c) => c.attributes?['aria-hidden'] == 'true')
        .attributes?['data-state'];

    testComponents('renders off state', (tester) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}, value: false));
      expect(trackState(tester), equals('unchecked'));
    });

    testComponents('renders on state', (tester) async {
      pumpWithTheme(tester, Toggle(onChanged: (_) {}, value: true));
      expect(trackState(tester), equals('checked'));
    });

    testComponents('renders disabled state', (tester) async {
      pumpWithTheme(
        tester,
        Toggle(onChanged: (_) {}, value: false, enabled: false),
      );
      expect(trackState(tester), equals('unchecked'));
      expect(find.tag('button'), findsNothing);
    });
  });

  // ─── Badge ─────────────────────────────────────────────────────────────────

  group('Badge preview', () {
    for (final variant in CoreBadgeVariant.values) {
      testComponents('renders ${variant.name} variant', (tester) async {
        pumpWithTheme(
          tester,
          Badge(variant: variant, child: Component.text(variant.name)),
        );
        // The root and wrapping label are both spans. Check the actual
        // variant chrome and label instead of assuming a single DOM tag.
        final root =
            find.tag('span').evaluate().first.component as DomComponent;
        final classes = root.classes!.split(RegExp(r'\s+'));
        final fill = switch (variant) {
          CoreBadgeVariant.filled => 'bg-surface-container-highest',
          CoreBadgeVariant.tonal => 'bg-surface-container-high',
          CoreBadgeVariant.outlined => 'bg-surface/0',
        };
        expect(classes, contains(fill));
        if (variant == CoreBadgeVariant.outlined) {
          expect(classes, contains('border-outline'));
        }
        expect(find.text(variant.name), findsOneComponent);
      });
    }
  });

  // ─── Alert ─────────────────────────────────────────────────────────────────

  group('Alert preview', () {
    testComponents('renders default alert', (tester) async {
      pumpWithTheme(
        tester,
        const Alert(
          description: 'Important information.',
          title: 'Heads up!',
        ),
      );
      expect(find.text('Heads up!'), findsOneComponent);
    });

    testComponents('renders destructive alert', (tester) async {
      pumpWithTheme(
        tester,
        const Alert.destructive(
          description: 'Something went wrong.',
          title: 'Error',
        ),
      );
      expect(find.text('Error'), findsOneComponent);
    });
  });

  // ─── Progress ──────────────────────────────────────────────────────────────

  group('Progress preview', () {
    testComponents('renders default progress', (tester) async {
      pumpWithTheme(
        tester,
        Progress(value: _kPartialProgressValue, max: _kMaxValue),
      );
      expect(find.tag('div'), findsNComponents(_kProgressDivCount));
    });

    testComponents('renders empty progress', (tester) async {
      pumpWithTheme(tester, Progress(value: _kMinValue, max: _kMaxValue));
      expect(find.tag('div'), findsNComponents(_kProgressDivCount));
    });

    testComponents('renders full progress', (tester) async {
      pumpWithTheme(tester, Progress(value: _kMaxValue, max: _kMaxValue));
      expect(find.tag('div'), findsNComponents(_kProgressDivCount));
    });
  });

  // ─── Slider ────────────────────────────────────────────────────────────────

  group('Slider preview', () {
    testComponents('renders default slider', (tester) async {
      pumpWithTheme(
        tester,
        Slider(
          onChanged: (_) {},
          value: _kMidValue,
          min: _kMinValue,
          max: _kMaxValue,
        ),
      );
      expect(find.tag('div'), findsNComponents(_kSliderDivCount));
    });

    testComponents('renders disabled slider', (tester) async {
      pumpWithTheme(
        tester,
        Slider(
          onChanged: (_) {},
          value: _kMidValue,
          min: _kMinValue,
          max: _kMaxValue,
          enabled: false,
        ),
      );
      expect(find.tag('div'), findsNComponents(_kSliderDivCount));
    });
  });

  // ─── Avatar ────────────────────────────────────────────────────────────────

  group('Avatar preview', () {
    testComponents('renders initials avatar', (tester) async {
      pumpWithTheme(tester, Avatar(initials: 'AB'));
      expect(find.text('AB'), findsOneComponent);
    });

    testComponents('renders placeholder avatar', (tester) async {
      pumpWithTheme(tester, Avatar());
      // The box, and inside it the wrapper that holds its letters to the
      // desktop typography tier — a wrapper that draws no box of its own.
      expect(find.tag('div'), findsNComponents(2));
    });
  });

  // ─── Card ──────────────────────────────────────────────────────────────────

  group('Card preview', () {
    testComponents('renders default card', (tester) async {
      pumpWithTheme(
        tester,
        Card(
          header: Component.text('Card Title'),
          body: Component.text('Content goes here.'),
        ),
      );
      expect(find.text('Card Title'), findsOneComponent);
      expect(find.text('Content goes here.'), findsOneComponent);
    });
  });

  // ─── Toast ─────────────────────────────────────────────────────────────────

  group('Toast preview', () {
    testComponents('renders default toast', (tester) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Success',
          description: 'Changes saved.',
          onDismiss: () {},
        ),
      );
      expect(find.text('Success'), findsOneComponent);
    });

    testComponents('renders destructive toast', (tester) async {
      pumpWithTheme(
        tester,
        Toast(
          message: 'Error',
          description: 'Something went wrong.',
          variant: .destructive,
          onDismiss: () {},
        ),
      );
      expect(find.text('Error'), findsOneComponent);
    });
  });

  // ─── Select ────────────────────────────────────────────────────────────────

  group('Select preview', () {
    testComponents('renders select with options', (tester) async {
      pumpWithTheme(
        tester,
        Select<String>(
          onChanged: (_) {},
          items: const [
            CoreSelectItem(value: 'apple', label: 'Apple'),
            CoreSelectItem(value: 'banana', label: 'Banana'),
          ],
          placeholder: 'Pick a fruit',
        ),
      );
      // Select's trigger is a read-only `TextField` (`<input role="combobox">`)
      // since the 2026-09 redesign — no `<button>` — with a Popover-anchored
      // panel. Check the trigger exists.
      expect(find.tag('input'), findsOneComponent);
    });
  });

  // ─── Accordion ─────────────────────────────────────────────────────────────

  group('Accordion preview', () {
    testComponents('renders accordion items', (tester) async {
      pumpWithTheme(
        tester,
        Accordion(
          items: [
            AccordionItem(
              content: Component.text('Content here'),
              expanded: true,
              title: 'Section 1',
            ),
            AccordionItem(
              content: Component.text('More content'),
              title: 'Section 2',
            ),
          ],
        ),
      );
      expect(find.text('Section 1'), findsOneComponent);
      expect(find.text('Section 2'), findsOneComponent);
    });
  });

  // ─── Tabs ──────────────────────────────────────────────────────────────────

  group('Tabs preview', () {
    testComponents('renders tab pane', (tester) async {
      pumpWithTheme(
        tester,
        TabPane(
          tabs: [
            CoreTabItem(
              label: 'Account',
              content: Component.text('Account settings'),
            ),
            CoreTabItem(
              label: 'Password',
              content: Component.text('Password settings'),
            ),
          ],
          selectedIndex: 0,
        ),
      );
      expect(find.text('Account'), findsOneComponent);
    });
  });

  // ─── Tooltip ───────────────────────────────────────────────────────────────

  group('Tooltip preview', () {
    testComponents('renders tooltip trigger', (tester) async {
      pumpWithTheme(
        tester,
        Tooltip(
          message: 'Helpful tip',
          child: Button(
            variant: .outline,
            child: Component.text('Hover me'),
          ),
        ),
      );
      expect(find.text('Hover me'), findsOneComponent);
    });
  });

  // ─── Dialog ────────────────────────────────────────────────────────────────

  group('Dialog preview', () {
    testComponents('renders dialog structure', (tester) async {
      pumpWithTheme(
        tester,
        Dialog(
          title: Component.text('Dialog Title'),
          open: true,
        ),
      );
      expect(find.text('Dialog Title'), findsOneComponent);
    });
  });

  // ─── Breadcrumb ────────────────────────────────────────────────────────────

  group('Breadcrumb preview', () {
    testComponents('renders breadcrumb items', (tester) async {
      pumpWithTheme(
        tester,
        const Breadcrumb(
          items: [
            CoreBreadcrumbItem(label: 'Home', href: '/'),
            CoreBreadcrumbItem(label: 'Components'),
            CoreBreadcrumbItem(label: 'Current'),
          ],
        ),
      );
      expect(find.text('Home'), findsOneComponent);
      expect(find.text('Current'), findsOneComponent);
    });
  });

  // ─── Pagination ────────────────────────────────────────────────────────────

  group('Pagination preview', () {
    testComponents('renders pagination', (tester) async {
      const totalPages = 10;
      pumpWithTheme(
        tester,
        const Pagination(
          page: 1,
          totalPages: totalPages,
        ),
      );
      expect(find.text('1'), findsOneComponent);
    });
  });

  // ─── Loading ───────────────────────────────────────────────────────────────

  group('Loading preview', () {
    testComponents('renders loading spinner', (tester) async {
      pumpWithTheme(tester, const Loading());
      // Loading renders multiple <span> dots/segments.
      expect(find.tag('span'), findsComponents);
    });
  });

  // ─── Skeleton ──────────────────────────────────────────────────────────────

  group('Skeleton preview', () {
    testComponents('renders skeleton placeholder', (tester) async {
      pumpWithTheme(tester, Skeleton());
      expect(find.tag('div'), findsOneComponent);
    });
  });
}
