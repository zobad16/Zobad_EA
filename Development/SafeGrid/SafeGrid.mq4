//+------------------------------------------------------------------+
//|                                                     SafeGrid.mq4 |
//|                 Copyright 2018, QuantSoftware.net, Zobad Mahmood |
//|                                    https://www.quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2018, QuantSoftware.net, Zobad Mahmood"
#property link      "https://www.quantsoftware.net"
#property version   "1.00"
#property strict
//---------------------------------------------------------------------
#include "EntrySignal.mqh"
#include "MoneyManagement.mqh"
#include "Indicators.mqh"


EntrySignal     *algo ;
MoneyManagement *mm   ;
Indicators      *ind  ;

enum Strat_typeII
            {
               _DIRECTIONAL = 4,  //Directional
               _REVERSAL    = 5,  //Reversal
               //BOTH        = 1,  //Dir&Rev
               //ST_DEV_C2   = 2,  //Standard Deviation 2
               //ST_DEV_C3   = 3,  //Standard Deviation 3
               //_BREAKIN     = 6,  //Break in
               //_DIRECTIONAL_Range = 7,  //Directional Volatility
               //_REVERSAL_Range    = 8,  //Reversal Volatility
               //_MID_CROSS_DIRECTIONAL = 9, //Mid Directional
               //_MID_CROSS_REVERSAL    =10, //Mid Reversal   
               //_ADR_DIRECTIONAL       =11, //ADR Directional
               //_ADR_REVERSAL          =12, //ADR Reversal
            };

enum LotType
{
   MANUAL = 0,
   AUTO    = 1,
};
enum Take_Profit_Type{
   
   FIXED=0,
   VOLATILITY=1,
  // MID_BB=2
};
enum _type
{
   FIX    = 0,      //Fixed
   VOLAT  = 1       //Volatility
};
enum Type
  {
   INCREASE = 1,// Increase
   DECREASE = 0,// Decrease
   SAME = 2,// Same
  };

