import 'dart:typed_data';
import 'package:flutter_nfc_kit/flutter_nfc_kit.dart' as fkit;
import 'package:nfc_manager/ndef_record.dart' as nfc;

/// Abstract NFC adapter
abstract class NfcPlatformAdapter {
  Future<fkit.NFCAvailability> getAvailability();
  Future<fkit.NFCTag> poll({Duration timeout});
  Future<String> transceive(String command);
  Future<List<nfc.NdefRecord>> readNdefRecords();
  Future<void> writeNdefRecords(List<nfc.NdefRecord> records);
  Future<void> finish();
}

/// Implementation using flutter_nfc_kit
class FlutterNfcPlatformAdapter implements NfcPlatformAdapter {
  @override
  Future<fkit.NFCAvailability> getAvailability() async {
    return fkit.FlutterNfcKit.nfcAvailability;
  }

  @override
  Future<fkit.NFCTag> poll({Duration timeout = const Duration(seconds: 20)}) {
    return fkit.FlutterNfcKit.poll(timeout: timeout);
  }

  @override
  Future<String> transceive(String command) {
    return fkit.FlutterNfcKit.transceive(command);
  }

  @override
  Future<List<nfc.NdefRecord>> readNdefRecords() async {
    final fkitRecords = await fkit.FlutterNfcKit.readNDEFRecords();

    return fkitRecords.map((r) {
      // Convert nullable Uint8List? to non-nullable with empty fallback
      final type = r.type ?? Uint8List(0);
      final id = r.id ?? Uint8List(0);
      final payload = r.payload ?? Uint8List(0);

      return nfc.NdefRecord(
        type: type,
        identifier: id,
        payload: payload,
        typeNameFormat: nfc.TypeNameFormat.values[r.tnf.index],
      );
    }).toList();
  }

  int _tnfToInt(nfc.TypeNameFormat tnf) {
    switch (tnf) {
      case nfc.TypeNameFormat.empty:
        return 0x00;
      case nfc.TypeNameFormat.wellKnown:
        return 0x01;
      case nfc.TypeNameFormat.media:
        return 0x02;
      case nfc.TypeNameFormat.absoluteUri:
        return 0x03;
      case nfc.TypeNameFormat.external:
        return 0x04;
      case nfc.TypeNameFormat.unchanged:
        return 0x05;
      case nfc.TypeNameFormat.unknown:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    return 0x06;
  }

  // @override
  // Future<void> writeNdefRecords(List<nfc.NdefRecord> records) async {
  //   final fkitRecords = records.map((r) {
  //     final type = r.type ?? Uint8List(0);
  //     final id = r.identifier ?? Uint8List(0);
  //     final payload = r.payload ?? Uint8List(0);

  //     return fkit.NdefRecordWrite(
  //       tnf: _tnfToInt(r.typeNameFormat), // convert your enum to int
  //       type: type,
  //       id: id,
  //       payload: payload,
  //     );
  //   }).toList();

  //   await fkit.FlutterNfcKit.writeNDEFRecords(fkitRecords);
  // }

  @override
  Future<void> finish() {
    return fkit.FlutterNfcKit.finish();
  }

  @override
  Future<void> writeNdefRecords(List<nfc.NdefRecord> records) {
    // TODO: implement writeNdefRecords
    throw UnimplementedError();
  }
}
