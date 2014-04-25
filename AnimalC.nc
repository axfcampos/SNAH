#include "Timer.h"
#include "Animal.h"

module AnimalC @safe() {
  
  uses {
    interface Boot;
    interface Packet; //to access message_t
    //interface AMPacket; //to access message_t
    interface AMSend as SendPing; //to send packets
    interface AMSend as SendFoodQuery;
    interface AMSend as SendFoodUpdate;
    interface SplitControl as AMControl; //to start radio
    interface Receive as ReceivePing; //to receive packets
    interface Receive as ReceiveFoodUpdate; //to update daily food dosage
    interface Receive as ReceiveFoodQuery; //receive food query
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

  //vars
  bool busy = FALSE; //keep track if radio is busy sending
  message_t packet; //to hold data for transmission
  float max_food; //daily max food intake
  float food_intake; //amount of food eaten today
  int last_msg[MAX_ANIMALS];


  //funcs
  event void Boot.booted(){
    dbg("Boot", "=== Node has booted successfully!\n");
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
      busy = FALSE;
    }
  }
  event void SendFoodQuery.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&packet == msg) {
      dbg("Boot", "No errors accured, Send is available\n");
      busy = FALSE;
    }
  }
  event void SendFoodUpdate.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&packet == msg) {
      dbg("Boot", "No errors accured, Send is available\n");
      busy = FALSE;
    }
  }
  event message_t* ReceivePing.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\n hello \n");
    dbg("Boot", "\n please %d", len);
    if (len == sizeof(PingMsg)) {
      PingMsg* ping_pkt = (PingMsg*)payload;
      dbg("Boot", "== Message Arrived!\n number: %d \n", ping_pkt->number);
    }
  }

  event message_t* ReceiveFoodQuery.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "IVE ARRIVED!!!");

  }

  event message_t* ReceiveFoodUpdate.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\nola chegou o update %d vs %d\n", len, sizeof(UpdateFoodDailyDosage));
    
    if (len == sizeof(UpdateFoodDailyDosage)){
      UpdateFoodDailyDosage* pkt = (UpdateFoodDailyDosage*)payload; //cast
      dbg("Boot", "CHEGOU AQUI\n"); 
      if(!check_ok_for_broadcast){
        return msg;
      }
      dbg("Boot", "here here here\n");
      if(pkt->mote_dest == 0){ //if 0, update mine and broadcast (save id to avoid rebroadcast)
        max_food = pkt->newFoodMaxkg;
        broadcastFoodUpdate(msg); 
        
      } else {
        if(pkt->mote_dest == TOS_NODE_ID){ //if its me
          max_food = pkt->newFoodMaxkg;
        }
      }

    }
  }


  //aux functions
  void broadcastFoodUpdate(message_t* msg){
    dbg("Boot", "here here\n");
    if(!busy){
      if (call SendFoodUpdate.send(
            AM_BROADCAST_ADDR, msg, sizeof(UpdateFoodDailyDosage)) == SUCCESS){
        dbg("Boot", "forward message");
        busy = TRUE;
      }
    } else {
      dbg("Boot", "broadcast failed. ITS BUSY!");
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

}
