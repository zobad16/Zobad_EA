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
enum be
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
extern string             Set0="-------Old Setting--------";
extern double             lot=1; // lot
extern n1                 tpv      = 1;   // take-profit
extern double             tp       = 3.0; // take-profit
extern n                  tpv1     = 1;   // take-profit % from balance
extern double             tp1      = 3.0; // take-profit % from balance
extern double             sl       = 1.5; // stop-loss

extern bool               UseATR2orders=true;
extern double             lot2=1; // lot 2
extern n1                 tpv2      = 1;   // take-profit 2 
extern double             tp2       = 3.0; // take-profit 2
extern n                  tpv12     = 1;   // take-profit % from balance 2
extern double             tp12      = 3.0; // take-profit % from balance 2
extern double             sl2=1.5; // stop-loss 2

extern int                slippage = 0; // проскальзывание
extern int                magic       = 1; // magic number
extern string             comment="robot RT"; // comment
//+------------------------------------------------------+
extern string             Set1="-------NewRules--------";
bool   NewRule       =    true;
extern int                StopLoss=0;
extern int                TakeProfit=0;
extern string             Set2="-------Trailing stop Setting-------";
extern bool               TrailingStopEnable=true;
extern int                TrailStep=10;
extern string             Set6="-----Break Even----";
extern bool               UseBreakEven=true;
extern be                 BreakEvenType=JUMP_BREAKEVEN;
extern int                BreakEvenPips=13;
extern string             Set5="-----Money Managment----";
extern bool               MoneyManagmentEnable=true;
extern n                  risk     = 0; // risk
extern double             riskz    = 2; // risk in %
extern n                  risk2     = 0; // risk 2
extern double             riskz2    = 2; // risk in % 2
extern bool               UseATRMinMAx=true;
extern double             ATRMin=0.0001;
extern double             ATRMax=0.0026;

extern bool               TrailingStopEnable2=true;
extern int                TrailStep2=10;
extern bool               UseBreakEven2=true;
extern be                 BreakEvenType2=JUMP_BREAKEVEN;
extern int                BreakEvenPips2=13;
extern string             Set7="------SecondEntry_Setting----";
extern bool               SecondEntryRule=true;
extern bool               AtrFilter_SecondEntry=true;
//+-------------------------------------+
int                       MaxSlippage=5;
int                       Trend=2;
datetime                  LastTime;
string                    Orders[2];
// other
double                    point;
int                       digits,Q;
// global variables for parameters from indicators
extern string             Set3="-------Bolinger Band Setting-------";
extern ENUM_TIMEFRAMES    bb_tf        = PERIOD_H4;   // bolinger::time-fream
extern int                bb_period    = 20;          // bolinger::period 
extern double             bb_deviation = 2;           // bolinger::deviation
int                       bb_shift=0;           // bolinger::shift
extern ENUM_APPLIED_PRICE bb_price=PRICE_CLOSE; // bolinger::price

extern ENUM_TIMEFRAMES    atr_tf       = PERIOD_H4;   // atr::time-fream
extern int                atr_period   = 20;          // atr::period

                                                      // global variables
 int                      ArrSize=3;
 int                      distBuy=20;
