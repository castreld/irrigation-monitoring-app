#define BLYNK_PRINT Serial

#include <ESP8266WiFi.h>
#include <ESPAsyncTCP.h>
#include <ESPAsyncWebServer.h>
#include <BlynkSimpleEsp8266.h>
#include <ArduinoJson.h>
#include <DHT.h>

char auth[] = "YOUR_BLYNK_AUTH_TOKEN";
char ssid[] = "YOUR_WIFI_SSID";
char pass[] = "YOUR_WIFI_PASSWORD";

#define DHTPIN D2
#define DHTTYPE DHT11
#define RELAY_PIN D1
const int soilMoisturePin = A0;

#define DRY_VALUE 850
#define WET_VALUE 350

float temperature = 0.0;
float humidity = 0.0;
float soilMoisture = 0.0;
bool relayStatus = false;
bool autoMode = true;

unsigned long lastSensorReadTime = 0;
const unsigned long sensorReadInterval = 2000;

unsigned long pumpUptimeMs = 60000;
unsigned long pumpDowntimeMs = 300000;
unsigned long lastPumpStateChangeTime = 0;

AsyncWebServer server(80);
DHT dht(DHTPIN, DHTTYPE);

BLYNK_WRITE(V3) {
  int value = param.asInt();
  if (!autoMode) {
    relayStatus = (value == 1);
    digitalWrite(RELAY_PIN, relayStatus ? HIGH : LOW);
    Serial.printf("[Blynk] Manual Pump toggle: %s\n", relayStatus ? "ON" : "OFF");
  } else {
    Blynk.virtualWrite(V3, relayStatus ? 1 : 0);
    Serial.println("[Blynk] Manual Pump toggle ignored (Auto Mode is Active)");
  }
}

BLYNK_WRITE(V4) {
  autoMode = (param.asInt() == 1);
  Serial.printf("[Blynk] Auto Mode toggled: %s\n", autoMode ? "ON" : "OFF");
  if (autoMode) {
    lastPumpStateChangeTime = millis();
  }
}

BLYNK_WRITE(V5) {
  float minutes = param.asFloat();
  if (minutes > 0.0) {
    pumpUptimeMs = (unsigned long)(minutes * 60.0 * 1000.0);
    Serial.printf("[Blynk] Pump Uptime updated: %.2f mins (%lu ms)\n", minutes, pumpUptimeMs);
  }
}

BLYNK_WRITE(V6) {
  float minutes = param.asFloat();
  if (minutes > 0.0) {
    pumpDowntimeMs = (unsigned long)(minutes * 60.0 * 1000.0);
    Serial.printf("[Blynk] Pump Downtime updated: %.2f mins (%lu ms)\n", minutes, pumpDowntimeMs);
  }
}

