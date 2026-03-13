import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class CloudinaryService extends GetxService {
  static const String _cloudNameDefine = String.fromEnvironment(
    'CLOUDINARY_CLOUD_NAME',
  );
  static const String _uploadPresetDefine = String.fromEnvironment(
    'CLOUDINARY_UPLOAD_PRESET',
  );
  static const String _folderDefine = String.fromEnvironment(
    'CLOUDINARY_FOLDER',
  );

  String _clean(String? raw) {
    if (raw == null) {
      return '';
    }
    final trimmed = raw.trim();
    if (trimmed.length >= 2 &&
        ((trimmed.startsWith('"') && trimmed.endsWith('"')) ||
            (trimmed.startsWith("'") && trimmed.endsWith("'")))) {
      return trimmed.substring(1, trimmed.length - 1).trim();
    }
    return trimmed;
  }

  String _envOrDefine(String key, String defineValue) {
    final envValue = _clean(dotenv.env[key]);
    if (envValue.isNotEmpty) {
      return envValue;
    }
    return _clean(defineValue);
  }

  String get _cloudName =>
      _envOrDefine('CLOUDINARY_CLOUD_NAME', _cloudNameDefine);

  String get _uploadPreset =>
      _envOrDefine('CLOUDINARY_UPLOAD_PRESET', _uploadPresetDefine);

  String get _folder {
    final configured = _envOrDefine('CLOUDINARY_FOLDER', _folderDefine);
    return configured.isNotEmpty ? configured : 'taskflow/profile';
  }

  Future<String> uploadProfileImage({
    required Uint8List bytes,
    required String fileName,
  }) async {
    if (_cloudName.isEmpty || _uploadPreset.isEmpty) {
      throw Exception(
        'Cloudinary is not configured. Add CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env (or pass them with --dart-define). Then do a full app restart.',
      );
    }

    final url = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );

    final request =
        http.MultipartRequest('POST', url)
          ..fields['upload_preset'] = _uploadPreset
          ..fields['folder'] = _folder
          ..files.add(
            http.MultipartFile.fromBytes('file', bytes, filename: fileName),
          );

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      print(
        'Cloudinary upload failed with status ${response.statusCode}: ${response.body}',
      );
      throw Exception('Cloudinary upload failed: ${response.body}');
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    final secureUrl = payload['secure_url'] as String?;
    if (secureUrl == null || secureUrl.isEmpty) {
      throw Exception('Cloudinary did not return secure_url.');
    }

    return secureUrl;
  }
}
