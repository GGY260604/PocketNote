import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/record.dart';
import 'firestore_service.dart';

class RecordRemoteRepo {
  final FirestoreService _fs;
  RecordRemoteRepo(this._fs);

  int _typeToInt(RecordType t) {
    switch (t) {
      case RecordType.spending:
        return 0;
      case RecordType.income:
        return 1;
      case RecordType.transfer:
        return 2;
    }
  }

  RecordType _intToType(int v) {
    switch (v) {
      case 1:
        return RecordType.income;
      case 2:
        return RecordType.transfer;
      default:
        return RecordType.spending;
    }
  }

  Map<String, dynamic> _toMap(Record r) => {
    'id': r.id,
    'type': _typeToInt(r.type),
    'amountCents': r.amountCents,
    'date': Timestamp.fromDate(r.date),
    'title': r.title,
    'tag': r.tag,
    'includeInStats': r.includeInStats,
    'includeInBudget': r.includeInBudget,
    'categoryId': r.categoryId,
    'accountId': r.accountId,
    'fromAccountId': r.fromAccountId,
    'toAccountId': r.toAccountId,
    'serviceChargeCents': r.serviceChargeCents,
    'createdAt': Timestamp.fromDate(r.createdAt),
    'updatedAt': Timestamp.fromDate(r.updatedAt),
    'isDeleted': r.isDeleted,
  };

  Record _fromMap(Map<String, dynamic> m) => Record(
    id: m['id'] as String,
    type: _intToType((m['type'] as num?)?.toInt() ?? 0),
    amountCents: (m['amountCents'] as num?)?.toInt() ?? 0,
    date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    title: m['title'] as String?,
    tag: m['tag'] as String?,
    includeInStats: (m['includeInStats'] as bool?) ?? true,
    includeInBudget: (m['includeInBudget'] as bool?) ?? true,
    categoryId: m['categoryId'] as String?,
    accountId: m['accountId'] as String?,
    fromAccountId: m['fromAccountId'] as String?,
    toAccountId: m['toAccountId'] as String?,
    serviceChargeCents: (m['serviceChargeCents'] as num?)?.toInt() ?? 0,
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isDeleted: (m['isDeleted'] as bool?) ?? false,
  );

  Future<void> upsert(String uid, Record r) async {
    await _fs.recordsCol(uid).doc(r.id).set(_toMap(r), SetOptions(merge: true));
  }

  Future<List<Record>> getAll(String uid) async {
    final snap = await _fs.recordsCol(uid).get();
    return snap.docs.map((d) => _fromMap(d.data())).toList();
  }
}
