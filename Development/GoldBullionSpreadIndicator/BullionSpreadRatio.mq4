//+------------------------------------------------------------------+
//|                                                PriceRatioNew.mq4 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 1
#property indicator_plots   1
//--- plot pr
#property indicator_label1  "pr"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrWhite
#property indicator_style1  STYLE_SOLID
#property indicator_width1  1
//--- indicator buffers

enum CalculationType {
   DIFFERENCE = 1, //Price difference
};
enum CalculationPrice {
   OPEN =0, //Open
   CLOSE =1 //Close
   };


double         prBuffer[];
input string            pair1 = "GCZ3";
input string            pair2 = "XAUUSD";
input CalculationType   calculationType  = DIFFERENCE; 
input CalculationPrice  calculationPrice = CLOSE; 

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
  string short_name;
//--- indicator buffers mapping
   IndicatorDigits(2);
   SetIndexBuffer(0,prBuffer);
   short_name="Bullion Spread Ratio: " ;
   IndicatorShortName(short_name);
   SetIndexLabel(0,short_name);
//---
   return(INIT_SUCCEEDED);
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
   if(calculationType == DIFFERENCE){
   //Calculation type difference
   double pair1Price = 0.0;
   double pair2Price = 0.0;
   for(int i=0; i<rates_total; i++){
      if(calculationPrice == CLOSE){      
         pair1Price = iClose(pair1,0,i);
         pair2Price = iClose(pair2,0,i);;
      }else if(calculationPrice ==OPEN){
         pair1Price = iOpen(pair1,0,i);
         pair2Price = iOpen(pair1,0,i);
      }
      if(pair1Price <= 0 || pair2Price <= 0)return(0);
      
      double spread = pair1Price - pair2Price;
      prBuffer[i]=spread;
      
      
   
   }
   
   
   }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
