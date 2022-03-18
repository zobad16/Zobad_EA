//+------------------------------------------------------------------+
//|                                        BB_Grid_Ea_V2 _NEW_V9.mq5 |
//|                                  Copyright 2021, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
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

input string  GridSet="------------PositiveGrid Settings -------------------";
input E_Grid_Direction Grid_Direction=0;//Grid Direction
input bool  Positive_Grid=true;//Positive Grid
input bool Grid_Hide_TP_SL=false;//Grid Hide TP/SL
input E_SST  Strategy_Type=0;//Strategy Type
input int   Grid_Max_Leg=10;//Grid Max Leg
input int   magic_num=46598; //Magic Number
input double  Lot_Size=0.01;// Lot Size
input double  TP_Point=100;//TP Point
input double  SL_Point=100;//SL Point
input double  TP_Money=1000;//TP Money
input double  SL_Money=1000;//SL Money
input double  Grid_Leg_Threshold=50;//Grid Leg Threshold
input double  Grid_Lot_Multiplier=1.25;//Grid Multiplier
input string             Trade_Comment="Grid";
input string  Bollinger_Bands_Setting="=====  Bollinger Bands =====";
input int     BB_Period=20;// Bollinger Bands Period
input double  BB_deviation=2;// Bollinger Bands deviation
input int     BB_Shift=0;// Bollinger Shift
input ENUM_APPLIED_PRICE  BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
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

//---
   return(INIT_SUCCEEDED);
}
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
//---
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
if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && OrdersTT(0)==0)
{
   
   Refresh_Sell();
       
       trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
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
  
   if(Strategy_Type==2 && (Grid_Direction==1||Grid_Direction==2) && OrdersTT(1)==0)
 {
 
  
           Refresh_Buy();
     
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
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
   CheckLoss();
 
   if(Orders()==0)
   {
      Refresh_Buy();
      Refresh_Sell();


   }

//***********************************************************

   if(Positive_Grid)
   {
      if(C_B_P!=-1 && Orders()!=0)
      {
         if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)>=(GB_P[C_B_P]+Grid_Leg_Threshold*Point()))
         {
            C_B_P++;
            GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
            Count_B++;
            double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_B_P)*Lot_Size,2);
            GBL_P[C_B_P]=lot_size_G;
 if( (Grid_Direction==0||Grid_Direction==2))
            trade.Buy(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),(OPB/Count_B)-SL_Point*Point(),FTPB,Trade_Comment);
          Average_SL((OPB/Count_B)-SL_Point*Point() );

         }



      }
      if(C_S_P!=-1&& Orders()!=0)
      {
         if(SymbolInfoDouble(Symbol(),SYMBOL_BID)<=(GS_P[C_S_P]-Grid_Leg_Threshold*Point()))
         {
            C_S_P++;
            GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
            Count_S++;
            double lot_size_G=NormalizeDouble(MathPow(Grid_Lot_Multiplier,C_S_P)*Lot_Size,2);
            GSL_P[C_S_P]=lot_size_G;
            //  int SellTicket=OrderSend(Symbol(),OP_SELL,lot_size_G,Bid,5,(OPS/Count_S)+SL_Point*Point(),FTPS,Trade_Comment,magic_num,0,clrNONE);
           if( (Grid_Direction==1||Grid_Direction==2))
            trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),(OPS/Count_S)+SL_Point*Point(),FTPS,Trade_Comment);
          Average_SL((OPS/Count_S)+SL_Point*Point() );

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
         //   int BuyTicket=OrderSend(Symbol(),OP_BUY,Lot_Size,Ask,5,Ask-SL_Point*Point,TPB,Trade_Comment,magic_num,0,clrNONE);
         trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),TPB,Trade_Comment);
         C_B_N=0;
         GB_N[C_B_N]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL_N[C_B_N]=Lot_Size;
         C_B_P=0;
         GB_P[C_B_P]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL_P[C_B_P]=Lot_Size;
         OPB=SymbolInfoDouble(Symbol(),SYMBOL_ASK)+OPB;
         Count_B++;
         FTPB=TPB;
      }

      if(BB_Check()==-1 && Orders()==0&&  (Grid_Direction==1||Grid_Direction==2))
      {
         Refresh_Buy();
         // int SellTicket=OrderSend(Symbol(),OP_SELL,Lot_Size,Bid,5,Bid+SL_Point*Point,TPS,Trade_Comment,magic_num,0,clrNONE);
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),TPS,Trade_Comment);
         C_S_N=0;
         GS_N[C_S_N]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL_N[C_S_N]=Lot_Size;
         C_S_P=0;
         GS_P[C_S_P]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL_P[C_S_P]=Lot_Size;
         OPS=SymbolInfoDouble(Symbol(),SYMBOL_BID)+OPS;
         Count_S++;
         FTPS=TPS;
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
  //+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
  {
//---
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
      return;
    if(sparam=="CloseAll") // Close all
    {
        //CloseAll(Magic);
        //CloseAllBtn.Pressed(false);
        MessageBox("Closing All Orders!")                           ;
        CloseAll();
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
        close(POSITION_TYPE_BUY);
        Print("Close All Buy Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
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
        close(POSITION_TYPE_SELL);
        Print("Close All Sell Orders event");
        //WindowRedraw();
        reset = true;
        Refresh_Buy();
        Refresh_Sell();
    }
   }
    
   
}
//+------------------------------------------------------------------+
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
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op)
{
   if(op == ORDER_TYPE_BUY){
      if(OrdersTT(ORDER_TYPE_BUY)==0 && (Grid_Direction==Grid_Long||Grid_Direction==Grid_Both))
         trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),Trade_Comment);  
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
   
   else if(op == ORDER_TYPE_SELL && (Grid_Direction==Grid_Short||Grid_Direction==Grid_Both)){
      if(OrdersTT(ORDER_TYPE_SELL)==0)
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),Trade_Comment);    
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
int Orders( )
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
//+------------------------------------------------------------------+
int OrdersTT( int TT)
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
//+------------------------------------------------------------------+
//|                                                                  |
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
   if(num<SL_Money*(-1))
   {
      Refresh_Buy();
      Refresh_Sell();
      close(0);
      close(1);
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

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
