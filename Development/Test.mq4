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


EntrySignal    *algo ;
MoneyManagement *mm;

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
input LotType          lotType            = MANUAL    ;             //Lot Type
input double           _risk              = 2.0       ;             //%Available Balance::Lot
input double           LotSize            = 1.0       ;             //Position::Lot Size(Manual)
extern string          order1="-------Order--------";             //Order 1 Settings
bool                   order1Open         =  false    ; 
extern Strat_type      _strat_type        = ST_DEV_C2 ;             //Strategy:: Type      
input bool             useStrategy1       = true      ;             //Strategy::Use Strategy
input Take_Profit_Type TP_Type            = VOLATILITY;             //Reversal TP:: Type
input Take_Profit_Type SL_Type            = VOLATILITY;             //Reversal SL:: Type
input double           TP_Value           = 25.0      ;             //Reversal TP:: Volatility/Fixed(Points)
input double           SL_Value           = 12.0      ;             //Reversal SL:: Volatility/Fixed(Points)
input Take_Profit_Type TP_Type1            = VOLATILITY;             //Directional TP:: Type
input Take_Profit_Type SL_Type1            = VOLATILITY;             //Directional SL:: Type
input double           TP_Value1           = 25.0      ;             //Directional TP:: Volatility/Fixed(Points)
input double           SL_Value1           = 12.0      ;             //Directional SL:: Volatility/Fixed(Points)

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
       

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   algo = new EntrySignal();
   mm   = new MoneyManagement();
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
   delete(mm);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
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
           bool res = Revised_Buy(_strat_type,tcode);
         }
         else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {     
           Print("Sell Alert");
           bool res = Revised_Sell(_strat_type,tcode);
         }         
      }
   }
   else if(useLegacy == false)
   {
      if(algo.OrderOperationCode(Magic_Number)!=FAIL && useTrail==true)
      {
         mm.TrailOrder(_trail_type1,_trailBy,Magic_Number);
      }   
      if(IsNewBar())
      {
         int ccode = FAIL;
         int tcode = FAIL;         
         tcode = algo.isSignalCandleRev(_strat_type,ccode);   
         if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {           
           Print("Buy Alert");
           bool res = Revised_Buy(_strat_type,tcode);
         }
         else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
         {     
           Print("Sell Alert");
           bool res = Revised_Sell(_strat_type,tcode);
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
   string comment = (string)strat+""+(string)rt_Code;
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
   string comment = (string)strat+""+(string)rt_Code;
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