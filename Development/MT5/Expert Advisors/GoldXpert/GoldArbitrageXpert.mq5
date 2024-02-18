//+------------------------------------------------------------------+
//|                                           GoldArbitrageXpert.mq5 |
//|                                    Copyright 2023, Zobad Mahmood |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Zobad Mahmood"
#property link      "https://www.mql5.com"
#property version   "1.00"
//GUI
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
#include <Trade\Trade.mqh>
#include <Trade\TerminalInfo.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\SymbolInfo.mqh>
enum EntryType
  {
   BUY_SPREAD =1, //Buy Spread
   SELL_SPREAD = -1 //Sell Spread
  };


//--- input parameters
input string      Magic = "814";
input EntryType Type= SELL_SPREAD; //EntryType
input string   Symbol1 = "NASf";
input string   Symbol2 = "NAS100";
input bool     AllowTrade = false;
input double   Symbol1Lots    = 0.05;
input double   Symbol2Lots    = 1;
input string   _Comment = "Synthetic Spread Trader" ;
input bool     UseDollarTP=false;
input bool     UseDollarSL=false;
input bool     UseGrid        = false;
input int      LegsAllowed    = 3;

//-------Input variables from GUI
double   BenchmarkPrice = 164.5;
double   SellSpread     = 1;
double   BuySpread      = 5;
double     LegDollarTP       = 100;
double      DollarTP       = 100;
double      DollarSL       =-500;
double   GridThreshold = 0.1;
//--------Stats variables
double deltaHigh = 0.0;
double deltaLow = 0.0;

int dayToday =0;
//-----Variables
CEdit   InputParams[9];
CDialog Dialog;
CLabel  LabelsInputs[10];
CLabel  LabelsValues[2];
CLabel  Stats_Lbl[6];
CLabel  StatsValues_Lbl[6];
CButton Buttons[5];

color DialogColor= C'16,21,43';
string FontName = "Segoe UI";

CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CTrade trade;
CTerminalInfo  TerminalInfo;

