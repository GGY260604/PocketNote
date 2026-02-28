import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/budget.dart';
import 'firestore_service.dart';

class BudgetRemoteRepo {
  final FirestoreService _fs;
  BudgetRemoteRepo(this._fs);

  Map<String, dynamic> _toMap(Budget b) => {
    'id': b.id,
    'monthKey': b.monthKey,
    'categoryId': b.categoryId,
    'amountCents': b.amountCents,
    'createdAt': Timestamp.fromDate(b.createdAt),
    'updatedAt': Timestamp.fromDate(b.updatedAt),
    'isDeleted': b.isDeleted,
  };

  Budget _fromMap(Map<String, dynamic> m) => Budget(
    id: m['id'] as String,
    monthKey: (m['monthKey'] as String?) ?? 'global',
    categoryId: (m['categoryId'] as String?) ?? '',
    amountCents: (m['amountCents'] as num?)?.toInt() ?? 0,
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isDeleted: (m['isDeleted'] as bool?) ?? false,
  );

  Future<void> upsert(String uid, Budget b) async {
    await _fs.budgetsCol(uid).doc(b.id).set(_toMap(b), SetOptions(merge: true));
  }

  Future<List<Budget>> getAll(String uid) async {
    final snap = await _fs.budgetsCol(uid).get();
    return snap.docs.map((d) => _fromMap(d.data())).toList();
  }
}
