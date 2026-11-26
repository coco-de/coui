/// Disk cache operations for icon data.
///
/// Uses conditional export: dart:io on server/mobile/desktop,
/// no-op stubs on web.
library;

export 'disk_cache_stub.dart' if (dart.library.io) 'disk_cache_io.dart';
