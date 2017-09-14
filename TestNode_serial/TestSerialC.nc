#include "gatewayNode.h"
#include "Timer.h"

module TestSerialtC {

  uses {
	interface Boot;
    	interface Packet;
    	interface AMSend;
    	interface SplitControl as Control;
    	interface Timer<TMilli> as MilliTimer;	
  }

} implementation {

  message_t packet;

  bool locked = FALSE;
  uint16_t counter = 0;

  task void sendToNetwork();

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call Control.start();	
  }

 //***************** AMControl interface ********************//
  event void Control.startDone(error_t err){
      
    if(err == SUCCESS) {
	dbg("serial","Serial on!\n");
	dbg("role","I'm Gateway node %d: preparing to send request through serial port\n", TOS_NODE_ID);
	call MilliTimer.startPeriodic(1000);
    }
 }
  
  event void Control.stopDone(error_t err){}


  //***************** MilliTimer interface ********************//
 
 event void MilliTimer.fired() {
	post sendToNetwork();
  }
  

  //************************* Read interface **********************//

  task void sendToNetwork() {
	counter++;
	
	if(locked){
		return;
	}
	else{
		my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	
		if(mess == NULL){return;}
		if(call Packet.maxPayloadLength() < sizeof(my_msg_t)){
			return;
		}
	
		mess->value = counter;
		  
		dbg("serial_send", "Try to relay message to network server node at time %s \n", sim_time_string());

		if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
		  locked = TRUE;	
		  dbg("serial_send", "Packet passed to lower layer successfully!\n");
		  dbg("serial_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
		  dbg_clear("serial_pack","\t\t Payload \n" );
		  dbg_clear("serial_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		  dbg_clear("serial_pack", "\t\t value: %hhu \n", mess->value);
		  dbg_clear("serial_send", "\n ");
		  dbg_clear("serial_pack", "\n");

	        }
	}

  }

//********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	locked = FALSE;
	dbg("serial_send", "Packet sent...");

//	if ( call PacketAcknowledgements.wasAcked( buf ) ) {
//	  dbg_clear("serial_ack", "and ack received");
//	  call MilliTimer.stop();
//	} else {
//	  dbg_clear("serial_ack", "but ack was not received");
//	  post sendToNetwork();
//	}
	dbg_clear("serial_send", " at time %s \n", sim_time_string());
    }

  }

}

