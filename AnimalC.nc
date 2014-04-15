#include "Animal.h"
#include "Timer.h"

module AnimalC @safe() {
  
  uses interface App;
  uses interface Boot;
  uses interface Packet;
  uses interface AMPacket;
  uses interface AMSend;
  //SpliControl is a general interface used for starting and stopping componenets. 
  //but name AMControl is a mnemonic to remind us that the particular instance of SplitControl
  //is used to control the ActiveMessageG component
  uses interface SplitControl as AMControl; 
}


implementation {
  bool busy = FALSE;
  message_t pkt;


  event void Boot.booted() {
    call AMControl.start();
    dbg("Boot", "Node has started.\n")
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      dbg("Boot", "AMControl started\n");
    }else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {

  }
}
