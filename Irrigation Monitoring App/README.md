# Smart Farming: Sistem Pemantauan Irigasi Pintar

Proyek ini adalah sistem pemantauan dan otomatisasi irigasi pertanian berbasis Internet of Things (IoT) menggunakan mikrokontroler ESP8266, sensor lingkungan, Blynk Cloud API, dan aplikasi mobile Flutter.

---

## Prasyarat Sistem

### Kebutuhan Perangkat Keras
- Mikrokontroler NodeMCU ESP8266
- Sensor Suhu & Kelembaban Udara DHT11
- Sensor Kelembaban Tanah (Soil Moisture Sensor) analog
- Modul Relay 5V & Pompa Air Solenoid
- Kabel Jumper & Breadboard

### Kebutuhan Perangkat Lunak
- Flutter SDK v3.10.7 atau versi terbaru
- Android Studio / VS Code dengan plugin Flutter
- Arduino IDE untuk memprogram ESP8266

---

## Konfigurasi Blynk Cloud Datastream

Sebelum menjalankan perangkat keras dan aplikasi, konfigurasikan pin virtual berikut pada template Blynk Cloud Anda:

| Pin Virtual | Nama Datastream | Tipe Data | Deskripsi |
|---|---|---|---|
| V0 | Suhu | Double / Decimal | Nilai suhu lingkungan (°C) |
| V1 | Kelembaban Udara | Double / Decimal | Kadar kelembaban udara (%) |
| V2 | Kelembaban Tanah | Double / Decimal | Kadar kelembaban air tanah (%) |
| V3 | Pompa Air | Integer (0/1) | Status pompa air (0 = Mati, 1 = Menyala) |
| V4 | Mode Otomatis | Integer (0/1) | Status otomatisasi pompa berdasarkan sensor |
| V10 - V12 | Jadwal Siklus | String | Waktu eksekusi penyiraman terjadwal |

---

## Panduan Arduino IDE

### Pustaka Arduino yang Diperlukan
Instal pustaka berikut melalui menu **Library Manager** di Arduino IDE sebelum melakukan kompilasi:
1. **ESP8266WiFi** (Bawaan board ESP8266)
2. **Blynk** oleh Volodymyr Shymanskyy (v1.3.2+)
3. **DHT sensor library** oleh Adafruit (v1.4.6+)
4. **Adafruit Unified Sensor** oleh Adafruit (v1.1.14+)

### Kode Firmware Arduino ESP8266

```cpp
#define BLYNK_TEMPLATE_ID "TMPLxxxxxx"
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
}
```

---

## Alur Kerja Aplikasi Flutter

### Fitur Utama
1. **Onboarding & Token Dinamis**: Pengguna memasukkan token autentikasi Blynk saat pertama kali membuka aplikasi. Token disimpan secara persisten di penyimpanan lokal perangkat.
2. **Dashboard Real-Time**: Polling otomatis data sensor dari cloud setiap 5 detik dengan grafik visual perkiraan cuaca di Lembang, Jawa Barat.
3. **Kontrol Manual & Otomatisasi**: Sakelar kendali pompa dan mode otomatis terhubung langsung ke pin virtual Blynk.
4. **Pengaturan Penjadwalan Siklus**: Form dinamis yang menyesuaikan jumlah siklus penyiraman secara kronologis dengan validasi waktu berurutan.
5. **Analisis Tren & Riwayat**: Grafik tren kelembaban tanah harian menggunakan basis data lokal SQLite.
6. **Ekspor Laporan CSV**: Konversi riwayat sensor ke file CSV yang dapat dibagikan ke aplikasi eksternal via native sharing sheet.
