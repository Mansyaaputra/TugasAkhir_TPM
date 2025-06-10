// filepath: lib/services/database_factory.dart
import 'database_interface.dart';
// Conditional imports
import 'Local_db_mobile.dart' if (dart.library.html) 'Local_db_web.dart';

class DatabaseFactory {
  static DatabaseInterface? _instance;
  
  static DatabaseInterface getInstance() {
    _instance ??= LocalDb.instance;
    return _instance!;
  }
}
