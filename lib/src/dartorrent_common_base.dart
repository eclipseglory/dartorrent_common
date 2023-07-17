import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:math' as math;

import 'dart:typed_data';

/// Checks if you are awesome. Spoiler: you are.
class CompactAddress {
  final InternetAddress address;
  final int port;
  String? _contactEncodingStr;

  CompactAddress(this.address, this.port) {
    assert(port >= 0 && port <= 65535, 'wrong port');
  }

  /// Get compact address bytes
  ///
  /// The bytes formate is [`ip-bytes`][`port bytes`]
  List<int> toBytes([bool growable = true]) {
    if (growable) {
      var l = <int>[];
      l.addAll(address.rawAddress);
      var b = Uint8List(2);
      ByteData.view(b.buffer).setUint16(0, port);
      l.addAll(b);
      return l;
    } else {
      var len = address.rawAddress.length + 2;
      var l = Uint8List(len);
      var i = 0;
      for (; i < len - 2; i++) {
        l[i] = address.rawAddress[i];
      }
      ByteData.view(l.buffer).setUint16(address.rawAddress.length, port);
      return l;
    }
  }

  CompactAddress clone() {
    return CompactAddress(address, port);
  }

  String get addressString {
    return address.address;
  }

  String toContactEncodingString() {
    _contactEncodingStr ??= String.fromCharCodes(toBytes());
    return _contactEncodingStr!;
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

  /// Transform compact address list to bytes
  ///
  /// the [addresses] list should contains same ip type `CompactAddress`
  /// or will exception will happen.
  static List<int> multipleAddressBytes(List<CompactAddress> addresses,
      [bool growable = true]) {
    if (addresses.isEmpty) return <int>[];

    if (growable) {
      var l = <int>[];
      addresses.forEach((address) {
        l.addAll(address.toBytes(false));
      });
      return l;
    } else {
      var len = addresses[0].address.rawAddress.length + 2;
      var l = Uint8List(addresses.length * len);
      var view = ByteData.view(l.buffer);
      for (var i = 0; i < addresses.length; i++) {
        var add = addresses[i];
        for (var j = 0; j < add.address.rawAddress.length; j++) {
          l[i * len + j] = add.address.rawAddress[j];
        }
        view.setUint16(i * len + len - 2, add.port);
      }
      return l;
    }
  }

  /// Parse compact bytes to ipv4 address
  static List<CompactAddress> parseIPv4Addresses(List<int> message,
      [int offset = 0, int? end]) {
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

  /// Parse compact bytes to ipv4 address list
  static CompactAddress? parseIPv4Address(List<int> message, [int offset = 0]) {
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

  /// Parse compact bytes to ipv6 address
  static CompactAddress? parseIPv6Address(List<int> message, [int offset = 0]) {
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

  /// Parse compact bytes to ipv6 address list
  static List<CompactAddress> parseIPv6Addresses(List<int> message,
      [int offset = 0, int? end]) {
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

/// Random bytes array.
///
/// [count] is bytes length, if [typedList] is `false` , will return a fixed-length array ([Uint8List]).
///
/// [typedList] default value is `false`
List<int> randomBytes(int count, [bool typedList = false]) {
  var random = math.Random();

  if (typedList) {
    var bytes = Uint8List(count);
    for (var i = 0; i < count; i++) {
      bytes[i] = random.nextInt(256);
    }
    return bytes;
  } else {
    var bytes = <int>[];
    for (var i = 0; i < count; i++) {
      bytes.add(random.nextInt(256));
    }
    return bytes;
  }
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

Future<List<Uri>> _getTrackerFrom(String trackerUrlStr,
    [int retryTime = 0]) async {
  if (retryTime >= 3) return [];
  HttpClient? client;
  var _access = () async {
    var alist = <Uri>[];
    var aurl = Uri.parse(trackerUrlStr);
    var client = HttpClient();
    var request = await client.getUrl(aurl);
    var response = await request.close();
    if (response.statusCode != 200) return alist;
    var stream = utf8.decoder.bind(response);
    await stream.forEach((element) {
      var ss = element.split('\n');
      ss.forEach((url) {
        if (url.isNotEmpty) {
          try {
            var r = Uri.parse(url);
            alist.add(r);
          } catch (e) {
            //
          }
        }
      });
    });
    return alist;
  };
  try {
    var re = await _access();
    client?.close();
    return re;
  } catch (e) {
    client?.close();
    await Future.delayed(
        Duration(seconds: 15 * math.pow(2, retryTime).toInt()));
    return _getTrackerFrom(trackerUrlStr, ++retryTime);
  }
}

/// Get trackers url list from some awsome website
Stream<List<Uri>> findPublicTrackers() {
  var f = <Future<List<Uri>>>[];
  f.add(_getTrackerFrom('https://newtrackon.com/api/stable'));
  f.add(_getTrackerFrom('https://trackerslist.com/all.txt'));
  f.add(_getTrackerFrom(
      'https://cdn.jsdelivr.net/gh/ngosang/trackerslist/trackers_all.txt'));
  f.add(_getTrackerFrom('https://at.raxianch.moe/?type=AT-all'));
  return Stream.fromFutures(f);
}