color                     ArrColorBuy=clrBlue;
 int                      distSell=20;
 color                    ArrColorSell=clrRed;
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
   if(!IsTesting())
     {
      Orders[0]="Order_1_"+Symbol()+"_"+IntegerToString(magic);
      Orders[1]="Order_2_"+Symbol()+"_"+IntegerToString(magic);
     }
   else
     {
      Orders[0]="Order_1_"+Symbol();
      Orders[1]="Order_2_"+Symbol();
     }
   if(Digits<4)
     {
      point=0.01;
      digits=2;
     }
   else
     {
      point=0.0001;
      digits=4;
     }

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---
   GlobalVariableDel(Orders[0]);
   GlobalVariableDel(Orders[1]);
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(UseATRMinMAx)
     {

      if(dt==Time[0])return;
      double _atr=NormalizeDouble(iATR(Symbol(),atr_tf,atr_period,0),Digits);
      if(TotalOrder(OP_BUY)+TotalOrder(OP_SELL)==0 && (_atr<ATRMin || _atr>ATRMax))
         {
            dt=Time[0];
            return;
         }
      f();
      if(LastTime!=Time[1])
        {
         LastTime=Time[1];
         Trend=2;
         NewRuleFun();
         GetOrder();
        }
      if(TrailingStopEnable==true && !UseATR2orders)
         TrailingStop(-1);
      if(TrailingStopEnable==true && UseATR2orders)
         TrailingStop((int)(GlobalVariableGet(Orders[0])));
      if(TrailingStopEnable2==true && UseATR2orders)
         TrailingStop2((int)(GlobalVariableGet(Orders[1])));
      if(UseBreakEven==true && !UseATR2orders)
         sub_trailing(-1);
      if(UseBreakEven==true && UseATR2orders)
         sub_trailing((int)(GlobalVariableGet(Orders[0])));
      if(UseBreakEven2==true && UseATR2orders)
         sub_trailing2((int)(GlobalVariableGet(Orders[1])));
       
     }
  }
  void f()
  {

   if(timer<TimeCurrent()) 
   {
      return;
   }
   static int auth_order=0; // authorization order//ao
   static int aab1 = Bid>=iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_UPPER,1)?0:1;//aab1
   static int aas1 = Bid<=iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_LOWER,1)?0:1;//aas1
   static int aab2 = 1;//aab2
   static int aas2 = 1;//aas2
   static int tb = 0;//tb
   static int ts = 0;//ts
   double bb_up  = iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_UPPER,1);
   double bb_dwn = iBands(Symbol(),bb_tf,bb_period,bb_deviation,bb_shift,bb_price,MODE_LOWER,1);
   if(aas1 && aas2 && Bid>bb_up)
     {
      aas1=0;
      ao=2;
      aab2 = 1;
      aas2 = 0;
     }
   else aas1=1;

   if(aab1 && aab2 && Bid<=bb_dwn)
     {
      aab1=0;
      ao=1;
      aas2 = 1;
      aab2 = 0;
     }
   else aab1=1;
   int t=0;
   if(NumberOfPositions(Symbol(),-1)==0)
   {
        if(NewRule==false)
         if(ao==1 && order_start_b(t))
           {
            if(
               ObjectFind(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]))<0
               )
              {
               ObjectCreate(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJ_ARROW_UP,0,Time[1],Low[1]-distBuy*Point);
               ObjectSetInteger(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_COLOR,ArrColorBuy);
               ObjectSet(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_WIDTH,ArrSize);
              }
               tb=t;
               ao=0;
           }
   
   
        if(NewRule==false)
         if(ao==2 && order_start_s(t))
           {
               if(
                  ObjectFind(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]))<0
                  )
                 {
                  ObjectCreate(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJ_ARROW_DOWN,0,Time[1],High[1]+distSell*Point);
                  ObjectSetInteger(0,WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_COLOR,ArrColorSell);
                  ObjectSet(WindowExpertName()+IntegerToString(mg)+TimeToStr(Time[1]),OBJPROP_WIDTH,ArrSize);
                 }
                  ts=t;
                  ao=0;
           }
   }

   if(tb && OrderSelect(tb,SELECT_BY_TICKET))
     {
      if(OrderCloseTime())
        {

         if(OrderComment()==comment+"[tp]") aab2=1;

         tb=0;

        }
     }

   if(ts && OrderSelect(ts,SELECT_BY_TICKET))
     {
      if(OrderCloseTime())
        {
         if(OrderComment()==comment+"[tp]") aas2=1;
         ts=0;
        }
     }
   static int td[100];
   for(int c=OrdersTotal()-1; c>=0; c--)
     {
      if(OrderSelect(c,SELECT_BY_POS,MODE_TRADES))
        {
         if(OrderSymbol()==Symbol() && OrderMagicNumber()==mg && OrderComment()==comment)
           {
            if(OrderProfit()>AccountBalance()/100*tp1)
              {
               Print("order #"+IntegerToString(OrderTicket())+" close due to profit in %");
               for(int c1=0; c1<100; c1++)
                 {
                  if(!td[c1])
                    {
                     td[c1]=OrderTicket();
                     break;
                    }
                 }
              }
           }
        }
     }

   for(int c=0; c<100; c++)
     {
      if(td[c] && OrderSelect(td[c],SELECT_BY_TICKET))
        {
         if(OrderType()==OP_BUY)
           {
            if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),0,clrYellow))
              {
               e_ts_vi1[3]=0;
               e_ts_vi2[3]=0;
               td[c]=0;
              }
            else
              {
               if(e_ts(GetLastError(),3)) td[c]=0;
              }
           }
         else
         if(OrderType()==OP_SELL)
           {
            if(OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),0,clrYellow))
              {
               e_ts_vi1[3]=0;
               e_ts_vi2[3]=0;
               td[c]=0;
              }
            else
              {
               if(e_ts(GetLastError(),3)) td[c]=0;
              }
           }
        }
     }

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
   return false;
}
bool SellSignalCheck()
{
   return false
}
bool PlaceOrder()
{
   return false;
}