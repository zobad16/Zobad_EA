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
#property indicator_buffers 7
#property indicator_color1 Green
#property indicator_color2 Yellow
#define PRICE_RATIO  1

extern string symbolY = "US30";
extern string symbolX = "US500";
extern int    ratioPeriod = 100;
extern color  PR_C;
extern int    channelLength = 30;
extern color  LR_C;
extern double stddevC1 = 0.618;
extern color  C1 = LightGreen;
extern double stddevC2 = 1.618;
extern color  C2 = Brown;
extern double stddevC3 = 2.618;
extern color C3 = Red;
const int period = 100;
double prBuffer [];
double mean[];
double bufStdevC1p[]; double bufStdevC1n[];
double bufStdevC2p[]; double bufStdevC2n[];
double bufStdevC3p[]; double bufStdevC3n[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
      SetIndexStyle(0,DRAW_LINE,EMPTY,EMPTY,PR_C);
      SetIndexBuffer(0,prBuffer);
      SetIndexStyle(0,DRAW_LINE);
      SetIndexBuffer(1,mean);
      SetIndexStyle(1,DRAW_LINE);
      SetIndexBuffer(2,bufStdevC1p);
      SetIndexStyle(2,DRAW_LINE);
      SetIndexStyle(2,DRAW_LINE,EMPTY,EMPTY,C1);
      SetIndexBuffer(3,bufStdevC1n);
      SetIndexStyle(3,DRAW_LINE);
      SetIndexStyle(3,DRAW_LINE,EMPTY,EMPTY,C1);
      /*SetIndexBuffer(4,bufStdevC2p);
      SetIndexStyle(4,DRAW_LINE);
      SetIndexBuffer(5,bufStdevC2n);
      SetIndexStyle(5,DRAW_LINE);
      SetIndexBuffer(6,bufStdevC3p);
      SetIndexStyle(6,DRAW_LINE);
      SetIndexBuffer(7,bufStdevC3n);
      SetIndexStyle(7,DRAW_LINE);*/
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
   
   double x[], y[];
   ArrayResize(x,ratioPeriod);
   ArrayResize(y,ratioPeriod);
   GetData(symbolX,x );
   GetData(symbolY,y);
   PriceRatio(y,x,prBuffer);
   Mean(prBuffer,mean);
   double _std = StdDev(prBuffer,mean);
   Comment("Standard Deviation: ",(string)_std);
   iStdDevC(mean,_std,stddevC1,bufStdevC1p,bufStdevC1n);
  // iStdDevC(mean,_std,stddevC2,bufStdevC2p,bufStdevC2n);
  // iStdDevC(mean,_std,stddevC3,bufStdevC3p,bufStdevC3n);
   //Calculate Price ratio
   //calculate std dev channels
   //Plot Price ratio on std channels

   
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
void PriceRatio(double &y[], double &x[], double &res[])
{
   
   
   int size = ArraySize(x);
   if(size!=ArraySize(y))size = 0;   
   for(int i =0 ; i < ratioPeriod ; i++ )
   {
      double result =0.0;
      if(y[i]!=0 && x[i]!=0)
         res[i]= y[i]/x[i];
      else continue;
      //Print("Price Ratio: ",(string)res[i]);
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
   int size = channelLength;
   double _mean=0.0;
   for(int i=0; i<size ; i++){   
      _mean+=pr[i];
   }
   double avg = _mean/size;
   //Print("Mean{",_mean,"} Size{",size,"} Avg{",avg,"}");
   for(int i = 0; i<size; i++)
   res[i]=avg;
   
}
 void LR(double &pr[],double &pStart, double &pStop)
 {
   int n = channelLength - 1;
   double value=0.0;
   double a,b,c;
   double sumy=value;
   double sumx=0.0;
   double sumxy=0.0;
   double sumx2=0.0;
   for(int i=1; i<n; i++)
     {
      value=pr[i];
      sumy+=value;
      sumxy+=value*i;
      sumx+=i;
      sumx2+=i*i;
     }
   c=sumx2*n-sumx*sumx;
   if(c==0.0) return;
   b=(sumxy*n-sumx*sumy)/c;
   a=(sumy-sumx*b)/n;
   double LR_price_2=a;
   double LR_price_1=a+b*n;
   pStart = LR_price_1;
   pStop = LR_price_2;
 }
 
double StdDev(double &price_ratio[], double &_mean[]){
   double x=0,x_sum=0,x_avg=0,x_sum_squared=0,std_dev=0;
   for(int i=0; i<period; i++)
     {
      //Takes close price and - it from the LR/mean
      x=MathAbs(price_ratio[i]-_mean[i]);
      x_sum+=x;
      if(i>0)
        {
         x_avg=(x_avg+x)/i;
         x_sum_squared+=(x-x_avg)*(x-x_avg);
         std_dev=MathSqrt(x_sum_squared/(period-1));
        }
     }
     return std_dev;
 }
void iStdDevC(double &_mean[],double std,double channel, double &bufferPositive[], double &bufferNegative[])
{
   int size = channelLength;
   double _std=0.0;
   for(int i=0; i<size ; i++){   
      bufferPositive[i] = _mean[i] + std * channel ;
      bufferNegative[i] = _mean[i] - std * channel ;
   }

}