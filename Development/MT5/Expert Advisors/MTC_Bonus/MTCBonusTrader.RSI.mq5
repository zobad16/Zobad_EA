//+------------------------------------------------------------------+
//|                                               MTCBonusTrader.mq5 |
//|                                  Copyright 2022, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2022, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Controls\Button.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Label.mqh>
CDialog Dialog;
CButton MannualEntryBtn [3];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
CButton StartBtn[2];
CLabel  Labels[6];
CLabel  LabelsValues[6];
CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CTrade trade;
CTerminalInfo  TerminalInfo;
enum BBM
{
   DIRECTIONAL=0,
   REVERSAL=1




};
enum E_Grid_Direction
{

Grid_Long=0,//Long
Grid_Short=1,//Short
Grid_Both=2//Both



};
enum Tp_Type
{

None=0,//None
Fixed=1,//Fix
Average=2//AVG
};
enum E_SST
{
   Directional=0,
   Reversal=1,
   MA_Directional = 2,
   MA_Reversal = 3,
   Open_Now=4,
   Manual =5,
   RSI=6,
};
datetime Expiry=D'2022.12.12 00:00';
bool exp_deliverd = false;
input string  EA_Setting="===== EA Setting =====";
input E_Grid_Direction Grid_Direction=0;//Grid Direction
input bool  Negative_Grid_Enable=true;
input int   magic_num=46598; //Magic Number
input double  Lot_Size=0.01;// Lot Size
input double  Grid_Multiplier=1.25;//Grid Lot Multiplier
E_SST  Strategy_Type=0;//Strategy Type
input string  Comment_Order="MTC-B";//Comment Order
input double  TP_Point=2500;//TP Point
input double  TP_Money=100;//TP $Money
input double  Grid_Risk_Money=100;//Grid Risk $Money
input double  Distance_Point=2500;//Grid Leg Threshold(Points)
input Tp_Type Grid_Tp_Type = None;
input double  Grid_Tp = 2500;
input int  Grid_Max_Legs=10;//Grid Max Legs 
input bool UseCloseLeg = false;//Use Close Leg
input int  CloseLegN   = 5;   //PNL Close N Legs 
input bool UseHedgeNLegs = false; //Use hedge legs after n legs
input int  NLegsHedge    = 5;     //N Leg Hedge 

input string  RSI_Setting="=====  RSI Settings =====";
input int     RSIPeriod       = 14;      // RSI period
input ENUM_TIMEFRAMES RSI_Timeframe = PERIOD_H1; //RSI Timeframe
input ENUM_APPLIED_PRICE  RSI_Applied_Price=PRICE_CLOSE;// RSI Applied Price

 bool   Grid_Hide_all_TP_SL=true;//Grid Hide all TP/SL  
  BBM     Bollinger_Bands_Method=0;// Bollinger Bands
 string  Bollinger_Bands_Setting="=====  Bollinger Bands =====";
 int     BB_Period=20;// Bollinger Bands Period
 double  BB_deviation=2;// Bollinger Bands deviation
 int     BB_Shift=0;// Bollinger Shift
 ENUM_APPLIED_PRICE  BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
 string  MA_Setting="=====  Moving Average =====";
 int     MovingPeriod       = 50;      // Moving Average period
 int     MovingShift        = 0;       // Moving Average shift
 ENUM_MA_METHOD MA_Method   = MODE_EMA; //Moving Average Method
 ENUM_APPLIED_PRICE  MA_Applied_Price=PRICE_CLOSE;// MA Applied Price
double TPB,TPS;
int C_B=-1;
int C_S=-1;
double GB[1000];
double GBL[1000];
double GS[1000];
double GSL[1000];
int Handler_Band;
double UPBB1[];
double DNBB1[];
bool reset;
double point_signal = 0.0;
int    ExtHandle=0;
const int SIGNAL_BUY = 1;
const int SIGNAL_SELL = -1;
const int SIGNAL_NONE = 0;
int handle_rsi =0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   if(CheckExpiry())
   {
      Alert("EA expired. Please contact the developer");
      exp_deliverd=true;
      return(INIT_FAILED);   
   }
   ExtHandle=iMA(_Symbol,_Period,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   handle_rsi = iRSI(Symbol(),RSI_Timeframe,RSIPeriod, RSI_Applied_Price); 
    if(handle_rsi==INVALID_HANDLE)
     {
      printf("Error creating RSI indicator");
      return(INIT_FAILED);
     }
   trade.SetExpertMagicNumber(magic_num);
   Handler_Band=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   Dialog.Create(ChartID(),"                                      ALGOTRADEUP",0,5,5,400,200);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrGold);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   
