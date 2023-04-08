//+------------------------------------------------------------------+
//|                                                  ScalperAlgo.mq5 |
//|                                    Copyright 2023, Zobad Mahmood |
//|                                          zobad.mahmood@gmail.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, Zobad Mahmood"
#property link      "zobad.mahmood@gmail.com"
#property version   "1.00"
#include "../../Libraries/Common.mq5"
/*#import "Common.ex5"
  bool CheckExpiry(datetime Expiry);
  double GetPnl(int   magic_num);
  double GetPnl(int   magic_num,double &buy ,double &sell);
  int DemoTotalOrders();
  int TotalOrders( int magic_num, int op, string symbol, string comment );
  int TotalOrders(int magic_num, string symbol,int &buy_count , int &sell_count, string comment );
  int TotalOrders( int magic_num,  string symbol, string comment );
#import*/

#include <Trade\Trade.mqh>
#include <Trade\SymbolInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Expert\Money\MoneyFixedRisk.mqh>
#include <Trade\PositionInfo.mqh>
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
#include <Controls\Edit.mqh>
CEdit   InputParams[3];
CDialog Dialog;
CButton MannualEntryBtn [5];
CButton CloseAllBtn;
CButton CloseBuysBtn;
CButton CloseSellsBtn;
CButton TitleBtn;
CButton SaveBtn;
CLabel  Labels[8];
CLabel  LabelsInputs[8];
CLabel  LabelsValues[8];
color DialogColor= C'16,21,43';
string FontName = "Segoe UI";
color FirstComboBoxColor= C'27,33,59';
color FirstComboBoxBorderColor= C'18,69,99';
color HedgeBtnColor= C'255,136,0';
color HedgeBtnTextColor=clrBlack;
enum Stop_Types
  {
   None=0,
   Fix=1,
   ATR=2,
   MidBand = 3,
   OppositeBand =4,
  };

CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper

CPositionInfo  m_position;
//CMoneyFixedRisk m_money;
//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input int     MagicNumber = 200;             //Magic Number
input bool    UseAutoLot  = false;           //Use Auto lot calculation
input double  RiskPerTrade = 1;              //Risk per trade
input Stop_Types TP_Type = Fix;           //TP Type
input Stop_Types SL_Type = Fix;           //SL Type
input double  FixPipStopLoss = 25;           //ATR/Fixed Pip SL
input double  FixPipTakeProfit = 25;         //ATR/Fixed Pip TP
input string  OrderComment = "ScalperAlgo";  //Comment
input bool     UseTrailStop = false;         //Use Trail Stop
input ushort   InpTrailingStop   = 50;       // Trailing Stop (in pips)
input ushort   InpTrailingStep   = 5;        // Trailing Step (in pips)
input string InputEntrySettings = "===== Entry Singal Settings =====";
input bool    UseBuySignal      = true;      //Use Buy signal
input bool    UseSellSignal     = true;      //Use Sell signal
input bool    UseReverseEntry   = false;     //Use Reverse entry
input bool    UseBBSignal       = true;      //Use Condition 1- BB
input bool    UseHigherHigh     = true;      //Use Condition 2- HighHigh/LowerLow
input bool    UseMASignal       = true;      //Use Condition 3- EMA
input bool    UseRSISignal      = true;      //Use Condition 4- RSI
input bool    UseRangeSignal    = true;      //Use Condition 5- Candle length
input string  MA_Setting="=====  Moving Average =====";
input int     MovingPeriod       = 60;      // Moving Average period
input int     MovingShift        = 0;       // Moving Average shift
input ENUM_MA_METHOD MA_Method   = MODE_EMA; //Moving Average Method
input ENUM_APPLIED_PRICE  MA_Applied_Price=PRICE_CLOSE;// MA Applied Price
input ENUM_TIMEFRAMES MA_Timeframe = PERIOD_H1; //MA Timeframe
input string  Bollinger_Bands_Setting="=====  Bollinger Bands =====";
input int     BB_Period=20;// Bollinger Bands Period
input double  BB_deviation=2;// Bollinger Bands deviation
input int     BB_Shift=0;// Bollinger Shift
input ENUM_TIMEFRAMES BB_Timeframe = PERIOD_H1; //Bollinger Bands Timeframe
input ENUM_APPLIED_PRICE  BB_Applied_Price=PRICE_CLOSE;// Bollinger Applied Price
input string  RSI_Setting="=====  RSI Settings =====";
input bool    UseRsiSignal    = true;    //Use RSI confirmation
input int     RSIBuyThreshold = 30;      //RSI Buy Threshold
input int     RSISellThreshold= 70;      //RSI Sell Threshold
input int     RSIPeriod       = 14;      // RSI period
input ENUM_TIMEFRAMES RSI_Timeframe = PERIOD_H1; //RSI Timeframe
input ENUM_APPLIED_PRICE  RSI_Applied_Price=PRICE_CLOSE;// RSI Applied Price
input string  ATR_Setting="=====  ATR Stops Settings =====";
input int     ATR_Period = 14;
input ENUM_TIMEFRAMES ATR_Filter_TF =PERIOD_H1;


