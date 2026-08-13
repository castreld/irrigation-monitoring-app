import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  final http.Client _client;
  final String _apiKey = 'YOUR_API_KEY';

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  Future<WeatherData> fetchWeather() async {
    final url = Uri.parse(
      'https://api.openweathermap.org/data/2.5/weather?q=Lembang,ID&appid=$_apiKey&units=metric',
    );

    try {
      final response = await _client.get(url).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Gagal mengambil data cuaca. Kode status: ${response.statusCode}');
      }
    } on SocketException {
      throw const SocketException('Koneksi internet terputus. Gagal mengambil data cuaca.');
    } on TimeoutException {
      throw TimeoutException('Waktu koneksi habis saat mengambil data cuaca.');
    } catch (e) {
      throw Exception('Gagal mengambil data cuaca: ${e.toString().replaceAll('Exception: ', '')}');
    }
  }
}
