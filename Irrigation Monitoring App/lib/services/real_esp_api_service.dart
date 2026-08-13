import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/sensor_data.dart';
import 'api_service.dart';

class RealEspApiService implements ApiService {
  String authToken;
  final http.Client _client;

  RealEspApiService({
    required this.authToken,
    http.Client? client,
  }) : _client = client ?? http.Client();

  double _toDouble(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString()) ?? 0.0;
  }

  bool _toBool(dynamic val) {
    if (val == null) return false;
    if (val is num) return val.toInt() == 1;
    final s = val.toString().trim();
    return s == '1' || s.toLowerCase() == 'true';
  }

  @override
  void updateToken(String token) {
    authToken = token;
  }

  @override
  Future<SensorData> fetchStatus() async {
    final url = Uri.parse(
      'https://blynk.cloud/external/api/get?token=$authToken&v0&v1&v2&v3&v4',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return SensorData(
          temperature: _toDouble(data['v0']),
          humidity: _toDouble(data['v1']),
          soilMoisture: _toDouble(data['v2']),
          relayStatus: _toBool(data['v3']),
          autoMode: _toBool(data['v4']),
        );
      } else {
        throw Exception('Kode status server: ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Koneksi internet terputus. Gagal menghubungkan ke Blynk Cloud.');
    } on TimeoutException {
      throw TimeoutException('Waktu koneksi habis saat menghubungi Blynk Cloud.');
    } catch (e) {
      throw Exception('Gagal menghubungkan ke Blynk Cloud: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Future<void> toggleRelay(bool state) async {
    final val = state ? 1 : 0;
    final url = Uri.parse(
      'https://blynk.cloud/external/api/update?token=$authToken&v3=$val',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('Kode status server: ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Koneksi internet terputus. Gagal memperbarui status pompa.');
    } on TimeoutException {
      throw TimeoutException('Waktu koneksi habis saat memperbarui status pompa.');
    } catch (e) {
      throw Exception('Gagal memperbarui status pompa: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Future<void> toggleAutoMode(bool state) async {
    final val = state ? 1 : 0;
    final url = Uri.parse(
      'https://blynk.cloud/external/api/update?token=$authToken&v4=$val',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) {
        throw Exception('Kode status server: ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Koneksi internet terputus. Gagal memperbarui mode otomatis.');
    } on TimeoutException {
      throw TimeoutException('Waktu koneksi habis saat memperbarui mode otomatis.');
    } catch (e) {
      throw Exception('Gagal memperbarui mode otomatis: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }

  @override
  Future<void> updateSchedules(List<String> times) async {
    try {
      for (int i = 0; i < times.length; i++) {
        final pin = 10 + i;
        final timeStr = Uri.encodeComponent(times[i]);
        final url = Uri.parse(
          'https://blynk.cloud/external/api/update?token=$authToken&v$pin=$timeStr',
        );
        final response = await _client.get(url).timeout(const Duration(seconds: 5));
        if (response.statusCode != 200) {
          throw Exception('Gagal memperbarui V$pin. Kode status: ${response.statusCode}');
        }
      }
    } on SocketException {
      throw const SocketException('Koneksi internet terputus. Gagal memperbarui jadwal di Blynk.');
    } on TimeoutException {
      throw TimeoutException('Waktu koneksi habis saat memperbarui jadwal di Blynk.');
    } catch (e) {
      throw Exception('Gagal memperbarui jadwal di Blynk: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
