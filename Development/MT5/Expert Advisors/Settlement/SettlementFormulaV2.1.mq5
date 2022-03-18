//+------------------------------------------------------------------+
//|                                                 SettlementEA.mq5 |
//|                                      Copyright 2021, AlgoTradeup |
//|                                          https://algotradeup.com |
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
CTerminalInfo  TerminalInfo;
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
CLabel  ReversalLabel;
CLabel  ReversalValue;
CButton MannualEntryBtn [9];
CButton CloseBtn;
CButton TitleBtn;
CTrade trade;
input int               magic_num         =  46598; //Magic Number
input string            Trade_Symbol      =  "EURUSD.r";//Order Symbol
input string            TradeComment      = "Settlement_Formula";
input bool              AutoTimeEntry     = false;
input bool              UseReversal       = false; //Use Reversal
input bool              UseMannualEntry   = false; //Use Manual entry
//---------------------------------------------------------------------
double            Settlement_Price  =  0.0;//Settlement price
double            Lot_Size          =  0.0;//Lots
double            Entry_Threshold   =  0.0;//Entry threshold(pips)
double            Tp_Fix            =  0.0;//Tp Fixed(pips)
double            Sl_Fix            =  0.0; //Sl Fix(pips)
double            TP_Money          =  100;     //TP $
double            SL_Money          =  100;     //SL $

