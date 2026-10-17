import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../features/bodega/models/transaction_record.dart';
import 'reward_events.dart';

class TransactionWriter {
  static Future<void> insert(Transaction txn, TransactionRecord tx) async {
    if (!tx.amount.isFinite || tx.amount <= 0) {
      throw ArgumentError('El monto debe ser mayor a cero');
    }
    if (!['expense', 'income', 'transfer'].contains(tx.type)) {
      throw ArgumentError('Tipo de movimiento inválido');
    }
    final source = await txn.query(
      'accounts',
      where: 'id = ? AND is_archived = 0',
      whereArgs: [tx.accountId],
    );
    if (source.isEmpty) throw StateError('La cuenta ya no está disponible');
    if (tx.type == 'transfer') {
      final target = await txn.query(
        'accounts',
        where: 'id = ? AND is_archived = 0',
        whereArgs: [tx.toAccountId],
      );
      if (tx.accountId == tx.toAccountId || target.isEmpty) {
        throw ArgumentError('Selecciona otra cuenta de destino');
      }
    }
    await txn.insert('transactions', tx.toMap());
    await RewardEvents.award(txn, 'transaction:${tx.id}', 5);
    final delta = tx.type == 'income' ? tx.amount : -tx.amount;
    await txn.rawUpdate(
      'UPDATE accounts SET balance = ROUND(balance + ?, 8) WHERE id = ?',
      [delta, tx.accountId],
    );
    if (tx.type == 'transfer') {
      await txn.rawUpdate(
        'UPDATE accounts SET balance = ROUND(balance + ?, 8) WHERE id = ?',
        [tx.amount, tx.toAccountId],
      );
    }
  }
}
