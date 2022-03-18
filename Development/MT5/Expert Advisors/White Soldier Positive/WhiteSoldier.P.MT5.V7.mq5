//+------------------------------------------------------------------+
//|                                        BB_Grid_Ea_V2 _NEW_V9.mq5 |
//|                                     Copyright 2021, Algotradeup. |
//|                                     https://www.algotradeup.com/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, Algotradeup."
#property link      "https://algotradeup.com/"
#property version   "1.00"
#property strict
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
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
enum E_SST
{
   Directional=0,
   Reversal=1,
   Open_Now=2
};
enum E_Grid_Direction
{

Grid_Long=0,//Long
Grid_Short=1,//Short
Grid_Both=2//Both



};

input string               GridSet="------------PositiveGrid Settings -------------------";
input int                  magic_num=46598; //Magic Number
input bool                 Positive_Grid=true;//Positive Grid
input E_Grid_Direction     Grid_Direction=0;//Grid Direction
input E_SST                Strategy_Type=0;//Strategy Type
input double               Lot_Size=0.01;// Lot Size
input int                  Grid_Max_Leg=10;//Grid Max Leg
input double               Grid_Leg_Threshold=50;//Grid Leg Threshold
input double               Grid_Lot_Multiplier=1.25;//Grid Multiplier
input bool                 Grid_Hide_TP_SL=false;//Grid Hide TP/SL
input double               TP_Point=100;//TP Point
input double               SL_Point=100;//SL Point
input double               TP_Money=1000;//TP Money
input double               SL_Money=1000;//SL Money
input bool                 UseEquityTrail=false;//Use Equity trail
input double               EquityTrailStart= 500;//Equity Trail Start point
input double               Width=200;//Equity trail width
input string               Trade_Comment="POS_GRID";
input string               Bollinger_Bands_Setting="=====  Bollinger Bands =====";
input int                  BB_Period=20;// Bollinger Bands Period
input double               BB_deviation=2;// Bollinger Bands deviation
input int                  BB_Shift=0;// Bollinger Shift
input ENUM_APPLIED_PRICE   BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
datetime Expiry=D'2022.12.19 00:00';
bool exp_deliverd = false;
double TPB,TPS;
int C_B_N=-1;
int C_S_N=-1;
double GB_N[1000];
double GBL_N[1000];
double GS_N[1000];
double GSL_N[1000];

