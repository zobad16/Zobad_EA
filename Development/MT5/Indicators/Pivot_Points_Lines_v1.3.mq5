//+------------------------------------------------------------------+
//|                                      Pivot_Points_Lines_v1.3.mq4 |
//|                                         Copyright 2021, NickBixy |
//|             https://www.forexfactory.com/showthread.php?t=904734 |
//+------------------------------------------------------------------+
#property copyright "Copyright 2021, NickBixy"
#property link      "https://www.forexfactory.com/showthread.php?t=904734"
//#property version   "1.3"
#property strict
#property indicator_chart_window
//--- declaration of constants
#define OP_BUY 0           //Buy 
#define OP_SELL 1          //Sell
#define OP_BUYLIMIT 2      //BUY LIMIT pending order 
#define OP_SELLLIMIT 3     //SELL LIMIT pending order  
#define OP_BUYSTOP 4       //BUY STOP pending order  
#define OP_SELLSTOP 5      //SELL STOP pending order  
//---
#define OBJPROP_TIME1 300
#define OBJPROP_PRICE1 301
#define OBJPROP_TIME2 302
#define OBJPROP_PRICE2 303
#define OBJPROP_TIME3 304
#define OBJPROP_PRICE3 305
//---
#define OBJPROP_RAY 310
#define OBJPROP_FIBOLEVELS 200
//---
#define OBJPROP_FIRSTLEVEL1 211
#define OBJPROP_FIRSTLEVEL2 212
#define OBJPROP_FIRSTLEVEL3 213
#define OBJPROP_FIRSTLEVEL4 214
#define OBJPROP_FIRSTLEVEL5 215
#define OBJPROP_FIRSTLEVEL6 216
#define OBJPROP_FIRSTLEVEL7 217
#define OBJPROP_FIRSTLEVEL8 218
#define OBJPROP_FIRSTLEVEL9 219
#define OBJPROP_FIRSTLEVEL10 220
#define OBJPROP_FIRSTLEVEL11 221
#define OBJPROP_FIRSTLEVEL12 222
#define OBJPROP_FIRSTLEVEL13 223
#define OBJPROP_FIRSTLEVEL14 224
#define OBJPROP_FIRSTLEVEL15 225
#define OBJPROP_FIRSTLEVEL16 226
#define OBJPROP_FIRSTLEVEL17 227
#define OBJPROP_FIRSTLEVEL18 228
#define OBJPROP_FIRSTLEVEL19 229
#define OBJPROP_FIRSTLEVEL20 230
#define OBJPROP_FIRSTLEVEL21 231
#define OBJPROP_FIRSTLEVEL22 232
#define OBJPROP_FIRSTLEVEL23 233
#define OBJPROP_FIRSTLEVEL24 234
#define OBJPROP_FIRSTLEVEL25 235
#define OBJPROP_FIRSTLEVEL26 236
#define OBJPROP_FIRSTLEVEL27 237
#define OBJPROP_FIRSTLEVEL28 238
#define OBJPROP_FIRSTLEVEL29 239
#define OBJPROP_FIRSTLEVEL30 240
#define OBJPROP_FIRSTLEVEL31 241
//---
#define MODE_OPEN 0
#define MODE_CLOSE 3
#define MODE_VOLUME 4
#define MODE_REAL_VOLUME 5
#define MODE_TRADES 0
#define MODE_HISTORY 1
#define SELECT_BY_POS 0
#define SELECT_BY_TICKET 1
//---
#define DOUBLE_VALUE 0
#define FLOAT_VALUE 1
#define LONG_VALUE INT_VALUE
//---
#define CHART_BAR 0
#define CHART_CANDLE 1
//---
#define MODE_ASCEND 0
#define MODE_DESCEND 1
//---
#define MODE_LOW 1
#define MODE_HIGH 2
#define MODE_TIME 5
#define MODE_BID 9
#define MODE_ASK 10
#define MODE_POINT 11
#define MODE_DIGITS 12
#define MODE_SPREAD 13
#define MODE_STOPLEVEL 14
#define MODE_LOTSIZE 15
#define MODE_TICKVALUE 16
#define MODE_TICKSIZE 17
#define MODE_SWAPLONG 18
#define MODE_SWAPSHORT 19
#define MODE_STARTING 20
#define MODE_EXPIRATION 21
#define MODE_TRADEALLOWED 22
#define MODE_MINLOT 23
#define MODE_LOTSTEP 24
#define MODE_MAXLOT 25
#define MODE_SWAPTYPE 26
#define MODE_PROFITCALCMODE 27
#define MODE_MARGINCALCMODE 28
#define MODE_MARGININIT 29
#define MODE_MARGINMAINTENANCE 30
#define MODE_MARGINHEDGED 31
#define MODE_MARGINREQUIRED 32
#define MODE_FREEZELEVEL 33
//---
#define EMPTY -1
//---
#define CharToStr CharToString
#define DoubleToStr DoubleToString
#define StrToDouble StringToDouble
#define StrToInteger (int)StringToInteger
#define StrToTime StringToTime
#define TimeToStr TimeToString
#define StringGetChar StringGetCharacter
#define StringSetChar StringSetCharacter
enum pivotTypes
  {
   Standard,//Standard(Floor)
   Fibonacci,//Fibonacci
   Camarilla,//Camarilla
   Woodie,//Woodie
   Traditional,//Traditional
   Demark,//Demark
   Classic//Classic
  };
enum yesnoChoiceToggle
  {
   No,
   Yes
  };
enum enabledisableChoiceToggle
  {
   Disable,
   Enable
  };
enum labelLocation1
  {
   Left_1,//Left
   Middle_1,//Middle
   Right_1,//Right
  };
enum labelLocation2
  {
   Follow_Price_2,//Follow Price
   Left_2,//Left
   Middle_2,//Middle
   Right_2,//Right
  };
input string indiLink="https://www.forexfactory.com/showthread.php?t=904734";//Indicator's Support Thread On Forex Factory
input int UniqueID=1;//Unique ID
input int historicalPP=0;//Historical Pivot Points,Set 0 for NONE
input string Header="----------------- Pivot Point Settings------------------------------------------";//----- Pivot Point Settings
input pivotTypes pivotSelection=Standard;//Formula
input ENUM_TIMEFRAMES timeFrame=PERIOD_D1;//TimeFrame
input yesnoChoiceToggle drawFuturePlot=No;//Draw Future Plot?
input yesnoChoiceToggle showPriceLabel=No;//Show Price In Label?
input yesnoChoiceToggle useShortLines=No;//Draw Short Lines For Current Period?
input int ShiftLabel=3;//Label Follow Price Shift -Move Left, +Move Right
input int Line_Length=15;//Length Of Short Line
input string HeaderStandardAdditionalSettings="----------------- Standard(Floor) Additional Settings------------------------------------------";//----- Standard(Floor) Additional Settings
input yesnoChoiceToggle drawFloorMidPP=No;//Show Mid Pivot Points?
input yesnoChoiceToggle floorCPR=Yes;//Show Central Pivot Range?
input string Header2="----------------- Line/Label Customize Settings------------------------------------------";//----- Line/Label Customize Settings
input string customMSG="";//MSG Before Pivot Point Name
input ENUM_LINE_STYLE lineStyle=STYLE_SOLID;//Line Style
input int lineWidth=1;//Line Width
input string Font="Arial";//Label Font
input int labelFontSize=8;//Label Text Size
input labelLocation1 historicalLabelLocation=Left_1;//Historical Label Location?
input labelLocation2 currentLabelLocation=Follow_Price_2;//Current Label Location?
input labelLocation1 futureLabelLocation=Right_1;//Future Label Location?
input yesnoChoiceToggle hideHistoricalLabels=No;//Hide Historical Pivot Points Labels?
input yesnoChoiceToggle hideCurrentLabels=No;//Hide Current Pivot Points Labels?
input yesnoChoiceToggle hideFutureLabels=No;//Hide Future Pivot Points Labels?
input yesnoChoiceToggle useSameColorLabelChoice=Yes;//Label Use Same Color?
input color useSameColorLabelColor=clrWhite;//Label Color For Label Use Same Color
input color resistantColor=clrRed;//Resistant Line/Label Color
input color pivotColor=clrYellow;//Pivot Line/Label Color
input color supportColor=clrLime;//Support Line/Label Color
input color midColor=clrGreen;//Standard(Floor)Mid PP Line/Label Color
input color CPRColor=clrViolet;//Standard(Floor)CPR PP Line/Label Color
string indiName="PPL"+(string)UniqueID+" "+EnumToString(pivotSelection)+" "+EnumToString(timeFrame)+" ";
string camarillaPivotNames[]=
  {
   "PP",
   "L1",
   "L2",
   "L3",
   "L4",
   "H1",
   "H2",
   "H3",
   "H4",
   "H5",
   "L5",
  };
double camarillaValueArray[11];
bool showCamarilla[11];
string standardPivotNames[]=
  {
   "PP",
   "S1",
   "S2",
   "S3",
   "R1",
   "R2",
   "R3",
   "R4",
   "S4",
   "MR4",
   "MR3",
   "MR2",
   "MR1",
   "MS1",
   "MS2",
   "MS3",
   "MS4",
  };
double standardValueArray[17];
bool showStandard[17];
string traditionalPivotNames[]=
  {
   "PP",
   "S1",
   "S2",
   "S3",
   "R1",
   "R2",
   "R3",
   "R4",
   "S4",
   "S5",
   "R5",
  };
double traditionalValueArray[11];
bool showTraditional[11];
string demarkPivotNames[]=
  {
   "PP",
   "R1",
   "S1"
  };
