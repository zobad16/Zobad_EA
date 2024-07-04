//+------------------------------------------------------------------+
//|                                                      ProjectName |
//|                                      Copyright 2020, CompanyName |
//|                                       http://www.companyname.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup"
#property link      "https://algotradeup.com"
#property version   "1.00"

#include <Trade\Trade.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>

CTerminalInfo  TerminalInfo;
CPositionInfo  m_position;
CDialog Dialog;
CEdit   Inputs[8];
CLabel  InputLabels[8];
CLabel  FlagLabel;
CLabel  FlagValue;
CLabel  TimeFlagLabel;
CLabel  TimeFlagValue;
CLabel  TimeLabel;
CLabel  TimeValue;
CLabel  PNLLabel;
CLabel  PNLValue;
CLabel  LotsTypeLabel;
CLabel  LotsTypeValue;
CLabel  ReversalLabel;
CLabel  ReversalValue;
CLabel  UseGridLabel;
CLabel  UseGridValue;
CLabel  LegsLabel;
CLabel  LegsValue;
CLabel  BLegsLabel;
CLabel  BLegsValue;
CLabel  SLegsLabel;
CLabel  SLegsValue;
CLabel  NPLabel;
CLabel  NPValue;
CButton MannualEntryBtn [9];
CButton CloseBtn;
CButton TitleBtn;
CTrade trade;

enum lotsType{
   FIXED_TYPE = 0,         //Fix Lots
   PERCENT_BALANCE = 1,    //Percent of the account
   MONEY = 2,              //Dollar amount
};
enum stopType{
   FIXED = 0, //Fix
   AVG   = 1  //Average
};
input int               magic_num         =  46598; //Magic Number
//input string            Trade_Symbol      =  "EURUSD.r";//Order Symbol
input string            TradeComment      = "WeeklyTrendRanger";
input bool              AutoTimeEntry     = false;
input bool              UseMannualEntry   = true; //Use Manual entry
input bool              AllowMonday       = true; //Trade on Monday
input lotsType          LotsType          = FIXED_TYPE;
input bool              UseGrid           = false;
input int               MaxLegs           = 3;
input double            GridLotSize       = 0.1;
input double            GridEntryPoints   = 100;
input stopType          GridTPType        = AVG; //Grid Tp Type
input double            GridTp_Fix        = 800;//Tp Fixed(pips)
input double            GridSl_Fix        = 800; //Sl Fix(pips)

//Not used
input bool             UseDirectional        = false; //Use Directional
input bool             UsePartialClose       = false; //Use Partial close
input double           PartialClosePoints    = 600.00;//Partial Close Points
input double           PartialClosePercent   = 50.00; //Partial Close Percent
input bool             UseJumptoBreakeven    = false; //Use Jump to Breakeven
input double           BreakevenTriggerPoints= 600.00;//Breakeven at points
input double           BreakevenPoints       = 50.00; //Points to add from breakeven


bool                 UseEquityTrail=false;//Use Equity trail
double               EquityTrailStart= 500;//Equity Trail Start point
double               Width=200;//Equity trail width

//---------------------------------------------------------------------
double            Threshold_Price  =  0.0;//Threshold price
double            Lot_Size          =  0.0;//Lots
double            Entry_Threshold   =  40;//Entry threshold(pips)
double            Tp_Fix            =  800;//Tp Fixed(pips)
double            Sl_Fix            =  100; //Sl Fix(pips)
double            TP_Money          =  1000;     //TP $
double            SL_Money          =  1000;     //SL $

string          Entry_Time          = "00:00";
bool _flag = false;
datetime Expiry=D'2025.10.19 00:00';
string current_time ;
bool exp_deliverd = false;
bool trade_time = false;