string          Entry_Time          = "00:00";
bool _flag = false;
datetime Expiry=D'2022.10.19 00:00';
string current_time ;
bool exp_deliverd = false;
bool trade_time = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   trade.SetExpertMagicNumber(magic_num);
   Dialog.Create(ChartID(),"                                      ALGOTRADEUP",0,5,5,400,400);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrGold);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   TitleBtn.Create(0,"Title",0,5,6,0,0)                              ;
   TitleBtn.Text("Settlement EA")                                            ;
   TitleBtn.FontSize(12)                                          ;                                    
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(225)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrDarkTurquoise)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   Dialog.Add(TitleBtn);
   
   InputLabels[0].Create(0,"PriceLabel",0,5,45,0,0);
   InputLabels[0].Text("Settlement Price: ");
   InputLabels[0].FontSize(9);
   Dialog.Add(InputLabels[0])                                     ;
   
   Inputs[0].Create(0,"PriceEdit",0,125,45,0,0);
   Inputs[0].Text(""+(string)Settlement_Price);
   Inputs[0].FontSize(9);
   Inputs[0].Height(20)                                            ;
   Inputs[0].Width(100)                                            ;
   Dialog.Add(Inputs[0])                                           ;
   
   TimeLabel.Create(0,"_TimeLabel",0,250,25,0,0)                   ;
   TimeLabel.Text("Time: ")                                        ;
   TimeLabel.FontSize(9)                                          ;
   Dialog.Add(TimeLabel)                                          ;
   
   TimeValue.Create(0,"_TimeValue",0,320,25,0,0)                   ;
   TimeValue.Text(TimeToString(TimeLocal(),TIME_MINUTES))         ;
   TimeValue.FontSize(9)                                          ;
   Dialog.Add(TimeValue)                                          ;
   
   FlagLabel.Create(0,"FlagLabel",0,250,45,0,0)                   ;
   FlagLabel.Text("Flag: ")                                        ;
   FlagLabel.FontSize(9)                                          ;
   Dialog.Add(FlagLabel)                                          ;
   
   FlagValue.Create(0,"FlagValue",0,320,45,0,0)                   ;
   FlagValue.Text((string)_flag)                                        ;
   FlagValue.FontSize(9)                                          ;
   Dialog.Add(FlagValue)                                          ;
   
   PNLLabel.Create(0,"PNLLabel",0,250,65,0,0)                   ;
   PNLLabel.Text("PNL: ")                                        ;
   PNLLabel.FontSize(9)                                          ;
   Dialog.Add(PNLLabel)                                          ;
   
   PNLValue.Create(0,"PNLValue",0,320,65,0,0)                   ;
   PNLValue.Text("0.0")                                        ;
   PNLValue.FontSize(9)                                          ;
   Dialog.Add(PNLValue)                                          ;
   
   TimeFlagLabel.Create(0,"TimeFlagLabel",0,250,85,0,0)                   ;
   TimeFlagLabel.Text("Is Time: ")                                        ;
   TimeFlagLabel.FontSize(9)                                          ;
   Dialog.Add(TimeFlagLabel)                                          ;
   
   TimeFlagValue.Create(0,"TimeFlagValue",0,320,85,0,0)                   ;
   TimeFlagValue.Text((string)trade_time)                                        ;
   TimeFlagValue.FontSize(9)                                          ;
   Dialog.Add(TimeFlagValue)                                          ;
   
   
   ReversalLabel.Create(0,"ReverseLabel",0,250,105,0,0)             ;
   ReversalLabel.Text("Reversal: ")                             ;
   ReversalLabel.FontSize(9)                                     ;
   Dialog.Add(ReversalLabel)                                     ;
   
   ReversalValue.Create(0,"ReverseEdit",0,320,105,0,0)                 ;
   ReversalValue.Text(""+(string)UseReversal)                                          ;
   ReversalValue.FontSize(9)                                          ;                                          ;
   Dialog.Add(ReversalValue)                                          ;
   
   InputLabels[1].Create(0,"LotsLabel",0,5,65,0,0)                ;
   InputLabels[1].Text("Lots: ")                                  ;
   InputLabels[1].FontSize(9)                                     ;
   Dialog.Add(InputLabels[1])                                     ;
   
   Inputs[1].Create(0,"LotsEdit",0,125,65,0,0)                    ;
   Inputs[1].Text(""+(string)Lot_Size)                                          ;
   Inputs[1].FontSize(9)                                          ;
   Inputs[1].Height(20)                                           ;
   Inputs[1].Width(100)                                           ;
   Dialog.Add(Inputs[1])                                          ;
   
   InputLabels[2].Create(0,"TPPLabel",0,5,85,0,0)                 ;
   InputLabels[2].Text("TP points: ")                             ;
   InputLabels[2].FontSize(9)                                     ;
   Dialog.Add(InputLabels[2])                                     ;
   
   Inputs[2].Create(0,"TPPEdit",0,125,85,0,0)                     ;
   Inputs[2].Text(""+(string) Tp_Fix )                                          ;
   Inputs[2].FontSize(9)                                          ;
   Inputs[2].Height(20)                                           ;
   Inputs[2].Width(100)                                           ;
   Dialog.Add(Inputs[2])                                          ;
   
   InputLabels[3].Create(0,"TPDLabel",0,5,105,0,0)                ;
   InputLabels[3].Text("TP$: ")                                   ;
   InputLabels[3].FontSize(9)                                     ;
   Dialog.Add(InputLabels[3])                                     ;
   
   Inputs[3].Create(0,"TPDEdit",0,125,105,0,0)                    ;
   Inputs[3].Text(""+(string)TP_Money)                                          ;
   Inputs[3].FontSize(9)                                          ;
   Inputs[3].Height(20)                                           ;
   Inputs[3].Width(100)                                           ;
   Dialog.Add(Inputs[3])                                          ;
   
   InputLabels[4].Create(0,"SLDLabel",0,5,125,0,0)                ;
   InputLabels[4].Text("SL$: ")                                   ;
   InputLabels[4].FontSize(9)                                     ;
   Dialog.Add(InputLabels[4])                                     ;
   
   Inputs[4].Create(0,"SLDEdit",0,125,125,0,0)                    ;
   Inputs[4].Text(""+ (string)SL_Money )                                          ;
   Inputs[4].FontSize(9)                                          ;
   Inputs[4].Height(20)                                           ;
   Inputs[4].Width(100)                                           ;
   Dialog.Add(Inputs[4])                                          ;
   
   InputLabels[5].Create(0,"ThreshLabel",0,5,145,0,0)             ;
   InputLabels[5].Text("Threshold: ")                             ;
   InputLabels[5].FontSize(9)                                     ;
   Dialog.Add(InputLabels[5])                                     ;
   
   Inputs[5].Create(0,"ThreshEdit",0,125,145,0,0)                 ;
   Inputs[5].Text(""+(string)Entry_Threshold)                                          ;
   Inputs[5].FontSize(9)                                          ;
   Inputs[5].Height(20)                                           ;
   Inputs[5].Width(100)                                           ;
   Dialog.Add(Inputs[5])                                          ;
   
   InputLabels[6].Create(0,"TimeLabel",0,5,165,0,0)             ;
   InputLabels[6].Text("Entry Time: ")                             ;
   InputLabels[6].FontSize(9)                                     ;
   Dialog.Add(InputLabels[6])                                     ;
   
   Inputs[6].Create(0,"TimeEdit",0,125,165,0,0)                 ;
   Inputs[6].Text(""+(string)Entry_Time)                                          ;
   Inputs[6].FontSize(9)                                          ;
   Inputs[6].Height(20)                                           ;
   Inputs[6].Width(100)                                           ;
   Dialog.Add(Inputs[6])                                          ;
   
   
   MannualEntryBtn[0].Create(0,"Get_Price_Btn",0,5, 210,0,0)             ;
   MannualEntryBtn[0].Text("Fetch Price")                            ;
   MannualEntryBtn[0].Height(35)                                  ;
   MannualEntryBtn[0].Width(114)                                  ;
   //MannualEntryBtn[0].Color(clrWhite)                           ;
   MannualEntryBtn[0].ColorBackground(clrMediumSpringGreen)       ;
   MannualEntryBtn[0].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[0])                                 ;
   
   MannualEntryBtn[1].Create(0,"Mannual_lmt",0,6+110, 210,0,0)             ;
   MannualEntryBtn[1].Text("Place Lmts")                            ;
   MannualEntryBtn[1].Height(35)                                  ;
   MannualEntryBtn[1].Width(114)                                  ;
   //MannualEntryBtn[0].Color(clrWhite)                           ;
   MannualEntryBtn[1].ColorBackground(clrMediumSpringGreen)       ;
   MannualEntryBtn[1].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[1])                                 ;
   
   MannualEntryBtn[2].Create(0,"Close_Btn",0,6,245,0,0)           ;
   MannualEntryBtn[2].Text("Close")                               ;
   MannualEntryBtn[2].Height(28)                                  ;
   MannualEntryBtn[2].Width(114)                                  ;
   MannualEntryBtn[2].Color(clrWhite)                           ;
   MannualEntryBtn[2].ColorBackground(clrBlue)       ;
   MannualEntryBtn[2].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[2])                                 ;
   
   MannualEntryBtn[3].Create(0,"Reset_Btn",0,6+110,245,0,0)           ;
   MannualEntryBtn[3].Text("Reset")                               ;
   MannualEntryBtn[3].Height(28)                                  ;
   MannualEntryBtn[3].Width(114)                                  ;
   MannualEntryBtn[3].Color(clrWhite)                           ;
   MannualEntryBtn[3].ColorBackground(clrRed)       ;
   MannualEntryBtn[3].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[3])                                 ;
   
   MannualEntryBtn[4].Create(0,"Ok_Btn",0,6,273,0,0)           ;
   MannualEntryBtn[4].Text("Apply Parameters")                               ;
   MannualEntryBtn[4].Height(28)                                  ;
   MannualEntryBtn[4].Width(224)                                  ;
   MannualEntryBtn[4].Color(clrBlack)                           ;
   MannualEntryBtn[4].ColorBackground(clrLime)       ;
   MannualEntryBtn[4].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[4])                                 ;
   
   MannualEntryBtn[5].Create(0,"BuySp_Btn",0,6,300,0,0)           ;
   MannualEntryBtn[5].Text("Buy @ SP")                               ;
   MannualEntryBtn[5].Height(28)                                  ;
   MannualEntryBtn[5].Width(114)                                  ;
   MannualEntryBtn[5].Color(clrWhite)                           ;
   MannualEntryBtn[5].ColorBackground(clrBlue)       ;
   MannualEntryBtn[5].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[5])                                 ;
   
   MannualEntryBtn[6].Create(0,"SellSp_Btn",0,6+110,300,0,0)           ;
   MannualEntryBtn[6].Text("Sell @ SP")                               ;
   MannualEntryBtn[6].Height(28)                                  ;
   MannualEntryBtn[6].Width(114)                                  ;
   MannualEntryBtn[6].Color(clrWhite)                           ;
   MannualEntryBtn[6].ColorBackground(clrRed)       ;
   MannualEntryBtn[6].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[6])                                 ;
   
   MannualEntryBtn[7].Create(0,"Buy_Btn",0,6,328,0,0)           ;
   MannualEntryBtn[7].Text("Buy")                               ;
   MannualEntryBtn[7].Height(28)                                  ;
   MannualEntryBtn[7].Width(114)                                  ;
   MannualEntryBtn[7].Color(clrWhite)                           ;
   MannualEntryBtn[7].ColorBackground(clrBlue)       ;
   MannualEntryBtn[7].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[7])                                 ;
   
   MannualEntryBtn[8].Create(0,"Sell_Btn",0,6+110,328,0,0)           ;
   MannualEntryBtn[8].Text("Sell")                               ;
   MannualEntryBtn[8].Height(28)                                  ;
   MannualEntryBtn[8].Width(114)                                  ;
   MannualEntryBtn[8].Color(clrWhite)                           ;
   MannualEntryBtn[8].ColorBackground(clrRed)       ;
   MannualEntryBtn[8].ColorBorder(clrBlack)                       ;
   Dialog.Add(MannualEntryBtn[8])                                 ;
   SetParameters();
   EventSetMillisecondTimer(200);
