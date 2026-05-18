#include <Arduino.h>
#include <WiFi.h>
#include <WiFiUdp.h>
#include <TFT_eSPI.h>
#include <Preferences.h>

#ifndef WIFI_SSID
#error "WIFI_SSID not defined"
#endif

#ifndef WIFI_PASSWORD
#error "WIFI_PASSWORD not defined"
#endif

const char* ssid = WIFI_SSID;
const char* password = WIFI_PASSWORD;

TFT_eSPI tft;
WiFiServer server(80);
Preferences prefs;

// ---------- Display ----------
void displayMessage(const String& msg)
{
  tft.fillScreen(TFT_BLACK);
  tft.setTextColor(TFT_WHITE, TFT_BLACK);
  tft.setTextSize(2);
  tft.setCursor(0, 0);
  tft.println(msg);
}

// ---------- Backup message ----------
void saveMessage(const String& msg)
{
  prefs.begin("display", false);
  prefs.putString("last_msg", msg);
  prefs.end();
}

// ---------- Restore message ----------
void restoreMessage()
{
  prefs.begin("display", true);
  String msg = prefs.getString("last_msg", "No message");
  prefs.end();
  displayMessage(msg);
}

WiFiUDP udp;
const uint16_t DISCOVERY_PORT = 4210;
const char* MAGIC = "DISCOVER_TDONGLE";

void setup()
{
  Serial.begin(115200);

  tft.init();
  tft.setRotation(1);

  restoreMessage();   // ← after a reboot

  WiFi.begin(ssid, password);
  while (WiFi.status() != WL_CONNECTED) {
    delay(300);
    Serial.print(".");
  }

  Serial.println("\nWiFi connected");
  Serial.println(WiFi.localIP());
  
  udp.begin(DISCOVERY_PORT);

  server.begin();
}

// Decode URL-encoded string (e.g., %3F -> ?)
String urlDecode(String input) {
  String output = "";
  for (int i = 0; i < input.length(); i++) {
    if (input[i] == '%' && i + 2 < input.length()) {
      String hex = input.substring(i + 1, i + 3);
      char c = (char)strtol(hex.c_str(), NULL, 16);
      output += c;
      i += 2;
    } else if (input[i] == '+') {
      output += ' ';
    } else {
      output += input[i];
    }
  }
  return output;
}

void loop()
{
  // ---------- HTTP Server ----------
  WiFiClient client = server.available();
  if (client) {
    String req = client.readStringUntil('\r');
    client.flush();

    int idx = req.indexOf("msg=");
    if (idx > 0) {
      String msg = req.substring(idx + 4);
      msg = msg.substring(0, msg.indexOf(' '));
      msg = urlDecode(msg);

      displayMessage(msg);
      saveMessage(msg);
    }

    client.print(
      "HTTP/1.1 200 OK\r\n"
      "Content-Type: text/plain\r\n"
      "Connection: close\r\n\r\n"
      "OK"
    );
    client.stop();
  }

  // ---------- UDP Discovery ----------
  int packetSize = udp.parsePacket();
  if (packetSize > 0) {
    char buffer[64];
    int len = udp.read(buffer, sizeof(buffer) - 1);
    if (len <= 0) return;

    buffer[len] = '\0';

    if (strcmp(buffer, MAGIC) == 0) {
      String response = "TDONGLE@";
      response += WiFi.localIP().toString();

      udp.beginPacket(udp.remoteIP(), udp.remotePort());
      udp.print(response);
      udp.endPacket();
    }
  }
}
