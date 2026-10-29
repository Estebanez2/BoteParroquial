import '../../models/group_invitation.dart';

/// Public Hosting domain verified in this Firebase project. No arbitrary redirects.
abstract final class InvitationLinks {
  static const host = 'boteparroquial.web.app';
  static Uri forCode(InvitationCode code) =>
      Uri.https(host, '/join/${code.value}');

  static InvitationCode? parse(String text) {
    final raw = InvitationCode.parse(text);
    if (raw != null) return raw;
    final uri = Uri.tryParse(text.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        uri.host != host ||
        uri.port != 443 ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.pathSegments.length != 2 ||
        uri.pathSegments.first != 'join') {
      return null;
    }
    return InvitationCode.parse(uri.pathSegments.last);
  }

  /// Only the invitation may survive login; no caller-controlled return URL.
  static InvitationCode? fromRoute(Uri uri) {
    if (uri.hasAuthority &&
        (uri.scheme != 'https' ||
            uri.host != host ||
            uri.port != 443 ||
            uri.userInfo.isNotEmpty)) {
      return null;
    }
    if (uri.pathSegments.length == 2 && uri.pathSegments.first == 'join') {
      return InvitationCode.parse(uri.pathSegments.last);
    }
    if (uri.path == '/login' || uri.path == '/loading') {
      return InvitationCode.parse(uri.queryParameters['invitation'] ?? '');
    }
    return null;
  }
}
