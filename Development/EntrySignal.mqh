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
            Indicators *ind;
            bool isSell(int type);
            bool isBuy(int type);
            int  Directional(int op);
            int  Reversal(int op);
            int  Std_Dev_Ch2();
            int  Std_Dev_Ch3();
            int  Std_Dev_All();
            int  Revised_Std_Dev_Ch2();
            int  Revised_Std_Dev_Ch3();
            int  Revised_Reversal()   ;
            int  Revised_Directional();
            int  Test_Directional()   ;
            int  Test_Reversal()      ;
            enum Operations
            {
               DIRECTIONAL_BUY  =  1110,
               DIRECTIONAL_SELL =  1101,
               REVERSAL_BUY     =  0111,
               REVERSAL_SELL    =  1011,
               BUY              =  9009,
               SELL             =  8008,
               BUY_LEG1         =  18911,
               BUY_LEG2         =  18921,
               SELL_LEG1        =  18912,
               SELL_LEG2        =  18922,
               HEDGE_BUY        =  19811,
               HEDGE_SELL        =  19812,
               FAIL             =  0,
               FAIL_ERR         =  -13,
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
               DIRECTIONAL = 4,  //Directional
               REVERSAL    = 5,  //Reversal
               BOTH        = 1,  //Dir&Rev
               ST_DEV_C2   = 2,  //Standard Deviation 2
               ST_DEV_C3   = 3,  //Standard Deviation 3
               BREAKIN     = 6,  //Break in
                      
            };
   public:       
            EntrySignal();
            ~EntrySignal();
            int  Pattern_Point(double points);
            int  Pattern_Point_Negative(double points);
            int  Pattern_Point_Negative(double points, int magic);
            int  Pattern_Breakin();
            int  isSignalCandle(int type, int& _ccode);
            int  isSignalCandleRev(int type, int& _ccode);
            int  isSignalCandleTest(int type,int &_ccode);
            int  OrderOperationCode(int magic);
            bool isOrder(int &ticket,int magic, int opcode);
            bool isExist(int magic, string comment, int &count, int &op_code, double &lots);
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EntrySignal::EntrySignal()
  {
    ind = new Indicators();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
EntrySignal::~EntrySignal()
  {
   delete(ind);
  }
//+------------------------------------------------------------------+

bool EntrySignal::isSell(int t){return false;}
bool EntrySignal::isBuy(int t){return false;}
bool EntrySignal::isExist(int magic, string comment, int &count, int &op_code, double &prevlot)
{
   int total = OrdersTotal();
   for(int ii=total-1; ii>=0;ii--){
      if(OrderSelect(total-1,SELECT_BY_POS,MODE_TRADES)>0){ 
         if(StringFind(OrderComment(),comment,0)!=-1){
            count=count+1;
            op_code = OrderType();
            if(OrderLots()>prevlot){
               prevlot = OrderLots();
            }
         }
      }
   }
   //Print("Count[",count,"]Method");
   if (count>0) return true;
   return false;
}
int  EntrySignal::Pattern_Point(double points)
{
  int digit =(int) MarketInfo(Symbol(), MODE_DIGITS);
  int total =OrdersTotal();
  if(OrderSelect(total-1,SELECT_BY_POS,MODE_TRADES)>0)
  {
   double openPrice=OrderOpenPrice();
   int    op_type= OrderType();
   if(op_type == OP_BUY)
   {
      //if(openPrice - Bid >= points)
      if(Bid -openPrice  >= NormalizeDouble(points*_Point,digit))
      {
         return DIRECTIONAL_BUY;
      }
   }
   if(op_type == OP_SELL)
   {
      if(openPrice-Ask >=NormalizeDouble(points*_Point,digit))
      //if(Ask-openPrice >=points)
      {
         return DIRECTIONAL_SELL;
      }   
   }  
  }     
  return FAIL;
}

int  EntrySignal::Pattern_Point_Negative(double points)
{
  int digit =(int) MarketInfo(Symbol(), MODE_DIGITS);
  int total =OrdersTotal();
  if(OrderSelect(total-1,SELECT_BY_POS,MODE_TRADES)>0)
  {
   
   double openPrice=OrderOpenPrice();
   int    op_type= OrderType();
   if(op_type == OP_SELL){  
      double t = (Bid - openPrice) * _Point;
      
      if(Bid -openPrice  >= NormalizeDouble(points*_Point,digit)){
         //Print("Checking sell[",t,"]" );  
       //if(openPrice - Bid >= points)
         return REVERSAL_SELL;
      }
   }
   if(op_type == OP_BUY){
      if(openPrice-Ask >=NormalizeDouble(points*_Point,digit)){
      double t = (openPrice- Ask) * _Point;
     // Print("Checking buy[",t,"]" );
      //if(Ask-openPrice >=points)      
         return REVERSAL_BUY;
      }   
   }  
  }     
  return FAIL;
}
int  EntrySignal::Pattern_Point_Negative(double points, int magic)
{
  int digit =(int) MarketInfo(Symbol(), MODE_DIGITS);
  int total =OrdersTotal();
  for(int i=total-1; i>0; i--){
     if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
     {
      if(OrderMagicNumber()==magic && OrderSymbol()==Symbol()){      
         double openPrice=OrderOpenPrice();
         int    op_type= OrderType();
         if(op_type == OP_SELL){  
            double t = (Bid - openPrice) * _Point;
            
            if(Bid -openPrice  >= NormalizeDouble(points*_Point,digit)){
               Print("Checking Point Value[",NormalizeDouble(points*_Point,digit),"]" );  
             //if(openPrice - Bid >= points)
               return REVERSAL_SELL;
            }
         }
         if(op_type == OP_BUY){
            if(openPrice-Ask >=NormalizeDouble(points*_Point,digit)){
            double t = (openPrice- Ask) * _Point;
            Print("Checking Point Value[",NormalizeDouble(points*_Point,digit),"]" );  
            //if(Ask-openPrice >=points)      
               return REVERSAL_BUY;
            }   
         }
      }  
     }else{Print("Error Order Select");}
  }     
  return FAIL;
}
int EntrySignal:: Pattern_Breakin()
{
   double bb_high =ind.iBB(1,MODE_UPPER);
   double bb_high2=ind.iBB(2,MODE_UPPER);
   double bb_low  =ind.iBB(1,MODE_LOWER);
   double bb_low2 =ind.iBB(2,MODE_LOWER);
   if(Open[2]>bb_high2 && Close[2]<bb_high2 ){ 
     if(Close[1]> Close[2] && Close[1]<bb_high){Print("Sell Alert"); return REVERSAL_SELL;}
   } 
   else if(Open[2]<bb_low2 && Close[2]>bb_low2){  
      if(Close[1]< Close[2] && Close[1]>bb_low){ Print("Buy Order Alert"); return REVERSAL_BUY;}
   }
   return FAIL;
}
int  EntrySignal::Directional(int op)
{
   double bb_high = ind.iBB(1,MODE_UPPER)                                  ;
   double bb_low  = ind.iBB(1,MODE_LOWER)                                  ;
   int    result  = FAIL                                                   ;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = DIRECTIONAL_BUY  ;
   else if(Open[1]>bb_low && Close[1]< bb_low  ) result = DIRECTIONAL_SELL ;
   return result                                                           ;   
}
int  EntrySignal::Reversal(int op)
{
   double bb_high = ind.iBB(1,MODE_UPPER)                                  ;
   double bb_low  = ind.iBB(1,MODE_LOWER)                                  ;
   int    result  = FAIL                                                   ;
   if     (Open[1]<bb_high && Close[1]>bb_high ) result = REVERSAL_BUY     ;
   else if(Open[1]>bb_low && Close[1]<bb_low   ) result = REVERSAL_SELL    ;
   result = Pattern_Breakin()                                              ;
   return result                                                           ;
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
    
   double bb_high    = ind.iBB(1,MODE_UPPER)                                                     ;
   double bb_high_i0 = ind.iBB(0,MODE_UPPER)                                                     ;
   double bb_low     = ind.iBB(1,MODE_LOWER)                                                     ;
   double bb_low_i0  = ind.iBB(0,MODE_LOWER)                                                     ;
   double stdev_C2P  = ind.iLR(1,C2P)                                                            ;
   double stdev_C2M  = ind.iLR(1,C2M)                                                            ;  
   int    res        = FAIL                                                                      ;
   if(stdev_C2P == 0 || stdev_C2M == 0) return FAIL_ERR                                          ;
   if( (Close[1]>stdev_C2P && Close[1]<bb_high) &&(Open[0]<bb_high_i0) ) res = REVERSAL_SELL     ;
   else  if( (Close[1]<stdev_C2M && Close[1]>bb_low) && (Open[0]>bb_low_i0) ) res = REVERSAL_BUY ;
   else if( (Close[1] > stdev_C2P && Close[1] > bb_high && Open[0] > bb_high_i0)||
            (Close[1] < stdev_C2M && Close[1] < bb_low  && Open[0] < bb_low_i0 )   ){
             res = FAIL                                                                          ;
            }
   else res = FAIL                                                                               ;
   //Comment("Std_Dev_Ch2() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
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
   
   double bb_high    = ind.iBB(1,MODE_UPPER)                                                                                        ;
   double bb_high_i0 = ind.iBB(0,MODE_UPPER)                                                                                        ;
   double bb_low     = ind.iBB(1,MODE_LOWER)                                                                                        ;
   double bb_low_i0  = ind.iBB(0,MODE_LOWER)                                                                                        ;
   double stdev_C3P  = ind.iLR(1,C3P)                                                                                               ;
   double stdev_C2P  = ind.iLR(1,C2P)                                                                                               ;
   double stdev_C3M  = ind.iLR(1,C3M)                                                                                               ;
   double stdev_C2M  = ind.iLR(1,C2M)                                                                                               ;
   int    res        = FAIL                                                                                                         ;
   if(stdev_C2P == 0 ||stdev_C2M == 0.0 || stdev_C3P==0.0 || stdev_C3M == 0)        return FAIL_ERR                                          ;
   
   //for buy
   if       (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] > bb_high  )                           res = DIRECTIONAL_BUY ;
   else if( (Close[1] >  stdev_C3P && Close[1] > bb_high   && Open [0] > stdev_C3P) &&  Open[0] > bb_high_i0) res = DIRECTIONAL_BUY ;
   else if  (High [1] >= stdev_C2P && Close[1] < stdev_C2P && Close[1] < bb_high  )                           return FAIL           ;
   else if  (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] > bb_low   )                           res = REVERSAL_BUY    ;
   //for sell
   else if  (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] < bb_low   )                           res = DIRECTIONAL_SELL;
   else if( (Close[1] <  stdev_C3M && Close[1] < bb_low    && Open [0] < stdev_C3M) && (Open[0] < bb_low_i0)) res = DIRECTIONAL_SELL;
   else if  (Low  [1] <= stdev_C2M && Close[1] > stdev_C2M && Close[1] > bb_low)                              return FAIL           ;
   else if  (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] < bb_high)                             res = REVERSAL_SELL   ;
   Comment("Std_Dev_Ch3() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C3P[",(string)stdev_C3P,"] stdev_C3M[",(string)stdev_C3M,"]") ;
   return res                                                                                                                       ;
}
/**********************************************************************************************************************************
 * Logic
 * --------
 * Trade Directional:
 *    If Close Outside BB and within Channel 2, Place Directional Order. Only Directional Order.
 * Don't Trade if:
 * 	When Market Closes Outside Channel 2 and outside Bollinger Band, and then Opens inside Bollinger Band, Don't Trade. 
 *
 **********************************************************************************************************************************/
