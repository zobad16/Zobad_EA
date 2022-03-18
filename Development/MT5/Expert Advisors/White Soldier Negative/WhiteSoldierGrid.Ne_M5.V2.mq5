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
   Open_Now=2
};

input string  EA_Setting="===== EA Setting =====";
input E_Grid_Direction Grid_Direction=0;//Grid Direction
input bool  Negative_Grid_Enable=true;
input int   magic_num=46598; //Magic Number
input double  Lot_Size=0.01;// Lot Size
input E_SST  Strategy_Type=0;//Strategy Type
input string  Comment_Order="BB_Grid";//Comment Order
input double  TP_Point=100;//TP Point
input double  TP_Money=100;//TP $Money
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
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   trade.SetExpertMagicNumber(magic_num);
   Handler_Band=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
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
if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && CalculateCurrentOrders(0)==0)
{
         Refresh_Sell();
         trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order);
         C_B=0;
         GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL[C_B]=Lot_Size;
  
  
  
  
  }
  
   if(Strategy_Type==2 && (Grid_Direction==1||Grid_Direction==2) && CalculateCurrentOrders(1)==0)
 {
 
  
         Refresh_Buy();
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order);
         C_S=0;
         GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL[C_S]=Lot_Size;
  }
   CheckLoss();

   if( CalculateCurrentOrders2( )==0)
   {
      Refresh_Buy();
      Refresh_Sell();


   }
   if(Negative_Grid_Enable)
   {
      if(C_B!=-1 &&  CalculateCurrentOrders2( )!=0 && CalculateCurrentOrders2()<=(Grid_Max_Legs+1))
      {
         if(SymbolInfoDouble(Symbol(),SYMBOL_ASK)<=(GB[C_B]-Distance_Point*Point()))
         {
            C_B++;
            GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_B)*Lot_Size,2);
            GBL[C_B]=lot_size_G;
 if( (Grid_Direction==0||Grid_Direction==2))
            trade.Buy(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,NULL,Comment_Order);
            BTP_Average();

         }



      }
      if(C_S!=-1&&  CalculateCurrentOrders2( )!=0 && CalculateCurrentOrders2()<=(Grid_Max_Legs+1))
      {
         if(SymbolInfoDouble(Symbol(),SYMBOL_BID)>=(GS[C_S]+Distance_Point*Point()))
         {
            C_S++;
            GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
            double lot_size_G=NormalizeDouble(MathPow(Grid_Multiplier,C_S)*Lot_Size,2);
            GSL[C_S]=lot_size_G;
 if( (Grid_Direction==1||Grid_Direction==2))
            trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,NULL,Comment_Order);
            STP_Average();

         }



      }
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
   if( CalculateCurrentOrders2( )==0 && iVolume(NULL,PERIOD_CURRENT,0)<=1)
   {
      if(BB_Check()==1 &&  CalculateCurrentOrders2( )==0)
      {
         Refresh_Sell();
          if( (Grid_Direction==0||Grid_Direction==2))
         trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),NULL,TPB,Comment_Order);
         C_B=0;
         GB[C_B]=SymbolInfoDouble(Symbol(),SYMBOL_ASK);
         GBL[C_B]=Lot_Size;
      }

      if(BB_Check()==-1 &&  CalculateCurrentOrders2( )==0)
      {
         Refresh_Buy();
          if( (Grid_Direction==1||Grid_Direction==2))
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),NULL,TPS,Comment_Order);
         C_S=0;
         GS[C_S]=SymbolInfoDouble(Symbol(),SYMBOL_BID);
         GSL[C_S]=Lot_Size;
      }


   }
}
//+------------------------------------------------------------------+
int BB_Check()
{
   int k=0;

   CopyBuffer(Handler_Band,1,1,1,UPBB1);
   CopyBuffer(Handler_Band,2,1,1,DNBB1);
   if(iOpen(NULL,PERIOD_CURRENT,1)<=UPBB1[0] && iClose(NULL,PERIOD_CURRENT,1)>=UPBB1[0] && Bollinger_Bands_Method==0)
      k=1;
   if(iOpen(NULL,PERIOD_CURRENT,1)<=UPBB1[0] && iClose(NULL,PERIOD_CURRENT,1)>=UPBB1[0] && Bollinger_Bands_Method==1)
      k=-1;
   if(iOpen(NULL,PERIOD_CURRENT,1)>=DNBB1[0] && iClose(NULL,PERIOD_CURRENT,1)<=DNBB1[0] && Bollinger_Bands_Method==0)
      k=-1;
   if(iOpen(NULL,PERIOD_CURRENT,1)>=DNBB1[0] && iClose(NULL,PERIOD_CURRENT,1)<=DNBB1[0] && Bollinger_Bands_Method==1)
      k=1;
   return(k);
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
void CheckLoss()
{
   double  num=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
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
      close(0);
      close(1);
      C_B=-1;
      C_S=-1;
   }


}
//+------------------------------------------------------------------+
void CheckProfit()
{
   double  num=0;
   for(int i=OrdersTotal()-1; i>=0; i--)
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
      close(0);
      close(1);
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