double demarkValueArray[3];
bool showDemark[3];
string woodiePivotNames[]=
  {
   "PP",
   "S1",
   "S2",
   "R1",
   "R2",
   "S3",
   "S4",
   "R3",
   "R4",
  };
double woodieValueArray[9];
bool showWoodie[9];
string fibonacciPivotNames[]=
  {
   "PP",
   "R38",
   "R61",
   "R78",
   "R100",
   "R138",
   "R161",
   "R200",
   "S38",
   "S61",
   "S78",
   "S100",
   "S138",
   "S161",
   "S200",
  };
double fibonacciValueArray[15];
bool showFibonacci[15];
string classicPivotNames[]=
  {
   "PP",
   "S1",
   "S2",
   "S3",
   "S4",
   "R1",
   "R2",
   "R3",
   "R4"
  };
//+------------------------------------------------------------------+
double classicValueArray[9];
bool showClassic[9];
string floorCPRPivotNames[]=
  {
   "BC",
   "TC"
  };
double floorCPRValueArray[2];
bool showFloorCPR[2];
input string showHeader="-----------------Enable/Disable Specified Pivot Point----------------------------------------------";//----- Enable/Disable Specified Pivot Point
input string showStandardPivotHeader="Standard(Floor) Pivot Point--------------------------------------------";//----- Standard(Floor) Pivot Point Settings
input enabledisableChoiceToggle showStandardPivotR4=Enable;//Standard Pivot R4
input enabledisableChoiceToggle showStandardPivotR3=Enable;//Standard Pivot R3
input enabledisableChoiceToggle showStandardPivotR2=Enable;//Standard Pivot R2
input enabledisableChoiceToggle showStandardPivotR1=Enable;//Standard Pivot R1
input enabledisableChoiceToggle showStandardPivotPP=Enable;//Standard Pivot PP
input enabledisableChoiceToggle showStandardPivotS1=Enable;//Standard Pivot S1
input enabledisableChoiceToggle showStandardPivotS2=Enable;//Standard Pivot S2
input enabledisableChoiceToggle showStandardPivotS3=Enable;//Standard Pivot S3
input enabledisableChoiceToggle showStandardPivotS4=Enable;//Standard Pivot S4
input string StandardMidPivotHeader="-----------------Standard(Floor) Mid Pivot Points";//----- Standard(Floor) Mid PP
input enabledisableChoiceToggle showStandardPivotMR4=Enable;//Standard Pivot MR4
input enabledisableChoiceToggle showStandardPivotMR3=Enable;//Standard Pivot MR3
input enabledisableChoiceToggle showStandardPivotMR2=Enable;//Standard Pivot MR2
input enabledisableChoiceToggle showStandardPivotMR1=Enable;//Standard Pivot MR1
input enabledisableChoiceToggle showStandardPivotMS1=Enable;//Standard Pivot MS1
input enabledisableChoiceToggle showStandardPivotMS2=Enable;//Standard Pivot MS2
input enabledisableChoiceToggle showStandardPivotMS3=Enable;//Standard Pivot MS3
input enabledisableChoiceToggle showStandardPivotMS4=Enable;//Standard Pivot MS4
input string showCPRPivotHeader="Standard(Floor) CPR Pivot Point--------------------------------------------";//----- Standard(Floor) CPR Pivot Point
input enabledisableChoiceToggle showCPRTC=Enable;//Standard CPR Pivot TC
input enabledisableChoiceToggle showCPRBC=Enable;//Standard CPR Pivot BC
input string showFibonacciPivotHeader="Fibonacci Pivot Point--------------------------------------------";//----- Fibonacci Pivot Point Settings
input enabledisableChoiceToggle showFibonacciPivotR200=Enable;//Fibonacci Pivot R200
input enabledisableChoiceToggle showFibonacciPivotR161=Enable;//Fibonacci Pivot R161
input enabledisableChoiceToggle showFibonacciPivotR138=Enable;//Fibonacci Pivot R138
input enabledisableChoiceToggle showFibonacciPivotR100=Enable;//Fibonacci Pivot R100
input enabledisableChoiceToggle showFibonacciPivotR78=Enable;//Fibonacci Pivot R78
input enabledisableChoiceToggle showFibonacciPivotR61=Enable;//Fibonacci Pivot R61
input enabledisableChoiceToggle showFibonacciPivotR38=Enable;//Fibonacci Pivot R38
input enabledisableChoiceToggle showFibonacciPivotPP=Enable;//Fibonacci Pivot PP
input enabledisableChoiceToggle showFibonacciPivotS38=Enable;//Fibonacci Pivot S38
input enabledisableChoiceToggle showFibonacciPivotS61=Enable;//Fibonacci Pivot S61
input enabledisableChoiceToggle showFibonacciPivotS78=Enable;//Fibonacci Pivot S78
input enabledisableChoiceToggle showFibonacciPivotS100=Enable;//Fibonacci Pivot S100
input enabledisableChoiceToggle showFibonacciPivotS138=Enable;//Fibonacci Pivot S138
input enabledisableChoiceToggle showFibonacciPivotS161=Enable;//Fibonacci Pivot S161
input enabledisableChoiceToggle showFibonacciPivotS200=Enable;//Fibonacci Pivot S200
input string showWoodiePivotHeader="Woodie Pivot Point--------------------------------------------";//----- Woodie Pivot Point Settings
input enabledisableChoiceToggle showWoodieR4=Enable;//Woodie Pivot R4
input enabledisableChoiceToggle showWoodieR3=Enable;//Woodie Pivot R3
input enabledisableChoiceToggle showWoodieR2=Enable;//Woodie Pivot R2
input enabledisableChoiceToggle showWoodieR1=Enable;//Woodie Pivot R1
input enabledisableChoiceToggle showWoodiePP=Enable;//Woodie Pivot PP
input enabledisableChoiceToggle showWoodieS1=Enable;//Woodie Pivot S1
input enabledisableChoiceToggle showWoodieS2=Enable;//Woodie Pivot S2
input enabledisableChoiceToggle showWoodieS3=Enable;//Woodie Pivot S3
input enabledisableChoiceToggle showWoodieS4=Enable;//Woodie Pivot S4
input string showCamarillaPivotHeader="Camarilla Pivot Point--------------------------------------------";//----- Camarilla Pivot Point Settings
input enabledisableChoiceToggle showCamarillaH5=Enable;//Camarilla Pivot H5
input enabledisableChoiceToggle showCamarillaH4=Enable;//Camarilla Pivot H4
input enabledisableChoiceToggle showCamarillaH3=Enable;//Camarilla Pivot H3
input enabledisableChoiceToggle showCamarillaH2=Enable;//Camarilla Pivot H2
input enabledisableChoiceToggle showCamarillaH1=Enable;//Camarilla Pivot H1
input enabledisableChoiceToggle showCamarillaPP=Disable;//Camarilla Pivot PP
input enabledisableChoiceToggle showCamarillaL1=Enable;//Camarilla Pivot L1
input enabledisableChoiceToggle showCamarillaL2=Enable;//Camarilla Pivot L2
input enabledisableChoiceToggle showCamarillaL3=Enable;//Camarilla Pivot L3
input enabledisableChoiceToggle showCamarillaL4=Enable;//Camarilla Pivot L4
input enabledisableChoiceToggle showCamarillaL5=Enable;//Camarilla Pivot L5
input string showTraditionalPivotHeader="Traditional Pivot Point--------------------------------------------";//----- Traditional Pivot Point Settings
input enabledisableChoiceToggle showTraditionalR5=Enable;//Traditional Pivot R5
input enabledisableChoiceToggle showTraditionalR4=Enable;//Traditional Pivot R4
input enabledisableChoiceToggle showTraditionalR3=Enable;//Traditional Pivot R3
input enabledisableChoiceToggle showTraditionalR2=Enable;//Traditional Pivot R2
input enabledisableChoiceToggle showTraditionalR1=Enable;//Traditional Pivot R1
input enabledisableChoiceToggle showTraditionalPP=Enable;//Traditional Pivot PP
input enabledisableChoiceToggle showTraditionalS1=Enable;//Traditional Pivot S1
input enabledisableChoiceToggle showTraditionalS2=Enable;//Traditional Pivot S2
input enabledisableChoiceToggle showTraditionalS3=Enable;//Traditional Pivot S3
input enabledisableChoiceToggle showTraditionalS4=Enable;//Traditional Pivot S4
input enabledisableChoiceToggle showTraditionalS5=Enable;//Traditional Pivot S5
input string showDemarkPivotHeader="Demark Pivot Point--------------------------------------------";//----- Demark Pivot Point Settings
input enabledisableChoiceToggle showDemarkR1=Enable;//Demark Pivot R1
input enabledisableChoiceToggle showDemarkPP=Enable;//Demark Pivot PP
input enabledisableChoiceToggle showDemarkS1=Enable;//Demark Pivot S1
input string showClassicPivotHeader="Classic Pivot Point--------------------------------------------";//----- Classic Pivot Point Settings
input enabledisableChoiceToggle showClassicR4=Enable;//Classic Pivot R4
input enabledisableChoiceToggle showClassicR3=Enable;//Classic Pivot R3
input enabledisableChoiceToggle showClassicR2=Enable;//Classic Pivot R2
input enabledisableChoiceToggle showClassicR1=Enable;//Classic Pivot R1
input enabledisableChoiceToggle showClassicPP=Enable;//Classic Pivot PP
input enabledisableChoiceToggle showClassicS1=Enable;//Classic Pivot S1
input enabledisableChoiceToggle showClassicS2=Enable;//Classic Pivot S2
input enabledisableChoiceToggle showClassicS3=Enable;//Classic Pivot S3
input enabledisableChoiceToggle showClassicS4=Enable;//Classic Pivot S4
//+------------------------------------------------------------------+
int OnInit()
  {
   EnableDisablePivotPoint();
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
void  OnDeinit(const int  reason)
  {
   if(reason==1 || reason==2 || reason==3 || reason==4 || reason==5 || reason==7 || reason==9)
     {
      ObjectsDeleteAll(0,"PPL"+(string)UniqueID,0,OBJ_TREND) ;
      ObjectsDeleteAll(0,"PPL"+(string)UniqueID,0,OBJ_TEXT) ;
     }
   /*
   REASON_PROGRAM
   0
   Expert Advisor terminated its operation by calling the ExpertRemove() function

   REASON_REMOVE
   1
   Program has been deleted from the chart

   REASON_RECOMPILE
   2
   Program has been recompiled

   REASON_CHARTCHANGE
   3
   Symbol or chart period has been changed

   REASON_CHARTCLOSE
   4
   Chart has been closed

   REASON_PARAMETERS
   5
   Input parameters have been changed by a user

   REASON_ACCOUNT
   6
   Another account has been activated or reconnection to the trade server has occurred due to changes in the account settings

   REASON_TEMPLATE
   7
   A new template has been applied

   REASON_INITFAILED
   8
   This value means that OnInit() handler has returned a nonzero value

   REASON_CLOSE
   9
   Terminal has been closed
   */
  }
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
   if(pivotSelection==Camarilla)
     {
      camarillaPivotPoint(camarillaValueArray,0,false);
      for(int i=0; i<ArraySize(camarillaValueArray); i++)
        {
         if(showCamarilla[i])
           {
            DrawPivotLines(camarillaValueArray[i],camarillaPivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            camarillaPivotPoint(camarillaValueArray,j,false);
            for(int k=0; k<ArraySize(camarillaValueArray); k++)
              {
               if(showCamarilla[k])
                 {
                  DrawHistoricalLines(camarillaValueArray[k],camarillaPivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         camarillaPivotPoint(camarillaValueArray,0,true);
         for(int k=0; k<ArraySize(camarillaValueArray); k++)
           {
            if(showCamarilla[k])
              {
               DrawFuturePlot(camarillaValueArray[k],camarillaPivotNames[k]);
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Standard)
     {
      if(drawFloorMidPP==Yes)
        {
         standardPivotPoint(standardValueArray,0,false);
         for(int i=0; i<17; i++)
           {
            if(showStandard[i])
              {
               DrawPivotLines(standardValueArray[i],standardPivotNames[i]);
              }
           }
         if(floorCPR==Yes)//current
           {
            standardPivotPointCPR(floorCPRValueArray,0,false);
            for(int k=0; k<ArraySize(floorCPRValueArray); k++)
              {
               if(showFloorCPR[k])
                 {
                  DrawCPRPivotLines(floorCPRValueArray[k],floorCPRPivotNames[k]);
                 }
              }
           }
         int numHistoricalPP=historicalPP;
         if(numHistoricalPP>0)
           {
            for(int j=1; j<=numHistoricalPP; j++)
              {
               if(timeFrame==PERIOD_D1)
                 {
                  if(foundWeekend(j))
                    {
                     numHistoricalPP++;
                     continue;
                    }
                 }
               standardPivotPoint(standardValueArray,j,false);
               for(int k=0; k<17; k++)
                 {
                  if(showStandard[k])
                    {
                     DrawHistoricalLines(standardValueArray[k],standardPivotNames[k],j);
                    }
                 }
               if(floorCPR==Yes)//historical
                 {
                  standardPivotPointCPR(floorCPRValueArray,j,false);
                  for(int k=0; k<ArraySize(floorCPRValueArray); k++)
                    {
                     if(showFloorCPR[k])
                       {
                        DrawCPRHistoricalLines(floorCPRValueArray[k],floorCPRPivotNames[k],j);
                       }
                    }
                 }
              }
           }
         if(drawFuturePlot==Yes)
           {
            standardPivotPoint(standardValueArray,0,true);
            for(int k=0; k<17; k++)
              {
               if(showStandard[k])
                 {
                  DrawFuturePlot(standardValueArray[k],standardPivotNames[k]);
                 }
              }
            if(floorCPR==Yes)
              {
               standardPivotPointCPR(floorCPRValueArray,0,true);
               for(int k=0; k<ArraySize(floorCPRValueArray); k++)
                 {
                  if(showFloorCPR[k])
                    {
                     DrawCPRFuturePlot(floorCPRValueArray[k],floorCPRPivotNames[k]);
                    }
                 }
              }
           }
        }
      else
        {
         standardPivotPoint(standardValueArray,0,false);
         for(int i=0; i<9; i++)
           {
            if(showStandard[i])
              {
               DrawPivotLines(standardValueArray[i],standardPivotNames[i]);
              }
            if(floorCPR==Yes)//current
              {
               standardPivotPointCPR(floorCPRValueArray,0,false);
               for(int k=0; k<ArraySize(floorCPRValueArray); k++)
                 {
                  if(showFloorCPR[k])
                    {
                     DrawCPRPivotLines(floorCPRValueArray[k],floorCPRPivotNames[k]);
                    }
                 }
              }
           }
         int numHistoricalPP=historicalPP;
         if(numHistoricalPP>0)
           {
            for(int j=1; j<=numHistoricalPP; j++)
              {
               if(timeFrame==PERIOD_D1)
                 {
                  if(foundWeekend(j))
                    {
                     numHistoricalPP++;
                     continue;
                    }
                 }
               standardPivotPoint(standardValueArray,j,false);
               for(int k=0; k<9; k++)
                 {
                  if(showStandard[k])
                    {
                     DrawHistoricalLines(standardValueArray[k],standardPivotNames[k],j);
                    }
                 }
               if(floorCPR==Yes)//historical
                 {
                  standardPivotPointCPR(floorCPRValueArray,j,false);
                  for(int k=0; k<ArraySize(floorCPRValueArray); k++)
                    {
                     if(showFloorCPR[k])
                       {
                        DrawCPRHistoricalLines(floorCPRValueArray[k],floorCPRPivotNames[k],j);
                       }
                    }
                 }
              }
           }
         if(drawFuturePlot==Yes)
           {
            standardPivotPoint(standardValueArray,0,true);
            for(int k=0; k<9; k++)
              {
               if(showStandard[k])
                 {
                  DrawFuturePlot(standardValueArray[k],standardPivotNames[k]);
                 }
              }
            if(floorCPR==Yes)//future
              {
               standardPivotPointCPR(floorCPRValueArray,0,true);
               for(int k=0; k<ArraySize(floorCPRValueArray); k++)
                 {
                  if(showFloorCPR[k])
                    {
                     DrawCPRFuturePlot(floorCPRValueArray[k],floorCPRPivotNames[k]);
                    }
                 }
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Fibonacci)
     {
      fibonacciPivotPoint(fibonacciValueArray,0,false);
      for(int i=0; i<ArraySize(fibonacciValueArray); i++)
        {
         if(showFibonacci[i])
           {
            DrawPivotLines(fibonacciValueArray[i],fibonacciPivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            fibonacciPivotPoint(fibonacciValueArray,j,false);
            for(int k=0; k<ArraySize(fibonacciValueArray); k++)
              {
               if(showFibonacci[k])
                 {
                  DrawHistoricalLines(fibonacciValueArray[k],fibonacciPivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         fibonacciPivotPoint(fibonacciValueArray,0,true);
         for(int k=0; k<ArraySize(fibonacciValueArray); k++)
           {
            if(showFibonacci[k])
              {
               DrawFuturePlot(fibonacciValueArray[k],fibonacciPivotNames[k]);
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Woodie)
     {
      woodiePivotPoint(woodieValueArray,0,false);
      for(int i=0; i<ArraySize(woodieValueArray); i++)
        {
         if(showWoodie[i])
           {
            DrawPivotLines(woodieValueArray[i],woodiePivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            woodiePivotPoint(woodieValueArray,j,false);
            for(int k=0; k<ArraySize(woodieValueArray); k++)
              {
               if(showWoodie[k])
                 {
                  DrawHistoricalLines(woodieValueArray[k],woodiePivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         woodiePivotPoint(woodieValueArray,0,true);
         for(int k=0; k<ArraySize(woodieValueArray); k++)
           {
            if(showWoodie[k])
              {
               DrawFuturePlot(woodieValueArray[k],woodiePivotNames[k]);
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Traditional)
     {
      traditionalPivotPoint(traditionalValueArray,0,false);
      for(int i=0; i<ArraySize(traditionalValueArray); i++)
        {
         if(showTraditional[i])
           {
            DrawPivotLines(traditionalValueArray[i],traditionalPivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            traditionalPivotPoint(traditionalValueArray,j,false);
            for(int k=0; k<ArraySize(traditionalValueArray); k++)
              {
               if(showTraditional[k])
                 {
                  DrawHistoricalLines(traditionalValueArray[k],traditionalPivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         traditionalPivotPoint(traditionalValueArray,0,true);
         for(int k=0; k<ArraySize(traditionalValueArray); k++)
           {
            if(showTraditional[k])
              {
               DrawFuturePlot(traditionalValueArray[k],traditionalPivotNames[k]);
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Demark)
     {
      demarkPivotPoint(demarkValueArray,0,false);
      for(int i=0; i<ArraySize(demarkValueArray); i++)
        {
         if(showDemark[i])
           {
            DrawPivotLines(demarkValueArray[i],demarkPivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            demarkPivotPoint(demarkValueArray,j,false);
            for(int k=0; k<ArraySize(demarkValueArray); k++)
              {
               if(showDemark[k])
                 {
                  DrawHistoricalLines(demarkValueArray[k],demarkPivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         demarkPivotPoint(demarkValueArray,0,true);
         for(int k=0; k<ArraySize(demarkValueArray); k++)
           {
            if(showDemark[k])
              {
               DrawFuturePlot(demarkValueArray[k],demarkPivotNames[k]);
              }
           }
        }
     }
//+------------------------------------------------------------------+
   if(pivotSelection==Classic)
     {
      classicPivotPoint(classicValueArray,0,false);
      for(int i=0; i<ArraySize(classicValueArray); i++)
        {
         if(showClassic[i])
           {
            DrawPivotLines(classicValueArray[i],classicPivotNames[i]);
           }
        }
      int numHistoricalPP=historicalPP;
      if(numHistoricalPP>0)
        {
         for(int j=1; j<=numHistoricalPP; j++)
           {
            if(timeFrame==PERIOD_D1)
              {
               if(foundWeekend(j))
                 {
                  numHistoricalPP++;
                  continue;
                 }
              }
            classicPivotPoint(classicValueArray,j,false);
            for(int k=0; k<ArraySize(classicValueArray); k++)
              {
               if(showClassic[k])
                 {
                  DrawHistoricalLines(classicValueArray[k],classicPivotNames[k],j);
                 }
              }
           }
        }
      if(drawFuturePlot==Yes)
        {
         classicPivotPoint(classicValueArray,0,true);
         for(int k=0; k<ArraySize(classicValueArray); k++)
           {
            if(showClassic[k])
              {
               DrawFuturePlot(classicValueArray[k],classicPivotNames[k]);
              }
           }
        }
     }
   return 0;
  }
//+------------------------------------------------------------------+
void DrawPivotLines(double value,string pivotName)
  {
   int timeframeValueLabel=0;
   int timeframeValueLine=0;
   if(currentLabelLocation==Follow_Price_2 || useShortLines==Yes)
     {
      switch(Period())
        {
         // Start of the 'switch' body
         case PERIOD_M1 :
            timeframeValueLabel=1;
            break;// Variations..
         case PERIOD_M2 :
            timeframeValueLabel=2;
            break;// Variations..
         case PERIOD_M3 :
            timeframeValueLabel=3;
            break;// Variations..
         case PERIOD_M4 :
            timeframeValueLabel=4;
            break;// Variations..
         case PERIOD_M5 :
            timeframeValueLabel=5;
            break;// Variations..
         case PERIOD_M6 :
            timeframeValueLabel=6;
            break;// Variations..
         case PERIOD_M10 :
            timeframeValueLabel=10;
            break;// Variations..
         case PERIOD_M12 :
            timeframeValueLabel=12;
            break;// Variations..
         case PERIOD_M15 :
            timeframeValueLabel=15;
            break;// Variations..
         case PERIOD_M20 :
            timeframeValueLabel=20;
            break;// Variations..
         case PERIOD_M30 :
            timeframeValueLabel=30;
            break;// Variations..
         case PERIOD_H1 :
            timeframeValueLabel=60;
            break;// Variations..
         case PERIOD_H2 :
            timeframeValueLabel=240;
            break;// Variations..
         case PERIOD_H3 :
            timeframeValueLabel=180;
            break;// Variations..
         case PERIOD_H4 :
            timeframeValueLabel=240;
            break;// Variations..
         case PERIOD_H6 :
            timeframeValueLabel=360;
            break;// Variations..
         case PERIOD_H8 :
            timeframeValueLabel=480;
            break;// Variations..
         case PERIOD_H12 :
            timeframeValueLabel=720;
            break;// Variations..
         case PERIOD_D1 :
            timeframeValueLabel=1440;
            break;// Variations..
         case PERIOD_W1 :
            timeframeValueLabel=10080;
            break;// Variations..
         case PERIOD_MN1 :
            timeframeValueLabel=43200;
            break;// Variations..
        }                                 // Header of the 'switch'
     }
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValueLine=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValueLine=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValueLine=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValueLine=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValueLine=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValueLine=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValueLine=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValueLine=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValueLine=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValueLine=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValueLine=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValueLine=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValueLine=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValueLine=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValueLine=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValueLine=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValueLine=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValueLine=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValueLine=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValueLine=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValueLine=43200;
         break;// Variations..
     }
   datetime Time[];
   int count=2;   // number of elements to copy
   ArraySetAsSeries(Time,true);
   CopyTime(_Symbol,_Period,0,count,Time);
   color lineLabelColor=clrNONE;
   string message="";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('R'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }
   if('P'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=pivotColor;
     }
   if('S'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }
   if('M'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=midColor;
     }
   if('H'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }
   if('L'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }
   string nameLine=  indiName+pivotName+" Line";
   string nameLabel= indiName+pivotName+" Label";
   if(ObjectFindMQL4(nameLine) != 0)
     {
      if(useShortLines==Yes)
        {
         ObjectCreate(0,nameLine,OBJ_TREND,0,Time[1]+timeframeValueLabel*60, value, Time[0]+timeframeValueLabel*60*Line_Length, value);
        }
      else
        {
         ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,0),value,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
        }
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      if(useShortLines==Yes)
        {
         ObjectMoveMQL4(nameLine, 0, Time[1]+timeframeValueLabel*60, value);
         ObjectMoveMQL4(nameLine, 1, Time[0]+timeframeValueLabel*60*Line_Length, value);
        }
      else
        {
         ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,0),value);
         ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
        }
     }
   if(hideCurrentLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(useShortLines==Yes)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
            if(useSameColorLabelChoice==Yes)
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
              }
            else
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
              }
            ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
           }
         else
           {
            if(currentLabelLocation==Follow_Price_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
              }
            if(currentLabelLocation==Left_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0),value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
              }
            if(currentLabelLocation==Middle_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValueLine*30,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
              }
            if(currentLabelLocation==Right_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
              }
            if(useSameColorLabelChoice==Yes)
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
              }
            else
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
              }
            ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
           }
         ChartRedraw(0);
        }
      else
        {
         if(currentLabelLocation==Follow_Price_2)
           {
            ObjectMoveMQL4(nameLabel,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
           }

         if(currentLabelLocation==Left_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0),value);
           }
         if(currentLabelLocation==Middle_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValueLine*30,value);
           }
         if(currentLabelLocation==Right_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
           }
        }
     }
  }
//camarilla formula
void camarillaPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//camrilla pivot point formula
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         shift+=1;
        }
     }
   double camRange= iHigh(NULL,timeFrame,shift)-iLow(NULL,timeFrame,shift);
   double prevHigh=iHigh(NULL,timeFrame,shift);
   double prevLow=iLow(NULL,timeFrame,shift);
   double prevClose=iClose(NULL,timeFrame,shift);
   if(futurePlot)
     {
      prevClose= SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double H5=((prevHigh/prevLow)*prevClose);
   double H4=prevClose+camRange*1.1/2;
   double H3=((1.1/4) * camRange) + prevClose;
   double H2=prevClose+camRange*1.1/6;
   double H1=prevClose+camRange*1.1/12;
   double L1=prevClose-camRange*1.1/12;
   double L2=prevClose-camRange*1.1/6;
   double L3=prevClose-camRange*1.1/4;
   double L4=prevClose-camRange*1.1/2;
   double L5=prevClose-(H5-prevClose);
   double PP = (prevHigh+prevLow+prevClose)/3;
   ppArrayRef[0]=PP;
   ppArrayRef[1]=L1;
   ppArrayRef[2]=L2;
   ppArrayRef[3]=L3;
   ppArrayRef[4]=L4;
   ppArrayRef[5]=H1;
   ppArrayRef[6]=H2;
   ppArrayRef[7]=H3;
   ppArrayRef[8]=H4;
   ppArrayRef[9]=H5;
   ppArrayRef[10]=L5;
  }
//+------------------------------------------------------------------+
//standard pivot point formula
void standardPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//the formula for the standard floor pivot points
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday - skip over
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday - skip over
        {
         shift+=1;
        }
     }
   double prevHigh = iHigh(NULL,timeFrame,shift);
   double prevLow=iLow(NULL,timeFrame,shift);
   double prevClose=iClose(NULL,timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double PP = (prevHigh+prevLow+prevClose)/3;
   double R1 = (PP * 2)-prevLow;
   double S1 = (PP * 2)-prevHigh;
   double R2 = PP + prevHigh - prevLow;
   double S2 = PP - prevHigh + prevLow;
   double R3 = R1 + (prevHigh-prevLow);
   double S3 = prevLow - 2 * (prevHigh-PP);
   double R4 = R3+(R2-R1);
   double S4 = S3-(S1-S2);
   ppArrayRef[0]=PP;
   ppArrayRef[1]=S1;
   ppArrayRef[2]=S2;
   ppArrayRef[3]=S3;
   ppArrayRef[4]=R1;
   ppArrayRef[5]=R2;
   ppArrayRef[6]=R3;
   ppArrayRef[7]=R4;
   ppArrayRef[8]=S4;
   if(drawFloorMidPP==Yes)
     {
      //mid pivots
      ppArrayRef[9]=(R3+R4)/2;
      ppArrayRef[10]=(R2+R3)/2;
      ppArrayRef[11]=(R1+R2)/2;
      ppArrayRef[12]=(PP+R1)/2;
      ppArrayRef[13]=(PP+S1)/2;
      ppArrayRef[14]=(S1+S2)/2;
      ppArrayRef[15]=(S2+S3)/2;
      ppArrayRef[16]=(S3+S4)/2;
     }
  }
//+------------------------------------------------------------------+
void woodiePivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//woodie pivot point formula
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         shift+=1;
        }
     }
   double prevRange= iHigh(NULL,timeFrame,shift)-iLow(NULL,timeFrame,shift);
   double prevHigh = iHigh(NULL,timeFrame,shift);
   double prevLow=iLow(NULL,timeFrame,shift);
   double prevClose = iClose(NULL, timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double todayOpen = iOpen(NULL, timeFrame,shift-1);
   double PP = (prevHigh+prevLow+(todayOpen*2))/4;
   double R1 = (PP * 2)-prevLow;
   double R2 = PP + prevRange;
   double S1 = (PP * 2)-prevHigh;
   double S2 = PP - prevRange;
   double S3 = (prevLow-2*(prevHigh-PP));
   double S4 = (S3-prevRange);
   double R3 = (prevHigh+2*(PP-prevLow));
   double R4 = (R3+prevRange);
   ppArrayRef[0]=PP;
   ppArrayRef[1]=S1;
   ppArrayRef[2]=S2;
   ppArrayRef[3]=R1;
   ppArrayRef[4]=R2;
   ppArrayRef[5]=S3;
   ppArrayRef[6]=S4;
   ppArrayRef[7]=R3;
   ppArrayRef[8]=R4;
  }
//fibonacci formula
void fibonacciPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//fibonacchi pivot point formula
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         shift+=1;
        }
     }
   double prevRange= iHigh(NULL,timeFrame,shift)-iLow(NULL,timeFrame,shift);
   double prevHigh = iHigh(NULL,timeFrame,shift);
   double prevLow=iLow(NULL,timeFrame,shift);
   double prevClose=iClose(NULL,timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double Pivot=(prevHigh+prevLow+prevClose)/3;
   double R38=  Pivot + ((prevRange) * 0.382);
   double R61=  Pivot + ((prevRange) * 0.618);
   double R78=  Pivot + ((prevRange) * 0.786);
   double R100= Pivot + ((prevRange) * 1.000);
   double R138= Pivot + ((prevRange) * 1.382);
   double R161= Pivot + ((prevRange) * 1.618);
   double R200= Pivot + ((prevRange) * 2.000);
   double S38 = Pivot - ((prevRange) * 0.382);
   double S61 = Pivot - ((prevRange) * 0.618);
   double S78 = Pivot -((prevRange)  * 0.786);
   double S100= Pivot - ((prevRange) * 1.000);
   double S138= Pivot - ((prevRange) * 1.382);
   double S161= Pivot - ((prevRange) * 1.618);
   double S200= Pivot - ((prevRange) * 2.000);
   ppArrayRef[0]=Pivot;
   ppArrayRef[1]=R38;
   ppArrayRef[2]=R61;
   ppArrayRef[3]=R78;
   ppArrayRef[4]=R100;
   ppArrayRef[5]=R138;
   ppArrayRef[6]=R161;
   ppArrayRef[7]=R200;
   ppArrayRef[8]=S38;
   ppArrayRef[9]=S61;
   ppArrayRef[10]=S78;
   ppArrayRef[11]=S100;
   ppArrayRef[12]=S138;
   ppArrayRef[13]=S161;
   ppArrayRef[14]=S200;
  }
//+------------------------------------------------------------------+
//traditional pivot point formula
void traditionalPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//the formula for the traditional floor pivot points
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }

   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday - skip over
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday - skip over
        {
         shift+=1;
        }
     }
   double prevHigh = iHigh(NULL,timeFrame,shift);
   double prevLow=iLow(NULL,timeFrame,shift);
   double prevClose=iClose(NULL,timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double PP = (prevHigh+prevLow+prevClose)/3;
   double R1 = PP * 2 - prevLow;
   double S1 = PP * 2 - prevHigh;
   double R2 = PP + prevHigh - prevLow;
   double S2 = PP - prevHigh + prevLow;
   double R3 = PP * 2 + (prevHigh - 2 * prevLow);
   double S3 = PP * 2 - (2 * prevHigh - prevLow);
   double R4 = PP * 3 + (prevHigh - 3 * prevLow);
   double S4 = PP * 3 - (3 * prevHigh - prevLow);
   double R5 = PP * 4 + (prevHigh - 4 * prevLow);
   double S5 = PP * 4 - (4 * prevHigh - prevLow) ;
   ppArrayRef[0]=PP;
   ppArrayRef[1]=S1;
   ppArrayRef[2]=S2;
   ppArrayRef[3]=S3;
   ppArrayRef[4]=R1;
   ppArrayRef[5]=R2;
   ppArrayRef[6]=R3;
   ppArrayRef[7]=R4;
   ppArrayRef[8]=S4;
   ppArrayRef[9]=S5;
   ppArrayRef[10]=R5;
  }
//+------------------------------------------------------------------+
void demarkPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//demark pivot point formula
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         shift+=1;
        }
     }
   double prevHigh =    iHigh(NULL,timeFrame,shift);
   double prevLow=      iLow(NULL,timeFrame,shift);
   double prevClose =   iClose(NULL, timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double prevOpen =    iOpen(NULL, timeFrame,shift);
   double X=1;
   if(prevOpen==prevClose)
     {
      X=(prevHigh+prevLow+(2*prevClose));
     }
   if(prevClose>prevOpen)
     {
      X=((2*prevHigh)+prevLow+prevClose);
     }
   if(prevClose<prevOpen)
     {
      X=(prevHigh+(prevLow*2)+prevClose);
     }
   double PP =X/4;
   double R1 =X/2-prevLow;
   double S1 =X/2-prevHigh;
   ppArrayRef[0]=PP;
   ppArrayRef[1]=R1;
   ppArrayRef[2]=S1;
  }
//+------------------------------------------------------------------+
void classicPivotPoint(double &ppArrayRef[],int timeframeShift,bool futurePlot)//classic pivot point formula
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1+timeframeShift;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         shift+=1;
        }
     }
   double prevHigh =    iHigh(NULL,timeFrame,shift);
   double prevLow=      iLow(NULL,timeFrame,shift);
   double prevClose =   iClose(NULL, timeFrame,shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double PP =(prevHigh+prevLow+prevClose)/3;
   double R1 =(2*PP)-prevLow;
   double S1 =(2*PP)-prevHigh;
   double R2=PP+(prevHigh-prevLow);
   double S2=PP-(prevHigh-prevLow);
   double R3=PP+2*(prevHigh-prevLow);
   double S3=PP-2*(prevHigh-prevLow);
   double R4=PP+3*(prevHigh-prevLow);
   double S4=PP-3*(prevHigh-prevLow);
   ppArrayRef[0]=PP;
   ppArrayRef[1]=S1;
   ppArrayRef[2]=S2;
   ppArrayRef[3]=S3;
   ppArrayRef[4]=S4;
   ppArrayRef[5]=R1;
   ppArrayRef[6]=R2;
   ppArrayRef[7]=R3;
   ppArrayRef[8]=R4;
  }
//+------------------------------------------------------------------+
void EnableDisablePivotPoint()//Enable/DisablePivotPoint
  {
//Standard(Floor)
   if(showStandardPivotPP==Disable)//Standard(Floor) PP
      showStandard[0]=false;
   else
      showStandard[0]=true;
   if(showStandardPivotS1==Disable)//Standard(Floor) S1
      showStandard[1]=false;
   else
      showStandard[1]=true;
   if(showStandardPivotS2==Disable)//Standard(Floor) S2
      showStandard[2]=false;
   else
      showStandard[2]=true;
   if(showStandardPivotS3==Disable)//Standard(Floor) S3
      showStandard[3]=false;
   else
      showStandard[3]=true;
   if(showStandardPivotR1==Disable)//Standard(Floor) R1
      showStandard[4]=false;
   else
      showStandard[4]=true;
   if(showStandardPivotR2==Disable)//Standard(Floor) R2
      showStandard[5]=false;
   else
      showStandard[5]=true;
   if(showStandardPivotR3==Disable)//Standard(Floor) R3
      showStandard[6]=false;
   else
      showStandard[6]=true;
   if(showStandardPivotR4==Disable)//Standard(Floor) R4
      showStandard[7]=false;
   else
      showStandard[7]=true;
   if(showStandardPivotS4==Disable)//Standard(Floor) S4
      showStandard[8]=false;
   else
      showStandard[8]=true;
   if(showStandardPivotMR4==Disable)//Standard(Floor) MR4
      showStandard[9]=false;
   else
      showStandard[9]=true;
   if(showStandardPivotMR3==Disable)//Standard(Floor) MR3
      showStandard[10]=false;
   else
      showStandard[10]=true;
   if(showStandardPivotMR2==Disable)//Standard(Floor) MR2
      showStandard[11]=false;
   else
      showStandard[11]=true;
   if(showStandardPivotMR1==Disable)//Standard(Floor) MR1
      showStandard[12]=false;
   else
      showStandard[12]=true;
   if(showStandardPivotMS1==Disable)//Standard(Floor) MS1
      showStandard[13]=false;
   else
      showStandard[13]=true;
   if(showStandardPivotMS2==Disable)//Standard(Floor) MS2
      showStandard[14]=false;
   else
      showStandard[14]=true;
   if(showStandardPivotMS3==Disable)//Standard(Floor) MS3
      showStandard[15]=false;
   else
      showStandard[15]=true;
   if(showStandardPivotMS4==Disable)//Standard(Floor) MS4
      showStandard[16]=false;
   else
      showStandard[16]=true;

//Camarilla
   if(showCamarillaPP==Disable) //Camarilla PP
      showCamarilla[0]=false;
   else
      showCamarilla[0]=true;
   if(showCamarillaL1==Disable)//Camarilla L1
      showCamarilla[1]=false;
   else
      showCamarilla[1]=true;
   if(showCamarillaL2==Disable)//Camarilla L2
      showCamarilla[2]=false;
   else
      showCamarilla[2]=true;
   if(showCamarillaL3==Disable)//Camarilla L3
      showCamarilla[3]=false;
   else
      showCamarilla[3]=true;
   if(showCamarillaL4==Disable)//Camarilla L4
      showCamarilla[4]=false;
   else
      showCamarilla[4]=true;
   if(showCamarillaH1==Disable)//Camarilla H1
      showCamarilla[5]=false;
   else
      showCamarilla[5]=true;
   if(showCamarillaH2==Disable)//Camarilla H2
      showCamarilla[6]=false;
   else
      showCamarilla[6]=true;
   if(showCamarillaH3==Disable)//Camarilla H3
      showCamarilla[7]=false;
   else
      showCamarilla[7]=true;
   if(showCamarillaH4==Disable)//Camarilla H4
      showCamarilla[8]=false;
   else
      showCamarilla[8]=true;
   if(showCamarillaH5==Disable)//Camarilla H5
      showCamarilla[9]=false;
   else
      showCamarilla[9]=true;
   if(showCamarillaL5==Disable)//Camarilla L5
      showCamarilla[10]=false;
   else
      showCamarilla[10]=true;

//Woodie
   if(showWoodiePP==Disable)//Woodie PP
      showWoodie[0]=false;
   else
      showWoodie[0]=true;
   if(showWoodieS1==Disable)//Woodie S1
      showWoodie[1]=false;
   else
      showWoodie[1]=true;
   if(showWoodieS2==Disable)//Woodie S2
      showWoodie[2]=false;
   else
      showWoodie[2]=true;
   if(showWoodieR1==Disable)//Woodie R1
      showWoodie[3]=false;
   else
      showWoodie[3]=true;
   if(showWoodieR2==Disable)//Woodie R2
      showWoodie[4]=false;
   else
      showWoodie[4]=true;
   if(showWoodieS3==Disable)//Woodie S3
      showWoodie[5]=false;
   else
      showWoodie[5]=true;
   if(showWoodieS4==Disable)//Woodie S4
      showWoodie[6]=false;
   else
      showWoodie[6]=true;
   if(showWoodieR3==Disable)//Woodie R3
      showWoodie[7]=false;
   else
      showWoodie[7]=true;
   if(showWoodieR4==Disable)//Woodie R4
      showWoodie[8]=false;
   else
      showWoodie[8]=true;

//Fibonacci
   if(showFibonacciPivotPP==Disable)//Fibonacci PP
      showFibonacci[0]=false;
   else
      showFibonacci[0]=true;
   if(showFibonacciPivotR38==Disable)//Fibonacci R38
      showFibonacci[1]=false;
   else
      showFibonacci[1]=true;
   if(showFibonacciPivotR61==Disable)//Fibonacci R61
      showFibonacci[2]=false;
   else
      showFibonacci[2]=true;
   if(showFibonacciPivotR78==Disable)//Fibonacci R78
      showFibonacci[3]=false;
   else
      showFibonacci[3]=true;
   if(showFibonacciPivotR100==Disable)//Fibonacci R100
      showFibonacci[4]=false;
   else
      showFibonacci[4]=true;
   if(showFibonacciPivotR138==Disable)//Fibonacci R138
      showFibonacci[5]=false;
   else
      showFibonacci[5]=true;
   if(showFibonacciPivotR161==Disable)//Fibonacci R161
      showFibonacci[6]=false;
   else
      showFibonacci[6]=true;
   if(showFibonacciPivotR200==Disable)//Fibonacci R200
      showFibonacci[7]=false;
   else
      showFibonacci[7]=true;
   if(showFibonacciPivotS38==Disable)//Fibonacci S38
      showFibonacci[8]=false;
   else
      showFibonacci[8]=true;
   if(showFibonacciPivotS61==Disable)//Fibonacci S61
      showFibonacci[9]=false;
   else
      showFibonacci[9]=true;
   if(showFibonacciPivotS78==Disable)//Fibonacci S78
      showFibonacci[10]=false;
   else
      showFibonacci[10]=true;
   if(showFibonacciPivotS100==Disable)//Fibonacci S100
      showFibonacci[11]=false;
   else
      showFibonacci[11]=true;
   if(showFibonacciPivotS138==Disable)//Fibonacci S138
      showFibonacci[12]=false;
   else
      showFibonacci[12]=true;
   if(showFibonacciPivotS161==Disable)//Fibonacci S161
      showFibonacci[13]=false;
   else
      showFibonacci[13]=true;
   if(showFibonacciPivotS200==Disable)//Fibonacci S200
      showFibonacci[14]=false;
   else
      showFibonacci[14]=true;

//Traditional
   if(showTraditionalPP==Disable)//Traditional PP
      showTraditional[0]=false;
   else
      showTraditional[0]=true;
   if(showTraditionalS1==Disable)//Traditional S1
      showTraditional[1]=false;
   else
      showTraditional[1]=true;
   if(showTraditionalS2==Disable)//Traditional S2
      showTraditional[2]=false;
   else
      showTraditional[2]=true;
   if(showTraditionalS3==Disable)//Traditional S3
      showTraditional[3]=false;
   else
      showTraditional[3]=true;
   if(showTraditionalR1==Disable)//Traditional R1
      showTraditional[4]=false;
   else
      showTraditional[4]=true;
   if(showTraditionalR2==Disable)//Traditional R2
      showTraditional[5]=false;
   else
      showTraditional[5]=true;
   if(showTraditionalR3==Disable)//Traditional R3
      showTraditional[6]=false;
   else
      showTraditional[6]=true;
   if(showTraditionalR4==Disable)//Traditional R4
      showTraditional[7]=false;
   else
      showTraditional[7]=true;
   if(showTraditionalS4==Disable)//Traditional S4
      showTraditional[8]=false;
   else
      showTraditional[8]=true;
   if(showTraditionalS5==Disable)//Traditional S5
      showTraditional[9]=false;
   else
      showTraditional[9]=true;
   if(showTraditionalR5==Disable)//Traditional R5
      showTraditional[10]=false;
   else
      showTraditional[10]=true;

//Demark
   if(showDemarkPP==Disable)//Demark PP
      showDemark[0]=false;
   else
      showDemark[0]=true;
   if(showDemarkR1==Disable)//Demark R1
      showDemark[1]=false;
   else
      showDemark[1]=true;
   if(showDemarkS1==Disable)//Demark S1
      showDemark[2]=false;
   else
      showDemark[2]=true;

//Classic
   if(showClassicPP==Disable)//Classic PP
      showClassic[0]=false;
   else
      showClassic[0]=true;
   if(showClassicS1==Disable)//Classic S1
      showClassic[1]=false;
   else
      showClassic[1]=true;
   if(showClassicS2==Disable)//Classic S2
      showClassic[2]=false;
   else
      showClassic[2]=true;
   if(showClassicS3==Disable)//Classic S3
      showClassic[3]=false;
   else
      showClassic[3]=true;
   if(showClassicS4==Disable)//Classic S4
      showClassic[4]=false;
   else
      showClassic[4]=true;
   if(showClassicR1==Disable)//Classic R1
      showClassic[5]=false;
   else
      showClassic[5]=true;
   if(showClassicR2==Disable)//Classic R2
      showClassic[6]=false;
   else
      showClassic[6]=true;
   if(showClassicR3==Disable)//Classic R3
      showClassic[7]=false;
   else
      showClassic[7]=true;
   if(showClassicR4==Disable)//Classic R4
      showClassic[8]=false;
   else
      showClassic[8]=true;

//CPR
   if(showCPRBC==Disable)//CPR BC
      showFloorCPR[0]=false;
   else
      showFloorCPR[0]=true;
   if(showCPRTC==Disable)//CPR TC
      showFloorCPR[1]=false;
   else
      showFloorCPR[1]=true;
  }
//+------------------------------------------------------------------+
void DrawHistoricalLines(double value,string pivotName,int index)
  {
   int timeframeValue=0;
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValue=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValue=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValue=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValue=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValue=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValue=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValue=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValue=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValue=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValue=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValue=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValue=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValue=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValue=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValue=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValue=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValue=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValue=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValue=43200;
         break;// Variations..
     }
   color lineLabelColor=clrNONE;
   string message="";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('R'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }
   if('P'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=pivotColor;
     }
   if('S'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }
   if('M'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=midColor;
     }
   if('H'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }
   if('L'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }
   string nameLine=  indiName+pivotName+" Line"+" "+(string)index;
   string nameLabel= indiName+pivotName+" Label"+" "+(string)index;
   if(ObjectFindMQL4(nameLine) != 0)
     {
      ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,index),value,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,index),value);
      ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
     }
   if(hideHistoricalLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(historicalLabelLocation==Left_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index),value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
           }
         if(historicalLabelLocation==Middle_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index)+timeframeValue*30,value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
           }
         if(historicalLabelLocation==Right_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
           }

         if(useSameColorLabelChoice==Yes)
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
           }
         else
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
           }
         ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
         ChartRedraw(0);
        }
      else
        {
         if(historicalLabelLocation==Left_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index),value);
           }
         if(historicalLabelLocation==Middle_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index)+timeframeValue*30,value);
           }
         if(historicalLabelLocation==Right_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
           }
        }
     }
  }
//+------------------------------------------------------------------+
bool foundWeekend(int index)
  {
   bool result=false;
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,index);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday
        {
         result=true;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,index);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday
        {
         result=true;
        }
     }
   return result;
  }
