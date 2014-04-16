#include "Animal.h"

configuration AnimalAppC {}
implementation {

  components MainC as LedsC;
  components AnimalC as App;
  components new AMSenderC(AM_RADIO_PING_MSG);
  components new AMReceiverC(AM_RADIO_PING_MSG);
  components ActiveMessageC;
  components new TimerMilliC();

  App.Boot -> MainC.Boot;

  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;
  App.Leds -> LedsC;
  App.MilliTimer -> TimerMilliC;
}
