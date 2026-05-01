import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:secure_vault/services/db_service.dart';

final dbServiceProvider = Provider<DbService>((ref) {
  return DbService();
});
