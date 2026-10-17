import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/supabase/supabase_config.dart';
import '../../../../core/supabase/supabase_service.dart';
import '../models/patient_care_note_model.dart';

/// Clinical Care Notes Repository for Clinova.
///
/// Manages care notes and clinical observations for the patient.
/// Backed by local storage with reactive stream broadcasts and Supabase sync.
class PatientCareNotesRepository {
  PatientCareNotesRepository._();

  static final PatientCareNotesRepository instance = PatientCareNotesRepository._();

  static const String _storageKey = 'clinova_patient_care_notes';

  final List<PatientCareNote> _notes = [];
  final StreamController<List<PatientCareNote>> _notesController =
      StreamController<List<PatientCareNote>>.broadcast();

  Stream<List<PatientCareNote>> get notesStream => _notesController.stream;
  List<PatientCareNote> get notes => List.unmodifiable(_notes);
  PatientCareNote? get latestNote => _notes.isNotEmpty ? _notes.first : null;

  Future<void> init() async {
    _notes.clear();
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedJson = prefs.getString(_storageKey);
      if (savedJson != null && savedJson.trim().isNotEmpty) {
        final decoded = jsonDecode(savedJson) as List<dynamic>;
        for (final item in decoded) {
          if (item is Map<String, dynamic>) {
            _notes.add(PatientCareNote.fromJson(item));
          }
        }
      }
    } catch (_) {
      // Fallback gracefully without fabricating data
    }
    _notesController.add(List.unmodifiable(_notes));

    final client = SupabaseConfig.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((_) {
        fetchNotesFromSupabase();
      });
      await fetchNotesFromSupabase();
    }
  }

  /// Fetches published care notes for this patient from Supabase
  Future<void> fetchNotesFromSupabase() async {
    final client = SupabaseConfig.client;
    if (client == null) return;
    try {
      final response = await client
          .from(SupabaseService.tablePatientCareNotes)
          .select()
          .order('published_at', ascending: false);

      final List<PatientCareNote> fetched = [];
      for (final row in response as List) {
        final map = row as Map<String, dynamic>;
        fetched.add(PatientCareNote(
          id: map['id']?.toString() ?? 'care-note-${DateTime.now().millisecondsSinceEpoch}',
          text: map['note_text'] as String? ?? '',
          date: map['published_at'] != null ? DateTime.tryParse(map['published_at'] as String) : null,
          author: map['author_name'] as String? ?? 'Attending Physician',
          category: map['category'] as String? ?? 'Doctor Review',
        ));
      }

      if (fetched.isNotEmpty) {
        _notes.clear();
        _notes.addAll(fetched);
        _notesController.add(List.unmodifiable(_notes));
      }
    } catch (e) {
      debugPrint('[PatientCareNotesRepository] Error fetching care notes from Supabase: $e');
    }
  }

  Future<void> addNote(PatientCareNote note) => saveNote(note);

  Future<void> saveNote(PatientCareNote note) async {
    final existingIndex = _notes.indexWhere((n) => n.id == note.id);
    if (existingIndex != -1) {
      _notes[existingIndex] = note;
    } else {
      _notes.insert(0, note);
    }
    _notesController.add(_notes);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> saveNotes(List<PatientCareNote> notes) async {
    _notes.clear();
    _notes.addAll(notes);
    _notesController.add(_notes);
    try {
      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(_notes.map((n) => n.toJson()).toList());
      await prefs.setString(_storageKey, encoded);
    } catch (_) {}
  }

  Future<void> clearNotes() async {
    _notes.clear();
    _notesController.add(_notes);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (_) {}
  }
}
