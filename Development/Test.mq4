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


EntrySignal     *algo ;
MoneyManagement *mm   ;
Indicators      *ind  ;

enum LotType
{
   MANUAL = 0,
   AUTO    = 1,
};
enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
   MID_BB=2
};
enum _type
{
   FIX    = 0,      //Fixed
   VOLAT  = 1       //Volatility
};
input int              Magic_Number       = 1         ;             //Magic Number 
input bool             useLegacy          = false     ;             //Use Legacy Entry Signal
extern string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
input bool             useConsecutive     = false     ;             //Use Consecutive Loss
input int              noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
input double           percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot="-------Lot Setting---------------------";
input LotType          lotType            = AUTO      ;             //Lot Type
input double           _risk              = 2.0       ;             //%Available Balance::Lot
input double           LotSize            = 0.5       ;             //Position::Lot Size(Manual)
extern string          order1="-------Order--------"  ;             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_type      _strat_type        = DIRECTIONAL ;             //Strategy:: Type      
input bool             useStrategy1       = true      ;             //Strategy::Use Strategy
extern string          reversalSet="-------Reversal Strategy TP/SL--------";             //Reversal TP and SL Settings

input Take_Profit_Type TP_Type            = VOLATILITY;             //Reversal TP:: Type
input Take_Profit_Type SL_Type            = VOLATILITY;             //Reversal SL:: Type
input double           TP_Value           =  4.5      ;             //Reversal TP:: Volatility/Fixed(Points)
input double           SL_Value           =  1.5      ;             //Reversal SL:: Volatility/Fixed(Points)

extern string          directionSet="-------Directional Strategy TP/SL--------";             //Directional TP/SL Settings
input Take_Profit_Type TP_Type1           = VOLATILITY;             //Directional TP:: Type
input Take_Profit_Type SL_Type1           = VOLATILITY;             //Directional SL:: Type
input double           TP_Value1          =  3.5      ;             //Directional TP:: Volatility/Fixed(Points)
input double           SL_Value1          =  1.5      ;             //Directional SL:: Volatility/Fixed(Points)

