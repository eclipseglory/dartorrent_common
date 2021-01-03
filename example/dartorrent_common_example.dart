import 'dart:io';
import 'dart:typed_data';

import 'package:dartorrent_common/dartorrent_common.dart';

void main() {
  var c = CompactAddress(
      InternetAddress.fromRawAddress(Uint8List.fromList(randomBytes(4))),
      12112);
  print(c);

  var c1 = CompactAddress.parseIPv4Address(c.toBytes());
  print(c1);

  var c2 = c1.clone();
  print(c2 == c);
  var bytes = CompactAddress.multipleAddressBytes([c, c1, c2]);
  print(bytes);
  var l = CompactAddress.parseIPv4Addresses(bytes);
  print(l);
  l.clear();
}
