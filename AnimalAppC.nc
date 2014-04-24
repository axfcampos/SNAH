#include "Animal.h"

configuration AnimalAppC {}
implementation {

  components MainC;
  components AnimalC as App;
  components ActiveMessageC;
  components new AMSenderC(AM_PINGMSG);
  components new AMReceiverC(AM_PINGMSG) as Receiver0;
  components new AMReceiverC(AM_GETFOODDAILYDOSAGE) as Receiver1;
  components new TimerMilliC() as Timer0;

  App.Boot -> MainC.Boot;
  
  App.Packet -> AMSenderC;
  //App.AMPacket -> AMSenderC;
  App.AMSend -> AMSenderC;
  App.AMControl -> ActiveMessageC;
  App.ReceivePing -> Receiver0;
  App.ReceiveFoodQuery -> Receiver1;
  App.MilliTimer -> Timer0;
}
