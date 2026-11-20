#ifndef ROBO_EYES_MANAGER_H
#define ROBO_EYES_MANAGER_H

#include <Arduino.h>
#include <Adafruit_SSD1306.h>
#include <FluxGarage_RoboEyes.h>

class RoboEyesManager
{
private:
  Adafruit_SSD1306 &display;
  RoboEyes<Adafruit_SSD1306> roboEyes;

  enum EyeState
  {
    Default,
    Happy,
    Curiosity,
    Sleepy,
    Asleep,
    Angry,
    Scare,
    Scared,
    TiltedLeft,
    TiltedRight,
  } currentState;

  static const unsigned long IDLE_DELAY = 5000;
  static const unsigned long DEEP_SLEEP_DELAY = 10000;
  static const unsigned long ANGRY_DURATION = 5000;
  static const unsigned long HAPPY_DURATION = 500;
  static const unsigned long CURIOSITY_DURATION = 10000;
  static const unsigned long SCARE_DURATION = 4000;
  static const unsigned long SCARED_DURATION = 2000;
  static const unsigned long Tilted_DURATION = 1000;

  unsigned long lastActionTime;
  bool isSpecialAnimation;

  void setDefaultState()
  {
    roboEyes.setMood(DEFAULT);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setAutoblinker(ON, 2, 2);
    roboEyes.setIdleMode(ON, 2, 2);
    roboEyes.setHFlicker(OFF);
    roboEyes.setVFlicker(OFF);
    roboEyes.setSweat(OFF);
    roboEyes.setCuriosity(OFF);
  }

public:
  RoboEyesManager(Adafruit_SSD1306 &disp)
      : display(disp), roboEyes(disp), currentState(Default),
        lastActionTime(0), isSpecialAnimation(false) {}

  void begin(int screenWidth, int screenHeight, int refreshDelay)
  {
    roboEyes.begin(screenWidth, screenHeight, refreshDelay);
    setDefaultState();
    lastActionTime = millis();
  }

  void update()
  {
    unsigned long currentTime = millis();
    unsigned long elapsedTime = currentTime - lastActionTime;

    if (!isSpecialAnimation)
    {
      switch (currentState)
      {
      case Default:
        if (elapsedTime >= IDLE_DELAY)
        {
          unsigned int randomChoice = random(1, 11);
          if (randomChoice > 8)
          {
            enterSleepyState();
            lastActionTime = currentTime;
          }
          else
          {
            enterCuriosityState();
            lastActionTime = currentTime;
          }
        }
        break;

      case Sleepy:
        if (elapsedTime >= DEEP_SLEEP_DELAY)
        {
          enterAsleepState();
          lastActionTime = currentTime;
        }
        break;

      case Angry:
        if (elapsedTime >= ANGRY_DURATION)
        {
          enterDefaultState();
          lastActionTime = currentTime;
        }
        break;
      case Scare:
        if (elapsedTime >= SCARE_DURATION)
        {
          enterDefaultState();
          lastActionTime = currentTime;
        }
        break;
      case Scared:
        if (elapsedTime >= SCARED_DURATION)
        {
          enterScareState();
          lastActionTime = currentTime;
        }
        break;
      case Happy:
        if (elapsedTime >= HAPPY_DURATION)
        {
          enterDefaultState();
          lastActionTime = currentTime;
        }
        break;
      case Curiosity:
        if (elapsedTime >= CURIOSITY_DURATION)
        {
          unsigned int randomChoice = random(1, 11);
          if (randomChoice > 7)
          {
            enterSleepyState();
            lastActionTime = currentTime;
          }
          else
          {
            enterDefaultState();
            lastActionTime = currentTime;
          }
        }
        break;
      case TiltedLeft:
        if (elapsedTime >= Tilted_DURATION)
        {
          enterDefaultState();
          lastActionTime = currentTime;
        }
        break;
      case TiltedRight:
        if (elapsedTime >= Tilted_DURATION)
        {
          enterDefaultState();
          lastActionTime = currentTime;
        }
        break;

      case Asleep:
        break;
      }
    }

    roboEyes.update();
  }

  void isButtonPressed()
  {
    if ((currentState == Asleep || currentState == Sleepy) && !isSpecialAnimation)
    {
      enterAngryState();
      lastActionTime = millis();
    }
    if ((currentState == Default || currentState == Curiosity) && !isSpecialAnimation)
    {
      unsigned int randomChoice = random(1, 11);
      if (randomChoice > 7)
      {
        enterAngryState();
        lastActionTime = millis();
      }
      else
      {
        enterHappyState();
        lastActionTime = millis();
      }
    }
  }