//----------------------

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetTimer(1);
   trade.SetExpertMagicNumber(Magic);
   InitializeGUI();
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
   
   //update GUI
   SpreadValuesUpdate(spreadBidAsk, brokerSpread);
   DeltaLabelsUpdate(spreadBidAsk);
   GUILegsUpdate();
   LabelsValues[0].Text(DoubleToString(getPnL(Magic),2));
   double totalOrders = isOrdersTotal(Magic);
   
   if(totalOrders > 0){
      int legs = isOrdersLegsTotal(Magic);
      bool isSignalGrid = isGridSignal(legs);
      double pnl = getPnL(Magic);
      if(isSignalGrid && AllowTrade && Type == SELL_SPREAD){
         PlaceOrderPair(POSITION_TYPE_SELL,POSITION_TYPE_BUY);
      }
      else if(isSignalGrid && AllowTrade && Type == BUY_SPREAD){
         PlaceOrderPair(POSITION_TYPE_BUY,POSITION_TYPE_SELL);
      }
      if(UseDollarTP && pnl >= DollarTP){
         Print("Reached TP Target. Closing positions");
         PrintSpreadsII("Closing Positions-----TP$ Hit");
         CloseAllOrders();
        }
      else if(UseDollarSL && pnl <= DollarSL){
         Print("SL Limit hit. Closing positions");
         PrintSpreadsII("Closing Positions-----SL$ Hit");         
         CloseAllOrders();
       }
     }
     //new entry
     else{
       if(IsBuySpread(spreadBidAsk) && totalOrders == 0 && AllowTrade && Type ==BUY_SPREAD){
         PlaceOrderPair(POSITION_TYPE_BUY,POSITION_TYPE_SELL);
         //Trade
       }
      else if(IsSellSpread(spreadBidAsk) && totalOrders == 0 && AllowTrade && Type == SELL_SPREAD){
            //Trade
         PlaceOrderPair(POSITION_TYPE_SELL,POSITION_TYPE_BUY);
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
//| Trade function                                                   |
//+------------------------------------------------------------------+
void OnTrade()
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
   if(id == CHARTEVENT_OBJECT_CLICK){
      if(sparam == "")
         return;
      else if(sparam == "OpenBuy"){
          if(Type == BUY_SPREAD){
             Print("Opening Buy spread");
             PlaceOrderPair(POSITION_TYPE_BUY,POSITION_TYPE_SELL);
            }      
          else{
            Print("Disabled");
          }
          Buttons[1].Pressed(false);
      }
      else if(sparam == "OpenSell"){
         if(Type == SELL_SPREAD){
            Print("Opening sell spread");
            PlaceOrderPair(POSITION_TYPE_SELL,POSITION_TYPE_BUY);
         }
         else{
            Print("Disabled");
         }
         Buttons[2].Pressed(false);
      }
      else if(sparam == "CloseAll"){
         Print("Closing All");
         Buttons[3].Pressed(false);
         CloseAllOrders();
      }
      else if(sparam == "Apply"){
         Print("Applying params");
         Buttons[4].Pressed(false);
         ApplyParams();
      }
     }
     ChartRedraw();
  }
//+------------------------------------------------------------------+

//Initialize GUI
void InitializeGUI()
  {
   int width = 450, height = 400;
   Dialog.Create(ChartID(),"GoldArbitrageXpert",0,5,20,width,height);
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

   Buttons[4].Create(0,"Apply",0,5,300,0,0)                      ;
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

   LabelsInputs[7].Create(0,"Grid_LBL",0,12,175,0,0)                      ;
   LabelsInputs[7].Text("Grid Threshold: ");
   LabelsInputs[7].Color(clrWhite);
   Dialog.Add(LabelsInputs[7]);
   InputParams[7].Create(0,"Grid_Edit",0,140,175,0,0);
   InputParams[7].Text(""+(string)GridThreshold)                                          ;
   InputParams[7].FontSize(9)                                          ;
   InputParams[7].Height(20)                                           ;
   InputParams[7].Width(100)                                           ;
   Dialog.Add(InputParams[7]);

   LabelsInputs[8].Create(0,"LegTP_LBL",0,12,200,0,0)                      ;
   LabelsInputs[8].Text("Leg TP$: ");
   LabelsInputs[8].Color(clrWhite);
   Dialog.Add(LabelsInputs[8]);
   InputParams[8].Create(0,"LegTP_Edit",0,140,200,0,0);
   InputParams[8].Text(""+(string)LegDollarTP)                                          ;
   InputParams[8].FontSize(9)                                          ;
   InputParams[8].Height(20)                                           ;
   InputParams[8].Width(100)                                           ;
   Dialog.Add(InputParams[8]);


   LabelsInputs[5].Create(0,"TP_Label",0,12,225,0,0);
   LabelsInputs[5].Text("Accumulative TP$ : ");
   LabelsInputs[5].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[5]);
   InputParams[5].Create(0,"TPEdit",0,140,225,0,0);
   InputParams[5].Text(""+(string)DollarTP)                                          ;
   InputParams[5].FontSize(9)                                          ;
   InputParams[5].Height(20)                                           ;
   InputParams[5].Width(100)                                           ;
   Dialog.Add(InputParams[5]);

   LabelsInputs[6].Create(0,"SL_Label",0,12,250,0,0);
   LabelsInputs[6].Text("Accumulative SL$ : ");
   LabelsInputs[6].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[6]);
   InputParams[6].Create(0,"SLEdit",0,140,250,0,0);
   InputParams[6].Text(""+(string)DollarSL)                                          ;
   InputParams[6].FontSize(9)                                          ;
   InputParams[6].Height(20)                                           ;
   InputParams[6].Width(100)                                           ;
   Dialog.Add(InputParams[6]);

   LabelsInputs[9].Create(0,"Pnl_Label",0,260,100,0,0);
   LabelsInputs[9].Text("PNL: ");
   LabelsInputs[9].Color(clrWhite)                                       ;
   Dialog.Add(LabelsInputs[9]);
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

   Stats_Lbl[2].Create(0,"Legs_Label",0,260,160,0,0);
   Stats_Lbl[2].Text("Legs: ");
   Stats_Lbl[2].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[2]);
   StatsValues_Lbl[2].Create(0,"Legs_Value",0,335,160,0,0);
   StatsValues_Lbl[2].Text("0");
   StatsValues_Lbl[2].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[2]);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ApplyParams()
  {
   BenchmarkPrice = StringToDouble(InputParams[0].Text());//Benchmark
   BuySpread = StringToDouble(InputParams[1].Text());//buy spread
   SellSpread= StringToDouble(InputParams[2].Text());//sell spread
//Symbol1Lots = StringToDouble(InputParams[3].Text()); //pair1 lots
//Symbol2Lots = StringToDouble(InputParams[4].Text());//pair2 Lots
   DollarTP = StringToDouble(InputParams[5].Text());//TP$
   DollarSL = StringToDouble(InputParams[6].Text());//SL$
   GridThreshold = StringToDouble(InputParams[7].Text());//Grid Threshold
   LegDollarTP   = StringToDouble(InputParams[8].Text());
   Print("Parameters applied: Benchmark: "+BenchmarkPrice+" | BuySpread: ["+BuySpread+"] | SellSpread: ["+SellSpread+"] | Symbol1Lots: ["+Symbol1Lots+"] | Symbol2Lots: ["+Symbol2Lots+"] | DollarTP: ["+DollarTP+"] | DollarSL: ["+DollarSL+"] | Grid Threshold: ["+GridThreshold+"] ");

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void PrintSpreads(string entryMsg){
   double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol1,SYMBOL_ASK);
   double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   double spreadAskBid = SymbolInfoDouble(Symbol1,SYMBOL_ASK) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   Print(entryMsg+"  Bid-Bid Spread: "+DoubleToString(spread,2)+" | Bid-Ask spread: "+DoubleToString(spreadBidAsk,2)+" | Ask-Bid spread: "+DoubleToString(spreadAskBid,2));
   Print("Symbol1 Bid: "+DoubleToString(SymbolInfoDouble(Symbol1,SYMBOL_BID),2)+" | Symbol1 Ask: "+DoubleToString(SymbolInfoDouble(Symbol1,SYMBOL_ASK),2));
   Print("Symbol2 Bid: "+DoubleToString(SymbolInfoDouble(Symbol2,SYMBOL_BID),2)+" | Symbol2 Ask: "+DoubleToString(SymbolInfoDouble(Symbol2,SYMBOL_ASK),2));

  }
