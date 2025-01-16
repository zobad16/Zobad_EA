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
input string   Symbol1 = "GOLDFEB25";
input string   Symbol2 = "XAUUSD";
input bool     AllowTrade = false;
input double   Symbol1Lots    = 1;
input double   Symbol2Lots    = 1;
input string   _Comment = "SSS" ;
input bool     UseDollarTP=false;
input bool     UsePointTP=true;
input bool     UseDollarSL=false;
input bool     UseGrid        = false;
input int      LegsAllowed    = 3;

//-------Input variables from GUI
double   BenchmarkPrice = 15.5;
double   SellSpread     = 1.0;
double   BuySpread      = 4;
double   LegDollarTP    = 100;
double   DollarTP       = 500;
double   PointTP        = 1.5;
double   DollarSL       =-2000;
double   GridThreshold = 1.0;
//--------Stats variables
double deltaHigh = 0.0;
double deltaLow = 0.0;
double riskFreeRate = 0.0525;  // 5% annual risk-free rate
double storageRate = 0.01;   // 1% annual storage cost
   
int dayToday =0;
//-----Variables
CEdit   InputParams[11];
CDialog Dialog;
CLabel  LabelsInputs[11];
CLabel  LabelsValues[2];
CLabel  Stats_Lbl[6];
CLabel  StatsValues_Lbl[6];
CLabel  EntryAtLbl;
CLabel  EntryAtValue;
CLabel  StatsGrid_Lbl[6];
CLabel  StatsGridValues_Lbl[6];
CLabel  AvgSpreadLbl;
CLabel  AvgSpreadValue;
CButton Buttons[7];

color DialogColor= C'16,21,43';
string FontName = "Segoe UI";

CSymbolInfo    m_symbol;
CPositionInfo  m_position;
CTrade trade;
CTerminalInfo  TerminalInfo;
bool debug = false;

