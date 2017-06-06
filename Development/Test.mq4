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
input int              Magic_Number = 1;                 //Magic Number 
extern string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
input bool             useConsecutive =false;            //Use Consecutive Loss
input int              noConsqLossAllowed=3;             //Consecutive Losses Allowed
input double           percentReduction=5;               //Lot Size Percent Reduction
extern string          setLot="-------Lot Setting---------------------";
input LotType          lotType=MANUAL;                  //Lot Type
input double           _risk=2.0;                        //%Available Balance::Lot

extern string          order1="-------Order_1--------";  //Order 1 Settings
bool                   order1Open=false;
extern string          Strat_Name="Break Out Inverse";   //Strategy Name
extern Strat_type      _strat_type = ST_DEV_C2      ;     //Strategy Type      
input bool             useStrategy1=true;                //Use Strategy
input double           LotSize=1.0;                      //Lot Size
input Take_Profit_Type TP_Type= VOLATILITY;              //Take Profit Type
input Take_Profit_Type SL_Type= VOLATILITY;              //Stop Loss Type
input double           TP_Value=25.0;                    //TP Volatility/Fixed(Points)
input double           SL_Value=12.0;                    //SL Volatility/Fixed(Points)
input int              _timegap1=31;                     //Order 1 time gap(in mins)
input bool             _trail1 = false;                  //Use Trailing Stop For Order 1
input int              _trailPoint1;                     //When to Trail
input bool             _breakEven1 = false;              //Use jump to breakeven
input int              _whenJump1=25;                    //When to Jump to Breakeven
input int              _jumpBy1=6;                       //Points to add after the Breakeven Jump
input bool             _use_risk_candle1=false;           //Use Risk Management
input int              _risk_candle1=4;                  //candles to Read for Risk Management
double                 _highestStop1;
double                 _lowestStop1;
input bool             _gapCloseCheck1=false;             //Use Close Candle after a certain time gap
input int              _whenClose1= 50;                  //Time gap in minutes
       

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
      int ccode = 0;
      int tcode = 0;
      
   if(IsNewBar())
   {
       tcode     = algo.isSignalCandle(3,ccode);   
      if((tcode == DIRECTIONAL_BUY||tcode==REVERSAL_BUY)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
      {
        Print("Buy Alert");
        bool res= Buy(_strat_type,tcode);
      }
      else if((tcode == DIRECTIONAL_SELL||tcode==REVERSAL_SELL)&&(algo.OrderOperationCode(Magic_Number)==FAIL))
      {
         Print("Sell Alert");
         bool res = Sell(_strat_type,tcode);
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