//+------------------------------------------------------------------+
//|                                                           SR.mq4 |
//|                      Copyright © 2004, MetaQuotes Software Corp. |
//|                                       http://www.metaquotes.net/ |
//|                                                                  |
//+------------------------------------------------------------------+
#property  copyright "Copyright © 2004, MetaQuotes Software Corp."
#property  link      "http://www.metaquotes.net/"
//---- indicator settings
#property  indicator_separate_window
#property  indicator_buffers 6
#property  indicator_color1  MediumBlue
#property  indicator_color2  Red
#property  indicator_color3  Yellow
#property  indicator_color4  Red
#property  indicator_color5  Red
#property  indicator_color6  Red
#property  indicator_color7  White
#property  indicator_width1  2
//---- indicator parameters



extern string FXPair1        = "US30.CASH";
extern string FXPair2        = "US500.CASH";
//extern string FXPair3        = "USNDX.CASH";
extern int    SignalMethod   = MODE_SMA;
extern int    SignalSMA      = 14;
extern int    SignalSMA2     = 100;
input int    lagPeriod      = 8;
extern int    BandsPeriod    = 14;
extern int    BandsDeviation = 2;


//
double SDCDBuffer[];
double SDCDBuffer2[];
double SignalBuffer[];
double SignalBuffer2[];
double SignalBuffer3[];
double SignalBuffer4[];
double SignalBuffer5[];
double SDCDLagBuffer[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int init()
{

   SetIndexBuffer(0,SDCDBuffer);   SetIndexLabel(0,""+FXPair1+"/"+FXPair2+"");
   //SetIndexBuffer(1,SDCDBuffer2);   SetIndexLabel(1,"Nasdaq/DowJones");
   SetIndexBuffer(1,SignalBuffer); SetIndexLabel(1,"MA");
   SetIndexBuffer(2,SignalBuffer2);SetIndexLabel(2,"MA2");
   SetIndexBuffer(3,SignalBuffer3);SetIndexLabel(3,"Lower");
   SetIndexBuffer(4,SignalBuffer4);SetIndexLabel(4,"Upper");
  // SetIndexBuffer(6,SDCDLagBuffer);SetIndexLabel(6,""+FXPair1+"/"+FXPair3+"");
//
   IndicatorShortName("PR("+BandsPeriod+",["+FXPair1+"],["+FXPair2+"])");
   return(0);
  }
  
//+------------------------------------------------------------------+
//| Moving Averages Convergence/Divergence                           |
//+------------------------------------------------------------------+

int start()
{
   double SDCDBuffer1[];
   int counted_bars=IndicatorCounted();
   int i,limit;
   double point = MarketInfo(FXPair2,MODE_POINT);
   if(counted_bars<0) return(-1);
   if(counted_bars>0) counted_bars--;
         limit = MathMin(Bars-counted_bars,Bars-1);
   //
   //
   //
   //
   //
   ArrayResize(SDCDBuffer, limit,limit );
   ArrayResize(SDCDBuffer1, limit,limit );
   int multiplier=0;
   int p1mult = 0 , p2mult = 0;  
   
   if(FXPair1 == "US500.CASH" && FXPair2 =="US30.CASH" ) {   p1mult = 50 ; p2mult = 5;}
   else if(FXPair1 == "US30.CASH" && FXPair2 == "US500.CASH"){p1mult = 5 ; p2mult = 50;}
   else if(FXPair1 == "US30.CASH" && FXPair2 =="USDNX.CASH" ){    p1mult = 5 ; p2mult = 20;}  
   for(i=limit; i>=0; i--) SDCDBuffer[i] = iMA(FXPair1,0,1,0,MODE_SMA,PRICE_CLOSE*p1mult,i) / MathMax(iMA(FXPair2,0,1,0,MODE_SMA,PRICE_CLOSE*p2mult,i),point);
   for(i=limit; i>=0; i--)
   {
      SignalBuffer[i]  = iMAOnArray(SDCDBuffer,Bars,SignalSMA, 0,SignalMethod,i);
             //SignalBuffer2[i] = iMAOnArray(SDCDBuffer,Bars,SignalSMA2,0,SignalMethod,i);      
      SignalBuffer3[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,MODE_LOWER,i); 
      SignalBuffer4[i] = iBandsOnArray(SDCDBuffer,0,BandsPeriod, BandsDeviation,0,MODE_UPPER,i);
   }
          
         //for(i=limit; i>=0; i--) SDCDLagBuffer[i] = iMA(FXPair1,0,1,0,MODE_SMA,PRICE_CLOSE*5,i) / MathMax(iMA(FXPair3,0,1,0,MODE_SMA,PRICE_CLOSE*20,i),point);
         //for(i=limit; i>=0; i--) SDCDBuffer[i] = (iClose(FXPair1,0,i)*50) / (iClose(FXPair2,0,i)*5); 
        // for(i= limit; i>1;i--) SDCDLagBuffer[i] = (SDCDBuffer[i+lagPeriod]-SDCDBuffer[i]);
         //for(int l =0; l<=lagPeriod; l++) SDCDLagBuffer[l] = SDCDBuffer[l]-SDCDBuffer[l+lagPeriod];              
        // for(i= 0; i<=limit;i++) SDCDLagBuffer[i] = (SDCDBuffer[lagPeriod-i]-SDCDBuffer[i]);

    // }
   return(0);
  }

/*double iATROnArray(double &_High[], double &_Low[], double &_Close[], int length, int shift=0)
{
    double sum = 0;
    for (int iBar = shift+length-1; iBar >= shift; iBar--){
        double  TR  = MathMax(_High[iBar], _Close[iBar+1]) - MathMin(_Low[iBar], _Close[iBar+1]);
        sum += TR;
    }
    return(sum/length);
}*/
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