datetime nextResetTime = 0;  // Global variable for next reset time
//----------------------

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   EventSetMillisecondTimer(250);
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
   DeltaLabelsReset();
   if(debug == false && IsNewTick(Symbol1) && IsNewTick(Symbol2)){
      double brokerSpread = GetBrokerSpreadDelta();
      double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
      double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
      double spreadAskBid =  SymbolInfoDouble(Symbol1,SYMBOL_ASK) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
      
      //update GUI
      if(Type == SELL_SPREAD)SpreadValuesUpdate(spreadBidAsk, brokerSpread);
      if(Type == BUY_SPREAD)SpreadValuesUpdate(spreadAskBid, brokerSpread);
      DeltaLabelsUpdate(spreadBidAsk);
      GUILegsUpdate();
      EntryLevelUpdate(brokerSpread);
      double totalOrders = isOrdersTotal(Magic);
      
      if(totalOrders > 0){
         int legs = isOrdersLegsTotal(Magic);
         bool isSignalGrid = isGridSignal(legs);
         AverageSpreadUpdate(CalculateAverageSpread());
         //double pnl = getPnL(Magic);
         if(isSignalGrid && AllowTrade && Type == SELL_SPREAD){
            PlaceOrderPair(POSITION_TYPE_SELL,POSITION_TYPE_BUY);
         }
         else if(isSignalGrid && AllowTrade && Type == BUY_SPREAD){
            PlaceOrderPair(POSITION_TYPE_BUY,POSITION_TYPE_SELL);
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
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
   double brokerSpread = GetBrokerSpreadDelta();
   double pnl = getPnL(Magic);
   double avg_spread = CalculateAverageSpread();
   double spread = SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   double spreadBidAsk =  SymbolInfoDouble(Symbol1,SYMBOL_BID) - SymbolInfoDouble(Symbol2,SYMBOL_ASK) ;
   LabelsValues[0].Text(DoubleToString(pnl,2));
   if(!AllowTrade)return;   
   
   //Print("AVG spread ",avg_spread, " | diff: ", avg_spread+PointTP);
   if(UseDollarTP && pnl >= DollarTP){
      Print("Reached TP Target. Closing positions");
      PrintSpreadsII("Closing Positions-----TP$ Hit");
      CloseAllOrders();
     }
   else if(UsePointTP && ((Type ==  BUY_SPREAD) && spread > avg_spread+PointTP+brokerSpread)){
      Print("Reached TP Points Target. Closing positions");
      Print("Spread: ", spread, " | spread+tppoint: ",DoubleToString(avg_spread+PointTP,2)," | broker spread: ",DoubleToString(brokerSpread,2));
      PrintSpreadsII("Closing Positions-----TP$ Hit");
      CloseAllOrders();
     }
   else if(UsePointTP && ((Type ==  SELL_SPREAD) && (spread-brokerSpread < (avg_spread-PointTP-brokerSpread)) )){
      Print("Reached TP Points Target. Closing positions");
      Print("Spread: ", spread, " | spread+tppoint: ",DoubleToString(avg_spread-PointTP,2)," | broker spread: ",DoubleToString(brokerSpread,2));
      PrintSpreadsII("Closing Positions-----TP$ Hit");
      CloseAllOrders();
     }
   else if(UseDollarSL && pnl <= DollarSL){
      Print("SL Limit hit. Closing positions");
      PrintSpreadsII("Closing Positions-----SL$ Hit");         
      CloseAllOrders();
    }
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
      else if(sparam == "CloseLast"){
         Print("Closing Last Order");
         Buttons[3].Pressed(false);
         CloseLastOrder();
      }
      else if(sparam == "CloseAll"){
         Print("Closing All");
         Buttons[4].Pressed(false);
         CloseAllOrders();
      }
      else if(sparam == "Apply"){
         Print("Applying params");
         Buttons[5].Pressed(false);
         ApplyParams();
      }
     }
     ChartRedraw();
  }
//+------------------------------------------------------------------+

//Initialize GUI
void InitializeGUI()
  {
   int width = 540, height = 400;
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
   Buttons[0].FontSize(10)                                          ;
   Buttons[0].Font(FontName);
   Buttons[0].Height(30)                                            ;
   Buttons[0].Width(480)                                            ;
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

   Buttons[3].Create(0,"CloseLast",0,5,64,0,0)                      ;
   Buttons[3].Text("CLOSE LAST TRADE")                                     ;
   Buttons[3].FontSize(9)                                          ;
   Buttons[3].Height(25)                                            ;
   Buttons[3].Width(242)                                            ;
   Buttons[3].Color(clrWhite)                                       ;
   Buttons[3].ColorBackground(clrCrimson)                             ;
   Buttons[3].ColorBorder(clrBlack)                                 ;
   Buttons[3].Pressed(false);
   Dialog.Add(Buttons[3]);
   
   Buttons[4].Create(0,"CloseAll",0,5,88,0,0)                      ;
   Buttons[4].Text("CLOSE ALL TRADES")                                     ;
   Buttons[4].FontSize(9)                                          ;
   Buttons[4].Height(25)                                            ;
   Buttons[4].Width(242)                                            ;
   Buttons[4].Color(clrWhite)                                       ;
   Buttons[4].ColorBackground(clrCrimson)                             ;
   Buttons[4].ColorBorder(clrBlack)                                 ;
   Buttons[4].Pressed(false);
   Dialog.Add(Buttons[4]);
   
   Buttons[5].Create(0,"Apply",0,5,320,0,0)                      ;
   Buttons[5].Text("Apply")                                     ;
   Buttons[5].FontSize(9)                                          ;
   Buttons[5].Height(25)                                            ;
   Buttons[5].Width(242)                                            ;
   Buttons[5].Color(clrWhite)                                       ;
   Buttons[5].ColorBackground(secondary_color)                             ;
   Buttons[5].ColorBorder(clrMediumSeaGreen)                                 ;
   Buttons[5].Pressed(false);
   Dialog.Add(Buttons[5]);

   LabelsInputs[0].Create(0,"BenchmarkPR_Label",0,12,120,0,0);
   LabelsInputs[0].Text("Benchmark Spread: ");
   LabelsInputs[0].Color(clrWhite)                                       ;
   Dialog.Add(LabelsInputs[0]);
   InputParams[0].Create(0,"BenchmarkEdit",0,160,120,0,0);
   InputParams[0].Text(""+(string)BenchmarkPrice)                                          ;
   InputParams[0].FontSize(9)                                          ;
   InputParams[0].Height(20)                                           ;
   InputParams[0].Width(80)                                           ;
   Dialog.Add(InputParams[0]);

   LabelsInputs[1].Create(0,"BuyPR_Label",0,12,145,0,0);
   LabelsInputs[1].Text("BUY Threshold: ");
   LabelsInputs[1].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[1]);
   InputParams[1].Create(0,"BuyEdit",0,160,145,0,0);
   InputParams[1].Text(""+(string)BuySpread)                                          ;
   InputParams[1].FontSize(9)                                          ;
   InputParams[1].Height(20)                                           ;
   InputParams[1].Width(80)                                           ;
   Dialog.Add(InputParams[1]);

   LabelsInputs[2].Create(0,"SellPR_Label",0,12,170,0,0);
   LabelsInputs[2].Text("SELL Threshold: ");
   LabelsInputs[2].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[2]);
   InputParams[2].Create(0,"SellEdit",0,160,170,0,0);
   InputParams[2].Text(""+(string)SellSpread)                                          ;
   InputParams[2].FontSize(9)                                          ;
   InputParams[2].Height(20)                                           ;
   InputParams[2].Width(80)                                           ;
   Dialog.Add(InputParams[2]);

   LabelsInputs[7].Create(0,"Grid_LBL",0,12,195,0,0)                      ;
   LabelsInputs[7].Text("Grid Threshold: ");
   LabelsInputs[7].Color(clrWhite);
   Dialog.Add(LabelsInputs[7]);
   InputParams[7].Create(0,"Grid_Edit",0,160,195,0,0);
   InputParams[7].Text(""+(string)GridThreshold)                                          ;
   InputParams[7].FontSize(9)                                          ;
   InputParams[7].Height(20)                                           ;
   InputParams[7].Width(80)                                           ;
   Dialog.Add(InputParams[7]);

   LabelsInputs[8].Create(0,"LegTP_LBL",0,12,220,0,0)                      ;
   LabelsInputs[8].Text("Leg TP$: ");
   LabelsInputs[8].Color(clrWhite);
   Dialog.Add(LabelsInputs[8]);
   InputParams[8].Create(0,"LegTP_Edit",0,160,220,0,0);
   InputParams[8].Text(""+(string)LegDollarTP)                                          ;
   InputParams[8].FontSize(9)                                          ;
   InputParams[8].Height(20)                                           ;
   InputParams[8].Width(80)                                           ;
   Dialog.Add(InputParams[8]);


   LabelsInputs[5].Create(0,"TP_Label",0,12,245,0,0);
   LabelsInputs[5].Text("Accumulative TP$ : ");
   LabelsInputs[5].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[5]);
   InputParams[5].Create(0,"TPEdit",0,160,245,0,0);
   InputParams[5].Text(""+(string)DollarTP)                                          ;
   InputParams[5].FontSize(9)                                          ;
   InputParams[5].Height(20)                                           ;
   InputParams[5].Width(80)                                           ;
   Dialog.Add(InputParams[5]);

   LabelsInputs[10].Create(0,"TPPoint_Label",0,12,270,0,0);
   LabelsInputs[10].Text("Accumulative TP Point : ");
   LabelsInputs[10].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[10]);
   InputParams[10].Create(0,"TPPEdit",0,160,270,0,0);
   InputParams[10].Text(""+(string)PointTP)                                          ;
   InputParams[10].FontSize(9)                                          ;
   InputParams[10].Height(20)                                           ;
   InputParams[10].Width(80)                                           ;
   Dialog.Add(InputParams[10]);
   
   LabelsInputs[6].Create(0,"SL_Label",0,12,295,0,0);
   LabelsInputs[6].Text("Accumulative SL$ : ");
   LabelsInputs[6].Color(clrWhite) ;
   Dialog.Add(LabelsInputs[6]);
   InputParams[6].Create(0,"SLEdit",0,160,295,0,0);
   InputParams[6].Text(""+(string)DollarSL)                                          ;
   InputParams[6].FontSize(9)                                          ;
   InputParams[6].Height(20)                                           ;
   InputParams[6].Width(80)                                           ;
   Dialog.Add(InputParams[6]);

   LabelsInputs[9].Create(0,"Pnl_Label",0,260,100,0,0);
   LabelsInputs[9].Text("PNL: ");
   LabelsInputs[9].Color(clrWhite)                                       ;
   Dialog.Add(LabelsInputs[9]);
   LabelsValues[0].Create(0,"Pnl_Value",0,365,100,0,0);
   LabelsValues[0].Text("0.00");
   LabelsValues[0].Color(clrWhite)                                       ;
   Dialog.Add(LabelsValues[0]);

   Stats_Lbl[0].Create(0,"DeltaHigh_Label",0,260,120,0,0);
   Stats_Lbl[0].Text("Delta High: ");
   Stats_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[0]);
   StatsValues_Lbl[0].Create(0,"DeltaHigh_Value",0,365,120,0,0);
   StatsValues_Lbl[0].Text("0.00");
   StatsValues_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[0]);

   Stats_Lbl[1].Create(0,"DeltaLow_Label",0,260,140,0,0);
   Stats_Lbl[1].Text("Delta Low: ");
   Stats_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[1]);
   StatsValues_Lbl[1].Create(0,"DeltaLow_Value",0,365,140,0,0);
   StatsValues_Lbl[1].Text("0.00");
   StatsValues_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[1]);

   Stats_Lbl[2].Create(0,"Legs_Label",0,260,160,0,0);
   Stats_Lbl[2].Text("Legs: ");
   Stats_Lbl[2].Color(clrWhite)                                       ;
   Dialog.Add(Stats_Lbl[2]);
   StatsValues_Lbl[2].Create(0,"Legs_Value",0,365,160,0,0);
   StatsValues_Lbl[2].Text("0");
   StatsValues_Lbl[2].Color(clrWhite)                                       ;
   Dialog.Add(StatsValues_Lbl[2]);
   
   EntryAtLbl.Create(0,"Next_Label",0,260,180,0,0);
   EntryAtLbl.Text("Entry: ");
   EntryAtLbl.Color(clrWhite)                                       ;
   Dialog.Add(EntryAtLbl);
   EntryAtValue.Create(0,"Next_Value",0,365,180,0,0);
   EntryAtValue.Text("0");
   EntryAtValue.Color(clrWhite)                                       ;
   Dialog.Add(EntryAtValue);
   
   //grid legs allowed
   //grid next entry
   //average point
   //CLabel  StatsGrid_Lbl[6];
   //CLabel  StatsGridValues_Lbl[6];
   StatsGrid_Lbl[0].Create(0,"GridLegsAllow_Label",0,260,200,0,0);
   StatsGrid_Lbl[0].Text("L-Allowed: ");
   StatsGrid_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(StatsGrid_Lbl[0]);
   StatsGridValues_Lbl[0].Create(0,"GridLegsAllowed_Value",0,365,200,0,0);
   StatsGridValues_Lbl[0].Text(IntegerToString(LegsAllowed));
   StatsGridValues_Lbl[0].Color(clrWhite)                                       ;
   Dialog.Add(StatsGridValues_Lbl[0]);
   
   StatsGrid_Lbl[1].Create(0,"NextG_Label",0,260,220,0,0);
   StatsGrid_Lbl[1].Text("Next Grid: ");
   StatsGrid_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(StatsGrid_Lbl[1]);
   StatsGridValues_Lbl[1].Create(0,"NextG_Value",0,365,220,0,0);
   StatsGridValues_Lbl[1].Text("0.0");
   StatsGridValues_Lbl[1].Color(clrWhite)                                       ;
   Dialog.Add(StatsGridValues_Lbl[1]);
   
   AvgSpreadLbl.Create(0,"AVGSPREAD_Label",0,260,240,0,0);
   AvgSpreadLbl.Text("AVG-SRD: ");
   AvgSpreadLbl.Color(clrWhite)                                       ;
   Dialog.Add(AvgSpreadLbl);
   AvgSpreadValue.Create(0,"AVGSPREAD_Value",0,365,240,0,0);
   AvgSpreadValue.Text("0");
   AvgSpreadValue.Color(clrWhite)                                       ;
   Dialog.Add(AvgSpreadValue);
   
  }
