//+------------------------------------------------------------------+
//|                                                   Indicators.mqh |
//|                                   Copyright 2017, Zobad Mahmood. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Zobad Mahmood."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
class Indicators
{
   private:
            int             _period_BB;
            int             _period_atr;
            int             _LR_period;
            int             _LR_length;
            double          _std_Channel_1;
            double          _std_Channel_2;
            double          _std_Channel_3;
            ENUM_TIMEFRAMES _chartTimeFrame;
   public:
            double          iAtr(int index);
            double          iPRAtr(string y, string x,int period,int index);
            double          iBB(int index, int mode);
            double          iLR(int index, int mode);
            double          iLR2(int index,int mode);
            double          iPR(string y, string x,int period,int index, int mode);
            double          iPR2(int index, int mode);
            void            setPeriodBB(int _period){_period_BB = _period;}
            void            setPeriodATR(int _period){_period_atr = _period;}
            double          iADR(int mode, string symbol = "");
            Indicators();
            Indicators(int pBB =14,int pAtr=14,int pLR=14, int lengthLR =34, double stdc1 =0.618, double stdc2 = 1.618, double stdc3 = 2.618);

            ~Indicators();
};
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Indicators::Indicators()
{
   _period_BB  = 14;
   _period_atr = 14;
   _LR_period  = 0;
   _LR_length  = 34;
   _std_Channel_1 = 0.618;
   _std_Channel_2 = 1.618;
   _std_Channel_3 = 2.618;   
}
Indicators::Indicators(int pBB ,int pAtr=14,int pLR=14, int lengthLR =34, double stdc1 =0.618, double stdc2 = 1.618, double stdc3 = 2.618)
{
   _period_BB  = pBB;
   _period_atr = pAtr;
   _LR_period  = pLR;
   _LR_length  = lengthLR;
   _std_Channel_1 = stdc1;
   _std_Channel_2 = stdc2;
   _std_Channel_3 = stdc3;   
}
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
Indicators::~Indicators()
  {
  }
//+------------------------------------------------------------------+

