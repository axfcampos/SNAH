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
  void writeLog(char log_line[]);
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
    
  //logs
  FILE* log_file;
  char log_buffer[2];
  
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
        call FSpotProximityTimer.startPeriodic(90000);
        call BroadcastTimer.startPeriodic(100000 * (10 - TOS_NODE_ID));
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
    writeLog("@Ping: Sending packet is done. \n");
    if (&packet == msg) {
      writeLog("@Ping: No errors accured, Send is available");
      //busy = FALSE;
      //pthread_mutex_unlock(&count_mutex);
      busy = FALSE;
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
    writeLog("Sending Food Update packet is done. ");
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
      writeLog("@ReceiveFoodUpdate; arrived"); 
      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcasted message. dont broadcast again
        writeLog("@ReceiveFoodUpdate: Already broadcast. Discarding....");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if(pkt->mote_dest == 0){ //if 0, update mine and broadcast (save id to avoid rebroadcast)
        max_food = pkt->new_food_max;
        broadcastFoodUpdate(msg); 
        writeLog("@ReceiveFoodUpdate: mote_dest = 0, update and re-broadcast");
        
      } else {
        if(pkt->mote_dest == TOS_NODE_ID){ //if its me
          writeLog("@ReceiveFoodUpdate: Message to me, not rebroadcasting");
          max_food = pkt->new_food_max;
        }else{
          writeLog("@ReceiveFoodUpdate: Not to me and not 0, re-broadcasting");
          broadcastFoodUpdate(msg);
        }
      }
    } else {
      writeLog("Something went terribly wrong!");
    }
    return msg;
  }


  //aux functions
  void broadcastFoodUpdate(message_t* msg){
    writeLog("broadcasting food update");
    if(busy){return;}
    if (call SendFoodUpdate.send(
         AM_BROADCAST_ADDR, msg, sizeof(UpdateFoodDailyDosage)) == SUCCESS){
      writeLog("forwarded food query message");
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
    writeLog("@BroadcastTimer: it fired!");
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
      writeLog("success broadcast AnimalInfo");
      busy = TRUE;
      ai_pkt = 0;
    }
  }

  task void fwd_broadcast_animal_info(){
    //pthread_mutex_lock(&count_mutex);
    if(busy){return;}
    writeLog("@fwd_broadcast_animal_info: entered");
    ai_pkt = (AnimalInfo*)call Packet.getPayload(&packet, sizeof(AnimalInfo));
    ai_pkt->msg_id = animal_info_packet->msg_id;
    ai_pkt->gps_la = animal_info_packet->gps_la;
    ai_pkt->gps_lo = animal_info_packet->gps_lo;
    ai_pkt->food_g = animal_info_packet->food_g;
    ai_pkt->mote_id = animal_info_packet->mote_id;
    if(call SendAnimalInfo.send(
          AM_BROADCAST_ADDR, &packet, sizeof(AnimalInfo)) == SUCCESS){
      writeLog("@fwd_broadcast_animal_info: SUCCESS");
      busy = TRUE;
      ai_pkt = 0;
    }
  }

  event void SendAnimalInfo.sendDone(message_t* msg, error_t error){
    
    writeLog("@SendAnimalInfo.sendDone: entering");
    if (&packet == msg){
      //unlock mutex... ?
      //dbg("Boot", "@SendAnimalInfo.sendDone ----\n");
      //pthread_mutex_unlock(&count_mutex);
      busy = FALSE;
    }
  }
  
  event message_t* ReceiveAnimalInfo.receive(message_t* msg, void* payload, uint8_t len){
    char str[200];
    if (len == sizeof(AnimalInfo)){
      AnimalInfo* pkt = (AnimalInfo*)payload; //cast
      //dbg("Boot", "@AnimalInfo: msg_id:%d mote_id:%d\n", pkt->msg_id, pkt->mote_id); 
      sprintf(str, "@AnimalInfo: msg_id:%d mote_id:%d\n", pkt->msg_id, pkt->mote_id); 
      writeLog(str);
      if(!check_ok_for_broadcast(pkt->msg_id) || pkt->mote_id == TOS_NODE_ID){
        //already broadcasted message. dont broadcast again
        writeLog("@AnimalInfo: Already broadcast. Discarding....");
        return msg;
      } else {
        add_to_broadcast_checker(pkt->msg_id);
      }

      if(TOS_NODE_ID == 0){
        writeLog("@AnimalInfo: REACHED SERVER, im 0");
        sensor_file = fopen("sensor_info.txt", "a+"); 
        fprintf(sensor_file, "node_id: %d || GPS-la: %d lo: %d || food_eaten: %d || msg_id: %d\n", 
            pkt->mote_id, pkt->gps_la, pkt->gps_lo, pkt->food_g, pkt->msg_id);
        fclose(sensor_file);
      }else{
        writeLog("@AnimalInfo: calling post task fwd ");
        animal_info_packet = pkt;
        post fwd_broadcast_animal_info();
      }
    } else {
      dbg("Boot", "Something went terribly wrong!");
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
    //dbg("Boot", "@ReceiveProximity: TURNING ON PROXIMITY!\n");
    writeLog("@ReceiveProximity: TURNING ON PROXIMITY!");
    if(proximity){
      proximity = FALSE;
    }else{
      proximity = TRUE;
    }
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
    char str[200], str1[200];

    sprintf(food_filename, "fs%d", spot_id);
    feeding_spot = fopen(food_filename, "r");

    fscanf(feeding_spot, "%d %d", &value, &max);
    //dbg("Boot", "\n\n eating %d .. %d", value, max);
    sprintf(str, "@eat_from_spot: eating %d of %d in max: %d", food_amount, value, max);
    writeLog(str);
    if (food_intake >= max_food){
      //dbg("Boot", "@eat_from_spot: DID NOT EAT. Achieve daily dosage!");
      sprintf(str, "@eat_from_spot: DID NOT EAT. Achieved daily max dosage!");
      writeLog(str);
      fclose(feeding_spot);
      return;
    }//already had daily dosage!
    
    fclose(feeding_spot);
    feeding_spot = fopen(food_filename, "w+");

    if(value > food_amount){
      //dbg("Boot", "\n\n eating %d .. %d", (value - food_amount), max);
      sprintf(str1, "@eat_from_spot: eating %d .. %d", (value - food_amount), max);
      writeLog(str1);
      fprintf(feeding_spot, "%d %d", (value - food_amount), max);
      food_intake += food_amount; 
    }else{
      //dbg("Boot", "------ Not enough food! in feeding spot %d \n", spot_id);
      sprintf(str1, "@eat_from_spot: Not enough food in feeding spot %d", spot_id);
      writeLog(str1);
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
    char str[200];
    
    //dbg("Boot", "@updateFeedingSpot: entered");
    sprintf(str, "@updateFeedingSpot new_max: %d spot_id: %d", new_max_food, spot_id);
    writeLog(str);

    sprintf(food_filename, "fs%d", spot_id);
    feeding_spot = fopen(food_filename, "r");
    fscanf(feeding_spot, "%d %d", &value, &max);
    fclose(feeding_spot);
    feeding_spot = fopen(food_filename, "w+");
    fprintf(feeding_spot, "%d %d\n", new_max_food, new_max_food);
    fclose(feeding_spot);
  }

  
  event message_t* ReceiveUpdateFeedingSpot.receive(message_t* msg, void* payload, uint8_t len){
    char str[200];
    char str2[200];
    sprintf(str, "@ReceiveUpdateFeedingSpot.receive(): msg arrived");
    //dbg("Boot", "\nola chegou o update %d vs %d\n", len, sizeof(UpdateFeedingSpot));
    writeLog(str);
    if (len == sizeof(UpdateFeedingSpot)){
      UpdateFeedingSpot* pkt = (UpdateFeedingSpot*)payload; //cast
      if(!check_ok_for_broadcast(pkt->msg_id)){
        //already broadcasted message. dont broadcast again
        //dbg("Boot", "Already broadcast. Discarding....");
        sprintf(str, "@ReceiveUpdateFedingSpot.receive: Already broadcast. Discarding..");
        writeLog(str);
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
        //dbg("Boot", "broadcasting food SPOT update\n");
        sprintf(str2, "@ReceiveUpdateFoodSpot.receive(): forwarding!");
        writeLog(str2);
        fwd_broadcast_update_spot(msg);        
      }

    } else {
      dbg("Boot", "Something went terribly wrong!");
    }
    return msg;
  }

  void fwd_broadcast_update_spot(message_t* msg){
    char str[200];
    if(busy){return;}
    if (call SendUpdateFeedingSpot.send(
              AM_BROADCAST_ADDR, msg, sizeof(UpdateFeedingSpot)) == SUCCESS){
      //dbg("Boot", "forwarded food SPOT UPDATE message\n");
      sprintf(str, "@fwd_broadcast_update_spot: send == SUCCES, BUSY = TRUE");
      writeLog(str);
      busy = TRUE;
    }else{
      dbg("Boot", "WHYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYYY\n\n");
    }
    //dbg("Boot", "WHYYYYYYYY\n");
  }

  event void SendUpdateFeedingSpot.sendDone(message_t* msg, error_t error){
    //dbg("Boot", "@SendUpdateFeedingSpot: done\n");
    char str[200];
    sprintf(str, "@SendUpdateFeedingSpot: done. busy = false");
    writeLog(str);
    busy = FALSE;
  }
  
  void writeLog(char log_line[]){
    sprintf(log_buffer, "l%d", TOS_NODE_ID);
    log_file = fopen(log_buffer, "a+");

    fprintf(log_file, "%s\n", log_line);
    fclose(log_file);
  }
}







