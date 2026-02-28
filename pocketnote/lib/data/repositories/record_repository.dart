import '../../models/record.dart';
import '../local/record_local_repo.dart';

class RecordRepository {
  final RecordLocalRepo _local;
  RecordRepository(this._local);

  Future<List<Record>> getAll() => _local.getAll();

  Future<void> upsert(Record r) => _local.upsert(r);

  Future<void> softDelete(String id) => _local.softDelete(id);
}
