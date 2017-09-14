/**
 *  Configuration file for wiring of **networkNode** module to other common 
 *  components needed for proper functioning
 *
 */

#include "networkNode.h"

configuration networkNodeAppC {}

implementation {

  components MainC, networkNodeC as App;
  components ActiveMessageC as Radio;
  components SerialActiveMessageC as Serial;
  components new TimerMilliC();

  //Boot interface
  App.Boot -> MainC.Boot;

  //Receive Radio interfaces
 // App.Receive -> Radio.AMReceiverC[AM_MY_MSG];

  //Send Serial interfaces
//  App.AMSend -> Serial.AMSendC[AM_MY_MSG];

  //Control
  App.RadioControl -> Radio;
  App.SerialControl -> Serial;
  
  //Serial
  App.UartSend -> Serial.AMSend[AM_MY_MSG];
//  App.UartReceive -> Serial.Receive;
  App.UartPacket -> Serial;
  App.UartAMPacket -> Serial;

  //Radio
//  App.RadioSend -> Radio;
  App.RadioReceive -> Radio.Receive[AM_MY_MSG];
//  App.RadioSnoop -> Radio.Snoop;
  App.RadioPacket -> Radio;
  App.RadioAMPacket -> Radio;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

}

