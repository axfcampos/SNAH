#ifndef ANIMAL_H
#define ANIMAL_H

enum {
  AM_PINGMSG = 6,
  AM_GETFOODDAILYDOSAGE = 6,
  AM_UPDATEFOODDAILYDOSAGE = 6,
};

//Ping msg struct
typedef nx_struct PingMsg{
  nx_uint16_t number;
} PingMsg;

typedef nx_struct GetFoodDailyDosage{
  nx_uint16_t msgId; //to denie rebroadcast
  nx_uint8_t foodkg; //amount of food eaten in kg
} GetFoodDailyDosage;

typedef nx_struct UpdateFoodDailyDosage{
  nx_uint16_t msgId; //to denie rebroadcast
  nx_uint8_t newFoodMaxkg; //new max amount of daily food 
} UpdateFoodDailyDosage;


#endif

