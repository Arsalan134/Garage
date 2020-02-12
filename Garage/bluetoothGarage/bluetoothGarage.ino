#include <SoftwareSerial.h>

SoftwareSerial mySerial(10, 11); // TX, RX

int up = 9;
int dayan = 8;
int down = 7;

int delayS = 200;

void setup() {
  mySerial.begin(9600);
  Serial.begin(9600);
  pinMode(up, OUTPUT);
  pinMode(dayan, OUTPUT);
  pinMode(down, OUTPUT);
}

void loop() {

  delay(1000);
  char c;

  if (mySerial.available())
    c = mySerial.read();

  switch (c) {
    case '0':
      digitalWrite(up, HIGH);
      Serial.println("up");
      delay(delayS);
      digitalWrite(up, LOW);
      Serial.println("release");
      break;
    case '1':
      digitalWrite(dayan, HIGH);
      Serial.println("stop");
      delay(delayS);
      digitalWrite(dayan, LOW);
      Serial.println("release");
      break;
    case '2':
      digitalWrite(down, HIGH);
      Serial.println("down");
      delay(delayS);
      digitalWrite(down, LOW);
      Serial.println("release");
      break;
    default:
      digitalWrite(up, LOW);
      digitalWrite(dayan, LOW);
      digitalWrite(down, LOW);
      Serial.println("low");
      break;
  }



}



