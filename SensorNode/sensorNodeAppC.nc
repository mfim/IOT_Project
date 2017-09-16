/**
 *  Configuration file for wiring of Sensor Node module to other common 
 *  components needed for proper functioning
 *
 *  @author Matheus Fim and Caio Zuliani 
 */
#define NEW_PRINTF_SEMANTICS
#include "../LoraLikeConfig.h"
#include "printf.h"

configuration sensorNodeAppC {}

implementation {

  components MainC, sensorNodeC as App;
  components new AMSenderC(AM_MY_MSG);
  components ActiveMessageC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1; 
  components PrintfC;
  components SerialStartC;
  components new FakeSensorC();
  
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.AMSend -> AMSenderC;
  App.Receive -> ActiveMessageC.Receive[AM_MY_ACK];

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;

  //Timer interface
  App.MilliTimer -> Timer0;
  App.AckTimer -> Timer1;  

  //Fake Sensor read
  App.Read -> FakeSensorC;

}