//+------------------------------------------------------------------+
void DrawFuturePlot(double value,string pivotName)
  {
   int timeframeValue=0;
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValue=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValue=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValue=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValue=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValue=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValue=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValue=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValue=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValue=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValue=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValue=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValue=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValue=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValue=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValue=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValue=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValue=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValue=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValue=43200;
         break;// Variations..
     }
   color lineLabelColor=clrNONE;
   string message="";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('R'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }

   if('P'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=pivotColor;
     }

   if('S'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }

   if('M'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=midColor;
     }

   if('H'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=resistantColor;
     }

   if('L'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=supportColor;
     }
   string nameLine=  indiName+pivotName+" Line"+" Future";
   string nameLabel= indiName+pivotName+" Label"+" Future";
   if(ObjectFindMQL4(nameLine) != 0)
     {
      ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,0)+timeFrame*60,value,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
      ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
     }
   if(hideFutureLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(futureLabelLocation==Left_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
           }
         if(futureLabelLocation==Middle_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*90,value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
           }
         if(futureLabelLocation==Right_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
            ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
           }
         if(useSameColorLabelChoice==Yes)
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
           }
         else
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
           }
         ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
         ChartRedraw(0);
        }
      else
        {
         if(futureLabelLocation==Left_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
           }
         if(futureLabelLocation==Middle_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*90,value);
           }
         if(futureLabelLocation==Right_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
           }
        }
     }
  }
