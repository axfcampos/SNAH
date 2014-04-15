//@author Alexandre Campos

#include "Animal.h"

configuration AnimalAppC {}
implementation {

  components MainC as App;
  components new AMSenderC(AM_RADIO_PING_MSG);
  components new AMReceiverC(AM_RADIO_PING_MSG);
  components new ActiveMessageC;
  components new TimerMilliC();

  App.Boot -> MainC.Boot;

  App.Receive -> AMReceiverC;
  App.Send -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.Packet -> AMSenderC;

  App.MilliTimer -> TimerMilliC;
}
