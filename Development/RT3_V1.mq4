//+------------------------------------------------------------------+
//|                                                       RT3_V1.mq4 |
//|                              Zobad Mahmood, Mobile +923009326947 |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Zobad Mahmood, Mobile +923009326947"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict

//+------------------------------------------------------------------+
//| Global Varaiables for Parameters                                 |
//+------------------------------------------------------------------+ 
//+------------------------------------------------------------------+
#define nd NormalizeDouble
#define d  Digits()
//+------------------------------------------------------------------+
enum Breakeven
  {
   FIXED_BREAKEVEN,
   JUMP_BREAKEVEN
  };
enum n
 {
   ms=1/*start*/,
   mc=0/*stop*/
 };
enum n1
 {
   m1=1/*atr*/ /*,
   m2 = 2/*% from balance*/,
   m3=3/*fix*/,
 };

// // order
extern string Set0="-------Old Setting--------";
extern double lot=1; // lot
extern n1     tpv      = 1;   // take-profit-volatility
extern double tp       = 3.0; // take-profit-fix
extern n      tpv1     = 1;   // take-profit % from balance volatility
extern double tp1      = 3.0; // take-profit % from balance fixed
extern double sl       = 1.5; // stop-loss

extern bool   UseATR2orders=true;
extern double lot2=1; // lot 2
extern n1     tpv2      = 1;   // take-profit 2- volatility based
extern double tp2       = 3.0; // take-profit 2- fixed
extern n      tpv12     = 1;   // take-profit % from balance 2
extern double tp12      = 3.0; // take-profit % from balance 2
extern double sl2=1.5; // stop-loss 2

extern int    slippage = 0; // Slippage
extern int    magic       = 1; // magic number
extern string comment="robot RT"; // comment
//+------------------------------------------------------+
extern string Set1="-------NewRules--------";
bool   NewRule=true;
extern int    StopLoss=0;
extern int    TakeProfit=0;
extern string Set2="-------Trailing stop Setting-------";
extern bool   TrailingStopEnable=true;
extern int    TrailStep=10;
extern string Set6="-----Break Even----";
extern bool UseBreakEven=true;
extern Breakeven BreakEvenType=JUMP_BREAKEVEN;
extern int BreakEvenPips=13;
extern string Set5="-----Money Managment----";
extern bool   MoneyManagmentEnable=true;
extern n      risk     = 0; // risk
extern double riskz    = 2; // risk in %
extern n      risk2     = 0; // risk 2
extern double riskz2    = 2; // risk in % 2
extern bool   UseATRMinMAx=true;
extern double ATRMin=0.0001;
extern double ATRMax=0.0026;

extern bool   TrailingStopEnable2=true;
extern int    TrailStep2=10;
extern bool UseBreakEven2=true;
extern Breakeven BreakEvenType2=JUMP_BREAKEVEN;
extern int BreakEvenPips2=13;
extern string Set7="------SecondEntry_Setting----";
extern bool   SecondEntryRule=true;
extern bool   AtrFilter_SecondEntry=true;
//+-------------------------------------+
int      MaxSlippage=5;
int      Trend=2;
datetime LastTime;
string   Orders[2];
double point;
int digits,Q;
extern string Set3="-------Bolinger Band Setting-------";
extern ENUM_TIMEFRAMES    bb_tf        = PERIOD_H4;   // bolinger::time-frame
extern int                bb_period    = 20;          // bolinger::period 
extern double             bb_deviation = 2;           // bolinger::deviation
int                bb_shift=0;           // bolinger::shift
extern ENUM_APPLIED_PRICE bb_price=PRICE_CLOSE; // bolinger::price
extern ENUM_TIMEFRAMES    atr_tf       = PERIOD_H4;   // atr::time-frame
extern int                atr_period   = 20;          // atr::period

                                                      // global variables
 int                ArrSize=3;
 int                distBuy=20;
color              ArrColorBuy=clrBlue;
 int                distSell=20;
 color              ArrColorSell=clrRed;

//+------------------------------------------------------------------+
datetime SecondBuyTime;
datetime SecondSellTime;
//+------------------------------------------------------------------+
datetime dt=0;
bool     SecondSell=false;
bool     SecondBuy=false;
double   HighBBand=0;
double   LowBBand=0;

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
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Pattern Check function                                           |
//+------------------------------------------------------------------+
bool PatternCheck()
{
   return false;
}
bool PlaceDoubleOrder()
{
   return false;
}
bool BuySignalCheck()
{
   return false
}
bool SellSignalCheck()
{
   return false
}
bool PlaceOrder()
{
   return false;
}