//standard pivot point formula
void standardPivotPointCPR(double &ppArrayRef[],int timeframeShift,bool futurePlot)//the formula for the standard floor pivot points
  {
   int shift=0;
   if(futurePlot)
     {
      shift=0;
     }
   else
     {
      shift=1;
     }
   /*
   Returned value
   The zero-based day of week (0 means Sunday,1,2,3,4,5,6) of the specified date.
   */
   if(timeFrame==PERIOD_D1)
     {
      datetime dayCheck1=iTime(NULL,PERIOD_D1,timeframeShift+shift);
      if(TimeDayOfWeekMQL4(dayCheck1) == 0)//found sunday - skip over
        {
         shift+=1;
        }
      datetime dayCheck2=iTime(NULL,PERIOD_D1,timeframeShift+shift);
      if(TimeDayOfWeekMQL4(dayCheck2) == 6)//found saturday - skip over
        {
         shift+=1;
        }
     }
   double prevHigh = iHigh(NULL,timeFrame,timeframeShift+shift);
   double prevLow=iLow(NULL,timeFrame,timeframeShift+shift);
   double prevClose=iClose(NULL,timeFrame,timeframeShift+shift);
   if(futurePlot)
     {
      prevClose=  SymbolInfoDouble(NULL,SYMBOL_BID);
     }
   double PP = (prevHigh+prevLow+prevClose)/3;
   double BC = (prevHigh+prevLow)/2;
   double TC = (PP-BC)+PP;
   ppArrayRef[0]=BC;
   ppArrayRef[1]=TC;
  }
