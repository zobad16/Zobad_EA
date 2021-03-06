//+------------------------------------------------------------------+
//|                                                           SR.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 5
#property  indicator_color1  MediumBlue
#property  indicator_color2  Red
#property  indicator_color3  Yellow
#property  indicator_color4  Brown
#property  indicator_color5  Brown
#property  indicator_color6  White
#property  indicator_width1  2
//---- indicator parameters



extern string FXPair1        = "EURUSD";
extern string FXPair2        = "GBPUSD";
extern int    SignalMethod   = MODE_SMA;
extern int    SignalSMA      = 14;
extern int    SignalSMA2     = 100;
extern int    BandsPeriod    = 14;
extern int    BandsDeviation = 2;


//
double SDCDBuffer[];
double SignalBuffer[];
double SignalBuffer2[];
double SignalBuffer3[];
double SignalBuffer4[];
double SignalBuffer5[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{

   SetIndexBuffer(0,SDCDBuffer);   SetIndexLabel(0,"SDCD");
   SetIndexBuffer(1,SignalBuffer); SetIndexLabel(1,"Signal");
   SetIndexBuffer(2,SignalBuffer2);SetIndexLabel(2,"Signal2");
   SetIndexBuffer(3,SignalBuffer3);SetIndexLabel(2,"Signal3");
   SetIndexBuffer(4,SignalBuffer4);SetIndexLabel(2,"Signal4");
//
   IndicatorShortName("SR("+BandsPeriod+","+SignalSMA+")");
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+

int start()
{
   int counted_bars=IndicatorCounted();
   int i,limit;
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
   //
   //
   //
   //
   //
      
   for(i=limit; i>=0; i--) SDCDBuffer[i] = iMA(FXPair1,0,1,0,MODE_SMA,PRICE_OPEN,i) / MathMax(iMA(FXPair2,0,1,0,MODE_SMA,PRICE_OPEN,i),Point);              
   for(i=limit; i>=0; i--)
   {
       SignalBuffer[i]  = iMAOnArray(SDCDBuffer,Bars,SignalSMA, 0,SignalMethod,i);
       SignalBuffer2[i] = iMAOnArray(SDCDBuffer,Bars,SignalSMA2,0,SignalMethod,i);      
       SignalBuffer3[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,MODE_LOWER,i); 
       SignalBuffer4[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,MODE_UPPER,i);
    }
     
   return(0);
  }

double iATROnArray(double _High[], double _Low[], double _Close[], int length, int shift=0)
{
    double sum = 0;
    for (int iBar = shift+length-1; iBar >= shift; iBar--){
        double  TR  = MathMax(_High[iBar], _Close[iBar+1]) - MathMin(_Low[iBar], _Close[iBar+1]);
        sum += TR;
    }
    return(sum/length);
}
void GetData(string symbol,int length,double & _High[],double & _Low[], double & _Close[])
{
   for(int i = length -1; i >=0; i--)
   {
      _High[i] = iHigh(symbol,0,i);
      _Low[i]  = iLow(symbol, 0 , i);
      _Close[i] = iClose(symbol,0,i);
   }
   
}
//+------------------------------------------------------------------+