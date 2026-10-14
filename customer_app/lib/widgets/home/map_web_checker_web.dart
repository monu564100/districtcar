// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:js' as js;

bool isGoogleMapsJsReady() {
  try {
    if (!js.context.hasProperty('google')) return false;
    final dynamic google = js.context['google'];
    if (google == null) return false;
    final dynamic maps = google['maps'];
    if (maps == null) return false;
    return maps['MapTypeId'] != null;
  } catch (_) {
    return false;
  }
}
