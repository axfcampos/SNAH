#ifndef ANIMAL_SENSOR_H
#define ANIMAL_SENSOR_H

enum {
  AM_RADIO_PING_MSG = 6
};

//Ping msg struct
typedef nx_struct PingMsg{
  nx_uint8_t number;
  nx_uint8_t nodeid;
} PingMsg;

#endif

