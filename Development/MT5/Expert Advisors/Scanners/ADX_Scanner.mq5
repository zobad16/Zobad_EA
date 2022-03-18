//+------------------------------------------------------------------+
//|                                                  ADX_Scanner.mq5 |
//|                                      Copyright 2021, AlgoTradeup |
//|                                          https://algotradeup.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, AlgoTradeup"
#property link      "https://algotradeup.com"
#property version   "1.00"
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
#include <Controls\Dialog.mqh>
#include <Controls\Button.mqh>
#include <Controls\Label.mqh>
//--- input parameters
input string   ADXSET="----ADX PARAMETERS----";
input int      ADX_Period = 14;
input ENUM_TIMEFRAMES TimeFrame    = PERIOD_H4;
input ENUM_APPLIED_PRICE   applied_price=PRICE_CLOSE; 
input string   ScannerSettings="----Symbols----";
input string   Symbol1="CL-J22";
input string   Symbol2="GC_J22";
input string   Symbol3="SI-K22";
input string   Symbol4="NQ-H22";
input string   Symbol5="ES-H22";
input string   Symbol6="YM-H22";
bool start_flag = true;
int   rsi_handle[7];
string symbols[7];

CDialog Dialog;
CLabel  H_Labels[8];
CLabel  Labels[32];
CLabel  LabelsValues[32];
int OnInit()
  {
   start_flag =true;
//--- create timer
   EventSetTimer(10);
   SetSymbols();
      bool is_set_handles = SetHandles();
      if(!is_set_handles){
         Print("Reason handle failed");
         return INIT_FAILED;
       }  
       Dialog.Create(ChartID(),"    WWW.QUANTECHSOL.COM",0,5,5,300,250);
      string dialogNumber=Dialog.Name();
      ObjectSetInteger(ChartID(),dialogNumber+"Caption",OBJPROP_BGCOLOR,clrOrange);
      ObjectSetInteger(ChartID(),dialogNumber+"ClientBack",OBJPROP_BGCOLOR,clrBlack);
      ObjectSetInteger(ChartID(),dialogNumber+"Border",OBJPROP_BGCOLOR,clrBlack);
      CreateLabels();
      
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//--- destroy timer
   EventKillTimer();
   Dialog.Destroy(reason);
   
  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
   if(start_flag){
      GetValues();
      start_flag = false;
   }
   
  }
