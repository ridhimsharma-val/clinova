import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/auth/auth_config.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../models/case_attachment_model.dart';

/// Validation response when inspecting medical files
class FileValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String mimeType;

  const FileValidationResult({
    required this.isValid,
    this.errorMessage,
    required this.mimeType,
  });

  factory FileValidationResult.valid(String mimeType) => FileValidationResult(
        isValid: true,
        mimeType: mimeType,
      );

  factory FileValidationResult.invalid(String message) => FileValidationResult(
        isValid: false,
        errorMessage: message,
        mimeType: 'application/octet-stream',
      );
}

/// Clinova Central Medical Document Attachment Repository
///
/// Handles:
/// - Validation for file extensions, MIME types, and 20 MB size limit
/// - File picking compatible with Flutter Web (in-memory bytes)
/// - Uploading to private Supabase Storage bucket `case-medical-documents`
/// - Persisting metadata to `public.case_attachments`
/// - Generating short-lived secure signed URLs for doctor & patient inspection
/// - Cache and offline demo support
class CaseAttachmentRepository {
  CaseAttachmentRepository._();

  static final CaseAttachmentRepository instance = CaseAttachmentRepository._();

  static const String bucketName = 'case-medical-documents';
  static const int maxFileSizeBytes = 20 * 1024 * 1024; // 20 MB

  static const Set<String> supportedExtensions = {
    'pdf',
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };

  // In-memory cache keyed by caseId/reference
  final Map<String, List<CaseAttachmentModel>> _caseAttachments = {};
  final StreamController<Map<String, List<CaseAttachmentModel>>> _streamController =
      StreamController<Map<String, List<CaseAttachmentModel>>>.broadcast();

  Stream<Map<String, List<CaseAttachmentModel>>> get attachmentsStream => _streamController.stream;

  /// Validates a single file before allowing attachment
  FileValidationResult validateFile({
    required String filename,
    required int sizeBytes,
    List<CaseAttachmentModel> existingAttachments = const [],
  }) {
    final cleanName = filename.trim();
    if (cleanName.isEmpty) {
      return FileValidationResult.invalid("File name cannot be empty.");
    }

    // 1. Check size limit
    if (sizeBytes <= 0) {
      return FileValidationResult.invalid("File '$cleanName' is empty (0 bytes).");
    }
    if (sizeBytes > maxFileSizeBytes) {
      final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
      return FileValidationResult.invalid(
        "File '$cleanName' exceeds the 20 MB limit ($mb MB). Please select a file under 20 MB.",
      );
    }

    // 2. Check extension
    final lastDot = cleanName.lastIndexOf('.');
    if (lastDot == -1 || lastDot == cleanName.length - 1) {
      return FileValidationResult.invalid(
        "File '$cleanName' does not have a valid extension. Supported formats: PDF, JPEG, PNG, WebP, HEIC.",
      );
    }

    final ext = cleanName.substring(lastDot + 1).toLowerCase();
    if (!supportedExtensions.contains(ext)) {
      return FileValidationResult.invalid(
        "Unsupported file format '.$ext' for '$cleanName'. Supported formats: PDF, JPEG, PNG, WebP, HEIC.",
      );
    }

    // 3. Duplicate check
    final isDuplicate = existingAttachments.any(
      (a) => a.originalFilename.toLowerCase() == cleanName.toLowerCase() && a.fileSizeBytes == sizeBytes,
    );
    if (isDuplicate) {
      return FileValidationResult.invalid("'$cleanName' is already attached to this case.");
    }

    // Derive MIME type
    String mime = 'application/octet-stream';
    switch (ext) {
      case 'pdf':
        mime = 'application/pdf';
        break;
      case 'jpg':
      case 'jpeg':
        mime = 'image/jpeg';
        break;
      case 'png':
        mime = 'image/png';
        break;
      case 'webp':
        mime = 'image/webp';
        break;
      case 'heic':
        mime = 'image/heic';
        break;
      case 'heif':
        mime = 'image/heif';
        break;
    }

    return FileValidationResult.valid(mime);
  }

