#ifndef ANIMALSENSOR


enum {
  AM_RADIO_PING_MSG = 6;
}

//Ping msg struct
typedef nx_struct ping_msg{
  nx_uint8_t number;
  nx_uint8_t nodeid;
} ping_msg


#endif