//+------------------------------------------------------------------+
void DrawCPRPivotLines(double value,string pivotName)
  {
   int timeframeValueLabel=0;
   int timeframeValueLine=0;
   if(currentLabelLocation==Follow_Price_2 || useShortLines==Yes)
     {
      switch(Period())
        {
         // Start of the 'switch' body
         case PERIOD_M1 :
            timeframeValueLabel=1;
            break;// Variations..
         case PERIOD_M2 :
            timeframeValueLabel=2;
            break;// Variations..
         case PERIOD_M3 :
            timeframeValueLabel=3;
            break;// Variations..
         case PERIOD_M4 :
            timeframeValueLabel=4;
            break;// Variations..
         case PERIOD_M5 :
            timeframeValueLabel=5;
            break;// Variations..
         case PERIOD_M6 :
            timeframeValueLabel=6;
            break;// Variations..
         case PERIOD_M10 :
            timeframeValueLabel=10;
            break;// Variations..
         case PERIOD_M12 :
            timeframeValueLabel=12;
            break;// Variations..
         case PERIOD_M15 :
            timeframeValueLabel=15;
            break;// Variations..
         case PERIOD_M20 :
            timeframeValueLabel=20;
            break;// Variations..
         case PERIOD_M30 :
            timeframeValueLabel=30;
            break;// Variations..
         case PERIOD_H1 :
            timeframeValueLabel=60;
            break;// Variations..
         case PERIOD_H2 :
            timeframeValueLabel=240;
            break;// Variations..
         case PERIOD_H3 :
            timeframeValueLabel=180;
            break;// Variations..
         case PERIOD_H4 :
            timeframeValueLabel=240;
            break;// Variations..
         case PERIOD_H6 :
            timeframeValueLabel=360;
            break;// Variations..
         case PERIOD_H8 :
            timeframeValueLabel=480;
            break;// Variations..
         case PERIOD_H12 :
            timeframeValueLabel=720;
            break;// Variations..
         case PERIOD_D1 :
            timeframeValueLabel=1440;
            break;// Variations..
         case PERIOD_W1 :
            timeframeValueLabel=10080;
            break;// Variations..
         case PERIOD_MN1 :
            timeframeValueLabel=43200;
            break;// Variations..
        }                                 // Header of the 'switch'
     }
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValueLine=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValueLine=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValueLine=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValueLine=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValueLine=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValueLine=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValueLine=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValueLine=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValueLine=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValueLine=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValueLine=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValueLine=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValueLine=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValueLine=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValueLine=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValueLine=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValueLine=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValueLine=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValueLine=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValueLine=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValueLine=43200;
         break;// Variations..
     }
   datetime Time[];
   int count=2;   // number of elements to copy
   ArraySetAsSeries(Time,true);
   CopyTime(_Symbol,_Period,0,count,Time);
   color lineLabelColor=clrNONE;
   string message="Poop";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('B'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=CPRColor;
     }
   else
      if('T'==StringGetCharacter(pivotName,0))
        {
         lineLabelColor=CPRColor;
        }
   string nameLine=  indiName+pivotName+" Line";
   string nameLabel= indiName+pivotName+" Label";
   if(ObjectFindMQL4(nameLine) != 0)
     {
      if(useShortLines==Yes)
        {
         ObjectCreateMQL4(nameLine, OBJ_TREND, 0, Time[1]+timeframeValueLabel*60, value, Time[0]+timeframeValueLabel*60*Line_Length, value);
        }
      else
        {
         ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,0),value,iTime(NULL,timeFrame,0)+timeframeValueLine*120,value);
        }
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      if(useShortLines==Yes)
        {
         ObjectMoveMQL4(nameLine, 0, Time[1]+timeframeValueLabel*60, value);
         ObjectMoveMQL4(nameLine, 1, Time[0]+timeframeValueLabel*60*Line_Length, value);
        }
      else
        {
         ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,0),value);
         ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
        }
     }
   if(hideCurrentLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(useShortLines==Yes)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
            if(useSameColorLabelChoice==Yes)
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
              }
            else
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
              }
            ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
           }
         else
           {
            if(currentLabelLocation==Follow_Price_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
              }
            if(currentLabelLocation==Left_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0),value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
              }
            if(currentLabelLocation==Middle_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValueLine*30,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
              }
            if(currentLabelLocation==Right_2)
              {
               ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
               ObjectSetInteger(0,nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
              }
            if(useSameColorLabelChoice==Yes)
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
              }
            else
              {
               ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
              }
            ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
            ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
           }
         ChartRedraw(0);
        }
      else
        {
         if(currentLabelLocation==Follow_Price_2)
           {
            ObjectMoveMQL4(nameLabel,0,Time[0]+timeframeValueLabel*60*ShiftLabel,value);
           }
         if(currentLabelLocation==Left_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0),value);
           }
         if(currentLabelLocation==Middle_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValueLine*30,value);
           }
         if(currentLabelLocation==Right_2)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValueLine*60,value);
           }
        }
     }
  }
