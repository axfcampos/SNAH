//sup
#include "Timer.h"
#include "Animal.h"
#include <pthread.h>
#include <time.h>
#include <stdlib.h>
#include <stdio.h>
#include <string.h>

module AnimalC @safe() {

  provides {
    interface Read<uint16_t> as SensorReadSimulator;
  }
  
  uses {
    interface Boot;
    interface Packet; //to access message_t
    //interface AMPacket; //to access message_t
    interface AMSend as SendPing; //to send packets
    //interface AMSend as SendFoodQuery;
    interface AMSend as SendFoodUpdate;
    //interface AMSend as SendFoodResponse;
    interface AMSend as SendAnimalInfo;
    interface AMSend as SendUpdateFeedingSpot;

    interface SplitControl as AMControl; //to start radio
    
    interface Receive as ReceivePing; //to receive packets
    interface Receive as ReceiveFoodUpdate; //to update daily food dosage
    //interface Receive as ReceiveFoodQuery; //receive food query
    //interface Receive as ReceiveFoodResponse; //receive food response and fwd
    interface Receive as ReceiveAnimalInfo;
    interface Receive as ReceiveProximity;
    interface Receive as ReceiveUpdateFeedingSpot;

    interface Timer<TMilli> as BroadcastTimer;
    interface Timer<TMilli> as GpsTimer;
    interface Timer<TMilli> as FSpotProximityTimer;

    interface Read<uint16_t> as SensorRead;
  }
}

/*
 * dbg: Boot is stdout
 *
 */
