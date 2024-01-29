/**
* @author KalleCoder
* @date 2024-01-05
* @version 1.0
* @file Joystick_Car_Leds.ino
* @brief
* This program controlls an ESP32 WROVER. 
* With the parts I will wright below it should immulate the blinkers of a car, the headlight of a card, and at which state the car is in(Gas/Break/Still).
* parts: ESP32 WROVER, Breadboard, Freenove 8 RGB LED Module, Joystick, Jumper F/M x8, Yellow LED x2, Resistor 220Ω x2, Jumper M/M x4. 
* Here is a link to the youtube video showing the build: https://youtu.be/wTZuMti9LjQ 
*/

// headlight and gas/still/break states LED strip
#include "Freenove_WS2812_Lib_for_ESP32.h"

#define LEDS_COUNT 8 // number of leds
#define LEDS_PIN 2 // which pin the led is connected to
#define CHANNEL 0 // RMT module channel 

Freenove_ESP32_WS2812 strip = Freenove_ESP32_WS2812(LEDS_COUNT, LEDS_PIN, CHANNEL, TYPE_GRB); // making the strip object 
int m_color[6][3] = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}, {0, 0, 0}, {255, 255, 255}, {255, 255, 0}}; // last one is yellow
int delayVal = 50;

//Blinker LEDS
#define PIN_LED 15
#define PIN_LED_SECOND 13

int xyzPins[] = {12, 14, 33}; //x, y, z pins

void setup() 
{
  Serial.begin(115200);
  // led setup 
  strip.begin(); 
  turnOnHalfLight();
  // joystick setup
  pinMode(xyzPins[2], INPUT_PULLUP); // z axis is a button
  // initialize digital pin PIN_LED and PIN_LED_SECOND as an output 
  pinMode(PIN_LED, OUTPUT);
  pinMode(PIN_LED_SECOND, OUTPUT); 
}

bool bigBright = false; // to keep track on if the lights are on or not 

void loop() 
{

  // joystick values
  int xVal = analogRead(xyzPins[0]);
  int yVal = analogRead(xyzPins[1]);
  int zVal = digitalRead(xyzPins[2]); // different because its a button 
  //Serial.printf("X, Y, Z: %d,\t%d,\t%d\n", xVal, yVal, zVal);
  //delay(500);

    // headlight 
  if (zVal == 0)
  {
    if (bigBright == false)
    {
      turnOnBrightLight();
      bigBright = true; // So you can turn it of later
    }
    else if (bigBright == true)
    {
      turnOnHalfLight();
      bigBright = false; // so you can turn it on later
    }
  }

  // pressing the gas or breaking
  GasBreak(xVal);


  // Left blinker
  if (yVal > 3000) // middle value for y is 2300 and pressing the joystick dowm when holding on the side like a blinker stick activates it
  {
    Serial.printf("Y: %d\n", yVal);
    Serial.printf("Turning left\n");
    for (int i = 0; i < 3; i++)
    {
      delay(500);
      digitalWrite(PIN_LED, HIGH);
      delay(500);
      digitalWrite(PIN_LED, LOW);
    }
  }

  // right blinker 
  if (yVal < 1700) // middle value for y is 2300 and pressing the joystick up when holding on the side like a blinker stick activates it
  {
    Serial.printf("Y: %d\n", yVal);
    Serial.printf("Turning right\n");
    for (int i = 0; i < 3; i++)
    {
      delay(500);
      digitalWrite(PIN_LED_SECOND, HIGH);
      delay(500);
      digitalWrite(PIN_LED_SECOND, LOW);
    }
  }
}

/**
* @brief
* turns on the top 5 leds and sets to a lower strenght
* mimicing a half-light on a car
*/
void turnOnHalfLight()
{
  strip.setBrightness(5); // low strenght
  for (int i = 1; i < LEDS_COUNT; i++)
  {
    if (i == 1 || i == 7)
    {
      strip.setLedColorData(i, m_color[3][0], m_color[3][1], m_color[3][2]); // turning the bottom ones off execpt the gas/break/still lamp
    }
    else
    {
      strip.setLedColorData(i, m_color[4][0], m_color[4][1], m_color[4][2]); // turning the rest white
    }
    strip.show();
    delay(delayVal);
  } 
}

/**
* @brief
* turns on the all leds and sets to a higher strenght
* mimicing a bright-light on a car
*/
void turnOnBrightLight()
{
  strip.setBrightness(15); // higher strenght
  for (int i = 1; i < LEDS_COUNT; i++)
  {
    strip.setLedColorData(i, m_color[4][0], m_color[4][1], m_color[4][2]); // turning all but the bottom bright white
    strip.show();
    delay(delayVal);
  } 
}

/**
* @brief
* Changes the bottom led into three different colors
* Green when pressing the joystick forward. Representing pressing the gas pedal
* Yellow when the joystick does nothing. Representing not pressing any pedal
* Red when pressing the joystick backwards. Representing pressing the brakes
* @param x Is the x value from the joystick and is needed to determine which state the "car" is in
*/

void GasBreak(int x)
{
  // if you are pressing the gas
  if (x < 1500) // The joystick has an x value around 1900 when its not in motion. 
  {
    strip.setLedColorData(0, m_color[1][0], m_color[1][1], m_color[1][2]); // making the bottom green
    strip.show();
    delay(delayVal);
  }

  // if you are doing nothing
  if (x > 1500 && x < 2300)
  {
    strip.setLedColorData(0, m_color[5][0], m_color[5][1], m_color[5][2]); // making the bottom yellow
    strip.show();
    delay(delayVal);
  }

  // if you are breaking
  if (x > 2300)
  {
    strip.setLedColorData(0, m_color[0][0], m_color[0][1], m_color[0][2]); // making the bottom red
    strip.show();
    delay(delayVal);
  }
}

