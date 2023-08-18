//+------------------------------------------------------------------+
//|                                        SyntheticSpreadTrader.mq4 |
//|                                   Copyright 2023, Zobad Mahmood. |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Zobad Mahmood."
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#property strict
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
//--- input parameters
input string   Magic="814";
input string   Symbol1="GCZ3";
input string   Symbol2="XAUUSD";
input bool     AllowTrade = false;
input string   _Comment       = "Synthetic Spread Trader";
input bool     UseDollarTP    = false;
input bool     UseDollarSL    = false;
//-----Variables
CEdit   InputParams[9];
CDialog Dialog;
CLabel  LabelsInputs[10];
CLabel  LabelsValues[2];
CLabel  Stats_Lbl[3];
CLabel  StatsValues_Lbl[3];
CButton Buttons[5];
color DialogColor= C'16,21,43';
string FontName = "Segoe UI";

//-------Input variables
double   BenchmarkPrice = 31.7;
double   SellSpread     = 1;
double   BuySpread      = -5;
double   Symbol1Lots    = 1;
double   Symbol2Lots    = 1;
double      DollarTP       = 100;
double      DollarSL       =-500;
//--------Stats variables
double deltaHigh = 0.0;
double deltaLow = 0.0;


//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   InitializeGUI();
   EventSetTimer(60);


//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   Dialog.Destroy(reason);
   EventKillTimer();

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   double brokerSpread = GetBrokerSpreadDelta();
   double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   SpreadValuesUpdate(spreadBidAsk, brokerSpread);
   DeltaLabelsUpdate(spreadBidAsk);
   double spreadAB =  SymbolInfoDouble(Symbol1,SYMBOL_ASK) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   Buttons[0].Text("Spread:  "+DoubleToString(spreadBidAsk,2)+"  |  BrokerSpread: "+(DoubleToString(brokerSpread,2)));
   LabelsValues[0].Text(DoubleToString(getPnL(Magic),2));
   double totalOrders = isOrdersTotal(Magic);
   if(IsBuySpread(spreadBidAsk) && totalOrders == 0 && AllowTrade)
     {
      PlaceOrderPair(OP_BUY,SymbolInfoDouble(Symbol1,SYMBOL_ASK),OP_SELL,SymbolInfoDouble(Symbol1,SYMBOL_BID));
      //Trade
     }
   else
      if(IsSellSpread(spreadBidAsk) && totalOrders == 0 && AllowTrade)
        {
         //Trade
         PlaceOrderPair(OP_SELL,SymbolInfoDouble(Symbol1,SYMBOL_BID),OP_BUY,SymbolInfoDouble(Symbol1,SYMBOL_ASK));
        }
   if(totalOrders > 0)
     {
      double pnl = getPnL(Magic);

      if(UseDollarTP && pnl >= DollarTP)
        {
         Print("Reached TP Target. Closing positions");
         CloseAllOrders(Magic);
        }
      else
         if(UseDollarSL && pnl <= DollarSL)
           {
            Print("SL Limit hit. Closing positions");
            CloseAllOrders(Magic);
           }

     }


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
   Dialog.OnEvent(id,lparam,dparam,sparam);
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "")
         return;

      if(sparam == "OpenBuy")
        {
         Print("Opening Buy spread");
         Buttons[1].Pressed(false);
         PlaceOrderPair(OP_BUY,SymbolInfoDouble(Symbol1,SYMBOL_ASK),OP_SELL,SymbolInfoDouble(Symbol1,SYMBOL_BID));
        }
      if(sparam == "OpenSell")
        {
         Print("Opening sell spread");
         Buttons[2].Pressed(false);
         PlaceOrderPair(OP_SELL,SymbolInfoDouble(Symbol1,SYMBOL_BID),OP_BUY,SymbolInfoDouble(Symbol1,SYMBOL_ASK));
        }
      if(sparam == "CloseAll")
        {
         Print("Closing All");
         Buttons[3].Pressed(false);
         CloseAllOrders(Magic);
        }
      if(sparam == "Apply")
        {
         Print("Applying params");
         Buttons[4].Pressed(false);
         ApplyParams();
        }

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ApplyParams()
  {
   BenchmarkPrice = StringToDouble(InputParams[0].Text());//Benchmark
   BuySpread = StringToDouble(InputParams[1].Text());//buy spread
   SellSpread= StringToDouble(InputParams[2].Text());//sell spread
   Symbol1Lots = StringToDouble(InputParams[3].Text()); //pair1 lots
   Symbol2Lots = StringToDouble(InputParams[4].Text());//pair2 Lots
   DollarTP = StringToDouble(InputParams[5].Text());//TP$
   DollarSL = StringToDouble(InputParams[6].Text());//SL$
   Print("Parameters applied: Benchmark: "+BenchmarkPrice+" | BuySpread: ["+BuySpread+"] | SellSpread: ["+SellSpread+"] | Symbol1Lots: ["+Symbol1Lots+"] | Symbol2Lots: ["+Symbol2Lots+"] | DollarTP: ["+DollarTP+"] | DollarSL: ["+DollarSL+"]");

  }