int C_B_P=-1;
int C_S_P=-1;
double GB_P[1000];
double GBL_P[1000];
double GS_P[1000];
double GSL_P[1000];
double OPB=0;
double Count_B=0;
double OPS=0;
double Count_S=0;
double FTPB=0;
double FTPS=0;
int Handler_BB;
double UPBB1[];
double DNBB1[];
bool reset;

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
      return (INIT_FAILED);
      
   }
   trade.SetExpertMagicNumber(magic_num);
   Handler_BB=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   Dialog.Create(ChartID(),"                                      ALGOTRADEUP",0,5,5,400,200);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrGold);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);
   TitleBtn.Create(0,"Title",0,5,6,0,0)                              ;
   TitleBtn.Text("Anti-Martingale")                                            ;
   TitleBtn.FontSize(12)                                          ;                                    
   TitleBtn.Height(35)                                            ;
   TitleBtn.Width(200)                                            ;
   TitleBtn.Color(clrWhite)                                       ;
   TitleBtn.ColorBackground(clrDarkTurquoise)                             ;
   TitleBtn.ColorBorder(clrBlack)                                 ;
   TitleBtn.Disable()                                             ;
   Dialog.Add(TitleBtn);
   
   CloseAllBtn.Create(0,"CloseAll",0,5,120,0,0)                      ;
   CloseAllBtn.Text("Close All")                                     ;
   CloseAllBtn.FontSize(10)                                          ;                                    
   CloseAllBtn.Height(40)                                            ;
   CloseAllBtn.Width(200)                                            ;
   CloseAllBtn.Color(clrBlack)                                       ;
   CloseAllBtn.ColorBackground(clrWhite)                             ;
   CloseAllBtn.ColorBorder(clrBlack)                                 ;
   CloseAllBtn.Pressed(false);
   Dialog.Add(CloseAllBtn);
   
   MannualEntryBtn[0].Create(0,"OpenBuy",0,5,40,0,0)                ;
   MannualEntryBtn[0].Text("Open Buy")                                ;
   MannualEntryBtn[0].FontSize(10)                                    ;                                    
   MannualEntryBtn[0].Height(40)                                      ;
   MannualEntryBtn[0].Width(100)                                      ;
   MannualEntryBtn[0].Color(clrWhite)                                 ;
   MannualEntryBtn[0].ColorBackground(clrBlue)                        ;
   MannualEntryBtn[0].ColorBorder(clrBlack)                           ;
   MannualEntryBtn[0].Pressed(false);
   Dialog.Add(MannualEntryBtn[0]);
   
   CloseBuysBtn.Create(0,"CloseBuys",0,5,80,0,0)                      ;
   CloseBuysBtn.Text("Close Buys")                                     ;
   CloseBuysBtn.FontSize(10)                                          ;                                    
   CloseBuysBtn.Height(40)                                            ;
   CloseBuysBtn.Width(100)                                            ;
   CloseBuysBtn.Color(clrWhite)                                       ;
   CloseBuysBtn.ColorBackground(clrBlue)                               ;
   CloseBuysBtn.ColorBorder(clrBlack)                                 ;
   CloseBuysBtn.Pressed(false);
   Dialog.Add(CloseBuysBtn);
   
   MannualEntryBtn[1].Create(0,"OpenSell",0,105,40,0,0)                      ;
   MannualEntryBtn[1].Text("Open Sells")                                     ;
   MannualEntryBtn[1].FontSize(10)                                          ;                                    
   MannualEntryBtn[1].Height(40)                                            ;
   MannualEntryBtn[1].Width(100)                                            ;
   MannualEntryBtn[1].Color(clrWhite)                                       ;
   MannualEntryBtn[1].ColorBackground(clrRed)                               ;
   MannualEntryBtn[1].ColorBorder(clrBlack)                                 ;
   MannualEntryBtn[1].Pressed(false);
   Dialog.Add(MannualEntryBtn[1]);
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
   Dialog.Add(CloseSellsBtn);
   
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

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTimer(){
   if(!TerminalInfo.IsTradeAllowed() || exp_deliverd)
      return;
   int legs = Orders();
   double pnl = GetPnl();
   string dir = "";
    int op = -99;
   if(Grid_Direction == Grid_Long){ 
      op= POSITION_TYPE_BUY;        
      dir = "Long";
   }   
   else if(Grid_Direction == Grid_Short){
      dir = "Short";
      op = POSITION_TYPE_SELL;  
   }   
   else if(Grid_Direction == Grid_Both)   dir = "Both";
   LabelsValues[0].Text((string)legs);
   LabelsValues[1].Text((string)PointsSignal(op));
   LabelsValues[2].Text(dir);
   LabelsValues[3].Text((string)pnl);
}

void OnTick()
{
//---
   //if(!IsExpertEnabled()) return;
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
         
if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && OrdersTT(0)==0)
{
   
   Refresh_Sell();
       
       bool buy = trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
       if(buy){
         C_B_N=0;
         GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL_N[C_B_N]=Lot_Size;
         C_B_P=0;
         GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL_P[C_B_P]=Lot_Size;
         OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
         Count_B++;
         FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();
       }  
  
  
  
  }
  
   if(Strategy_Type==2 && (Grid_Direction==1||Grid_Direction==2) && OrdersTT(1)==0)
 {
 
  
           Refresh_Buy();
     
         bool sell = trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
         if(sell){
            C_S_N=0;
            GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_N[C_S_N]=Lot_Size;
            C_S_P=0;
            GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_P[C_S_P]=Lot_Size;
            OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
            Count_S++;
            FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
         }
  }
   if(Orders()==0)
   {
      Refresh_Buy();
      Refresh_Sell();
   }
   else{
      CheckLoss();
      EquityTrail(UseEquityTrail,EquityTrailStart,Width);
   }

