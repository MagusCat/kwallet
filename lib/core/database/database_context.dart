import '../services/credential_store.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

abstract class DatabaseContext {
  Future<Database> get database;
  void notifyChanged();
  CredentialStore get credentials;
  Future<String> resolveDatabasePath();
  Future<void> closeAndReset();
}
