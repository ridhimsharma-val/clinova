import 'dart:typed_data';
import 'package:flutter/material.dart';

/// Upload lifecycle status for medical attachments
enum AttachmentUploadStatus {
  selected,
  uploading,
  uploaded,
  failed,
}

/// Clinova Supporting Medical Document Attachment Model
///
/// Represents an optional medical document (MRI, X-ray, Lab Report, Prescription, etc.)
/// securely attached to a clinical case and stored in the private Supabase Storage bucket
/// `case-medical-documents` with metadata persisted in `public.case_attachments`.
class CaseAttachmentModel {
  final String id;
  final String? caseId;
  final String? patientId;
  final String? uploadedBy;
  final String originalFilename;
  final String storagePath;
  final String mimeType;
  final int fileSizeBytes;
  final DateTime createdAt;

  // Transient local state (for in-memory file selection, web preview, and upload progress)
  final Uint8List? bytes;
  final AttachmentUploadStatus uploadStatus;
  final String? errorMessage;
  final double uploadProgress; // 0.0 to 1.0

  const CaseAttachmentModel({
    required this.id,
    this.caseId,
    this.patientId,
    this.uploadedBy,
    required this.originalFilename,
    this.storagePath = '',
    required this.mimeType,
    required this.fileSizeBytes,
    required this.createdAt,
    this.bytes,
    this.uploadStatus = AttachmentUploadStatus.selected,
    this.errorMessage,
    this.uploadProgress = 0.0,
  });

  /// Convenient alias for originalFilename
  String get fileName => originalFilename;

  /// Human-readable file size string (e.g. "2.4 MB", "450 KB")
  String get formattedSize {
    if (fileSizeBytes <= 0) return '0 B';
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Clean, descriptive file category label
  String get fileTypeLabel {
    final lower = mimeType.toLowerCase();
    final nameLower = originalFilename.toLowerCase();
    if (lower.contains('pdf') || nameLower.endsWith('.pdf')) {
      return 'PDF Document';
    }
    if (lower.contains('jpeg') || lower.contains('jpg') || nameLower.endsWith('.jpg') || nameLower.endsWith('.jpeg')) {
      return 'JPEG Image';
    }
    if (lower.contains('png') || nameLower.endsWith('.png')) {
      return 'PNG Image';
    }
    if (lower.contains('webp') || nameLower.endsWith('.webp')) {
      return 'WebP Image';
    }
    if (lower.contains('heic') || lower.contains('heif') || nameLower.endsWith('.heic') || nameLower.endsWith('.heif')) {
      return 'HEIC Image';
    }
    return 'Medical Document';
  }

  /// Associated UI icon based on file MIME type
  IconData get icon {
    final lower = mimeType.toLowerCase();
    final nameLower = originalFilename.toLowerCase();
    if (lower.contains('pdf') || nameLower.endsWith('.pdf')) {
      return Icons.picture_as_pdf_rounded;
    }
    if (lower.contains('image') ||
        nameLower.endsWith('.jpg') ||
        nameLower.endsWith('.jpeg') ||
        nameLower.endsWith('.png') ||
        nameLower.endsWith('.webp') ||
        nameLower.endsWith('.heic')) {
      return Icons.image_rounded;
    }
    return Icons.description_rounded;
  }

  /// Color accent for file badge
  Color get accentColor {
    final lower = mimeType.toLowerCase();
    if (lower.contains('pdf')) {
      return const Color(0xFFC04B37); // PDF red accent
    }
    if (lower.contains('image')) {
      return const Color(0xFF28654F); // Clinova Forest Green
    }
    return const Color(0xFF32866C);
  }

  CaseAttachmentModel copyWith({
    String? id,
    String? caseId,
    String? patientId,
    String? uploadedBy,
    String? originalFilename,
    String? storagePath,
    String? mimeType,
    int? fileSizeBytes,
    DateTime? createdAt,
    Uint8List? bytes,
    AttachmentUploadStatus? uploadStatus,
    String? errorMessage,
    double? uploadProgress,
  }) {
    return CaseAttachmentModel(
      id: id ?? this.id,
      caseId: caseId ?? this.caseId,
      patientId: patientId ?? this.patientId,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      originalFilename: originalFilename ?? this.originalFilename,
      storagePath: storagePath ?? this.storagePath,
      mimeType: mimeType ?? this.mimeType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      createdAt: createdAt ?? this.createdAt,
      bytes: bytes ?? this.bytes,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      errorMessage: errorMessage ?? this.errorMessage,
      uploadProgress: uploadProgress ?? this.uploadProgress,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'case_id': caseId,
        'patient_case_id': caseId,
        'patient_id': patientId,
        'patient_user_id': patientId,
        'uploaded_by': uploadedBy,
        'original_filename': originalFilename,
        'storage_path': storagePath,
        'mime_type': mimeType,
        'file_size_bytes': fileSizeBytes,
        'created_at': createdAt.toIso8601String(),
        'upload_status': uploadStatus.name,
      };

  factory CaseAttachmentModel.fromJson(Map<String, dynamic> json) {
    AttachmentUploadStatus status = AttachmentUploadStatus.uploaded;
    final statusStr = json['upload_status'] as String?;
    if (statusStr != null) {
      status = AttachmentUploadStatus.values.firstWhere(
        (e) => e.name == statusStr,
        orElse: () => AttachmentUploadStatus.uploaded,
      );
    }

    return CaseAttachmentModel(
      id: json['id'] as String? ?? 'att-${DateTime.now().millisecondsSinceEpoch}',
      caseId: (json['case_id'] ?? json['patient_case_id']) as String?,
      patientId: (json['patient_id'] ?? json['patient_user_id']) as String?,
      uploadedBy: json['uploaded_by'] as String?,
      originalFilename: json['original_filename'] as String? ?? 'document',
      storagePath: json['storage_path'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? 'application/pdf',
      fileSizeBytes: (json['file_size_bytes'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      uploadStatus: status,
    );
  }
}
