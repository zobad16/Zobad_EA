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
            double          iPR(string y, string x,int index, int mode);
            double          iPR2(int index, int mode);
            Indicators();
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
double Indicators :: iPR(string y,string x, int index, int mode)
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
   return iCustom(NULL,0,path,y,x,SignalMethod,SignalSMA,SignalSMA2,BandsPeriod,BandsDeviation,mode,index);
}