/*int EntrySignal :: Revised_Std_Dev_Ch2()
{
     
   double bb_high    = ind.iBB(1,MODE_UPPER)                                                                 ;
   double bb_high_i0 = ind.iBB(0,MODE_UPPER)                                                                 ;
   double bb_low     = ind.iBB(1,MODE_LOWER)                                                                 ;
   double bb_low_i0  = ind.iBB(0,MODE_LOWER)                                                                 ;
   double stdev_C2P  = ind.iLR(1,C2P)                                                                        ;
   double stdev_C2M  = ind.iLR(1,C2M)                                                                        ; 
   double stdev_C1P  =  ind.iLR(1,C1P)                                                                       ;        
   double stdev_C1M  =  ind.iLR(1,C1M)                                                                       ;        
   int    res        = FAIL                                                                                  ;
   if     (  stdev_C2P == 0.0 || stdev_C2M == 0.0) return FAIL_ERR                                           ;
   if     ( (Close[1] > stdev_C2P &&  Close[1] < bb_high)  &&(Open [0] < bb_high_i0)) res = REVERSAL_SELL    ;
   else if( (Close[1] < stdev_C2M &&  Close[1] > bb_low)   &&(Open [0] > bb_low_i0 )) res = REVERSAL_BUY     ;
   else if( (Close[1] > bb_high)  &&  Close[1] < stdev_C2P ) res = DIRECTIONAL_BUY  ;
   else if( (Close[1] < bb_low)   && (Close[1] > stdev_C2M && Close[1] < stdev_C1P ))res = DIRECTIONAL_SELL ;     
   else if( (Close[1] >  bb_high)  &&(Close[1] < stdev_C2P && Close[1] > stdev_C1P )) res = DIRECTIONAL_BUY  ;
   else if( (Close[1] > stdev_C2P &&  Close[1] > bb_high   && Open [0] > bb_high_i0)||
            (Close[1] < stdev_C2M &&  Close[1] < bb_low    && Open [0] < bb_low_i0 )) res = FAIL             ;
   else                                                                               res = FAIL             ;
   //Comment("Std_Dev_Ch2() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
   return res;
}*/
int EntrySignal :: Revised_Std_Dev_Ch2()
{
     
   double bb_high    = ind.iBB(1,MODE_UPPER)                                                                 ;
   double bb_high_i0 = ind.iBB(0,MODE_UPPER)                                                                 ;
   double bb_low     = ind.iBB(1,MODE_LOWER)                                                                 ;
   double bb_low_i0  = ind.iBB(0,MODE_LOWER)                                                                 ;
   double stdev_C2P  = ind.iLR(1,C2P)                                                                        ;
   double stdev_C2M  = ind.iLR(1,C2M)                                                                        ; 
   double stdev_C1P  =  ind.iLR(1,C1P)                                                                       ;        
   double stdev_C1M  =  ind.iLR(1,C1M)                                                                       ;        
   int    res        = FAIL                                                                                  ;
   if     (  stdev_C2P == 0.0 || stdev_C2M == 0.0) return FAIL_ERR                                           ;
   else if( (Close[1] < bb_low)   && (Close[1] > stdev_C2M && Close[1] < stdev_C1P ))res = DIRECTIONAL_SELL ;     
   else if( (Close[1] >  bb_high)  &&(Close[1] < stdev_C2P && Close[1] > stdev_C1P )) res = DIRECTIONAL_BUY  ;
   else if( (Close[1] > stdev_C2P &&  Close[1] > bb_high   && Open [0] > bb_high_i0)||
            (Close[1] < stdev_C2M &&  Close[1] < bb_low    && Open [0] < bb_low_i0 )) res = FAIL             ;
   else                                                                               res = FAIL             ;
   //Comment("Std_Dev_Ch2() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
   return res;
}
/************************************************************************************************************************************************
 * Logic
 *--------
 * Trade Directional:                                  
 * 	If Close Outside BB and within Channel 2, Place Directional Order. Only Directional Order.        
 *  	When Market Closes Outside Channel 3 and Bollinger Band and then opens again outside Channel 3 and Bollinger Band place Directional Order.
 * Trade Reversal :
 *  	When Market Crosses Channel 3 and Closes inside both Channel 3 and Bollinger Band place Reversal Order.
 *  	When Market Crosses Channel 3 and Close inside Channel 3 but outside Bollinger Band place Reversal Order.         
 *  	When Closes Outside Channel 3 place Reversal Order(Temp Ignore)
 * Don't Trade:
 *	   When Market Closes Outside Channel 2 but inside Bollinger Band, and then Opens inside Bollinger Band.
 *
 ************************************************************************************************************************************************/
