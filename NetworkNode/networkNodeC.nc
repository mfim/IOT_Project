/**
 * PROJECT: LoraWAN-Like sensor Network
 * 
 * Source File for the implementation of networkNode in which
 * the networkNode receives through the radio from sensor nodes
 * and forwards a message to the network server node through the serialForwarder,(??? check if it works right!) 
 * it will the wait for the ack from network server and relay it to the  
 * right sensor node. 
 * 
 *  @authors Matheus Fim and Caio Zuliani
 */

#include "../LoraLikeConfig.h"
#include "printf.h"

module networkNodeC {

  uses {
	interface Boot;
	interface SplitControl as SerialControl;
        interface SplitControl as RadioControl;

    	interface AMSend as UartSend;
// 	interface Receive as UartReceive[am_id_t id];
    	interface Packet as UartPacket;
	interface AMPacket as UartAMPacket;

	interface AMSend as RadioSend;
	interface Receive as RadioReceive;
//	interface Receive as RadioSnoop[AM_MY:_MSG];
	interface Packet as RadioPacket;
	interface AMPacket as RadioAMPacket;

	interface PacketAcknowledgements;
    	interface Timer<TMilli> as MilliTimer;
	
  }

} implementation {

  uint8_t rec_id;
  uint16_t new_value;
  uint16_t sender;
  message_t packet;
  message_t ackPacket;
  my_msg_t not_again[6];
  uint8_t index=-1;

  task void sendToUart();
 
  bool       uartBusy;

  //***************** Boot interface ********************//
  event void Boot.booted() {
	uartBusy = FALSE;
	call RadioControl.start();	
	call SerialControl.start();
  }

  //***************** RadioControl interface ********************//
  event void RadioControl.startDone(error_t err){
      
    if(err != SUCCESS) {
	call RadioControl.start();
    }

  }
  
  event void RadioControl.stopDone(error_t err){}


//***************** SerialControl interface ********************//
  event void SerialControl.startDone(error_t err){
      
    if(err != SUCCESS) {
	call SerialControl.start();
    }

  }
  
  event void SerialControl.stopDone(error_t err){}


  //***************** MilliTimer interface ********************//
 // change to be the ack!!!! not now.....
 event void MilliTimer.fired() {
	post sendToUart();
  }
  


  //***************************** Radio Receive interface *****************//

  event message_t* RadioReceive.receive(message_t* buf,void* payload, uint8_t len) {
	
	uint8_t i;
			
	my_msg_t* mess=(my_msg_t*)payload;

	my_ack_t* ack=(my_ack_t*)(call RadioPacket.getPayload(&ackPacket, sizeof (my_ack_t)));

	ack->code = mess->sender + mess->value + mess->msg_id;
	call RadioSend.send(call RadioAMPacket.source(buf), &ackPacket, sizeof(my_ack_t));
         
	for(i = 0; i < CAPACITY; i++){
		if((not_again[i].msg_id == mess->msg_id) && (not_again[i].sender == mess->sender)){
			return buf;
		}
	}
		
	index = (index + 1) % CAPACITY;
	
	not_again[index].msg_id = mess->msg_id;
	not_again[index].value = mess->value;
        not_again[index].sender = mess->sender;  
	
	//printf("Not Again: Id: %u Value: %u Sender: %u\n", not_again[index].msg_id, not_again[index].value, not_again[index].sender);	
	//printf("THE SENDER IS.... %u\n", call RadioAMPacket.source(buf));
	//printfflush();	

        // OK CHANGE THIS!!!!!!! NOT BROADCAST; BUT TO RIGHT NODE!
	//call RadioSend.send(call RadioAMPacket.source(buf), &ackPacket, sizeof(my_ack_t));
        
	//post sendACK();
	if(!uartBusy){
	  post sendToUart();
	  uartBusy= TRUE;
	}
    return buf;

  }

  //********************* RadioSend interface ****************//
  event void RadioSend.sendDone(message_t* buf,error_t err) {}


  //************************* Read interface **********************//

  task void sendToUart() {
	
	my_msg_t* mess=(my_msg_t*)(call RadioPacket.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = not_again[index].msg_id;
	mess->value = not_again[index].value;
	mess->sender = not_again[index].sender;
		  
	//call PacketAcknowledgements.requestAck( &packet );
	call UartSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t));

  }

//********************* UartSend interface ****************//
  event void UartSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	uartBusy = FALSE;
    }
	
  }

}