//***********************************************************

   if(Positive_Grid)
   {
      int order = Orders();
      Count_B   = OrdersTT(POSITION_TYPE_BUY);
      Count_S   = OrdersTT(POSITION_TYPE_SELL);
      if(C_B_P!=-1 && order!=0)
      {
         //Need to check legs
         if(OrdersTT(ORDER_TYPE_BUY)<Grid_Max_Leg+1){
            GB_P[C_B_P] = LastOrderPrice(ORDER_TYPE_BUY);
            if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)>=(GB_P[C_B_P]+Grid_Leg_Threshold*Point()))
            {
               if( (Grid_Direction==0||Grid_Direction==2))
               {
                  double average_price_buy = Average_Open_Price(POSITION_TYPE_BUY);
                  
                  OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_B_P)*Lot_Size,2);
                  Count_B++;
                  if(trade.Buy(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),0,FTPB,Trade_Comment))
                  {
                     C_B_P++;
                     GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
                     GBL_P[C_B_P]=lot_size_G;
                     //Print("AVG["+average_price_buy+"]OPB["+OPB+"] Count_B["+Count_B+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     Average_SL((average_price_buy)-SL_Point*Point() );
                  
                  }
                  else
                     Count_B--;                  
               }
            }         
         }
      }
      if(C_S_P!=-1&& Orders()!=0)
      {
         if(OrdersTT(ORDER_TYPE_SELL)<Grid_Max_Leg+1)
         {
            GB_P[C_S_P] = LastOrderPrice(ORDER_TYPE_SELL);
            if( (Grid_Direction==1||Grid_Direction==2)){
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(GS_P[C_S_P]-Grid_Leg_Threshold*Point()))
               {
                  double average_price_sell = Average_Open_Price(POSITION_TYPE_SELL);
                  OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
                  Count_S++;
                  double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);            
                  bool sell = trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),0,FTPS,Trade_Comment);
                  if(sell){
                     C_S_P++;
                     GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
                     GSL_P[C_S_P]=lot_size_G;
                     //Print("AVG["+average_price_sell+"] OPS["+OPS+"] Count_S["+Count_S+"] SL_Point*point["+(SL_Point*Point())+"] point[]");
                     Average_SL((average_price_sell)+SL_Point*Point() );            
                  }
                  else{
                     Count_S--;
                  }
               }
            }               
         }
       }
   }