//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
  {
//---
     GetValues();
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
void CreateLabel(CDialog& dlg, CLabel& label, string name, int x, int y, string text, int fontsize =9, color _color = clrWhite){
   label.Create(0,name,0,x,y,0,0);
   label.Text(text);
   label.FontSize(fontsize);
   label.Color(_color);   
   dlg.Add(label);
}
void GetValues(){
   //int size = 28;
   int size = 6;
   for(int i = 1 ; i<= size; i++)
      LabelsValues[i].Text(DoubleToString(GetRsi(i-1),1));
    //for(int i = 17 ; i<= 24 ; i++)
    //  LabelsValues[i].Text(DoubleToString(GetRsi(i-3),1));
}
void SetSymbols(){
   symbols[0]= Symbol1;
   symbols[1]= Symbol2;
   symbols[2]= Symbol3;
   symbols[3]= Symbol4;
   symbols[4]= Symbol5;
   symbols[5]= Symbol6;
   /*symbols[6]= Symbol7;
   symbols[7]= Symbol8;
   symbols[8]= Symbol9;
   symbols[9]= Symbol10;
   symbols[10]= Symbol11;
   symbols[11]= Symbol12;
   symbols[12]= Symbol13;
   symbols[13]= Symbol14;
   symbols[14]= Symbol15;
   symbols[15]= Symbol16;
   symbols[16]= Symbol17;
   symbols[17]= Symbol18;
   symbols[18]= Symbol19;
   symbols[19]= Symbol20;
   symbols[20]= Symbol21;
   symbols[21]= Symbol22;
   symbols[22]= Symbol23;
   symbols[23]= Symbol24;*/
}
void SetSymbols(int index, string symbol){
   symbols[index] = symbol;
}
string GetSymbol(int index){
   return symbols[index];
}
int GetSymbolIndex(string symbol){
   for(int i = 0; i<28; i++)
      if(symbols[i] == symbol) return i;
   return -1;
}
bool SetHandles(){
   //int size = 27;
   int size = 6;
   for(int i = 0; i < size;i++){
      rsi_handle[i] = iADX(symbols[i],TimeFrame,ADX_Period);
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
   if(i == -1){
      Print("Unable to get handler. Reference index: "+IntegerToString(index));
   }
   
   return rsi_handle[i];
}
double GetRsi(string symbol){
   double   rsi[1];
   int handle = GetHandle(symbol);
   if(CopyBuffer(handle,0,0,1,rsi)!=1)
        {
         Print("CopyBuffer from iADX failed, no data, symbol: "+symbol);
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
void CreateLabels(){
   CreateLabel(Dialog,Labels[0],"Title",75,5,"ADX Scanner",14,clrWhite);
   //Headers
   /*CreateLabel(Dialog,Labels[1],"SymbolLBL",15,40,"Symbols",9,clrWhite);
   CreateLabel(Dialog,Labels[16],"SymbolLbl2",175,40,"Symbols",9,clrWhite);   
   CreateLabel(Dialog,LabelsValues[0],"RSILBL",95,40,"RSI",9,clrWhite);
   CreateLabel(Dialog,LabelsValues[15],"RSILBL2",255,40,"RSI",9,clrWhite);
   CreateLabel(Dialog,Labels[17],"SymbolLbl3",335,40,"Symbols",9,clrWhite);
   CreateLabel(Dialog,LabelsValues[16],"RSILBL3",415,40,"RSI",9,clrWhite);
   */
   CreateLabel(Dialog,H_Labels[0],"SymbolLBL",15,40,"Symbols",9,clrWhite);
   //CreateLabel(Dialog,H_Labels[1],"SymbolLbl2",175,40,"Symbols",9,clrWhite);   
   CreateLabel(Dialog,H_Labels[2],"ADXLBL",95,40,"ADX",9,clrWhite);
  // CreateLabel(Dialog,H_Labels[3],"ADXLBL2",255,40,"ADX",9,clrWhite);
   //CreateLabel(Dialog,H_Labels[4],"SymbolLbl3",335,40,"Symbols",9,clrWhite);
   //CreateLabel(Dialog,H_Labels[5],"ADXLBL3",415,40,"ADX",9,clrWhite);
   //CreateLabel(Dialog,H_Labels[6],"SymbolLbl4",495,40,"Symbols",9,clrWhite);   
   //CreateLabel(Dialog,H_Labels[7],"ADXLbl5",575,40,"Symbols",9,clrWhite);
            
      CreateLabel(Dialog,Labels[1],"Symbol1",15,65,Symbol1,8,clrWhite);
      CreateLabel(Dialog,Labels[2],"Symbol2",15,85,Symbol2,8,clrWhite);
      CreateLabel(Dialog,Labels[3],"Symbol3",15,105,Symbol3,8,clrWhite);
      CreateLabel(Dialog,Labels[4],"Symbol4",15,125,Symbol4,8,clrWhite);
      CreateLabel(Dialog,Labels[5],"Symbol5",15,145,Symbol5,8,clrWhite);
      CreateLabel(Dialog,Labels[6],"Symbol6",15,165,Symbol6,8,clrWhite);
      /*CreateLabel(Dialog,Labels[7],"Symbol7",15,185,Symbol7,8,clrWhite);
      
      CreateLabel(Dialog,Labels[8],"Symbol8",175,65,Symbol8,8,clrWhite);
      CreateLabel(Dialog,Labels[9],"Symbol9",175,85,Symbol9,8,clrWhite);
      CreateLabel(Dialog,Labels[10],"Symbol10",175,105,Symbol10,8,clrWhite);
      CreateLabel(Dialog,Labels[11],"Symbol11",175,125,Symbol11,8,clrWhite);
      CreateLabel(Dialog,Labels[12],"Symbol12",175,145,Symbol12,8,clrWhite);
      CreateLabel(Dialog,Labels[13],"Symbol13",175,165,Symbol13,8,clrWhite);
      CreateLabel(Dialog,Labels[14],"Symbol14",175,185,Symbol14,8,clrWhite);
      */
      CreateLabel(Dialog,LabelsValues[1],"ADX1",95,65,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[2],"ADX2",95,85,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[3],"ADX3",95,105,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[4],"ADX4",95,125,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[5],"ADX5",95,145,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[6],"ADX6",95,165,"0.0",9,clrWhite);
      /*CreateLabel(Dialog,LabelsValues[7],"ADX7",95,185,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[8],"ADX8",255,65,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[9],"ADX9",255,85,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[10],"ADX10",255,105,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[11],"ADX11",255,125,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[12],"ADX12",255,145,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[13],"ADX13",255,165,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[14],"ADX14",255,185,"0.0",9,clrWhite);
      
      CreateLabel(Dialog,Labels[15],"Symbol15",335,65,Symbol15,8,clrWhite);
      CreateLabel(Dialog,Labels[16],"Symbol16",335,85,Symbol16,8,clrWhite);
      CreateLabel(Dialog,Labels[17],"Symbol17",335,105,Symbol17,8,clrWhite);
      CreateLabel(Dialog,Labels[18],"Symbol18",335,125,Symbol18,8,clrWhite);
      CreateLabel(Dialog,Labels[19],"Symbol19",335,145,Symbol19,8,clrWhite);
      CreateLabel(Dialog,Labels[20],"Symbol20",335,165,Symbol20,8,clrWhite);
      CreateLabel(Dialog,Labels[21],"Symbol21",335,185,Symbol21,8,clrWhite);
      
      CreateLabel(Dialog,LabelsValues[15],"ADX15",415,65,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[16],"ADX16",415,85,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[17],"ADX17",415,105,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[18],"ADX18",415,125,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[19],"ADX19",415,145,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[20],"ADX20",415,165,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[21],"ADX21",415,185,"0.0",9,clrWhite);
      
      CreateLabel(Dialog, Labels[22],"Symbol22",495,65,Symbol22,8,clrWhite);   
      CreateLabel(Dialog, Labels[23],"Symbol23",495,85,Symbol23,8,clrWhite); 
      CreateLabel(Dialog, Labels[24],"Symbol24",495,105,Symbol24,8,clrWhite); 
      CreateLabel(Dialog, Labels[25],"Symbol25",495,125,Symbol25,8,clrWhite); 
      CreateLabel(Dialog, Labels[26],"Symbol26",495,145,Symbol26,8,clrWhite); 
      CreateLabel(Dialog, Labels[27],"Symbol27",495,165,Symbol27,8,clrWhite); 
      CreateLabel(Dialog, Labels[28],"Symbol28",495,185,Symbol28,8,clrWhite); 
      
      CreateLabel(Dialog,LabelsValues[22],"ADX22",575,65,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[23],"ADX23",575,85,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[24],"ADX24",575,105,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[25],"ADX25",575,125,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[26],"ADX26",575,145,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[27],"ADX27",575,165,"0.0",9,clrWhite);
      CreateLabel(Dialog,LabelsValues[28],"ADX28",575,185,"0.0",9,clrWhite);*/
}