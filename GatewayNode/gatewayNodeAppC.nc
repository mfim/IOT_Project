#define NEW_PRINTF_SEMANTICS
#include "../LoraLikeConfig.h"
#include "printf.h"

configuration gatewayNodeAppC {}

implementation {
  // we make use of two AM Type to differentiate the message from the ack 
  components MainC, gatewayNodeC as App;
  components new AMSenderC(AM_MY_MSG) as MsgSender;
  components new AMSenderC(AM_MY_ACK) as AckSender;
  components ActiveMessageC;
  components new TimerMilliC();
  components PrintfC;
  components SerialStartC;

  //Boot interface
  App.Boot -> MainC.Boot;

  //Send and Receive interfaces
  App.MsgSend -> MsgSender;
  App.AckSend -> AckSender;
  App.Receive1 -> ActiveMessageC.Receive[AM_MY_MSG];
  App.Receive2 -> ActiveMessageC.Receive[AM_MY_ACK];

  //Radio Control
  App.SplitControl -> ActiveMessageC;

  //Interfaces to access package fields
  App.AMPacket -> MsgSender;
  App.Packet -> MsgSender;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
}