int                    buy_counter=0;
int                    sell_counter=0;
int                     _count=0;
int                    _ticket;
double                 _tp;
double                 _sl;
int                    _opType;
//--------------------------------------------------------------------------------
//Input Variables 
//---------------------------------------------
extern int              Magic_Number       = 1         ;             //Magic Number 
string          set="----------Consecutive Losses--------------";//Consecutive Losses Settings
bool                    useConsecutive     = false     ;             //Use Consecutive Loss
int                     noConsqLossAllowed = 3         ;             //Consecutive Losses Allowed
double                  percentReduction   = 5         ;             //Lot Size Percent Reduction
extern string          setLot=     "-------Lot Setting -------"       ;
LotType          lotType            = MANUAL      ;             //Lot Type
double           _risk              = 0.02       ;             //%Available Balance::Lot
extern double           LotSize            = 0.01      ;             //Position:: Lot Size(Manual)
extern string          order1=     "-------Order -------"             ;  
bool                   order1Open         =  false    ; 
extern Strat_typeII      _strat_type        = _DIRECTIONAL ;           //Strategy:: Type      
extern bool             useStrategy1       = true      ;             //Strategy:: Use Strategy
bool useHedge= false     ;             //Strategy:: Use Hegde 
bool visible = true      ;
extern Take_Profit_Type TP_Type            = VOLATILITY;             //TP:: Type
extern Take_Profit_Type SL_Type            = VOLATILITY;             //SL:: Type
extern double           TP_Value           =  3.0      ;             //TP:: Volatility/Fixed(Points)
extern double           SL_Value           =  3.0      ;             //SL:: Volatility/Fixed(Points)
extern string           gSetting=     "-------Grid Settings -------"             ;  
extern bool             useGrid            =  true    ;             //Grid::Use Grid
extern double           gridLotAddition    = 0;                      //Grid::Leg Lot addition. 0= same lotsize, 1= prev lot+1...
extern int              leg                = 6         ;             //Grid::Leg
extern double           gridEntry          = 30.0       ;            //Grid::Grid Leg Gap(points)
extern bool             EQ_Based           = true      ;             //Use Equity Based TP
extern bool             useGridStop        = false     ;             //Us Equity Based SL
extern double           _profitTarget      = 1000      ;             //Profit Target
extern double           _stopLevel         = -500.0    ;             //Stop Out Level
extern int              _timegap1          = 31        ;             //Order 1 time gap(in mins)
//---------------------------------------------------------------------------------------
double                 prev_pricel         =0.0        ;
double                 prev_prices         =0.0        ;  
double                 prev_lots           =0.0        ;
double                 prev_lotl           =0.0        ;
int                    _cur_total         = 0         ;
bool                   startFlag          = false     ;
double                 pLong                          ;
double                 pShort                         ;
int porl=0;
datetime expiry = D'2018.06.06 00:00';
bool bExpiryAlertDelieverd = false;
bool debug = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   expiry = D'2018.06.06 00:00';
   bExpiryAlertDelieverd = false;
   startFlag = true ;
   algo = new EntrySignal(9,9)    ;
   mm   = new MoneyManagement();
   ind   = new Indicators(9,9)    ;  
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
   //---------------------------------------------------------------
   if(!IsTradeAllowed()){ Alert("Trade not Allowed"); }
   else{
      //Check for EA expiry
      if((TimeCurrent()>expiry)){ if(bExpiryAlertDelieverd ==false){Alert("The EA has Expired...");bExpiryAlertDelieverd=true;}}
   //---------------------------------------------------------------    
      //Logic Starts from here
      else{
         
      //logic
         if(isOrdersTotal(Magic_Number)<1)
         {
            if(debug){
               //Place Order
            }
            else{
               if(!isEntrySignal(OP_BUY)){
                  if(PlaceOrder(OP_BUY, LotSize,"Grid-BUY",prev_pricel)){
                     prev_prices = prev_pricel;
                     pLong  = 1;
                     prev_lotl = LotSize; 
                     prev_lots = LotSize;
                  }
                                  
               }
               
               else if(isEntrySignal(OP_SELL)){
                  PlaceOrder(OP_SELL, LotSize,"Grid-SELL",prev_prices);                  
                  prev_pricel = prev_prices;
                  pShort = 1;
                  prev_lots = LotSize;
                  prev_lotl = LotSize;
               }            
            }
         //First Order
         }
         else
         {
            if(isGrid(useGrid,gridEntry,leg,prev_pricel,Magic_Number,OP_BUY)){
               if(PlaceOrder(OP_BUY, lotAddition(prev_lotl,gridLotAddition),"Grid-BUY-Leg",prev_pricel)){
                  
                  prev_lotl = lotAddition(prev_lotl,gridLotAddition);
                  pLong  ++;
                  Print("-----------------------------------------------------");
                  Print("New Grid Leg[Buy], Price[",DoubleToStr(prev_pricel),"], LotSize[",DoubleToStr(prev_lotl),"], LegCount[",pLong,"]");
                  Print("-----------------------------------------------------");
               }
            }
            else if(isGrid(useGrid,gridEntry,leg,prev_prices,Magic_Number,OP_SELL)){
               if(PlaceOrder(OP_SELL, lotAddition(prev_lots,gridLotAddition),"Grid-SELL-Leg",prev_prices)){
                  prev_lots = lotAddition(prev_lots,gridLotAddition);
                  pShort  ++;
                  Print("-----------------------------------------------------");
                  Print("New Grid Leg[Sell], Price[",DoubleToStr(prev_prices),"], LotSize[",DoubleToStr(prev_lots),"], LegCount[",pShort,"]");
                  Print("----------------------------------------------------");

               }
            }
            if(ClosingSignal(useGrid,gridEntry,leg,prev_prices,Magic_Number,OP_BUY)||ClosingSignal(useGrid,gridEntry,leg,prev_prices,Magic_Number,OP_SELL)){
               Print("Closing signal. Clossing all");
               mm.CloseAllOrders(Magic_Number);
               
            }
            else if(mm.EquityBasedClose(EQ_Based,_profitTarget,useGridStop,_stopLevel,Magic_Number,porl)){
               Print("Equity Closed");
               ResetCounters();
            }
            //Call Grid method
            
         }
      
      
      }
   }
   
  }
  void ResetCounters()
  {
   _tp=0.0;_sl=0.0;prev_lotl=0.0;prev_lots=0.0;prev_pricel=0.0;prev_prices=0.0;pLong=0;pShort=0;
  }
