#include "Animal.h"

configuration AnimalAppC {}
implementation {

  components MainC;
  components AnimalC as App;
  components ActiveMessageC;
  components new AMSenderC(AM_RADIO_PING_MSG);
  components new AMReceiverC(AM_RADIO_PING_MSG);
  components new TimerMilliC() as Timer0;

  App.Boot -> MainC;
  
  App.Packet -> AMSenderC;
  App.AMPacket -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Receive -> AMReceiverC;
  App.Timer0 -> Timer0;
}
