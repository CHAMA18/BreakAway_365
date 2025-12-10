// Conditional export to use the web iframe implementation on web, and
// fall back to an external-launch view on other platforms.
export 'aicoach_view_stub.dart' if (dart.library.html) 'aicoach_view_web.dart';
