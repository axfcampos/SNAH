#include "Animal.h"

configuration AnimalAppC {}
implementation {

  components MainC;
  components AnimalC as App;
  components ActiveMessageC;
  
  components new AMSenderC(AM_PINGMSG) as Sender0;
  components new AMSenderC(AM_GETFOODDAILYDOSAGE) as Sender1;
  components new AMSenderC(AM_UPDATEFOODDAILYDOSAGE) as Sender2;
  components new AMSenderC(AM_GETFOODRESPONSE) as Sender3;

  components new AMReceiverC(AM_PINGMSG) as Receiver0;
  components new AMReceiverC(AM_GETFOODDAILYDOSAGE) as Receiver1;
  components new AMReceiverC(AM_UPDATEFOODDAILYDOSAGE) as Receiver2;
  components new AMReceiverC(AM_GETFOODRESPONSE) as Receiver3;

  components new TimerMilliC() as Timer0;

  App.Boot -> MainC.Boot;
  
  App.Packet -> Sender3;

  App.SendPing -> Sender0;
  App.SendFoodQuery -> Sender1;
  App.SendFoodUpdate -> Sender2;
  App.SendFoodResponse -> Sender3;

  App.AMControl -> ActiveMessageC;
  
  App.ReceivePing -> Receiver0;
  App.ReceiveFoodQuery -> Receiver1;
  App.ReceiveFoodUpdate -> Receiver2;
  App.ReceiveFoodResponse -> Receiver3;
  
  App.MilliTimer -> Timer0;
}
