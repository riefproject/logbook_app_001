import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logbook_app_001/services/mongo_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await dotenv.load(fileName: '.env');
  });

  test('connects to MongoDB Atlas through MongoService', () async {
    final MongoService mongoService = MongoService();

    try {
      expect(dotenv.env['MONGODB_URI'], isNotNull);
      await mongoService.connect();
    } catch (error) {
      fail('Koneksi gagal: $error');
    } finally {
      await mongoService.close();
    }
  });
}
