import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/weather_data.dart';
import '../models/automation_settings.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/weather_service.dart';
import '../services/storage_service.dart';

class IrrigationProvider extends ChangeNotifier {
  final ApiService _apiService;
  final DatabaseService _databaseService;
  final WeatherService _weatherService;
  final StorageService _storageService;
  
  SensorData? _data;
  WeatherData? _weather;
  AutomationSettings _settings = const AutomationSettings(
    cycles: 3,
    scheduledTimes: ['06:00', '12:00', '18:00'],
    pauseIfRaining: true,
  );
  bool _isLoading = false;
  bool _isActionInProgress = false;
  String? _errorMessage;
  Timer? _pollingTimer;
  String? _exportedPath;

  IrrigationProvider({
    required ApiService apiService,
    required DatabaseService databaseService,
    required WeatherService weatherService,
    required StorageService storageService,
  })  : _apiService = apiService,
        _databaseService = databaseService,
        _weatherService = weatherService,
        _storageService = storageService {
    _loadToken();
  }

  void _loadToken() {
    final token = _storageService.getAuthToken();
    if (token != null && token.isNotEmpty) {
      _apiService.updateToken(token);
      fetchStatus(showLoading: true);
    }
  }

  bool get isTokenConfigured {
    final token = _storageService.getAuthToken();
    return token != null && token.isNotEmpty;
  }

  SensorData? get data => _data;
  WeatherData? get weather => _weather;
  AutomationSettings get settings => _settings;
  bool get isLoading => _isLoading;
  bool get isActionInProgress => _isActionInProgress;
  String? get errorMessage => _errorMessage;
  bool get hasData => _data != null;
  String? get exportedPath => _exportedPath;

  Future<void> fetchStatus({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final freshData = await _apiService.fetchStatus();
      _data = freshData;
      _errorMessage = null;
      await _databaseService.insertLog(freshData);

      try {
        final freshWeather = await _weatherService.fetchWeather();
        _weather = freshWeather;
      } catch (_) {}
    } catch (e) {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleRelay(bool targetState) async {
    if (_data == null) return;
    
    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.toggleRelay(targetState);
      await fetchStatus(showLoading: false);
    } catch (e) {
      _errorMessage = 'Gagal mengubah status pompa: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> toggleAutoMode(bool targetState) async {
    if (_data == null) return;

    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.toggleAutoMode(targetState);
      await fetchStatus(showLoading: false);
    } catch (e) {
      _errorMessage = 'Gagal mengubah mode otomatis: ${e.toString().replaceAll('Exception: ', '')}';
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) {
      fetchStatus(showLoading: false);
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<List<Map<String, dynamic>>> getHistoricalLogs() async {
    return await _databaseService.getRecentLogs();
  }

  Future<void> exportData() async {
    _exportedPath = await _databaseService.exportLogsToCSV();
  }

  Future<void> updateAutomationSettings(AutomationSettings newSettings) async {
    _isActionInProgress = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _apiService.updateSchedules(newSettings.scheduledTimes);
      _settings = newSettings;
    } catch (e) {
      _errorMessage = 'Gagal memperbarui jadwal di Blynk: ${e.toString().replaceAll('Exception: ', '')}';
      rethrow;
    } finally {
      _isActionInProgress = false;
      notifyListeners();
    }
  }

  Future<void> saveAuthToken(String token) async {
    await _storageService.saveAuthToken(token);
    _apiService.updateToken(token);
    await fetchStatus(showLoading: true);
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
