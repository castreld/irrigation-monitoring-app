# Smart Farming: Smart Irrigation Monitoring System

This project is an Internet of Things (IoT) based smart agricultural irrigation monitoring and automation system using an ESP8266 microcontroller, environmental sensors, Blynk Cloud API, and a Flutter mobile application.

---

## System Prerequisites

### Hardware Requirements
- NodeMCU ESP8266 Microcontroller
- DHT11 Temperature & Humidity Sensor
- Analog Soil Moisture Sensor
- 5V Relay Module & Solenoid Water Pump
- Jumper Wires & Breadboard

### Software Requirements
- Flutter SDK v3.10.7 or later
- Android Studio / VS Code with Flutter plugin
- Arduino IDE to program the ESP8266

---

## Blynk Cloud Datastream Configuration

Configure the following virtual pins on your Blynk Cloud template before running the hardware and application:

| Virtual Pin | Datastream Name | Data Type | Description |
|---|---|---|---|
| V0 | Temperature | Double / Decimal | Ambient temperature value (°C) |
| V1 | Humidity | Double / Decimal | Ambient relative humidity value (%) |
| V2 | Soil Moisture | Double / Decimal | Soil moisture percentage (%) |
| V3 | Water Pump | Integer (0/1) | Solenoid valve status (0 = Off, 1 = On) |
| V4 | Auto Mode | Integer (0/1) | Automation status based on soil moisture |
| V10 - V12 | Schedule | String | Scheduled irrigation execution times |

---

## Arduino IDE Setup

### Required Arduino Libraries
Install the following libraries via the **Library Manager** in the Arduino IDE before compiling:
1. **ESP8266WiFi** (Built-in with ESP8266 board package)
2. **Blynk** by Volodymyr Shymanskyy (v1.3.2+)
3. **DHT sensor library** by Adafruit (v1.4.6+)
4. **Adafruit Unified Sensor** by Adafruit (v1.1.14+)

### ESP8266 Arduino Firmware Code

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

## Flutter Application Workflow

### Main Features
1. **Onboarding & Dynamic Token**: Users enter their Blynk authentication token when launching the app for the first time. The token is persistently saved to local storage via SharedPreferences.
2. **Real-Time Dashboard**: Automatically polls sensor data from the cloud every 5 seconds, displaying ambient conditions and local weather forecasts for Lembang, West Java.
3. **Manual Control & Automation**: Solenoid pump triggers and auto-mode statuses are directly linked to Blynk virtual datastreams.
4. **Dynamic Cycle Settings**: Configures multiple cycle execution times sequentially with chronological validation.
5. **Analytics & Trends**: Visualizes soil moisture logs over time using a local SQLite database table.
6. **Excel Spreadsheet Export**: Exports historical logs to a `.xlsx` spreadsheet and triggers a native sharing panel via share_plus.
