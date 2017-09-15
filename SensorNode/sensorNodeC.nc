/**
 * PROJECT: LoraWAN-Like sensor Network
 * 
 * Source File for the implementation of sensor node in which
 * the sensor node reads from the Fake Sensor (code previously available)
 * and forwards a message to the gateway node, 
 * the gateway node will then pass it to the network server node, and the ACK messages
 * will be relayed back until reaches the sensor node
 * 
 *  @authors Matheus Fim and Caio Zuliani
 */

#include "../LoraLikeConfig.h"
#include "Timer.h"
#include "printf.h"


// in the moment: reads fake sensor and broadcast every 30 seconds, ack message 
// to implement:  turn off radio when not transmiting, ack message time window should be 1 second

module sensorNodeC {

  uses {
	interface Boot;
    	interface AMPacket;
	interface Packet;
    	interface AMSend;
	interface Receive;
    	interface SplitControl;
    	interface Timer<TMilli> as MilliTimer;
	interface Timer<TMilli> as AckTimer;
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  uint16_t sender;
  uint16_t new_value;
  message_t packet;
  

  task void sendData();
  task void reSendData();

   task void reSendData() {
        
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
		
	mess->msg_id = rec_id;
	mess->value = new_value;
	mess->sender = sender;

	call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(my_msg_t));
  }
  //****************** Task send response *****************// 
 task void sendData() {
	call Read.read();
  }

//************************* Read interface **********************//
   
event void Read.readDone(error_t result, uint16_t data) {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter++;
	mess->value = data;
	mess->sender = TOS_NODE_ID;	

	rec_id = mess->msg_id;
	new_value = mess->value;
	sender = mess->sender;
       	
	call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t));

 }        

  //***************** Boot interface ********************//
  event void Boot.booted() {
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
      
    if(err == SUCCESS) {
	call MilliTimer.startPeriodic(30000);	
    }
    else{
	call SplitControl.start();
    }

  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	post sendData();
  }
  

  //***************** AckTimer interface ********************//
  event void AckTimer.fired() {
	post reSendData();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	call AckTimer.startOneShot(1000);	
    }
    else{
        post sendData();
    }
  }

 //********************* Receive ACK interface ****************//
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
        
      my_ack_t *ack = (my_ack_t *) payload;      
      
     // printf("ACK->CODE : %u\n", ack->code);
      //printfflush();    

      if(ack->code == sender + new_value + rec_id){ 		
	call AckTimer.stop(); 
      }	
 
      return msg;
  }

}



