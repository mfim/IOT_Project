/**
 * PROJECT: LoraWAN-Like sensor Network
 * 
 * Source File for the implementation of gateway node in which
 * the gateway receives a message from the sensor node
 * and forwards it message to the network node, 
 * the mote will then await for an ACK message and 
 * relay it back to the sensor node 
 * 
 *  @authors Matheus Fim and Caio Zuliani
 */

#include "../LoraLikeConfig.h"
#include "Timer.h"
#include "printf.h"

module gatewayNodeC {

  uses {
	interface Boot;
    	interface AMPacket;
	interface Packet;
    	interface AMSend as MsgSend;
	interface AMSend as AckSend;
	interface Receive as Receive1;
	interface Receive as Receive2;
    	interface SplitControl;
    	interface Timer<TMilli> as MilliTimer;
 }

} implementation {

  bool radioBusy;
  uint8_t rec_id;
  uint16_t new_value;
  uint16_t sender;
  uint16_t code;
  message_t ackPacket;
  message_t packet;

  task void sendData();
  task void sendAck();

  //****************** Task send ack *****************// 
  task void sendAck(){
	my_ack_t* ack = (my_ack_t*)(call Packet.getPayload(&ackPacket,sizeof(my_ack_t)));

	ack->code = code;

	call AckSend.send(sender, &ackPacket, sizeof(my_ack_t));       
	
  }
  //****************** Task send response *****************//
  task void sendData() {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
		
	mess->msg_id = rec_id;
	mess->value = new_value;
	mess->sender = sender;
	
	// send to network node ( SHOULD ALWAYS BE 1)
	call MsgSend.send(1, &packet, sizeof(my_msg_t));
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	radioBusy = FALSE;
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
      
    if(err != SUCCESS) {
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	printf("GATEWAY NODE %u\n Message ACK **NOT** Received: %u\n ReSending msg\n\n : %u\n", TOS_NODE_ID, rec_id);
    	printfflush(); 
	post sendData();
  }
  

  //********************* MsgSend interface ****************//
  event void MsgSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	call MilliTimer.startOneShot(1000);
    }
    else{
	post sendData();
    }
  }

  //********************* Receive ACK interface ****************//
  event message_t* Receive2.receive(message_t* msg, void* payload, uint8_t len){
        
      my_ack_t *ack = (my_ack_t *) payload;      
   	
      if(ack->code == sender + new_value + rec_id){ 
	
	printf("GATEWAY NODE %u\n ACK Received (code: %u)\n Timer Stoped\n Message Relayed\n\n : %u\n", TOS_NODE_ID, ack->code);
  	printfflush();
	
	code = ack->code;
	post sendAck();	
	radioBusy= FALSE;		
	call MilliTimer.stop(); 
      }	
   		
      return msg;
    
  }
  //********************* Receive MSG interface ****************//
  event message_t* Receive1.receive(message_t* msg, void* payload, uint8_t len){
      
      if(!radioBusy){
	
      	my_msg_t* mess = (my_msg_t*) payload;
        rec_id = mess ->msg_id;
      	new_value = mess ->value;   
        sender = mess->sender;    	
 
	printf("GATEWAY NODE %u\n Message Received: %u\n Start relay\n\n : %u\n", TOS_NODE_ID, rec_id);
    	printfflush(); 
 
 	post sendData();
  	radioBusy = TRUE;
      }

    return msg;
  }

  //********************* AckSend interface ****************//
  event void AckSend.sendDone(message_t* buf,error_t err) {
    if(err != SUCCESS){
	post sendAck();
    }
  }

}