//---
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
void OnTimer(){
   double pnl = CalculatePNL();
   FlagValue.Text((string)_flag);
   TimeFlagValue.Text((string) trade_time );
   TimeValue.Text(TimeToString(TimeLocal(),TIME_MINUTES));
   PNLValue.Text((string)pnl);
}
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(!TerminalInfo.IsTradeAllowed())
      return;
   if(CheckExpiry()){
      if(!exp_deliverd){
         exp_deliverd = true;
         Alert("EA expired. Please contact the developer");
      }
      else
         return;
   }
   datetime _time = TimeLocal();
   current_time = TimeToString(_time,TIME_MINUTES);
   Comment("Flag: "+(string)_flag);
   
   double adjustment_points = 15.0;
   //Comment("ask["+ask+"]bid["+bid+"]flag["+flag+"]");
   if(CheckTradeTime() && AutoTimeEntry && !trade_time){
      Inputs[0].Text( ""+(string)SymbolInfoDouble(Trade_Symbol,SYMBOL_BID));
      SetParameters();
      trade_time = true;
   }
   else
   {
      if(!_flag){
         double ask = SymbolInfoDouble(Trade_Symbol,SYMBOL_ASK);
         double bid = SymbolInfoDouble(Trade_Symbol,SYMBOL_BID);
         double _point = SymbolInfoDouble(Trade_Symbol,SYMBOL_POINT);
         
         int min_stop = (int)SymbolInfoInteger(Trade_Symbol,SYMBOL_TRADE_STOPS_LEVEL);
         double b_stop = NormalizePrice(Settlement_Price+(Entry_Threshold*_point));
         double s_stop = NormalizePrice(Settlement_Price-(Entry_Threshold*_point));
         bool b_stop_check = ( b_stop-ask ) > min_stop * _point;
         bool s_stop_check = ( bid - s_stop ) > min_stop * _point;
         
         if(b_stop_check && s_stop_check && !UseMannualEntry){
            PlacePendingOrders();
            Print("Buy Stop["+(string)b_stop+"] buy_check["+(string)b_stop_check+"] Sell Stop["+(string)s_stop+"] sell check["+(string)s_stop_check+"]");
         
         }
                     
      }   
      
   }
   ModifyTP();
   CheckLoss();
   
   
  }

