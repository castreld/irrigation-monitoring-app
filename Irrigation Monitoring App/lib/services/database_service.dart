import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import '../models/sensor_data.dart';

class DatabaseService {
  static final DatabaseService instance = DatabaseService();
  static Database? _database;

  DatabaseService();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('sensor_logs.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE sensor_logs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp TEXT,
        temperature REAL,
        humidity REAL,
        soilMoisture REAL
      )
    ''');
  }

  Future<void> insertLog(SensorData data) async {
    final db = await database;
    await db.insert(
      'sensor_logs',
      {
        'timestamp': DateTime.now().toIso8601String(),
        'temperature': data.temperature,
        'humidity': data.humidity,
        'soilMoisture': data.soilMoisture,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    final db = await database;
    return await db.query(
      'sensor_logs',
      orderBy: 'timestamp DESC',
      limit: 50,
    );
  }

  Future<String> exportLogsToExcel() async {
    final db = await database;
    final List<Map<String, dynamic>> records = await db.query(
      'sensor_logs',
      orderBy: 'timestamp ASC',
    );

    final excel = Excel.createExcel();
    final sheetObject = excel['Sheet1'];
    sheetObject.appendRow([
      TextCellValue('ID'),
      TextCellValue('Timestamp'),
      TextCellValue('Temperature'),
      TextCellValue('Humidity'),
      TextCellValue('Soil Moisture'),
    ]);

    for (final record in records) {
      sheetObject.appendRow([
        IntCellValue(record['id'] as int),
        TextCellValue(record['timestamp'] as String),
        DoubleCellValue((record['temperature'] as num).toDouble()),
        DoubleCellValue((record['humidity'] as num).toDouble()),
        DoubleCellValue((record['soilMoisture'] as num).toDouble()),
      ]);
    }

    final directory = await getApplicationDocumentsDirectory();
    final file = File(join(directory.path, 'irrigation_logs.xlsx'));
    final fileBytes = excel.save();
    if (fileBytes != null) {
      await file.writeAsBytes(fileBytes);
    }
    return file.path;
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
    }
  }
}
