import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/category.dart';
import 'firestore_service.dart';

class CategoryRemoteRepo {
  final FirestoreService _fs;
  CategoryRemoteRepo(this._fs);

  int _typeToInt(CategoryType t) => t == CategoryType.spending ? 0 : 1;
  CategoryType _intToType(int v) =>
      v == 0 ? CategoryType.spending : CategoryType.income;

  Map<String, dynamic> _toMap(Category c) => {
    'id': c.id,
    'type': _typeToInt(c.type),
    'name': c.name,
    'iconCodePoint': c.iconCodePoint,
    'iconFontFamily': c.iconFontFamily,
    'iconBgColorValue': c.iconBgColorValue,
    'createdAt': Timestamp.fromDate(c.createdAt),
    'updatedAt': Timestamp.fromDate(c.updatedAt),
    'isDeleted': c.isDeleted,
  };

  Category _fromMap(Map<String, dynamic> m) => Category(
    id: m['id'] as String,
    type: _intToType((m['type'] as num?)?.toInt() ?? 0),
    name: (m['name'] as String?) ?? '',
    iconCodePoint: (m['iconCodePoint'] as num?)?.toInt() ?? 0,
    iconFontFamily: (m['iconFontFamily'] as String?) ?? 'MaterialIcons',
    iconBgColorValue: (m['iconBgColorValue'] as num?)?.toInt() ?? 0xFF777777,
    createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    updatedAt: (m['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    isDeleted: (m['isDeleted'] as bool?) ?? false,
  );

  Future<void> upsert(String uid, Category c) async {
    await _fs
        .categoriesCol(uid)
        .doc(c.id)
        .set(_toMap(c), SetOptions(merge: true));
  }

  Future<List<Category>> getAll(String uid) async {
    final snap = await _fs.categoriesCol(uid).get();
    return snap.docs.map((d) => _fromMap(d.data())).toList();
  }
}
