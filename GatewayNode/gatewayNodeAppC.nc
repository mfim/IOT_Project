/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "gatewayNode.h"

configuration gatewayNodeAppC {}

implementation {

  components MainC, gatewayNodeC as App;
//  components new AMSenderC(AM_MY_MSG);
  components new AMReceiverC(AM_MY_MSG);
  components ActiveMessageC;
  components new SerialAMSenderC(AM_MY_MSG);
//  components new SerialAMReceiverC(AM_MY_MSG);
  components SerialActiveMessageC;
  components new TimerMilliC();

  //Boot interface
  App.Boot -> MainC.Boot;

  //Receive Radio interfaces
  App.Receive -> AMReceiverC;

  //Send Serial interfaces
  App.AMSend -> SerialAMSenderC;

  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
/* check if the renaming works! split to amcontrol in the other file */

  // Serial Control
  App.AMControl -> SerialActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> SerialAMSenderC;
  App.Packet -> SerialAMSenderC;
  App.PacketAcknowledgements-> SerialActiveMessageC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

}
