import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  static const String _cppCode = '''#define BLYNK_TEMPLATE_ID "TMPLxxxxxx"
#define BLYNK_TEMPLATE_NAME "Smart Irrigation"
#define BLYNK_PRINT Serial

#include <ESP8266WiFi.h>
#include <BlynkSimpleEsp8266.h>
#include <DHT.h>

char auth[] = "YOUR_BLYNK_TOKEN";
char ssid[] = "YOUR_WIFI_SSID";
char pass[] = "YOUR_WIFI_PASSWORD";

#define DHTPIN 2
#define DHTTYPE DHT11
#define RELAY_PIN 5
#define SOIL_PIN A0

DHT dht(DHTPIN, DHTTYPE);
BlynkTimer timer;

bool autoMode = true;

void sendSensorData() {
  float h = dht.readHumidity();
  float t = dht.readTemperature();
  int soilVal = analogRead(SOIL_PIN);
  float soilMoisture = (1024.0 - soilVal) / 1024.0 * 100.0;

  if (isnan(h) || isnan(t)) {
    return;
  }

  Blynk.virtualWrite(V0, t);
  Blynk.virtualWrite(V1, h);
  Blynk.virtualWrite(V2, soilMoisture);

  if (autoMode) {
    if (soilMoisture < 35.0) {
      digitalWrite(RELAY_PIN, HIGH);
      Blynk.virtualWrite(V3, 1);
    } else if (soilMoisture > 65.0) {
      digitalWrite(RELAY_PIN, LOW);
      Blynk.virtualWrite(V3, 0);
    }
  }
}

BLYNK_WRITE(V3) {
  int relayState = param.asInt();
  if (!autoMode) {
    digitalWrite(RELAY_PIN, relayState == 1 ? HIGH : LOW);
  }
}

BLYNK_WRITE(V4) {
  autoMode = param.asInt() == 1;
}

BLYNK_WRITE(V10) {
  String schedule = param.asStr();
}

void setup() {
  Serial.begin(115200);
  pinMode(RELAY_PIN, OUTPUT);
  dht.begin();
  Blynk.begin(auth, ssid, pass);
  timer.setInterval(2000L, sendSensorData);
}

void loop() {
  Blynk.run();
  timer.run();
}''';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Panduan Konfigurasi Blynk',
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Konfigurasi Blynk Datastream',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'Pastikan Anda telah mengonfigurasi pin virtual berikut pada dashboard Blynk Cloud Anda:',
                  style: TextStyle(color: Color(0xFF334155), fontSize: 13, height: 1.5),
                ),
                SizedBox(height: 16),
                _DatastreamRow(pin: 'V0', name: 'Suhu', type: 'Double / Decimal (C)'),
                _DatastreamRow(pin: 'V1', name: 'Kelembaban Udara', type: 'Double / Decimal (%)'),
                _DatastreamRow(pin: 'V2', name: 'Kelembaban Tanah', type: 'Double / Decimal (%)'),
                _DatastreamRow(pin: 'V3', name: 'Pompa Air (Relay)', type: 'Integer (0 atau 1)'),
                _DatastreamRow(pin: 'V4', name: 'Mode Otomatis', type: 'Integer (0 atau 1)'),
                _DatastreamRow(pin: 'V10-V12', name: 'Jadwal Siklus', type: 'String (HH:mm)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Boilerplate C++ ESP8266',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Color(0xFF10B981)),
                      onPressed: () {
                        Clipboard.setData(const ClipboardData(text: _cppCode));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Kode C++ berhasil disalin ke papan klip.'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Gunakan kode berikut pada Arduino IDE untuk firmware perangkat ESP8266 Anda. Sesuaikan variabel token dan WiFi Anda.',
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1)),
                  ),
                  child: const SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SelectableText(
                      _cppCode,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatastreamRow extends StatelessWidget {
  final String pin;
  final String name;
  final String type;

  const _DatastreamRow({
    required this.pin,
    required this.name,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: const Color(0xFFD1FAE5)),
            ),
            child: Text(
              pin,
              style: const TextStyle(
                color: Color(0xFF059669),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  type,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
