import 'local_db.dart';
import '../../models/record.dart';

class RecordLocalRepo {
  final box = LocalDb.records();

  Future<List<Record>> getAll() async {
    return box.values.toList();
  }

  Future<void> upsert(Record r) async {
    await box.put(r.id, r);
  }

  Future<void> softDelete(String id) async {
    final r = box.get(id);
    if (r == null) return;
    r.isDeleted = true;
    r.updatedAt = DateTime.now();
    await box.put(id, r);
  }
}