//---
   TitleBtn.Create(0,"Title",0,5,6,0,0)                              ;
   TitleBtn.Text("Martingale")                                            ;
   TitleBtn.FontSize(12)                                          ;                                    
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(200)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrDarkTurquoise)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   StartBtn[0].Create(0,"AutoStart",0,5,6,0,0)                              ;
   StartBtn[0].Text("Auto Start")                                            ;
   StartBtn[0].FontSize(10)                                          ;                                    
   StartBtn[0].Height(40)                                            ;
   StartBtn[0].Width(100)                                            ;
   StartBtn[0].Color(clrWhite)                                       ;
   StartBtn[0].ColorBackground(clrDarkTurquoise)                             ;
   StartBtn[0].ColorBorder(clrBlack)                                 ;
   StartBtn[1].Create(0,"ManualStart",0,105,6,0,0)                              ;
   StartBtn[1].Text("Manual Start")                                            ;
   StartBtn[1].FontSize(10)                                          ;                                    
   StartBtn[1].Height(40)                                            ;
   StartBtn[1].Width(100)                                            ;
   StartBtn[1].Color(clrWhite)                                       ;
   StartBtn[1].ColorBackground(clrDarkTurquoise)                             ;
   StartBtn[1].ColorBorder(clrBlack)                                 ;
   
   
   CloseAllBtn.Create(0,"CloseAll",0,5,120,0,0)                      ;
   CloseAllBtn.Text("Close All")                                     ;
   CloseAllBtn.FontSize(10)                                          ;                                    
   CloseAllBtn.Height(40)                                            ;
   CloseAllBtn.Width(200)                                            ;
   CloseAllBtn.Color(clrBlack)                                       ;
   CloseAllBtn.ColorBackground(clrWhite)                             ;
   CloseAllBtn.ColorBorder(clrBlack)                                 ;
   CloseAllBtn.Pressed(false);
   MannualEntryBtn[0].Create(0,"OpenBuy",0,5,40,0,0)                ;
   MannualEntryBtn[0].Text("Open Buy")                                ;
   MannualEntryBtn[0].FontSize(10)                                    ;                                    
   MannualEntryBtn[0].Height(40)                                      ;
   MannualEntryBtn[0].Width(100)                                      ;
   MannualEntryBtn[0].Color(clrWhite)                                 ;
   MannualEntryBtn[0].ColorBackground(clrBlue)                        ;
   MannualEntryBtn[0].ColorBorder(clrBlack)                           ;
   MannualEntryBtn[0].Pressed(false);
   CloseBuysBtn.Create(0,"CloseBuys",0,5,80,0,0)                      ;
   CloseBuysBtn.Text("Close Buys")                                     ;
   CloseBuysBtn.FontSize(10)                                          ;                                    
   CloseBuysBtn.Height(40)                                            ;
   CloseBuysBtn.Width(100)                                            ;
   CloseBuysBtn.Color(clrWhite)                                       ;
   CloseBuysBtn.ColorBackground(clrBlue)                               ;
   CloseBuysBtn.ColorBorder(clrBlack)                                 ;
   CloseBuysBtn.Pressed(false);
   MannualEntryBtn[1].Create(0,"OpenSell",0,105,40,0,0)                      ;
   MannualEntryBtn[1].Text("Open Sells")                                     ;
   MannualEntryBtn[1].FontSize(10)                                          ;                                    
   MannualEntryBtn[1].Height(40)                                            ;
   MannualEntryBtn[1].Width(100)                                            ;
   MannualEntryBtn[1].Color(clrWhite)                                       ;
   MannualEntryBtn[1].ColorBackground(clrRed)                               ;
   MannualEntryBtn[1].ColorBorder(clrBlack)                                 ;
   MannualEntryBtn[1].Pressed(false);
   reset = false                                                     ; 
   CloseSellsBtn.Create(0,"CloseSells",0,105,80,0,0)                      ;
   CloseSellsBtn.Text("Close Sells")                                     ;
   CloseSellsBtn.FontSize(10)                                          ;                                    
   CloseSellsBtn.Height(40)                                            ;
   CloseSellsBtn.Width(100)                                            ;
   CloseSellsBtn.Color(clrWhite)                                       ;
   CloseSellsBtn.ColorBackground(clrRed)                               ;
   CloseSellsBtn.ColorBorder(clrBlack)                                 ;
   CloseSellsBtn.Pressed(false);
   Dialog.Add(StartBtn[0]);
   Dialog.Add(StartBtn[1]);
   Dialog.Add(TitleBtn);
   Dialog.Add(CloseAllBtn);
   Dialog.Add(MannualEntryBtn[0]);
   Dialog.Add(CloseBuysBtn);
   Dialog.Add(CloseSellsBtn);
   Dialog.Add(MannualEntryBtn[1]);
   Labels[0].Create(0,"NetPnl",0,230,5,30,0);
   Labels[0].Text("Net PNL$: ");
   Labels[0].FontSize(10);
   Dialog.Add(Labels[0]);
   LabelsValues[0].Create(0,"NetPnlValue",0,320,5,30,0);
   LabelsValues[0].Text("0");
   LabelsValues[0].FontSize(10);
   Dialog.Add(LabelsValues[0]);
   Labels[1].Create(0,"BPnlLbl",0,230,25,30,0);
   Labels[1].Text("Buy PNL:");
   Labels[1].FontSize(10);
   Dialog.Add(Labels[1]);
   LabelsValues[1].Create(0,"BPnlValue",0,320,25,30,0);
   LabelsValues[1].Text("0.00");
   LabelsValues[1].FontSize(10);
   Dialog.Add(LabelsValues[1]);
   Labels[2].Create(0,"SPnlLbl",0,230,45,30,0);
   Labels[2].Text("Sell PNL:");
   Labels[2].FontSize(10);
   Dialog.Add(Labels[2]);
   LabelsValues[2].Create(0,"SPnlValue",0,320,45,30,0);
   LabelsValues[2].Text("-");
   LabelsValues[2].FontSize(10);
   Dialog.Add(LabelsValues[2]);
   Labels[3].Create(0,"NetLegsLbl",0,230,65,30,0);
   Labels[3].Text("Net Legs: ");
   Labels[3].FontSize(10);
   Dialog.Add(Labels[3]);
   LabelsValues[3].Create(0,"NetLegsValue",0,320,65,30,0);
   LabelsValues[3].Text("0.0");
   LabelsValues[3].FontSize(10);
   Dialog.Add(LabelsValues[3]);
   Labels[4].Create(0,"BLegsLbl",0,230,85,30,0);
   Labels[4].Text("Buy Legs: ");
   Labels[4].FontSize(10);
   Dialog.Add(Labels[4]);
   LabelsValues[4].Create(0,"BLegsValue",0,320,85,30,0);
   LabelsValues[4].Text("0.0");
   LabelsValues[4].FontSize(10);
   Dialog.Add(LabelsValues[4]);
   Labels[5].Create(0,"SlegsLbl",0,230,105,30,0);
   Labels[5].Text("Sell Legs: ");
   Labels[5].FontSize(10);
   Dialog.Add(Labels[5]);
   LabelsValues[5].Create(0,"SLegsValue",0,320,105,30,0);
   LabelsValues[5].Text("0.0");
   LabelsValues[5].FontSize(10);
   Dialog.Add(LabelsValues[5]);
   
   EventSetMillisecondTimer(300);
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
   Dialog.Destroy(reason);
   EventKillTimer();

}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer(){
   if(!TerminalInfo.IsTradeAllowed() || exp_deliverd)
      return;
   int b_count =0, s_count =0;   
   int orders = CalculateCurrentOrders2( b_count, s_count);
   double bpnl = 0.0, spnl = 0.0;
   double pnl = GetPnl(bpnl,spnl);
   string dir = "";
   int op = -99;
   if(Grid_Direction == Grid_Long)        {dir = "Long";op= POSITION_TYPE_BUY;}
   else if(Grid_Direction == Grid_Short)  {dir = "Short";op= POSITION_TYPE_SELL;}
   else if(Grid_Direction == Grid_Both)   dir = "Both";
   point_signal = PointsSignal(op);
   
   LabelsValues[0].Text(DoubleToString(pnl,2));
   LabelsValues[1].Text(DoubleToString(bpnl,2));
   LabelsValues[2].Text(DoubleToString(spnl,2));
   LabelsValues[3].Text(IntegerToString(orders));
   LabelsValues[4].Text(IntegerToString(b_count));
   LabelsValues[5].Text(IntegerToString(s_count));
}
bool CheckExpiry()
{
   MqlDateTime str1, str2;
   TimeToStruct(Expiry,str1);
   TimeToStruct(TimeCurrent(),str2);  
   if(str2.day >= str1.day && str2.mon >= str1.mon && str2.year >= str1.year)
      return true;
   else
      return false;   
}
void OnTick()
{
//---
   if(!TerminalInfo.IsTradeAllowed())
      return;
   if(CheckExpiry())
   {
      Alert("EA expired. Please contact the developer");
      exp_deliverd=true;
      return;   
   }   
   int orders_total = 0;
   int b_legs = 0, s_legs =0;
   orders_total = CalculateCurrentOrders2(b_legs,s_legs);   
   if(orders_total==0){
      Refresh_Sell();
      Refresh_Buy();
   }
   if(TP_Point!=0)
   {
      TPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
      TPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();


   }
   else
   {
      TPB=0;
      TPS=0;
   }
   int ma_signal = MA_Check();    
   if(Strategy_Type == Manual && orders_total>0 && b_legs==0 && Grid_Direction == Grid_Both)
   {
      Refresh_Buy();
      Refresh_Sell();
      if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
         C_B=0;
         GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL[C_B]=Lot_Size;
      } 
   }      
   if(Strategy_Type == Manual && orders_total>0 && s_legs==0&& Grid_Direction == Grid_Both) 
   {
      Refresh_Sell();
      Refresh_Buy();
      if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order)){
         C_S=0;
         GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL[C_S]=Lot_Size;
      }
     }     
   if((Strategy_Type==Open_Now )&& (Grid_Direction==0||Grid_Direction==2) && b_legs==0)
   {
      Refresh_Buy();
      Refresh_Sell();
      if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
         C_B=0;
         GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL[C_B]=Lot_Size;
      } 
   }
     
   else if((Strategy_Type==Open_Now  )&& (Grid_Direction==1||Grid_Direction==2) && s_legs==0)
    {
      Refresh_Sell();
      Refresh_Buy();
      if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order)){
         C_S=0;
         GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL[C_S]=Lot_Size;
      }
     }
     //MA Entry
     if(orders_total==0){
      if((ma_signal== 1 && (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal)  ))
      {
         Refresh_Sell();
         Refresh_Buy();
         if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
            C_B=0;
            GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL[C_B]=Lot_Size;
         } 
      }
      else if((ma_signal== -1 && (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal) ))
       {
         Refresh_Sell();
         Refresh_Buy();
         if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order)){
            C_S=0;
            GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL[C_S]=Lot_Size;
         }
        }
     
     }
  else    
   
   if(Negative_Grid_Enable)
   {
      int buy_legs =0, sell_legs = 0;
      int total_orders = CalculateCurrentOrders2(buy_legs,sell_legs);
      if(buy_legs>0 &&  total_orders>0 && buy_legs<(Grid_Max_Legs))
      {
         double trigger_price =point_signal;
         /*if(trigger_price == 0)
            return;
         *///GB[C_B] = LastOrderPrice(ORDER_TYPE_BUY);
         //if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)<=(trigger_price) && trigger_price > 0)
         if(LegEntryCheck(POSITION_TYPE_BUY))
         {
            //Alert("Buy Trigger point ="+(string)trigger_price);
            C_B++;
            double lot_prev = CalculateOrderLots(1 );
            double lot_size_T=NormalizeDouble(lot_prev*Grid_Multiplier,2);
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_B)*Lot_Size,2);
            double lots_n = NormalizeDouble(Lot_Size * MathPow(Grid_Multiplier, buy_legs),2);
            double lotStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
            lots_n=MathRound(lots_n/lotStep)*lotStep;
            Print("Previous Lot size: "+(string)lot_prev);
            //if(lot_size_T > lot_size_G)
            //   lot_size_G = lot_size_T;
            if( (Grid_Direction==0||Grid_Direction==2)|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal|| Strategy_Type == Open_Now)){
               double tp =0.0;
               if(Grid_Tp_Type == Fixed){
                  tp = SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
               }
               if(trade.Buy(lots_n,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,tp,Comment_Order)){
                  int cur_legs = buy_legs+1;
                  Print("Opening new buy leg: Total buy legs: "+cur_legs);
                  GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                  GBL[C_B]=lots_n;
                  if(Grid_Tp_Type == Average)BTP_Average();
               }
               else{
                  C_B--;
               }
            
            }
         }
      }
      if(sell_legs>0 &&  total_orders>0 && sell_legs<(Grid_Max_Legs))
      {
         double trigger_price =point_signal ;
         if(LegEntryCheck(POSITION_TYPE_SELL))
         {
            //Alert("Sell Trigger point ="+(string)trigger_price);
            C_S++;
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_S)*Lot_Size,2);
            double lots_n = NormalizeDouble(Lot_Size * MathPow(Grid_Multiplier, sell_legs),2);
            double lotStep=SymbolInfoDouble(_Symbol,SYMBOL_VOLUME_STEP);
            lots_n=MathRound(lots_n/lotStep)*lotStep;
            
            if( (Grid_Direction==1||Grid_Direction==2) || (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal || Strategy_Type == Open_Now)){
               double tp =0.0;
               if(Grid_Tp_Type == Fixed){
                  tp = SymbolInfoDouble(Symbol(),SYMBOL_ASK)-TP_Point*Point();
               }
            
               if(trade.Sell(lots_n,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,tp,Comment_Order)){
                  GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                  GSL[C_S]=lots_n;
                  int cur_legs = sell_legs+1;
                  Print("Opening new sell leg: Total sell legs: "+cur_legs );
                  if(Grid_Tp_Type == Average)STP_Average();
               }
               else{
                  C_S--;
               }
            }
         }
      }
   }
   
   if( orders_total==0 /*&& iVolume(NULL,PERIOD_CURRENT,0)<=1*/)
   {
      if(BB_Check()==1 &&  orders_total==0)
      {
         Refresh_Sell();
          if( (Grid_Direction==0||Grid_Direction==2)){
            if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
               C_B=0;
               GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
               GBL[C_B]=Lot_Size;
            } 
          }
         
         
      }

      if(BB_Check()==-1 &&  orders_total==0)
      {
         Refresh_Buy();
          if( (Grid_Direction==1||Grid_Direction==2)){
            if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order)){
               C_S=0;
               GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
               GSL[C_S]=Lot_Size;   
            }
          }
      }
   }
   if(orders_total>0){
      if(UseCloseLeg){
         int buy_legs =0, sell_legs = 0;
         int total_orders = CalculateCurrentOrders2(buy_legs,sell_legs);
         if(buy_legs >= CloseLegN){
            Alert("Closing buy legs.");
            CloseAllPositions(POSITION_TYPE_BUY);
         }
         else if(sell_legs >= CloseLegN){
            CloseAllPositions(POSITION_TYPE_SELL);
            Alert("Closing sell legs.");
         }      
      }
      if(UseHedgeNLegs){
         HedgeLegsMonitor();
      }
      CheckLoss();
      CheckProfit();
   }
}
int CheckEntrySignal(){
   //RSI Signal check
   /*int  iRSI(
   string              symbol,            // symbol name
   ENUM_TIMEFRAMES     period,            // period
   int                 ma_period,         // averaging period
   ENUM_APPLIED_PRICE  applied_price      // type of price or handle
   );*/
   if(Strategy_Type == RSI){
      double rsi_buffer[];
      ArraySetAsSeries(rsi_buffer, true);
      if (CopyBuffer(handle_rsi,0,0,20,rsi_buffer) < 0){Print("CopyBufferRSI error =",GetLastError());}
      
      if(Grid_Direction == Grid_Long || Grid_Direction == Grid_Both){
         if(rsi_buffer[0] > 50){
            return SIGNAL_BUY;
         }
      }
      else if(Grid_Direction == Grid_Short || Grid_Direction == Grid_Both){
         if(rsi_buffer[0] < 50){
            return SIGNAL_SELL;
         }
      }
   }
   //Moving Average signal
   
   
   //Manual
   
   return SIGNAL_NONE;
}
//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
   if(!TerminalInfo.IsTradeAllowed())
      return;
