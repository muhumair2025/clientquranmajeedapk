import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/foundation.dart';

/// Service for managing Mushaf (Quran page images) SQLite databases
/// Handles coordinate mapping and ayah text retrieval
class MushafDatabaseService {
  static Database? _ayahInfoDb;
  static Database? _arabicTextDb;
  
  static const String _ayahInfoDbName = 'ayahinfo_1352.db';
  static const String _arabicTextDbName = 'quran.ar.uthmani.db';
  
  /// Initialize both databases
  static Future<void> initialize() async {
    try {
      await Future.wait([
        _initAyahInfoDatabase(),
        _initArabicTextDatabase(),
      ]);
      debugPrint('✅ Mushaf databases initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing Mushaf databases: $e');
      rethrow;
    }
  }
  
  /// Initialize the ayah info database (coordinates)
  static Future<void> _initAyahInfoDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _ayahInfoDbName);
      
      // Always re-copy from assets to ensure latest version
      final exists = await databaseExists(path);
      if (exists) {
        await deleteDatabase(path);
        debugPrint('🔄 Deleted existing ayahinfo database for fresh copy');
      }
      
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      
      final data = await rootBundle.load('assets/Mushaf/1441/databases/$_ayahInfoDbName');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('✅ Copied ayahinfo database to $path (${bytes.length} bytes)');
      
      _ayahInfoDb = await openDatabase(path, readOnly: true);
      debugPrint('✅ Opened ayahinfo database');
    } catch (e) {
      debugPrint('❌ Error initializing ayahinfo database: $e');
      rethrow;
    }
  }
  
  /// Initialize the Arabic text database
  static Future<void> _initArabicTextDatabase() async {
    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, _arabicTextDbName);
      
      // Always re-copy from assets to ensure latest version
      // Delete existing database if it exists
      final exists = await databaseExists(path);
      if (exists) {
        await deleteDatabase(path);
        debugPrint('🔄 Deleted existing Arabic text database for fresh copy');
      }
      
      // Copy from assets
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
      
      final data = await rootBundle.load('assets/Mushaf/1441/databases/$_arabicTextDbName');
      final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      debugPrint('✅ Copied Arabic text database to $path (${bytes.length} bytes)');
      
      _arabicTextDb = await openDatabase(path, readOnly: true);
      
      // Verify table exists
      final tables = await _arabicTextDb!.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name='arabic_text'"
      );
      if (tables.isEmpty) {
        debugPrint('❌ arabic_text table NOT found in database!');
      } else {
        debugPrint('✅ arabic_text table verified');
      }
      
      debugPrint('✅ Opened Arabic text database');
    } catch (e) {
      debugPrint('❌ Error initializing Arabic text database: $e');
      rethrow;
    }
  }
  
  /// Get all glyphs (word segments) for a specific page
  static Future<List<GlyphInfo>> getGlyphsForPage(int pageNumber) async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    try {
      final results = await _ayahInfoDb!.query(
        'glyphs',
        where: 'page_number = ?',
        whereArgs: [pageNumber],
        orderBy: 'line_number ASC, position ASC',
      );
      
      return results.map((row) => GlyphInfo.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching glyphs for page $pageNumber: $e');
      return [];
    }
  }
  
  /// Get all glyphs for a specific ayah (for highlighting)
  static Future<List<GlyphInfo>> getGlyphsForAyah(int surahNumber, int ayahNumber) async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    try {
      final results = await _ayahInfoDb!.query(
        'glyphs',
        where: 'sura_number = ? AND ayah_number = ?',
        whereArgs: [surahNumber, ayahNumber],
        orderBy: 'page_number ASC, line_number ASC, position ASC',
      );
      
      return results.map((row) => GlyphInfo.fromMap(row)).toList();
    } catch (e) {
      debugPrint('❌ Error fetching glyphs for ayah $surahNumber:$ayahNumber: $e');
      return [];
    }
  }
  
  /// Find which ayah was tapped based on coordinates
  /// Returns the surah and ayah number, or null if no ayah found
  static Future<AyahLocation?> findAyahByCoordinates(int pageNumber, double x, double y) async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    try {
      // Query glyphs where the tap coordinates fall within the bounding box
      final results = await _ayahInfoDb!.query(
        'glyphs',
        where: 'page_number = ? AND min_x <= ? AND max_x >= ? AND min_y <= ? AND max_y >= ?',
        whereArgs: [pageNumber, x, x, y, y],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        final row = results.first;
        return AyahLocation(
          surahNumber: row['sura_number'] as int,
          ayahNumber: row['ayah_number'] as int,
          pageNumber: row['page_number'] as int,
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error finding ayah by coordinates: $e');
      return null;
    }
  }
  
  /// Get Arabic text for a specific ayah
  static Future<String?> getArabicText(int surahNumber, int ayahNumber) async {
    if (_arabicTextDb == null) {
      throw Exception('Arabic text database not initialized');
    }
    
    try {
      final results = await _arabicTextDb!.query(
        'arabic_text',
        columns: ['text'],
        where: 'sura = ? AND ayah = ?',
        whereArgs: [surahNumber, ayahNumber],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return results.first['text'] as String?;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching Arabic text for ayah $surahNumber:$ayahNumber: $e');
      return null;
    }
  }
  
  /// Get page number for a specific surah
  static Future<int?> getPageForSurah(int surahNumber) async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    try {
      final results = await _ayahInfoDb!.query(
        'glyphs',
        columns: ['page_number'],
        where: 'sura_number = ? AND ayah_number = 1',
        whereArgs: [surahNumber],
        limit: 1,
      );
      
      if (results.isNotEmpty) {
        return results.first['page_number'] as int?;
      }
      
      return null;
    } catch (e) {
      debugPrint('❌ Error fetching page for surah $surahNumber: $e');
      return null;
    }
  }
  
  /// Get page number for a specific para (juz)
  static Future<int?> getPageForPara(int paraNumber) async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    // Para-to-page mapping (standard Mushaf)
    const paraPages = {
      1: 1, 2: 22, 3: 42, 4: 62, 5: 82, 6: 102, 7: 122, 8: 142,
      9: 162, 10: 182, 11: 202, 12: 222, 13: 242, 14: 262, 15: 282,
      16: 302, 17: 322, 18: 342, 19: 362, 20: 382, 21: 402, 22: 422,
      23: 442, 24: 462, 25: 482, 26: 502, 27: 522, 28: 542, 29: 562, 30: 582,
    };
    
    return paraPages[paraNumber];
  }
  
  /// Get starting surah and ayah info for a specific para (juz)
  static Future<Map<String, int>?> getParaInfo(int paraNumber) async {
    // Para starting points (surah, ayah) - standard Mushaf
    const paraStartPoints = {
      1: {'startSurah': 1, 'startAyah': 1},       // Al-Fatiha 1
      2: {'startSurah': 2, 'startAyah': 142},     // Al-Baqara 142
      3: {'startSurah': 2, 'startAyah': 253},     // Al-Baqara 253
      4: {'startSurah': 3, 'startAyah': 93},      // Aal-e-Imran 93
      5: {'startSurah': 4, 'startAyah': 24},      // An-Nisa 24
      6: {'startSurah': 4, 'startAyah': 148},     // An-Nisa 148
      7: {'startSurah': 5, 'startAyah': 83},      // Al-Ma'idah 83
      8: {'startSurah': 6, 'startAyah': 111},     // Al-An'am 111
      9: {'startSurah': 7, 'startAyah': 88},      // Al-A'raf 88
      10: {'startSurah': 8, 'startAyah': 41},     // Al-Anfal 41
      11: {'startSurah': 9, 'startAyah': 93},     // At-Tawbah 93
      12: {'startSurah': 11, 'startAyah': 6},     // Hud 6
      13: {'startSurah': 12, 'startAyah': 53},    // Yusuf 53
      14: {'startSurah': 15, 'startAyah': 1},     // Al-Hijr 1
      15: {'startSurah': 17, 'startAyah': 1},     // Al-Isra 1
      16: {'startSurah': 18, 'startAyah': 75},    // Al-Kahf 75
      17: {'startSurah': 21, 'startAyah': 1},     // Al-Anbiya 1
      18: {'startSurah': 23, 'startAyah': 1},     // Al-Mu'minun 1
      19: {'startSurah': 25, 'startAyah': 21},    // Al-Furqan 21
      20: {'startSurah': 27, 'startAyah': 56},    // An-Naml 56
      21: {'startSurah': 29, 'startAyah': 46},    // Al-Ankabut 46
      22: {'startSurah': 33, 'startAyah': 31},    // Al-Ahzab 31
      23: {'startSurah': 36, 'startAyah': 28},    // Ya-Sin 28
      24: {'startSurah': 39, 'startAyah': 32},    // Az-Zumar 32
      25: {'startSurah': 41, 'startAyah': 47},    // Fussilat 47
      26: {'startSurah': 46, 'startAyah': 1},     // Al-Ahqaf 1
      27: {'startSurah': 51, 'startAyah': 31},    // Adh-Dhariyat 31
      28: {'startSurah': 58, 'startAyah': 1},     // Al-Mujadila 1
      29: {'startSurah': 67, 'startAyah': 1},     // Al-Mulk 1
      30: {'startSurah': 78, 'startAyah': 1},     // An-Naba 1
    };
    
    return paraStartPoints[paraNumber];
  }
  
  /// Get all surahs with their starting pages
  static Future<Map<int, int>> getSurahPageMapping() async {
    if (_ayahInfoDb == null) {
      throw Exception('Ayah info database not initialized');
    }
    
    try {
      final results = await _ayahInfoDb!.rawQuery(
        'SELECT DISTINCT sura_number, MIN(page_number) as page_number FROM glyphs WHERE ayah_number = 1 GROUP BY sura_number ORDER BY sura_number'
      );
      
      final Map<int, int> mapping = {};
      for (var row in results) {
        mapping[row['sura_number'] as int] = row['page_number'] as int;
      }
      
      return mapping;
    } catch (e) {
      debugPrint('❌ Error fetching surah-page mapping: $e');
      return {};
    }
  }
  
  /// Close databases
  static Future<void> close() async {
    await _ayahInfoDb?.close();
    await _arabicTextDb?.close();
    _ayahInfoDb = null;
    _arabicTextDb = null;
    debugPrint('✅ Mushaf databases closed');
  }
}

