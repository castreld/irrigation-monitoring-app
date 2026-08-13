import '../models/sensor_data.dart';
import 'api_service.dart';

class MockApiService implements ApiService {
  SensorData _state = const SensorData(
    temperature: 25.5,
    humidity: 60.0,
    soilMoisture: 45.0,
    relayStatus: false,
    autoMode: true,
  );

  @override
  Future<SensorData> fetchStatus() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    if (_state.autoMode) {
      if (_state.soilMoisture < 35) {
        _state = _state.copyWith(relayStatus: true);
      } else if (_state.soilMoisture > 65) {
        _state = _state.copyWith(relayStatus: false);
      }
    }
    double nextMoisture = _state.soilMoisture;
    if (_state.relayStatus) {
      nextMoisture = (nextMoisture + 1.5).clamp(0.0, 100.0);
    } else {
      nextMoisture = (nextMoisture - 0.2).clamp(0.0, 100.0);
    }
    double nextTemp = _state.temperature + (0.1 - 0.2 * (nextMoisture / 100.0));
    _state = _state.copyWith(
      soilMoisture: nextMoisture,
      temperature: nextTemp,
    );
    return _state;
  }

  @override
  Future<void> toggleRelay(bool state) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _state = _state.copyWith(relayStatus: state);
  }

  @override
  Future<void> toggleAutoMode(bool state) async {
    await Future.delayed(const Duration(milliseconds: 500));
    _state = _state.copyWith(autoMode: state);
  }

  @override
  Future<void> updateSchedules(List<String> times) async {
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  void updateToken(String token) {}
}