//---
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
      
    if(sparam == "AutoStart"){
      MessageBox("Switching to auto mode")                           ;
      StartBtn[0].Pressed(false);
      Strategy_Type = Open_Now;
    }
    if(sparam == "ManualStart"){
      MessageBox("Switching to manual mode")                           ;
      StartBtn[1].Pressed(false);
      Strategy_Type = Manual;
      Print(Strategy_Type);
    }  
    if(sparam=="CloseAll") // Close all
    {
        MessageBox("Closing All Orders!")                           ;
        CloseAllPositions();
        CloseAllBtn.Pressed(false);
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
    }
    if(sparam=="OpenBuy") // Close Buys
    {
        MannualEntryBtn[0].Pressed(false);
        MessageBox("Opening Buy Order!")                           ;
        MannualEntry(ORDER_TYPE_BUY);
        Print("Opened Buy Position");
    }
    if(sparam=="CloseBuys") // Close Buys
    {
        CloseBuysBtn.Pressed(false);
        MessageBox("Closing All Buy Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_BUY);
        Print("Close All Buy Orders event");
        reset = true;
        Refresh_Buy();
    }
    if(sparam=="OpenSell") // Close Buys
    {
        MannualEntryBtn[1].Pressed(false);
        MessageBox("Opening Sell Order!")                           ;
        MannualEntry(ORDER_TYPE_SELL);
        Print("Opened Sell Position");
    }
    if(sparam=="CloseSells") // Close Sells
    {
        CloseSellsBtn.Pressed(false);
        MessageBox("Closing All sell Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_SELL);
        Print("Close All Sell Orders event");
        reset = true;
        Refresh_Sell();
    }
    
   }
    ChartRedraw();
   
}
void HedgeLegsMonitor(){
   int b_legs=0, s_legs=0, bh_leg =0, sh_leg =0;
   double b_lots=0.0, s_lots =0.0, bh_lots =0.0, sh_lots =0;
   int total = CalculateCurrentOrders2(b_legs,b_lots,s_legs,s_lots,bh_leg,bh_lots,sh_leg,sh_lots);
   
   //Print("BUY["+IntegerToString(b_legs)+"] SELL["+IntegerToString(s_legs)+"] Total["+IntegerToString(total)+"]");
   if(b_legs >= NLegsHedge){
      if(sh_leg == 0){
         if(trade.Sell(b_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Comment_Order+"-Hedge")){
            SetTpToZero(POSITION_TYPE_BUY);
         }
      }
      //Check if next buy hedge needs to be open
      if(sh_leg>=1){
         int rounded_legs = round((b_legs/NLegsHedge));
        // Alert("Locking buy- Rounded legs["+rounded_legs+"]");
        //Print("Locking buy- Rounded legs["+rounded_legs+"]Hedged Sells["+sh_leg+"]");
         if(rounded_legs > sh_leg){
            Print("Locking buy- Rounded legs["+rounded_legs+"] Hedged Sells["+sh_leg+"]");
            double new_lots = b_lots - sh_lots; 
            if(trade.Sell(new_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Comment_Order+"-Hedge")){
               SetTpToZero(POSITION_TYPE_BUY);
            }
         }     
      }
      
   }
   if(s_legs >= NLegsHedge){
      if(bh_leg == 0){
         if(trade.Buy(s_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,NULL,Comment_Order+"-Hedge")){
            SetTpToZero(POSITION_TYPE_SELL);
         }
      }
      
      if(bh_leg>=1){
         int rounded_legs = round((s_legs/NLegsHedge));
         //Print("Locking sell- Rounded legs["+rounded_legs+"]Hedged Buys["+bh_leg+"]");
         if(rounded_legs > bh_leg){
            Print("Locking sell- Rounded legs["+rounded_legs+"]");
            double new_lots = b_lots - bh_lots; 
            if(trade.Sell(new_lots,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Comment_Order+"-Hedge")){
               SetTpToZero(POSITION_TYPE_SELL);
            }
         }     
      } 
   }

}
void SetTpToZero(int op){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE) == op)
            trade.PositionModify(PositionGetTicket(i),NULL,NULL);
      }
   }
}
double PointsSignal(int op){
   int legs = CalculateCurrentOrders2( );
   double Grid_Leg_Threshold = Distance_Point;
   //Print("Opened Legs: "+legs);
    double last_price = LastOrderPrice(op);
    double next_price = 0.0;
    MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    else
    {
       double _ask=tick.ask;
       double _bid=tick.bid;;
         if(op == POSITION_TYPE_BUY){
            next_price = (last_price-  Grid_Leg_Threshold*Point());     
         }
         else if(op == POSITION_TYPE_SELL){
            if(_ask >= last_price+ Grid_Leg_Threshold*Point()){
               next_price = (last_price+Grid_Leg_Threshold*Point());
            }
         }
        return next_price; 
     }    
   //return 0.0;
}
//+------------------------------------------------------------------+
int BB_Check()
{
   if(Strategy_Type == Directional || Strategy_Type == Reversal ){
      int k=0;
      MqlTick tick;
       if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
       double Ask=tick.ask;
       double Bid=tick.bid;
       
      CopyBuffer(Handler_Band,1,0,1,UPBB1);
      CopyBuffer(Handler_Band,2,0,1,DNBB1);
      if(Ask>=UPBB1[0] && Bollinger_Bands_Method==0)
         k=1;
      if(Ask>=UPBB1[0] && Bollinger_Bands_Method==1)
         k=-1;
      if(iOpen(NULL,PERIOD_CURRENT,1)<=UPBB1[0] && iClose(NULL,PERIOD_CURRENT,1)>=UPBB1[0] && Bollinger_Bands_Method==0)
         k=1;
         
      if(iOpen(NULL,PERIOD_CURRENT,1)<=UPBB1[0] && iClose(NULL,PERIOD_CURRENT,1)>=UPBB1[0] && Bollinger_Bands_Method==1)
         k=-1;
      if(Bid<=DNBB1[0] && Bollinger_Bands_Method==0)
         k=-1;   
      if(Bid<=DNBB1[0] && Bollinger_Bands_Method==1)
         k=1;   
      if(iOpen(NULL,PERIOD_CURRENT,1)>=DNBB1[0] && iClose(NULL,PERIOD_CURRENT,1)<=DNBB1[0] && Bollinger_Bands_Method==0)
         k=-1;
      if(iOpen(NULL,PERIOD_CURRENT,1)>=DNBB1[0] && iClose(NULL,PERIOD_CURRENT,1)<=DNBB1[0] && Bollinger_Bands_Method==1)
         k=1;
      return(k);
      
   }
   return 0;
}
bool LegEntryCheck(){
   int orders_buy = 0;
   int orders_sell = 0;
   int orders_total = CalculateCurrentOrders2(orders_buy,orders_sell);
   double distance = Distance_Point * Point();
   if(orders_total == 0 || orders_total == Grid_Max_Legs)
      return false;
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return false; }
   double Ask=tick.ask;
   double Bid=tick.bid;
   
   if(orders_buy > 0){
      double price = LastOrderPrice(POSITION_TYPE_BUY);
      if(Bid <= price - distance ){
         Print("BUY-Leg Entry["+IntegerToString(orders_total+1)+"]: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
         
       else return false;  
   }
   if(orders_sell > 0){
      double price = LastOrderPrice(POSITION_TYPE_SELL);
      if(Ask >= price + distance ){
         Print("SELL-Leg Entry["+IntegerToString(orders_total+1)+"]: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
       else return false;  
   }
   return false;
}
bool LegEntryCheck(int op){
   int orders_buy = 0;
   int orders_sell = 0;
   int orders_total = CalculateCurrentOrders2(orders_buy,orders_sell);
   double distance = Distance_Point * Point();
   if(orders_total == 0 || orders_total == Grid_Max_Legs)
      return false;
   
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return false; }
   double Ask=tick.ask;
   double Bid=tick.bid;
   
   if(op == POSITION_TYPE_BUY && orders_buy > 0 && (Grid_Direction == Grid_Long || Grid_Direction == Grid_Both)){
      double price = LastOrderPrice(POSITION_TYPE_BUY);
      if(Bid <= price - distance ){
         Print("BUY-Leg Entry["+IntegerToString(orders_total+1)+"]: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
         
       else return false;  
   }
   if(op == POSITION_TYPE_SELL && orders_sell > 0 && (Grid_Direction == Grid_Short || Grid_Direction == Grid_Both)){
      double price = LastOrderPrice(POSITION_TYPE_SELL);
      if(Ask >= price + distance ){
         Print("SELL-Leg Entry["+IntegerToString(orders_total+1)+"]: Last Price["+DoubleToString(price)+"] ");
         return true;
      }
       else return false;  
   }
   return false;
}
int MA_Check()
{
    if(Strategy_Type==MA_Directional || Strategy_Type == MA_Reversal){
      int signal = 0;
      double   ma[1];
      if(CopyBuffer(ExtHandle,0,0,1,ma)!=1)
        {
         Print("CopyBuffer from iMA failed, no data");
         return 0;
        }
      double open = iOpen(Symbol(),0,0);    
      int k=0;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
       double Ask=tick.ask;
       double Bid=tick.bid;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Directional  )signal = 1;
      else if((Bid <= ma[0] && open > ma[0])&& Strategy_Type==MA_Directional) signal = -1;
      if((Ask >= ma[0] && open < ma[0]) && Strategy_Type==MA_Reversal  )signal = -1;
      else if((Bid <=ma[0] && open > ma[0])&& Strategy_Type==MA_Reversal) signal = 1;
      return signal;   
    }
   else{
      return 0;
   }
   
   
   

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
double GetPnl(){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
double GetPnl(double &buy ,double &sell){
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol()){
               long pos_type = PositionGetInteger(POSITION_TYPE);
               double profit =PositionGetDouble(POSITION_PROFIT);
               double swap = PositionGetDouble(POSITION_SWAP);
               
               if(pos_type == POSITION_TYPE_BUY ){
                  buy+=profit+swap;
               }
               else if(pos_type == POSITION_TYPE_SELL){
                  sell += profit+swap;
               }
               num=num+profit+swap;
            }
      }
   }
   return num;
}
//+------------------------------------------------------------------+
void CheckLoss()
{
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   if(num<Grid_Risk_Money*(-1))
   {
      Refresh_Buy();
      Refresh_Sell();
      CloseAllPositions();
      Print("Negative Grid-"+Symbol()+"-Risk $ reached -"+(string)Grid_Risk_Money+". Closing positions ...");
      Alert("Negative Grid-"+Symbol()+"-Risk $ reached -"+(string)Grid_Risk_Money+". Closing positions ...");
      C_B=-1;
      C_S=-1;
   }


}
//+------------------------------------------------------------------+
void CheckProfit()
{
   double  num=0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   if(num>=TP_Money)
   {
      Refresh_Buy();
      Refresh_Sell();
      CloseAllPositions();
      Print("Negative Grid-"+Symbol()+"-Profit $ reached -"+(string)TP_Money+". Closing positions ...");
      Alert("Negative Grid-"+Symbol()+"-Profit $ reached -"+(string)TP_Money+". Closing positions ...");
      C_B=-1;
      C_S=-1;
   }


}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void BTP_Average()
{
   double LotT=0;
   double num=0;
   double P_Avg=0;
   for(int i=0; i<=C_B; i++)
   {
      num=num+GB[i]*GBL[i];
      LotT=GBL[i]+LotT;

   }
   P_Avg=NormalizeDouble(num/LotT,Digits());
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==0)
            trade.PositionModify(PositionGetTicket(i),NULL,P_Avg+TP_Point*Point());

      }
   }
}
//+------------------------------------------------------------------+
void STP_Average()
{
   double LotT=0;
   double num=0;
   double P_Avg=0;
   for(int i=0; i<=C_S; i++)
   {
      num=num+GS[i]*GSL[i];
      LotT=GSL[i]+LotT;

   }
   P_Avg=NormalizeDouble(num/LotT,Digits());
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==1)
            trade.PositionModify(PositionGetTicket(i),NULL,P_Avg-TP_Point*Point());

      }
   }
}
//+------------------------------------------------------------------+
void Refresh_Buy()
{
   ArrayFill(GB,0,1000,0);
   ArrayFill(GBL,0,1000,0);
   C_B=-1;


}
//+------------------------------------------------------------------+
void Refresh_Sell()
{
   ArrayFill(GS,0,1000,0);
   ArrayFill(GSL,0,1000,0);
   C_S=-1;


}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
int CalculateCurrentOrders( int TT)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==TT && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


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
      return k;
   

}
//+------------------------------------------------------------------+
int CalculateCurrentOrders2( )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)==Comment_Order)
            k++;
      }

   }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c , int &sell_c )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_COMMENT)== Comment_Order){
            long op = PositionGetInteger(POSITION_TYPE);
            if(op == POSITION_TYPE_BUY){
               buy_c++;
            }
            if(op == POSITION_TYPE_SELL){
               sell_c++;
            }
            k++;
         }
            
      }

   }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c, double &lots_b , int &sell_c , double &lots_s)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num) 
            if(PositionGetString(POSITION_COMMENT)==Comment_Order){
               long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  buy_c++;
                  lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  sell_c++;
                  lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
        }           
      }
   return(k);


}
int CalculateCurrentOrders2(int &buy_c, double &lots_b , int &sell_c , double &lots_s, int &h_legs_b, double &h_lots_b,int &h_legs_s, double &h_lots_s)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num) 
            if(PositionGetString(POSITION_COMMENT) ==Comment_Order ){
               long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  buy_c++;
                  lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  sell_c++;
                  lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
            if(PositionGetString(POSITION_COMMENT) == (Comment_Order+"-Hedge")){
            long op = PositionGetInteger(POSITION_TYPE);
               if(op == POSITION_TYPE_BUY){
                  h_legs_b++;
                  h_lots_b+= PositionGetDouble(POSITION_VOLUME);
               }
               if(op == POSITION_TYPE_SELL){
                  h_legs_s++;
                  h_lots_s+= PositionGetDouble(POSITION_VOLUME);
               }
               k++;
            }
         }                     
      }
   return(k);


}
/*double CalculateOrderLots(){
   double lots = 0.0;
   lots = CalculateCurrentOrderLots(1);
   int legs = CalculateCurrentOrders2();   
   legs++;
   if()
   return lots;

}*/
double CalculateOrderLots(int mode =1 )
{

//---
   int k=0;
   double h_lot = 0.0, l_lot =1.0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num)
            {
               if(PositionGetDouble(POSITION_VOLUME)> h_lot)
                  h_lot = PositionGetDouble(POSITION_VOLUME);
               if(PositionGetDouble(POSITION_VOLUME)< l_lot)
                  l_lot = PositionGetDouble(POSITION_VOLUME); 
               k++;     
            }
      }

   }
   if(mode == 1)
      return h_lot;
   else if(mode == -1)
      return l_lot;   
   if(k == 0)
      return 0.0;      
   return -1.00;   
  // return(k);


}
//+------------------------------------------------------------------+
void close(int TT)
{

//---

   for(int i=0; i<=PositionsTotal(); i++)
   {
      //if(!PositionGetTicket(i)) break;
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE)==TT)
            trade.PositionClose(PositionGetTicket(i));
      }
      
   }
   if(POSITION_TYPE_BUY)Refresh_Buy();
   else if(POSITION_TYPE_SELL)Refresh_Sell();


//---
}
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }
void CloseAllPositions(int op)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            }
            else{
               Refresh_Buy();
               Refresh_Sell();
            }   
  }  
void CloseAll()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      //if(!PositionGetTicket(i)) break;
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num )
            trade.PositionClose(PositionGetTicket(i));
      }
      
   }
   Refresh_Buy();
   Refresh_Sell();
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op)
{
   if(op == ORDER_TYPE_BUY){
      if(CalculateCurrentOrders(ORDER_TYPE_BUY)==0 && (Grid_Direction==Grid_Long||Grid_Direction==Grid_Both)){
         Refresh_Sell();
         if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
            C_B=0;
            GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL[C_B]=Lot_Size;
         }
         
      }
         
         
   }
   
   else if(op == ORDER_TYPE_SELL && (Grid_Direction==Grid_Short||Grid_Direction==Grid_Both)){
      if(CalculateCurrentOrders(ORDER_TYPE_SELL)==0)
      {
         Refresh_Buy();
         if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order)){
            C_S=0;
            GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL[C_S]=Lot_Size;
         
         }
         
      }
   }

}
