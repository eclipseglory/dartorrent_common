import 'package:dartorrent_common/dartorrent_common.dart';
import 'package:test/test.dart';

void main() {
  group('Compact Address Test ', () {
    test('IPv4 create/clone', () {
      var bytes = [0, 0, 12, 2, 0, 1, 21, 21];
      var c = CompactAddress.parseIPv4Address(bytes, 2);
      var a = c.address;
      for (var i = 0; i < a.rawAddress.length; i++) {
        assert(bytes[i + 2] == a.rawAddress[i]);
      }
      print(c.toString());
      var b = c.toBytes();
      for (var i = 0; i < b.length; i++) {
        assert(bytes[i + 2] == b[i]);
      }

      var c1 = c.clone();
      assert(c1 == c);
      assert(c1.toString() == c.toString());

      bytes = [0, 0, 1000, 12, 2, 0, 1, 21, 21, 127, 89, 22, 12, 12, 22, 0, 0];
      var l = CompactAddress.parseIPv4Addresses(bytes, 3, 15);
      assert(l.length == 2);
      assert(l[0] == c1);
      var bb = CompactAddress.multipleAddressBytes(l);
      for (var i = 0; i < bb.length; i++) {
        assert(bb[i] == bytes[i + 3]);
      }
      print(bb);
    });
  });
}
