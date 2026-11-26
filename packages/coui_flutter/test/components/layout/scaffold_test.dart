import 'package:coui_flutter/coui_flutter.dart' as coui;
import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';

material.Widget _buildApp(material.Widget child) => material.MaterialApp(
  home: coui.Theme(data: const coui.ThemeData(), child: child),
);

const _kHeaderColor = material.Color(0xFF001122);
const _kFooterColor = material.Color(0xFF334455);
const _kBackgroundColor = material.Color(0xFF667788);

void main() {
  group('CoreScaffoldFabLocation', () {
    test('endFloat static instance is available', () {
      expect(
        coui.CoreScaffoldFabLocation.endFloat,
        isA<coui.CoreScaffoldFabLocation>(),
      );
    });

    test('centerFloat static instance is available', () {
      expect(
        coui.CoreScaffoldFabLocation.centerFloat,
        isA<coui.CoreScaffoldFabLocation>(),
      );
    });

    test('startFloat static instance is available', () {
      expect(
        coui.CoreScaffoldFabLocation.startFloat,
        isA<coui.CoreScaffoldFabLocation>(),
      );
    });

    test('endFloat.getAlignment returns bottomRight', () {
      expect(
        coui.alignmentForFabLocation(coui.CoreScaffoldFabLocation.endFloat),
        equals(material.Alignment.bottomRight),
      );
    });

    test('centerFloat.getAlignment returns bottomCenter', () {
      expect(
        coui.alignmentForFabLocation(coui.CoreScaffoldFabLocation.centerFloat),
        equals(material.Alignment.bottomCenter),
      );
    });

    test('startFloat.getAlignment returns bottomLeft', () {
      expect(
        coui.alignmentForFabLocation(coui.CoreScaffoldFabLocation.startFloat),
        equals(material.Alignment.bottomLeft),
      );
    });

    test('endFloat toString returns correct label', () {
      expect(
        coui.CoreScaffoldFabLocation.endFloat.toString(),
        equals('CoreScaffoldFabLocation.endFloat'),
      );
    });

    test('centerFloat toString returns correct label', () {
      expect(
        coui.CoreScaffoldFabLocation.centerFloat.toString(),
        equals('CoreScaffoldFabLocation.centerFloat'),
      );
    });

    test('startFloat toString returns correct label', () {
      expect(
        coui.CoreScaffoldFabLocation.startFloat.toString(),
        equals('CoreScaffoldFabLocation.startFloat'),
      );
    });
  });

  group('AppBar', () {
    testWidgets('renders with title', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.AppBar(
            title: material.Text('App Title'),
          ),
        ),
      );

      expect(find.text('App Title'), findsOneWidget);
    });

    testWidgets('renders with leading widget', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.AppBar(
            leading: [material.Text('leading')],
          ),
        ),
      );

      expect(find.text('leading'), findsOneWidget);
    });

    testWidgets('renders with trailing widget', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.AppBar(
            trailing: [material.Text('trailing')],
          ),
        ),
      );

      expect(find.text('trailing'), findsOneWidget);
    });

    testWidgets('renders with multiple actions', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.AppBar(
            leading: [material.Text('back')],
            title: material.Text('Title'),
            trailing: [
              material.Text('search'),
              material.Text('more'),
            ],
          ),
        ),
      );

      expect(find.text('back'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('search'), findsOneWidget);
      expect(find.text('more'), findsOneWidget);
    });

    testWidgets('renders AppBar widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.AppBar(),
        ),
      );

      expect(find.byType(coui.AppBar), findsOneWidget);
    });
  });

  group('Scaffold', () {
    testWidgets('renders with child', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            child: material.Text('scaffold body'),
          ),
        ),
      );

      expect(find.text('scaffold body'), findsOneWidget);
    });

    testWidgets('renders with appBar in headers', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            headers: [coui.AppBar(title: material.Text('Header Title'))],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('Header Title'), findsOneWidget);
    });

    testWidgets('renders with floatingActionButton', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            floatingActionButton: material.Text('FAB'),
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('FAB'), findsOneWidget);
    });

    testWidgets('renders floatingActionButton at endFloat by default', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            floatingActionButton: material.Text('FAB'),
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('FAB'), findsOneWidget);
    });

    testWidgets('renders with centerFloat floatingActionButtonLocation', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            floatingActionButton: material.Text('center FAB'),
            floatingActionButtonLocation:
                coui.CoreScaffoldFabLocation.centerFloat,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('center FAB'), findsOneWidget);
    });

    testWidgets('renders with startFloat floatingActionButtonLocation', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            floatingActionButton: material.Text('start FAB'),
            floatingActionButtonLocation:
                coui.CoreScaffoldFabLocation.startFloat,
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.text('start FAB'), findsOneWidget);
    });

    testWidgets('renders Scaffold widget in tree', (tester) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(find.byType(coui.Scaffold), findsOneWidget);
    });
  });

  group('Scaffold resizeToAvoidBottomInset', () {
    const bottomMarkerKey = material.Key('bottom-marker');
    const insetBottom = 300.0;

    /// Hosts [scaffold] under a MediaQuery reporting an IME bottom inset,
    /// mimicking an open on-screen keyboard.
    material.Widget buildWithImeInset(material.Widget scaffold) {
      return _buildApp(
        material.MediaQuery(
          data: const material.MediaQueryData(
            viewInsets: material.EdgeInsets.only(bottom: insetBottom),
          ),
          child: scaffold,
        ),
      );
    }

    /// A body whose bottom edge position reveals whether the scaffold
    /// resized for the inset.
    material.Widget buildBody() {
      return const material.Align(
        alignment: material.Alignment.bottomCenter,
        child: material.SizedBox(
          key: bottomMarkerKey,
          width: 40,
          height: 40,
        ),
      );
    }

    testWidgets('lifts content above the IME inset by default', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        buildWithImeInset(coui.Scaffold(child: buildBody())),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;
      final markerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      // Default (true): matches Material's own default and the Web twin,
      // where the browser resizes the visual viewport with no opt-out.
      expect(markerBottom, screenHeight - insetBottom);
    });

    testWidgets('keeps content under the IME inset when opted out', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        buildWithImeInset(
          coui.Scaffold(
            resizeToAvoidBottomInset: false,
            child: buildBody(),
          ),
        ),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;
      final markerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      // Opting out is what a full-bleed screen (media, maps) asks for:
      // the content keeps the whole height and extends behind the keyboard.
      expect(markerBottom, screenHeight);
    });

    testWidgets('lifts content above the IME inset when enabled', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        buildWithImeInset(
          coui.Scaffold(
            resizeToAvoidBottomInset: true,
            child: buildBody(),
          ),
        ),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;
      final markerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      expect(markerBottom, screenHeight - insetBottom);
    });

    testWidgets('lifts footers above the IME inset when enabled', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        buildWithImeInset(
          const coui.Scaffold(
            resizeToAvoidBottomInset: true,
            footers: [
              material.SizedBox(key: bottomMarkerKey, height: 40),
            ],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;
      final footerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      expect(footerBottom, screenHeight - insetBottom);
    });

    testWidgets('removes the consumed inset from the child MediaQuery', (
      tester,
    ) async {
      double? childBottomInset;

      final _ = await tester.pumpWidget(
        buildWithImeInset(
          coui.Scaffold(
            resizeToAvoidBottomInset: true,
            child: material.Builder(
              builder: (context) {
                childBottomInset = material.MediaQuery.viewInsetsOf(
                  context,
                ).bottom;
                return const material.SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      // Nested scaffolds must not double-apply the same inset.
      expect(childBottomInset, 0);
    });

    testWidgets('keeps the child MediaQuery inset when disabled', (
      tester,
    ) async {
      double? childBottomInset;

      final _ = await tester.pumpWidget(
        buildWithImeInset(
          coui.Scaffold(
            resizeToAvoidBottomInset: false,
            child: material.Builder(
              builder: (context) {
                childBottomInset = material.MediaQuery.viewInsetsOf(
                  context,
                ).bottom;
                return const material.SizedBox.shrink();
              },
            ),
          ),
        ),
      );

      expect(childBottomInset, insetBottom);
    });

    testWidgets('does not double-apply the inset across nested scaffolds', (
      tester,
    ) async {
      // Both scaffolds now resize by default, so a shell-plus-page
      // composition is the ordinary case rather than an opt-in one. The
      // inner scaffold must see an inset of zero and lift the marker
      // exactly once.
      final _ = await tester.pumpWidget(
        buildWithImeInset(
          coui.Scaffold(
            child: coui.Scaffold(child: buildBody()),
          ),
        ),
      );

      final screenHeight = tester
          .getSize(find.byType(coui.Scaffold).first)
          .height;
      final markerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      expect(markerBottom, screenHeight - insetBottom);
    });

    testWidgets('leaves geometry untouched when no IME inset is reported', (
      tester,
    ) async {
      // Every scaffold now takes the resize path, so the zero-inset case is
      // what every existing screenshot and golden renders through. A single
      // stray pixel here would move all of them at once.
      final _ = await tester.pumpWidget(
        _buildApp(coui.Scaffold(child: buildBody())),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;
      final markerBottom = tester.getBottomLeft(find.byKey(bottomMarkerKey)).dy;

      expect(markerBottom, screenHeight);
    });
  });

  group('Scaffold header top safe area', () {
    const insetTop = 44.0;
    const headerMarkerKey = material.ValueKey('header_marker');
    const footerMarkerKey = material.ValueKey('footer_marker');

    /// Hosts [scaffold] under a MediaQuery reporting a status bar / notch
    /// top inset, mimicking a device with a display cutout.
    material.Widget buildWithTopInset(material.Widget scaffold) {
      return _buildApp(
        material.MediaQuery(
          data: const material.MediaQueryData(
            padding: material.EdgeInsets.only(top: insetTop),
          ),
          child: scaffold,
        ),
      );
    }

    testWidgets('insets the header below the status bar', (tester) async {
      final _ = await tester.pumpWidget(
        buildWithTopInset(
          const coui.Scaffold(
            headers: [
              material.SizedBox(key: headerMarkerKey, height: 56),
            ],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byKey(headerMarkerKey)).dy, insetTop);
    });

    testWidgets('does not inset the footer', (tester) async {
      final _ = await tester.pumpWidget(
        buildWithTopInset(
          const coui.Scaffold(
            footers: [
              material.SizedBox(key: footerMarkerKey, height: 56),
            ],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      final screenHeight = tester.getSize(find.byType(coui.Scaffold)).height;

      expect(
        tester.getBottomLeft(find.byKey(footerMarkerKey)).dy,
        screenHeight,
      );
    });

    testWidgets('insets a floating header too', (tester) async {
      final _ = await tester.pumpWidget(
        buildWithTopInset(
          const coui.Scaffold(
            floatingHeader: true,
            headers: [
              material.SizedBox(key: headerMarkerKey, height: 56),
            ],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byKey(headerMarkerKey)).dy, insetTop);
    });

    testWidgets('is a no-op when an outer SafeArea already consumed it', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        buildWithTopInset(
          const material.SafeArea(
            child: coui.Scaffold(
              headers: [
                material.SizedBox(key: headerMarkerKey, height: 56),
              ],
              child: material.SizedBox.shrink(),
            ),
          ),
        ),
      );

      // The outer SafeArea already pushed the scaffold down by insetTop and
      // stripped the padding, so the header must not be inset a second time.
      expect(tester.getTopLeft(find.byKey(headerMarkerKey)).dy, insetTop);
    });

    testWidgets('leaves the header at the top edge without an inset', (
      tester,
    ) async {
      final _ = await tester.pumpWidget(
        _buildApp(
          const coui.Scaffold(
            headers: [
              material.SizedBox(key: headerMarkerKey, height: 56),
            ],
            child: material.SizedBox.shrink(),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byKey(headerMarkerKey)).dy, 0);
    });
  });
}