//+------------------------------------------------------------------+
//|Place Order function: params: op:int, lot:double, comment:string  |
//+------------------------------------------------------------------+

bool PlaceOrder(int op, double lot, string comment, double &price){
   double openprice=0.0, tp=0.0,sl=0.0;
   if(op == OP_BUY)openprice = Bid;
   else if(op==OP_SELL)openprice = Ask;
   price = openprice;
   return (mm.PlaceOrderHidden(op,lot,Magic_Number,(int)comment));
   //_tp = mm.CalculateTP(op,TP_Type,TP_Value);
   //_sl = mm.CalculateSL(op,openprice, SL_Type,SL_Value);
   //_opType = op;
   //_count++;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int isLegOpen(int mg, string symbol, int op)
  {
   int count =0;
   int total = OrdersTotal();
   for(int i=0;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==mg && OrderSymbol()== symbol && OrderType() == op){
          count++;          
          }
        }
     }
     if(debug){Print("Debug log:Symbol[",symbol,"]OrderType[",IntegerToString(op),"]Count[",IntegerToString(count),"]");}
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool IsNewBar()
{
  static datetime RegBarTime=0;
  datetime ThisBarTime=Time[0];
  if(ThisBarTime==RegBarTime)return false;
  else{ RegBarTime=ThisBarTime;return true;}
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
   
int isOrdersTotal(int mg)
{
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ;i<total;i++){
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0){
         if(OrderMagicNumber()==mg && OrderSymbol()== Symbol()){
               count+=1;               
         }      
      }
   }
   return count;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

bool isEntrySignal(int op)
{
   double adr_high      = ind.iADR(15,"");
   double adr_low       = ind.iADR(-15,"");
   if(adr_high == 0 || adr_low == 0) return false;
   Comment("high[",adr_high,"]low[",adr_low,"]");
   
   //--------------------------------------------   
   if(op == OP_BUY){
      if(Close[0]>adr_high){ Print("Buy Directional.");return true; }
   }
   else if(op== OP_SELL){
      if(Close[0]< adr_low){Print("Sell Directional.");return true;}
   }
   return true;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool isGrid(bool use, double legStep, int _leg,double orderPrice, int mg, int op){
   if(use && isLegOpen(mg,Symbol(),op)<_leg){
      if(op == OP_BUY && Bid >= nextGridPrice(mg,op,legStep,orderPrice)){
         if(debug) Print("NextGridPrice[",DoubleToStr(nextGridPrice(mg,op,legStep,orderPrice)),"]");
         return true;
       }
      else if(op == OP_SELL && Ask<=nextGridPrice(mg,op,legStep,orderPrice)){
         if(debug) Print("NextGridPrice[",DoubleToStr(nextGridPrice(mg,op,legStep,orderPrice)),"]");
         return true;
       }
   }
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

double nextGridPrice(int mg, int op, double legStep, double firstEntryPrice){
   int buyLegs = isLegOpen(mg,Symbol(),OP_BUY);
   int sellLegs = isLegOpen(mg,Symbol(),OP_SELL);
   double nextEPoint= firstEntryPrice;
   
   if(op== OP_BUY){
         nextEPoint = nextEPoint + (((buyLegs+1)*legStep)*Point) ;
      }
   else if(op== OP_SELL){
      nextEPoint = nextEPoint - (((sellLegs+1)*legStep)*Point) ;
      }
      if(debug){Print("Next Point for Grid Leg[", (string)nextEPoint,"]");}
   return nextEPoint;

}
bool ClosingSignal(bool use, double legStep, int _leg,double orderPrice, int mg, int op){
    if(use && isLegOpen(mg,Symbol(),op)>=_leg){
      if(op == OP_BUY && Bid >= nextGridPrice(mg,op,legStep,orderPrice)){
         if(debug) Print("NextGridPrice[",DoubleToStr(nextGridPrice(mg,op,legStep,orderPrice)),"]");
         return true;
       }
      else if(op == OP_SELL && Ask<=nextGridPrice(mg,op,legStep,orderPrice)){
         if(debug) Print("NextGridPrice[",DoubleToStr(nextGridPrice(mg,op,legStep,orderPrice)),"]");
         return true;
       }
   }
   return false;
}
double lotAddition(double prevLot, double add ){
   return (prevLot)+add;
}