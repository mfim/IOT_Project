/**
 *  based on work of @author Luca Pietro Borsani
 */

#ifndef NETWORK_H
#define NETWORK_H

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t value;
	nx_uint16_t sender;
} my_msg_t;

// the sender only needs to know that his message was received
typedef nx_struct my_ack {
	nx_uint16_t code;
} my_ack_t;



enum{
AM_MY_MSG = 6,
AM_MY_ACK = 9,
CAPACITY = 5,
};

#endif