double         ExtTrailingStop=0.0;
double         ExtTrailingStep=0.0;

int digits_adjust=1;

enum Mode
  {
   Auto = 1,
   Mannual = 2
  };

Mode Strategy_Mode = Auto;
double stop = 0;
int rsi_handle = 0;
int ma_handle = 0;
int bb_handle = 0;
int atr_handle = 0;
double Lot_Size = 0.0;
double               TP_Money=700;//TP Money
double               SL_Money=2000;//SL Money
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
   CreateSmallScreen();

   EventSetTimer(60);
   m_trade.SetExpertMagicNumber(MagicNumber);
   m_symbol.Name(Symbol());
   m_symbol.Refresh();
   if(!RefreshRates())
     {
      Print("Error RefreshRates. Bid=",DoubleToString(m_symbol.Bid(),Digits()),
            ", Ask=",DoubleToString(m_symbol.Ask(),Digits()));
      return(INIT_FAILED);
     }
//--- tuning for 3 or 5 digits

   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
//stop = FixPipStopLoss*m_symbol.Point()*digits_adjust;
//indicators handles initilization
   ExtTrailingStop=InpTrailingStop*m_symbol.Point()*digits_adjust;
   ExtTrailingStep=InpTrailingStep*m_symbol.Point()*digits_adjust;

//RSI
   rsi_handle = iRSI(Symbol(),RSI_Timeframe,RSIPeriod, RSI_Applied_Price);
   if(rsi_handle==INVALID_HANDLE)
     {
      printf("Error creating RSI indicator");
      return(INIT_FAILED);
     }
   atr_handle = iATR(NULL,PERIOD_CURRENT, ATR_Period);
   if(atr_handle==INVALID_HANDLE)
     {
      printf("Error creating ATR indicator");
      return(INIT_FAILED);
     }
