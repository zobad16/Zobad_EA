//+------------------------------------------------------------------+
//|                                                  RSI_Scanner.mq5 |
//|                                      Copyright 2021, AlgoTradeup |
//|                                          https://algotradeup.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup"
#property link      "https://algotradeup.com"
#property version   "1.00"

#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
//--- input parameters
input string   RSISET="----RSI PARAMETERS----";
input int      RSI_Period = 14;
input ENUM_TIMEFRAMES TimeFrame    = PERIOD_H4;
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE; 
input string   ScannerSettings="----Symbols----";
input string   Symbol1="EURUSD.r";
input string   Symbol2="GBPUSD.r";
input string   Symbol3="AUDUSD.r";
input string   Symbol4="NZDUSD.r";
input string   Symbol5="USDCAD.r";
input string   Symbol6="USDCHF.r";
input string   Symbol7="USDJPY.r";

int   rsi_handle[10];
string symbols[10];

CDialog Dialog;
CLabel  Labels[14];
CLabel  LabelsValues[14];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
      SetSymbols();
      bool is_set_handles = SetHandles();
      if(!is_set_handles){
         Print("Reason handle failed");
         return INIT_FAILED;
       }  
       Dialog.Create(ChartID(),"                   WWW.QUANTECHSOL.COM",0,5,5,400,250);
      string dialogNumber=Dialog.Name();
      ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
      ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrBlack);
      Labels[0].Create(0,"Title",0,75,5,30,0);
      Labels[0].Text("RSI Scanner ");
      Labels[0].FontSize(14);
      Labels[0].Color(clrWhite);   
      Dialog.Add(Labels[0]);
      Labels[1].Create(0,"SymbolLBL",0,15,40,30,0);
      Labels[1].Text("Symbols");
      Labels[1].FontSize(9);
      Labels[1].Color(clrWhite);   
      Dialog.Add(Labels[1]);
      
      Labels[2].Create(0,"Symbol1",0,15,65,30,0);
      Labels[2].Text(Symbol1);
      Labels[2].FontSize(8);
      Labels[2].Color(clrWhite);   
      Dialog.Add(Labels[2]);
      Labels[3].Create(0,"Symbol2",0,15,85,30,0);
      Labels[3].Text(Symbol2);
      Labels[3].FontSize(8);
      Labels[3].Color(clrWhite);   
      Dialog.Add(Labels[3]);
      Labels[4].Create(0,"Symbol3",0,15,105,30,0);
      Labels[4].Text(Symbol3);
      Labels[4].FontSize(8);
      Labels[4].Color(clrWhite);   
      Dialog.Add(Labels[4]);
      Labels[5].Create(0,"Symbol4",0,15,125,30,0);
      Labels[5].Text(Symbol4);
      Labels[5].FontSize(8);
      Labels[5].Color(clrWhite);   
      Dialog.Add(Labels[5]);
      Labels[6].Create(0,"Symbol5",0,15,145,30,0);
      Labels[6].Text(Symbol5);
      Labels[6].FontSize(8);
      Labels[6].Color(clrWhite);   
      Dialog.Add(Labels[6]);
      Labels[7].Create(0,"Symbol6",0,15,165,30,0);
      Labels[7].Text(Symbol6);
      Labels[7].FontSize(8);
      Labels[7].Color(clrWhite);   
      Dialog.Add(Labels[7]);
      Labels[8].Create(0,"Symbol7",0,15,185,30,0);
      Labels[8].Text(Symbol7);
      Labels[8].FontSize(8);
      Labels[8].Color(clrWhite);   
      Dialog.Add(Labels[8]);
      
      LabelsValues[0].Create(0,"RSILBL",0,95,40,30,0);
      LabelsValues[0].Text("RSI");
      LabelsValues[0].FontSize(9);
      LabelsValues[0].Color(clrWhite);   
      Dialog.Add(LabelsValues[0]);
      LabelsValues[1].Create(0,"RSIS1",0,95,65,30,0);
      LabelsValues[1].Text("0.0");
      LabelsValues[1].FontSize(9);
      LabelsValues[1].Color(clrWhite);   
      Dialog.Add(LabelsValues[1]);
      LabelsValues[2].Create(0,"RSIS2",0,95,85,30,0);
      LabelsValues[2].Text("0.0");
      LabelsValues[2].FontSize(9);
      LabelsValues[2].Color(clrWhite);   
      Dialog.Add(LabelsValues[2]);
      LabelsValues[3].Create(0,"RSIS3",0,95,105,30,0);
      LabelsValues[3].Text("0.0");
      LabelsValues[3].FontSize(9);
      LabelsValues[3].Color(clrWhite);   
      Dialog.Add(LabelsValues[3]);
      LabelsValues[4].Create(0,"RSIS4",0,95,125,30,0);
      LabelsValues[4].Text("0.0");
      LabelsValues[4].FontSize(9);
      LabelsValues[4].Color(clrWhite);   
      Dialog.Add(LabelsValues[4]);
      LabelsValues[5].Create(0,"RSIS5",0,95,145,30,0);
      LabelsValues[5].Text("0.0");
      LabelsValues[5].FontSize(9);
      LabelsValues[5].Color(clrWhite);   
      Dialog.Add(LabelsValues[5]);
      LabelsValues[6].Create(0,"RSIS6",0,95,165,30,0);
      LabelsValues[6].Text("0.0");
      LabelsValues[6].FontSize(9);
      LabelsValues[6].Color(clrWhite);   
      Dialog.Add(LabelsValues[6]);
      LabelsValues[7].Create(0,"RSIS7",0,95,185,30,0);
      LabelsValues[7].Text("0.0");
      LabelsValues[7].FontSize(9);
      LabelsValues[7].Color(clrWhite);   
      Dialog.Add(LabelsValues[7]);
