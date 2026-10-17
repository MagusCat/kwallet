import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class RewardEvents {
  static Future<void> award(DatabaseExecutor db, String key, int points) async {
    await db.insert('reward_events', {
      'id': key,
      'points': points,
      'created_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
