#include "loraNode.h"
#include "Timer.h"

module loraNodeC {

  uses {
	interface Boot;
	interface SplitControl as SerialControl;
        interface SplitControl as RadioControl;

    	interface AMSend as UartSend;
    	interface Packet as UartPacket;
	interface AMPacket as UartAMPacket;

	interface AMSend as RadioSend;
	interface Receive as RadioReceive;
	interface Packet as RadioPacket;
	interface AMPacket as RadioAMPacket;

    	interface Timer<TMilli> as MilliTimer;
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  uint8_t new_value;
  message_t packet;

  task void sendData();
  task void sendToUart();
  bool       uartBusy;

  //****************** Task send response *****************//
  
 task void sendData() {
	call Read.read();
  }

//************************* Read interface **********************//
   
event void Read.readDone(error_t result, uint16_t data) {

	my_msg_t* mess=(my_msg_t*)(call RadioPacket.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = counter++;
	mess->value = data;	
    
	dbg("radio_send", "Try to broadcast a request to gateways at time %s \n", sim_time_string());
    	
	//call PacketAcknowledgements.requestAck( &packet );

	if(call RadioSend.send(AM_BROADCAST_ADDR,&packet,sizeof(my_msg_t)) == SUCCESS){
		
	  dbg("radio_send", "Packet passed to lower layer successfully!\n");
	  dbg("radio_pack",">>>Pack\n \t Payload length %hhu \n", call RadioPacket.payloadLength( &packet ) );
	  dbg_clear("radio_pack","\t Source: %hhu \n ", call RadioAMPacket.source( &packet ) );
	  dbg_clear("radio_pack","\t Destination: %hhu \n ", call RadioAMPacket.destination( &packet ) );
	  dbg_clear("radio_pack","\t AM Type: %hhu \n ", call RadioAMPacket.type( &packet ) );
	  dbg_clear("radio_pack","\t\t Payload \n" );
	  dbg_clear("radio_pack", "\t\t msg_id: %hhu \n", mess->msg_id);
	  dbg_clear("radio_pack", "\t\t value: %hhu \n", mess->value);
	  dbg_clear("radio_send", "\n ");
	  dbg_clear("radio_pack", "\n");
      
      }

 }        

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call RadioControl.start();
	if(TOS_NODE_ID == (3)){
		uartBusy = FALSE;
		call SerialControl.start();
	}

  }

  //***************** RadioControl interface ********************//
  event void RadioControl.startDone(error_t err){
      
    if(err == SUCCESS) {

	dbg("radio","Radio on!\n");
	if(TOS_NODE_ID < 3){
		dbg("role","I'm Sensor node %d: start sending periodical request\n", TOS_NODE_ID);
		call MilliTimer.startPeriodic(20000);	
	}
	else{
		dbg("role","I'm Gateway node %d: start receiving requests\n", TOS_NODE_ID);
	}
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

  //***************************** Radio Receive interface *****************//

  event message_t* RadioReceive.receive(message_t* buf,void* payload, uint8_t len) {
	if(TOS_NODE_ID > 2){
		my_msg_t* mess=(my_msg_t*)payload;
		rec_id = mess->msg_id;
		new_value = mess->value;
	
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
	}else{
		return NULL;
	}

  }

 //************************* Read interface **********************//

  task void sendToUart() {
	
	my_msg_t* mess=(my_msg_t*)(call RadioPacket.getPayload(&packet,sizeof(my_msg_t)));
	mess->msg_id = rec_id;
	mess->value = new_value;	
		
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



  //***************** MilliTimer interface ********************//

  event void MilliTimer.fired() {
	RadioControl.start();
	post sendData();
  }
  

  //********************* RadioSend interface ****************//

  event void RadioSend.sendDone(message_t* buf,error_t err) {

    if(&packet == buf && err == SUCCESS ) {
	RadioControl.stop();
	dbg("radio_send", "Packet sent...");
	dbg_clear("radio_send", " at time %s \n", sim_time_string());
    }
	// turn off radio for another 30 seconds! battery....

  }

}

