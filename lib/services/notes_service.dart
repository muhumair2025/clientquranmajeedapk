import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class NotesService {
  static const String _notesKey = 'ayah_notes';
  static Map<String, String> _ayahNotes = {};
  static bool _isLoaded = false;

  /// Initialize the notes service by loading data from SharedPreferences
  static Future<void> initialize() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = prefs.getString(_notesKey);
      
      if (notesJson != null) {
        final Map<String, dynamic> notesMap = json.decode(notesJson);
        _ayahNotes = notesMap.cast<String, String>();
      }
      
      _isLoaded = true;
      debugPrint('Loaded ${_ayahNotes.length} ayah notes');
    } catch (e) {
      debugPrint('Error loading notes: $e');
      _ayahNotes = {};
      _isLoaded = true;
    }
  }

  /// Save notes to SharedPreferences
  static Future<void> _saveNotes() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notesJson = json.encode(_ayahNotes);
      await prefs.setString(_notesKey, notesJson);
      debugPrint('Saved ${_ayahNotes.length} ayah notes');
    } catch (e) {
      debugPrint('Error saving notes: $e');
    }
  }

  /// Add or update a note for an ayah
  static Future<void> addNote(int surahIndex, int ayahIndex, String note) async {
    await initialize();
    
    final key = '${surahIndex}_$ayahIndex';
    if (note.trim().isEmpty) {
      _ayahNotes.remove(key);
    } else {
      _ayahNotes[key] = note.trim();
    }
    await _saveNotes();
  }

  /// Get note for an ayah
  static Future<String?> getNote(int surahIndex, int ayahIndex) async {
    await initialize();
    final key = '${surahIndex}_$ayahIndex';
    return _ayahNotes[key];
  }

  /// Remove note for an ayah
  static Future<void> removeNote(int surahIndex, int ayahIndex) async {
    await initialize();
    final key = '${surahIndex}_$ayahIndex';
    _ayahNotes.remove(key);
    await _saveNotes();
  }

  /// Check if an ayah has a note
  static Future<bool> hasNote(int surahIndex, int ayahIndex) async {
    await initialize();
    final key = '${surahIndex}_$ayahIndex';
    return _ayahNotes.containsKey(key) && _ayahNotes[key]!.isNotEmpty;
  }

  /// Get all notes
  static Future<Map<String, String>> getAllNotes() async {
    await initialize();
    return Map.from(_ayahNotes);
  }

  /// Get count of notes
  static Future<int> getNotesCount() async {
    await initialize();
    return _ayahNotes.length;
  }

  /// Clear all notes
  static Future<void> clearAllNotes() async {
    await initialize();
    _ayahNotes.clear();
    await _saveNotes();
  }
}

/// Model class for ayah with note
class AyahWithNote {
  final int surahIndex;
  final int ayahIndex;
  final String note;
  
  AyahWithNote({
    required this.surahIndex,
    required this.ayahIndex,
    required this.note,
  });

  String get key => '${surahIndex}_$ayahIndex';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AyahWithNote &&
          runtimeType == other.runtimeType &&
          surahIndex == other.surahIndex &&
          ayahIndex == other.ayahIndex;

  @override
  int get hashCode => surahIndex.hashCode ^ ayahIndex.hashCode;

  @override
  String toString() => 'AyahWithNote(surahIndex: $surahIndex, ayahIndex: $ayahIndex)';
}
