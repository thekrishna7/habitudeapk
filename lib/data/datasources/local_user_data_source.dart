import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/app_logger.dart';
import '../models/user_profile_model.dart';

abstract class LocalUserDataSource {
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> deleteUserProfile();
}

class LocalUserDataSourceImpl implements LocalUserDataSource {
  static const String _keyUserProfile = 'habitude_user_profile';
  final SharedPreferences _prefs;

  LocalUserDataSourceImpl(this._prefs);

  @override
  Future<UserProfile?> getUserProfile() async {
    try {
      final jsonString = _prefs.getString(_keyUserProfile);
      if (jsonString == null || jsonString.isEmpty) {
        return null;
      }
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return UserProfile.fromJson(jsonMap);
    } catch (e, st) {
      AppLogger.error('Failed to parse local user profile', e, st);
      return null;
    }
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    try {
      final jsonString = jsonEncode(profile.toJson());
      await _prefs.setString(_keyUserProfile, jsonString);
    } catch (e, st) {
      AppLogger.error('Failed to save local user profile', e, st);
      rethrow;
    }
  }

  @override
  Future<void> deleteUserProfile() async {
    await _prefs.remove(_keyUserProfile);
  }
}
