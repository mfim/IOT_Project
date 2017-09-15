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
   
      //printf("ACK->CODE : %u\n", ack->code);
      //printfflush();
	
      if(ack->code == sender + new_value + rec_id){ 
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
      	//oldPacket = packet;

	//printf("G THE SENDER IS.... %u\n", call AMPacket.source( &packet ));	

  	post sendData();
  	radioBusy = TRUE;
      }

    return msg;
  }

  //********************* AckSend interface ****************//
  event void AckSend.sendDone(message_t* buf,error_t err) {}
	// IMPLEMENT SOMETHING!

}

