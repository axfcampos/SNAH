#ifndef ANIMAL_SENSOR_H
#define ANIMAL_SENSOR_H

enum {
  AM_RADIO_PING_MSG = 6,
};

//Ping msg struct
typedef nx_struct ping_msg{
  nx_uint8_t number;
  nx_uint8_t nodeid;
} ping_msg;


#endif

