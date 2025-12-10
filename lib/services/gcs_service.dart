import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:googleapis/storage/v1.dart' as gcs;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// Service for uploading files to Google Cloud Storage
/// 
/// This service uses the native GCS API which supports:
/// - Files larger than 10GB (up to 5TB)
/// - Resumable uploads for reliability
/// - Direct GCS bucket access
class GCSService {
  static const String _projectId = 'break-away365-36gi4f';
  static const String _bucketName = 'break-away365-36gi4f.firebasestorage.app';

  /// Upload a file to Google Cloud Storage using resumable upload
  /// 
  /// [fileName] - The name to save the file as in GCS
  /// [fileBytes] - The file content as bytes
  /// [contentType] - MIME type of the file (e.g., 'application/pdf', 'video/mp4')
  /// [onProgress] - Optional callback to track upload progress (0.0 to 1.0)
  /// 
  /// Returns the public URL of the uploaded file
  static Future<String> uploadFile({
    required String fileName,
    required Uint8List fileBytes,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    try {
      // Get Firebase auth token to authenticate with GCS
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to upload files');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      // Create authenticated HTTP client
      final authClient = _AuthenticatedClient(
        http.Client(),
        idToken,
      );

      // Initialize GCS API
      final storage = gcs.StorageApi(authClient);

      // Create object metadata
      final objectMetadata = gcs.Object()
        ..name = fileName
        ..contentType = contentType;

      // Upload file using resumable upload
      final uploadMedia = gcs.Media(
        Stream.value(fileBytes),
        fileBytes.length,
        contentType: contentType,
      );

      // Perform the upload
      final uploadedObject = await storage.objects.insert(
        objectMetadata,
        _bucketName,
        uploadMedia: uploadMedia,
        uploadOptions: gcs.ResumableUploadOptions(),
      );

      // Generate public URL
      final publicUrl = 'https://storage.googleapis.com/$_bucketName/${uploadedObject.name}';
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload file to GCS: $e');
    }
  }

  /// Upload large file with chunked/resumable upload
  /// This is ideal for files over 10GB
  static Future<String> uploadLargeFile({
    required String fileName,
    required Stream<List<int>> fileStream,
    required int fileSize,
    required String contentType,
    Function(double progress)? onProgress,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated to upload files');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final authClient = _AuthenticatedClient(
        http.Client(),
        idToken,
      );

      final storage = gcs.StorageApi(authClient);

      final objectMetadata = gcs.Object()
        ..name = fileName
        ..contentType = contentType;

      final uploadMedia = gcs.Media(
        fileStream,
        fileSize,
        contentType: contentType,
      );

      // Use resumable upload for large files
      final uploadedObject = await storage.objects.insert(
        objectMetadata,
        _bucketName,
        uploadMedia: uploadMedia,
        uploadOptions: gcs.ResumableUploadOptions(),
      );

      final publicUrl = 'https://storage.googleapis.com/$_bucketName/${uploadedObject.name}';
      
      return publicUrl;
    } catch (e) {
      throw Exception('Failed to upload large file to GCS: $e');
    }
  }

  /// Delete a file from GCS
  static Future<void> deleteFile(String fileName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final authClient = _AuthenticatedClient(
        http.Client(),
        idToken,
      );

      final storage = gcs.StorageApi(authClient);
      await storage.objects.delete(_bucketName, fileName);
    } catch (e) {
      throw Exception('Failed to delete file from GCS: $e');
    }
  }

  /// Get download URL for a file
  static String getDownloadUrl(String fileName) {
    return 'https://storage.googleapis.com/$_bucketName/$fileName';
  }

  /// List all files in the bucket
  static Future<List<gcs.Object>> listFiles({String? prefix}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User must be authenticated');
      }

      final idToken = await user.getIdToken();
      if (idToken == null) {
        throw Exception('Failed to get authentication token');
      }

      final authClient = _AuthenticatedClient(
        http.Client(),
        idToken,
      );

      final storage = gcs.StorageApi(authClient);
      final objects = await storage.objects.list(
        _bucketName,
        prefix: prefix,
      );

      return objects.items ?? [];
    } catch (e) {
      throw Exception('Failed to list files from GCS: $e');
    }
  }
}

/// Custom HTTP client that adds Firebase auth token to requests
class _AuthenticatedClient extends http.BaseClient {
  final http.Client _inner;
  final String _token;

  _AuthenticatedClient(this._inner, this._token);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers['Authorization'] = 'Bearer $_token';
    return _inner.send(request);
  }
}
