import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'dart:typed_data';

/// Checks if you are awesome. Spoiler: you are.
class CompactAddress {
  final InternetAddress address;
  final int port;
  String _contactEncodingStr;

  CompactAddress(this.address, this.port) {
    assert(address != null && port != null, 'address or port can not be null');
    assert(port >= 0 && port <= 65535, 'wrong port');
  }

  List<int> toBytes() {
    var l = <int>[];
    l.addAll(address.rawAddress);
    var b = Uint8List(2);
    ByteData.view(b.buffer).setUint16(0, port);
    l.addAll(b);
    return l;
  }

  CompactAddress clone() {
    return CompactAddress(address, port);
  }

  String get addressString {
    return address.address;
  }

  String toContactEncodingString() {
    _contactEncodingStr ??= String.fromCharCodes(toBytes());
    return _contactEncodingStr;
  }

  @override
  String toString() {
    return '${address.address}:$port';
  }

  @override
  int get hashCode => toContactEncodingString().hashCode;

  @override
  bool operator ==(b) {
    if (b is CompactAddress) {
      return b.address == address && port == b.port;
    }
    return false;
  }

  static List<int> multipleAddressBytes(List<CompactAddress> addresses) {
    var l = <int>[];
    addresses.forEach((address) {
      l.addAll(address.toBytes());
    });
    return l;
  }

  static List<CompactAddress> parseIPv4Addresses(List<int> message,
      [int offset = 0, int end]) {
    if (message == null) return <CompactAddress>[];
    end ??= message.length;
    var l = <CompactAddress>[];
    for (var i = offset; i < end; i += 6) {
      try {
        var a = parseIPv4Address(message, i);
        if (a != null) {
          l.add(a);
        }
      } catch (e) {
        log('Parse IPv4 error:', error: e, name: 'COMMON LIB');
      }
    }
    return l;
  }

  static CompactAddress parseIPv4Address(List<int> message, [int offset = 0]) {
    if (message == null) return null;
    if (message.length - offset < 6) {
      return null;
    }
    var l = Uint8List(4);
    for (var i = 0; i < l.length; i++) {
      l[i] = message[offset + i];
    }
    var b = Uint8List(2);
    b[0] = message[offset + 4];
    b[1] = message[offset + 5];
    var port = ByteData.view(b.buffer).getUint16(0);
    return CompactAddress(
        InternetAddress.fromRawAddress(l, type: InternetAddressType.IPv4),
        port);
  }

  static CompactAddress parseIPv6Address(List<int> message, [int offset = 0]) {
    if (message == null) return null;
    if (message.length - offset < 18) {
      return null;
    }
    var l = Uint8List(16);
    for (var i = 0; i < l.length; i++) {
      l[i] = message[offset + i];
    }
    var b = Uint8List(2);
    b[0] = message[offset + 16];
    b[1] = message[offset + 17];
    var port = ByteData.view(b.buffer).getUint16(0);
    return CompactAddress(
        InternetAddress.fromRawAddress(l, type: InternetAddressType.IPv6),
        port);
  }

  static List<CompactAddress> parseIPv6Addresses(List<int> message,
      [int offset = 0, int end]) {
    if (message == null) return <CompactAddress>[];
    end ??= message.length;
    var l = <CompactAddress>[];
    for (var i = offset; i < end; i += 18) {
      try {
        var a = parseIPv6Address(message, i);
        if (a != null) {
          l.add(a);
        }
      } catch (e) {
        log('Parse IPv4 error:', error: e, name: 'COMMON LIB');
      }
    }
    return l;
  }
}

List<int> randomBytes(count) {
  var random = math.Random();
  var bytes = List<int>(count);
  for (var i = 0; i < count; i++) {
    bytes[i] = random.nextInt(256);
  }
  return bytes;
}

/// return random int number , `0 - max`
///
/// [max] values  between 1 and (1<<32) inclusive.
int randomInt(int max) {
  return math.Random().nextInt(max);
}

///
/// Transform buffer to hex string
String transformBufferToHexString(List<int> buffer) {
  var str = buffer.fold<String>('', (previousValue, byte) {
    var hex = byte.toRadixString(16);
    if (hex.length != 2) hex = '0' + hex;
    return previousValue + hex;
  });
  return str;
}
