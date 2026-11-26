import 'package:coui_core/coui_core.dart';
import 'package:coui_web/coui_web.dart';
import 'package:jaspr_test/jaspr_test.dart';

import '../helpers/pump_with_theme.dart';

/// Whether the tree renders a skeleton and no real content.
///
/// Both halves matter. A loading state that renders the skeleton *and*
/// the value is not a loading state — it is the content with something
/// flickering behind it, which is exactly the shape the wrapper this
/// standard replaced had.
void _expectSkeletonOnly(
  ComponentTester tester,
  Component child, {
  required String absent,
}) {
  pumpWithTheme(tester, child);

  expect(find.byType(Skeleton), findsComponents);
  expect(find.text(absent), findsNothing);
}

void main() {
  group('the same standard holds on the Web', () {
    // A standard that works on one platform is not a standard. These are
    // the Web twins of the Flutter cases: the caller substitutes a
    // skeleton in the slot the value would occupy, with no per-component
    // loading flag on either side.
    testComponents('a listing item', (tester) async {
      _expectSkeletonOnly(
        tester,
        Listing(children: [Skeleton(width: '200px')]),
        absent: 'Order #1',
      );
    });

    testComponents('a card body', (tester) async {
      _expectSkeletonOnly(
        tester,
        Card(body: Skeleton(width: '200px')),
        absent: 'Revenue',
      );
    });

    testComponents('an avatar', (tester) async {
      _expectSkeletonOnly(
        tester,
        Avatar(
          child: Skeleton(width: '40px', height: '40px'),
        ),
        absent: 'AB',
      );
    });

    testComponents('a chat bubble', (tester) async {
      _expectSkeletonOnly(
        tester,
        Chat(bubble: Skeleton(width: '180px')),
        absent: 'Hello',
      );
    });
  });
}
