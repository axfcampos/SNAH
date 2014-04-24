#include "Timer.h"
#include "Animal.h"

module AnimalC @safe() {
  
  uses {
    interface Boot;
    interface Packet; //to access message_t
    //interface AMPacket; //to access message_t
    interface AMSend; //to send packets
    interface SplitControl as AMControl; //to start radio
    interface Receive as ReceivePing; //to receive packets
    //interface Receive as ReceiveFoodUpdate; //to update daily food dosage
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

  //vars
  bool busy = FALSE; //keep track if radio is busy sending
  message_t packet; //to hold data for transmission
  float max_food; //daily max food intake
  float food_intake; //amount of food eaten today


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
    dbg("Boot", "Gonna do something\n");
    
    if(!busy){
      
      PingMsg* ping_pkt = 
        (PingMsg*)(call Packet.getPayload(&packet, sizeof(PingMsg)));
      ping_pkt->number = 1;
      
      if(call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(PingMsg)) == SUCCESS){
        busy = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&packet == msg) {
      dbg("Boot", "No errors accured, Send is available\n");
      busy = FALSE;
    }
  }

  event message_t* ReceivePing.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "\n hello \n");
    dbg("Boot", "\n please \n");
    if (len == sizeof(PingMsg)) {
      PingMsg* ping_pkt = (PingMsg*)payload;
      dbg("Boot", "== Message Arrived!\n number: %d \n", ping_pkt->number);
    }
  }

  event message_t* ReceiveFoodQuery.receive(message_t* msg, void* payload, uint8_t len){
    dbg("Boot", "IVE ARRIVED!!!");

  }


}