void InitializeGUIII()
  {
   int width = 500, height = 400;
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
   Buttons[0].FontSize(9)                                          ;
   Buttons[0].Font(FontName);
   Buttons[0].Height(30)                                            ;
   Buttons[0].Width(425)                                            ;
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
   
   EntryAtLbl.Create(0,"Next_Label",0,260,180,0,0);
   EntryAtLbl.Text("Entry: ");
   EntryAtLbl.Color(clrWhite)                                       ;
   Dialog.Add(EntryAtLbl);
   EntryAtValue.Create(0,"Next_Value",0,335,180,0,0);
   EntryAtValue.Text("0");
   EntryAtValue.Color(clrWhite)                                       ;
   Dialog.Add(EntryAtValue);
   
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
   PointTP  = StringToDouble(InputParams[10].Text());
   DollarSL = StringToDouble(InputParams[6].Text());//SL$
   GridThreshold = StringToDouble(InputParams[7].Text());//Grid Threshold
   LegDollarTP   = StringToDouble(InputParams[8].Text());
   Print("Parameters applied: Benchmark: "+BenchmarkPrice+" | BuySpread: ["+BuySpread+"] | SellSpread: ["+SellSpread+"] | Symbol1Lots: ["+Symbol1Lots+"] | Symbol2Lots: ["+Symbol2Lots+"] | DollarTP: ["+DollarTP+"]  | TPPoint: ["+PointTP+"] | DollarSL: ["+DollarSL+"] | Grid Threshold: ["+GridThreshold+"] ");

  }