//---
   return(INIT_SUCCEEDED);
  }
void OnDeinit(const int reason)
{
//---
   Dialog.Destroy(reason);
}
  
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
//---
   //Comment(""+Symbol1+": "+DoubleToString(GetRsi(Symbol1),1)+" "+Symbol2+": "+DoubleToString(GetRsi(Symbol2),1));
//--- return value of prev_calculated for next call
   for(int i = 1 ; i< 8 ; i++){
      LabelsValues[i].Text(DoubleToString(GetRsi(i-1),1));
   }
   return(rates_total);
  }
//+------------------------------------------------------------------+
void SetSymbols(){
   symbols[0]= Symbol1;
   symbols[1]= Symbol2;
   symbols[2]= Symbol3;
   symbols[3]= Symbol4;
   symbols[4]= Symbol5;
   symbols[5]= Symbol6;
   symbols[6]= Symbol7;
   //symbols[7]= Symbol8;
   
}
void SetSymbols(int index, string symbol){
   symbols[index] = symbol;
}
string GetSymbol(int index){
   return symbols[index];
}
int GetSymbolIndex(string symbol){
   for(int i = 0; i<10; i++)
      if(symbols[i] == symbol) return i;
   return -1;
}
bool SetHandles(){
   int size = 7;
   for(int i = 0; i <size;i++){
      rsi_handle[i] = iRSI(symbols[i],TimeFrame,RSI_Period,applied_price);
      if(rsi_handle[i]== INVALID_HANDLE){
      //--- tell about the failure and output the error code 
      PrintFormat("Failed to create handle of the iRSI indicator for the symbol %s/%s, error code %d", 
                  symbols[i], 
                  EnumToString(TimeFrame), 
                  GetLastError());
      return false;              
     }
   }
   return true;
}
int GetHandle(string symbol){
   int index = GetSymbolIndex(symbol);
   return rsi_handle[index];
}
int GetHandle(int index){
   string symbol= GetSymbol(index);
   int i = GetSymbolIndex(symbol);
   return rsi_handle[i];
}
double GetRsi(string symbol){
   double   rsi[1];
   int handle = GetHandle(symbol);
   if(CopyBuffer(handle,0,0,1,rsi)!=1)
        {
         Print("CopyBuffer from iMA failed, no data, symbol: "+symbol);
         return 0.0;
        }
   return rsi[0];     
}
double GetRsi(int index){
   double   rsi[1];
   int handle = GetHandle(index);
   string symbol = GetSymbol(index);
   if(CopyBuffer(handle,0,0,1,rsi)!=1)
        {
         Print("CopyBuffer from iMA failed, no data, symbol: "+symbol);
         return 0.0;
        }
   return rsi[0];
}