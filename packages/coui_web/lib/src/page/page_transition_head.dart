part of '../coui_web.dart';

const _kPageTransitionOwnerAttribute = 'data-coui-page-transition-owner';
const _kPageTransitionStyleOwner = 'style';
const _kPageTransitionScriptOwner = 'direction';

/// The server declares the two assets in the head. The client owns only those
/// assets: mounting Jaspr's global head adapter would discard a host's
/// unkeyed, server-rendered head children outside this client island.
class _PageTransitionHead extends StatefulComponent {
  const _PageTransitionHead();

  @override
  State<_PageTransitionHead> createState() => _PageTransitionHeadState();
}

class _PageTransitionHeadState extends State<_PageTransitionHead> {
  _PageTransitionHeadLease? _lease;

  @override
  Component build(BuildContext context) {
    final css = resolvePageTransitionRules(context).css;
    if (!kIsWeb) {
      return Document.head(
        children: [
          // Empty is an explicit off value, so a deeper disabled theme also
          // overrides a parent's enabled style during server rendering.
          Component.element(
            tag: 'style',
            id: kPageTransitionStyleId,
            attributes: const {
              _kPageTransitionOwnerAttribute: _kPageTransitionStyleOwner,
            },
            children: [RawText(css)],
          ),
          if (css.isNotEmpty)
            const Component.element(
              tag: 'script',
              id: kPageTransitionScriptId,
              attributes: {
                _kPageTransitionOwnerAttribute: _kPageTransitionScriptOwner,
              },
              children: [RawText(kPageTransitionDirectionScript)],
            ),
        ],
      );
    }

    final lease = _lease ??= _pageTransitionHead.createLease();
    _pageTransitionHead.update(
      lease,
      css: css,
      // Match Jaspr's head priority, including retained depth after a graft.
      depth: (context as Element).depth,
    );
    return const Component.fragment([]);
  }

  @override
  void dispose() {
    final lease = _lease;
    if (lease != null) _pageTransitionHead.release(lease);
    super.dispose();
  }
}

class _PageTransitionHeadLease {
  _PageTransitionHeadLease(this.order);

  final int order;
  String css = '';
  int depth = 0;
}

final _pageTransitionHead = _PageTransitionHeadOwner();

/// Owns references to our assets only. An existing same-id asset without our
/// server ownership mark belongs to the host and is never adopted or changed.
class _PageTransitionHeadOwner {
  final _leases = <_PageTransitionHeadLease>{};
  int _nextOrder = 0;
  web.HTMLStyleElement? _style;
  String? _serverCss;
  bool _createdStyle = false;
  web.HTMLScriptElement? _directionScript;

  _PageTransitionHeadLease createLease() =>
      _PageTransitionHeadLease(_nextOrder++);

  void update(
    _PageTransitionHeadLease lease, {
    required String css,
    required int depth,
  }) {
    final added = _leases.add(lease);
    if (!added && lease.css == css && lease.depth == depth) return;
    lease
      ..css = css
      ..depth = depth;
    _publish();
  }

  void release(_PageTransitionHeadLease lease) {
    _leases.remove(lease);
    if (_leases.isNotEmpty) {
      _publish();
      return;
    }

    final style = _style;
    if (style != null) {
      if (_createdStyle) {
        style.remove();
      } else if (style.textContent != _serverCss) {
        // With no client owners, the server's declarative asset remains.
        // An active zero-duration owner instead publishes its empty CSS.
        style.textContent = _serverCss;
      }
    }
    _style = null;
    _serverCss = null;
    _createdStyle = false;
    // Direction is document-wide, like the server's classic script. Keep it
    // across root remounts so its anonymous listener is installed only once.
  }

  void _publish() {
    final winner = _leases.reduce((earlier, later) {
      if (earlier.depth != later.depth) {
        return earlier.depth > later.depth ? earlier : later;
      }
      return earlier.order > later.order ? earlier : later;
    });
    final css = winner.css;
    var style = _style;
    if (style == null) {
      final existing = web.document.getElementById(kPageTransitionStyleId);
      if (existing != null) {
        if (existing.tagName == 'STYLE' &&
            existing.getAttribute(_kPageTransitionOwnerAttribute) ==
                _kPageTransitionStyleOwner) {
          style = existing as web.HTMLStyleElement;
          _serverCss = style.textContent;
          _style = style;
        }
      } else if (css.isNotEmpty) {
        style = web.document.createElement('style') as web.HTMLStyleElement
          ..id = kPageTransitionStyleId
          ..setAttribute(
            _kPageTransitionOwnerAttribute,
            _kPageTransitionStyleOwner,
          );
        _style = style;
        _createdStyle = true;
        web.document.head!.appendChild(style);
      }
    }
    if (style != null && style.textContent != css) style.textContent = css;
    if (css.isNotEmpty) _ensureDirectionScript();
  }

  void _ensureDirectionScript() {
    if (_directionScript != null) return;
    final existing = web.document.getElementById(kPageTransitionScriptId);
    if (existing != null) {
      if (existing.tagName == 'SCRIPT' &&
          existing.getAttribute(_kPageTransitionOwnerAttribute) ==
              _kPageTransitionScriptOwner) {
        _directionScript = existing as web.HTMLScriptElement;
      }
      return;
    }
    final script = web.document.createElement('script') as web.HTMLScriptElement
      ..id = kPageTransitionScriptId
      ..setAttribute(
        _kPageTransitionOwnerAttribute,
        _kPageTransitionScriptOwner,
      )
      ..textContent = kPageTransitionDirectionScript;
    _directionScript = script;
    web.document.head!.appendChild(script);
  }
}
