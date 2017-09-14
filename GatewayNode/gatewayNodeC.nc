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
	interface SplitControl as SerialControl;
        interface SplitControl as RadioControl;

    	interface AMSend as UartSend;
// 	interface Receive as UartReceive[am_id_t id];
    	interface Packet as UartPacket;
	interface AMPacket as UartAMPacket;

//	interface AMSend as RadioSend[am_id_t id];
	interface Receive as RadioReceive;
//	interface Receive as RadioSnoop[AM_MY:_MSG];
	interface Packet as RadioPacket;
	interface AMPacket as RadioAMPacket;

	interface PacketAcknowledgements;
    	interface Timer<TMilli> as MilliTimer;
	
  }

} implementation {

  uint8_t rec_id;
  message_t packet;

  task void sendToUart();
  bool       uartBusy;

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	uartBusy = FALSE;
	call RadioControl.start();	
	call SerialControl.start();
  }

  //***************** RadioControl interface ********************//
  event void RadioControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");
	dbg("role","I'm Gateway node %d: start receiving requests\n", TOS_NODE_ID);
    }
    else{
	call RadioControl.start();
    }

  }
  
  event void RadioControl.stopDone(error_t err){}


//***************** SerialControl interface ********************//
  event void SerialControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("serial","Serial on!\n");
	dbg("role","I'm Gateway node %d: preparing to send request through serial port\n", TOS_NODE_ID);
    }
    else{
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

	my_msg_t* mess=(my_msg_t*)payload;
	rec_id = mess->msg_id;
	
	dbg("radio_rec","Message received at time %s \n", sim_time_string());
	dbg("radio_pack",">>>Pack \n \t Payload length %hhu \n", call RadioPacket.payloadLength( buf ) );
	dbg_clear("radio_pack","\t Source: %hhu \n", call RadioAMPacket.source( buf ) );
	dbg_clear("radio_pack","\t Destination: %hhu \n", call RadioAMPacket.destination( buf ) );
	dbg_clear("radio_pack","\t AM Type: %hhu \n", call RadioAMPacket.type( buf ) );
	dbg_clear("radio_pack","\t\t Payload \n" );
	dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	dbg_clear("radio_rec", "\n ");
	dbg_clear("radio_pack","\n");
	
	//post sendACK();
	if(!uartBusy){
	  post sendToUart();
	  uartBusy= TRUE;
	}
    return buf;

  }


  //************************* Read interface **********************//


  task void sendToUart() {
	
	my_msg_t* mess=(my_msg_t*)(call RadioPacket.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = rec_id;
		
	dbg("serial_send", "Try to relay message to network server node at time %s \n", sim_time_string());
	  
	//call PacketAcknowledgements.requestAck( &packet );
	if(call UartSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
		dbg("serial_send", "Packet passed to lower layer successfully!\n");
		dbg("serial_pack",">>>Pack\n \t Payload length %hhu \n", call UartPacket.payloadLength( &packet ) );
		dbg_clear("serial_pack","\t Source: %hhu \n ", call UartAMPacket.source( &packet ) );
		dbg_clear("serial_pack","\t Destination: %hhu \n ", call UartAMPacket.destination( &packet ) );
		dbg_clear("serial_pack","\t AM Type: %hhu \n ", call UartAMPacket.type( &packet ) );
		dbg_clear("serial_pack","\t\t Payload \n" );
		dbg_clear("serial_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
		dbg_clear("serial_pack", "\t\t value: %hhu \n", mess->value);
		dbg_clear("serial_send", "\n ");
		dbg_clear("serial_pack", "\n");
        }

  }

//********************* UartSend interface ****************//
  event void UartSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	uartBusy = FALSE;
	dbg("serial_send", "Packet sent...");

	dbg_clear("serial_send", " at time %s \n", sim_time_string());
    }
	
  }

}

