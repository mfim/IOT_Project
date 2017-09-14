/**
 *  based on work of @author Luca Pietro Borsani
 */

#ifndef SENSOR_H
#define SENSOR_H

typedef nx_struct my_msg {
	nx_uint16_t msg_id;
	nx_uint16_t value;
} my_msg_t;

enum{
AM_MY_MSG = 6,
};

#endif
