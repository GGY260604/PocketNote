import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/account.dart';
import 'firestore_service.dart';

class AccountRemoteRepo {
  final FirestoreService _fs;
  AccountRemoteRepo(this._fs);

  Map<String, dynamic> _toMap(Account a) => {
    'id': a.id,
    'name': a.name,
    'iconCodePoint': a.iconCodePoint,
    'iconFontFamily': a.iconFontFamily,
    'iconBgColorValue': a.iconBgColorValue,
    'balanceCents': a.balanceCents,
    'createdAt': Timestamp.fromDate(a.createdAt),
    'updatedAt': Timestamp.fromDate(a.updatedAt),
    'isDeleted': a.isDeleted,
  };

  Account _fromMap(Map<String, dynamic> m) => Account(
    id: m['id'] as String,
    name: (m['name'] as String?) ?? '',
    iconCodePoint: (m['iconCodePoint'] as num?)?.toInt() ?? 0,
    iconFontFamily: (m['iconFontFamily'] as String?) ?? 'MaterialIcons',
    iconBgColorValue: (m['iconBgColorValue'] as num?)?.toInt() ?? 0xFF777777,
    balanceCents: (m['balanceCents'] as num?)?.toInt() ?? 0,
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isDeleted: (m['isDeleted'] as bool?) ?? false,
  );

  Future<void> upsert(String uid, Account a) async {
    await _fs
        .accountsCol(uid)
        .doc(a.id)
        .set(_toMap(a), SetOptions(merge: true));
  }

  Future<List<Account>> getAll(String uid) async {
    final snap = await _fs.accountsCol(uid).get();
    return snap.docs.map((d) => _fromMap(d.data())).toList();
  }
}
