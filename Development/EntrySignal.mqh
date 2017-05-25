//+------------------------------------------------------------------+
//|                                                  EntrySignal.mqh |
//|                        Copyright 2017, MetaQuotes Software Corp. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class EntrySignal
{
   private:
            bool isSell(int type);
            bool isBuy(int type);
            int  BreakoutInverse();
            int  Reversal();
            int  Std_Dev_Ch2();
            int  Std_Dev_Ch3();
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
int  EntrySignal::BreakoutInverse(){return 0;}
int  EntrySignal::Reversal(){return 0;}
int  EntrySignal::Std_Dev_Ch2(){return 0;}
int  EntrySignal::Std_Dev_Ch3(){return 0;}
int  EntrySignal::isSignalCandle(int type){return 0;}              