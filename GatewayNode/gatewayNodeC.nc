/**
 * PROJECT: LoraWAN-Like sensor Network
 * 
 * Source File for the implementation of gateway node in which
 * the gateway node receives through the radio from sensor nodes
 * and forwards a message to the network server node through the serialForwarder,(??? check if it works right!) 
 * it will the wait for the ack from network server and relay it to the  
 * right sensor node. 
 * 
 *  @authors Matheus Fim and Caio Zuliani
 */

#include "gatewayNode.h"
//#include "Timer.h"


// in the moment: receives msg from radio, relay to serial 
// to implement: check if it works, specially the change in the interfaces radio/serial

module gatewayNodeC {

  uses {
	interface Boot;
    	interface AMPacket;
	interface Packet;
	interface PacketAcknowledgements;
    	interface AMSend;
    	interface SplitControl;
	// added later 
	interface SplitControl as AMControl;
    	interface Receive;
    	interface Timer<TMilli> as MilliTimer;
	
  }

} implementation {

  uint8_t rec_id;
  message_t packet;

  task void sendToNetwork();

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call AMControl.start();	
	call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");
	dbg("role","I'm Gateway node %d: start receiving requests\n", TOS_NODE_ID);
    }
    else{
	call SplitControl.start();
    }

  }
  
  event void SplitControl.stopDone(error_t err){}


//***************** AMControl interface ********************//
  event void AMControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("serial","Serial on!\n");
	dbg("role","I'm Gateway node %d: preparing to send request through serial port\n", TOS_NODE_ID);
    }
    else{
	call AMControl.start();
    }

  }
  
  event void AMControl.stopDone(error_t err){}




  //***************** MilliTimer interface ********************//
 
 event void MilliTimer.fired() {
	post sendToNetwork();
  }
  


  //***************************** Receive interface *****************//


  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

	my_msg_t* mess=(my_msg_t*)payload;
	rec_id = mess->msg_id;
	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call Packet.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call AMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call AMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call AMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	dbg_clear("radio_rec", "\n ");
	dbg_clear("radio_pack","\n");
	
	post sendToNetwork();
	
    return buf;

  }


  //************************* Read interface **********************//


  task void sendToNetwork() {

	my_msg_t* mess=(my_msg_t*)(call Packet.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = rec_id;
	  
	dbg("serial_send", "Try to relay message to network server node at time %s \n", sim_time_string());
	call PacketAcknowledgements.requestAck( &packet );
	if(call AMSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
		
	  dbg("serial_send", "Packet passed to lower layer successfully!\n");
	  dbg("serial_pack",">>>Pack\n \t Payload length %hhu \n", call Packet.payloadLength( &packet ) );
	  dbg_clear("serial_pack","\t Source: %hhu \n ", call AMPacket.source( &packet ) );
	  dbg_clear("serial_pack","\t Destination: %hhu \n ", call AMPacket.destination( &packet ) );
	  dbg_clear("serial_pack","\t AM Type: %hhu \n ", call AMPacket.type( &packet ) );
	  dbg_clear("serial_pack","\t\t Payload \n" );
	  dbg_clear("serial_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("serial_pack", "\t\t value: %hhu \n", mess->value);
	  dbg_clear("serial_send", "\n ");
	  dbg_clear("serial_pack", "\n");

        }

  }

//********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	dbg("serial_send", "Packet sent...");

	if ( call PacketAcknowledgements.wasAcked( buf ) ) {
	  dbg_clear("serial_ack", "and ack received");
	  call MilliTimer.stop();
	} else {
	  dbg_clear("serial_ack", "but ack was not received");
	  post sendToNetwork();
	}
	dbg_clear("serial_send", " at time %s \n", sim_time_string());
    }
	// turn off radio for another 30 seconds! battery....

  }

}

