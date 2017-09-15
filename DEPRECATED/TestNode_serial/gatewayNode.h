/**
 *  based on work of Luca Pietro Borsani
 *  Modified by: Matheus Fim and Caio Zuliani
 */

#ifndef GATEWAY_H
#define GATEWAY_H

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t value;
} my_msg_t;

enum{
AM_MY_MSG = 6,
};

#endif
