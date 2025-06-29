import 'dart:async';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

export 'ios_options.dart';

class CunningDocumentScanner {
  static const MethodChannel _channel =
      MethodChannel('cunning_document_scanner');

  static Future<List<String>> getPictures({
    int noOfPages = 1,
    bool isGalleryImportAllowed = false,
    String lang = "ar"

  }) async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
    ].request();
    if (statuses.containsValue(PermissionStatus.denied) ||
        statuses.containsValue(PermissionStatus.permanentlyDenied)) {
      throw Exception("Permission not granted");
    }

    final List<dynamic> pictures = await _channel.invokeMethod('getPictures', {
      'noOfPages': noOfPages,
      'isGalleryImportAllowed': isGalleryImportAllowed,
      'iosScannerOptions': {
        'imageFormat': 'jpg',
        'jpgCompressionQuality': '1.0',
      },
      'lang': lang,
    });
    return pictures.map((e) => e as String).toList();
  }
}
