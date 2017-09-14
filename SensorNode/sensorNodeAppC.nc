/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sensorNode.h"

configuration sensorNodeAppC {}

implementation {

  components MainC, sensorNodeC as App;
  components new AMSenderC(AM_MY_MSG);
  components ActiveMessageC;
  components new TimerMilliC();
  components new FakeSensorC();
  
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.AMSend -> AMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;
  App.PacketAcknowledgements->ActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;

}

