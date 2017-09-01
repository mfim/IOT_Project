/**
 *  based on work of @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

#define SEND_PERIOD 30000

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t value;
} my_msg_t;

#define REQ 1
#define RESP 2 

enum{
AM_MY_MSG = 6,
};

#endif