void PrintSpreadsII(string entryMsg)
  {
   double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol1,SYMBOL_ASK);
   double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   double spreadAskBid = SymbolInfoDouble(Symbol1,SYMBOL_ASK) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   Print(entryMsg+" | Bid-Ask spread: "+DoubleToString(spreadBidAsk,2));
   Print("Symbol1 Bid: "+DoubleToString(SymbolInfoDouble(Symbol1,SYMBOL_BID),2)+" | Symbol1 Ask: "+DoubleToString(SymbolInfoDouble(Symbol1,SYMBOL_ASK),2));
   Print("Symbol2 Bid: "+DoubleToString(SymbolInfoDouble(Symbol2,SYMBOL_BID),2)+" | Symbol2 Ask: "+DoubleToString(SymbolInfoDouble(Symbol2,SYMBOL_ASK),2));

  }
double GetBrokerSpreadDelta()
  {
  /*
  double bid = SymbolInfoDouble(Symbol(),SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol(),SYMBOL_ASK);*/
   double delta = SymbolInfoInteger(Symbol1,SYMBOL_SPREAD) + SymbolInfoInteger(Symbol2,SYMBOL_SPREAD) ;
   return delta*SymbolInfoDouble(Symbol1,SYMBOL_POINT);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double GetSymbolSpreadDelta()
  {
   double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
   double ask = SymbolInfoDouble(Symbol1,SYMBOL_ASK);
   double spread =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   return spread;
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
   string typeStrng = Type == BUY_SPREAD ? "BUY" : "SELL";
   string text = "Spread:  "+DoubleToString(spread,2)+"  |  BrokerSpreads: "+(DoubleToString(brokerspread,2))+" | Type: "+typeStrng;
   Buttons[0].Text(text);
   
}
bool IsBuySpread(double spread)
  {
   if(Type == SELL_SPREAD)
      return false;
      
   double thresh = BuySpread;
   if (thresh<0){
      thresh = -thresh;
      Print("thresh: "+(thresh));
   }
      
   double spreadDelta = GetBrokerSpreadDelta();
   double basePrice = (BenchmarkPrice-spreadDelta-BuySpread);

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
  if(Type == BUY_SPREAD)
      return false;
      
   double spreadDelta = GetBrokerSpreadDelta();
   double basePrice = (BenchmarkPrice+spreadDelta+SellSpread);
   bool isThresholdHit = spread >= basePrice;
   if(isThresholdHit)
      PrintSpreads("SELL SPREAD  ");//("SELL Spread: ",spread," Diff: ",isThresholdHit, " BasePrice: ",basePrice);

   return (isThresholdHit);
  }
void GUILegsUpdate(){
   int legs = isOrdersLegsTotal(Magic);
   StatsValues_Lbl[2].Text((string)legs);
}
int isLegDirection(int mg){
   int count =0;
   int total = PositionsTotal();
   for(int i = 0 ; i<total; i++){
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol1  && PositionGetInteger(POSITION_MAGIC)==Magic){
            if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_BUY)return 1;
            else if(PositionGetInteger(POSITION_TYPE)==POSITION_TYPE_SELL)return -1;
           }
        }
     }
   return count;
} 
int isOrdersLegsTotal(int mg){
   int k = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(PositionGetTicket(i)){
         if(PositionGetString(POSITION_SYMBOL)==Symbol1  && PositionGetInteger(POSITION_MAGIC)==Magic)
            k++;
      }
   }
   return(k);
}
int isOrdersTotal(int mg){
   int k = 0;
   for(int i=0; i<PositionsTotal(); i++){
      if(PositionGetTicket(i)){
         if(PositionGetInteger(POSITION_MAGIC)==mg)
            k++;
      }
   }
   return(k);
}
double getPnL(int magic){   
   double  PnL=0;
   for(int i=0; i<PositionsTotal(); i++){
      if(PositionGetTicket(i)){
         if(PositionGetInteger(POSITION_MAGIC)==Magic){
            PnL=PnL+PositionGetDouble(POSITION_PROFIT);
            PnL+= PositionGetDouble(POSITION_SWAP);
         }            
      }
    }
    return PnL;
}
void CloseAllOrders(){
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==Magic)
            if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
            } 
}
bool isGridSignal(int legs)
  {
   if(UseGrid == false || legs >= LegsAllowed ) return false;
   
   const int BUY =1, SELL =-1;
   int direction = isLegDirection(Magic);
   
   double spread = GetSymbolSpreadDelta();
   double bSpreadDelta = GetBrokerSpreadDelta();
   double bp = 0.0;
   
   bp = direction ==SELL?  (BenchmarkPrice+bSpreadDelta+SellSpread) : direction==BUY? (BenchmarkPrice-bSpreadDelta-BuySpread):0.0;
   if(bp<=0.0) return false;
   
   if(direction == SELL && Type == SELL_SPREAD){
      double grid_threshold = 0.0;
      grid_threshold = bp+ (GridThreshold * legs);
      Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
         
      if(  spread  >= grid_threshold){
         Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
         PrintSpreadsII("SELL SPREAD GRID HIT------>");
         return true;
      }
   }
   if(direction == BUY && Type == BUY_SPREAD){
      double grid_threshold = 0.0;
      grid_threshold = bp - (GridThreshold * legs);
      Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
      
      if(  spread  <= grid_threshold){
         Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
         PrintSpreadsII("BUY SPREAD GRID HIT------>");
         return true;
      }
   }
   
   bool isThresholdHit = spread >= bp;
   if(isThresholdHit)
      PrintSpreads("SELL SPREAD  ");//("SELL Spread: ",spread," Diff: ",isThresholdHit, " BasePrice: ",basePrice);

   return false;
  }
bool PlaceOrderPair(int opX, int opY){
   PrintSpreads("Placing orders::  ");
   if(opX == POSITION_TYPE_BUY){
      if(trade.Buy(Symbol1Lots, Symbol1,SymbolInfoDouble(Symbol1,SYMBOL_ASK),NULL,NULL,_Comment)){
         if(trade.Sell(Symbol2Lots,Symbol2,SymbolInfoDouble(Symbol2,SYMBOL_BID),NULL,NULL,_Comment))
            return true;
      }
   }
   else if(opX == POSITION_TYPE_SELL){
      if(trade.Sell(Symbol1Lots, Symbol1,SymbolInfoDouble(Symbol1,SYMBOL_BID),NULL,NULL,_Comment)){
         if(trade.Buy(Symbol2Lots,Symbol2,SymbolInfoDouble(Symbol2,SYMBOL_ASK),NULL,NULL,_Comment))
            return true;
      }
   }
   return false;
//return ();
}