//MA
   ma_handle=iMA(_Symbol,MA_Timeframe,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ma_handle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
//BB
   bb_handle=iBands(NULL,0,BB_Period,BB_Shift,BB_deviation,BB_Applied_Price);
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
//int totalOrders = 0;
void OnTick()
  {
//---
   if(!RefreshRates())
      return;
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return;
   double sl = 0.0;
   int totalOrders = TotalOrders(MagicNumber,m_symbol.Name(),OrderComment);
//int totalOrders = TotalOrders(MagicNumber,Symbol(),OrderComment);
//Print("Calling Function: ",DemoTotalOrders());

   if(totalOrders == 0 && Strategy_Mode == Auto)
     {
      bool b_signal = IsSignal(ORDER_TYPE_BUY);
      bool s_signal = IsSignal(ORDER_TYPE_SELL);

      double b_stop = m_symbol.Ask()-stop;
      double s_stop = m_symbol.Ask()+stop;
      //double b_lots= m_money.CheckOpenLong(m_symbol.Ask(),b_stop);
      double b_lots= AutoLotCalculateLong(m_symbol.Ask(),CalculateSL(ORDER_TYPE_BUY));
      //double s_lots= m_money.CheckOpenShort(m_symbol.Bid(),s_stop);
      double s_lots= AutoLotCalculateShort(m_symbol.Bid(),CalculateSL(ORDER_TYPE_SELL));
      Print("Total Orders: ",IntegerToString(totalOrders),
            ", sl= ",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(b_lots,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2),
            ", Risk %: ",DoubleToString(RiskPerTrade/100,2),
            ", Risk: ", DoubleToString(m_account.Balance()*(RiskPerTrade/100),2),
            ", Lots: ", DoubleToString(b_lots,2));
      if(b_signal && UseBuySignal && !UseReverseEntry)
         m_trade.Buy(b_lots,Symbol(),m_symbol.Bid(),CalculateSL(ORDER_TYPE_BUY),CalculateTP(ORDER_TYPE_BUY),OrderComment);
      if(s_signal && UseSellSignal && !UseReverseEntry)
         m_trade.Sell(s_lots,Symbol(),m_symbol.Ask(),CalculateSL(ORDER_TYPE_SELL),CalculateTP(ORDER_TYPE_SELL),OrderComment);
      if(b_signal && UseBuySignal && UseReverseEntry)
         m_trade.Sell(s_lots,Symbol(),m_symbol.Ask(),CalculateSL(ORDER_TYPE_SELL),CalculateTP(ORDER_TYPE_SELL),OrderComment);
      if(s_signal && UseSellSignal && UseReverseEntry)
         m_trade.Buy(b_lots,Symbol(),m_symbol.Bid(),CalculateSL(ORDER_TYPE_BUY),CalculateTP(ORDER_TYPE_BUY),OrderComment);

     }else{
      Trailing();
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
   if(id == CHARTEVENT_OBJECT_CLICK)
     {
      if(sparam == "")
         return;
      if(sparam=="CloseAll") // Close all
        {
         MessageBox("Closing All Orders!")                           ;
         CloseAllPositions();
         CloseAllBtn.Pressed(false);         
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
        }
      if(sparam=="OpenSell") // Close Buys
        {
         //CloseAll(Magic);
         MannualEntryBtn[1].Pressed(false);
         MessageBox("Opening Sell Order!")                           ;
         MannualEntry(ORDER_TYPE_SELL);
         Print("Opened Sell Position");
         //WindowRedraw();
        }
      if(sparam=="CloseSells") // Close Sells
        {
         CloseSellsBtn.Pressed(false);
         MessageBox("Closing All sell Orders!")                           ;
         CloseAllPositions(POSITION_TYPE_SELL);
         Print("Close All Sell Orders event");
        }
      if(sparam =="ApplyBtn")
        {
         //SetParameters();
         MessageBox("Applying parameters");
        }
      if(sparam == "AutoStart")
        {
         MessageBox("Auto Mode enabled");
         Strategy_Mode = Auto;
         TitleBtn.Pressed(false);
        }
      if(sparam == "OpenManual")
        {
         MessageBox("Manual mode enabled");
         Strategy_Mode = Mannual;
         MannualEntryBtn[2].Pressed(false);
        }
     }

  }


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateTP(int op)
  {
   /*
   double b_stop = m_symbol.Ask()-stop;
      double s_stop = m_symbol.Ask()+stop;
   */
   if(TP_Type==Fix)
     {
      stop = FixPipTakeProfit*m_symbol.Point()*digits_adjust;
      if(op == ORDER_TYPE_BUY)
        {
         return (m_symbol.Ask()+stop);
        }
      else
         if(op == ORDER_TYPE_SELL)
           {
            return (m_symbol.Ask()-stop);
           }
     }
   else
      if(TP_Type == ATR)
        {
         double   atr[1];
         if(CopyBuffer(atr_handle,0,0,1,atr)!=1)
           {
            Print("CopyBuffer from ATR failed, no data");
            return 0.0;
           }
         double thresh = FixPipTakeProfit * atr[0];
         if(op == ORDER_TYPE_BUY)
           {
            double _stop = m_symbol.Ask() + thresh;
            return _stop;
           }
         else
            if(op == ORDER_TYPE_SELL)
              {
               double _stop = m_symbol.Bid() - thresh;
               return _stop;
              }
        }
      else
         if(TP_Type== MidBand) {}


   return 0.0;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double CalculateSL(int op)
  {
   if(SL_Type==Fix)
     {
      stop = FixPipStopLoss*m_symbol.Point()*digits_adjust;
      if(op == ORDER_TYPE_BUY)
        {
         return (m_symbol.Ask()-stop);
        }
      else
         if(op == ORDER_TYPE_SELL)
           {
            return (m_symbol.Ask()+stop);
           }
     }
   else
      if(SL_Type == ATR)
        {
         double ask = m_symbol.Ask();
         double bid = m_symbol.Bid();
         double min_stop = m_symbol.StopsLevel();
         double   atr[1];
         if(CopyBuffer(atr_handle,0,0,1,atr)!=1)
           {
            Print("CopyBuffer from ATR failed, no data");
            return 0.0;
           }
         double thresh = FixPipStopLoss * atr[0];
         if(op == ORDER_TYPE_BUY)
           {
            double _stop = m_symbol.Bid() - thresh;
            Print("Stop Loss: ", DoubleToString(stop,_Digits),
                  ", Order Type: BUY ",
                  ", Minimum stop level: ",IntegerToString(m_symbol.StopsLevel()),
                  ", ATR: ",DoubleToString(atr[0],_Digits));
            if(thresh < min_stop*_Point)
              {
               Print("Invalid sl. Sl Smaller than minimum stop allowed");
              }
            return (_stop);
           }
         else
            if(op == ORDER_TYPE_SELL)
              {
               double _stop = m_symbol.Ask() + thresh;
               Print("Stop Loss: ", DoubleToString(stop,_Digits),
                     ", Order Type: SELL ",
                     ", Minimum stop level: ",IntegerToString(m_symbol.StopsLevel()),
                     ", ATR: ",DoubleToString(atr[0],_Digits));
               if(thresh < min_stop*_Point)
                 {
                  Print("Invalid sl. Sl Smaller than minimum stop allowed");
                 }
               return(_stop);
              }

        }
        else if(SL_Type == MidBand){
            double mid[3]; 
            CopyBuffer(bb_handle,0,0,2,mid);
            Print("BB_MID[0]= ", DoubleToString(mid[0]));
            return (mid[0]);  
        }
      else if(SL_Type == OppositeBand) {
            if(op ==ORDER_TYPE_SELL){
               double up[3];
               CopyBuffer(bb_handle,1,0,2,up);   
               Print("BB_UP[0]= ", DoubleToString(up[0]));
               return (up[0]);
            }
            else if(op == ORDER_TYPE_BUY){
               double bot[2];
               CopyBuffer(bb_handle,2,0,2,bot);
               Print("BB_BOT[0]= ", DoubleToString(bot[0]));
               return (bot[0]);
            }
       }
         

   return 0.0;
  }
//+------------------------------------------------------------------+
//+------------------------------------------------------------------+
//| Refreshes the symbol quotes data                                 |
//+------------------------------------------------------------------+
bool RefreshRates()
  {
//--- refresh rates
   if(!m_symbol.RefreshRates())
      return(false);
//--- protection against the return value of "zero"
   if(m_symbol.Ask()==0 || m_symbol.Bid()==0)
      return(false);
//---
   return(true);
  }
//+------------------------------------------------------------------+
bool IsSignal(int op)
  {


   return (IsSignalMA(op) && IsSignalRSI(op) && IsSignalBB(op) && IsSignalHHLL(op));
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSignalHHLL(int op)
  {
   if(!UseHigherHigh)
      return true;

   if(op == ORDER_TYPE_BUY)
     {
      double close1 = iClose(NULL,PERIOD_CURRENT,1);
      double close2 = iClose(NULL,PERIOD_CURRENT,2);

      if(close1 > close2)
        {
         Print("HIGHER HIGH => Close1: ",DoubleToString(close1),
               ", Close2: ", DoubleToString(close2));
         return true;
        }
     }
   else
      if(op == ORDER_TYPE_SELL)
        {
         double close1 = iClose(NULL,PERIOD_CURRENT,1), close2 = iClose(NULL,PERIOD_CURRENT,2);

         if(close1 < close2)
           {
            Print("LOWER LOW => Close1: ",DoubleToString(close1),
                  ", Close2: ", DoubleToString(close2));
            return true;
           }
        }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSignalBB(int op)
  {
   if(!UseBBSignal)
      return true;

   if(op == ORDER_TYPE_BUY)
     {
      //get bb values
      double up[3];
      CopyBuffer(bb_handle,1,0,2,up);
      //BB Breakout top band
      double close = iClose(NULL,PERIOD_CURRENT,1);
      Print("BB Close: "+close+" | BBTOP: ",DoubleToString(up[1],5));
      Comment("1: "+up[1]+" | 2: "+ up[2]);

      if(iClose(NULL,PERIOD_CURRENT,1)>up[1])
        {

         Print("BB-BUY breakout");
         return true;
        }
     }
   else
      if(op == ORDER_TYPE_SELL)
        {
         double bot[2];
         CopyBuffer(bb_handle,2,0,2,bot);
         double close = iClose(NULL,PERIOD_CURRENT,1);
         Print("BB Close: "+close+" | BBBot: ",DoubleToString(bot[1],5));
         //BB Breakout bot band
         if(iClose(NULL,PERIOD_CURRENT,1)<bot[1])
           {
            Print("BB-SELL breakout");
            return true;
           }
        }
   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSignalRSI(int op)
  {
   if(!UseRSISignal)
      return true;

   double rsi[2];

   if(CopyBuffer(rsi_handle,0,0,1,rsi)!=1)
     {
      Print("CopyBuffer from RSI failed, no data");
      return false;
     }

   if(op == ORDER_TYPE_BUY)
     {
      bool signal = false;
      if(rsi[1]<=RSIBuyThreshold)
        {
         Print("RSI- BUY Threshold");
         return true;
        }
     }
   else
      if(op == ORDER_TYPE_SELL)
        {
         if(rsi[1]>=RSISellThreshold)
           {
            Print("RSI- SELL Threshold");
            return true;
           }
        }


   return false;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
bool IsSignalMA(int op)
  {
   if(!UseMASignal)
      return true;

   double   ma[1];
   if(CopyBuffer(ma_handle,0,0,1,ma)!=1)
     {
      Print("CopyBuffer from iMA failed, no data");
      return false;
     }

   if(op == ORDER_TYPE_BUY)
     {
      bool signal = false;
      if(m_symbol.Bid() > ma[0])
        {
         Print("BUY Signal MA-> Bid: ",m_symbol.Bid()," |MA: ",ma[0]);
         signal = true;
        }
      return (signal);
     }
   else
      if(op == ORDER_TYPE_SELL)
        {
         bool signal = false;
         if(m_symbol.Ask()< ma[0])
           {
            Print("SELL Signal MA-> ASK: ",m_symbol.Ask()," |MA: ",ma[0]);
            signal = true;
           }
         return (signal);
        }

   return false;
  }
//+------------------------------------------------------------------+
//| Getting lot size for open long position.                         |
//+------------------------------------------------------------------+
double AutoLotCalculateLong(double price,double sl)
  {
//if(m_symbol==NULL)
//   return(0.0);
//--- select lot size
   double m_percent = RiskPerTrade;
   double lot;
   double minvol=m_symbol.LotsMin();
   if(sl==0.0)
      lot=minvol;
   else
     {
      double loss;
      if(price==0.0)
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,m_symbol.Ask(),sl);
      else
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_BUY,1.0,price,sl);
      double stepvol=m_symbol.LotsStep();
      lot=MathFloor(m_account.Balance()*m_percent/loss/100.0/stepvol)*stepvol;
     }
//---
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//| Getting lot size for open short position.                        |
//+------------------------------------------------------------------+
double AutoLotCalculateShort(double price,double sl)
  {
   double m_percent = RiskPerTrade;
   double lot;
   double minvol=m_symbol.LotsMin();
   if(sl==0.0)
      lot=minvol;
   else
     {
      double loss;
      if(price==0.0)
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_SELL,1.0,m_symbol.Bid(),sl);
      else
         loss=-m_account.OrderProfitCheck(m_symbol.Name(),ORDER_TYPE_SELL,1.0,price,sl);
      double stepvol=m_symbol.LotsStep();
      lot=MathFloor(m_account.Balance()*m_percent/loss/100.0/stepvol)*stepvol;
     }
//---
   if(lot<minvol)
      lot=minvol;
//---
   double maxvol=m_symbol.LotsMax();
   if(lot>maxvol)
      lot=maxvol;
//--- return trading volume
   return(lot);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void MannualEntry(int op)
  {
   /*double b_lots= AutoLotCalculateLong(m_symbol.Ask(),CalculateSL(ORDER_TYPE_BUY));
      //double s_lots= m_money.CheckOpenShort(m_symbol.Bid(),s_stop);
      double s_lots= AutoLotCalculateShort(m_symbol.Bid(),CalculateSL(ORDER_TYPE_SELL));

   if(b_signal)m_trade.Buy(b_lots,Symbol(),m_symbol.Bid(),CalculateSL(ORDER_TYPE_BUY),CalculateTP(ORDER_TYPE_BUY),OrderComment);
      if(s_signal)m_trade.Sell(s_lots,Symbol(),m_symbol.Ask(),CalculateSL(ORDER_TYPE_SELL),CalculateTP(ORDER_TYPE_SELL),OrderComment);
   */
   if(op == ORDER_TYPE_BUY && UseBuySignal)
     {
      double _tp = CalculateTP(ORDER_TYPE_BUY);
      double _stop = CalculateSL(ORDER_TYPE_BUY);
      double b_lots= AutoLotCalculateLong(m_symbol.Ask(),_stop);
      Print("Sl= ",DoubleToString(_stop,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(b_lots,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2),
            ", Risk %: ",DoubleToString(RiskPerTrade/100,2),
            ", Risk: ", DoubleToString(m_account.Balance()*(RiskPerTrade/100),2),
            ", Lots: ", DoubleToString(b_lots,2));
      m_trade.Buy(b_lots,Symbol(),m_symbol.Bid(),_stop,_tp,OrderComment);

     }
   else
      if(op == ORDER_TYPE_SELL && UseSellSignal)
        {
         double _tp = CalculateTP(ORDER_TYPE_SELL);
         double _stop = CalculateSL(ORDER_TYPE_SELL);
         double s_lots= AutoLotCalculateShort(m_symbol.Bid(),_stop);
         Print("Sl= ",DoubleToString(_stop,m_symbol.Digits()),
               ", CheckOpenShort: ",DoubleToString(s_lots,2),
               ", Balance: ",    DoubleToString(m_account.Balance(),2),
               ", Equity: ",     DoubleToString(m_account.Equity(),2),
               ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2),
               ", Risk %: ",DoubleToString(RiskPerTrade/100,2),
               ", Risk: ", DoubleToString(m_account.Balance()*(RiskPerTrade/100),2),
               ", Lots: ", DoubleToString(s_lots,2));
         m_trade.Sell(s_lots,Symbol(),m_symbol.Bid(),_stop,_tp,OrderComment);
        }

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(void)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==MagicNumber)
            if(!m_trade.PositionClose(m_position.Ticket()))  // close a position by the specified m_symbol
              {
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CloseAllPositions(int op)
  {
   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of current positions
      if(m_position.SelectByIndex(i)) // selects the position by index for further access to its properties
         if(m_position.Magic()==MagicNumber && m_position.PositionType() == (ENUM_POSITION_TYPE)op)
            if(!m_trade.PositionClose(m_position.Ticket()))  // close a position by the specified m_symbol
              {
               Print(__FILE__," ",__FUNCTION__,", ERROR: "," PositionClose ",m_position.Ticket(),", ",m_trade.ResultRetcodeDescription());
              }
  }
//+------------------------------------------------------------------+

//| Trailing                                                         |

//+------------------------------------------------------------------+

void Trailing()
{
   if(ExtTrailingStop==0 || !UseTrailStop)
      return;

   for(int i=PositionsTotal()-1; i>=0; i--) // returns the number of open positions
      if(m_position.SelectByIndex(i))
         if(m_position.Symbol()==m_symbol.Name() && m_position.Magic()==MagicNumber)
           {
            if(m_position.PositionType()==POSITION_TYPE_BUY)
              {
               if(m_position.PriceCurrent()-m_position.PriceOpen()>ExtTrailingStop+ExtTrailingStep)
                  if(m_position.StopLoss()<m_position.PriceCurrent()-(ExtTrailingStop+ExtTrailingStep))
                    {
                     if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(m_position.PriceCurrent()-ExtTrailingStop),
                                                m_position.TakeProfit()))
                        Print("Modify ",m_position.Ticket(),
                              " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                              ", description of result: ",m_trade.ResultRetcodeDescription());
                     continue;
                    }
              }
            else if(m_position.PositionType()==POSITION_TYPE_SELL)
                 {
                  if(m_position.PriceOpen()-m_position.PriceCurrent()>ExtTrailingStop+ExtTrailingStep)

                     if((m_position.StopLoss()>(m_position.PriceCurrent()+(ExtTrailingStop+ExtTrailingStep))) ||
                        (m_position.StopLoss()==0))
                       {
                        if(!m_trade.PositionModify(m_position.Ticket(),m_symbol.NormalizePrice(m_position.PriceCurrent()+ExtTrailingStop),
                                                   m_position.TakeProfit()))
                           Print("Modify ",m_position.Ticket(),
                                 " Position -> false. Result Retcode: ",m_trade.ResultRetcode(),
                                 ", description of result: ",m_trade.ResultRetcodeDescription());
                       }
                 }
           }
}


//GUI
void CreateSmallScreen()
  {
   int d_width =380, d_height=220;
   Dialog.Create(ChartID(),"                             WWW.QUANTECHSOL.COM",0,5,5,d_width,d_height);
   string dialogNumber=Dialog.Name();
   ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
   ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrWhite);

   ObjectDelete(ChartID(),dialogNumber+"Border");
//CreateButton(Dialog,TitleBtn,"OpenHedge", "AUTO START", 100,35,15,16,0,0,clrWhite,10);
   int width = 100, height = 35, fontsize = 9, width_big = 200;
   color border_color = clrBlack, font_color = clrWhite;
   int x2 = 0, y2 =0;
   CreateButton(Dialog,TitleBtn,"AutoStart", "AUTO START", width,height,15,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[2],"OpenManual", "START MANUAL", width,height,115,16,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[0],"OpenBuy", "BUY", width,height,15,50,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,CloseBuysBtn,"CloseBuys", "CLOSE BUYS", width,height,15,84,x2,y2,fontsize,font_color,clrBlue,border_color);
   CreateButton(Dialog,MannualEntryBtn[1],"OpenSell", "SELL", width,height,115,50,x2,y2,fontsize,font_color,clrRed,border_color);

//reset = false                                                     ;
   CreateButton(Dialog,CloseSellsBtn,"CloseSells", "CLOSE SELLS", width,height,115,84,x2,y2,fontsize,font_color,clrRed,border_color);
   CreateButton(Dialog,CloseAllBtn,"CloseAll", "CLOSE TRADES", width_big,height,15,118,x2,y2,fontsize,font_color,clrMaroon,border_color);

   int lbl_fontsize = 9;
   color lbl_color1 = clrBlack, lbl_color2= clrDarkBlue,  lbl_color3 = clrSlateGray;
   /*  CreateLabel(Dialog, LabelsInputs[0],"LotsLbl", "Lots: ",15,165,x2,y2,lbl_fontsize,lbl_color1);
    CreateLabel(Dialog, LabelsInputs[1],"ProfitLbl", "Profit$: ",15,190,x2,y2,lbl_fontsize,lbl_color1);
    CreateLabel(Dialog, LabelsInputs[2],"LossLbl", "Loss$: ",15,214,x2,y2,lbl_fontsize,lbl_color1);

    InputParams[0].Create(0,"LotsEdit",0,80,160,0,0)                    ;
    int e_height = 20, e_width = 110, e_fontsize = 10;
    SetEditProperties(Dialog,InputParams[0],""+(string)Lot_Size,e_height,e_width,e_fontsize);

    InputParams[1].Create(0,"ProfitEdit",0,80,185,0,0)                    ;
    SetEditProperties(Dialog,InputParams[1],""+(string)TP_Money,e_height,e_width,e_fontsize);

    InputParams[2].Create(0,"LossEdit",0,80,210,0,0)                    ;
    SetEditProperties(Dialog,InputParams[2],""+(string)SL_Money,e_height,e_width,e_fontsize);

    CreateButton(Dialog,SaveBtn,"ApplyBtn", "APPLY", width_big,height,15,238,x2,y2,fontsize,clrBlack,clrLime,border_color);
    */
   CreateLabel(Dialog, Labels[0],"NPnlLbl", "NET PNL$: ",230,22,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, LabelsValues[0],"NPNLValue", "0.0",300,22,x2,y2,lbl_fontsize,lbl_color2);
   CreateLabel(Dialog, Labels[1],"BPnlLbl", "BUY PNL$: ",230,45,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[1],"BPNLValue", "0.0",300,45,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[2],"SPnlLbl", "SELL PNL$: ",230,65,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[2],"SPNLValue", "0.0",300,65,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[3],"BLegsLbl", "BUY Legs: ",230,85,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[3],"BLegsValue", "0.0",300,85,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, Labels[4],"SLegsLbl", "SELL Legs: ",230,105,x2,y2,lbl_fontsize,lbl_color3);
   CreateLabel(Dialog, LabelsValues[4],"SLegsValue", "0.0",300,105,x2,y2,lbl_fontsize,lbl_color3);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateButton(CDialog &dialog, CButton &button, string name, string text, int width, int height, int x_dim, int y_dim, int x2_dim, int y2_dim,  int font_size, color _color, color c_bg, color c_brdr)
  {
   button.Create(0,name,0,x_dim,y_dim,x2_dim,y2_dim);
   button.FontSize(font_size);
   button.Height(height);
   button.Width(width);
   button.Text(text);
   button.ColorBackground(c_bg)                               ;
   button.ColorBorder(c_brdr)                                 ;
   button.Color(_color);
   button.Pressed(false);
   dialog.Add(button);
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CreateLabel(CDialog &dialog, CLabel &lbl, string name, string text, int x_dim, int y_dim, int x2_dim, int y2_dim,  int font_size, color _color)
  {
   lbl.Create(0,name,0,x_dim,y_dim,x2_dim,y2_dim);
   lbl.FontSize(font_size);
   lbl.Text(text);
   lbl.Color(_color);
   dialog.Add(lbl);
   /*
   Labels[1].Create(0,"BPnlLbl",0,530,55,30,0);
   Labels[1].Text("BUY PNL$: ");
   Labels[1].FontSize(9);
   Labels[1].Color(clrSlateGray);
   Dialog.Add(Labels[1]);
   */
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetEditProperties(CDialog &dialog,CEdit &_edit, string text, int height, int width, int fontsize)
  {
   _edit.Text(text);
   _edit.FontSize(fontsize);
   _edit.Width(width);
   _edit.Height(height);
   dialog.Add(_edit);


   /*
      InputParams[0].Create(0,"LotsEdit",0,80,165,0,0)                    ;
      InputParams[0].Text(""+(string)Lot_Size)                                          ;
      InputParams[0].FontSize(10)                                          ;
      InputParams[0].Height(25)                                           ;
      InputParams[0].Width(330)                                           ;
      Dialog.Add(InputParams[0])                                          ;
   */
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void SetPropertiesButton(CButton &button, string text, int width, int height,color _color, int font_size)
  {
   button.Text(text);
   button.FontSize(font_size);
   button.Color(_color);

  }
//+------------------------------------------------------------------+