/*int  Revised_Std_Dev_Ch3()
{
   double bb_high    =  ind.iBB(1,MODE_UPPER)                                                                ;
   double bb_high_i0 =  ind.iBB(0,MODE_UPPER)                                                                ;
   double bb_low     =  ind.iBB(1,MODE_LOWER)                                                                ;
   double bb_low_i0  =  ind.iBB(0,MODE_LOWER)                                                                ;
   double stdev_C3P  =  ind.iLR(1,C3P)                                                                       ;
   double stdev_C2P  =  ind.iLR(1,C2P)                                                                       ;
   double stdev_C1P  =  ind.iLR(1,C1P)                                                                       ;        
   double stdev_C3M  =  ind.iLR(1,C3M)                                                                       ;
   double stdev_C2M  =  ind.iLR(1,C2M)                                                                       ; 
   double stdev_C1M  =  ind.iLR(1,C1M)                                                                       ;        
   int    res        =  FAIL                                                                                 ;
   if(stdev_C1P == 0.0 || stdev_C1M == 0.0 || stdev_C2P == 0.0 ||stdev_C2M == 0.0 || stdev_C3P==0.0 || stdev_C3M == 0.0)        return FAIL                       ;
   
   if     ((Close[1] >  bb_high)  &&(Close[1] < stdev_C2P && Close[1] > stdev_C1P )) res =  DIRECTIONAL_BUY  ;
   else if((Close[1] <  bb_low )  &&(Close[1] > stdev_C2M && Close[1] < stdev_C1M )) res =  DIRECTIONAL_SELL ;
   else if (Close[1] >  stdev_C3P )                                                  res =  REVERSAL_SELL    ;
   else if (Close[1] <  stdev_C3M )                                                  res =  REVERSAL_BUY     ;
  /* else if (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] < bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] > bb_low )     res =  REVERSAL_BUY     ; 
   else if (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] > bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] < bb_low )     res =  REVERSAL_BUY     ;
  */
  /* else if (High [1] >= stdev_C3P && ( Close[1] < stdev_C3P && Close[1] > stdev_C2P ) && Close[1] < bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && ( Close[1] > stdev_C3M && Close[1] < stdev_C2M ) && Close[1] > bb_low )     res =  REVERSAL_BUY     ; 
   else if (High [1] >= stdev_C3P && ( Close[1] < stdev_C3P && Close[1] > stdev_C2P ) && Close[1] > bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] < bb_low )     res =  REVERSAL_BUY     ;
   // else if (High [1] >= stdev_C2P && Close[1] < stdev_C2P && Close[1] < bb_high)     return FAIL             ;
   //for sell
  // else if (Low  [1] <= stdev_C2M && Close[1] > stdev_C2M && Close[1] > bb_low )     return FAIL             ;
  else if( (Close[1] > stdev_C2P &&  Close[1] > bb_high   && Open [0] > bb_high_i0)||
            (Close[1] < stdev_C2M &&  Close[1] < bb_low    && Open [0] < bb_low_i0 )) res = FAIL             ;   
   Comment("Std_Dev_Ch3() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
   
   return res;
}*/
int EntrySignal :: Revised_Std_Dev_Ch3()
{
   double bb_high    =  ind.iBB(1,MODE_UPPER)                                                                ;
   double bb_high_i0 =  ind.iBB(0,MODE_UPPER)                                                                ;
   double bb_low     =  ind.iBB(1,MODE_LOWER)                                                                ;
   double bb_low_i0  =  ind.iBB(0,MODE_LOWER)                                                                ;
   double stdev_C3P  =  ind.iLR(1,C3P)                                                                       ;
   double stdev_C3P2 =  ind.iLR(2,C3P);
   double stdev_C3P3 =  ind.iLR(3,C3P);   
   double stdev_C2P  =  ind.iLR(1,C2P)                                                                       ;
   double stdev_C2P2 =  ind.iLR(2,C2P);
   double stdev_C2P3 =  ind.iLR(3,C2P);
   double stdev_C1P  =  ind.iLR(1,C1P)                                                                       ;        
   double stdev_C3M  =  ind.iLR(1,C3M)                                                                       ;
   double stdev_C3M2 =  ind.iLR(2,C3M);
   double stdev_C3M3 =  ind.iLR(3,C3M);
   
   double stdev_C2M  =  ind.iLR(1,C2M)                                                                       ; 
   double stdev_C2M2 =  ind.iLR(2,C2M);
   double stdev_C2M3 =  ind.iLR(3,C2M);
   double stdev_C1M  =  ind.iLR(1,C1M)                                                                       ;        
   int    res        =  FAIL                                                                                 ;
   if(stdev_C1P == 0.0 || stdev_C1M == 0.0 || stdev_C2P == 0.0 ||stdev_C2M == 0.0 || stdev_C3P==0.0 || stdev_C3M == 0.0)  return FAIL   ;
   
   if     ((Close[1] >  bb_high)  &&(Close[1] < stdev_C2P && Close[1] > stdev_C1P )) res =  DIRECTIONAL_BUY  ;
   else if((Close[1] <  bb_low )  &&(Close[1] > stdev_C2M && Close[1] < stdev_C1M )) res =  DIRECTIONAL_SELL ;
   if     ((Close[1] >  bb_high)  &&(Close[1] < stdev_C2P && Close[1] > stdev_C1P )) res =  DIRECTIONAL_BUY  ;
   else if (Close[1] <  bb_low )                                                     res =  DIRECTIONAL_SELL ;
   else if (Close[1] >  bb_high)                                                     res =  DIRECTIONAL_BUY  ;
   else if((Close[1] <  bb_low )  &&(Close[1] < stdev_C2M ))                         res =  DIRECTIONAL_SELL ;
   else if (Close[1] >  stdev_C3P && Close[1] > bb_high)                             res =  DIRECTIONAL_BUY  ;
   else if (Close[1] <  stdev_C3M && Close[1] < bb_low )                             res =  DIRECTIONAL_SELL ;
   
   else if (High [1] >= stdev_C3P && ( Close[1] < stdev_C3P && Close[1] > stdev_C2P )) res =  REVERSAL_SELL  ;
   else if (Low  [1] <= stdev_C3M && ( Close[1] > stdev_C3M && Close[1] < stdev_C2M )) res =  REVERSAL_BUY   ;
   else if( (Close[1] > stdev_C2P &&  Close[1] > bb_high   && Open [0] > bb_high_i0)||
            (Close[1] < stdev_C2M &&  Close[1] < bb_low    && Open [0] < bb_low_i0 )) res = FAIL             ;   
   else if (High [3] >= stdev_C3P3&& (Close[3] < stdev_C3P3 && Close[3] > stdev_C2P3) && 
            High [2] >= stdev_C3P2&& (Close[2] < stdev_C3P2 && Close[2] > stdev_C2P2) &&
            High [1] >= stdev_C3P && (Close[1] < stdev_C3P  && Close[1] > stdev_C2P)) res = REVERSAL_SELL    ;
   else if (Low  [3] <= stdev_C3M3 &&(Close[3] > stdev_C3M3 && Close[3] < stdev_C2M3) &&
            Low  [2] <= stdev_C3M2 &&(Close[2] > stdev_C3M2 && Close[2] < stdev_C2M2) &&  
            Low  [1] <= stdev_C3M  &&(Close[1] > stdev_C3M  && Close[1] < stdev_C2M)) res = REVERSAL_BUY     ; 
   Comment("Std_Dev_Ch3() values: \nres[",(string)res,"]\nbb_high[",(string)bb_high,"] bb_high_i0[",(string)bb_high_i0,"]\nbb_low[",(string)bb_low,"] bb_low_i0[",(string)bb_low_i0,"]\nstdev_C2P[",(string)stdev_C2P,"] stdev_C2M[",(string)stdev_C2M,"]") ;
   
   return res;
}
int EntrySignal :: Revised_Directional()
{
   double bb_high    =  ind.iBB(1,MODE_UPPER)                                                                ;
   double bb_high_i0 =  ind.iBB(0,MODE_UPPER)                                                                ;
   double bb_low     =  ind.iBB(1,MODE_LOWER)                                                                ;
   double bb_low_i0  =  ind.iBB(0,MODE_LOWER)                                                                ;
   double stdev_C2P  =  ind.iLR(1,C2P)                                                                       ;
   double stdev_C2M  =  ind.iLR(1,C2M)                                                                       ; 
   double stdev_C3M  =  ind.iLR(1,C3M)                                                                       ;
   double stdev_C3P  =  ind.iLR(1,C3P)                                                                       ;  
   int    res        =  FAIL                                                                                 ;
   if(      (Close[1] > bb_high)  &&  Close[1] < stdev_C2P ) res = DIRECTIONAL_BUY                           ;
   else if( (Close[1] < bb_low)   &&  Close[1] > stdev_C2M ) res = DIRECTIONAL_SELL                          ; 
   else if  (Close[1] > stdev_C3P &&  Close[1] > bb_high)    res = DIRECTIONAL_BUY                           ;
   else if  (Close[1] < stdev_C3M &&  Close[1] < bb_low )    res = DIRECTIONAL_SELL                          ;
   
   return res                                                                                                ;
}
int EntrySignal :: Test_Directional()
{
   int res                 =  FAIL                 ;
   double bb_high          =  ind.iBB(1,MODE_UPPER);
   double bb_low           =  ind.iBB(1,MODE_LOWER);
   //-----------------------------------------
   
   if(Close[1]>bb_high)     res = DIRECTIONAL_BUY  ;
   else if(Close[1]<bb_low) res =DIRECTIONAL_SELL  ;
   return res;
}
int EntrySignal:: Test_Reversal()
{
   int res = FAIL;
   double bb_high          =  ind.iBB(1,MODE_UPPER);
   double bb_low           =  ind.iBB(1,MODE_LOWER);
   double bb_high2         =  ind.iBB(2,MODE_UPPER);
   double bb_low2          =  ind.iBB(2,MODE_LOWER);
   double stdev_C2P        =  ind.iLR(1,C2P)       ;
   double stdev_C2M        =  ind.iLR(1,C2M)       ; 
   double stdev_C3M        =  ind.iLR(1,C3M)       ;
   double stdev_C3P        =  ind.iLR(1,C3P)       ;
   double stdev_C2P2       =  ind.iLR(2,C2P)       ;
   double stdev_C2M2       =  ind.iLR(2,C2M)       ; 
   double stdev_C3M2       =  ind.iLR(2,C3M)       ;
   double stdev_C3P2       =  ind.iLR(2,C3P)       ;  
   //--------------------------------------
   
  if(High[1]>=stdev_C3P && Close[1]<stdev_C2P)                         res = REVERSAL_SELL;
  else if(Low[1]<=stdev_C3M && Close[1]>stdev_C2M)                     res = REVERSAL_BUY ;
  else if(Close[2]>stdev_C3P2 && Open[1]>stdev_C3P && Open[1]<bb_high) res = REVERSAL_SELL; 
  else if(Close[2]<stdev_C3M2 && Open[1]<stdev_C3M && Open[1]>bb_low)  res = REVERSAL_BUY ; 
   
   
   return res;
}
int EntrySignal :: Revised_Reversal()
{
   double bb_high    =  ind.iBB(1,MODE_UPPER)                                                                ;
   double bb_high_i0 =  ind.iBB(0,MODE_UPPER)                                                                ;
   double bb_low     =  ind.iBB(1,MODE_LOWER)                                                                ;
   double bb_low_i0  =  ind.iBB(0,MODE_LOWER)                                                                ;
   double stdev_C3P  =  ind.iLR(1,C3P)                                                                       ;
   double stdev_C3P2 =  ind.iLR(2,C3P);
   double stdev_C3P3 =  ind.iLR(3,C3P);   
   double stdev_C2P  =  ind.iLR(1,C2P)                                                                       ;
   double stdev_C2P2 =  ind.iLR(2,C2P);
   double stdev_C2P3 =  ind.iLR(3,C2P);
   double stdev_C3M  =  ind.iLR(1,C3M)                                                                       ;
   double stdev_C3M2 =  ind.iLR(2,C3M);
   double stdev_C3M3 =  ind.iLR(3,C3M);
   double stdev_C2M  =  ind.iLR(1,C2M)                                                                       ; 
   double stdev_C2M2 =  ind.iLR(2,C2M);
   double stdev_C2M3 =  ind.iLR(3,C2M);
   int    res        =  FAIL                                                                                 ;          
   if      (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] < bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] > bb_low )     res =  REVERSAL_BUY     ; 
   else if (High [1] >= stdev_C3P && Close[1] < stdev_C3P && Close[1] > bb_high)     res =  REVERSAL_SELL    ;
   else if (Low  [1] <= stdev_C3M && Close[1] > stdev_C3M && Close[1] < bb_low )     res =  REVERSAL_BUY     ;                                                                              
   else if (High [3] >= stdev_C3P3&&(Close[3] < stdev_C3P3&& Close[3] > stdev_C2P3) && 
            High [2] >= stdev_C3P2&&(Close[2] < stdev_C3P2&& Close[2] > stdev_C2P2) &&
            High [1] >= stdev_C3P &&(Close[1] < stdev_C3P && Close[1] > stdev_C2P)) res = REVERSAL_SELL      ;
   else if (Low  [3] <= stdev_C3M3&&(Close[3] > stdev_C3M3&& Close[3] < stdev_C2M3) &&
            Low  [2] <= stdev_C3M2&&(Close[2] > stdev_C3M2&& Close[2] < stdev_C2M2) &&  
            Low  [1] <= stdev_C3M &&(Close[1] > stdev_C3M && Close[1] < stdev_C2M)) res = REVERSAL_BUY       ; 
   res = Pattern_Breakin()                                                                                   ;
   
   return res                                                                                                ;
}
int EntrySignal :: isSignalCandle(int type, int& _ccode)
{   
   int res     = FAIL                                  ;
   int res2    = FAIL                                  ;
   string rest = ""                                    ;
   switch(type)
   {
      case BOTH        :
         res  = Std_Dev_Ch3()                          ;
         res2 = Std_Dev_Ch2()                          ;
         if(res != FAIL){
            rest = ""+(string)ST_DEV_C3+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 != FAIL){
            rest = ""+(string)ST_DEV_C2+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         break                                         ;
      case DIRECTIONAL :
         res  = Std_Dev_Ch3()                          ;
         res2 = Std_Dev_Ch2()                          ;
         if(res == DIRECTIONAL_BUY || res == DIRECTIONAL_SELL){
            rest = ""+(string)ST_DEV_C3+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 == DIRECTIONAL_BUY || res2 == DIRECTIONAL_SELL){
            rest = ""+(string)ST_DEV_C2+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         break                                         ;
      case REVERSAL    :
         res  = Std_Dev_Ch3()                          ;
         res2 = Std_Dev_Ch2()                          ;
         if(res == REVERSAL_BUY || res == REVERSAL_SELL){
            rest = ""+(string)ST_DEV_C3+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 == REVERSAL_BUY || res2 == REVERSAL_SELL){
            rest = ""+(string)ST_DEV_C2+""+(string)res2;
            _ccode = (int) rest                        ;
         }
         break                                         ;
      case ST_DEV_C2   :
         res = Std_Dev_Ch2()                           ;
         rest=""+(string)ST_DEV_C2+""+(string)res      ;
         _ccode = (int)rest                            ;
        // res = (int) rest;
         break                                         ;
      case ST_DEV_C3   :
         res = Std_Dev_Ch3()                           ;
         rest=""+(string)ST_DEV_C3+""+(string)res      ;
         _ccode = (int)rest                            ;
         //res = (int)rest;
         break                                         ;
         
   }
   //res= (int)ST_DEV_C2+""+res;
   //Print("res[",res,"]");
   return res                                          ;
}      
int EntrySignal :: isSignalCandleRev(int type, int& _ccode)
{   
   int res  = FAIL                                     ;
   int res2 = FAIL                                     ;
   int res3 = FAIL                                     ;
   string rest=""                                      ;
   switch(type)
   {
      case BOTH        :
         res  = Revised_Std_Dev_Ch3()                  ;
         res2 = Revised_Std_Dev_Ch2()                  ;
         res3 = Pattern_Breakin()                      ;
         if(res != FAIL){
            rest = ""+(string)ST_DEV_C3+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 != FAIL){
            rest = ""+(string)ST_DEV_C2+""+(string)res2;
            _ccode = (int) rest                        ;
            res = res2                                 ;
         }
         else if(res3 != FAIL){
            rest = ""+(string)BREAKIN+""+(string)res3  ;
            _ccode = (int) rest                        ;
            res = res3                                 ;
         }
         break                                         ;
      case DIRECTIONAL :        
         res  = Revised_Directional()                  ;
         rest=""+(string)ST_DEV_C2+""+(string)res      ;
         _ccode = (int)rest                            ;
         break                                         ;
      case REVERSAL    :
         res  = Revised_Std_Dev_Ch3()                  ;
         res2 = Revised_Std_Dev_Ch2()                  ;
         res3 = Pattern_Breakin()                      ;
         if(res == REVERSAL_BUY || res == REVERSAL_SELL){
            rest = ""+(string)ST_DEV_C3+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 == REVERSAL_BUY || res2 == REVERSAL_SELL){
            rest = ""+(string)ST_DEV_C2+""+(string)res2;
            _ccode = (int) rest                        ;
            res    = res2                              ;
         }
         else if(res3 != FAIL){
            rest = ""+(string)BREAKIN+""+(string)res   ;
            _ccode = (int) rest                        ;
            res = res3                                 ;
         }
         else res = FAIL                               ;
         break;
      case ST_DEV_C2   :
         res = Revised_Std_Dev_Ch2()                   ;
         rest=""+(string)ST_DEV_C2+""+(string)res      ;
         _ccode = (int)rest                            ;
        // res = (int) rest;
         break                                         ;
      case ST_DEV_C3   :
         res = Revised_Std_Dev_Ch3()                   ;
         rest=""+(string)ST_DEV_C3+""+(string)res      ;
         _ccode = (int)rest                            ;
         //res = (int)rest;
         break                                         ;
      case BREAKIN     :
         res = Pattern_Breakin()                      ;
         if(res == REVERSAL_BUY || res == REVERSAL_SELL){
            rest = ""+(string)BREAKIN+""+(string)res   ;
            _ccode = (int) rest                        ;
            Print("Res[",res," _Ccode[",_ccode,"]")  ;
         }
         break                                         ;
         
   }
  // Comment(res);
   //res= (int)ST_DEV_C2+""+res;
   //Print("res[",res,"]");
   return res                                          ;
}

int EntrySignal :: isSignalCandleTest(int type, int& _ccode)
{   
   int res  = FAIL                                     ;
   int res2 = FAIL                                     ;
   int res3 = FAIL                                     ;
   string rest=""                                      ;
   switch(type)
   {
      case BOTH        :
         res  = Test_Directional()                     ;
         res2 = Test_Reversal()                        ;
         res3 = Pattern_Breakin()                      ;
         if(res != FAIL){
            rest = ""+(string)DIRECTIONAL+""+(string)res ;
            _ccode = (int) rest                        ;
         }
         else if(res2 != FAIL){
            rest = ""+(string)REVERSAL+""+(string)res2;
            _ccode = (int) rest                        ;
            res = res2                                 ;
         }
         else if(res3 != FAIL){
            rest = ""+(string)BREAKIN+""+(string)res3  ;
            _ccode = (int) rest                        ;
            res = res3                                 ;
         }
         break                                         ;
      case DIRECTIONAL :
         res  = Test_Directional()                     ;
         _ccode = (int)rest                            ;
         break                                         ;
      case REVERSAL    :
         res  = Test_Reversal()                        ;
         if(res == REVERSAL_BUY || res == REVERSAL_SELL){
            _ccode = (int) rest                        ;
         }
         else res = FAIL                               ;
         break;
      case ST_DEV_C2   :
         break                                         ;
      case ST_DEV_C3   :
         break                                         ;
      case BREAKIN     :
         res = Pattern_Breakin()                      ;
         if(res == REVERSAL_BUY || res == REVERSAL_SELL){
            rest = ""+(string)BREAKIN+""+(string)res   ;
            _ccode = (int) rest                        ;
            Print("Res[",res," _Ccode[",_ccode,"]")  ;
         }
         break                                         ;
         
   }
  // Comment(res);
   //res= (int)ST_DEV_C2+""+res;
   //Print("res[",res,"]");
   return res                                          ;
} 
 
int  EntrySignal::OrderOperationCode(int magic){
    int total = OrdersTotal()                          ;
    int opCode = FAIL                                  ;
    if(total<1)return FAIL                             ;
    for(int i=0; i<total;i++)
    {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         if((OrderMagicNumber()==magic ) && (OrderSymbol()==Symbol()) )
         {
            opCode = (int) OrderComment()              ;
         }
       }
     }
    return opCode                                      ;
}
bool EntrySignal::isOrder(int &ticket ,int magic, int opcode){
   
   int total = OrdersTotal()                           ;
   if(total<1)return false                             ;
   for(int i=0; i<total;i++)
   {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)==true)
      {
         if((OrderMagicNumber()==magic) && OrderSymbol()==Symbol())
         {
            if(StringFind(OrderComment(),(string)opcode,0)!=-1)
            {
               ticket = OrderTicket()                  ;   
               return true                             ;
            }
         }
       }
    }
    return false                                       ;

}      