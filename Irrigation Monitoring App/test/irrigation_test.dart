import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:irrigation_monitoring_app/models/sensor_data.dart';
import 'package:irrigation_monitoring_app/models/weather_data.dart';
import 'package:irrigation_monitoring_app/models/automation_settings.dart';
import 'package:irrigation_monitoring_app/services/mock_api_service.dart';
import 'package:irrigation_monitoring_app/services/database_service.dart';
import 'package:irrigation_monitoring_app/services/weather_service.dart';
import 'package:irrigation_monitoring_app/services/storage_service.dart';
import 'package:irrigation_monitoring_app/providers/irrigation_provider.dart';

class MockDatabaseService extends DatabaseService {
  final List<Map<String, dynamic>> _logs = [];

  @override
  Future<void> insertLog(SensorData data) async {
    _logs.add({
      'timestamp': DateTime.now().toIso8601String(),
      'temperature': data.temperature,
      'humidity': data.humidity,
      'soilMoisture': data.soilMoisture,
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getRecentLogs() async {
    return List.from(_logs.reversed);
  }

  @override
  Future<String> exportLogsToExcel() async {
    return 'mock_path/irrigation_logs.xlsx';
  }
}

class MockWeatherService extends WeatherService {
  @override
  Future<WeatherData> fetchWeather() async {
    return const WeatherData(
      temperature: 24.5,
      condition: 'Rain',
      iconCode: '10d',
    );
  }
}

class MockStorageService implements StorageService {
  String? _token;

  @override
  SharedPreferences? get _prefs => null;

  @override
  set _prefs(SharedPreferences? prefs) {}

  @override
  Future<void> init() async {}

  @override
  String? getAuthToken() => _token;

  @override
  Future<bool> saveAuthToken(String token) async {
    _token = token;
    return true;
  }

  @override
  Future<bool> clearAuthToken() async {
    _token = null;
    return true;
  }
}

void main() {
  group('SensorData Model Tests', () {
    test('fromJson parses valid JSON with double and int values', () {
      final json = {
        'temperature': 25,
        'humidity': 70.5,
        'soilMoisture': 45,
        'relayStatus': false,
        'autoMode': true,
      };

      final data = SensorData.fromJson(json);

      expect(data.temperature, 25.0);
      expect(data.humidity, 70.5);
      expect(data.soilMoisture, 45.0);
      expect(data.relayStatus, false);
      expect(data.autoMode, true);
    });

    test('toJson creates correct map structure', () {
      const data = SensorData(
        temperature: 26.5,
        humidity: 70.0,
        soilMoisture: 45.0,
        relayStatus: false,
        autoMode: true,
      );

      final json = data.toJson();

      expect(json['temperature'], 26.5);
      expect(json['humidity'], 70.0);
      expect(json['soilMoisture'], 45.0);
      expect(json['relayStatus'], false);
      expect(json['autoMode'], true);
    });

    test('copyWith correctly replaces specified fields', () {
      const data = SensorData(
        temperature: 26.5,
        humidity: 70.0,
        soilMoisture: 45.0,
        relayStatus: false,
        autoMode: true,
      );

      final updated = data.copyWith(
        temperature: 28.0,
        relayStatus: true,
      );

      expect(updated.temperature, 28.0);
      expect(updated.humidity, 70.0);
      expect(updated.soilMoisture, 45.0);
      expect(updated.relayStatus, true);
      expect(updated.autoMode, true);
    });
  });

  group('WeatherData Model Tests', () {
    test('fromJson parses weather JSON correctly', () {
      final json = {
        'main': {'temp': 24.5},
        'weather': [
          {'main': 'Rain', 'icon': '10d'}
        ],
      };
      final data = WeatherData.fromJson(json);
      expect(data.temperature, 24.5);
      expect(data.condition, 'Rain');
      expect(data.iconCode, '10d');
    });
  });

  group('AutomationSettings Model Tests', () {
    test('copyWith copies cycles and scheduledTimes', () {
      const settings = AutomationSettings(
        cycles: 3,
        scheduledTimes: ['06:00', '12:00', '18:00'],
        pauseIfRaining: true,
      );
      final updated = settings.copyWith(cycles: 5, pauseIfRaining: false);
      expect(updated.cycles, 5);
      expect(updated.scheduledTimes, const ['06:00', '12:00', '18:00']);
      expect(updated.pauseIfRaining, false);
    });
  });

  group('MockApiService Tests', () {
    late MockApiService mockApi;

    setUp(() {
      mockApi = MockApiService();
    });

    test('fetchStatus returns valid SensorData and simulates delay', () async {
      final startTime = DateTime.now();
      final data = await mockApi.fetchStatus();
      final duration = DateTime.now().difference(startTime);

      expect(duration.inMilliseconds, greaterThanOrEqualTo(900));
      
      expect(data.temperature, isA<double>());
      expect(data.humidity, isA<double>());
      expect(data.soilMoisture, isA<double>());
      expect(data.relayStatus, isA<bool>());
      expect(data.autoMode, isA<bool>());
    });

    test('toggleRelay and toggleAutoMode modify API state', () async {
      await mockApi.toggleAutoMode(false);
      await mockApi.toggleRelay(true);
      
      final data = await mockApi.fetchStatus();
      
      expect(data.relayStatus, true);
      expect(data.autoMode, false);
    });
  });

  group('IrrigationProvider & Database integration tests', () {
    late MockApiService mockApi;
    late MockDatabaseService mockDb;
    late MockWeatherService mockWeather;
    late MockStorageService mockStorage;
    late IrrigationProvider provider;

    setUp(() {
      mockApi = MockApiService();
      mockDb = MockDatabaseService();
      mockWeather = MockWeatherService();
      mockStorage = MockStorageService();
      provider = IrrigationProvider(
        apiService: mockApi,
        databaseService: mockDb,
        weatherService: mockWeather,
        storageService: mockStorage,
      );
    });

    test('fetchStatus logs reading in database', () async {
      expect(await mockDb.getRecentLogs(), isEmpty);

      await provider.fetchStatus(showLoading: false);

      expect(provider.hasData, true);
      final logs = await mockDb.getRecentLogs();
      expect(logs.length, 1);
      expect(logs.first['temperature'], provider.data!.temperature);
      expect(logs.first['humidity'], provider.data!.humidity);
      expect(logs.first['soilMoisture'], provider.data!.soilMoisture);
    });

    test('exportData sets exportedPath in provider', () async {
      await provider.exportData();
      expect(provider.exportedPath, 'mock_path/irrigation_logs.xlsx');
    });

    test('fetchStatus updates weather in provider', () async {
      expect(provider.weather, isNull);
      await provider.fetchStatus(showLoading: false);
      expect(provider.weather, isNotNull);
      expect(provider.weather!.temperature, 24.5);
      expect(provider.weather!.condition, 'Rain');
    });

    test('updateAutomationSettings notifies listeners and updates state', () async {
      expect(provider.settings.cycles, 3);
      const newSettings = AutomationSettings(
        cycles: 6,
        scheduledTimes: ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00'],
        pauseIfRaining: false,
      );
      await provider.updateAutomationSettings(newSettings);
      expect(provider.settings.cycles, 6);
      expect(provider.settings.scheduledTimes, const ['06:00', '08:00', '10:00', '12:00', '14:00', '16:00']);
      expect(provider.settings.pauseIfRaining, false);
    });

    test('saveAuthToken updates token in storage and provider status', () async {
      await provider.saveAuthToken('new_token');
      expect(mockStorage.getAuthToken(), 'new_token');
    });
  });
}