double Indicators::iAtr(int index)
{
   double atr =0.0;
   atr= NormalizeDouble(iATR(NULL, 0,_period_atr,index),Digits);   
   return atr;
}
double Indicators::iPRAtr(string y, string x,int period,int index)
{
   double atr =0.0;
   string path = "PR_ATR.EX4";
   atr = iCustom(NULL,0,path,y,x,period,0,index);
   //atr= NormalizeDouble(iATR(NULL, 0,_period_atr,index),Digits);   
   return atr;
}
double Indicators::iBB(int index, int mode)
{
   double bb= 0.0;
   if(mode>=0 && mode <= 2)
   {
      bb= NormalizeDouble(iBands(NULL,0,_period_BB,2, 0, PRICE_CLOSE, mode,index),Digits);
   }
   return bb;
}
double Indicators::iLR(int index,int mode)
{
   double ilr=0.0;
   string LR_trendline, stDevCP1,stDevCM1, stDevCP2, stDevCM2, stDevCP3, stDevCM3;
   LR_trendline = (string)_LR_period+"m "+(string)_LR_length+" TL";
   stDevCP1     = (string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_1+"d";
   stDevCM1     =(string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_1+"d";
   stDevCP2     = (string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_2+"d";
   stDevCM2     = (string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_2+"d";
   stDevCP3     =(string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_3+"d";
   stDevCM3     = (string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_3+"d";
   double LR_line = NormalizeDouble(ObjectGetValueByShift(LR_trendline, index),Digits);
   //double LR_line2 = NormalizeDouble(ObjectGetValueByShift(LR_trendline, index),Digits);
   double stDev_Positive1 = NormalizeDouble(ObjectGetValueByShift(stDevCP1, index),Digits);
   double stDev_Negativ1 = NormalizeDouble(ObjectGetValueByShift(stDevCM1, index),Digits);
   double stDev_Positive2 = NormalizeDouble(ObjectGetValueByShift(stDevCP2, index),Digits);
   double stDev_Negativ2 = NormalizeDouble(ObjectGetValueByShift(stDevCM2, index),Digits);
   double stDev_Positive3 = NormalizeDouble(ObjectGetValueByShift(stDevCP3, index),Digits);
   double stDev_Negativ3 = NormalizeDouble(ObjectGetValueByShift(stDevCM3, index),Digits);
   switch (mode)
   {
      case 0:
         ilr = LR_line;
         break;
      case 1:
         ilr = stDev_Positive1;
         break;
      case -1:
         ilr = stDev_Negativ1;
         break;
      case 2:
         ilr = stDev_Positive2;
         break;
      case -2:
         ilr = stDev_Negativ2;
         break;
      case 3:
         ilr = stDev_Positive3;
         break;
      case -3:
         ilr = stDev_Negativ3;
         break; 
   }
   return ilr;
   
}

double Indicators::iLR2(int index,int mode)
{
   double ilr=0.0;
   switch (mode)
   {
      case 0:{//Linear Regression Line
         string a = (string)_LR_period+"m "+(string)_LR_length+" TL";         
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case 1:{//STD Channel1 Positive
         string a = (string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_1+"d";;
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case -1:{//STD Channel1 Negative
         string a = (string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_1+"d";
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case 2:{//STD Channel2 Positive
         string a =(string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_2+"d";
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case -2:{//STD Channel2 Negative
         string a = (string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_2+"d";
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case 3:{//STD Channel3 Positive
         string a = (string)_LR_period+"m "+(string)_LR_length+" +"+(string)_std_Channel_3+"d";
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
      case -3:{//STD Channel3 Negative
         string a =(string)_LR_period+"m "+(string)_LR_length+" -"+(string)_std_Channel_3+"d";
         ilr = NormalizeDouble(ObjectGetValueByShift(a, index),Digits);
         break;}
   }
   return ilr;
   
}
double Indicators :: iPR(string y,string x,int period, int index, int mode)
{
   string Y              = "EURUSD";
   string X              = "GBPUSD";
   int    SignalMethod   = MODE_SMA;
   int    SignalSMA      = 20;
   int    SignalSMA2     = 100;
   int    BandsPeriod    = 20;
   int    BandsDeviation = 2;
   string path = "price_ratio_0.0.3.EX4";
   /*
   double bb_up = iCustom(NULL,0,path,Y,X,SignalMethod,SignalSMA,SignalSMA2,BandsPeriod,BandsDeviation,4,1);
   double bb_down= iCustom(NULL,0,path,Y,X,SignalMethod,SignalSMA,SignalSMA2,BandsPeriod,BandsDeviation,3,1);
   double bb_mid= iCustom(NULL,0,path,Y,X,SignalMethod,SignalSMA,SignalSMA2,BandsPeriod,BandsDeviation,1,1);
   double pr= iCustom(NULL,0,path,Y,X,SignalMethod,SignalSMA,SignalSMA2,BandsPeriod,BandsDeviation,0,1);*/
   return iCustom(y,0,path,y,x,SignalMethod,SignalSMA,SignalSMA2,period,BandsDeviation,mode,index);
}
double Indicators :: iADR(int mode, string symbol="")
{
   double ilr=0.0;
   int index =0;
   string adr_high, adr_low,wkly_mid_low, wkly_mid_high, wkly_high, wkly_low, wkly_high1,wkly_low1,wkly_high2,wkly_low2,wkly_high3,wkly_low3;switch (mode)
   {
      case 15:  
         adr_high = "TextPlace_ADRHighLine";       
         ilr = NormalizeDouble(ObjectGetValueByShift(adr_high, index),Digits);
         Print(" adr_high[",ilr,"]");
         break;
      case -15:
         adr_low  = "TextPlace_ADRLowLine";
         ilr =NormalizeDouble(ObjectGetValueByShift(adr_low, index),Digits);
         Print("adr_low[",ilr,"]");
         break;
      case 1:
         wkly_mid_high = "TextPlace_WklyMidHigh";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_mid_high, index),Digits);
         Print("wkly_mid_high[",ilr,"]");
         break;
      case -1:
         wkly_mid_low  = "TextPlace_WklyMidLow";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_mid_low, index),Digits);
         Print("wkly_mid_low[",ilr,"]");
         break;
      case 2:
         wkly_high     = "TextPlace_WklyHigh";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_high, index),Digits);
         Print("wkly_high[",ilr,"]");
         break;
      case -2:
         wkly_low      = "TextPlace_WklyLow";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_low, index),Digits);
         Print("wkly_low[",ilr,"]");
         break;
      case 3:
         wkly_high1    = "TextPlace_WklyExtHigh_1";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_high1, index),Digits);
         Print("wkly_high1[",ilr,"]");
         break;
      case -3:
         wkly_low1     = "TextPlace_WklyExtLow_1";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_low1, index),Digits);
         Print("wkly_low1[",ilr,"]");
         break;
      case 4:
         wkly_high2    = "TextPlace_WklyExtHigh_2";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_high2, index),Digits);
         Print("wkly_high2[",ilr,"]");
         break;
      case -4:
         wkly_low2     = "TextPlace_WklyExtLow_2";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_low2, index),Digits);
         Print("wkly_low2[",ilr,"]");
         break;
      case 5:
         wkly_high3    = "TextPlace_WklyExtHigh_3";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_high3, index),Digits);
         Print("wkly_high3[",ilr,"]");
         break;
      case -5:
         wkly_low3     = "TextPlace_WklyExtLow_3";
         ilr = NormalizeDouble(ObjectGetValueByShift(wkly_low3, index),Digits);
         Print("wkly_low3[",ilr,"]");
         break;   
           
   }
   return ilr;

}