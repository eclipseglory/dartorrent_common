import 'package:dartorrent_common/dartorrent_common.dart';
import 'package:test/test.dart';

void main() {
  group('Compact Address Test ', () {
    test('IPv4 create/clone', () {
      var bytes = randomBytes(8);
      var c = CompactAddress.parseIPv4Address(bytes, 2);
      if (c != null) {
        expect(c, isNotNull);
        var a = c.address;

        for (var i = 0; i < a.rawAddress.length; i++) {
          assert(bytes[i + 2] == a.rawAddress[i]);
        }

        print(c.toString());
        var b = c.toBytes();
        var b1 = c.toBytes(false);
        for (var i = 0; i < b.length; i++) {
          assert(bytes[i + 2] == b[i] && b1[i] == b[i]);
        }

        var c1 = c.clone();
        assert(c1 == c);
        assert(c1.toString() == c.toString());

        bytes = randomBytes(17, true);
        var l = CompactAddress.parseIPv4Addresses(bytes, 3, 15);
        assert(l.length == 2);
        var bb = CompactAddress.multipleAddressBytes(l);
        for (var i = 0; i < bb.length; i++) {
          assert(bb[i] == bytes[i + 3]);
        }

        print(bb);
      }
    });
  });
}