//+------------------------------------------------------------------+
void DrawCPRHistoricalLines(double value,string pivotName,int index)
  {
   int timeframeValue=0;
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValue=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValue=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValue=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValue=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValue=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValue=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValue=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValue=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValue=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValue=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValue=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValue=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValue=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValue=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValue=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValue=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValue=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValue=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValue=43200;
         break;// Variations..
     }
   color lineLabelColor=clrNONE;
   string message="";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('B'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=CPRColor;
     }
   if('T'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=CPRColor;
     }
   string nameLine=  indiName+pivotName+" Line"+" "+(string)index;
   string nameLabel= indiName+pivotName+" Label"+" "+(string)index;
   if(ObjectFindMQL4(nameLine) != 0)
     {
      ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,index),value,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,index),value);
      ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
     }
   if(hideHistoricalLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(historicalLabelLocation==Left_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index),value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
           }
         if(historicalLabelLocation==Middle_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index)+timeframeValue*30,value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
           }
         if(historicalLabelLocation==Right_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
           }
         if(useSameColorLabelChoice==Yes)
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
           }
         else
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
           }
         ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
         ChartRedraw(0);
        }
      else
        {
         if(historicalLabelLocation==Left_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index),value);
           }
         if(historicalLabelLocation==Middle_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index)+timeframeValue*30,value);
           }
         if(historicalLabelLocation==Right_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,index)+timeframeValue*60,value);
           }
        }
     }
  }