/// Model for glyph (word segment) information
class GlyphInfo {
  final int glyphId;
  final int pageNumber;
  final int lineNumber;
  final int surahNumber;
  final int ayahNumber;
  final int position;
  final int minX;
  final int maxX;
  final int minY;
  final int maxY;
  
  GlyphInfo({
    required this.glyphId,
    required this.pageNumber,
    required this.lineNumber,
    required this.surahNumber,
    required this.ayahNumber,
    required this.position,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
  
  factory GlyphInfo.fromMap(Map<String, dynamic> map) {
    return GlyphInfo(
      glyphId: map['glyph_id'] as int,
      pageNumber: map['page_number'] as int,
      lineNumber: map['line_number'] as int,
      surahNumber: map['sura_number'] as int,
      ayahNumber: map['ayah_number'] as int,
      position: map['position'] as int,
      minX: map['min_x'] as int,
      maxX: map['max_x'] as int,
      minY: map['min_y'] as int,
      maxY: map['max_y'] as int,
    );
  }
  
  /// Get bounding rectangle for this glyph
  /// Scaled to screen coordinates
  Rect getScaledRect(double scaleX, double scaleY) {
    return Rect.fromLTRB(
      minX * scaleX,
      minY * scaleY,
      maxX * scaleX,
      maxY * scaleY,
    );
  }
  
  @override
  String toString() {
    return 'Glyph(page: $pageNumber, line: $lineNumber, surah: $surahNumber, ayah: $ayahNumber, bounds: ($minX,$minY)-($maxX,$maxY))';
  }
}

/// Model for ayah location
class AyahLocation {
  final int surahNumber;
  final int ayahNumber;
  final int pageNumber;
  
  AyahLocation({
    required this.surahNumber,
    required this.ayahNumber,
    required this.pageNumber,
  });
  
  @override
  String toString() => 'Surah $surahNumber, Ayah $ayahNumber (Page $pageNumber)';
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AyahLocation &&
        other.surahNumber == surahNumber &&
        other.ayahNumber == ayahNumber;
  }
  
  @override
  int get hashCode => surahNumber.hashCode ^ ayahNumber.hashCode;
}


