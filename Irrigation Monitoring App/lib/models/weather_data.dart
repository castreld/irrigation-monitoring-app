class WeatherData {
  final double temperature;
  final String condition;
  final String iconCode;

  const WeatherData({
    required this.temperature,
    required this.condition,
    required this.iconCode,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final main = json['main'] as Map<String, dynamic>;
    final weatherList = json['weather'] as List<dynamic>;
    final weather = weatherList.first as Map<String, dynamic>;
    return WeatherData(
      temperature: (main['temp'] as num).toDouble(),
      condition: weather['main'] as String,
      iconCode: weather['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'main': {'temp': temperature},
      'weather': [
        {'main': condition, 'icon': iconCode}
      ],
    };
  }
}
