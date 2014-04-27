#ifndef ANIMAL_H
#define ANIMAL_H

enum {
  AM_PINGMSG = 5,
  //AM_GETFOODDAILYDOSAGE = 4,
  AM_UPDATEFOODDAILYDOSAGE = 6,
  AM_ANIMALINFO = 4,
  AM_PROXIMITY = 3,
  AM_UPDATEFEEDINGSPOT = 2,
  //AM_GETFOODRESPONSE = 3,
  MAX_ANIMALS = 10000,
};

//Ping msg struct
typedef nx_struct PingMsg{
  nx_uint16_t number;
} PingMsg;

/*typedef nx_struct GetFoodDailyDosage{
  nx_uint32_t msg_id; //to denie rebroadcast
  nx_uint16_t mote_dest; //if 0 deliver to all
} GetFoodDailyDosage;

typedef nx_struct GetFoodResponse {
  nx_uint32_t msg_id; //unique for each node resp
  nx_uint8_t food_g; //amount of food it ate
  nx_uint16_t mote_id; //mote id
} GetFoodResponse;

*/

typedef nx_struct Proximity {
  nx_uint8_t nothing; //nothing
} Proxmity;

typedef nx_struct AnimalInfo {
  nx_int32_t gps_la; //gps latitue
  nx_int32_t gps_lo; //gps longitude
  nx_uint16_t food_g; //food eaten
  nx_uint32_t msg_id; //unique
  nx_uint16_t mote_id; //the unique mote_id
} AnimalInfo;

typedef nx_struct UpdateFeedingSpot {
  nx_uint16_t food_g; //food in grams
  nx_uint32_t msg_id; //unique
  nx_uint8_t spot_id; //spot id
} UpdateFeedingSpot;

typedef nx_struct UpdateFoodDailyDosage{
  nx_uint32_t msg_id; //to denie rebroadcast
  nx_uint16_t mote_dest; //if 0 deliver to all
  nx_uint8_t new_food_max; //new max amount of daily food 
} UpdateFoodDailyDosage;


#endif