//+------------------------------------------------------------------+
void InitializeGUI()
  {
   Dialog.Create(ChartID(),"GoldArbitrageXpert",0,5,5,400,350);
   string dialogNumber=Dialog.Name();
   color bg_color = C'39, 40, 42';
   color banner_color = C'29, 27, 27';
   color primary_color = C'93, 138, 206';
//color secondary_color = C'87, 121, 83';
   color accent_color = C'58, 85, 82';

   color secondary_color = clrSeaGreen;
//OBJPROP_BORDER_COLOR
//OBJPROP_FONTSIZE
//BORDER_SUNKEN
//OBJPROP_BORDER_TYPE

   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,C'80,174,187');
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BORDER_COLOR,C'26,31,50');
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_COLOR,clrBlack);
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_FONTSIZE,12);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,C'26,31,50');
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BORDER_COLOR,bg_color);
   ObjectDelete(ChartID(),dialogNumber+"Border");

   Buttons[0].Create(0,"Spread",0,5,6,0,0)                              ;
   Buttons[0].Text("Spread:  "+"0.0")                                            ;
   Buttons[0].FontSize(11)                                          ;
   Buttons[0].Font(FontName);
   Buttons[0].Height(30)                                            ;
   Buttons[0].Width(375)                                            ;
   Buttons[0].Color(clrWhite)                                       ;
   Buttons[0].ColorBackground(bg_color)                             ;
   Buttons[0].ColorBorder(C'80,174,187')                                 ;
   Buttons[0].Disable()                                             ;
   Dialog.Add(Buttons[0]);

   Buttons[1].Create(0,"OpenBuy",0,5,40,0,0)                ;
   Buttons[1].Text("BUY SPREAD")                                ;
   Buttons[1].FontSize(9)                                    ;
   Buttons[1].Font(FontName);
   Buttons[1].Height(25)                                      ;
   Buttons[1].Width(120)                                      ;
   Buttons[1].Color(clrWhite)                                 ;
   Buttons[1].ColorBackground(secondary_color)                        ;
   Buttons[1].ColorBorder(clrMediumSeaGreen)                           ;
   Buttons[1].Pressed(false);
   Dialog.Add(Buttons[1]);

   Buttons[2].Create(0,"OpenSell",0,126,40,0,0)                      ;
   Buttons[2].Text("SELL SPREAD")                                     ;
   Buttons[2].FontSize(9)                                          ;
   Buttons[2].Height(25)                                            ;
   Buttons[2].Width(120)                                            ;
   Buttons[2].Color(clrWhite)                                       ;
   Buttons[2].ColorBackground(clrCrimson)                               ;
   Buttons[2].ColorBorder(clrFireBrick)                                 ;
   Buttons[2].Pressed(false);
   Dialog.Add(Buttons[2]);

   Buttons[3].Create(0,"CloseAll",0,5,64,0,0)                      ;
   Buttons[3].Text("CLOSE ALL TRADES")                                     ;
   Buttons[3].FontSize(9)                                          ;
   Buttons[3].Height(25)                                            ;
   Buttons[3].Width(242)                                            ;
   Buttons[3].Color(clrWhite)                                       ;
   Buttons[3].ColorBackground(clrCrimson)                             ;
   Buttons[3].ColorBorder(clrBlack)                                 ;
   Buttons[3].Pressed(false);
   Dialog.Add(Buttons[3]);

   Buttons[4].Create(0,"Apply",0,5,275,0,0)                      ;
   Buttons[4].Text("Apply")                                     ;
   Buttons[4].FontSize(9)                                          ;
   Buttons[4].Height(25)                                            ;
   Buttons[4].Width(242)                                            ;
   Buttons[4].Color(clrWhite)                                       ;
   Buttons[4].ColorBackground(secondary_color)                             ;
   Buttons[4].ColorBorder(clrMediumSeaGreen)                                 ;
   Buttons[4].Pressed(false);
   Dialog.Add(Buttons[4]);

   LabelsInputs[0].Create(0,"BenchmarkPR_Label",0,12,100,0,0);
   LabelsInputs[0].Text("Benchmark Spread: ");
   LabelsInputs[0].Color(clrWhite)                                       ;
   Dialog.Add(LabelsInputs[0]);
   InputParams[0].Create(0,"BenchmarkEdit",0,140,100,0,0);
   InputParams[0].Text(""+(string)BenchmarkPrice)                                          ;
   InputParams[0].FontSize(9)                                          ;
   InputParams[0].Height(20)                                           ;
   InputParams[0].Width(100)                                           ;
   Dialog.Add(InputParams[0]);

   LabelsInputs[1].Create(0,"BuyPR_Label",0,12,125,0,0);
   LabelsInputs[1].Text("BUY Threshold: ");
   LabelsInputs[1].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[1]);
   InputParams[1].Create(0,"BuyEdit",0,140,125,0,0);
   InputParams[1].Text(""+(string)BuySpread)                                          ;
   InputParams[1].FontSize(9)                                          ;
   InputParams[1].Height(20)                                           ;
   InputParams[1].Width(100)                                           ;
   Dialog.Add(InputParams[1]);

   LabelsInputs[2].Create(0,"SellPR_Label",0,12,150,0,0);
   LabelsInputs[2].Text("SELL Threshold: ");
   LabelsInputs[2].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[2]);
   InputParams[2].Create(0,"SellEdit",0,140,150,0,0);
   InputParams[2].Text(""+(string)SellSpread)                                          ;
   InputParams[2].FontSize(9)                                          ;
   InputParams[2].Height(20)                                           ;
   InputParams[2].Width(100)                                           ;
   Dialog.Add(InputParams[2]);

   LabelsInputs[3].Create(0,"Pair1Lots_Label_Label",0,12,175,0,0);
   LabelsInputs[3].Text("Pair 1 Lots: ");
   LabelsInputs[3].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[3]);
   InputParams[3].Create(0,"Lot1Edit",0,140,175,0,0);
   InputParams[3].Text(""+(string)Symbol1Lots)                                          ;
   InputParams[3].FontSize(9)                                          ;
   InputParams[3].Height(20)                                           ;
   InputParams[3].Width(100)                                           ;
   Dialog.Add(InputParams[3]);

   LabelsInputs[4].Create(0,"Pair2Lots_Label",0,12,200,0,0);
   LabelsInputs[4].Text("Pair 2 Lots: ");
   LabelsInputs[4].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[4]);
   InputParams[4].Create(0,"Lot2Edit",0,140,200,0,0);
   InputParams[4].Text(""+(string)Symbol2Lots)                                          ;
   InputParams[4].FontSize(9)                                          ;
   InputParams[4].Height(20)                                           ;
   InputParams[4].Width(100)                                           ;
   Dialog.Add(InputParams[4]);

   LabelsInputs[5].Create(0,"TP_Label",0,12,225,0,0);
   LabelsInputs[5].Text("TP $ : ");
   LabelsInputs[5].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[5]);
   InputParams[5].Create(0,"TPEdit",0,140,225,0,0);
   InputParams[5].Text(""+(string)DollarTP)                                          ;
   InputParams[5].FontSize(9)                                          ;
   InputParams[5].Height(20)                                           ;
   InputParams[5].Width(100)                                           ;
   Dialog.Add(InputParams[5]);

   LabelsInputs[6].Create(0,"SL_Label",0,12,250,0,0);
   LabelsInputs[6].Text("SL $ : ");
   LabelsInputs[6].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[6]);
   InputParams[6].Create(0,"SLEdit",0,140,250,0,0);
   InputParams[6].Text(""+(string)DollarSL)                                          ;
   InputParams[6].FontSize(9)                                          ;
   InputParams[6].Height(20)                                           ;
   InputParams[6].Width(100)                                           ;
   Dialog.Add(InputParams[6]);


   LabelsInputs[7].Create(0,"Pnl_Label",0,260,100,0,0);
   LabelsInputs[7].Text("PNL: ");
   LabelsInputs[7].Color(clrWhite)                                       ;
   Dialog.Add(LabelsInputs[7]);
   LabelsValues[0].Create(0,"Pnl_Value",0,335,100,0,0);
   LabelsValues[0].Text("0.00");
   LabelsValues[0].Color(clrWhite)                                       ;
   Dialog.Add(LabelsValues[0]);
   
   Stats_Lbl[0].Create(0,"DeltaHigh_Label",0,260,120,0,0);
   Stats_Lbl[0].Text("Delta High: ");
   Stats_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[0]);
   StatsValues_Lbl[0].Create(0,"DeltaHigh_Value",0,335,120,0,0);
   StatsValues_Lbl[0].Text("0.00");
   StatsValues_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[0]);
   
   Stats_Lbl[1].Create(0,"DeltaLow_Label",0,260,140,0,0);
   Stats_Lbl[1].Text("Delta Low: ");
   Stats_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[1]);
   StatsValues_Lbl[1].Create(0,"DeltaLow_Value",0,335,140,0,0);
   StatsValues_Lbl[1].Text("0.00");
   StatsValues_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[1]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int isOrdersTotal(int mg)
  {
   int count =0;
   int total = OrdersTotal();
   for(int i = 0 ; i<total; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         if(OrderMagicNumber()==mg /*&& OrderSymbol()== Symbol()*/)
           {
            count+=1;
           }
        }
     }
   return count;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsNewBar()
  {
   static datetime RegBarTime=0;
   datetime ThisBarTime=Time[0];
   if(ThisBarTime==RegBarTime)
     {
      return false;
     }
   else
     {
      RegBarTime=ThisBarTime;
      return true;
     }
  }