void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(id == CHARTEVENT_OBJECT_CLICK){
         if(sparam == "")
            return;
         if(sparam=="Ok_Btn"){
            MessageBox("Applying parameters");
            SetParameters();
            MannualEntryBtn[4].Pressed(false);
            return;
         }   
         if(sparam=="Close_Btn"){
            CloseAll();
            MannualEntryBtn[2].Pressed(false);
            return;
         }
         if(sparam=="Reset_Btn"){
            //_flag = true;
            MessageBox("Reseting flags");
            _flag = false;
            trade_time = false;
            MannualEntryBtn[3].Pressed(false);
            return;
         }
         if(sparam == "Get_Price_Btn"){
            MessageBox("Fetching current price");
            MannualEntryBtn[0].Pressed(false);
            Inputs[0].Text( ""+(string)SymbolInfoDouble(Trade_Symbol,SYMBOL_BID));
            return;
            //PlacePendingOrders();
         }
         if(sparam == "Mannual_lmt"){
            MessageBox("Placing mannual order");
            //if(!_flag)
            //{
               MannualEntryBtn[1].Pressed(false);
               PlacePendingOrders();
               _flag = true;
               return;
            //}   
         }
         if(sparam == "BuySp_Btn"){
            MessageBox("Placing mannual order");
            MannualEntryBtn[5].Pressed(false);
            MannualEntrySP(ORDER_TYPE_BUY);
            _flag = true;
            return;
         }
         if(sparam == "SellSp_Btn"){
            MessageBox("Placing mannual order");
            MannualEntryBtn[6].Pressed(false);
            MannualEntrySP(ORDER_TYPE_SELL);
            _flag = true;
            return;
         }
         if(sparam == "Buy_Btn"){
            MessageBox("Placing mannual order");
            MannualEntryBtn[7].Pressed(false);
            MannualEntry(ORDER_TYPE_BUY);
            _flag = true;
            return;
         }
         if(sparam == "Sell_Btn"){
            MessageBox("Placing mannual order");
            MannualEntryBtn[8].Pressed(false);
            MannualEntry(ORDER_TYPE_SELL);
            _flag = true;
            return;
         }
      }
   }
   
  
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
//+------------------------------------------------------------------+
void PlacePendingOrders(){
   double ask = SymbolInfoDouble(Trade_Symbol,SYMBOL_ASK);
   double bid = SymbolInfoDouble(Trade_Symbol,SYMBOL_BID);
   double _point = SymbolInfoDouble(Trade_Symbol,SYMBOL_POINT);
   Print(Settlement_Price);
   if(!UseReversal){
      if(trade.BuyStop(Lot_Size,NormalizePrice(Settlement_Price+(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
         if(trade.SellStop(Lot_Size,NormalizePrice(Settlement_Price-(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
               //set flag to true
               _flag = true;
         }
         else{
            Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
            _flag = true;
         }  
      }
   }
   else{
      if(trade.SellLimit(Lot_Size,NormalizePrice(Settlement_Price+(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
         if(trade.BuyLimit(Lot_Size,NormalizePrice(Settlement_Price-(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
               //set flag to true
               _flag = true;
         }
         else{
            Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
            _flag = true;
         }  
   }
   
   
   }
   

}
bool ModifyTP(){
   int positions = PositionsTotal();
   int count = 0, op = -9999; ulong ticket =-999,ticket_p=-999;
   double op_price = 0.0, p_price =0.0, tp = 0.0;
   for(int i=0; i<=positions; i++)
   {
      //if(!PositionGetTicket(i)) break;
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Trade_Symbol && PositionGetInteger(POSITION_MAGIC)==magic_num )
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY || PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)
            {
               count++;
               ticket = PositionGetInteger(POSITION_TICKET);
               op_price = PositionGetDouble(POSITION_PRICE_OPEN);
               op = (int)PositionGetInteger(POSITION_TYPE);
               tp = PositionGetDouble(POSITION_TP);
            }
      }
      
   }
   int count_p = 0;
   for(int i = 0 ; i< OrdersTotal();i++)
   {
      //Check pending count == 1
      //Take the price and and close the ticket
      if(OrderGetTicket(i) > 0){
         if(OrderGetString(ORDER_SYMBOL)==Trade_Symbol && OrderGetInteger(ORDER_MAGIC)==magic_num ){
            if(OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_STOP || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_STOP
               ||OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_BUY_LIMIT || OrderGetInteger(ORDER_TYPE)==ORDER_TYPE_SELL_LIMIT){
               count_p++;
               ticket_p = OrderGetInteger(ORDER_TICKET);
               p_price  = OrderGetDouble(ORDER_PRICE_OPEN);
            }
         }
      }    
   }
   //if position open:
      //if stop orders open -> delete and put as sl
   if(count == 1 && count_p >0){
      Alert("Count: "+(string)count_p+" |Ticket: "+(string)ticket_p);
      trade.OrderDelete(ticket_p);
      
   if(tp > 0.0)
      return false;
   if(ticket != -999)
   {
      double _point = SymbolInfoDouble(Trade_Symbol,SYMBOL_POINT);
      double _tp = 0.0, _sl=0.0;
      if(op == POSITION_TYPE_BUY){
         _tp = NormalizePrice(op_price+(Tp_Fix *_point ));
         _sl = NormalizePrice(Settlement_Price-(Entry_Threshold*_point));
         if(UseReversal)_sl =NormalizePrice(op_price-(Entry_Threshold*_point));
         //Settlement_Price-(Entry_Threshold*_point)
      }
         
      else if(op == POSITION_TYPE_SELL){
         _tp = NormalizePrice(op_price -(Tp_Fix *_point));  
         _sl = NormalizePrice(Settlement_Price+(Entry_Threshold*_point));
         if(UseReversal)_sl =NormalizePrice(op_price+(Entry_Threshold*_point));
      }
         
      else
         return false;   
      Comment(ticket_p);   
      if(trade.PositionModify(ticket,_sl, _tp )){
         trade.OrderDelete(ticket_p);
      }
      
   }
   }
   return false;
}
void CheckLoss()
{
   double  num=0;
   int n = 0;
    for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Trade_Symbol){
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
double CalculatePNL(){
   double pnl = 0.0;
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Trade_Symbol){
            pnl=pnl+PositionGetDouble(POSITION_PROFIT);            
         }
            
      }
   }   
   return pnl;
}
void CloseAll()
{
   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Trade_Symbol && PositionGetInteger(POSITION_MAGIC)==magic_num )
            trade.PositionClose(PositionGetTicket(i));
      }
   }
}
void SetParameters(){
   Settlement_Price = StringToDouble(Inputs[0].Text());
   Lot_Size         = StringToDouble(Inputs[1].Text());
   Tp_Fix           = StringToDouble(Inputs[2].Text());
   TP_Money         = StringToDouble(Inputs[3].Text());
   //Sl_Fix           = StringToDouble(Inputs[4].Text());
   SL_Money         = StringToDouble(Inputs[4].Text());
   Entry_Threshold  = StringToDouble(Inputs[5].Text());
   Entry_Time       = Inputs[6].Text();
}
bool CheckTradeTime(){
   if(StringSubstr(current_time,0,5) == Entry_Time )
      return true;
   return false;
}
void MannualEntry(int op){
   PlaceOrder(op);

}
void MannualEntry(){
   //if above settlement price place buy: place sell
   double _bid = SymbolInfoDouble(Trade_Symbol,SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol,SYMBOL_ASK);
   if(!UseReversal){
      if(_bid < Settlement_Price && _ask < Settlement_Price)
         PlaceOrder(ORDER_TYPE_SELL);
      if(_ask > Settlement_Price && _bid > Settlement_Price)   
         PlaceOrder(ORDER_TYPE_BUY);
   }
   if(UseReversal){
      if(_bid < Settlement_Price && _ask < Settlement_Price)
         PlaceOrder(ORDER_TYPE_BUY);
      if(_ask > Settlement_Price && _bid > Settlement_Price)   
         PlaceOrder(ORDER_TYPE_SELL);
   }
   
}
void MannualEntrySP(int op){
   //if above settlement price place buy: place sell
   double _bid = SymbolInfoDouble(Trade_Symbol,SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol,SYMBOL_ASK);
   double _point = SymbolInfoDouble(Trade_Symbol,SYMBOL_POINT);
   int adj_op = op;
   if(UseReversal){
      if(op == ORDER_TYPE_BUY)adj_op = ORDER_TYPE_SELL;
      else if(op == ORDER_TYPE_SELL)adj_op = ORDER_TYPE_BUY;
   }   
   if(adj_op == ORDER_TYPE_BUY)
   {
      if(_ask > Settlement_Price)
      {
         if(trade.BuyLimit(Lot_Size,NormalizePrice(Settlement_Price),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
            if(trade.SellStop(Lot_Size,NormalizePrice(Settlement_Price-(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
               _flag = true;
            }
            else{
               Print("Error opening Sell Stop Order. Reason: "+(string)GetLastError());
               _flag = true;
            }  
         }
      }
      else
         PlaceOrder(ORDER_TYPE_BUY);               
   }
   if(adj_op == ORDER_TYPE_SELL)
   {
      if(_bid < Settlement_Price)
      {
         if(trade.SellLimit(Lot_Size,NormalizePrice(Settlement_Price),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
            if(trade.BuyStop(Lot_Size,NormalizePrice(Settlement_Price+(Entry_Threshold*_point)),Trade_Symbol,0.0,0.0,ORDER_TIME_GTC,0,TradeComment)){
               _flag = true;
            }
            else{
               Print("Error opening Sell Limit Order. Reason: "+(string)GetLastError());
               _flag = true;
            }  
         }
      }
      else
         PlaceOrder(ORDER_TYPE_SELL);                        
   }
   
}
void PlaceOrder(int op){

   double _bid = SymbolInfoDouble(Trade_Symbol,SYMBOL_BID);
   double _ask = SymbolInfoDouble(Trade_Symbol,SYMBOL_ASK);
   double _point = SymbolInfoDouble(Trade_Symbol,SYMBOL_POINT);
   int ticket = -99;
   if(op == ORDER_TYPE_BUY){
      if(UseReversal){
         ticket = trade.Buy(Lot_Size,Trade_Symbol,_ask,NormalizePrice(_ask-(Entry_Threshold*_point)),NormalizePrice(_bid+(+Tp_Fix*_point)),TradeComment);
         _flag =true;
      }
      else{
         ticket = trade.Buy(Lot_Size,Trade_Symbol,_ask,NormalizePrice(Settlement_Price-(Entry_Threshold*_point)),NormalizePrice(_ask+(+Tp_Fix*_point)),TradeComment);
         _flag =true;
      }      
   }
         
   else if(op == ORDER_TYPE_SELL){
      if(!UseReversal){
         ticket = trade.Sell(Lot_Size,Trade_Symbol,_ask,NormalizePrice(Settlement_Price+(Entry_Threshold*_point)),NormalizePrice(_bid-(Tp_Fix*_point)),TradeComment);
         _flag = true;
      }
      else{
         ticket = trade.Sell(Lot_Size,Trade_Symbol,_ask,NormalizePrice(_bid+(Entry_Threshold*_point)),NormalizePrice(_ask-(Tp_Fix*_point)),TradeComment);
         _flag = true;
      }   
   }
      
}
double NormalizePrice(double price)
  {
   double m_tick_size=SymbolInfoDouble(_Symbol,SYMBOL_TRADE_TICK_SIZE);
   return(NormalizeDouble(MathRound(price/m_tick_size)*m_tick_size,_Digits));
  }