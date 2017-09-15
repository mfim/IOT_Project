/**
 *  based on work of @author Luca Pietro Borsani
 */

#ifndef GATEWAY_H
#define GATEWAY_H

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t value;
	nx_uint16_t sender;
} my_msg_t;

enum{
AM_MY_MSG = 6,
};

#endif
