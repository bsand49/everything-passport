import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  static Future<File?> downloadAndSaveImage(String url, http.Client client,
      {String fileName = 'temp_image.jpg'}) async {
    try {
      final response = await client.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final tempDir = await getTemporaryDirectory();
        final filePath = p.join(tempDir.path, fileName);
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);
        return file;
      }
    } catch (_) {
      // Return null on failure, handling error in caller
    }
    return null;
  }
}
