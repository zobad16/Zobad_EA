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
CTrade         m_trade;                      // trading object
CSymbolInfo    m_symbol;                     // symbol info object
CAccountInfo   m_account;                    // account info wrapper
//CMoneyFixedRisk m_money;
//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input int     MagicNumber = 200;             //Magic Number
input bool    UseAutoLot  = false;           //Use Auto lot calculation
input double  RiskPerTrade = 1;              //Risk per trade
input double  FixPipStopLoss = 25;           //Fixed Pip SL    
input double  FixPipTakeProfit = 25;         //Fixed Pip TP
input string  OrderComment = "ScalperAlgo";  //Comment
input string InputEntrySettings = "===== Entry Singal Settings =====";
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

double stop = 0;
int rsi_handle = 0;
int ma_handle = 0;
int bb_handle = 0;
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- create timer
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
   int digits_adjust=1;
   if(m_symbol.Digits()==3 || m_symbol.Digits()==5)
      digits_adjust=10;
      stop = FixPipStopLoss*m_symbol.Point()*digits_adjust;
  //indicators handles initilization
   //RSI
   rsi_handle = iRSI(Symbol(),RSI_Timeframe,RSIPeriod, RSI_Applied_Price); 
   if(rsi_handle==INVALID_HANDLE)
   {
      printf("Error creating RSI indicator");
      return(INIT_FAILED);
   }
   //MA
   ma_handle=iMA(_Symbol,MA_Timeframe,MovingPeriod,MovingShift,MA_Method,MA_Applied_Price);
   if(ma_handle==INVALID_HANDLE)
     {
      printf("Error creating MA indicator");
      return(INIT_FAILED);
     }
   
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
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
   
   if(totalOrders == 0){
      bool b_signal = IsSignal(ORDER_TYPE_BUY);
      bool s_signal = IsSignal(ORDER_TYPE_SELL);
      double b_stop = m_symbol.Ask()-stop;
      double s_stop = m_symbol.Ask()+stop;
      //double b_lots= m_money.CheckOpenLong(m_symbol.Ask(),b_stop);
      double b_lots= AutoLotCalculateLong(m_symbol.Ask(),b_stop);
      //double s_lots= m_money.CheckOpenShort(m_symbol.Bid(),s_stop);
      double s_lots= AutoLotCalculateShort(m_symbol.Bid(),s_stop);
      Print("Total Orders: ",IntegerToString(totalOrders),
            ", sl= ",DoubleToString(sl,m_symbol.Digits()),
            ", CheckOpenLong: ",DoubleToString(b_lots,2),
            ", Balance: ",    DoubleToString(m_account.Balance(),2),
            ", Equity: ",     DoubleToString(m_account.Equity(),2),
            ", FreeMargin: ", DoubleToString(m_account.FreeMargin(),2),
            ", Risk %: ",DoubleToString(RiskPerTrade/100,2),
            ", Risk: ", DoubleToString(m_account.Balance()*(RiskPerTrade/100),2),
            ", Lots: ", DoubleToString(b_lots,2));
      if(b_signal)m_trade.Buy(b_lots,Symbol(),m_symbol.Bid(),b_stop,s_stop,OrderComment);
      if(s_signal)m_trade.Sell(s_lots,Symbol(),m_symbol.Ask(),s_stop,0,OrderComment);
      
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
bool IsSignal(int op){


   return (IsSignalMA(op) && IsSignalRSI(op) && IsSignalBB(op));
}
bool IsSignalBB(int op){
   if(!UseBBSignal)return true;
   
   if(op == ORDER_TYPE_BUY){
      //get bb values
      double up[3];
      CopyBuffer(bb_handle,1,0,2,up);
      //BB Breakout top band
      double close = iClose(NULL,PERIOD_CURRENT,1);
      Print("BB Close: "+close+" | BBTOP: ",DoubleToString(up[1],5));
      Comment("1: "+up[1]+" | 2: "+ up[2]);
      
      if(iClose(NULL,PERIOD_CURRENT,1)>up[1]){
         
         Print("BB-BUY breakout");
         return true;
      }
   }
   else if(op == ORDER_TYPE_SELL){
      double bot[2];
      CopyBuffer(bb_handle,2,0,1,bot);
      double close = iClose(NULL,PERIOD_CURRENT,1);
      Print("BB Close: "+close+" | BBBot: ",DoubleToString(bot[1],5));
      //BB Breakout bot band
      if(iClose(NULL,PERIOD_CURRENT,1)<bot[1]){
         Print("BB-SELL breakout");
         return true;
      }
   }
   return false;
}
bool IsSignalRSI(int op){
   if(!UseRSISignal) return true;
   
   double rsi[2];
   
   if(CopyBuffer(rsi_handle,0,0,1,rsi)!=1){   Print("CopyBuffer from RSI failed, no data");   return false;  }
   
   if(op == ORDER_TYPE_BUY){
      bool signal = false;
      if(rsi[1]<=RSIBuyThreshold){
         Print("RSI- BUY Threshold");
         return true;
      }
   }else if(op == ORDER_TYPE_SELL){
      if(rsi[1]>=RSISellThreshold){
         Print("RSI- SELL Threshold");
         return true;
      }
   }
   
   
   return false;
}
bool IsSignalMA(int op){
   if(!UseMASignal) return true;
   
   double   ma[1];
   if(CopyBuffer(ma_handle,0,0,1,ma)!=1){   Print("CopyBuffer from iMA failed, no data");   return false;  }
   
   if(op == ORDER_TYPE_BUY){
      bool signal = false;
      if(m_symbol.Bid() > ma[0] ){
         Print("BUY Signal MA-> Bid: ",m_symbol.Bid()," |MA: ",ma[0] );
         signal = true;
      }
      return (signal);
   }
   else if(op == ORDER_TYPE_SELL){
      bool signal = false;
      if(m_symbol.Ask()< ma[0]){
         Print("SELL Signal MA-> ASK: ",m_symbol.Ask()," |MA: ",ma[0] );
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
  