//*******************************************************************

   if(Strategy_Type!=2)
{
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
   if(Orders()==0 && iVolume(NULL,PERIOD_CURRENT,0)<=1)
   {
      if(BB_Check()==1 && Orders()==0&&  (Grid_Direction==0||Grid_Direction==2) )
      {
         Refresh_Sell();
         double _ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         //   int BuyTicket=OrderSend(Symbol(),OP_BUY,Lot_Size,Ask,5,Ask-SL_Point*Point,TPB,Trade_Comment,magic_num,0,clrNONE);
         if(trade.Buy(Lot_Size,NULL,_ask,_ask-(SL_Point*Point()),TPB,Trade_Comment)){
            C_B_N=0;
            GB_N[C_B_N]=_ask;
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=_ask;
            GBL_P[C_B_P]=Lot_Size;
            OPB=_ask+OPB;
            Count_B++;
            FTPB=TPB;
         }
         
      }

      if(BB_Check()==-1 && Orders()==0&&  (Grid_Direction==1||Grid_Direction==2))
      {
         Refresh_Buy();
         double _bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
         // int SellTicket=OrderSend(Symbol(),OP_SELL,Lot_Size,Bid,5,Bid+SL_Point*Point,TPS,Trade_Comment,magic_num,0,clrNONE);
         if(trade.Sell(Lot_Size,NULL,_bid,_bid+(SL_Point*Point()),TPS,Trade_Comment)){
            C_S_N=0;
            GS_N[C_S_N]=_bid;
            GSL_N[C_S_N]=Lot_Size;
            C_S_P=0;
            GS_P[C_S_P]=_bid;
            GSL_P[C_S_P]=Lot_Size;
            OPS=_bid+OPS;
            Count_S++;
            FTPS=TPS;
         }
         
      }


   }
   if(OrdersTT(0)==0)
   {
      OPB=0;
      Count_B=0;

   }
   if(OrdersTT(1)==0)
   {
      OPS=0;
      Count_S=0;

   }
   }
}
double PointsSignal(int op){
   int legs = Orders();
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
            next_price = (last_price+ Grid_Leg_Threshold*Point());     
         }
         else if(op == POSITION_TYPE_SELL){
            if(_ask <= last_price- Grid_Leg_Threshold*Point()){
               next_price = (last_price- Grid_Leg_Threshold*Point());
            }
         }
        return next_price; 
     }    
   //return 0.0;
}
double Average_Open_Price(int op)
{
   int count = 0;
   double sum = 0.0;
   double avg = 0.0;
   for(int i=PositionsTotal()-1; i>=0; i--){ // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==magic_num && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
         {
            count ++;
            sum += m_position.PriceOpen();
         }   
   }
   avg = sum/count;
   return avg;           
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
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   Dialog.OnEvent(id,lparam,dparam,sparam);
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
    if(sparam=="CloseAll") // Close all
    {
        //CloseAll(Magic);
        //CloseAllBtn.Pressed(false);
        MessageBox("Closing All Orders!")                           ;
        CloseAllPositions();
        CloseAllBtn.Pressed(false);
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
    }
    if(sparam=="OpenBuy") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[0].Pressed(false);
        MessageBox("Opening Buy Order!")                           ;
        MannualEntry(ORDER_TYPE_BUY);
        //MannualEntry(OP_BUY);
        Print("Opened Buy Position");
        //WindowRedraw();
    }
    if(sparam=="CloseBuys") // Close Buys
    {
        //CloseAll(Magic);
        CloseBuysBtn.Pressed(false);
        MessageBox("Closing All Buy Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_BUY);
        Print("Close All Buy Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
    }
    if(sparam=="OpenSell") // Close Buys
    {
        //CloseAll(Magic);
        MannualEntryBtn[1].Pressed(false);
        MessageBox("Opening Sell Order!")                           ;
        MannualEntry(ORDER_TYPE_SELL);
        //MannualEntry(OP_SELL);
        Print("Opened Sell Position");
        //WindowRedraw();
    }
    if(sparam=="CloseSells") // Close Sells
    {
        //CloseAll(Magic);
        CloseSellsBtn.Pressed(false);
        MessageBox("Closing All sell Orders!")                           ;
        CloseAllPositions(POSITION_TYPE_SELL);
        Print("Close All Sell Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Sell();
    }
   }
    
   
}
//+------------------------------------------------------------------+
int BB_Check()
{
   int k=0;
   MqlTick tick;
    if(!SymbolInfoTick(_Symbol,tick)) { Print("no tick data available, error = ",GetLastError()); ExpertRemove(); return -99; }
    double Ask=tick.ask;
    double Bid=tick.bid;
    
   CopyBuffer(Handler_BB,1,0,1,UPBB1);
   CopyBuffer(Handler_BB,2,0,1,DNBB1);
//  double UPBB1=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price,MODE_UPPER,1);
//  double   DNBB1=iBands(NULL,0,BB_Period,BB_deviation,BB_Shift,BB_Applied_Price,MODE_LOWER,1);
   if(Ask>=UPBB1[0] && Strategy_Type==0)
      k=1;
   if(Ask>=UPBB1[0] && Strategy_Type==1)
      k=-1;
   if(iOpen(NULL,0,1)<=UPBB1[0] && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==0)
      k=1;
   if(iOpen(NULL,0,1)<=UPBB1[0]  && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==1)
      k=-1;
   if(Bid<=DNBB1[0] && Strategy_Type==0)
      k=-1;   
   if(Bid<=DNBB1[0] && Strategy_Type==1)
      k=1;     
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==0)
      k=-1;
   if(iOpen(NULL,0,1)>=DNBB1[0]  && iClose(NULL,0,1)<=DNBB1[0]  && Strategy_Type==1)
      k=1;
   return(k);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void close(int TT)
{

//---

   for(int i=0; i<PositionsTotal()+1; i++)
   {
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE)==TT)
            trade.PositionClose(PositionGetTicket(i));
      }
      
   }
   if(TT == POSITION_TYPE_BUY)
      Refresh_Buy();
   else if(TT == POSITION_TYPE_SELL)
      Refresh_Sell();   

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
   for(int i=0; i<PositionsTotal()+1; i++)
   {
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
      if(OrdersTT(ORDER_TYPE_BUY)==0 && (Grid_Direction==Grid_Long||Grid_Direction==Grid_Both))
         if(trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment)){  
            C_B_N=0;
            GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_N[C_B_N]=Lot_Size;
            C_B_P=0;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            GBL_P[C_B_P]=Lot_Size;
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            FTPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point();   
         }
   }
   
   else if(op == ORDER_TYPE_SELL && (Grid_Direction==Grid_Short||Grid_Direction==Grid_Both)){
      if(OrdersTT(ORDER_TYPE_SELL)==0)
         if(trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment)){    
            C_S_N=0;
            GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_N[C_S_N]=Lot_Size;
            C_S_P=0;
            GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            GSL_P[C_S_P]=Lot_Size;
            OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
            Count_S++;
            FTPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point();
         }
   }

}
int Orders( )
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


}
//+------------------------------------------------------------------+
int OrdersTT( int TT)
{

//---
   int k=0;

   for(int i=PositionsTotal()-1; i>=0; i--)
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
//|                                                                  |
//+------------------------------------------------------------------+
double GetPnl(){
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   return num;
}
void CheckLoss()
{
   double  num=0;
   for(int i=PositionsTotal()-1; i>=0; i--)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol())
            num=num+PositionGetDouble(POSITION_PROFIT);
      }
   }
   if(num<SL_Money*(-1) || num>=TP_Money)
   {
      Refresh_Buy();
      Refresh_Sell();
      CloseAllPositions();
      C_B_P=-1;
      C_S_P=-1;
      C_B_N=-1;
      C_S_N=-1;
   }


}
//+------------------------------------------------------------------+
void Average_SL(double NSL )
{


   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetDouble(POSITION_SL)!=NSL )
         trade.PositionModify(PositionGetTicket(i),NSL,PositionGetDouble(POSITION_TP));
          //  int yy=OrderModify(OrderTicket(),OrderOpenPrice(),NSL,OrderTakeProfit(), 0, clrNONE);
      }
   }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void Refresh_Buy()
{
   ArrayFill(GB_N,0,1000,0);
   ArrayFill(GBL_N,0,1000,0);
   C_B_N=-1;
//*********
   ArrayFill(GB_P,0,1000,0);
   ArrayFill(GBL_P,0,1000,0);
   C_B_P=-1;


}
//+------------------------------------------------------------------+
void Refresh_Sell()
{
   ArrayFill(GS_P,0,1000,0);
   ArrayFill(GSL_P,0,1000,0);
   C_S_P=-1;
//**********************
   ArrayFill(GS_N,0,1000,0);
   ArrayFill(GSL_N,0,1000,0);
   C_S_N=-1;


}
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
bool trail_flag = false;
double trail_equity =0.0;
void EquityTrail(bool use, double start, double width){
   if(!use)return;
   
   double pnl = GetPnl();
   
   //trail 
   if(trail_flag){
      if(pnl<=trail_equity){
         //Liquidate
         trail_flag = false;
         Print("Liquidating positions- Equity trail- Profit["+DoubleToString(pnl,2)+"] trail["+DoubleToString(trail_equity,2)+"]");
         if(Grid_Direction == Grid_Long)
            CloseAllPositions(POSITION_TYPE_BUY);
         else if(Grid_Direction == Grid_Short)
            CloseAllPositions(POSITION_TYPE_SELL);   
         return;
      }
      else if((pnl-trail_equity)> width){
         trail_equity = pnl-width;
      }
   }
   else if(!trail_flag){
      if(pnl >= start){
         
         trail_flag = true;
         trail_equity = pnl-width;
         Print("Trail Started-"+Symbol()+"- Trailing at: "+DoubleToString(trail_equity,1));
         return;
      }
   }

}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