void setup() {
  Serial.begin(115200);
  delay(10);
  Serial.println("\nInitializing Smart Irrigation Node...");

  pinMode(RELAY_PIN, OUTPUT);
  digitalWrite(RELAY_PIN, LOW);
  
  dht.begin();

  Serial.printf("Connecting to Wi-Fi: %s", ssid);
  WiFi.begin(ssid, pass);
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
  }
  Serial.println("\nWi-Fi Connected successfully.");
  Serial.print("Local IP Address: ");
  Serial.println(WiFi.localIP());

  Blynk.config(auth);
  Blynk.connect();

  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Origin", "*");
  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  DefaultHeaders::Instance().addHeader("Access-Control-Allow-Headers", "Content-Type");

  server.on("/api/status", HTTP_OPTIONS, [](AsyncWebServerRequest *request) {
    request->send(200);
  });
  server.on("/api/control", HTTP_OPTIONS, [](AsyncWebServerRequest *request) {
    request->send(200);
  });

  server.on("/api/status", HTTP_GET, [](AsyncWebServerRequest *request) {
    StaticJsonDocument<256> doc;
    doc["temperature"] = temperature;
    doc["humidity"] = humidity;
    doc["soilMoisture"] = soilMoisture;
    doc["relayStatus"] = relayStatus;
    doc["autoMode"] = autoMode;

    String responsePayload;
    serializeJson(doc, responsePayload);
    request->send(200, "application/json", responsePayload);
  });

  server.on("/api/control", HTTP_POST, [](AsyncWebServerRequest *request) {}, NULL, 
    [](AsyncWebServerRequest *request, uint8_t *data, size_t len, size_t index, size_t total) {
      StaticJsonDocument<256> doc;
      DeserializationError error = deserializeJson(doc, data, len);

      if (error) {
        request->send(400, "application/json", "{\"status\":\"error\",\"message\":\"Malformed JSON\"}");
        return;
      }

      if (doc.containsKey("autoMode")) {
        bool targetAutoMode = doc["autoMode"];
        if (targetAutoMode != autoMode) {
          autoMode = targetAutoMode;
          Blynk.virtualWrite(V4, autoMode ? 1 : 0);
          Serial.printf("[API] Auto Mode toggled: %s\n", autoMode ? "ON" : "OFF");
          
          if (autoMode) {
            lastPumpStateChangeTime = millis();
          }
        }
      }

      if (doc.containsKey("relayStatus")) {
        bool targetRelayStatus = doc["relayStatus"];
        if (!autoMode) {
          if (targetRelayStatus != relayStatus) {
            relayStatus = targetRelayStatus;
            digitalWrite(RELAY_PIN, relayStatus ? HIGH : LOW);
            Blynk.virtualWrite(V3, relayStatus ? 1 : 0);
            Serial.printf("[API] Pump state toggled: %s\n", relayStatus ? "ON" : "OFF");
          }
        } else {
          Serial.println("[API] Control ignored: manual relay toggles are disabled in Auto Mode");
        }
      }

      request->send(200, "application/json", "{\"status\":\"success\"}");
    }
  );

  server.begin();
  Serial.println("Local HTTP server running on Port 80.");
}

void loop() {
  if (Blynk.connected()) {
    Blynk.run();
  } else {
    static unsigned long lastReconnectAttempt = 0;
    if (millis() - lastReconnectAttempt > 10000) {
      lastReconnectAttempt = millis();
      Blynk.connect();
    }
  }

  unsigned long currentMillis = millis();

  if (currentMillis - lastSensorReadTime >= sensorReadInterval) {
    lastSensorReadTime = currentMillis;

    float tempReading = dht.readTemperature();
    float humReading = dht.readHumidity();

    if (!isnan(tempReading) && !isnan(humReading)) {
      temperature = tempReading;
      humidity = humReading;
      
      Blynk.virtualWrite(V0, temperature);
      Blynk.virtualWrite(V1, humidity);
    } else {
      Serial.println("[Warning] Failed to read from DHT sensor.");
    }

    int rawMoisture = analogRead(soilMoisturePin);
    int mappedMoisture = map(rawMoisture, DRY_VALUE, WET_VALUE, 0, 100);
    soilMoisture = constrain(mappedMoisture, 0, 100);

    Blynk.virtualWrite(V2, (int)soilMoisture);

    Serial.printf("[Sensors] Temp: %.1fC | Hum: %.1f%% | Soil Moisture: %.1f%% (Raw: %d)\n", 
                  temperature, humidity, soilMoisture, rawMoisture);
  }

  if (autoMode) {
    if (relayStatus) {
      if (currentMillis - lastPumpStateChangeTime >= pumpUptimeMs) {
        relayStatus = false;
        digitalWrite(RELAY_PIN, LOW);
        lastPumpStateChangeTime = currentMillis;
        
        Blynk.virtualWrite(V3, 0);
        Serial.printf("[Automation] Uptime cycle completed (Ran for %lu ms). Pump is now OFF\n", pumpUptimeMs);
      }
    } else {
      if (currentMillis - lastPumpStateChangeTime >= pumpDowntimeMs) {
        relayStatus = true;
        digitalWrite(RELAY_PIN, HIGH);
        lastPumpStateChangeTime = currentMillis;

        Blynk.virtualWrite(V3, 1);
        Serial.printf("[Automation] Downtime cycle completed (Idle for %lu ms). Pump is now ON\n", pumpDowntimeMs);
      }
    }
  }
}
