//+------------------------------------------------------------------+
//|                                                         Test.mq4 |
//|                                                    Zobad Mahmood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include "EntrySignal.mqh"
#include "MoneyManagement.mqh"
#include "Indicators.mqh"


EntrySignal *algo ;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   algo = new EntrySignal();
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   
   delete(algo);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(IsNewBar())
   {
      int ccode=0;
      algo.isSignalCandle(3,ccode);
      Print("[",ccode,"]");
   }
  }
//+------------------------------------------------------------------+

bool IsNewBar()
  {
   static datetime RegBarTime=0;
   datetime ThisBarTime=Time[0];
   if(ThisBarTime==RegBarTime)
     {
      return false;
     }
   else
     {
      RegBarTime=ThisBarTime;
      return true;
     }
  }