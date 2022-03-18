//+------------------------------------------------------------------+
//|                                        BB_Grid_Ea_V2 _NEW_V9.mq5 |
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
enum E_SST
{
   Directional=0,
   Reversal=1,
   Open_Now=2,
   MA_Directional = 3,
   MA_Reversal = 4
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
input bool    Trail_TP=true;
input double  TrailingStop_Point=50;
input double  TrailingStep_Point=2;
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
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
//---
   trade.SetExpertMagicNumber(magic_num);
   Handler_BB=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);

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
int orders_total = Orders();
if(Strategy_Type==2 && (Grid_Direction==0||Grid_Direction==2) && OrdersTT(0)==0)
{
   
   Refresh_Sell();
       
       trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TP_Point*Point(),NULL);  
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
     
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),SymbolInfoDouble(Symbol(),SYMBOL_BID)-TP_Point*Point(),NULL);    
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
   if(Orders()==1)
      Trail();
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
            trade.Buy(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),(OPB/Count_B)-SL_Point*Point(),FTPB,NULL);
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
            trade.Sell(lot_size_G,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),(OPS/Count_S)+SL_Point*Point(),FTPS,NULL);
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
         trade.Buy(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_ASK),SymbolInfoDouble(Symbol(),SYMBOL_ASK)-SL_Point*Point(),TPB,NULL);
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
         trade.Sell(Lot_Size,NULL,SymbolInfoDouble(Symbol(),SYMBOL_BID),SymbolInfoDouble(Symbol(),SYMBOL_BID)+SL_Point*Point(),TPS,NULL);
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
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
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
void Trail()
{
   for(int i=PositionsTotal()-1; i>=0; i--)
      if(PositionGetTicket(i))
         if(PositionGetString(POSITION_SYMBOL)==Symbol() && PositionGetInteger(POSITION_MAGIC)==magic_num)
         {
            if(PositionGetInteger(POSITION_TYPE)==0)
            {
               if(SymbolInfoDouble(Symbol(),SYMBOL_BID)-TrailingStop_Point *Point()>=PositionGetDouble(POSITION_PRICE_OPEN) && ((SymbolInfoDouble(Symbol(),SYMBOL_BID)-TrailingStop_Point *Point())>PositionGetDouble(POSITION_SL) ||PositionGetDouble(POSITION_SL)==0 ))
               {

                  trade.PositionModify(PositionGetTicket(i),
                                       SymbolInfoDouble(Symbol(),SYMBOL_BID)-TrailingStop_Point *Point(),PositionGetDouble(POSITION_TP));
               }
            }
            if(PositionGetInteger(POSITION_TYPE)==1)
            {

               if((SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TrailingStop_Point *Point())<PositionGetDouble(POSITION_PRICE_OPEN) &&((SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TrailingStop_Point  *Point())<PositionGetDouble(POSITION_SL)||PositionGetDouble(POSITION_SL)==0))
               {

                  trade.PositionModify(PositionGetTicket(i),
                                       SymbolInfoDouble(Symbol(),SYMBOL_ASK)+TrailingStop_Point *Point(),PositionGetDouble(POSITION_TP));
               }
            }
         }
}
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
