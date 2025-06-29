import 'dart:io';

import 'package:cunning_document_scanner/cunning_document_scanner.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as imgPackage;
import 'package:path_provider/path_provider.dart' ;
import 'package:path/path.dart' as path;

Future<String> getImageBalayage({int persent = 70, bool isRotate = false, lang = "ar"}) async {
  try {
    List<String> pictures = await CunningDocumentScanner.getPictures(lang: lang);

    if (pictures.isEmpty) {
      return "";
    }

    final String originalImagePath = pictures[0];
    final File originalFile = File(originalImagePath);

    if (!await originalFile.exists()) {
      return "";
    }
    
    final bytes = await originalFile.readAsBytes();
    imgPackage.Image? sourceImage = imgPackage.decodeImage(bytes);

    if (sourceImage == null) {
      return "";
    }

    // --- MEMORY CRASH FIX ---
    // Resize the image to a reasonable size FIRST to prevent memory crashes.
    // 1500px on the longest side is plenty for a document.
    imgPackage.Image resizedImage = imgPackage.copyResize(
      sourceImage,
      width: sourceImage.width > sourceImage.height ? 1500 : -1,
      height: sourceImage.height >= sourceImage.width ? 1500 : -1,
    );

    // Now, apply brightness adjustments to the smaller, memory-friendly image.
    for (var pixel in resizedImage) {
      pixel.r = (pixel.r * 1.1).clamp(0, 255).toInt();
      pixel.g = (pixel.g * 1.1).clamp(0, 255).toInt();
      pixel.b = (pixel.b * 1.1).clamp(0, 255).toInt();
    }

    // Encode the final, processed image with good quality.
    List<int> finalImageBytes = imgPackage.encodeJpg(resizedImage, quality: 85);

    // Save the final processed image to a new file.
    final Directory tempDir = await getTemporaryDirectory();
    final String finalPath = path.join(
      tempDir.path,
      "${DateTime.now().millisecondsSinceEpoch}_processed.jpeg"
    );

    final File finalFile = File(finalPath);
    await finalFile.writeAsBytes(finalImageBytes, flush: true);

    // Clean up the original large image file from the scanner.
    await originalFile.delete();
    
    // Return the path to our new, processed, and much smaller file.
    return finalPath;

  } on PlatformException catch (e) {
    print("Scanning failed: $e");
    return '';
  } catch (e) {
    print("Image processing failed: $e");
    return '';
  }
}