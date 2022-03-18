//+------------------------------------------------------------------+
//|                                             price_ratio.mq4      |
//|                                               Quantech Sol_Zobad |
//|                                    https://www.quantsoftware.net |
//+------------------------------------------------------------------+
#property copyright "Quantech Sol_Zobad"
#property link      "https://www.quantsoftware.net"
#property strict
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 9
#property  indicator_plots 4
#property  indicator_color1  MediumBlue
#property  indicator_type1 DRAW_LINE
#property  indicator_color2  Red
#property  indicator_type2 DRAW_LINE
#property  indicator_color3  Red
#property  indicator_type3 DRAW_LINE
#property  indicator_color4  Red
#property  indicator_type4 DRAW_LINE

//---- indicator parameters
#include <MovingAverages.mqh>



input string FXPair1        = "GBPUSD";
input string FXPair2        = "USDJPY";
//extern string FXPair3        = "USNDX.CASH";
input int    SignalMethod   = MODE_SMA;
input int    SignalSMA      = 14;
input int    SignalSMA2     = 100;
input int    lagPeriod      = 8;
input int    periodIs    = 14;//period

input int    BandsPeriod    = 14;
input int    BandsDeviation = 2;

double        ExtMLBuffer[];
double        ExtTLBuffer[];
double        ExtBLBuffer[];
double        ExtStdDevBuffer[];
double SDCDBuffer[];
double SignalBuffer[];
double SignalBuffer2[];
double SignalBuffer3[];
double SignalBuffer4[];
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int ma1,ma2;
int OnInit()
{
   int p1mult = 1 , p2mult = 1;  
   
   if(StringFind(FXPair1, "US500",0)!= -1)  p1mult = 50 ;
   else if(  StringFind(FXPair1, "US30" ,0) !=-1) p1mult = 5 ;
   else if( StringFind(FXPair1, "USNDX" ,0) !=-1) p1mult = 20 ;
   
   if(StringFind(FXPair2, "US500",0)!= -1)  p2mult = 50 ;
   else if(  StringFind(FXPair2, "US30" ,0) !=-1) p2mult = 5 ;
   else if( StringFind(FXPair2, "USNDX" ,0) !=-1) p2mult = 20 ;
   ma1=iMA(FXPair1,0,1,0,MODE_SMA,PRICE_CLOSE*p1mult);
   ma2=iMA(FXPair2,0,1,0,MODE_SMA,PRICE_CLOSE*p2mult);
   SetIndexBuffer(1,SignalBuffer); 
   ArraySetAsSeries(SignalBuffer,true); 
   PlotIndexSetString(1,PLOT_LABEL,"RSI");
   SetIndexBuffer(2,SignalBuffer3);
   ArraySetAsSeries(SignalBuffer3,true); 
   PlotIndexSetString(2,PLOT_LABEL,"Lower");
   SetIndexBuffer(3,SignalBuffer4);
   ArraySetAsSeries(SignalBuffer4,true); 
   PlotIndexSetString(3,PLOT_LABEL,"Upper");
   SetIndexBuffer(0,SDCDBuffer); 
   ArraySetAsSeries(SDCDBuffer,true); 
   PlotIndexSetString(0,PLOT_LABEL,""+FXPair1+"/"+FXPair2+"");
   SetIndexBuffer(4,SignalBuffer2,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(SignalBuffer2,true); 
   PlotIndexSetString(4,PLOT_LABEL,"MA2");
   SetIndexBuffer(5,ExtMLBuffer,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(ExtMLBuffer,true); 
   SetIndexBuffer(6,ExtTLBuffer,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(ExtTLBuffer,true); 
   SetIndexBuffer(7,ExtBLBuffer,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(ExtBLBuffer,true); 
   SetIndexBuffer(8,ExtStdDevBuffer,INDICATOR_CALCULATIONS);
   ArraySetAsSeries(ExtStdDevBuffer,true); 
   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE); 
   IndicatorSetString(INDICATOR_SHORTNAME,"PR("+IntegerToString(BandsPeriod)+",["+FXPair1+"],["+FXPair2+"])");
   IndicatorSetInteger(INDICATOR_DIGITS,MathMax(_Digits+1,6));
   return INIT_SUCCEEDED;
  
  }
  
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+
void  OnDeinit(const int  reason)
{

}
int  OnCalculate( 
   const int        rates_total,       
   const int        prev_calculated,   
   const int        begin,             
   const double&    price[]           
   )
  {
   int counted_bars=prev_calculated;
   int i,limit;
   if(IsStopped()) 
      return(0);
   double point = SymbolInfoDouble(FXPair2,SYMBOL_POINT);
   
   if(counted_bars<0) return 0;      
   
   if(counted_bars>0) counted_bars--;       
   
   int bar=MathMin(MathMin(Bars(Symbol(),PERIOD_CURRENT),Bars(FXPair1,PERIOD_CURRENT)),Bars(FXPair2,PERIOD_CURRENT));
      
   limit = MathMin(bar-counted_bars,bar-1);
   
   
   
   for(i=MathMax(limit,0); i>=0&&!IsStopped(); i--) 
   {
      double mas[];
      CopyBuffer(ma1,0,i,1,mas);
      double mas1[];
      CopyBuffer(ma2,0,i,1,mas1);
      SDCDBuffer[i] = mas[0] / MathMax(mas1[0],point);
   }   
      
   for(i=MathMax(limit,0); i>=0&&!IsStopped(); i--)
      SignalBuffer[i]  = iMAOnArray(SDCDBuffer,bar,SignalSMA, 0,SignalMethod,i);
   if(!first)
      for(i=BandsPeriod; i<=MathMax(limit,BandsPeriod)&&!IsStopped(); i++)
      {
         SignalBuffer3[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,1,i); 
         SignalBuffer4[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,0,i);
      }
   else
   {
      SignalBuffer3_ = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,1,BandsPeriod); 
      SignalBuffer4_ = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,0,BandsPeriod);
   }
   if(!first)
      for(i=0; i<=MathMax(limit-BandsPeriod-1,0)&&!IsStopped(); i++)
         {
            SignalBuffer3[i] = SignalBuffer3[i+BandsPeriod-1]; 
            SignalBuffer4[i] = SignalBuffer4[i+BandsPeriod-1];
         }
   else
   {
      SignalBuffer3[0]=SignalBuffer3_;
      SignalBuffer4[0]=SignalBuffer4_;
   } 
   first=1;
   return rates_total;
}
int first=0;
double SignalBuffer3_=0,SignalBuffer4_=0;
double iBandsOnArray(double &price[],int total,int BandsPeriod_, double BandsDeviation_, int ma_shift, int mode,int i)
{
      ExtMLBuffer[i]=SimpleMA(i,BandsPeriod_,price);
      //--- calculate and write down StdDev
      ExtStdDevBuffer[i]=StdDev_Func(i,price,ExtMLBuffer,BandsPeriod_);
      //--- upper line
      if(!mode) return ExtTLBuffer[i]=ExtMLBuffer[i]+BandsDeviation_*ExtStdDevBuffer[i];
      //--- lower line
      return ExtBLBuffer[i]=ExtMLBuffer[i]-BandsDeviation_*ExtStdDevBuffer[i];
}
double StdDev_Func(const int position,const double &price[],const double &ma_price[],const int period_)
  {
   double std_dev=0.0;
//--- calcualte StdDev
   if(position>=period_)
     {
      for(int i=0; i<period_; i++)
         std_dev+=MathPow(price[position-i]-ma_price[position],2.0);
      std_dev=MathSqrt(std_dev/period_);
     }
//--- return calculated value
   return(std_dev);
  }
double iMAOnArray(double &array[],
                      int total,
                      int period_,
                      int ma_shift,
                      int ma_method,
                      int shift)
  {
   double buf[],arr[];
   if(total==0) total=ArraySize(array);
   if(total>0 && total<=period_) return(0);
   if(shift>total-period_-ma_shift) return(0);
   switch(ma_method)
     {
      case MODE_SMA :
        {
         total=ArrayCopy(arr,array,0,shift+ma_shift,period_);
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0;
         int    i,pos=total-1;
         for(i=1;i<period_;i++,pos--)
            sum+=arr[pos];
         while(pos>=0)
           {
            sum+=arr[pos];
            buf[pos]=sum/period_;
            sum-=arr[pos+period_-1];
            pos--;
           }
         return(buf[0]);
        }
      case MODE_EMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double pr=2.0/(period_+1);
         int    pos=total-2;
         while(pos>=0)
           {
            if(pos==total-2) buf[pos+1]=array[pos+1];
            buf[pos]=array[pos]*pr+buf[pos+1]*(1-pr);
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_SMMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0;
         int    i,k,pos;
         pos=total-period_;
         while(pos>=0)
           {
            if(pos==total-period_)
              {
               for(i=0,k=pos;i<period_;i++,k++)
                 {
                  sum+=array[k];
                  buf[k]=0;
                 }
              }
            else sum=buf[pos+1]*(period_-1)+array[pos];
            buf[pos]=sum/period_;
            pos--;
           }
         return(buf[shift+ma_shift]);
        }
      case MODE_LWMA :
        {
         if(ArrayResize(buf,total)<0) return(0);
         double sum=0.0,lsum=0.0;
         double price;
         int    i,weight=0,pos=total-1;
         for(i=1;i<=period_;i++,pos--)
           {
            price=array[pos];
            sum+=price*i;
            lsum+=price;
            weight+=i;
           }
         pos++;
         i=pos+period_;
         while(pos>=0)
           {
            buf[pos]=sum/weight;
            if(pos==0) break;
            pos--;
            i--;
            price=array[pos];
            sum=sum-lsum+price*period_;
            lsum-=array[i];
            lsum+=price;
           }
         return(buf[shift+ma_shift]);
        }
      default: return(0);
     }
   return(0);
  }
//+------------------------------------------------------------------+