//+------------------------------------------------------------------+
void DrawCPRFuturePlot(double value,string pivotName)
  {
   int timeframeValue=0;
   switch(timeFrame)                                  // Header of the 'switch'
     {
      // Start of the 'switch' body
      case PERIOD_M1 :
         timeframeValue=1;
         break;// Variations..
      case PERIOD_M2 :
         timeframeValue=2;
         break;// Variations..
      case PERIOD_M3 :
         timeframeValue=3;
         break;// Variations..
      case PERIOD_M4 :
         timeframeValue=4;
         break;// Variations..
      case PERIOD_M5 :
         timeframeValue=5;
         break;// Variations..
      case PERIOD_M6 :
         timeframeValue=6;
         break;// Variations..
      case PERIOD_M10 :
         timeframeValue=10;
         break;// Variations..
      case PERIOD_M12 :
         timeframeValue=12;
         break;// Variations..
      case PERIOD_M15 :
         timeframeValue=15;
         break;// Variations..
      case PERIOD_M20 :
         timeframeValue=20;
         break;// Variations..
      case PERIOD_M30 :
         timeframeValue=30;
         break;// Variations..
      case PERIOD_H1 :
         timeframeValue=60;
         break;// Variations..
      case PERIOD_H2 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H3 :
         timeframeValue=180;
         break;// Variations..
      case PERIOD_H4 :
         timeframeValue=240;
         break;// Variations..
      case PERIOD_H6 :
         timeframeValue=360;
         break;// Variations..
      case PERIOD_H8 :
         timeframeValue=480;
         break;// Variations..
      case PERIOD_H12 :
         timeframeValue=720;
         break;// Variations..
      case PERIOD_D1 :
         timeframeValue=1440;
         break;// Variations..
      case PERIOD_W1 :
         timeframeValue=10080;
         break;// Variations..
      case PERIOD_MN1 :
         timeframeValue=43200;
         break;// Variations..
     }
   color lineLabelColor=clrNONE;
   string message="";
   if(showPriceLabel==Yes)
     {
      message=customMSG+pivotName+": "+DoubleToString(value,Digits());
     }
   else
     {
      message=customMSG+pivotName;
     }
   if('B'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=CPRColor;
     }
   if('T'==StringGetCharacter(pivotName,0))
     {
      lineLabelColor=CPRColor;
     }
   string nameLine=  indiName+pivotName+" Line"+" Future";
   string nameLabel= indiName+pivotName+" Label"+" Future";
   if(ObjectFindMQL4(nameLine) != 0)
     {
      ObjectCreateMQL4(nameLine,OBJ_TREND,0,iTime(NULL,timeFrame,0)+timeFrame*60,value,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
      ObjectSetMQL4(nameLine,OBJPROP_RAY,false);
      ObjectSetMQL4(nameLine,OBJPROP_COLOR,lineLabelColor);
      ObjectSetMQL4(nameLine,OBJPROP_STYLE,lineStyle);
      ObjectSetMQL4(nameLine,OBJPROP_WIDTH,lineWidth);
      ObjectSetMQL4(nameLine,OBJPROP_BACK,true);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTED,false);
      ObjectSetMQL4(nameLine,OBJPROP_SELECTABLE,false);
      ChartRedraw(0);
     }
   else
     {
      ObjectMoveMQL4(nameLine,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
      ObjectMoveMQL4(nameLine,1,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
     }
   if(hideFutureLabels==No)
     {
      if(ObjectFindMQL4(nameLabel) != 0)
        {
         if(futureLabelLocation==Left_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_LEFT_UPPER);
           }
         if(futureLabelLocation==Middle_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*90,value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_UPPER);
           }
         if(futureLabelLocation==Right_1)
           {
            ObjectCreateMQL4(nameLabel,OBJ_TEXT,0,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
            ObjectSetMQL4(nameLabel,OBJPROP_ANCHOR,ANCHOR_RIGHT_UPPER);
           }
         if(useSameColorLabelChoice==Yes)
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,useSameColorLabelColor);
           }
         else
           {
            ObjectSetTextMQL4(nameLabel,message,labelFontSize,Font,lineLabelColor);
           }
         ObjectSetMQL4(nameLabel,OBJPROP_BACK,true);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTED,false);
         ObjectSetMQL4(nameLabel,OBJPROP_SELECTABLE,false);
         ChartRedraw(0);
        }
      else
        {
         if(futureLabelLocation==Left_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*60,value);
           }
         if(futureLabelLocation==Middle_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*90,value);
           }
         if(futureLabelLocation==Right_1)
           {
            ObjectMoveMQL4(nameLabel,0,iTime(NULL,timeFrame,0)+timeframeValue*120,value);
           }
        }
     }
  }