//getEquity(): double return total equity for all open orders
double getPnL()
  {
   double PnL=0;
   int total = OrdersTotal();
   for(int i = 0 ; i<total; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         PnL+=OrderProfit();
        }
     }
   return PnL;
  }

//getEquity(): double return total equity open orders
//param: magic:int, symbol:string
double getPnL(int magic, string symbol)
  {
   double PnL=0;
   int total = OrdersTotal();

   for(int i = 0 ; i<total; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         if(OrderMagicNumber()==magic && OrderSymbol()== symbol)
           {
            PnL+=OrderProfit();
           }
        }
     }
   return PnL;
  }

//getEquity(): double return total equity for open orders
//param: magic:int
double getPnL(int magic)
  {
   double PnL =0;
   int total = OrdersTotal();
   for(int i = 0 ; i<total; i++)
     {
      if(OrderSelect(i,SELECT_BY_POS,MODE_TRADES)>0)
        {
         //OrderMagicNumber==magic?equity+=OrderProfit()
         if(OrderMagicNumber()==magic)
           {
            PnL+=OrderProfit();
           }
        }
     }
   return PnL;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsBuySpread(double spread)
  {
   double spreadDelta = GetBrokerSpreadDelta();
   double basePrice = (BenchmarkPrice-spreadDelta+BuySpread);

   bool isThresholdHit = spread <= basePrice ;
   if(isThresholdHit)
      PrintSpreads("BUY SPREAD  ");//Print("BUY Spread: ",spread," Diff: ",isThresholdHit, " BasePrice: ",basePrice);
   return (isThresholdHit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSellSpread(double spread)
  {
   double spreadDelta = GetBrokerSpreadDelta();
   double basePrice = (BenchmarkPrice+spreadDelta+SellSpread);
   bool isThresholdHit = spread >= basePrice;
   if(isThresholdHit)
      PrintSpreads("SELL SPREAD  ");//("SELL Spread: ",spread," Diff: ",isThresholdHit, " BasePrice: ",basePrice);

   return (isThresholdHit);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool PlaceOrderPair(int opX, double pX, int opY, double pY)
  {
   PrintSpreads("Placing orders::  ");
   int ticketX = OrderSend(Symbol1,opX,Symbol1Lots,pX,33,0,0,_Comment,Magic,0,Yellow);

   int ticketY = OrderSend(Symbol2,opY,Symbol2Lots,pY,33,0,0,_Comment,Magic,0,Yellow);
   return false;
//return ();
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool CloseAllOrders(int Magic_Numbe)
  {
// int Slippage =33;
   PrintSpreads("Closing Orders:: ");
   int total= OrdersTotal();
   for(int ii=total-1; ii>=0; ii--)
     {
      if(OrderSelect(ii,SELECT_BY_POS)==true)
        {
         if(OrderMagicNumber()==Magic_Numbe)
           {
            if(OrderType()==OP_BUY)
              {
               if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_BID),33,clrAntiqueWhite))
                  Print("Order Send Failed with Error[",GetLastError(),"]");
               //continue;
              }
            if(OrderType()==OP_SELL)
              {
               if(!OrderClose(OrderTicket(),OrderLots(),MarketInfo(OrderSymbol(),MODE_ASK),33,clrAntiqueWhite))
                  Print("Order Send Failed with Error[",GetLastError(),"]");
               //continue;
              }
           }
        }
     }
   if(isOrdersTotal(Magic_Numbe)==0)
      return true;
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintSpreads(string entryMsg)
  {
   double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol1,SYMBOL_ASK);
   double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   double spreadAskBid = SymbolInfoDouble(Symbol1,SYMBOL_ASK) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   Print(entryMsg+"  Bid-Bid Spread: "+DoubleToString(spread,2)+" | Bid-Ask spread: "+DoubleToString(spreadBidAsk,2)+" | Ask-Bid spread: "+DoubleToString(spreadAskBid,2));
   Print("Symbol1 Bid: "+DoubleToStr(SymbolInfoDouble(Symbol1,SYMBOL_BID),2)+" | Symbol1 Ask: "+DoubleToString(SymbolInfoDouble(Symbol1,SYMBOL_ASK),2));
   Print("Symbol2 Bid: "+DoubleToStr(SymbolInfoDouble(Symbol2,SYMBOL_BID),2)+" | Symbol2 Ask: "+DoubleToString(SymbolInfoDouble(Symbol2,SYMBOL_ASK),2));

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetBrokerSpreadDelta()
  {
   double delta = MarketInfo(Symbol1,MODE_SPREAD) + MarketInfo(Symbol2,MODE_SPREAD) ;
   return delta*MarketInfo(Symbol1,MODE_POINT);
  }

//+------------------------------------------------------------------+
void DeltaLabelsUpdate(double spread){
   if(deltaHigh == 0.0 && deltaLow ==0.0){
      deltaHigh = spread;
      deltaLow  = spread;
   }
   if(deltaLow>0.0 && spread<= deltaLow){
      deltaLow = spread;
   }
   deltaHigh = spread>deltaHigh ? spread: deltaHigh;
   StatsValues_Lbl[0].Text(DoubleToString( deltaHigh , 2));
   StatsValues_Lbl[1].Text(DoubleToString( deltaLow , 2));
}
void SpreadValuesUpdate(double spread, double brokerspread){
   Buttons[0].Text("Spread:  "+DoubleToString(spread,2)+"  |  BrokerSpread: "+(DoubleToString(brokerspread,2)));

}