bool CheckNewDay(){
   // First run or after midnight
    if(TimeCurrent() >= nextResetTime)
    {
        // Calculate next midnight
        MqlDateTime time;
        TimeToStruct(TimeCurrent(), time);
        time.hour = 0;
        time.min = 0;
        time.sec = 0;
        
        //Daily
        nextResetTime = StructToTime(time) + PeriodSeconds(PERIOD_D1);
         // Calculate next minute
        //nextResetTime = TimeCurrent() + 60;
        return true;
    }
   return false;
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
void AverageSpreadUpdate(double spread){
   AvgSpreadValue.Text(DoubleToString( spread , 2));
}
void DeltaLabelsReset(){
   if(CheckNewDay()){
      Print("New Day- Reset---------");
      deltaHigh = 0.0;
      deltaLow  = 0.0;
      StatsValues_Lbl[0].Text("0.0");
      StatsValues_Lbl[1].Text("0.0");
   }
}
void SpreadValuesUpdate(double spread, double brokerspread){
   double carryCost = CalculateGoldCarryCost(Symbol2,Symbol1,riskFreeRate,storageRate);
   double carryCostSpread = CalculateTheoraticalFuturePrice/*CalculateGoldCarryCost*/(Symbol2,Symbol1,riskFreeRate,storageRate);
   carryCostSpread = carryCostSpread- SymbolInfoDouble(Symbol2,SYMBOL_BID) ;
   string typeStrng = Type == BUY_SPREAD ? "BUY" : "SELL";
   string text = "Spread:  "+DoubleToString(spread,2)+"  |  B-Spreads: "+(DoubleToString(brokerspread,2))+" | cc: "+DoubleToString(carryCost,2)+" | cc-spread: "+DoubleToString(carryCostSpread,2);
   Buttons[0].Text(text);
   
}
void EntryLevelUpdate(double brokerspread){
   double netSpreadS = DoubleToString(BenchmarkPrice+brokerspread+SellSpread, Digits());
   double netSpreadB = DoubleToString(BenchmarkPrice-brokerspread-BuySpread,Digits());
   string value = "S: "+ netSpreadS+" | B: "+netSpreadB;
   EntryAtValue.Text(value);
}
void GridEntryLevelUpdate(double thresh){
   StatsGridValues_Lbl[1].Text(DoubleToString(thresh,2));
}
double CalculateAverageSpread(){
   double pricexlots1= 0.0, pricexlots2= 0.0, lots1=0.0, lots2=0.0;
   
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==Magic){
            if(m_position.Symbol() == Symbol1){
               lots1+= m_position.Volume();
               pricexlots1+= m_position.PriceOpen()*m_position.Volume();
            }
            else if(m_position.Symbol() == Symbol2){
               lots2+= m_position.Volume();
               pricexlots2+= m_position.PriceOpen()*m_position.Volume();
            }
         }
         
   double average_spread2 = (pricexlots1 - pricexlots2)/(lots1);
   
   return average_spread2;           
   
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
void GetLastOrderPrices(double &price1, double &price2){
   datetime time1=D'01.01.2004'; 
   datetime time2=D'01.01.2004';
   
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==Magic){
            if(m_position.Symbol() == Symbol1){
               if(m_position.Time() >= time1){
                  time1 = m_position.Time();
                  price1 = m_position.PriceOpen();
               }
            }else if(m_position.Symbol() == Symbol2){
               if(m_position.Time() >= time2){
                  time2 = m_position.Time();
                  price2 = m_position.PriceOpen();
               }
            }
         }
            
}
double GetLastOrderSpread(){
   datetime time1=D'01.01.2004'; 
   datetime time2=D'01.01.2004';
   
   double price1 =0.0, price2 =0.0;
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==Magic){
            if(m_position.Symbol() == Symbol1){
               if(m_position.Time() > time1){
                  time1 = m_position.Time();
                  price1 = m_position.PriceOpen();
               }
            }else if(m_position.Symbol() == Symbol2){
               if(m_position.Time() > time2){
                  time2 = m_position.Time();
                  price2 = m_position.PriceOpen();
               }
            }
         }
   //Print(price1," | ",price2);      
   if(price1 != 0.0 && price2 != 0.0)       
      return(price1 - price2);
   return 0.0;            
}
void CloseLastOrder(){
   double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
   ulong ticket1 = 0;
   ulong ticket2= 0;
   datetime time1=D'01.01.2004'; 
   datetime time2=D'01.01.2004';
   
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==Magic){
            if(m_position.Symbol() == Symbol1){
               if(m_position.Time() > time1){
                  ticket1 = m_position.Ticket();
                  time1 = m_position.Time();
               }
            }else if(m_position.Symbol() == Symbol2){
               if(m_position.Time() > time2){
                  ticket2 = m_position.Ticket();
                  time2 = m_position.Time();
               }
            }
         }
   if(ticket1 > 0 && ticket2>0){
      Print("Closing tickets -> ",ticket1," | ",ticket2);
      if(!trade.PositionClose(ticket1)){ // 
         Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",ticket1,", ",trade.ResultRetcodeDescription());
         return;
      }
      if(!trade.PositionClose(ticket2)){ // 
         Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",ticket1,", ",trade.ResultRetcodeDescription());
         return;
      }
   }   
}
void CloseAllOrders(){
   if(IsNewTick(Symbol1) && IsNewTick(Symbol2)){
      double bid = SymbolInfoDouble(Symbol2,SYMBOL_BID);
      for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
         if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
            if(m_position.Magic()==Magic)
               if(!trade.PositionClose(m_position.Ticket())){ // close a position by the specified m_symbol
                  Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",trade.ResultRetcodeDescription());
               } 
   }else{
      Print("Close All Cancelled- Stale prices");
   }
}
bool isGridSignal(int legs)
  {
   if(UseGrid == false || legs >= LegsAllowed ) return false;
   
   const int BUY =1, SELL =-1;
   int direction = isLegDirection(Magic);
   
   double spread = GetSymbolSpreadDelta();
   double bSpreadDelta = GetBrokerSpreadDelta();
   double lastOrderSpread = GetLastOrderSpread();
   //Print("1) ",price1," | 2) price2", price2);
   if(lastOrderSpread  == 0.0)return false;  
   
   if(direction == SELL && Type == SELL_SPREAD){
      double grid_threshold = 0.0;
      grid_threshold = lastOrderSpread+GridThreshold;
      //Print("Last order spread ",DoubleToString(lastOrderSpread,2)," | Next: ",DoubleToString(grid_threshold,2));
      //Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
      GridEntryLevelUpdate(grid_threshold);   
      if(  spread  >= grid_threshold){
         //Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
         //PrintSpreadsII("SELL SPREAD GRID HIT------>");
         return true;
      }
   }
   if(direction == BUY && Type == BUY_SPREAD){
      double grid_threshold = 0.0;
      grid_threshold = lastOrderSpread - GridThreshold ;
      //Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
      GridEntryLevelUpdate(grid_threshold);
      if(  spread  <= grid_threshold){
         //Print("BP : "+(string)bp+" | GridThreshold*Leg: "+(string)(GridThreshold*legs)+" | Next Leg Grid Threshold: "+(string)grid_threshold);
         //PrintSpreadsII("BUY SPREAD GRID HIT------>");
         return true;
      }
   }
   
   //bool isThresholdHit = spread >= bp;
   //if(isThresholdHit)
   //   PrintSpreads("SELL SPREAD  ");//("SELL Spread: ",spread," Diff: ",isThresholdHit, " BasePrice: ",basePrice);

   return false;
  }
