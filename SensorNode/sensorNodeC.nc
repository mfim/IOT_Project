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

  //****************** Task resend response *****************//    
 task void reSendData() {
     
	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	
	// data of the previous message, if it has been overwritten, the data is lost 
	// there is a 30 seconds window. That is: 29 tries.	
	mess->msg_id = rec_id;
	mess->value = new_value;
	mess->sender = sender;

	printf("SENSOR NODE %u\n Message ACK **NOT** Received: %u\n ReSending msg\n\n : %u\n", TOS_NODE_ID, rec_id);
    	printfflush();
 
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
	// 30 seconds timer 
	call MilliTimer.startPeriodic(30000);	
    }
    else{
	call SplitControl.start();
    }

  }
  
  event void SplitControl.stopDone(error_t err){}

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {
	// this timer controls the 30 seconds readings
	post sendData();
  }
  

  //***************** AckTimer interface ********************//
  event void AckTimer.fired() {
	// this timer controls the 1 second time window to resend msg
	post reSendData();
  }

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    printf("SENSOR NODE %u\n Message Sent: %u\n Start 1 sec Timer\n\n : %u\n", TOS_NODE_ID, rec_id);
    printfflush();    

    if(&packet == buf && err == SUCCESS ) {
       // start the 1 second window 
       call AckTimer.startOneShot(1000);	
    }
    else{
       post sendData();
    }
  }

 //********************* Receive ACK interface ****************//
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
      // receive the ack and check if the code is write  	 
      my_ack_t *ack = (my_ack_t *) payload;      
      
      printf("SENSOR NODE %u\n ACK Received (code: %u)\n Timer Stoped\n\n : %u\n", TOS_NODE_ID, ack->code);
      printfflush();  
      
      if(ack->code == sender + new_value + rec_id){ 		
	call AckTimer.stop(); 
      }	
 
      return msg;
  }

}



