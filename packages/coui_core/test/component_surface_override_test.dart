import 'package:coui_core/coui_core.dart';
import 'package:test/test.dart';

void main() {
  test('Popup and Menubar material survives nested style composition', () {
    const panel = CorePopupStyle(surfaceStyle: .liquidGlass);
    const opaque = CorePopupStyle(surfaceStyle: .defaultStyle);
    expect(panel.copyWith(surfaceStyle: .defaultStyle), opaque);
    expect(panel.merge(opaque), opaque);
    expect({panel, opaque}, hasLength(2));
    const glass = CoreMenubarStyle(
      surfaceStyle: .liquidGlass,
      menuPanelStyle: panel,
    );
    final result = glass.merge(
      const CoreMenubarStyle(
        surfaceStyle: .defaultStyle,
        menuPanelStyle: CorePopupStyle(minWidth: 200),
      ),
    );
    expect(result.surfaceStyle, CoreSurfaceStyleId.defaultStyle);
    expect(result.menuPanelStyle!.surfaceStyle, CoreSurfaceStyleId.liquidGlass);
    expect(result.menuPanelStyle!.minWidth, 200);
    expect(
      glass.copyWith(surfaceStyle: .defaultStyle).surfaceStyle,
      CoreSurfaceStyleId.defaultStyle,
    );
    expect({glass, result}, hasLength(2));
  });

  test('standard commands are explicit and reserve the icon column', () {
    const item = CoreMenuItem<Object>.action('복사', standardAction: .copy);
    expect(item.hasLeading, isTrue);
    expect(item.standardAction!.icon, LucideIcons.copy);
    expect(const CoreMenuItem<Object>.action('Copy').standardAction, isNull);
    expect(
      const CoreMenubarEntry.action(label: 'Copy', standardAction: .copy),
      isNot(const CoreMenubarEntry.action(label: 'Copy')),
    );
  });

  test('AppBar material participates in merge, copy and value equality', () {
    const glass = CoreAppBarStyle(surfaceStyle: .liquidGlass);
    const opaque = CoreAppBarStyle(surfaceStyle: .defaultStyle);
    expect(glass.merge(opaque), opaque);
    expect(glass.merge(const CoreAppBarStyle()), glass);
    expect(glass.copyWith(surfaceStyle: .defaultStyle), opaque);
    expect({glass, opaque}, hasLength(2));
  });

  test(
    'NavigationBar material participates in merge, copy and value equality',
    () {
      const glass = CoreNavigationBarStyle(surfaceStyle: .liquidGlass);
      const opaque = CoreNavigationBarStyle(surfaceStyle: .defaultStyle);
      expect(glass.merge(opaque), opaque);
      expect(glass.merge(const CoreNavigationBarStyle()), glass);
      expect(glass.copyWith(surfaceStyle: .defaultStyle), opaque);
      expect({glass, opaque}, hasLength(2));
    },
  );

  test('Card material participates in merge, copy and value equality', () {
    const glass = CoreCardStyle(surfaceStyle: .liquidGlass);
    const opaque = CoreCardStyle(surfaceStyle: .defaultStyle);
    // A later layer states the material; an unstated one inherits it.
    expect(glass.merge(opaque), opaque);
    expect(glass.merge(const CoreCardStyle()), glass);
    expect(const CoreCardStyle().merge(opaque), opaque);
    expect(glass.copyWith(surfaceStyle: .defaultStyle), opaque);
    expect(
      glass.copyWith(padding: CoreEdgeInsets.zero).surfaceStyle,
      CoreSurfaceStyleId.liquidGlass,
    );
    // The material is the only difference, so equality and hashing carry it.
    expect({glass, opaque}, hasLength(2));
    expect(glass.hashCode, isNot(opaque.hashCode));
    // A card with no material statement is not a card that states the
    // baseline one — `null` inherits, `defaultStyle` removes.
    expect(const CoreCardStyle(), isNot(opaque));
  });

  test(
    'OutlinedContainer material participates in merge, copy and equality',
    () {
      const glass = CoreOutlinedContainerStyle(surfaceStyle: .liquidGlass);
      const opaque = CoreOutlinedContainerStyle(surfaceStyle: .defaultStyle);
      expect(glass.merge(opaque), opaque);
      expect(glass.merge(const CoreOutlinedContainerStyle()), glass);
      expect(const CoreOutlinedContainerStyle().merge(opaque), opaque);
      expect(glass.copyWith(surfaceStyle: .defaultStyle), opaque);
      // The card composes the container and resets only its padding, so the
      // material has to survive a copy that names another field.
      expect(
        glass.copyWith(padding: CoreEdgeInsets.zero).surfaceStyle,
        CoreSurfaceStyleId.liquidGlass,
      );
      expect({glass, opaque}, hasLength(2));
      expect(glass.hashCode, isNot(opaque.hashCode));
      expect(const CoreOutlinedContainerStyle(), isNot(opaque));
    },
  );

  test('content surfaces state no default material of their own', () {
    // Absence is the design: a constant would shadow the theme's material
    // axis for every card and container before any resolver reads it.
    expect(const CoreCardStyle().surfaceStyle, isNull);
    expect(const CoreOutlinedContainerStyle().surfaceStyle, isNull);
  });
}
