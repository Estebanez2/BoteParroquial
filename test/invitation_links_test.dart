import 'package:bote_parroquial/core/routing/invitation_links.dart';
import 'package:bote_parroquial/models/group_invitation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Verified HTTPS invitations and login continuation reject arbitrary URLs',
    () {
      const code = InvitationCode(
        groupId: 'qa',
        secret: '12345678901234567890123456789012',
      );
      final link = InvitationLinks.forCode(code);
      expect(InvitationLinks.parse(link.toString())?.value, code.value);
      expect(InvitationLinks.parse(code.value)?.value, code.value);
      expect(
        InvitationLinks.fromRoute(
          Uri.parse('/login?invitation=${code.value}'),
        )?.value,
        code.value,
      );
      expect(InvitationLinks.fromRoute(link)?.value, code.value);
      for (final invalid in [
        'http://boteparroquial.web.app/join/${code.value}',
        'https://example.org/join/${code.value}',
        'https://boteparroquial.web.app.evil.test/join/${code.value}',
        'https://user@boteparroquial.web.app/join/${code.value}',
        '$link?next=https://evil.test',
        '$link#fragment',
        'https://boteparroquial.web.app/join/invalid',
      ]) {
        expect(InvitationLinks.parse(invalid), isNull, reason: invalid);
      }
    },
  );
}