input int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
input bool             useTrail           = false     ;             //Trail::Use Trail
input _type            _trail_type1       = FIX       ;             //Trail::Type 
input double           _trailBy           = 40        ;             //Trail Volat/Fixed::Trail by
input bool             _breakEven1        = false     ;             //Breakeven::Use jump to breakeven
input int              _whenJump1         = 25        ;             //Breakeven::When to Jump
input int              _jumpBy1           = 6         ;             //Breakeven::Points to add after Jump
input bool             _use_risk_candle1  = false     ;             //Risk Management:: Use Risk Management
input int              _risk_candle1      = 4         ;             //Risk Management::Number of Candles to read
double                 _highestStop1                  ;
double                 _lowestStop1                   ;
input bool             _gapCloseCheck1    = false     ;             //Close Candle::Use time gap
input int              _whenClose1        = 50        ;             //Close Candel::Time gap in minutes
bool                   LR_Flag            = false     ;      

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   algo = new EntrySignal()    ;
   mm   = new MoneyManagement();
   ind   = new Indicators()    ;
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
   delete(mm)  ;
   delete(ind) ;
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(LR_Flag ==false)
   {
      if(CheckLR()==true)LR_Flag =true;
   }
   if(useLegacy == true)
   {  
      if(algo.OrderOperationCode(Magic_Number)!=FAIL && useTrail==true)
      {
         mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);
      }   
      if(IsNewBar())
      {
         int ccode = FAIL;
         int tcode = FAIL;
         tcode = algo.isSignalCandle(_strat_type,ccode);
         if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {           
           Print("Buy Alert");
           bool res = Revised_Buy(ccode,tcode);
         }
         else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {     
           Print("Sell Alert");
           bool res = Revised_Sell(ccode,tcode);
         }         
      }
   }
   //------------------------------------------------------------
   else if(useLegacy == false)
   {
      int comment =algo.OrderOperationCode(Magic_Number);
      if(comment!=FAIL)
      {
         if(StringFind(comment,(string)DIRECTIONAL_BUY,1)!=0 || StringFind(comment,(string)DIRECTIONAL_SELL,1))
         {mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);}
         else if(StringFind(comment,(string)REVERSAL_BUY,1)!=0 || StringFind(comment,(string)REVERSAL_SELL,1))
         {mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);}
      }   
      if(IsNewBar())
      {
         int ccode = FAIL;
         int tcode = FAIL;         
         tcode = algo.isSignalCandleRev(_strat_type,ccode);   
         if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         { 
            if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false)&& tcode == REVERSAL_BUY){             
               Print("Buy Alert Direction Code[",tcode,"]")                   ;
               Print("Buy Alert C Code[",ccode,"]")                           ;
               bool res = Revised_Buy(ccode,tcode)                      ;
               LR_Flag  = false                                               ;
            }
            else if(tcode == DIRECTIONAL_BUY)
            {
               bool res = Revised_Buy(ccode,tcode)                      ;
            }
         }
         else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {     
            if((LR_Flag == true || mm.isConsequtive(ccode,Magic_Number)==false) && tcode == REVERSAL_SELL){
               Print("Sell Alert Direction Code[",tcode,"]")                  ;
               Print("Sell Alert C Code[",ccode,"]")                          ;
               bool res = Revised_Sell(ccode,tcode)                     ;
               LR_Flag  = false                                               ;
            }
            else if(tcode == DIRECTIONAL_SELL)
            {
               bool res = Revised_Sell(ccode,tcode)                      ;
            }
         }         
      }
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
bool Buy(int strat,int rt_Code)
{
    string comment = (string)strat+""+(string)rt_Code;
    double tp =0.0, sl =0.0;
    double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
    mm.PlaceOrder(OP_BUY,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);
    return false;
}
bool Sell(int strat,int rt_Code)
{
    string comment = (string)strat+""+(string)rt_Code;
    double tp =0.0, sl =0.0;
    double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
    mm.PlaceOrder(OP_SELL,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);
   return false;
}
bool Revised_Buy(int strat, int rt_Code)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
   double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     (rt_Code == DIRECTIONAL_BUY)
   {       
      mm.PlaceOrder(OP_BUY,lot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
   }        
   else if(rt_Code == REVERSAL_BUY)
   {        
      mm.PlaceOrder(OP_BUY,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);   
   }         
   return false;
}
bool Revised_Sell(int strat, int rt_Code)
{
   string comment = (string)strat;
   double tp =0.0, sl =0.0;
   double lot = mm.CalculatePositionSize(lotType,LotSize,_risk);
   if     (rt_Code == DIRECTIONAL_SELL)
   {        
      mm.PlaceOrder(OP_SELL,lot,TP_Type1,TP_Value1,SL_Type1,SL_Value1,Magic_Number,(int)comment);
   }        
   else if(rt_Code == REVERSAL_SELL)
   {
      mm.PlaceOrder(OP_SELL,lot,TP_Type,TP_Value,SL_Type,SL_Value,Magic_Number,(int)comment);   
   }
   return false;
}
int PreviousOrder()
{
   if(OrdersTotal()>0)
   {
      if(OrderSelect(0,SELECT_BY_POS,MODE_TRADES)>0)
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
         {
            return OrderType();
         }
      }
   }
   else{
      if(OrderSelect(0,SELECT_BY_POS,MODE_HISTORY)>0)
      {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==Magic_Number)
         {
            return OrderType();
         }
      }   
   }
   return FAIL;
}
bool CheckLR()
{
   double lr  = ind.iLR(1,LR)      ;
   int opcode = PreviousOrder()    ;
   if     (opcode == OP_BUY )   
   {
      if(Close[1]>lr) return true  ;
      else            return false ;      
   }
   else if(opcode == OP_SELL)
   {
      if(Close[1]<lr) return true  ;   
      else            return false ;
   }
   return                     false;
}