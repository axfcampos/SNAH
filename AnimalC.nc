#include "Animal.h"

module AnimalC @safe() {
  
  uses {
    interface Boot;
    interface Packet; //to access message_t
    interface AMPacket; //to access message_t
    interface AMSend; //to send packets
    interface SplitControl as AMControl; //to start radio
    interface Receive; //to receive packets
    interface Timer<TMilli> as Timer0;
  }
}

/*
 * dbg: Boot is stdout
 *
 */
implementation {

  void doSomething();
  bool busy = FALSE; //keep track if radio is busy sending
  message_t pkt; //to hold data for transmission

  event void Boot.booted(){
    
    dbg("Boot", "Node has booted successfully!\n");

    call AMControl.start();
  }

  event void AMControl.startDone(error_t err){
    if (err == SUCCESS) {
      dbg("Boot", "Radio has started successfully!\n");
      //do something
      //doSomething();
      call Timer0.startPeriodic(250);
    } else {
      //retry
      dbg("Boot", "Radio failed to start, retrying..\n");
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err){
    dbg("Boot", "Radio has stopped..\n");
  }

  event void Timer0.fired(){
    
    //here we are gonna do something
    dbg("Boot", "Gonna do something\n");
    
    if(!busy){
      
      PingMsg* ping_pkt = 
        (PingMsg*)(call Packet.getPayload(&pkt, sizeof(PingMsg)));
      
      ping_pkt->nodeid = TOS_NODE_ID;
      ping_pkt->number = 1;
      
      if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(PingMsg)) == SUCCESS){
        busy = TRUE;
      }
    }
  }

  event void AMSend.sendDone(message_t* msg, error_t error){
    dbg("Boot", "Sending packet is done. \n");
    if (&pkt == msg) {
      dbg("Boot", "No errors accured, Send is !busy");
      busy = FALSE;
    }
  }

  event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
    if (len == sizeof(PingMsg)) {
      PingMsg* ping_pkt = (PingMsg*)payload;
      dbg("Boot", 
          "== Message Arrived!\n nodeid: %d \n number: %d \n", 
          ping_pkt->nodeid, ping_pkt->number);
    }
  }



}
