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
            enum Operations
            {
               DIRECTIONAL_BUY  =  1,
               DIRECTIONAL_SELL =  10,
               REVERSAL_BUY     =  2,
               REVERSAL_SELL    =  20,
               FAIL =  0,
            };
            enum Linear_Operations
            {
               LR   =  0,
               C1P  =  1,
               C1M  = -1,
               C2P  =  2,
               C2M  = -2,
               C3P  =  3,
               C3M  = -3,
            };
            enum Strat_type
            {
               DIRECTIONAL = 0,
               REVERSAL    = 1,
               ST_DEV_C2 =2,
               ST_DEV_C3 = 3,
               
            };
   public:       
            EntrySignal();
            ~EntrySignal();
            int  isSignalCandle(int type, int& _ccode);
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
   delete(i);
  }
//+------------------------------------------------------------------+

bool EntrySignal::isSell(int type){return false;}
bool EntrySignal::isBuy(int type){return false;}
int  EntrySignal::Directional(int op)
{
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   int    result  = FAIL;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = DIRECTIONAL_BUY;
   else if(Open[1]>bb_low && Close[1]< bb_low  ) result = DIRECTIONAL_SELL;
   return result;   
}
int  EntrySignal::Reversal(int op)
{
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   int    result  = FAIL;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = REVERSAL_BUY;
   else if(Open[1]>bb_low && Close[1]<bb_low   ) result = REVERSAL_SELL;
   return result;
}
int  EntrySignal::Std_Dev_Ch2()
{
   /*------------------------------------------------------
    * Logic:                                              |  
    *-------                                              |
    * Trade Reversal if:                                  |  
    * Close Outside C2 and inside BB, and opens inside BB | 
    * Trade Directional if:                               |
    * Close Outside C2 and outside BB, Open Outside BB    | 
    * Dont Trade if:                                      |
    * Close Outside C2 and outside BB, and Open inside BB |
    *------------------------------------------------------*/
    
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_high_i0 = i.iBB(0,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   double bb_low_i0 = i.iBB(0,MODE_LOWER);
   double stdev_C2P= i.iLR(1,C2P);
   double stdev_C2M= i.iLR(1,C2M); 
   int res = FAIL;
   if( (Close[1]>stdev_C2P && Close[1]<bb_high) &&(Open[0]<bb_high_i0) ) res = REVERSAL_SELL;
   else  if( (Close[1]<stdev_C2M && Close[1]>bb_low) && (Open[0]>bb_low_i0) ) res = REVERSAL_BUY;
   else if( (Close[1] > stdev_C2P && Close[1] > bb_high && Open[0] > bb_high_i0)||
            (Close[1] < stdev_C2M && Close[1] < bb_low  && Open[0] < bb_low_i0 )   ){
             res = FAIL;
            }
   Comment("Std_Dev_Ch2() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
   return res;

}
int  EntrySignal::Std_Dev_Ch3()
{
   /*----------------------------------------------------------
    * Logic:                                                  |  
    *-------                                                  |
    * Trade Directional if:                                   |  
    * 1)Market Crosses C3 and Close inside C3 and outside BB  |
    * 2)Close and open outside C3 and BB                      | 
    * Trade Reversal if:                                      |         
    * 1) Market Crosses C3 and Close inside C3 & BB           |
    *--------------------------                               |
    * If Reversal trade open and a Directional Signal         | 
    * occur Close Directional and open Reversal (hedge T/F)   |
    * Dont Trade if:                                          |
    * Close Outside C2 and inside BB, and Open inside BB      |
    *----------------------------------------------------------*/
   
   double bb_high = i.iBB(1,MODE_UPPER);
   double bb_high_i0 = i.iBB(0,MODE_UPPER);
   double bb_low  = i.iBB(1,MODE_LOWER);
   double bb_low_i0 = i.iBB(0,MODE_LOWER);
   double stdev_C3P= i.iLR(1,C3P);
   double stdev_C3M= i.iLR(1,C3M);
   
   int res = FAIL;
   //for buy
   if (High[1] >= stdev_C3P && Close[1] < stdev_C3P)
      res = DIRECTIONAL_BUY;
   else if( (Close[1] > stdev_C3P && Open[0] > stdev_C3P) && 
            (Close[1] > bb_high   && Open[0] > bb_high_i0)   )
      res = DIRECTIONAL_BUY;
   else if(Low[1]<= stdev_C3M && Close[1]<stdev_C3M && Close[1]>bb_low)
      res = REVERSAL_BUY;
   //for sell
   else if(Low[1]<= stdev_C3M && Close[1] > stdev_C3M)
      res = DIRECTIONAL_SELL;
   else if( (Close[1] < stdev_C3M && Open[0] < stdev_C3M) &&
            (Close[1] <bb_low       && Open[0] < bb_low_i0)    )
      res = DIRECTIONAL_SELL;
   else if(High[1]>= stdev_C3P && Close[1]<stdev_C3P && Close[1]<bb_high)
      res = REVERSAL_SELL;
   Comment("Std_Dev_Ch3() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C3P[",(string)stdev_C3P,"] stdev_C3M[",(string)stdev_C3M,"]") ;
   return res;
}
int  EntrySignal::isSignalCandle(int type, int& _ccode)
{   
   int res =FAIL;
   string rest="";
   switch(type)
   {
      case DIRECTIONAL :
         break;
      case REVERSAL    :
         break;
      case ST_DEV_C2   :
         res = Std_Dev_Ch2();
         _ccode=(int)""+ST_DEV_C2+""+res;
        // res = (int) rest;
         break;
      case ST_DEV_C3   :
         res = Std_Dev_Ch3();
         _ccode=(int)""+ST_DEV_C3+""+res;
         //res = (int)rest;
         break;
         
   }
   //res= (int)ST_DEV_C2+""+res;
   //Print("res[",res,"]");
   return res;
}              