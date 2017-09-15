#include "gatewayNode.h"
#include "Timer.h"


module gatewayNodeC {

  uses {
	interface Boot;
    	interface AMPacket;
	interface Packet;
    	interface AMSend;
	interface Receive;
    	interface SplitControl;
    	interface Timer<TMilli> as MilliTimer;
 }

} implementation {

  bool radioBusy;
  uint8_t rec_id;
  uint16_t new_value;
  uint16_t sender;
  message_t packet;

  task void sendData();

  //****************** Task send response *****************//
  
 task void sendData() {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = rec_id;
	mess->value = new_value;
	mess->sender = sender;
	
	call AMSend.send(1, &packet, sizeof(my_msg_t));
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
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	radioBusy= FALSE;
	return;
    }
    else{
	post sendData();
    }
  }

 //********************* Receive interface ****************//
  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){

    my_msg_t* mess = (my_msg_t*) payload;
    rec_id = mess ->msg_id;
    new_value = mess ->value;   
    sender = mess->sender;    	

    if(!radioBusy){
	post sendData();
	radioBusy = TRUE;
    }
    return msg;
  }

}

