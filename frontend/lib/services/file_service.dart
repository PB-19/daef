import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:daef/services/api_client.dart';

class FileService {
  FileService._();
  static final FileService instance = FileService._();

  // ── Pick a file (PDF or TXT) ──────────────────────────────────────────────────

  Future<PlatformFile?> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'txt'],
      withData: true,
    );
    return result?.files.firstOrNull;
  }

  // ── Upload file to backend → returns GCS path ─────────────────────────────────

  Future<String> upload(PlatformFile file) async {
    final bytes = file.bytes;
    if (bytes == null) throw Exception('Could not read file bytes');

    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(bytes, filename: file.name),
    });

    final response = await ApiClient.instance.dio.post(
      '/files/upload',
      data: formData,
      options: Options(contentType: 'multipart/form-data'),
    );

    return response.data['file_path'] as String;
  }

  // ── Delete file from GCS ──────────────────────────────────────────────────────

  Future<void> delete(String filePath) async {
    await ApiClient.instance.delete('/files', params: {'file_path': filePath});
  }
}
