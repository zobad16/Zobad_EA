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
#property indicator_buffers 8
#property indicator_color1 Green
#property indicator_color2 Yellow
#define PRICE_RATIO  1

extern string symbolY = "US30";
extern string symbolX = "US500";
extern int    ratioPeriod = 100;
extern color  PR_C = Green;
extern int    channelLength = 30;
extern color  LR_C = Yellow;
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
      
      SetIndexBuffer(0,prBuffer);
      SetIndexStyle(0,DRAW_LINE,EMPTY,EMPTY,PR_C);
      SetIndexBuffer(1,mean);
      SetIndexStyle(1,DRAW_LINE,EMPTY,EMPTY,LR_C);
      SetIndexBuffer(2,bufStdevC1p);
      SetIndexStyle(2,DRAW_LINE);
      SetIndexStyle(2,DRAW_LINE,EMPTY,EMPTY,C1);
      SetIndexBuffer(3,bufStdevC1n);
      SetIndexStyle(3,DRAW_LINE);
      SetIndexStyle(3,DRAW_LINE,EMPTY,EMPTY,C1);
      SetIndexBuffer(4,bufStdevC2p);
      SetIndexStyle(4,DRAW_LINE, EMPTY,EMPTY,C2);
      SetIndexBuffer(5,bufStdevC2n);
      SetIndexStyle(5,DRAW_LINE, EMPTY,EMPTY,C2);
      SetIndexBuffer(6,bufStdevC3p);
      SetIndexStyle(6,DRAW_LINE, EMPTY,EMPTY,C3);
      SetIndexBuffer(7,bufStdevC3n);
      SetIndexStyle(7,DRAW_LINE, EMPTY,EMPTY,C3);
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
   //double pr_start, pr_end;
  // LR(prBuffer,pr_start,pr_end);
  // mean[0]=pr_start;
   double _std = StdDev(prBuffer,mean);
   
   Comment("Standard Deviation: ",(string)_std);
   iStdDevC(mean,_std,stddevC1,bufStdevC1p,bufStdevC1n);
   iStdDevC(mean,_std,stddevC2,bufStdevC2p,bufStdevC2n);
   iStdDevC(mean,_std,stddevC3,bufStdevC3p,bufStdevC3n);
   //Calculate Price ratio
   //calculate std dev channels
   //Plot Price ratio on std channels

   //TestPriceRatio();
   
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
      else return;
      //Print("Price Ratio: ",(string)res[i]);
   }

}
/*void TestPriceRatio()
{
  double y[],x[];
  TestGetData(y,x);
  double res[];
  ArrayResize(res,100);
  int size = ArraySize(x);
   if(size!=ArraySize(y))size = 0;   
   for(int i =0 ; i < ArraySize(x) ; i++ )
   {
      double result =0.0;
      if(y[i]!=0 && x[i]!=0){      
         res[i]= y[i]/x[i];
         Comment("Res[",i,"]= ",res[i],", ");
        } 
      else return;
      //Print("Price Ratio: ",(string)res[i]);
   }
  //ArrayResize(x,)


}*//*
void TestGetData(double &y[], double &x[])
{
   double _y[]={52.381,51.782,54.851,54.470,54.381,55.809,55.395,55.193,54.037,56.252,
55.254,53.816,52.783,50.875,50.214,46.741,50.486,50.723,48.657,48.542,51.150,52.156,50.494,
51.883,49.815,49.919,50.639,50.820,52.839,52.762,53.587,51.610,52.522,52.866,51.587,50.396,
50.185,49.788,49.971,48.487,48.803,47.848,50.180,47.324,48.495,48.987,53.511,49.557,52.401,52.361,52.026,50.712,52.668,50.433,51.956,
51.237,52.990,51.921,51.060,51.041,50.359,50.804,49.180,50.651,50.280,47.584,51.600,49.803,49.925,50.990,49.501,54.625,49.076,54.562,51.128,53.193,51.563,48.461,46.116,
47.028,45.187,44.535,46.244,41.762,43.591,42.846,42.099,41.771,41.330,43.029,42.036,42.806,43.954,44.303,41.015,
40.747,40.249,41.851,43.086,42.698};
double _x[]= {47.738,47.307,49.392,49.778,51.435,50.529,50.323,50.138,
49.417,50.491,51.003,48.008,47.559,45.792,44.468,43.193,44.204,46.050,44.571,43.943,45.322,45.383,45.879,46.392,45.710,
44.680,44.584,45.700,47.159,47.284,48.429,46.649,46.689,46.814,46.590,46.132,45.964,44.405,43.971,43.979,
43.113,43.117,45.247,44.368,44.363,44.729,46.274,46.373,47.020,46.250,46.901,45.867,47.373,46.778,46.870,
46.365,46.627,46.872,46.492,45.730,46.191,45.281,44.897,44.769,46.047,44.881,45.698,44.352,45.179,46.095,
44.025,46.310,46.947,48.501,47.715,47.849,46.646,43.592,42.946,42.549,41.560,39.565,39.339,38.185,38.110,
36.947,35.896,35.848,36.401,36.332,37.646,38.234,38.467,38.549,36.662,35.699,35.989,37.587,38.080,38.103
};
 ArrayCopy(x,_x,0,0,WHOLE_ARRAY);
 ArrayCopy(y,_y,0,0,WHOLE_ARRAY);



}*/
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
     // _mean+=pr[i];
     res[i]=iMAOnArray(pr,0,channelLength,0,MODE_SMA,i);
   }
  // double avg = _mean/size;
   //Print("Mean{",_mean,"} Size{",size,"} Avg{",avg,"}");
   //for(int i = 0; i<size; i++)
  // res[0]=avg;
   
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
   for(int i=0; i<channelLength; i++)
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
     Comment("Stddev[",std_dev,"]");
     return std_dev;
 }
void iStdDevC(double &_mean[],double std,double channel, double &bufferPositive[], double &bufferNegative[])
{
   int size = channelLength;
   double _std=0.0;
   for(int i=0; i<size ; i++){   
      bufferPositive[i] = _mean[i] + std * channel ;
      //Comment("Mean[",_mean[i],"] std[",std,"] channel[",channel,"]");
      bufferNegative[i] = _mean[i] - std * channel ;
   }

}