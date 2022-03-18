//+------------------------------------------------------------------+
//|                                                   pivotpoint.mq5 |
//|                        Copyright 2012,                   niuniu. |
//|                                          risktechnocrat@gmail.com|
//+------------------------------------------------------------------+
#property copyright "Copyright 2012, niuniu"
#property link      "http://www.mql5.com"
#property version   "1.00"
//--- indicator settings
#property indicator_chart_window
#property indicator_buffers 7
#property indicator_plots   7
#property indicator_color1  Red
#property indicator_color2  Red
#property indicator_color3  Red
#property indicator_color4  Yellow
#property indicator_color5  DodgerBlue
#property indicator_color6  DodgerBlue
#property indicator_color7  DodgerBlue
//---
#property indicator_type1   DRAW_LINE
#property indicator_type2   DRAW_LINE
#property indicator_type3   DRAW_LINE
#property indicator_type4   DRAW_LINE
#property indicator_type5   DRAW_LINE
#property indicator_type6   DRAW_LINE
#property indicator_type7   DRAW_LINE
//---
#property indicator_label1  "R3"
#property indicator_label2  "R2"
#property indicator_label3  "R1"
#property indicator_label4  "Pivot Point"
#property indicator_label5  "S1"
#property indicator_label6  "S2"
#property indicator_label7  "S3"
//+------------------------------------------------------------------+
//| ENUM_PP_PERIOD                                                   |
//+------------------------------------------------------------------+
enum ENUM_PP_PERIOD
  {
   ppDay,   // Day 
   ppWeek,  // Week
   ppMonth  // Month
  };

//--- external parameters
input ENUM_PP_PERIOD ppPeriod=ppDay;    // PivotPoint Calculation Period

//---- buffers
double PPBuffer[];
double S1Buffer[];
double R1Buffer[];
double S2Buffer[];
double R2Buffer[];
double S3Buffer[];
double R3Buffer[];

//--global variables
int fontsize=10;
double P,S1,R1,S2,R2,S3,R3;
double LastHigh,LastLow,x;

MqlDateTime dateStr1;
MqlDateTime dateStr2;

bool drawBegin=false;
int dayOfWeek;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0,R3Buffer,INDICATOR_DATA);
   SetIndexBuffer(1,R2Buffer,INDICATOR_DATA);
   SetIndexBuffer(2,R1Buffer,INDICATOR_DATA);
   SetIndexBuffer(3,PPBuffer,INDICATOR_DATA);
   SetIndexBuffer(4,S1Buffer,INDICATOR_DATA);
   SetIndexBuffer(5,S2Buffer,INDICATOR_DATA);
   SetIndexBuffer(6,S3Buffer,INDICATOR_DATA);
//--- sets first bar from what index will be drawn
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,0.0);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,0.0);
//---
   return(0);
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
   int limit;
   if((ppPeriod==ppDay && _Period>PERIOD_D1) ||
      (ppPeriod==ppWeek && _Period>PERIOD_W1) ||
      (ppPeriod==ppMonth && _Period>PERIOD_MN1)) return(0);

//---
   if(prev_calculated==0) limit=0;
   else                   limit=prev_calculated-1;

   int dWeek=0;
//---
   for(int i=limit;i<rates_total-1 && !IsStopped();i++)
     {
      if(LastHigh==0.0)
        {
         //--- initialize
         LastHigh=high[i];
        }
      else
        {
         if(high[i]>LastHigh) LastHigh=high[i];
        }

      if(LastLow==0.0)
        {
         LastLow=low[i];
        }
      else
        {
         if(low[i]<LastLow) LastLow=low[i];
        }

      //--- decide whether
      TimeToStruct(time[i],dateStr1);
      TimeToStruct(time[i+1],dateStr2);

      if(dWeek==0) dWeek=dateStr1.day_of_week; //initialize

      //--- different day, calculate pivotpoint
      if(((ppPeriod==ppDay) && (dateStr1.day!=dateStr2.day))
         || ((ppPeriod==ppWeek) && (dWeek==dateStr2.day_of_week)) // start of new week
         || ((ppPeriod== ppMonth) && (dateStr1.mon!= dateStr2.mon)))
        {
         //--- calculate pivot points in current time period
         P=(LastHigh+LastLow+close[i])/3;
         R1 = (2*P)-LastLow;
         S1 = (2*P)-LastHigh;
         R2 = P+(LastHigh - LastLow);
         S2 = P-(LastHigh - LastLow);
         R3 = (2*P)+(LastHigh-(2*LastLow));
         S3 = (2*P)-((2* LastHigh)-LastLow);

         //--- start ploting when first 
         if(drawBegin)
           {
            PlotIndexSetInteger(0,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(1,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(2,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(3,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(4,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(5,PLOT_LINE_COLOR,159);
            PlotIndexSetInteger(6,PLOT_LINE_COLOR,159);
            drawBegin=true;
           }

         if(ppPeriod==ppWeek) dWeek=dateStr1.day_of_week;

         //--- reset period low & high
         LastLow=open[i+1]; LastHigh=open[i+1];
        }
      //--- plot starts at the next time period
      PPBuffer[i+1]=P;
      S1Buffer[i+1]=S1;
      R1Buffer[i+1]=R1;
      S2Buffer[i+1]=S2;
      R2Buffer[i+1]=R2;
      S3Buffer[i+1]=S3;
      R3Buffer[i+1]=R3;
     }
//--- return value of prev_calculated for next call
   return(rates_total);
  }
//+------------------------------------------------------------------+
