//+------------------------------------------------------------------+
//|                                                  EntrySignal.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict
#include "Indicators.mqh"

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class EntrySignal
{
   private:
            Indicators *i;
            bool isSell(int type);
            bool isBuy(int type);
            int  Directional(int op);
            int  Reversal(int op);
            int  Std_Dev_Ch2();
            int  Std_Dev_Ch3();
            enum Operation
            {
               BUY  =  1,
               SELL = -1,
               FAIL =  0,
            };
   public:       
            EntrySignal();
            ~EntrySignal();
            int  isSignalCandle(int type);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EntrySignal::EntrySignal()
  {
    i = new Indicators();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EntrySignal::~EntrySignal()
  {
  }
//+------------------------------------------------------------------+

bool EntrySignal::isSell(int type){return false;}
bool EntrySignal::isBuy(int type){return false;}
int  EntrySignal::Directional(int op)
{
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   int    result  = FAIL;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = BUY;
   else if(Open[1]>bb_low && Close[1]< bb_low  ) result = SELL;
   return result;   
}
int  EntrySignal::Reversal(int op)
{
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   int    result  = FAIL;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = BUY;
   else if(Open[1]>bb_low && Close[1]<bb_low   ) result = SELL;
   return result;
}
int  EntrySignal::Std_Dev_Ch2(){return 0;}
int  EntrySignal::Std_Dev_Ch3(){return 0;}
int  EntrySignal::isSignalCandle(int type){return 0;}              