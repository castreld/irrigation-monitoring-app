class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final bool relayStatus;
  final bool autoMode;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.relayStatus,
    required this.autoMode,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      temperature: (json['temperature'] as num).toDouble(),
      humidity: (json['humidity'] as num).toDouble(),
      soilMoisture: (json['soilMoisture'] as num).toDouble(),
      relayStatus: json['relayStatus'] as bool,
      autoMode: json['autoMode'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temperature': temperature,
      'humidity': humidity,
      'soilMoisture': soilMoisture,
      'relayStatus': relayStatus,
      'autoMode': autoMode,
    };
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    bool? relayStatus,
    bool? autoMode,
  }) {
    return SensorData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      soilMoisture: soilMoisture ?? this.soilMoisture,
      relayStatus: relayStatus ?? this.relayStatus,
      autoMode: autoMode ?? this.autoMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SensorData &&
        other.temperature == temperature &&
        other.humidity == humidity &&
        other.soilMoisture == soilMoisture &&
        other.relayStatus == relayStatus &&
        other.autoMode == autoMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      temperature,
      humidity,
      soilMoisture,
      relayStatus,
      autoMode,
    );
  }

  @override
  String toString() {
    return 'SensorData(temp: $temperature, hum: $humidity, soil: $soilMoisture, relay: $relayStatus, auto: $autoMode)';
  }
}