bool PlaceOrderPair(int opX, int opY){
   PrintSpreads("Placing orders::  ");
   if(opX == POSITION_TYPE_BUY){
      if(trade.Buy(Symbol1Lots, Symbol1,SymbolInfoDouble(Symbol1,SYMBOL_ASK),NULL,NULL,_Comment)){
         if(trade.Sell(Symbol2Lots,Symbol2,SymbolInfoDouble(Symbol2,SYMBOL_BID),NULL,NULL,_Comment))
            return true;
      }
      Print("An error occurred: BUY Opening position [ ",Symbol1," , ",Symbol1Lots," ]");
      
   }
   else if(opX == POSITION_TYPE_SELL){
      if(trade.Sell(Symbol1Lots, Symbol1,SymbolInfoDouble(Symbol1,SYMBOL_BID),NULL,NULL,_Comment)){
         if(trade.Buy(Symbol2Lots,Symbol2,SymbolInfoDouble(Symbol2,SYMBOL_ASK),NULL,NULL,_Comment))
            return true;
      }
      Print("An error occurred: SELL Opening position [ ",Symbol1," , ",Symbol1Lots," ]");
   }
   return false;
//return ();
}
//+------------------------------------------------------------------+
//| Check if symbol's ticks are within expiry threshold               |
//+------------------------------------------------------------------+
bool IsNewTick(string symbol, int expiryThresholdSeconds = 15)
{
   MqlTick ticks[];
   ArraySetAsSeries(ticks, true);
   
   // Get the latest tick
   int copied = CopyTicks(symbol, ticks, COPY_TICKS_ALL, 0, 1);
   
   if(copied <= 0){
      Print("Failed to get ticks for symbol: ", symbol, ", error: ", GetLastError());
      return false;
   }
   
   // Get current time and tick time
   datetime currentTime = TimeTradeServer();
   datetime tickTime = (datetime)ticks[0].time;
   
   // Calculate time difference
   int timeDifference = (int)(currentTime - tickTime);
   
   /*Print("Symbol: ", symbol);
   Print("Current Time: ", TimeToString(currentTime, TIME_DATE|TIME_SECONDS));
   Print("Tick Time: ", TimeToString(tickTime, TIME_DATE|TIME_SECONDS));
   Print("Time Difference: ", timeDifference, " seconds");*/
   // Return true if within threshold, false otherwise
   return (timeDifference < expiryThresholdSeconds);
}
//+------------------------------------------------------------------+
//| Get Current Gold Future Contract Expiry                           |
//+------------------------------------------------------------------+
datetime GetGoldFutureExpiry()
{
   datetime currentTime = TimeTradeServer();
   MqlDateTime currentTimeStruct;
   TimeToStruct(currentTime, currentTimeStruct);
   
   // Gold futures typically expire on the third last business day of the delivery month
   // Active months are Feb(G), Apr(J), Jun(M), Aug(Q), Oct(V), Dec(Z)
   int activeMonths[] = {2, 4, 6, 8, 10, 12};
   
   int currentMonth = currentTimeStruct.mon;
   int currentYear = currentTimeStruct.year;
   
   datetime expiryDate = 0;
   
   // Find next active month
   for(int i=0; i < ArraySize(activeMonths); i++)
   {
      if(activeMonths[i] > currentMonth)
      {
         int lastDay = GetLastDayOfMonth(currentYear, activeMonths[i]);
         expiryDate = StringToTime(StringFormat("%d.%d.%d", 
            currentYear, activeMonths[i], lastDay - 3));
         break;
      }
   }
   
   // If we're past December, look at next year's February
   if(expiryDate == 0)
   {
      int lastDay = GetLastDayOfMonth(currentYear + 1, 2);  // February of next year
      expiryDate = StringToTime(StringFormat("%d.2.%d", 
         currentYear + 1, lastDay - 3));
   }
   
   //Print("Current Future Contract Expiry: ", TimeToString(expiryDate, TIME_DATE));
   return expiryDate;
}