bool isDebug = false;

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int OnInit() {
   trade.SetExpertMagicNumber(magic_num);
   InitializeGUI();
   SetParameters();
   EventSetMillisecondTimer(200);

   return(INIT_SUCCEEDED);
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason) {
   Dialog.Destroy(reason);
   EventKillTimer();

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnTimer() {
   UpdateDashboard();  
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
string            Trade_Symbol      =  Symbol();
void OnTick() {
//---
   if(!TerminalInfo.IsTradeAllowed()){
      Comment("Auto trading is disabled");
      return;
   }
   if(CheckExpiry()) {
      if(!exp_deliverd) {
         exp_deliverd = true;
         Alert("EA expired. Please contact the developer");
      } else
         return;
   }
   
   datetime _time = TimeLocal();
   current_time = TimeToString(_time, TIME_MINUTES);
   Comment("Flag: "+(string)_flag);
   
   
   //1) first entry only if no open positions
   int legs = GetLegs();
   if(legs == 0){
      if(isDebug)PlaceOrder(POSITION_TYPE_BUY,TradeComment);
      if(!_flag && Threshold_Price > 0 && Lot_Size > 0) {
         int dayOfWeek = DayofWeek();
         double ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
         double bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
         double _point = SymbolInfoDouble(Trade_Symbol, SYMBOL_POINT);
         double pricePerPips = pricePerPip(Trade_Symbol);
               
         if(AllowMonday && (dayOfWeek >0 && dayOfWeek <6)) {
            if(isDebug) Print("Checking for signals");
            if(bid > Threshold_Price) {
               double difference = bid - Threshold_Price;
               double pipDifference = MathAbs(difference)/pricePerPips;
               if(isDebug) Print("Checking for sell signal");
               if(isDebug) Print(__FUNCTION__," Entry Threshold: ",Entry_Threshold,"  pip diff : ", pipDifference, "  2nd condition: ", (MathAbs(Tp_Fix * Point())/pricePerPips), " is in range: ", (pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips));
               if(!UseDirectional && pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("Sell");
                  MannualEntry(ORDER_TYPE_SELL);
                  _flag = true;
               }
               if(UseDirectional && pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("Directional BUY");
                  MannualEntry(ORDER_TYPE_BUY);
                  _flag = true;
               }
            } 
            else if(ask < Threshold_Price) {
               double difference = Threshold_Price- ask;
               double pipDifference = MathAbs(difference)/pricePerPips;
               if(isDebug) Print("Checking for buy signal");
               if(!UseDirectional && pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("BUY");
                  MannualEntry(ORDER_TYPE_BUY);
                  _flag = true;
               }
               if(UseDirectional && pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("Directional SELL");
                  MannualEntry(ORDER_TYPE_SELL);
                  _flag = true;
               }
            }
   
         } 
         else if(!AllowMonday && (dayOfWeek >1 && dayOfWeek <6)) {
            Print("Checking for signals");
            if(bid > Threshold_Price) {
               double difference = bid - Threshold_Price;
               double pipDifference = MathAbs(difference)/pricePerPips;
               Print("Checking for sell signal");
               if(pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("Sell");
                  MannualEntry(ORDER_TYPE_SELL);
                  _flag = true;
               }
            } 
            else if(ask < Threshold_Price) {
               double difference = Threshold_Price- ask;
               double pipDifference = MathAbs(difference)/pricePerPips;
               if(isDebug) Print("Checking for buy signal");
               if(pipDifference >= Entry_Threshold && pipDifference < MathAbs(Tp_Fix * Point())/pricePerPips) {
                  Print("BUY");
                  MannualEntry(ORDER_TYPE_BUY);
                  _flag = true;
               }
            }
         }
      }   
   }
   else{
      //2) if open positions
      //check for grid condition
      //if condition meets place order
      //sl same as 1st leg
      //tp either on avg price
      //mannual entry
      if(UseGrid && legs < MaxLegs && legs > 0){
         int lastOrderDirection = LastOrderDirection();
         if(lastOrderDirection == POSITION_TYPE_BUY){
            if(LegEntryCheck(lastOrderDirection)){
               //check if tp/sl fixed or avg
               //TODO calculate sl
               double ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
               double bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
               double tp = NormalizePrice(ask+(+Tp_Fix*Point()));
               double sl = NormalizePrice(FirstOrderPrice(POSITION_TYPE_BUY)-(Sl_Fix*Point()));
               if(trade.Buy(GridLotSize,NULL,ask, sl,(GridTPType == FIXED) ? tp: NULL,TradeComment)){
                  if(GridTPType == AVG) BTP_Average();
               }
            }
         }
         else if(lastOrderDirection == POSITION_TYPE_SELL){
            if(LegEntryCheck(lastOrderDirection)){
               //check if tp/sl fixed or avg
               double firstPosition = FirstOrderPrice(POSITION_TYPE_SELL);
               double ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
               double bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
               double sl = NormalizePrice(firstPosition+(+Sl_Fix*Point()));
               //todo tp
               //conditional tp
               if(trade.Sell(GridLotSize,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),sl,NULL,TradeComment)){
                  if(GridTPType == AVG)STP_Average();
               }
            }
         }
         //get latest position and its price
         //get first legs price and sl and tp
        
      }
      PartialClose();
      JumpToBreakeven();
      CheckLoss();
      EquityTrail(UseEquityTrail, EquityTrailStart, Width);
   }
   
   
}

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam) {
   if(id == CHARTEVENT_OBJECT_CLICK) {
      if(id == CHARTEVENT_OBJECT_CLICK) {
         if(sparam == "")
            return;
         if(sparam=="Ok_Btn") {
            MessageBox("Applying parameters");
            SetParameters();
            MannualEntryBtn[4].Pressed(false);
            return;
         }
         if(sparam=="Close_Btn") {
            CloseAll();
            MannualEntryBtn[2].Pressed(false);
            return;
         }
         if(sparam=="Reset_Btn") {
            //_flag = true;
            MessageBox("Reseting flags");
            _flag = false;
            trade_time = false;
            MannualEntryBtn[3].Pressed(false);
            return;
         }
         if(sparam == "Get_Price_Btn") {
            MessageBox("Fetching current price");
            MannualEntryBtn[0].Pressed(false);
            Inputs[0].Text(""+(string)SymbolInfoDouble(Trade_Symbol, SYMBOL_BID));
            return;
            //PlacePendingOrders();
         }
         if(sparam == "Mannual_lmt") {
            MessageBox("Placing mannual order");
            //if(!_flag)
            //{
            MannualEntryBtn[1].Pressed(false);
            PlacePendingOrders();
            _flag = true;
            return;
            //}
         }
         if(sparam == "BuySp_Btn") {
            MessageBox("Placing mannual order");
            MannualEntryBtn[5].Pressed(false);
            MannualEntrySP(ORDER_TYPE_BUY);
            _flag = true;
            return;
         }
         if(sparam == "SellSp_Btn") {
            MessageBox("Placing mannual order");
            MannualEntryBtn[6].Pressed(false);
            MannualEntrySP(ORDER_TYPE_SELL);
            _flag = true;
            return;
         }
         if(sparam == "Buy_Btn") {
            MessageBox("Placing mannual order");
            MannualEntryBtn[7].Pressed(false);
            MannualEntry(ORDER_TYPE_BUY);
            _flag = true;
            return;
         }
         if(sparam == "Sell_Btn") {
            MessageBox("Placing mannual order");
            MannualEntryBtn[8].Pressed(false);
            MannualEntry(ORDER_TYPE_SELL);
            _flag = true;
            return;
         }
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckExpiry() {
   MqlDateTime str1, str2;
   TimeToStruct(Expiry, str1);
   TimeToStruct(TimeCurrent(), str2);
   if(str2.day >= str1.day && str2.mon >= str1.mon && str2.year >= str1.year)
      return true;
   else
      return false;
}
void PartialClose(){
   if(!UsePartialClose) return;
   
   for(int i = 0; i<PositionsTotal(); i++){
      ulong positionTckt = PositionGetTicket(i);
      if(PositionSelectByTicket(positionTckt)){
         if(PositionGetInteger(POSITION_MAGIC) == magic_num && PositionGetString(POSITION_SYMBOL) == _Symbol){
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double lots = PositionGetDouble(POSITION_VOLUME);
            
            if(lots == Lot_Size || lots == GridLotSize){
               if(pType == POSITION_TYPE_BUY){
                  double _bid = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                  _bid = NormalizeDouble(_bid, _Digits);
                  if(_bid > openPrice + PartialClosePoints * Point()){
                     
                     double lotsToClose = (PartialClosePercent/100)*lots;
                     lotsToClose = NormalizeDouble(lotsToClose,2);
                     if(trade.PositionClosePartial(positionTckt,lotsToClose)){
                        Print("#",positionTckt,": Partialy closed. Price: ",_bid);
                     }                  
                  }
               }
               else if(pType == POSITION_TYPE_SELL){
                  double _ask = SymbolInfoDouble(_Symbol,SYMBOL_BID);
                  _ask = NormalizeDouble(_ask, _Digits);
                  
                  if(_ask < openPrice - PartialClosePoints * Point()){
                     double lotsToClose = (PartialClosePercent/100)*lots;
                     lotsToClose = NormalizeDouble(lotsToClose,2);
                     if(trade.PositionClosePartial(positionTckt,lotsToClose)){
                        Print("#",positionTckt,": Partialy closed. Price: ",_ask);
                        
                     }                  
                  }
               }
            }            
         }         
      }
   }

}
void JumpToBreakeven(){
   if(!UseJumptoBreakeven)return;
   
   for(int i = 0; i<PositionsTotal(); i++){
      ulong positionTckt = PositionGetTicket(i);
      if(PositionSelectByTicket(positionTckt)){
         if(PositionGetInteger(POSITION_MAGIC) == magic_num && PositionGetString(POSITION_SYMBOL) == _Symbol){
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            ENUM_POSITION_TYPE pType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            double lots = PositionGetDouble(POSITION_VOLUME);
            
            if(lots == Lot_Size || lots == GridLotSize){
               if(pType == POSITION_TYPE_BUY){
                  double _bid = SymbolInfoDouble(_Symbol,SYMBOL_ASK);
                  _bid = NormalizeDouble(_bid, _Digits);
                  if(_bid > openPrice + BreakevenTriggerPoints * Point()){
                     double sl = openPrice + BreakevenPoints * Point();                      
                     if(trade.PositionModify(positionTckt,sl, PositionGetDouble(POSITION_TP))){
                        Print("#",positionTckt,": Jump to breakeven. Price: ",DoubleToString(_bid,_Digits));
                     }                  
                  }
               }
               else if(pType == POSITION_TYPE_SELL){
                  double _ask = SymbolInfoDouble(_Symbol,SYMBOL_BID);
                  _ask = NormalizeDouble(_ask, _Digits);
                  
                  if(_ask < openPrice - BreakevenTriggerPoints * Point()){
                     double sl = openPrice - (BreakevenPoints * Point());                      
                     if(trade.PositionModify(positionTckt,sl, PositionGetDouble(POSITION_TP))){
                        Print("#",positionTckt,": Jump to breakeven. Price: ",DoubleToString(_ask,_Digits));
                     }                  
                  }
               }
            }            
         }         
      }
   }
}
bool LegEntryCheck(int op){
   double nextPrice = GetNextPrice(op);
   if(isDebug)Print("Grid next price ",nextPrice);
   double distance = GridEntryPoints*Point();
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return false; }
   
   double Ask=tick.ask;
   double Bid=tick.bid;
   
   double price = nextPrice;
      
   if(op == POSITION_TYPE_BUY ){
      if(Bid <= price){
      //if(Bid <= price - distance){
         Print("BUY-Leg Entry: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
   }
   if(op == POSITION_TYPE_SELL ){
      if(Ask >= price){
         Print("SELL-Leg Entry: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
   }
   return false;
}
double GetNextPrice(int op){   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) { 
      Print("no tick data available, error = ",GetLastError()); 
      ExpertRemove(); 
      return -99; 
   }
   else{
      double _ask=tick.ask;
      double _bid=tick.bid;
      double next_price = 0.0;
      double lastOrderPrice = LastOrderPrice(op);
      
      if(op == POSITION_TYPE_BUY){
         next_price = (lastOrderPrice -  GridEntryPoints*Point());     
      }
      else if(op == POSITION_TYPE_SELL){
         next_price = (lastOrderPrice+GridEntryPoints*Point());         
      }
      return next_price; 
   }
}

double Average_Open_Price(int op){
   double avg = 0.0;
   double lot=0.0,sum_lots=0.0, price =0.0,weighted_price=0.0, sum_weighted_price=0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(PositionGetTicket(i)) // selects the position by index for further access to its properties
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol()&& PositionGetInteger(POSITION_TYPE) == op && PositionGetString(POSITION_COMMENT) ==TradeComment )
         {
            lot = PositionGetDouble(POSITION_VOLUME);
            sum_lots += lot;
            price = PositionGetDouble(POSITION_PRICE_OPEN);
            weighted_price = lot*price;
            sum_weighted_price+= weighted_price;
            
         }   
   }
   avg = sum_weighted_price/sum_lots;
   return avg;
}
double LastOrderPrice(int op)
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
               }  
             }
         }
      }
      if(isDebug)Print("POsition type: ",op," Last Order Price: ",k);
      return k;
   

}
double LastOrderPrice()
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
               }  
             }
         }
      }
      return k;
   

}
double FirstOrderPrice()
{
   datetime time =D'01.01.2020';
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)<= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
               }  
             }
         }
      }
      return k;
   

}
double FirstOrderPrice(int op)
{
   datetime time;
      double k = 0.0;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE) == op)
             {
               if(i == 0){
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);               
               }
               if(PositionGetInteger(POSITION_TIME)<= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  k = PositionGetDouble(POSITION_PRICE_OPEN);
                  if(isDebug)Print(k);
               }  
             }
         }
      }
      return k;
   

}
int LastOrderDirection()
{
   datetime time =D'01.01.2020';
      int op = -999;
      for(int i=0; i<PositionsTotal(); i++)
      {
         if(PositionGetTicket(i))
         {
            if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
             {
               if(PositionGetInteger(POSITION_TIME)>= time)
               {
                  time =(datetime) PositionGetInteger(POSITION_TIME);
                  op = PositionGetInteger(POSITION_TYPE);
               }  
             }
         }
      }
      return op;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int DayofWeek() {
   MqlDateTime tm;
   TimeCurrent(tm);
   return(tm.day_of_week); // Day of week (0-Sunday, 1-Monday, ... ,6-Saturday)
//https://www.mql5.com/en/forum/328971/page3
}

int GetLegs(int op = -99){
   int b_legs = 0, s_legs = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionGetTicket(i)) {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Trade_Symbol) {
            ENUM_POSITION_TYPE direction = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            if(direction == POSITION_TYPE_BUY)b_legs ++;
            else if (direction == POSITION_TYPE_SELL) s_legs++;               
         }
      }
   }
   if(op == POSITION_TYPE_BUY)return b_legs;
   else if(op == POSITION_TYPE_SELL)return s_legs;
   
   return b_legs + s_legs;   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double pricePerPip(string sym="") {
   if(StringFind(sym, "XAUUSD", 0)!=-1) // exception for 1 pip = 0.1, like aug, xau...
      return 0.1;
   else if(StringFind(sym, "XAU/USD", 0)!=-1) // exception for 1 pip = 0.1, like aug, xau...
      return 0.1;   
   if(StringFind(sym, "BTCUSD", 0)!=-1 || StringFind(sym, "ETHUSD", 0)!=-1) // exception for 1pip = 10, like crypto and stock
      return 10;
///// common for all forex pairs, some broker may trim to 4 or 2 digits, so convert them back to 5 and 3 standard
   int deciCount = SymbolInfoInteger(sym, SYMBOL_DIGITS);
   if(deciCount==4)
      deciCount=5;
   if(deciCount==2)
      deciCount=3;
// now 1 pip is 10 points with forex 5 or 3 digits standard
   return MathPow(10, 1-deciCount);
}
//+------------------------------------------------------------------+
void PlacePendingOrders() {
   double ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
   double _point = SymbolInfoDouble(Trade_Symbol, SYMBOL_POINT);
   Print(Threshold_Price);
   if(!UseDirectional) {
      if(trade.BuyStop(Lot_Size, NormalizePrice(Threshold_Price+(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
         if(trade.SellStop(Lot_Size, NormalizePrice(Threshold_Price-(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
            //set flag to true
            _flag = true;
         } else {
            Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
            _flag = true;
         }
      }
   } else {
      if(trade.SellLimit(Lot_Size, NormalizePrice(Threshold_Price+(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
         if(trade.BuyLimit(Lot_Size, NormalizePrice(Threshold_Price-(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
            //set flag to true
            _flag = true;
         } else {
            Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
            _flag = true;
         }
      }


   }


}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BTP_Average()
{
   double LotT=0;
   double num=0;
   double P_Avg=Average_Open_Price(POSITION_TYPE_BUY);
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY && PositionGetString(POSITION_COMMENT) ==TradeComment )
            trade.PositionModify(PositionGetTicket(i),m_position.StopLoss(),Round2Ticksize(P_Avg+GridTp_Fix*Point()));

      }
   }
}
void STP_Average()
{
   double LotT=0;
   double num=0;
   double P_Avg=Average_Open_Price(POSITION_TYPE_SELL);
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL && PositionGetString(POSITION_COMMENT) ==TradeComment)
            trade.PositionModify(PositionGetTicket(i),m_position.StopLoss(),Round2Ticksize(P_Avg-GridSl_Fix*Point()));

      }
   }
}
bool ModifyTP() {
   int positions = PositionsTotal();
   int count = 0, op = -9999;
   ulong ticket =-999, ticket_p=-999;
   double op_price = 0.0, p_price =0.0, tp = 0.0;
   for(int i=0; i<=positions; i++) {
      //if(!PositionGetTicket(i)) break;
      if(PositionGetTicket(i)) {
         if(PositionGetString(POSITION_SYMBOL)==Trade_Symbol && PositionGetInteger(POSITION_MAGIC)==magic_num)
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL) {
               count++;
               ticket = PositionGetInteger(POSITION_TICKET);
               op_price = PositionGetDouble(POSITION_PRICE_OPEN);
               op = (int)PositionGetInteger(POSITION_TYPE);
               tp = PositionGetDouble(POSITION_TP);
            }
      }

   }
   int count_p = 0;
   for(int i = 0 ; i< OrdersTotal(); i++) {
      //Check pending count == 1
      //Take the price and and close the ticket
      if(OrderGetTicket(i) > 0) {
         if(OrderGetString(ORDER_SYMBOL)==Trade_Symbol && OrderGetInteger(ORDER_MAGIC)==magic_num) {
            if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP
                  ||OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT) {
               count_p++;
               ticket_p = OrderGetInteger(ORDER_TICKET);
               p_price  = OrderGetDouble(ORDER_PRICE_OPEN);
            }
         }
      }
   }
//if position open:
//if stop orders open -> delete and put as sl
   if(count == 1 && count_p >0) {
      Alert("Count: "+(string)count_p+" |Ticket: "+(string)ticket_p);
      trade.OrderDelete(ticket_p);

      if(tp > 0.0)
         return false;
      if(ticket != -999) {
         double _point = SymbolInfoDouble(Trade_Symbol, SYMBOL_POINT);
         double _tp = 0.0, _sl=0.0;
         if(op == POSITION_TYPE_BUY) {
            _tp = NormalizePrice(op_price+(Tp_Fix *_point));
            _sl = NormalizePrice(Threshold_Price-(Entry_Threshold*_point));
            if(UseDirectional)
               _sl =NormalizePrice(op_price-(Entry_Threshold*_point));
            //Settlement_Price-(Entry_Threshold*_point)
         }

         else if(op == POSITION_TYPE_SELL) {
            _tp = NormalizePrice(op_price -(Tp_Fix *_point));
            _sl = NormalizePrice(Threshold_Price+(Entry_Threshold*_point));
            if(UseDirectional)
               _sl =NormalizePrice(op_price+(Entry_Threshold*_point));
         }

         else
            return false;
         Comment(ticket_p);
         if(trade.PositionModify(ticket, _sl, _tp)) {
            trade.OrderDelete(ticket_p);
         }

      }
   }
   return false;
}


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckLoss() {
   double  num=0;
   int n = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionGetTicket(i)) {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==_Symbol) {
            num=num+PositionGetDouble(POSITION_PROFIT);
            n++;
         }

      }
   }
   if(n == 0)
      return;
   if(num<SL_Money*(-1) || num>=TP_Money)
      CloseAll();


}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculatePNL() {
   double pnl = 0.0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionGetTicket(i)) {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==_Symbol) {
            pnl=pnl+PositionGetDouble(POSITION_PROFIT);
         }

      }
   }
   return pnl;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAll() {
   for(int i=PositionsTotal()-1; i>=0; i--) {
      if(PositionGetTicket(i)) {
         if(PositionGetString(POSITION_SYMBOL)==_Symbol && PositionGetInteger(POSITION_MAGIC)==magic_num)
            if(!trade.PositionClose(PositionGetTicket(i))){
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
      }
   }
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetParameters() {
   Threshold_Price  = NormalizeDouble(StringToDouble(Inputs[0].Text()),_Digits);
   Lot_Size         = NormalizeDouble(StringToDouble(Inputs[1].Text()),2);
   Tp_Fix           = StringToDouble(Inputs[2].Text());
   Sl_Fix           = StringToDouble(Inputs[3].Text());
   TP_Money         = StringToDouble(Inputs[4].Text());
//Sl_Fix           = StringToDouble(Inputs[4].Text());
   SL_Money         = StringToDouble(Inputs[5].Text());
   Entry_Threshold  = StringToDouble(Inputs[6].Text());
   Entry_Time       = Inputs[7].Text();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CheckTradeTime() {
   if(StringSubstr(current_time, 0, 5) == Entry_Time)
      return true;
   return false;
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op) {
   PlaceOrder(op, TradeComment);

}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry() {
//if above settlement price place buy: place sell
   double _bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
   if(!UseDirectional) {
      if(_bid < Threshold_Price && _ask < Threshold_Price)
         PlaceOrder(ORDER_TYPE_SELL, TradeComment);
      if(_ask > Threshold_Price && _bid > Threshold_Price)
         PlaceOrder(ORDER_TYPE_BUY, TradeComment);
   }
   if(UseDirectional) {
      if(_bid < Threshold_Price && _ask < Threshold_Price)
         PlaceOrder(ORDER_TYPE_BUY, TradeComment);
      if(_ask > Threshold_Price && _bid > Threshold_Price)
         PlaceOrder(ORDER_TYPE_SELL, TradeComment);
   }

}

void MannualEntrySP(int op) {
//if above settlement price place buy: place sell
   double _bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
   double _point = SymbolInfoDouble(Trade_Symbol, SYMBOL_POINT);
   double lots = 0.0;
   
   if(LotsType == FIXED_TYPE) lots = Lot_Size;
   else if(LotsType == PERCENT_BALANCE) lots = CalculateRiskPercentLot(Lot_Size, Sl_Fix * _point);
   else if (LotsType == MONEY) lots = CalculateRiskMoneyLot(Lot_Size, Sl_Fix * _point);
   
   if(lots == 0){
      Print(__FUNCTION__,"Invalid Lot size");
      return;
   }
   
   int adj_op = op;
   if(UseDirectional) {
      if(op == ORDER_TYPE_BUY)
         adj_op = ORDER_TYPE_SELL;
      else if(op == ORDER_TYPE_SELL)
         adj_op = ORDER_TYPE_BUY;
   }
   if(adj_op == ORDER_TYPE_BUY) {
      if(_ask > Threshold_Price) {
         if(trade.BuyLimit(lots, NormalizePrice(Threshold_Price), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
            if(trade.SellStop(lots, NormalizePrice(Threshold_Price-(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
               _flag = true;
            } else {
               Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
               _flag = true;
            }
         }
      } else
         PlaceOrder(ORDER_TYPE_BUY, TradeComment);
   }
   if(adj_op == ORDER_TYPE_SELL) {
      if(_bid < Threshold_Price) {
         if(trade.SellLimit(lots, NormalizePrice(Threshold_Price), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
            if(trade.BuyStop(lots, NormalizePrice(Threshold_Price+(Entry_Threshold*_point)), Trade_Symbol, 0.0, 0.0, ORDER_TIME_GTC, 0, TradeComment)) {
               _flag = true;
            } else {
               Print("Error opening Sell Limit Order. Reason: "+(string)GetLastError());
               _flag = true;
            }
         }
      } else
         PlaceOrder(ORDER_TYPE_SELL, TradeComment);
   }

}

void PlaceOrder(int op, string comment) {

   double _bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
   double _point = SymbolInfoDouble(Trade_Symbol, SYMBOL_POINT);
   double lots = 0.0;
   
   if(LotsType == FIXED_TYPE) lots = Lot_Size;
   else if(LotsType == PERCENT_BALANCE) lots = CalculateRiskPercentLot(Lot_Size, Sl_Fix * _point);
   else if (LotsType == MONEY) lots = CalculateRiskMoneyLot(Lot_Size, Sl_Fix * _point);
   
   if(lots == 0){
      Print(__FUNCTION__,"Invalid Lot size");
      return;
   }
   
   int ticket = -99;
   
   if(op == ORDER_TYPE_BUY) {
      ticket = trade.Buy(lots, Trade_Symbol, _ask, NormalizePrice(_bid-(Sl_Fix*_point)), NormalizePrice(_ask+(+Tp_Fix*_point)), comment);
      _flag =true;      
   }

   else if(op == ORDER_TYPE_SELL) {
      ticket = trade.Sell(lots, Trade_Symbol, _bid, NormalizePrice(_bid+(Sl_Fix*_point)), NormalizePrice(_bid-(Tp_Fix*_point)), comment);
      _flag = true;      
   }

}


double NormalizePrice(double price) {
   double m_tick_size=SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   return(NormalizeDouble(MathRound(price/m_tick_size)*m_tick_size, _Digits));
}

bool trail_flag = false;
double trail_equity =0.0;
void EquityTrail(bool use, double start, double width) {
   if(!use)
      return;

   double pnl = CalculatePNL();

//trail
   if(trail_flag) {
      if(pnl<=trail_equity) {
         //Liquidate
         trail_flag = false;
         Alert(Symbol()+": EQ-Trail Liquidating positions");
         Print(Symbol()+": EQ-Trail Liquidating positions- Profit["+DoubleToString(pnl, 2)+"] trail["+DoubleToString(trail_equity, 2)+"]");
         CloseAll();
         return;
      } else if((pnl-trail_equity)> width) {
         trail_equity = pnl-width;
      }
   } else if(!trail_flag) {
      if(pnl >= start) {

         trail_flag = true;
         trail_equity = pnl-width;
         Print("Trail Started-"+Symbol()+"- Trailing at: "+DoubleToString(trail_equity, 1));
         return;
      }
   }

}
double CalculateRiskPercentLot(double riskPercent, double slPoints){
   double lots = 0.0;
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(tickSize == 0 || tickValue == 0 || lotstep == 0){
      Print(__FUNCTION__,"Lot size could not be calculated");
      return 0;
   }
   
   double riskMoney = AccountInfoDouble(ACCOUNT_BALANCE) * riskPercent /100;
   double moneyLotStep = (slPoints / tickSize) * tickValue * lotstep;
   Print("Percent lot money at risk: ", riskMoney);
   if(moneyLotStep == 0){
      Print(__FUNCTION__,"Lot size could not be calculated");
      return 0;
   }
   
   lots = MathFloor(riskMoney / moneyLotStep) * lotstep;
   
   return lots;

}
double CalculateRiskMoneyLot(double moneyAtRisk, double slPoints){
   double lots = 0.0;
   double tickSize = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   double tickValue = SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_VALUE);
   double lotstep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   
   if(tickSize == 0 || tickValue == 0 || lotstep == 0){
      Print(__FUNCTION__,"Lot size could not be calculated");
      return 0;
   }
   
   double riskMoney = moneyAtRisk;
   double moneyLotStep = (slPoints / tickSize) * tickValue * lotstep;
   
   if(moneyLotStep == 0){
      Print(__FUNCTION__,"Lot size could not be calculated");
      return 0;
   }
   
   lots = MathFloor(riskMoney / moneyLotStep) * lotstep;
   
   return lots;

}
double Round2Ticksize( double price )
{
   double tick_size = SymbolInfoDouble( _Symbol, SYMBOL_TRADE_TICK_SIZE );
   return( round( price / tick_size ) * tick_size );
}
void UpdateDashboard(){
   //pnl + legs calc
   double pnl = 0.0;
   int b_legs = 0, s_legs = 0;
   for(int i=0; i<PositionsTotal(); i++) {
      if(PositionGetTicket(i)) {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Trade_Symbol) {
            ENUM_POSITION_TYPE direction = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);
            pnl+= PositionGetDouble(POSITION_PROFIT);
            if(direction == POSITION_TYPE_BUY)b_legs ++;
            else if (direction == POSITION_TYPE_SELL) s_legs++;               
         }
      }
   }
   PNLValue.Text(DoubleToString(pnl,2));
   
   //lot type
   string lotstype = "";
   if(LotsType == FIXED_TYPE)lotstype = "Fixed";
   else if(LotsType == PERCENT_BALANCE)lotstype = "Account Percent";
   else if(LotsType == MONEY)lotstype = "Money";
   LotsTypeValue.Text(lotstype);
   
   LegsValue.Text(IntegerToString(b_legs+s_legs));     
   BLegsValue.Text(IntegerToString(b_legs));       
   SLegsValue.Text(IntegerToString(s_legs));  
   
   //pip difference
   double ask = SymbolInfoDouble(Trade_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(Trade_Symbol, SYMBOL_BID);
   //int digits = SymbolInfoInteger(Trade_Symbol, SYMBOL_DIGITS);
   
   double pricePerPips = pricePerPip(Trade_Symbol);
   
   double pipDifference = 0;
   if(bid > Threshold_Price) {
      double difference = bid - Threshold_Price;
      pipDifference = MathAbs(difference)/pricePerPips;
      FlagValue.Text((string)pipDifference);
   } else if(ask < Threshold_Price) {
      double difference = Threshold_Price- ask;
      pipDifference = MathAbs(difference)/pricePerPips;
   }
   //time and flag
   FlagValue.Text((string)_flag);
   TimeFlagValue.Text((string) trade_time);
   TimeValue.Text(DoubleToString(pipDifference,2));
}
void InitializeGUI(){
   Dialog.Create(ChartID(), "                                      ALGOTRADEUP", 0, 5, 20, 440, 380);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(), dialogNumber+"Caption", OBJPROP_BGCOLOR, clrGold);
   ObjectSetInteger(ChartID(), dialogNumber+"ClientBack", OBJPROP_BGCOLOR, clrWhite);
   TitleBtn.Create(0, "Title", 0, 5, 6, 0, 0)                              ;
   TitleBtn.Text("Weekly Trend Ranger")                                            ;
   TitleBtn.FontSize(12)                                          ;
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(225)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrDarkTurquoise)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   Dialog.Add(TitleBtn);

   InputLabels[0].Create(0, "PriceLabel", 0, 5, 45, 0, 0);
   InputLabels[0].Text("Opening Price: ");
   InputLabels[0].FontSize(9);
   Dialog.Add(InputLabels[0])                                     ;

   Inputs[0].Create(0, "PriceEdit", 0, 125, 45, 0, 0);
   Inputs[0].Text(""+(string)Threshold_Price);
   Inputs[0].FontSize(9);
   Inputs[0].Height(20)                                            ;
   Inputs[0].Width(100)                                            ;
   Dialog.Add(Inputs[0])                                           ;

   TimeLabel.Create(0, "_TimeLabel", 0, 250, 25, 0, 0)                   ;
   TimeLabel.Text("Pip Diff: ")                                        ;
   TimeLabel.FontSize(9)                                          ;
   Dialog.Add(TimeLabel)                                          ;

   TimeValue.Create(0, "_TimeValue", 0, 320, 25, 0, 0)                   ;
   TimeValue.Text(TimeToString(TimeLocal(), TIME_MINUTES))         ;
   TimeValue.FontSize(9)                                          ;
   Dialog.Add(TimeValue)                                          ;

   FlagLabel.Create(0, "FlagLabel", 0, 250, 45, 0, 0)                   ;
   FlagLabel.Text("Flag: ")                                        ;
   FlagLabel.FontSize(9)                                          ;
   Dialog.Add(FlagLabel)                                          ;

   FlagValue.Create(0, "FlagValue", 0, 320, 45, 0, 0)                   ;
   FlagValue.Text((string)_flag)                                        ;
   FlagValue.FontSize(9)                                          ;
   Dialog.Add(FlagValue)                                          ;

   PNLLabel.Create(0, "PNLLabel", 0, 250, 65, 0, 0)                   ;
   PNLLabel.Text("PNL: ")                                        ;
   PNLLabel.FontSize(9)                                          ;
   Dialog.Add(PNLLabel)                                          ;

   PNLValue.Create(0, "PNLValue", 0, 320, 65, 0, 0)                   ;
   PNLValue.Text("0.0")                                        ;
   PNLValue.FontSize(9)                                          ;
   Dialog.Add(PNLValue)                                          ;
   
   LotsTypeLabel.Create(0, "LotsTypeLabel", 0, 250, 85, 0, 0)                   ;
   LotsTypeLabel.Text("Lots Type: ")                                        ;
   LotsTypeLabel.FontSize(9)                                          ;
   Dialog.Add(LotsTypeLabel)                                          ;

   LotsTypeValue.Create(0, "LotsValue", 0, 320, 85, 0, 0)                   ;
   LotsTypeValue.Text(" - ")                                        ;
   LotsTypeValue.FontSize(9)                                          ;
   Dialog.Add(LotsTypeValue)                                          ;
   
   UseGridLabel.Create(0, "UseGridLabel", 0, 250, 105, 0, 0)                   ;
   UseGridLabel.Text("Use Grid: ")                                        ;
   UseGridLabel.FontSize(9)                                          ;
   Dialog.Add(UseGridLabel)                                          ;

   UseGridValue.Create(0, "UseGridValue", 0, 320, 105, 0, 0)                   ;
   UseGridValue.Text(UseGrid)                                        ;
   UseGridValue.FontSize(9)                                          ;
   Dialog.Add(UseGridValue)                                          ;
   
   LegsLabel.Create(0, "LegsLabel", 0, 250, 125, 0, 0)                   ;
   LegsLabel.Text("Legs: ")                                        ;
   LegsLabel.FontSize(9)                                          ;
   Dialog.Add(LegsLabel)                                          ;

   LegsValue.Create(0, "LegsValue", 0, 320, 125, 0, 0)                   ;
   LegsValue.Text(IntegerToString(0))                                        ;
   LegsValue.FontSize(9)                                          ;
   Dialog.Add(LegsValue)                                          ;
   
   BLegsLabel.Create(0, "BLegsLabel", 0, 250, 145, 0, 0)                   ;
   BLegsLabel.Text("Buy Legs: ")                                        ;
   BLegsLabel.FontSize(9)                                          ;
   Dialog.Add(BLegsLabel)                                          ;

   BLegsValue.Create(0, "BLegsValue", 0, 320, 145, 0, 0)                   ;
   BLegsValue.Text(IntegerToString(0))                                        ;
   BLegsValue.FontSize(9)                                          ;
   Dialog.Add(BLegsValue)                                          ;
   
   SLegsLabel.Create(0, "SLegsLabel", 0, 250, 165, 0, 0)                   ;
   SLegsLabel.Text("Sell Legs: ")                                        ;
   SLegsLabel.FontSize(9)                                          ;
   Dialog.Add(SLegsLabel)                                          ;

   SLegsValue.Create(0, "SLegsValue", 0, 320, 165, 0, 0)                   ;
   SLegsValue.Text(IntegerToString(0))                                        ;
   SLegsValue.FontSize(9)                                          ;
   Dialog.Add(SLegsValue)                                          ;
   
//   NPLabel.Create(0, "NPLabel", 0, 250, 185, 0, 0)                   ;
//   NPLabel.Text("Next Leg @ : ")                                        ;
//   NPLabel.FontSize(9)                                          ;
//   Dialog.Add(NPLabel)                                          ;
//
//   NPValue.Create(0, "NPValue", 0, 320, 185, 0, 0)                   ;
//   NPValue.Text(0)                                        ;
//   NPValue.FontSize(9)                                          ;
//   Dialog.Add(NPValue)                                          ;


   InputLabels[1].Create(0, "LotsLabel", 0, 5, 65, 0, 0)                ;
   InputLabels[1].Text("Lots: ")                                  ;
   InputLabels[1].FontSize(9)                                     ;
   Dialog.Add(InputLabels[1])                                     ;

   Inputs[1].Create(0, "LotsEdit", 0, 125, 65, 0, 0)                    ;
   Inputs[1].Text(""+(string)Lot_Size)                                          ;
   Inputs[1].FontSize(9)                                          ;
   Inputs[1].Height(20)                                           ;
   Inputs[1].Width(100)                                           ;
   Dialog.Add(Inputs[1])                                          ;

   InputLabels[2].Create(0, "TPPLabel", 0, 5, 85, 0, 0)                 ;
   InputLabels[2].Text("TP points: ")                             ;
   InputLabels[2].FontSize(9)                                     ;
   Dialog.Add(InputLabels[2])                                     ;

   Inputs[2].Create(0, "TPPEdit", 0, 125, 85, 0, 0)                     ;
   Inputs[2].Text(""+(string) Tp_Fix)                                          ;
   Inputs[2].FontSize(9)                                          ;
   Inputs[2].Height(20)                                           ;
   Inputs[2].Width(100)                                           ;
   Dialog.Add(Inputs[2])                                          ;
   
   InputLabels[3].Create(0, "SLPLabel", 0, 5, 105, 0, 0)                 ;
   InputLabels[3].Text("SL points: ")                             ;
   InputLabels[3].FontSize(9)                                     ;
   Dialog.Add(InputLabels[3])                                     ;

   Inputs[3].Create(0, "SLPEdit", 0, 125, 105, 0, 0)                     ;
   Inputs[3].Text(""+(string) Tp_Fix)                                          ;
   Inputs[3].FontSize(9)                                          ;
   Inputs[3].Height(20)                                           ;
   Inputs[3].Width(100)                                           ;
   Dialog.Add(Inputs[3])                                          ;

   InputLabels[4].Create(0, "TPDLabel", 0, 5, 125, 0, 0)                ;
   InputLabels[4].Text("TP$: ")                                   ;
   InputLabels[4].FontSize(9)                                     ;
   Dialog.Add(InputLabels[4])                                     ;

   Inputs[4].Create(0, "TPDEdit", 0, 125, 125, 0, 0)                    ;
   Inputs[4].Text(""+(string)TP_Money)                                          ;
   Inputs[4].FontSize(9)                                          ;
   Inputs[4].Height(20)                                           ;
   Inputs[4].Width(100)                                           ;
   Dialog.Add(Inputs[4])                                          ;

   InputLabels[5].Create(0, "SLDLabel", 0, 5, 145, 0, 0)                ;
   InputLabels[5].Text("SL$: ")                                   ;
   InputLabels[5].FontSize(9)                                     ;
   Dialog.Add(InputLabels[5])                                     ;

   Inputs[5].Create(0, "SLDEdit", 0, 125, 145, 0, 0)                    ;
   Inputs[5].Text(""+ (string)SL_Money)                                          ;
   Inputs[5].FontSize(9)                                          ;
   Inputs[5].Height(20)                                           ;
   Inputs[5].Width(100)                                           ;
   Dialog.Add(Inputs[5])                                          ;

   InputLabels[6].Create(0, "ThreshLabel", 0, 5, 165, 0, 0)             ;
   InputLabels[6].Text("Threshold: ")                             ;
   InputLabels[6].FontSize(9)                                     ;
   Dialog.Add(InputLabels[6])                                     ;

   Inputs[6].Create(0, "ThreshEdit", 0, 125, 165, 0, 0)                 ;
   Inputs[6].Text(""+(string)Entry_Threshold)                                          ;
   Inputs[6].FontSize(9)                                          ;
   Inputs[6].Height(20)                                           ;
   Inputs[6].Width(100)                                           ;
   Dialog.Add(Inputs[6])                                          ;

   InputLabels[7].Create(0, "TimeLabel", 0, 5, 185, 0, 0)             ;
   InputLabels[7].Text("Entry Time: ")                             ;
   InputLabels[7].FontSize(9)                                     ;
   Dialog.Add(InputLabels[7])                                     ;

   Inputs[7].Create(0, "TimeEdit", 0, 125, 185, 0, 0)                 ;
   Inputs[7].Text(""+(string)Entry_Time)                                          ;
   Inputs[7].FontSize(9)                                          ;
   Inputs[7].Height(20)                                           ;
   Inputs[7].Width(100)                                           ;
   Dialog.Add(Inputs[7])                                          ;
   
   MannualEntryBtn[2].Create(0, "Close_Btn", 0, 6, 245, 0, 0)           ;
   MannualEntryBtn[2].Text("Close")                               ;
   MannualEntryBtn[2].Height(28)                                  ;
   MannualEntryBtn[2].Width(114)                                  ;
   MannualEntryBtn[2].Color(clrWhite)                           ;
   MannualEntryBtn[2].ColorBackground(clrBlue)       ;
   MannualEntryBtn[2].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[2])                                 ;

   MannualEntryBtn[3].Create(0, "Reset_Btn", 0, 6+110, 245, 0, 0)           ;
   MannualEntryBtn[3].Text("Reset")                               ;
   MannualEntryBtn[3].Height(28)                                  ;
   MannualEntryBtn[3].Width(114)                                  ;
   MannualEntryBtn[3].Color(clrWhite)                           ;
   MannualEntryBtn[3].ColorBackground(clrRed)       ;
   MannualEntryBtn[3].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[3])                                 ;

   MannualEntryBtn[4].Create(0, "Ok_Btn", 0, 6, 273, 0, 0)           ;
   MannualEntryBtn[4].Text("Apply Parameters")                               ;
   MannualEntryBtn[4].Height(28)                                  ;
   MannualEntryBtn[4].Width(224)                                  ;
   MannualEntryBtn[4].Color(clrBlack)                           ;
   MannualEntryBtn[4].ColorBackground(clrLime)       ;
   MannualEntryBtn[4].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[4])                                 ;

   MannualEntryBtn[7].Create(0, "Buy_Btn", 0, 6, 300, 0, 0)           ;
   MannualEntryBtn[7].Text("Buy")                               ;
   MannualEntryBtn[7].Height(28)                                  ;
   MannualEntryBtn[7].Width(114)                                  ;
   MannualEntryBtn[7].Color(clrWhite)                           ;
   MannualEntryBtn[7].ColorBackground(clrBlue)       ;
   MannualEntryBtn[7].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[7])                                 ;

   MannualEntryBtn[8].Create(0, "Sell_Btn", 0, 6+110, 300, 0, 0)           ;
   MannualEntryBtn[8].Text("Sell")                               ;
   MannualEntryBtn[8].Height(28)                                  ;
   MannualEntryBtn[8].Width(114)                                  ;
   MannualEntryBtn[8].Color(clrWhite)                           ;
   MannualEntryBtn[8].ColorBackground(clrRed)       ;
   MannualEntryBtn[8].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[8])                                 ;



}
//+------------------------------------------------------------------+
