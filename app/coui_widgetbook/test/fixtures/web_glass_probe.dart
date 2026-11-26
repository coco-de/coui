/// Release-browser fixture for actual Flutter Web displacement and gestures.
library;

import 'dart:convert';
import 'dart:js_interop';

import 'package:coui_flutter/coui_flutter.dart';

@JS('couiFlutterGlassConfigure')
external set _configure(JSFunction value);
@JS('couiFlutterGlassState')
external set _state(JSFunction value);

void main() => runApp(const _Probe());

class _Probe extends StatefulWidget {
  const _Probe();
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  final _navKey = GlobalKey();
  int _selected = 0;
  bool _accept = true;
  bool _visible = true;
  bool _panel = true;
  bool _dark = false;
  bool _rtl = false;
  bool _reduced = false;
  bool _transparent = false;
  double _bezel = .32;
  double _width = 480;
  double _offset = 0;
  double _scale = 1;
  double _clipHeight = 100;
  CoreSurfaceStyleId _material = .liquidGlass;
  final _events = <int>[];

  @override
  void initState() {
    super.initState();
    _configure = ((String key, String value) {
      setState(() {
        switch (key) {
          case 'selected':
            _selected = int.parse(value);
          case 'accept':
            _accept = value == 'true';
          case 'visible':
            _visible = value == 'true';
          case 'panel':
            _panel = value == 'true';
          case 'dark':
            _dark = value == 'true';
          case 'rtl':
            _rtl = value == 'true';
          case 'reduced':
            _reduced = value == 'true';
          case 'transparent':
            _transparent = value == 'true';
          case 'bezel':
            _bezel = double.parse(value);
          case 'width':
            _width = double.parse(value);
          case 'offset':
            _offset = double.parse(value);
          case 'scale':
            _scale = double.parse(value);
          case 'clip':
            _clipHeight = double.parse(value);
          case 'material':
            _material = CoreSurfaceStyleId.values.byName(value);
          case 'clear':
            _events.clear();
        }
      });
    }).toJS;
    _state = (() {
      final box = _navKey.currentContext?.findRenderObject() as RenderBox?;
      final position = box?.localToGlobal(Offset.zero);
      return jsonEncode({
        'selected': _selected,
        'events': _events,
        if (box != null && position != null)
          'nav': [position.dx, position.dy, box.size.width, box.size.height],
      });
    }).toJS;
  }

  @override
  Widget build(BuildContext context) => CoUIApp(
    reduceTransparency: _transparent,
    theme: ThemeData.fromCore(
      _dark ? CoreThemePresets.dark : CoreThemePresets.light,
    ),
    home: Builder(
      builder: (context) => Directionality(
        textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
        child: MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: _reduced),
          child: ColoredBox(
            color: const Color(0xFFFFFFFF),
            child: Stacks(
              children: [
                const Position.fill(child: CustomPaint(painter: _Grid())),
                if (_visible && _panel)
                  Position(
                    left: 120,
                    top: 80,
                    width: 240,
                    height: 100,
                    child: ClipRect(
                      clipper: _PanelClipper(_clipHeight),
                      child: SurfaceBlur(
                        surfaceBlur: 1.5,
                        surfaceSaturation: 1.2,
                        surfaceBackdropBrightness: .9,
                        borderRadius: BorderRadius.circular(20),
                        refraction: CoreSurfaceRefraction(bezel: _bezel),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ),
                if (_visible)
                  Position(
                    left: 80,
                    top: 260,
                    width: _width,
                    child: Transform.translate(
                      offset: Offset(0, _offset),
                      child: Transform.scale(
                        scale: _scale,
                        child: ClipRect(
                          child: NavigationBar(
                            key: _navKey,
                            selectedIndex: _selected,
                            onSelected: (index) {
                              _events.add(index);
                              if (_accept) setState(() => _selected = index);
                            },
                            labelMode: .all,
                            navigationBarStyle: CoreNavigationBarStyle(
                              surfaceStyle: _material,
                            ),
                            items: const [
                              CoreNavigationBarItem.destination(
                                icon: Icon(LucideIcons.house),
                                label: 'Home',
                              ),
                              CoreNavigationBarItem.destination(
                                icon: Icon(LucideIcons.lock),
                                label: 'Disabled',
                                enabled: false,
                              ),
                              CoreNavigationBarItem.destination(
                                icon: Icon(LucideIcons.search),
                                label: 'Search',
                              ),
                              CoreNavigationBarItem.destination(
                                icon: Icon(LucideIcons.user),
                                label: 'Profile',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _PanelClipper extends CustomClipper<Rect> {
  const _PanelClipper(this.height);
  final double height;
  @override
  Rect getClip(Size size) => Rect.fromLTWH(0, 0, size.width, height);
  @override
  bool shouldReclip(_PanelClipper oldClipper) => height != oldClipper.height;
}

class _Grid extends CustomPainter {
  const _Grid();
  @override
  void paint(Canvas canvas, Size size) {
    for (var x = 0.0; x < size.width; x += 20) {
      canvas.drawRect(
        Rect.fromLTWH(x, 0, 10, size.height),
        Paint()..color = const Color(0xFF2369DA),
      );
    }
    for (var y = 0.0; y < size.height; y += 20) {
      canvas.drawRect(
        Rect.fromLTWH(0, y, size.width, 3),
        Paint()..color = const Color(0xFFD93048),
      );
    }
  }

  @override
  bool shouldRepaint(_Grid oldDelegate) => false;
}