implementation {

  //signatures
  bool check_ok_for_broadcast(int msg_id);
  void broadcastFoodUpdate(message_t* msg);
  void add_to_broadcast_checker(int msg_id);
  void eat(int food_amount);
  void eat_from_spot(int food_amount, int spot_id);
  void updateFeedingSpot(int new_max_food, int spot_id);
  void broadcast_animal_info();
  void fwd_broadcast_update_spot(message_t* msg);
  //void broadcastFoodQuery(message_t* msg);
  //void start_broadcastFoodResp();
  //void fwd_broadcastFoodResp(message_t* msg);
  
  /*
   * vars
   */
  bool busy = FALSE; //keep track if radio is busy sending
  AnimalInfo *ai_pkt;
  FILE* sensor_file;
    
  //radio
  int last_msg[MAX_ANIMALS];
  int last_msg_i = 0;
  pthread_mutex_t count_mutex;
  message_t packet; //to hold data for transmission
  AnimalInfo* animal_info_packet;

  //gps
  uint32_t gps_la;
  uint32_t gps_lo;
  FILE* gps_file;
  char filename[4];
  
  //feeding spot
  bool proximity;
  FILE* feeding_spot;
  int max_food; //daily max food intake
  int food_intake; //amount of food eaten today
  int eating_habit; //amount of it eats per meal
  char food_filename[3];
  //int aux_value;
  //int aux_max;
  //GetFoodResponse *gfr_pkt;
    
  
  //funcs
  event void Boot.booted(){
    dbg("Boot", "=== Node has booted successfully!\n");
    srand(time(NULL)); //starts random number gen. int r = rand()
    max_food = 1200; //grams
    food_intake = 0;
    eating_habit = 400; //how much it eats each time
    proximity = FALSE;
    //aux_value = 0;
    //aux_max = 0;
    gps_la = 38737107; //init values
    gps_lo = -93028921; //init values
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if (err == SUCCESS) {
      dbg("Boot", "Radio has started successfully!\n");
      if(TOS_NODE_ID != 0){
        call GpsTimer.startPeriodic(50000);
        call FSpotProximityTimer.startPeriodic(40000000);
        call BroadcastTimer.startPeriodic(200000 * (10 - TOS_NODE_ID));
      }
    } else {
      //retry
      dbg("Boot", "Radio failed to start, retrying..\n");
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err){
    dbg("Boot", "Radio has stopped..\n");
  }

  

  event void SendPing.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&packet == msg) {
      dbg("Boot", "No errors accured, Send is available\n");
      //busy = FALSE;
      //pthread_mutex_unlock(&count_mutex);
    }
  }
  /*event void SendFoodQuery.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending Food Query packet is done. \n");
    //if (&packet == msg) {
      //dbg("Boot", "No errors accured, Send is available\n");
      //busy = FALSE;
    //}

    //pthread_mutex_unlock(&count_mutex);
    dbg("Boot", "unlock mutex");
  }*/
  event void SendFoodUpdate.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending Food Update packet is done. \n");
    //if (&packet == msg) {
      //dbg("Boot", "No errors accured, Send is available\n");
      busy = FALSE;
    //}
  }
  /*event void SendFoodResponse.sendDone(message_t* msg, error_t error){
    dbg("Boot", "FoodResponse send Done");
    //pthread_mutex_unlock(&count_mutex);
    dbg("Boot", "unlocked mutex");
  }*/
  event message_t* ReceivePing.receive(message_t* msg, void* payload, uint8_t len){
    return msg;
  }

  /*event message_t* ReceiveFoodQuery.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "got food query");

    if (len == sizeof(GetFoodDailyDosage)){

      GetFoodDailyDosage* pkt = (GetFoodDailyDosage*)payload; //cast

      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcasted message. dont broadcast again
        dbg("Boot", "Already broadcast. Discarding....");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if ( pkt->mote_dest == 0){
        if(TOS_NODE_ID == 0){
          //only forward
          broadcastFoodQuery(msg);
        } else {
          //respond and forward
          broadcastFoodQuery(msg);
          start_broadcastFoodResp();
        }
      } else {
        if (pkt->mote_dest == TOS_NODE_ID){
          //respond and do NOT forward
          start_broadcastFoodResp();
        }
      }

    }else {
      dbg("Boot", "Something went terribly wrong @ Receive FoodQuery");
    }
    return msg;
  }*/

  /*event message_t* ReceiveFoodResponse.receive(message_t* msg, void* payload, uint8_t len){
    
    dbg("Boot", "received food response");
    //if im mote 0 = store for server to read. If not, forward

    if (len == sizeof(GetFoodResponse)){
      
      GetFoodResponse* pkt = (GetFoodResponse*)payload; //cast

      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcast, dont do it again
        dbg("Boot", "@ReceiveFoodResponse: Already broadcast. Discarding...");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if (TOS_NODE_ID == 0 ){
        dbg("Boot", "\n------------\n\n");
        dbg("Boot", "\nnode_id: %hhu | food_intake: %hhu | msg_id: %hhu \n", pkt->mote_id, pkt->food_g, pkt->msg_id);

      } else {
        fwd_broadcastFoodResp(msg);
      }

    } else {
      dbg("Boot", "Something went terribly wrong @ Receive FoodResponse");
    }
    return msg;
  }*/

  event message_t* ReceiveFoodUpdate.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\nola chegou o update %d vs %d\n", len, sizeof(UpdateFoodDailyDosage));
    
    if (len == sizeof(UpdateFoodDailyDosage)){
      UpdateFoodDailyDosage* pkt = (UpdateFoodDailyDosage*)payload; //cast
      dbg("Boot", "CHEGOU AQUI\n"); 
      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcasted message. dont broadcast again
        dbg("Boot", "Already broadcast. Discarding....");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }
      dbg("Boot", "here here here\n");
      if(pkt->mote_dest == 0){ //if 0, update mine and broadcast (save id to avoid rebroadcast)
        max_food = pkt->new_food_max;
        broadcastFoodUpdate(msg); 
        
      } else {
        if(pkt->mote_dest == TOS_NODE_ID){ //if its me
          max_food = pkt->new_food_max;
        }
      }
    } else {
      dbg("Boot", "Something went terribly wrong!");
    }
    return msg;
  }


  //aux functions
  void broadcastFoodUpdate(message_t* msg){
    dbg("Boot", "broadcasting food update\n");
    if(busy){return;}
    if (call SendFoodUpdate.send(
         AM_BROADCAST_ADDR, msg, sizeof(UpdateFoodDailyDosage)) == SUCCESS){
      dbg("Boot", "forwarded food query message");
      busy = TRUE;
    }
  }
  /*void broadcastFoodQuery(message_t* msg){
    dbg("Boot", "broadcasting food query");
    //pthread_mutex_lock(&count_mutex);
      if (call SendFoodQuery.send(
            AM_BROADCAST_ADDR, msg, sizeof(GetFoodDailyDosage)) == SUCCESS){
        dbg("Boot", "forwarded food query message");
        //pthread_mutex_unlock(&count_mutex);
      }
  }*/

  /*void start_broadcastFoodResp(){
    dbg("Boot", "broadcasting food response");
    //pthread_mutex_lock(&count_mutex);
      gfr_pkt = (GetFoodResponse*)call Packet.getPayload(&packet, sizeof(GetFoodResponse));
      gfr_pkt->msg_id = rand();
      gfr_pkt->food_g = food_intake;
      gfr_pkt->mote_id = TOS_NODE_ID;
      if (call SendFoodResponse.send(
            AM_BROADCAST_ADDR, &packet, sizeof(GetFoodResponse)) == SUCCESS){
        dbg("Boot", "started broadcast GetFoodResponse");
        gfr_pkt = 0;
        //pthread_mutex_unlock(&count_mutex);
      }
  }*/

  /*void fwd_broadcastFoodResp(message_t* msg){
    //pthread_mutex_lock(&count_mutex);
      if (call SendFoodResponse.send(
            AM_BROADCAST_ADDR, msg, sizeof(GetFoodResponse)) == SUCCESS){
        dbg("Boot", "fowarded GetFoodResponse");
        //pthread_mutex_unlock(&count_mutex);
      }
  }*/
  
  bool check_ok_for_broadcast(int msg_id){
    int i; 
    for (i = 0; i < MAX_ANIMALS; i++){
      if(last_msg[i] == msg_id){
        return FALSE;
      }
    }
    
    return TRUE; //ok for broadcast
  }

  void add_to_broadcast_checker(int msg_id){
    
    last_msg[last_msg_i] = msg_id;
    msg_id = (msg_id + 1) % MAX_ANIMALS;

  }


  //GPS SIMLATOR 
  event void SensorRead.readDone(error_t err, uint16_t val) {
    if (err == SUCCESS) {

      sprintf(filename, "gps%d", TOS_NODE_ID);
      gps_file = fopen(filename, "r");

      fscanf(gps_file, "%d", &gps_la);
      fscanf(gps_file, "%d", &gps_lo);

      fclose(gps_file);
    }
  } 
  command error_t SensorReadSimulator.read() {
    signal SensorReadSimulator.readDone(SUCCESS, 1); 
    return SUCCESS;
  }
  event void GpsTimer.fired() {
    call SensorReadSimulator.read();
  }
  event void BroadcastTimer.fired() {
  
    //broadcast readings
    dbg("Boot", "@BroadcastTimer: it fired!\n");
    broadcast_animal_info(); 
  }

  void broadcast_animal_info(){
    //pthread_mutex_lock(&count_mutex);
    if(busy){return;}
    ai_pkt = (AnimalInfo*)call Packet.getPayload(&packet, sizeof(AnimalInfo));
    ai_pkt->msg_id = rand();
    ai_pkt->gps_la = gps_la;
    ai_pkt->gps_lo = gps_lo;
    ai_pkt->food_g = food_intake;
    ai_pkt->mote_id = TOS_NODE_ID;
    if (call SendAnimalInfo.send(
          AM_BROADCAST_ADDR, &packet, sizeof(AnimalInfo)) == SUCCESS){
      dbg("Boot", "success broadcast AnimalInfo\n");
      busy = TRUE;
      ai_pkt = 0;
    }
  }

  task void fwd_broadcast_animal_info(){
    //pthread_mutex_lock(&count_mutex);
    if(busy){return;}
    dbg("Boot", "@fwd_broadcast_animal_info: entered");
    ai_pkt = (AnimalInfo*)call Packet.getPayload(&packet, sizeof(AnimalInfo));
    ai_pkt->msg_id = animal_info_packet->msg_id;
    ai_pkt->gps_la = animal_info_packet->gps_la;
    ai_pkt->gps_lo = animal_info_packet->gps_lo;
    ai_pkt->food_g = animal_info_packet->food_g;
    ai_pkt->mote_id = animal_info_packet->mote_id;
    if(call SendAnimalInfo.send(
          AM_BROADCAST_ADDR, &packet, sizeof(AnimalInfo)) == SUCCESS){
      dbg("Boot", "@fwd_broadcast_animal_info: SUCCESS\n");
      busy = TRUE;
      ai_pkt = 0;
    }
  }

  event void SendAnimalInfo.sendDone(message_t* msg, error_t error){
    
    dbg("Boot", "@SendAnimalInfo.sendDone: entering\n");
    if (&packet == msg){
      //unlock mutex... ?
      //dbg("Boot", "@SendAnimalInfo.sendDone ----\n");
      //pthread_mutex_unlock(&count_mutex);
      busy = FALSE;
    }
  }
  
  event message_t* ReceiveAnimalInfo.receive(message_t* msg, void* payload, uint8_t len){

    if (len == sizeof(AnimalInfo)){
      AnimalInfo* pkt = (AnimalInfo*)payload; //cast
      dbg("Boot", "@AnimalInfo: msg_id:%d mote_id:%d\n", pkt->msg_id, pkt->mote_id); 
      if(!check_ok_for_broadcast(pkt->msg_id) || pkt->mote_id == TOS_NODE_ID){
        //already broadcasted message. dont broadcast again
        dbg("Boot", "@AnimalInfo: Already broadcast. Discarding....\n");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if(TOS_NODE_ID == 0){
        dbg("Boot", "@AnimalInfo: REACHED SERVER\n");
        sensor_file = fopen("sensor_info.txt", "a+"); 
        fprintf(sensor_file, "node_id: %d || GPS-la: %d lo: %d || food_eaten: %d || msg_id: %d\n", 
            pkt->mote_id, pkt->gps_la, pkt->gps_lo, pkt->food_g, pkt->msg_id);
        fclose(sensor_file);
      }else{
        dbg("Boot", "@AnimalInfo: calling post task\n");
        animal_info_packet = pkt;
        post fwd_broadcast_animal_info();
      }
    } else {
      dbg("Boot", "Something went terribly wrong!\n");
    }
    return msg;
  }

  //Feeding spot proximity simulation
  event void FSpotProximityTimer.fired() {

    //dbg("Boot", "@FSpotProximityTimer fired!");
    if(proximity){
      //eat
      eat(eating_habit);
    }
  }

  event message_t* ReceiveProximity.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "@ReceiveProximity: TURNING ON PROXIMITY!\n");
    proximity = TRUE;
    return msg;
  }

  void eat(int food_amount){
    //Simulating Radio communication to make Food Spot dispense food.
    //check if feeding spot has enough
    //if so update to new value
    int id = TOS_NODE_ID;
    if(id == 1 || id == 2 || id == 3){
      eat_from_spot(food_amount, 1);
    }else{
    if(id == 4 || id == 5 || id == 6){
      eat_from_spot(food_amount, 2);
    }else{
    if(id == 7 || id == 8 || id == 9){
      eat_from_spot(food_amount, 3);
    }}}
  }

  void eat_from_spot(int food_amount, int spot_id){
    
    int value, max;

    sprintf(food_filename, "fs%d", spot_id);
    feeding_spot = fopen(food_filename, "r");

    fscanf(feeding_spot, "%d %d", &value, &max);
    dbg("Boot", "\n\n eating %d .. %d", value, max);
    if (food_intake >= max_food){
      dbg("Boot", "@eat_from_spot: DID NOT EAT. Achieve daily dosage!");
      fclose(feeding_spot);
      return;
    }//already had daily dosage!
    
    fclose(feeding_spot);
    feeding_spot = fopen(food_filename, "w+");

    if(value > food_amount){
      dbg("Boot", "\n\n eating %d .. %d", (value - food_amount), max);
      fprintf(feeding_spot, "%d %d", (value - food_amount), max);
      food_intake += food_amount; 
    }else{
      dbg("Boot", "------ Not enough food! in feeding spot %d \n", spot_id);
      fprintf(feeding_spot, "%d %d", 0, max);
      food_intake += value; //what was left
    }
    dbg("Boot", "@eat_from_spot: EATING DONE!");
      
    fclose(feeding_spot);
  }

  void updateFeedingSpot(int new_max_food, int spot_id){
    //Simulating Radio communication 
    //with feeding spot if proximity = true
    //to update max food dispensed
    int value, max;
    
    dbg("Boot", "@updateFeedingSpot: entered");
    sprintf(food_filename, "fs%d", spot_id);
    feeding_spot = fopen(food_filename, "r");
    fscanf(feeding_spot, "%d %d", &value, &max);
    fclose(feeding_spot);
    feeding_spot = fopen(food_filename, "w+");
    fprintf(feeding_spot, "%d %d\n", new_max_food, new_max_food);
    fclose(feeding_spot);
  }

  
  event message_t* ReceiveUpdateFeedingSpot.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\nola chegou o update %d vs %d\n", len, sizeof(UpdateFeedingSpot));
    
    if (len == sizeof(UpdateFeedingSpot)){
      UpdateFeedingSpot* pkt = (UpdateFeedingSpot*)payload; //cast
      dbg("Boot", "CHEGOU AQUI\n"); 
      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcasted message. dont broadcast again
        dbg("Boot", "Already broadcast. Discarding....");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if(proximity){ 
        int id = pkt->spot_id;
        if(id == 1 || id == 2 || id == 3){
          updateFeedingSpot(pkt->food_g, 1);
        }else{
        if(id == 4 || id == 5 || id == 6){
          updateFeedingSpot(pkt->food_g, 2);
        }else{
        if(id == 7 || id == 8 || id == 9){
          updateFeedingSpot(pkt->food_g, 3);
        }}}    
      }else{
        dbg("Boot", "broadcasting food SPOT update\n");
        fwd_broadcast_update_spot(msg);        
      }

    } else {
      dbg("Boot", "Something went terribly wrong!");
    }
    dbg("Boot", "Cant believe its you\n");
    return msg;
  }

  void fwd_broadcast_update_spot(message_t* msg){
    if(busy){return;}
    if (call SendUpdateFeedingSpot.send(
              AM_BROADCAST_ADDR, msg, sizeof(UpdateFeedingSpot)) == SUCCESS){
      dbg("Boot", "forwarded food SPOT UPDATE message\n");
      busy = TRUE;
    }else{
      dbg("Boot", "WHYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY\n\n");
    }
    dbg("Boot", "WHYYYYYYYY\n");
  }

  event void SendUpdateFeedingSpot.sendDone(message_t* msg, error_t error){
    dbg("Boot", "@SendUpdateFeedingSpot: done\n");
    busy = FALSE;
  }
}







