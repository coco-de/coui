import 'package:jaspr/jaspr.dart';
import 'package:meta/meta.dart';

final _elementIds = Expando<int>('CoUI element CSS scope');
int _nextElementId = 0;
const int _kScopeIdRadix = 36;
const String _kPlatformScope = kIsWeb ? 'web' : 'ssr';

/// Returns a private CSS scope for the element building [context].
///
/// Local keys and component configurations can be reused at different tree
/// locations. The framework context identifies the owning element instead,
/// retaining its scope through rebuilds and allocating a new one on remount.
/// Callers keep their explicit DOM id in preference to this generated scope.
/// Separate server/client namespaces keep unhydrated server roots distinct
/// from client elements. The private ids need not match during hydration.
@internal
String elementScopeId(BuildContext context, {required String prefix}) {
  final index = _elementIds[context] ??= _nextElementId++;
  return '$prefix-$_kPlatformScope-${index.toRadixString(_kScopeIdRadix)}';
}