  /// Sanitizes a filename for storage path
  String sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  }

  /// Generates private storage path: patient_user_id/case_uuid/generated_filename
  String generateStoragePath({
    required String patientId,
    required String caseId,
    required String originalFilename,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sanitized = sanitizeFilename(originalFilename);
    return "$patientId/$caseId/${timestamp}_$sanitized";
  }

  /// Local cache setter
  void setAttachmentsForCase(String caseId, List<CaseAttachmentModel> list) {
    _caseAttachments[caseId] = List.from(list);
    _streamController.add(Map.unmodifiable(_caseAttachments));
  }

  /// Local cache getter
  List<CaseAttachmentModel> getAttachmentsForCase(String caseId) {
    return List.unmodifiable(_caseAttachments[caseId] ?? []);
  }

  /// Fetches attachments for a case from Supabase
  Future<List<CaseAttachmentModel>> fetchAttachmentsForCase(String caseId) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      return getAttachmentsForCase(caseId);
    }

    try {
      final response = await client
          .from('case_attachments')
          .select()
          .or('case_id.eq.$caseId,patient_case_id.eq.$caseId')
          .order('created_at', ascending: true);

      final List<CaseAttachmentModel> fetched = [];
      for (final row in response as List) {
        fetched.add(CaseAttachmentModel.fromJson(row as Map<String, dynamic>));
      }

      setAttachmentsForCase(caseId, fetched);
      return fetched;
    } catch (e) {
      debugPrint('[CaseAttachmentRepository] Note fetching attachments for $caseId: $e');
      return getAttachmentsForCase(caseId);
    }
  }

  /// Uploads a single attachment to private storage and records metadata
  Future<CaseAttachmentModel> uploadAttachment({
    required CaseAttachmentModel attachment,
    required String caseId,
    required String patientId,
  }) async {
    final client = SupabaseConfig.client;
    final bytes = attachment.bytes;

    if (client == null || bytes == null) {
      // In demo or offline mode, simulate successful upload
      final updated = attachment.copyWith(
        caseId: caseId,
        patientId: patientId,
        uploadStatus: AttachmentUploadStatus.uploaded,
        uploadProgress: 1.0,
      );
      final current = List<CaseAttachmentModel>.from(getAttachmentsForCase(caseId));
      final idx = current.indexWhere((a) => a.id == attachment.id);
      if (idx != -1) {
        current[idx] = updated;
      } else {
        current.add(updated);
      }
      setAttachmentsForCase(caseId, current);
      return updated;
    }

    try {
      final currentSession = AuthConfig.authService.currentSession;
      final uploaderId = client.auth.currentUser?.id ?? currentSession?.id ?? patientId;

      final path = attachment.storagePath.isNotEmpty
          ? attachment.storagePath
          : generateStoragePath(
              patientId: patientId,
              caseId: caseId,
              originalFilename: attachment.originalFilename,
            );

      // 1. Upload bytes to private Supabase Storage bucket
      await client.storage.from(bucketName).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: attachment.mimeType,
              upsert: true,
            ),
          );

      // 2. Insert metadata into public.case_attachments
      final metadata = {
        'case_id': caseId,
        'patient_case_id': caseId,
        'patient_id': patientId,
        'patient_user_id': patientId,
        'uploaded_by': uploaderId,
        'original_filename': attachment.originalFilename,
        'storage_path': path,
        'mime_type': attachment.mimeType,
        'file_size_bytes': attachment.fileSizeBytes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final insertRes = await client.from('case_attachments').insert(metadata).select().maybeSingle();

      final id = insertRes?['id'] as String? ?? attachment.id;

      final uploaded = attachment.copyWith(
        id: id,
        caseId: caseId,
        patientId: patientId,
        uploadedBy: uploaderId,
        storagePath: path,
        uploadStatus: AttachmentUploadStatus.uploaded,
        uploadProgress: 1.0,
      );

      final current = List<CaseAttachmentModel>.from(getAttachmentsForCase(caseId));
      final idx = current.indexWhere((a) => a.id == attachment.id);
      if (idx != -1) {
        current[idx] = uploaded;
      } else {
        current.add(uploaded);
      }
      setAttachmentsForCase(caseId, current);

      return uploaded;
    } catch (e, st) {
      debugPrint('[CaseAttachmentRepository] Error uploading attachment: $e\n$st');
      final failed = attachment.copyWith(
        uploadStatus: AttachmentUploadStatus.failed,
        errorMessage: "Upload failed: ${e.toString()}",
      );
      final current = List<CaseAttachmentModel>.from(getAttachmentsForCase(caseId));
      final idx = current.indexWhere((a) => a.id == attachment.id);
      if (idx != -1) {
        current[idx] = failed;
      } else {
        current.add(failed);
      }
      setAttachmentsForCase(caseId, current);
      return failed;
    }
  }

  /// Creates a short-lived signed URL for secure download/preview
  Future<String?> getSignedUrl(String storagePath) async {
    final client = SupabaseConfig.client;
    if (client == null || storagePath.isEmpty) return null;

    try {
      final signedUrl = await client.storage.from(bucketName).createSignedUrl(storagePath, 3600);
      return signedUrl;
    } catch (e) {
      debugPrint('[CaseAttachmentRepository] Error getting signed url: $e');
      return null;
    }
  }

  /// Downloads raw attachment bytes
  Future<Uint8List?> downloadAttachment(String storagePath) async {
    final client = SupabaseConfig.client;
    if (client == null || storagePath.isEmpty) return null;

    try {
      final bytes = await client.storage.from(bucketName).download(storagePath);
      return bytes;
    } catch (e) {
      debugPrint('[CaseAttachmentRepository] Error downloading bytes: $e');
      return null;
    }
  }

  /// Deletes an attachment from metadata table and storage
  Future<bool> deleteAttachment(CaseAttachmentModel attachment) async {
    final client = SupabaseConfig.client;
    if (client == null) {
      if (attachment.caseId != null) {
        final current = List<CaseAttachmentModel>.from(getAttachmentsForCase(attachment.caseId!));
        current.removeWhere((a) => a.id == attachment.id);
        setAttachmentsForCase(attachment.caseId!, current);
      }
      return true;
    }

    try {
      if (attachment.storagePath.isNotEmpty) {
        await client.storage.from(bucketName).remove([attachment.storagePath]);
      }
      if (attachment.id.isNotEmpty) {
        await client.from('case_attachments').delete().eq('id', attachment.id);
      }
      if (attachment.caseId != null) {
        final current = List<CaseAttachmentModel>.from(getAttachmentsForCase(attachment.caseId!));
        current.removeWhere((a) => a.id == attachment.id);
        setAttachmentsForCase(attachment.caseId!, current);
      }
      return true;
    } catch (e) {
      debugPrint('[CaseAttachmentRepository] Error deleting attachment: $e');
      return false;
    }
  }
}
