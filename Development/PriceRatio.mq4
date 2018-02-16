//+------------------------------------------------------------------+
//|                                                   PriceRatio.mq4 |
//|                                   Copyright 2017, Zobad Mahmood. |
//|                                    https://www.quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Zobad Mahmood."
#property link      "https://www.quantsoftware.net"
#property version   "1.00"
#property strict
#property indicator_separate_window
#property indicator_buffers 2
#property indicator_color1 Green
#property indicator_color2 Yellow
#define PRICE_RATIO  1

extern string symbolX = "XAUUSD";
extern string symbolY = "GBPUSD";
extern int    ratioPeriod = 100;
extern int    channelLength = 30;
extern color  LR_C;
extern double stddevC1 = 0.618;
extern color  C1;
extern double stddevC2 = 1.618;
extern color  C2;
extern double stddevC3 = 2.618;
extern color C3;
const int period = 100;
double prBuffer [];
double mean[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
      SetIndexStyle(0,DRAW_LINE);
      SetIndexBuffer(0,prBuffer);
      SetIndexStyle(0,DRAW_LINE);
      SetIndexBuffer(1,mean);
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
   //Get data
   
   double x[100], y[100], pr[100];
   GetData(symbolX,x );
   GetData(symbolY,y);
   PriceRatio(y,x,prBuffer);
   Mean(prBuffer,mean);
   //Calculate Price ratio
   //calculate std dev channels
   //Plot Price ratio on std channels

   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void PriceRatio(double &y[], double &x[], double &res[])
{
   double result =0.0;
   int size = ArraySize(x);
   if(size!=ArraySize(y))size = 0;   
   for(int i =0 ; i < size -1 ; i++ )
   {
      //result+= y[i]/x[i];
      res[i]= y[i]/x[i];
   }

}
void GetData(string x, double &res[])
{
   for(int i =0; i< ratioPeriod ; i++){
      res[i]=iClose(x,PERIOD_CURRENT,i);   
   }
}

void Mean(double &pr[], double &res[])
{
   int size = 10;
   double _mean=0.0;
   for(int i=0; i<size ; i++){   
      _mean+=pr[i];
   }
   double avg = _mean/size;
   Print("Mean{",_mean,"} Size{",size,"} Avg{",avg,"}");
   for(int i = 0; i<size; i++)res[i]=avg;
   
}
