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
            double          iBB(int index, int mode);
            double          iLR(int index, int mode);
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