//+------------------------------------------------------------------+
//|                                                      LR_Test.mq4 |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, MetaQuotes Software Corp."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "MoneyManagement.mqh"
#include "EntrySignal.mqh"

//+------------------------------------------------------------------+
//| Parameters                                                       |
//+------------------------------------------------------------------+

extern int     IdNum          = 1;
extern int     RPeriod        = 28;
extern color   MidColor       = Red;
extern int     LineWeight     = 1;
extern int     PriceVal       = 0;
extern double  StDevOutside2  = 2.55;
extern color   Outside2       = Red;
extern double  StDevOutside   = 1.68;
extern color   Outside        = Brown;
extern double  StDevInside    = 0.809;
extern color   Inside         = Green;
extern int period=0;
extern int LR_length=28;   // bars back regression begins
extern double std_channel_1=0.618;        // 1st channel
extern double std_channel_2=1.618;        // 2nd channel
extern double std_channel_3=2.618;        // 3nd channel
MoneyManagement *m;
EntrySignal *signal;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   delete m;
   m=NULL;
   delete signal;
   signal = NULL;
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
   m= new MoneyManagement();
   int tkt =m.getTicket();
   string LR_trendline, stDevCP1,stDevCM1, stDevCP2, stDevCM2, stDevCP3, stDevCM3;
   LR_trendline = (string)period+"m "+(string)LR_length+" TL";
   stDevCP1     = (string)period+"m "+(string)LR_length+" +"+(string)std_channel_1+"d";
   stDevCM1     =(string)period+"m "+(string)LR_length+" -"+(string)std_channel_1+"d";
   stDevCP2     = (string)period+"m "+(string)LR_length+" +"+(string)std_channel_2+"d";
   stDevCM2     = (string)period+"m "+(string)LR_length+" -"+(string)std_channel_2+"d";
   stDevCP3     =(string)period+"m "+(string)LR_length+" +"+(string)std_channel_3+"d";
   stDevCM3     = (string)period+"m "+(string)LR_length+" -"+(string)std_channel_3+"d";
   double LR_line = NormalizeDouble(ObjectGetValueByShift(LR_trendline, 0),Digits);
   double LR_line2 = NormalizeDouble(ObjectGetValueByShift(LR_trendline, 2),Digits);
   double stDev_Positive1 = NormalizeDouble(ObjectGetValueByShift(stDevCP1, 0),Digits);
   double stDev_Negativ1 = NormalizeDouble(ObjectGetValueByShift(stDevCM1, 0),Digits);
   double stDev_Positive2 = NormalizeDouble(ObjectGetValueByShift(stDevCP2, 0),Digits);
   double stDev_Negativ2 = NormalizeDouble(ObjectGetValueByShift(stDevCM2, 0),Digits);
   double stDev_Positive3 = NormalizeDouble(ObjectGetValueByShift(stDevCP3, 0),Digits);
   double stDev_Negativ3 = NormalizeDouble(ObjectGetValueByShift(stDevCM3, 0),Digits);
   
   //Comment("Ticket[",(string)tkt,"] LR Line[0]="+(string)LR_line+"\nStandard Deviation positive[0]="+(string)stDev_Positive1+"\nStandard Deviation Negative[0]="+(string)stDev_Negativ1);
   
   
   double a = iCustom(Symbol(),0,"linear-regression-channel",0,2          );
   double b =iCustom(Symbol(),0,"linear-regression-channel",IdNum,RPeriod,
                      MidColor,LineWeight, PriceVal,StDevOutside2,Outside2,
                      StDevOutside,Outside,StDevInside,Inside,1,1          );
   double c = iCustom(Symbol(),0,"linear-regression-channel",IdNum,RPeriod,
                      MidColor,LineWeight, PriceVal,StDevOutside2,Outside2,
                      StDevOutside,Outside,StDevInside,Inside,2,1          );
   double d = iCustom(Symbol(),0,"linear-regression-channel",IdNum,RPeriod,
                      MidColor,LineWeight, PriceVal,StDevOutside2,Outside2,
                      StDevOutside,Outside,StDevInside,Inside,3,1          );       
   double e = iCustom(Symbol(),0,"linear-regression-channel",IdNum,RPeriod,
                      MidColor,LineWeight, PriceVal,StDevOutside2,Outside2,
                      StDevOutside,Outside,StDevInside,Inside,4,1          );
   double f = iCustom(Symbol(),0,"linear-regression-channel",IdNum,RPeriod,
                      MidColor,LineWeight, PriceVal,StDevOutside2,Outside2,
                      StDevOutside,Outside,StDevInside,Inside,5,1          );   
  Comment("a["+a+"]\nb["+b+"]\nc["+c+"]\nd["+d+"]\ne["+e+"]\nf["+f+"]");    
     
                                     
   
  }
//+------------------------------------------------------------------+