  void isMicTriggered()
  {
    if ((currentState == Asleep) && !isSpecialAnimation)
    {
      unsigned int randomChoice = random(1, 11);
      if (randomChoice > 7)
      {
        enterAngryState();
        lastActionTime = millis();
      }
      else
      {
        enterScaredState();
        lastActionTime = millis();
      }
    }
  }

  void isLifted()
  {
    Serial.print("isLifted");
    Serial.println();
    if ((currentState != Scared) && !isSpecialAnimation)
    {
      enterScaredState();
      lastActionTime = millis();
    }
  }

  void isPutDown()
  {
    Serial.print("isPutDown");
    Serial.println();
    if ((currentState != Scared) && !isSpecialAnimation)
    {
      enterScaredState();
      lastActionTime = millis();
    }
  }

  void isShaken()
  {
    Serial.print("Di goyangkan");
    Serial.println();
    if ((currentState != Scared) && !isSpecialAnimation)
    {
      enterScaredState();
      lastActionTime = millis();
    }
  }

  void isTiltedLeft()
  {
    Serial.print("isTiltedLeft");
    Serial.println();
    enterTiltedLeftState();
  }

  void isTiltedRight()
  {
    Serial.print("isTiltedRight");
    Serial.println();
    enterTiltedRightState();
  }

  void setSpecialAnimation(bool active)
  {
    isSpecialAnimation = active;
  }

private:
  void enterDefaultState()
  {
    currentState = Default;
    setDefaultState();
    Serial.print("CurrentState: Default");
    Serial.println();
  }

  void enterHappyState()
  {
    currentState = Happy;
    roboEyes.setMood(HAPPY);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.anim_laugh();
    roboEyes.setIdleMode(OFF);
    roboEyes.setAutoblinker(OFF);
    Serial.print("CurrentState: Happy");
    Serial.println();
  }

  void enterTiltedLeftState()
  {
    currentState = TiltedLeft;
    roboEyes.setIdleMode(OFF);
    roboEyes.setPosition(W);
    Serial.print("CurrentState: TiltedLeft");
    Serial.println();
  }

  void enterTiltedRightState()
  {
    currentState = TiltedRight;
    roboEyes.setIdleMode(OFF);
    roboEyes.setPosition(E);
    Serial.print("CurrentState: TiltedRight");
    Serial.println();
  }

  void enterScaredState()
  {
    currentState = Scared;
    roboEyes.setMood(TIRED);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setSweat(ON);
    roboEyes.setVFlicker(ON, 3);
    roboEyes.setHFlicker(ON, 3);
    roboEyes.setAutoblinker(OFF);
    Serial.print("CurrentState: Scared");
    Serial.println();
  }

  void enterScareState()
  {
    currentState = Scare;
    roboEyes.setMood(TIRED);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setSweat(OFF);
    roboEyes.setVFlicker(ON, 3);
    roboEyes.setHFlicker(ON, 3);
    roboEyes.setAutoblinker(OFF);
    Serial.print("CurrentState: Scare");
    Serial.println();
  }

  void enterCuriosityState()
  {
    currentState = Curiosity;
    roboEyes.setMood(DEFAULT);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setAutoblinker(ON, 2, 2);
    roboEyes.setIdleMode(ON, 2, 2);
    roboEyes.setHFlicker(OFF);
    roboEyes.setSweat(OFF);
    roboEyes.setCuriosity(ON);
    Serial.print("CurrentState: Curiosity");
    Serial.println();
  }

  void enterSleepyState()
  {
    currentState = Sleepy;
    roboEyes.setMood(TIRED);
    roboEyes.setHeight(20, 20);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setSweat(OFF);
    roboEyes.setAutoblinker(ON, 2, 2);
    roboEyes.setIdleMode(OFF);
    Serial.print("CurrentState: Sleepy");
    Serial.println();
  }

  void enterAsleepState()
  {
    currentState = Asleep;
    roboEyes.setMood(DEFAULT);
    roboEyes.setPosition(S);
    roboEyes.setHeight(3, 3);
    roboEyes.setAutoblinker(OFF);
    roboEyes.setIdleMode(OFF);
    roboEyes.setBorderradius(0, 0);
    Serial.print("CurrentState: Asleep");
    Serial.println();
  }

  void enterAngryState()
  {
    currentState = Angry;
    roboEyes.setMood(ANGRY);
    roboEyes.setWidth(32, 32);
    roboEyes.setHeight(36, 36);
    roboEyes.setBorderradius(8, 8);
    roboEyes.setPosition(DEFAULT);
    roboEyes.setHFlicker(ON, 2);
    Serial.print("CurrentState: Angry");
    Serial.println();
  }
};

#endif