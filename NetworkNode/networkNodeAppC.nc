/**
 *  Configuration file for wiring of **networkNode** module to other common 
 *  components needed for proper functioning
 *
 */
#define NEW_PRINTF_SEMANTICS
#include "../LoraLikeConfig.h"
#include "printf.h"

configuration networkNodeAppC {}

implementation {

  components MainC, networkNodeC as App;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;

  //Boot interface
  App.Boot -> MainC.Boot;

  //Control
  App.RadioControl -> Radio;
  App.SerialControl -> Serial;
  
  //Serial
  App.UartSend -> Serial.AMSend[AM_MY_MSG];
//  App.UartReceive -> Serial.Receive;
  App.UartPacket -> Serial;
  App.UartAMPacket -> Serial;

  //Radio
  App.RadioSend -> Radio.AMSend[AM_MY_ACK];
  App.RadioReceive -> Radio.Receive[AM_MY_MSG];
//  App.RadioSnoop -> Radio.Snoop;
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

}

