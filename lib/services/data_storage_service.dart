import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../models/glucose_reading.dart';

/// Service for managing local data persistence using SharedPreferences
class DataStorageService {
  static const String _userProfileKey = 'user_profile';
  static const String _glucoseReadingsKey = 'glucose_readings';
  static const String _lastGlucoseKey = 'last_glucose_reading';

  late SharedPreferences _prefs;

  /// Initialize the storage service
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  /// Save user profile to local storage
  Future<bool> saveUserProfile(UserProfile profile) async {
    try {
      final json = jsonEncode(profile.toJson());
      return await _prefs.setString(_userProfileKey, json);
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  /// Load user profile from local storage
  UserProfile? loadUserProfile() {
    try {
      final json = _prefs.getString(_userProfileKey);
      if (json == null) return null;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return UserProfile.fromJson(decoded);
    } catch (e) {
      print('Error loading user profile: $e');
      return null;
    }
  }

  /// Save a glucose reading to history
  Future<bool> saveGlucoseReading(GlucoseReading reading) async {
    try {
      // Save individual reading
      final json = jsonEncode(reading.toJson());
      await _prefs.setString(_lastGlucoseKey, json);

      // Add to history list
      final List<String> readings = _prefs.getStringList(_glucoseReadingsKey) ?? [];
      readings.add(json);
      
      // Keep only last 1000 readings
      if (readings.length > 1000) {
        readings.removeAt(0);
      }
      
      return await _prefs.setStringList(_glucoseReadingsKey, readings);
    } catch (e) {
      print('Error saving glucose reading: $e');
      return false;
    }
  }

  /// Get all glucose readings from history
  List<GlucoseReading> getAllGlucoseReadings() {
    try {
      final List<String>? readingsJson = _prefs.getStringList(_glucoseReadingsKey);
      if (readingsJson == null || readingsJson.isEmpty) return [];
      
      return readingsJson
          .map((json) => GlucoseReading.fromJson(jsonDecode(json) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error loading glucose readings: $e');
      return [];
    }
  }

  /// Get last glucose reading
  GlucoseReading? getLastGlucoseReading() {
    try {
      final json = _prefs.getString(_lastGlucoseKey);
      if (json == null) return null;
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return GlucoseReading.fromJson(decoded);
    } catch (e) {
      print('Error loading last glucose reading: $e');
      return null;
    }
  }

  /// Clear all data (for testing)
  Future<bool> clearAll() async {
    return await _prefs.clear();
  }
}