//+------------------------------------------------------------------+
//| Get Last Day of Month                                             |
//+------------------------------------------------------------------+
int GetLastDayOfMonth(int year, int month)
{
   int days[] = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31};
   
   // Adjust February for leap year
   if(month == 2 && ((year % 4 == 0 && year % 100 != 0) || year % 400 == 0))
      return 29;
      
   return days[month-1];
}
//+------------------------------------------------------------------+
//| Calculate Gold Carry Cost (Future vs Spot)                        |
//+------------------------------------------------------------------+
double CalculateTheoraticalFuturePrice(string spotSymbol, string futureSymbol, double riskFreeRate, double storageRate){
   // Get current prices
   MqlTick spotTick[], futureTick[];
   ArraySetAsSeries(spotTick, true);
   ArraySetAsSeries(futureTick, true);
   
   // Get latest ticks for both symbols
   if(CopyTicks(spotSymbol, spotTick, COPY_TICKS_ALL, 0, 1) <= 0 ||
      CopyTicks(futureSymbol, futureTick, COPY_TICKS_ALL, 0, 1) <= 0)
   {
      Print("Error getting ticks: ", GetLastError());
      return -1;
   }
   
   // Get spot and futures prices
   double spotPrice = spotTick[0].ask;
   double futurePrice = futureTick[0].ask;
   
   // Get time to expiry in years
   datetime futureExpiry = GetGoldFutureExpiry();
   datetime currentTime = TimeTradeServer();
   double timeToExpiry = (double)(futureExpiry - currentTime) / (365 * 24 * 60 * 60);
   
   // Calculate theoretical future price
   double theoreticalFuture = spotPrice * (1 + (riskFreeRate + storageRate) * timeToExpiry);
   return theoreticalFuture;
}
double CalculateGoldCarryCost(string spotSymbol, string futureSymbol, double riskFreeRate, double storageRate)
{
   // Get current prices
   MqlTick spotTick[], futureTick[];
   ArraySetAsSeries(spotTick, true);
   ArraySetAsSeries(futureTick, true);
   
   // Get latest ticks for both symbols
   if(CopyTicks(spotSymbol, spotTick, COPY_TICKS_ALL, 0, 1) <= 0 ||
      CopyTicks(futureSymbol, futureTick, COPY_TICKS_ALL, 0, 1) <= 0)
   {
      Print("Error getting ticks: ", GetLastError());
      return -1;
   }
   
   // Get spot and futures prices
   double spotPrice = spotTick[0].ask;
   double futurePrice = futureTick[0].ask;
   
   // Get time to expiry in years
   datetime futureExpiry = GetGoldFutureExpiry();
   datetime currentTime = TimeTradeServer();
   double timeToExpiry = (double)(futureExpiry - currentTime) / (365 * 24 * 60 * 60);
   
   // Calculate theoretical future price
   double theoreticalFuture = spotPrice * (1 + (riskFreeRate + storageRate) * timeToExpiry);
   
   // Calculate carry cost
   double carryCost = futurePrice - theoreticalFuture;
   
   // Print detailed analysis
   /*Print("=== Gold Carry Cost Analysis ===");
   Print("Analysis Time: ", TimeToString(currentTime, TIME_DATE|TIME_SECONDS));
   Print("Future Expiry: ", TimeToString(futureExpiry, TIME_DATE));
   Print("Time to Expiry (years): ", timeToExpiry);
   Print("Spot Price: ", spotPrice);
   Print("Future Price: ", futurePrice);
   Print("Risk-Free Rate: ", riskFreeRate * 100, "%");
   Print("Storage Rate: ", storageRate * 100, "%");
   Print("Theoretical Future Price: ", theoreticalFuture);
   Print("Carry Cost: ", carryCost);
   Print("Carry Cost %: ", (carryCost/spotPrice) * 100, "%");
   */
   return carryCost;
}