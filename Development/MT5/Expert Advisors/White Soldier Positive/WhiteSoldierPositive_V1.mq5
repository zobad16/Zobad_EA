//+------------------------------------------------------------------+
//|                                      WhiteSoldierPositive_V1.mq5 |
//|                                      Copyright 2021, AlgoTradeup |
//|                                          https://algotradeup.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup"
#property link      "https://algotradeup.com"
#property version   "1.00"
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Controls\Button.mqh>
CButton MannualEntryBtn [3];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
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
//--------------------------------------------------------

input string            GridSet="------------PositiveGrid Settings -------------------";

input int               magic_num=46598; //Magic Number
input E_Grid_Direction  Grid_Direction=Grid_Long;//Grid Direction
input bool              Positive_Grid=true;//Positive Grid
input bool              Grid_Hide_TP_SL=false;//Grid Hide TP/SL
input E_SST             Strategy_Type=0;//Strategy Type
input int               Grid_Max_Leg=10;//Grid Max Leg
input double            Lot_Size=0.01;// Lot Size
input double            TP_Point=100;//TP Point
input double            SL_Point=100;//SL Point
input double            TP_Money=1000;//TP Money
input double            SL_Money=1000;//SL Money
input double            Grid_Leg_Threshold=50;//Grid Leg Threshold
input double            Grid_Lot_Multiplier=1.25;//Grid Multiplier
input string            Trade_Comment="Grid";
input string            Bollinger_Bands_Setting="=====  Bollinger Bands =====";
input int               BB_Period=20;// Bollinger Bands Period
input double            BB_deviation=2;// Bollinger Bands deviation
input int               BB_Shift=0;// Bollinger Shift
input ENUM_APPLIED_PRICE  BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
//-------------------
int Handler_BB;
double UPBB1[];
double DNBB1[];
bool reset = false;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   trade.SetExpertMagicNumber(magic_num);
   Handler_BB=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
   TitleBtn.Create(0,"Title",0,5,6,0,0)                              ;
   TitleBtn.Text("Anti-Martingale")                                            ;
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
   //EventSetTimer(60);
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   //EventKillTimer();
   CloseAllBtn.Destroy(reason);
   MannualEntryBtn[0].Destroy(reason);
   CloseBuysBtn.Destroy(reason);
   MannualEntryBtn[1].Destroy(reason);
   CloseSellsBtn.Destroy(reason);
   TitleBtn.Destroy(reason);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   
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
   
  }
//+------------------------------------------------------------------+
int OrdersCount( int op)
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_TYPE)==op && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


}
int OrdersCount( )
{

//---
   int k=0;

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(PositionGetTicket(i))
      {
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
            k++;
      }

   }
   return(k);


}
int BB_Check()
{
   int k=0;
   CopyBuffer(Handler_BB,1,1,1,UPBB1);
   CopyBuffer(Handler_BB,2,1,1,DNBB1);
//  double UPBB1=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price,MODE_UPPER,1);
//  double   DNBB1=iBands(NULL,0,BB_Period,BB_deviation,BB_Shift,BB_Applied_Price,MODE_LOWER,1);
   if(iOpen(NULL,0,1)<=UPBB1[0] && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==0)
      k=1;
   if(iOpen(NULL,0,1)<=UPBB1[0]  && iClose(NULL,0,1)>=UPBB1[0]  && Strategy_Type==1)
      k=-1;
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

   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!PositionGetTicket(i)) break;
      if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num && PositionGetInteger(POSITION_TYPE)==TT)
         trade.PositionClose(PositionGetTicket(i));
   }


//---
}
void CloseAll()
{
   for(int i=0; i<PositionsTotal(); i++)
   {
      if(!PositionGetTicket(i)) break;
      if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num )
         trade.PositionClose(PositionGetTicket(i));
   }
   if(OrdersCount() == 0)
      return;
   else
      CloseAll();   
}