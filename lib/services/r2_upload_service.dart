import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as path;

class R2UploadService {
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    region: 'us-central1',
  );
  final Dio _dio = Dio();

  /// Uploads a file to R2 and returns the public URL.
  Future<String> uploadFile(
    File file, {
    String? propertyId,
    void Function(int, int)? onProgress,
  }) async {
    try {
      // ✅ Force refresh token (important after setting admin claim)
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      final fileName = path.basename(file.path);
      final contentType =
          lookupMimeType(file.path) ?? 'application/octet-stream';

      print('🚀 Starting upload for: $fileName ($contentType)');

      // 1) Get Presigned URL from Cloud Function
      print('⏳ Requesting upload URL...');
      final result = await _functions.httpsCallable('getR2UploadUrl').call({
        'fileName': fileName,
        'contentType': contentType,
        'propertyId': propertyId,
      });

      final data = Map<String, dynamic>.from(result.data);
      final uploadUrl = data['uploadUrl'] as String;
      final publicUrl = data['publicUrl'] as String;
      print('✅ Got upload URL. Uploading to R2...');

      // 2) Upload file directly to R2 using Dio (Streaming)
      final int fileSize = await file.length();
      print('📦 File Size: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');

      // Create stream
      final stream = file.openRead();

      await _dio.put(
        uploadUrl,
        data: stream,
        options: Options(
          headers: {
            Headers.contentLengthHeader: fileSize, // Required for stream
            'Content-Type': contentType,
          },
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null) {
            onProgress(sent, total);
          }
        },
      );

      print('🎉 Upload successful: $publicUrl');
      return publicUrl;
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('غير مصرح لك القيام بهذا الإجراء (Permission Denied)');
      }
      throw Exception('خطأ في الخدمة: ${e.message}');
    } catch (e) {
      throw Exception('فشل الرفع: $e');
    }
  }

  /// Deletes a file from R2 given its public URL.
  Future<void> deleteFile(String publicUrl) async {
    try {
      // ✅ Force refresh token
      await FirebaseAuth.instance.currentUser?.getIdToken(true);

      await _functions.httpsCallable('deleteR2File').call({
        'publicUrl': publicUrl,
      });
    } on FirebaseFunctionsException catch (e) {
      if (e.code == 'permission-denied') {
        throw Exception('غير مصرح لك بالحذف (Permission Denied)');
      }
      throw Exception('خطأ في الخدمة: ${e.message}');
    } catch (e) {
      throw Exception('فشل الحذف: $e');
    }
  }
}
