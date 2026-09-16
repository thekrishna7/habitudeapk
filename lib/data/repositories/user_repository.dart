import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/storage_service.dart';
import '../datasources/local_user_data_source.dart';
import '../models/user_profile_model.dart';

final localUserDataSourceProvider = Provider<LocalUserDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocalUserDataSourceImpl(prefs);
});

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dataSource = ref.watch(localUserDataSourceProvider);
  return UserRepositoryImpl(dataSource);
});

abstract class UserRepository {
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<void> deleteUserProfile();
}

class UserRepositoryImpl implements UserRepository {
  final LocalUserDataSource _localDataSource;

  UserRepositoryImpl(this._localDataSource);

  @override
  Future<UserProfile?> getUserProfile() {
    return _localDataSource.getUserProfile();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) {
    return _localDataSource.saveUserProfile(profile);
  }

  @override
  Future<void> deleteUserProfile() {
    return _localDataSource.deleteUserProfile();
  }
}
