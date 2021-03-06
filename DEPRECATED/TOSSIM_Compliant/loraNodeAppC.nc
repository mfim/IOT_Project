#include "loraNode.h"

configuration loraNodeAppC {}

implementation {

  components MainC, loraNodeC as App;

  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC();
  components new FakeSensorC();
  
  //Boot interface
  App.Boot -> MainC.Boot;

  //Control
  App.RadioControl -> Radio;
  App.SerialControl -> Serial;

  //Serial
  App.UartSend -> Serial.AMSend[AM_MY_MSG];
  App.UartPacket -> Serial;
  App.UartAMPacket -> Serial;

  //Radio
  App.RadioSend -> Radio.AMSend[AM_MY_MSG];
  App.RadioReceive -> Radio.Receive[AM_MY_MSG];
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;

}

