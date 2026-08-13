import '../models/sensor_data.dart';

abstract class ApiService {
  Future<SensorData> fetchStatus();
  Future<void> toggleRelay(bool state);
  Future<void> toggleAutoMode(bool state);
  Future<void> updateSchedules(List<String> times);
  void updateToken(String token);
}
