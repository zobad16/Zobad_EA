//+------------------------------------------------------------------+
//|                                                BB_Grid_Ea_V2.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup Ltd."
#property link      "https://www.algotradeup.com"
#property version   "1.00"
#property strict
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
CLabel  Labels[4];
CLabel  LabelsValues[4];
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
enum E_SST
{
   Directional=0,
   Reversal=1,
   MA_Directional = 2,
   MA_Reversal = 3,
   Open_Now=4,
};
enum Stop_Types
{
   None=0,
   Fix=1,
   ATR=2
};
datetime Expiry=D'2022.03.10 00:00';
bool exp_deliverd = false;
input string  EA_Setting="===== EA Setting =====";
input E_Grid_Direction Grid_Direction=0;//Grid Direction
input bool  Negative_Grid_Enable=true; //Use grid
input int   magic_num=46598; //Magic Number
input double  Lot_Size=0.01;// Lot Size
input E_SST  Strategy_Type=0;//Strategy Type
input string  Comment_Order="BB_Grid";//Comment Order
input Stop_Types Tp_Type = Fix;
input double  TP_Point=100;//TP Point
input double  TP_Money=100;//TP $Money
input Stop_Types Sl_Type = ATR;
input double  SL_Value = 1.2;
input double  Grid_Risk_Money=100;//Grid Risk $Money
input double  Distance_Point=50;//Grid Leg Threshold(Points)
input int  Grid_Max_Legs=10;//Grid Max Legs 
input BBM     Bollinger_Bands_Method=0;// Bollinger Bands
input double  Grid_Multiplier=1.25;//Grid Multiplier
input bool   Grid_Hide_all_TP_SL=true;//Grid Hide all TP/SL  
input string  Bollinger_Bands_Setting="=====  Bollinger Bands =====";
input int     BB_Period=20;// Bollinger Bands Period
input double  BB_deviation=2;// Bollinger Bands deviation
input int     BB_Shift=0;// Bollinger Shift
input ENUM_APPLIED_PRICE  BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
input string  MA_Setting="=====  Moving Average =====";
input int     MovingPeriod       = 50;      // Moving Average period
input int     MovingShift        = 0;       // Moving Average shift
input ENUM_MA_METHOD MA_Method   = MODE_EMA; //Moving Average Method
input ENUM_APPLIED_PRICE  MA_Applied_Price=PRICE_CLOSE;// MA Applied Price
input string  ATR_Setting="=====  ATR =====";
input int     ATR_Period = 14;
double TPB,TPS;
double SLB,SLS;
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
int    atr_handle = 0;

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
   ExtHandle=iMA(NULL,0,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ExtHandle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   trade.SetExpertMagicNumber(magic_num);
   Handler_Band=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   if(Handler_Band==INVALID_HANDLE)
     {
      printf("Error creating BB indicator");
      return(INIT_FAILED);
     }
   atr_handle = iATR(NULL,PERIOD_CURRENT, ATR_Period);
   if(atr_handle==INVALID_HANDLE)
     {
      printf("Error creating ATR indicator");
      return(INIT_FAILED);
     }
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
   
   Dialog.Add(TitleBtn);
   Dialog.Add(CloseAllBtn);
   Dialog.Add(MannualEntryBtn[0]);
   Dialog.Add(CloseBuysBtn);
   Dialog.Add(CloseSellsBtn);
   Dialog.Add(MannualEntryBtn[1]);
   
   Labels[0].Create(0,"LegsLbl",0,230,5,30,0);
   Labels[0].Text("LEGS #: ");
   Labels[0].FontSize(10);
   Dialog.Add(Labels[0]);
   LabelsValues[0].Create(0,"LegsValue",0,320,5,30,0);
   LabelsValues[0].Text("0");
   LabelsValues[0].FontSize(10);
   Dialog.Add(LabelsValues[0]);
   Labels[1].Create(0,"PointsLbl",0,230,25,30,0);
   Labels[1].Text("Next Entry:");
   Labels[1].FontSize(10);
   Dialog.Add(Labels[1]);
   LabelsValues[1].Create(0,"-",0,320,25,30,0);
   LabelsValues[1].Text("0.00");
   LabelsValues[1].FontSize(10);
   Dialog.Add(LabelsValues[1]);
   Labels[2].Create(0,"DirectionLbl",0,230,45,30,0);
   Labels[2].Text("Direction:");
   Labels[2].FontSize(10);
   Dialog.Add(Labels[2]);
   LabelsValues[2].Create(0,"DirectionValue",0,320,45,30,0);
   LabelsValues[2].Text("-");
   LabelsValues[2].FontSize(10);
   Dialog.Add(LabelsValues[2]);
   Labels[3].Create(0,"PnlLbl",0,230,65,30,0);
   Labels[3].Text("PNL$  : ");
   Labels[3].FontSize(10);
   Dialog.Add(Labels[3]);
   LabelsValues[3].Create(0,"PNLValue",0,320,65,30,0);
   LabelsValues[3].Text("0.0");
   LabelsValues[3].FontSize(10);
   Dialog.Add(LabelsValues[3]);
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
   if(!TerminalInfo.IsTradeAllowed())
      return;
   int orders = CalculateCurrentOrders2( );
   
   double pnl = GetPnl();
   string dir = "";
   int op = -99;
   if(Grid_Direction == Grid_Long)        {dir = "Long";op= POSITION_TYPE_BUY;}
   else if(Grid_Direction == Grid_Short)  {dir = "Short";op= POSITION_TYPE_SELL;}
   else if(Grid_Direction == Grid_Both)   dir = "Both";
   point_signal = PointsSignal(op);
   /*
   LabelsValues[0].Text(IntegerToString(orders)+"/"+IntegerToString(Grid_Max_Legs));
   LabelsValues[1].Text(DoubleToString(pnl,2));
   LabelsValues[2].Text(dir);*/
   LabelsValues[0].Text((string)orders+"/"+IntegerToString(Grid_Max_Legs));
   LabelsValues[1].Text((string)point_signal);
   LabelsValues[2].Text(dir);
   LabelsValues[3].Text(DoubleToString(pnl,2));
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
   int orders_total = 0;
   int min_stop = (int) SymbolInfoInteger(_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
   double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
   orders_total = CalculateCurrentOrders2();   
   if(orders_total==0){
      Refresh_Sell();
      Refresh_Buy();
   }
   if(TP_Point!=0)
   {
      if(Tp_Type == Fix){
         TPB=ask+TP_Point*Point();
         TPS=bid-TP_Point*Point();
         
      }
      else if(Tp_Type == ATR){
         double   atr[1];
         if(CopyBuffer(atr_handle,0,0,1,atr)!=1)
           {
            Print("CopyBuffer from ATR failed, no data");
            return ;
           }
         double thresh = TP_Point * atr[0];  
         TPB=ask+thresh;
         TPS=bid-thresh;
      }
      

   }
   else
   {
      TPB=0;
      TPS=0;
   }
   if(Sl_Type == ATR){
      double   atr[1];
         if(CopyBuffer(atr_handle,0,0,1,atr)!=1)
           {
            Print("CopyBuffer from ATR failed, no data");
            return ;
           }
         double thresh = SL_Value * atr[0];  
         SLB=ask-thresh;
         if(ask - SLB < min_stop*_Point){
            Print("Invalid sl. Sl Smaller than minimum stop allowed");
         }
         SLS=bid+thresh;
         if(bid + SLB < min_stop*_Point){
            Print("Invalid sl. Sl Smaller than minimum stop allowed");
         }
   }
   int ma_signal = MA_Check();    
      
   if((Strategy_Type==Open_Now )&& (Grid_Direction==0||Grid_Direction==2) && CalculateCurrentOrders(0)==0)
   {
      Refresh_Buy();
      Refresh_Sell();
      if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order)){
         C_B=0;
         GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL[C_B]=Lot_Size;
      } 
   }
     
   else if((Strategy_Type==Open_Now  )&& (Grid_Direction==1||Grid_Direction==2) && CalculateCurrentOrders(1)==0)
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
      if(C_B!=-1 &&  orders_total!=0 && orders_total<(Grid_Max_Legs))
      {
         double trigger_price =point_signal;
         if(trigger_price == 0)
            return;
         //GB[C_B] = LastOrderPrice(ORDER_TYPE_BUY);
         //if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)<=(trigger_price) && trigger_price > 0)
         if(LegEntryCheck())
         {
            Alert("Buy Trigger point ="+(string)trigger_price);
            C_B++;
            double lot_prev = CalculateOrderLots(1 );
            double lot_size_T=NormalizeDouble(lot_prev*Grid_Multiplier,2);
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_B)*Lot_Size,2);
            Print("Previous Lot size: "+(string)lot_prev);
            //if(lot_size_T > lot_size_G)
            //   lot_size_G = lot_size_T;
            if( (Grid_Direction==0||Grid_Direction==2)|| (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal)){
               if(trade.Buy(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,NULL,Comment_Order)){
                  GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                  GBL[C_B]=lot_size_G;
                  BTP_Average();
               }
               else{
                  C_B--;
               }
            
            }
         }
      }
      if(C_S!=-1&&  orders_total!=0 && orders_total<(Grid_Max_Legs))
      {
         double trigger_price =point_signal ;
         if(trigger_price == 0)
            return;
         //GS[C_S] = LastOrderPrice(ORDER_TYPE_SELL);
         //GS[C_S] = trigger_price;
         //if(SymbolInfoDouble(Symbol(),SYMBOL_BID)>=(trigger_price) && trigger_price > 0)
         if(LegEntryCheck())
         {
            Alert("Sell Trigger point ="+(string)trigger_price);
            C_S++;
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_S)*Lot_Size,2);
            if( (Grid_Direction==1||Grid_Direction==2) || (Strategy_Type == MA_Directional || Strategy_Type == MA_Reversal)){
               if(trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Comment_Order)){
                  GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                  GSL[C_S]=lot_size_G;
                  STP_Average();
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
      CheckLoss();
      CheckProfit();
   }
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
   int orders_total = CalculateCurrentOrders2();
   double distance = Distance_Point * Point();
   if(orders_total == 0 || orders_total == Grid_Max_Legs)
      return false;
   int orders_buy = CalculateCurrentOrders(POSITION_TYPE_BUY);
   int orders_sell = CalculateCurrentOrders(POSITION_TYPE_SELL);
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return false; }
   double Ask=tick.ask;
   double Bid=tick.bid;
   
   if(orders_buy > 0){
      double price = LastOrderPrice(POSITION_TYPE_BUY);
      if(Bid <= price - distance ){
         Print("Buy Legs["+orders_buy+"] Sell Legs["+orders_sell+"]");
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
int MA_Check()
{
    if(Strategy_Type==MA_Directional || Strategy_Type == MA_Reversal){
      int signal = 0;
      double   ma[2];
      if(CopyBuffer(ExtHandle,0,0,2,ma)!=2)
        {
         Print("CopyBuffer from iMA failed, no data");
         return 0;
        }
      double open = iOpen(Symbol(),0,0);    
      double open1 = iOpen(Symbol(),0,1);
      double close1 = iClose(_Symbol,0,1); 
      int k=0;
      MqlTick tick;
      if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
       double Ask=tick.ask;
       double Bid=tick.bid;
       
       //DIRECTIONAL
      if((Ask >= ma[0] && open < ma[0]) &&
          Strategy_Type==MA_Directional  )
            signal = 1;
      else if((Bid <= ma[0] && open > ma[0])&&
          Strategy_Type==MA_Directional) 
            signal = -1;
      
      //Reversal
      if((open1 < ma[1] && close1 < ma[1])&&
         (Ask >= ma[0] && open < ma[0]) &&
          Strategy_Type==MA_Reversal  )
            signal = -1;
      else if((open1 > ma[1] && close1 > ma[1])&&
              (Bid <=ma[0] && open > ma[0])&& 
               Strategy_Type==MA_Reversal) 
                  signal = 1;
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
         if(PositionGetString(POSITION_SYMBOL)==Symbol()  && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
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