//+------------------------------------------------------------------+
int ObjectFindMQL4(string name)
  {
   return(ObjectFind(0,name));
  }
//+------------------------------------------------------------------+
bool ObjectSetMQL4(string name,
                   int index,
                   double value)
  {
   switch(index)
     {
      case OBJPROP_TIME1:
         ObjectSetInteger(0,name,OBJPROP_TIME,(int)value);
         return(true);
      case OBJPROP_PRICE1:
         ObjectSetDouble(0,name,OBJPROP_PRICE,value);
         return(true);
      case OBJPROP_TIME2:
         ObjectSetInteger(0,name,OBJPROP_TIME,1,(int)value);
         return(true);
      case OBJPROP_PRICE2:
         ObjectSetDouble(0,name,OBJPROP_PRICE,1,value);
         return(true);
      case OBJPROP_TIME3:
         ObjectSetInteger(0,name,OBJPROP_TIME,2,(int)value);
         return(true);
      case OBJPROP_PRICE3:
         ObjectSetDouble(0,name,OBJPROP_PRICE,2,value);
         return(true);
      case OBJPROP_COLOR:
         ObjectSetInteger(0,name,OBJPROP_COLOR,(int)value);
         return(true);
      case OBJPROP_STYLE:
         ObjectSetInteger(0,name,OBJPROP_STYLE,(int)value);
         return(true);
      case OBJPROP_WIDTH:
         ObjectSetInteger(0,name,OBJPROP_WIDTH,(int)value);
         return(true);
      case OBJPROP_BACK:
         ObjectSetInteger(0,name,OBJPROP_BACK,(int)value);
         return(true);
      case OBJPROP_RAY:
         ObjectSetInteger(0,name,OBJPROP_RAY_RIGHT,(int)value);
         return(true);
      case OBJPROP_ELLIPSE:
         ObjectSetInteger(0,name,OBJPROP_ELLIPSE,(int)value);
         return(true);
      case OBJPROP_SCALE:
         ObjectSetDouble(0,name,OBJPROP_SCALE,value);
         return(true);
      case OBJPROP_ANGLE:
         ObjectSetDouble(0,name,OBJPROP_ANGLE,value);
         return(true);
      case OBJPROP_ARROWCODE:
         ObjectSetInteger(0,name,OBJPROP_ARROWCODE,(int)value);
         return(true);
      case OBJPROP_TIMEFRAMES:
         ObjectSetInteger(0,name,OBJPROP_TIMEFRAMES,(int)value);
         return(true);
      case OBJPROP_DEVIATION:
         ObjectSetDouble(0,name,OBJPROP_DEVIATION,value);
         return(true);
      case OBJPROP_FONTSIZE:
         ObjectSetInteger(0,name,OBJPROP_FONTSIZE,(int)value);
         return(true);
      case OBJPROP_CORNER:
         ObjectSetInteger(0,name,OBJPROP_CORNER,(int)value);
         return(true);
      case OBJPROP_XDISTANCE:
         ObjectSetInteger(0,name,OBJPROP_XDISTANCE,(int)value);
         return(true);
      case OBJPROP_YDISTANCE:
         ObjectSetInteger(0,name,OBJPROP_YDISTANCE,(int)value);
         return(true);
      case OBJPROP_FIBOLEVELS:
         ObjectSetInteger(0,name,OBJPROP_LEVELS,(int)value);
         return(true);
      case OBJPROP_LEVELCOLOR:
         ObjectSetInteger(0,name,OBJPROP_LEVELCOLOR,(int)value);
         return(true);
      case OBJPROP_LEVELSTYLE:
         ObjectSetInteger(0,name,OBJPROP_LEVELSTYLE,(int)value);
         return(true);
      case OBJPROP_LEVELWIDTH:
         ObjectSetInteger(0,name,OBJPROP_LEVELWIDTH,(int)value);
         return(true);

      default:
         return(false);
     }
   return(false);
  }
//+------------------------------------------------------------------+
bool ObjectMoveMQL4(string name,
                    int point,
                    datetime time1,
                    double price1)
  {
   return(ObjectMove(0,name,point,time1,price1));
  }
//+------------------------------------------------------------------+
bool ObjectCreateMQL4(string name,
                      ENUM_OBJECT type,
                      int window,
                      datetime time1,
                      double price1,
                      datetime time2=0,
                      double price2=0,
                      datetime time3=0,
                      double price3=0)
  {
   return(ObjectCreate(0,name,type,window,
                       time1,price1,time2,price2,time3,price3));
  }
//+------------------------------------------------------------------+
bool ObjectSetTextMQL4(string name,
                       string text,
                       int font_size,
                       string font="",
                       color text_color=CLR_NONE)
  {
   int tmpObjType=(int)ObjectGetInteger(0,name,OBJPROP_TYPE);
   if(tmpObjType!=OBJ_LABEL && tmpObjType!=OBJ_TEXT)
      return(false);
   if(StringLen(text)>0 && font_size>0)
     {
      if(ObjectSetString(0,name,OBJPROP_TEXT,text)==true
         && ObjectSetInteger(0,name,OBJPROP_FONTSIZE,font_size)==true)
        {
         if((StringLen(font)>0)
            && ObjectSetString(0,name,OBJPROP_FONT,font)==false)
            return(false);
         if(text_color>-1
            && ObjectSetInteger(0,name,OBJPROP_COLOR,text_color)==false)
            return(false);
         return(true);
        }
      return(false);
     }
   return(false);
  }
//+------------------------------------------------------------------+
int TimeDayOfWeekMQL4(datetime date)
  {
   MqlDateTime tm;
   TimeToStruct(date,tm);
   return(tm.day_of_week);
  }
//+------------------------------------------------------------------+
