// lib/core/utils/id_utils.dart
//
// Generates stable unique ids for local-first entities.
// We use UUID v4 strings to avoid collisions across offline devices.

import 'package:uuid/uuid.dart';

class IdUtils {
  static const Uuid _uuid = Uuid();

  static String newId() => _uuid.v4();
}
