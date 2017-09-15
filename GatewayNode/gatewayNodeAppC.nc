#include "gatewayNode.h"

configuration gatewayNodeAppC {}

implementation {

  components MainC, gatewayNodeC as App;
  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);	
  components ActiveMessageC;
  components new TimerMilliC();
 
  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> AMSenderC;
  App.Packet -> AMSenderC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
}

