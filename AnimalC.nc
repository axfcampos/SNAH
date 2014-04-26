//sup
#include "Timer.h"
#include "Animal.h"
#include <pthread.h>
#include <time.h>
#include <stdlib.h>

module AnimalC @safe() {
  
  uses {
    interface Boot;
    interface Packet; //to access message_t
    //interface AMPacket; //to access message_t
    interface AMSend as SendPing; //to send packets
    interface AMSend as SendFoodQuery;
    interface AMSend as SendFoodUpdate;
    interface AMSend as SendFoodResponse;

    interface SplitControl as AMControl; //to start radio
    
    interface Receive as ReceivePing; //to receive packets
    interface Receive as ReceiveFoodUpdate; //to update daily food dosage
    interface Receive as ReceiveFoodQuery; //receive food query
    interface Receive as ReceiveFoodResponse; //receive food response and fwd
    
    interface Timer<TMilli> as MilliTimer;
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
  void broadcastFoodQuery(message_t* msg);
  void start_broadcastFoodResp();
  void fwd_broadcastFoodResp(message_t* msg);
  
  //vars
  bool busy = FALSE; //keep track if radio is busy sending
  message_t packet; //to hold data for transmission
  float max_food = 10.0; //daily max food intake
  float food_intake = 10.0; //amount of food eaten today
  int last_msg[MAX_ANIMALS];
  int last_msg_i = 0;
  pthread_mutex_t count_mutex;
  GetFoodResponse *gfr_pkt;
    
  
  //funcs
  event void Boot.booted(){
    dbg("Boot", "=== Node has booted successfully!\n");
    srand(time(NULL)); //starts random number gen. int r = rand()
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if (err == SUCCESS) {
      dbg("Boot", "Radio has started successfully!\n");
    } else {
      //retry
      dbg("Boot", "Radio failed to start, retrying..\n");
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err){
    dbg("Boot", "Radio has stopped..\n");
  }

  event void MilliTimer.fired() {
    //here we are gonna do something
    dbg("Boot", "Timer fired\n");
  }

  event void SendPing.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&packet == msg) {
      dbg("Boot", "No errors accured, Send is available\n");
      //busy = FALSE;
      //pthread_mutex_unlock(&count_mutex);
    }
  }
  event void SendFoodQuery.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending Food Query packet is done. \n");
    //if (&packet == msg) {
      //dbg("Boot", "No errors accured, Send is available\n");
      //busy = FALSE;
    //}

    //pthread_mutex_unlock(&count_mutex);
    dbg("Boot", "unlock mutex");
  }
  event void SendFoodUpdate.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending Food Update packet is done. \n");
    //if (&packet == msg) {
      //dbg("Boot", "No errors accured, Send is available\n");
      //busy = FALSE;
      //pthread_mutex_unlock(&count_mutex);
    //}
    dbg("Boot", "unlocked mutex");
  }
  event void SendFoodResponse.sendDone(message_t* msg, error_t error){
    dbg("Boot", "FoodResponse send Done");
    //pthread_mutex_unlock(&count_mutex);
    dbg("Boot", "unlocked mutex");
  }
  event message_t* ReceivePing.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\n hello \n");
    dbg("Boot", "\n please %d", len);
    if (len == sizeof(PingMsg)) {
      PingMsg* ping_pkt = (PingMsg*)payload;
      dbg("Boot", "== Message Arrived!\n number: %d \n", ping_pkt->number);
    }
    return msg;
  }

  event message_t* ReceiveFoodQuery.receive(message_t* msg, void* payload, uint8_t len){
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
  }

  event message_t* ReceiveFoodResponse.receive(message_t* msg, void* payload, uint8_t len){
    
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
  }

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
    //pthread_mutex_lock(&count_mutex); 
      if (call SendFoodUpdate.send(
            AM_BROADCAST_ADDR, msg, sizeof(UpdateFoodDailyDosage)) == SUCCESS){
        dbg("Boot", "forwarded food query message");
        //busy = TRUE;
        //pthread_mutex_unlock(&count_mutex);
      }
  }
  void broadcastFoodQuery(message_t* msg){
    dbg("Boot", "broadcasting food query");
    //pthread_mutex_lock(&count_mutex);
      if (call SendFoodQuery.send(
            AM_BROADCAST_ADDR, msg, sizeof(GetFoodDailyDosage)) == SUCCESS){
        dbg("Boot", "forwarded food query message");
        //pthread_mutex_unlock(&count_mutex);
      }
  }
  void start_broadcastFoodResp(){
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
  }

  void fwd_broadcastFoodResp(message_t* msg){
    //pthread_mutex_lock(&count_mutex);
      if (call SendFoodResponse.send(
            AM_BROADCAST_ADDR, msg, sizeof(GetFoodResponse)) == SUCCESS){
        dbg("Boot", "fowarded GetFoodResponse");
        //pthread_mutex_unlock(&count_mutex);
      }
  }
  
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

}
