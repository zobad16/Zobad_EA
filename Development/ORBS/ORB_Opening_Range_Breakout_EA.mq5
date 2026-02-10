//+------------------------------------------------------------------+
//|                                ORB Opening Range Breakout EA.mq5 |
//|                           Copyright 2025, Allan Munene Mutiiria. |
//|                                   https://t.me/Forex_Algo_Trader |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Allan Munene Mutiiria."
#property link      "https://t.me/Forex_Algo_Trader"
#property version   "1.00"

#include <Trade\Trade.mqh>

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
enum SLTP_Method {                                                // Define SL/TP method enum
   Dynamic_Method = 0,                                            // Dynamic based on range size
   Static_Method  = 1                                             // Static based on fixed points
};

enum TrailingTypeEnum {                                           // Define trailing type enum
   Trailing_None   = 0,                                           // None
   Trailing_Points = 1                                            // By Points
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input ENUM_TIMEFRAMES RangeTF = PERIOD_M5;                        // Timeframe for Opening Range Calculation
input int RangeDurationMinutes = 30;                              // Duration of Opening Range in Minutes
input string SessionStartTime = "09:00";                          // Session Start Time (HH:MM)
input double TradeVolume = 0.01;                                  // Trade Volume Size
input double RR_Ratio = 2.0;                                      // Risk to Reward Ratio
input SLTP_Method SLTP_Approach = Dynamic_Method;                 // SL/TP Calculation Method
input int SL_Points = 50;                                         // SL Points (for Static Method)
input TrailingTypeEnum TrailingType = Trailing_None;              // Trailing Stop Type
input double Trailing_Stop_Points = 20.0;                         // Trailing Stop in Points
input double Min_Profit_To_Trail_Points = 30.0;                   // Min Profit to Start Trailing in Points
input int UniqueID = 987654321;                                   // Unique Trade Identifier
input int MaxPositionsDir = 1;                                     // Max Positions per Direction
input bool UseBreakoutFilter = true;                              // Use Breakout Confirmation Filter
input int ConfirmBars = 1;                                        // Bars to Confirm Breakout on Close (0 to disable)

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade obj_Trade;                                                 //--- Trade object
datetime sessionStart = 0;                                        //--- Session start time
datetime rangeEndTime = 0;                                        //--- Range end time
double rangeHigh = 0.0;                                           //--- Range high
double rangeLow = 0.0;                                            //--- Range low
bool rangeDefined = false;                                        //--- Range defined flag
bool breakoutHigh = false;                                        //--- Breakout high flag
bool breakoutLow = false;                                         //--- Breakout low flag
double breakoutPrice = 0.0;                                       //--- Breakout price
string highLevelObj = "ORB_HighLevel";                            //--- High level object name
string lowLevelObj = "ORB_LowLevel";                              //--- Low level object name
string highTextObj = "ORB_High_Text";                             //--- High text object
string lowTextObj = "ORB_Low_Text";                               //--- Low text object
bool tradedLong = false;                                          //--- Traded long flag
bool tradedShort = false;                                         //--- Traded short flag
datetime lastConfirmTime = 0;                                     //--- Last confirm time

//+------------------------------------------------------------------+
//| EA Start Function                                                |
//+------------------------------------------------------------------+
int OnInit() {
   obj_Trade.SetExpertMagicNumber(UniqueID);                      //--- Set magic number
   return(INIT_SUCCEEDED);                                        //--- Return success
}

//+------------------------------------------------------------------+
//| EA Stop Function                                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int code) {
   ObjectDelete(ChartID(), highLevelObj);                         //--- Delete high level
   ObjectDelete(ChartID(), lowLevelObj);                          //--- Delete low level
   ObjectDelete(ChartID(), highTextObj);                          //--- Delete high text
   ObjectDelete(ChartID(), lowTextObj);                           //--- Delete low text
   // Clean dynamic objects
   ObjectsDeleteAll(ChartID(), "ORB_Rectangle_", OBJ_RECTANGLE);  //--- Delete rectangles
   ObjectsDeleteAll(ChartID(), "ORB_StartVLine_", OBJ_VLINE);     //--- Delete start vlines
   ObjectsDeleteAll(ChartID(), "ORB_EndVLine_", OBJ_VLINE);       //--- Delete end vlines
   ObjectsDeleteAll(ChartID(), "ORB_StartTime_Text_", OBJ_TEXT);  //--- Delete start texts
   ObjectsDeleteAll(ChartID(), "ORB_EndTime_Text_", OBJ_TEXT);    //--- Delete end texts
   ObjectsDeleteAll(ChartID(), "EntryMarker_", OBJ_ARROW);        //--- Delete entry markers
}

//+------------------------------------------------------------------+
//| Tick Processing Function                                         |
//+------------------------------------------------------------------+
void OnTick() {
   datetime currentTime = TimeCurrent();                          //--- Get current time
   MqlDateTime timeStruct;                                        //--- Time structure
   TimeToStruct(currentTime, timeStruct);                         //--- Convert to struct
   // Determine if a new session has started
   string currentTimeStr = StringFormat("%02d:%02d", timeStruct.hour, timeStruct.min); //--- Format time string
   if (currentTimeStr == SessionStartTime && sessionStart != currentTime - (timeStruct.hour * 3600 + timeStruct.min * 60 + timeStruct.sec)) { //--- Check new session
      sessionStart = currentTime - timeStruct.sec;                //--- Align to minute start
      rangeEndTime = sessionStart + RangeDurationMinutes * 60;    //--- Calc end time
      rangeHigh = 0.0;                                            //--- Reset high
      rangeLow = DBL_MAX;                                         //--- Reset low
      rangeDefined = false;                                       //--- Reset defined
      breakoutHigh = false;                                       //--- Reset high breakout
      breakoutLow = false;                                        //--- Reset low breakout
      tradedLong = false;                                         //--- Reset long traded
      tradedShort = false;                                        //--- Reset short traded
      lastConfirmTime = 0;                                        //--- Reset confirm time
      // Clean previous visuals for current levels
      ObjectDelete(ChartID(), highLevelObj);                      //--- Delete high level
      ObjectDelete(ChartID(), lowLevelObj);                       //--- Delete low level
      ObjectDelete(ChartID(), highTextObj);                       //--- Delete high text
      ObjectDelete(ChartID(), lowTextObj);                        //--- Delete low text
   }
   if (sessionStart == 0) return;                                 //--- Return if no session
   double currBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);        //--- Get bid
   double currAsk = SymbolInfoDouble(_Symbol, SYMBOL_ASK);        //--- Get ask
   // Define the opening range
   if (currentTime < rangeEndTime) {                              //--- Check within range
      rangeHigh = MathMax(rangeHigh, iHigh(_Symbol, RangeTF, 0)); //--- Update high
      rangeLow = MathMin(rangeLow, iLow(_Symbol, RangeTF, 0));    //--- Update low
   } else if (!rangeDefined) {                                    //--- Check not defined
      rangeDefined = true;                                        //--- Set defined
      // Draw the opening range rectangle
      string rectObj = "ORB_Rectangle_" + IntegerToString(sessionStart); //--- Rect name
      ObjectCreate(ChartID(), rectObj, OBJ_RECTANGLE, 0, sessionStart, rangeHigh, rangeEndTime, rangeLow); //--- Create rect
      ObjectSetInteger(ChartID(), rectObj, OBJPROP_COLOR, clrLightBlue); //--- Set color
      ObjectSetInteger(ChartID(), rectObj, OBJPROP_FILL, true);   //--- Set fill
      ObjectSetInteger(ChartID(), rectObj, OBJPROP_BACK, true);   //--- Set back
      ObjectSetInteger(ChartID(), rectObj, OBJPROP_STYLE, STYLE_SOLID); //--- Set style
      ChartRedraw(ChartID());                                     //--- Redraw chart
      // Add vertical lines for start and end
      string startVLineObj = "ORB_StartVLine_" + IntegerToString(sessionStart); //--- Start vline name
      RenderVLine(startVLineObj, sessionStart, clrBlue, "ORB Start at " + TimeToString(sessionStart, TIME_MINUTES)); //--- Render start vline
      string endVLineObj = "ORB_EndVLine_" + IntegerToString(sessionStart); //--- End vline name
      RenderVLine(endVLineObj, rangeEndTime, clrBlue, "ORB End at " + TimeToString(rangeEndTime, TIME_MINUTES)); //--- Render end vline
      // Add time text labels for start and end
      double textOffset = (rangeHigh - rangeLow) * 0.05;          //--- Calc offset
      string startTimeTextObj = "ORB_StartTime_Text_" + IntegerToString(sessionStart); //--- Start text name
      RenderText(startTimeTextObj, sessionStart, rangeLow - textOffset, TimeToString(sessionStart, TIME_MINUTES), clrBlue, ANCHOR_UPPER); //--- Render start text
      string endTimeTextObj = "ORB_EndTime_Text_" + IntegerToString(sessionStart); //--- End text name
      RenderText(endTimeTextObj, rangeEndTime, rangeLow - textOffset, TimeToString(rangeEndTime, TIME_MINUTES), clrBlue, ANCHOR_UPPER); //--- Render end text
      // Render high and low levels
      RenderLevel(highLevelObj, rangeHigh, clrGreen, "ORB High"); //--- Render high level
      RenderLevel(lowLevelObj, rangeLow, clrRed, "ORB Low");      //--- Render low level
      // Add text labels
      RenderText(highTextObj, rangeEndTime, rangeHigh, "ORB High", clrGreen, ANCHOR_RIGHT_LOWER); //--- Render high text
      RenderText(lowTextObj, rangeEndTime, rangeLow, "ORB Low", clrRed, ANCHOR_RIGHT_UPPER); //--- Render low text
   }
   if (!rangeDefined) return;                                     //--- Return if not defined
   // Detect breakout
   bool justBreached = false;                                     //--- Init just breached
   if (currAsk > rangeHigh && !breakoutHigh) {                    //--- Check high breakout
      breakoutHigh = true;                                        //--- Set high breakout
      justBreached = true;                                        //--- Set just breached
      breakoutPrice = currAsk;                                    //--- Set breakout price
   } else if (currBid < rangeLow && !breakoutLow) {               //--- Check low breakout
      breakoutLow = true;                                         //--- Set low breakout
      justBreached = true;                                        //--- Set just breached
      breakoutPrice = currBid;                                    //--- Set breakout price
   }
   if ((breakoutHigh || breakoutLow) && !(tradedLong || tradedShort)) { //--- Check breakout and not traded
      // Confirm breakout with bar closures if enabled
      bool confirmed = false;                                      //--- Init confirmed
      if (ConfirmBars == 0) {                                      //--- Check no confirm
         confirmed = true;                                         //--- Set confirmed
      } else {                                                     //--- Else
         datetime currConfirmTime = iTime(_Symbol, RangeTF, 0);    //--- Get confirm time
         if (currConfirmTime != lastConfirmTime) {                 //--- Check new confirm
            lastConfirmTime = currConfirmTime;                     //--- Update last confirm
            int confirmCount = 0;                                  //--- Init count
            for (int i = 1; i <= ConfirmBars; i++) {               //--- Iterate bars
               double closePrice = iClose(_Symbol, RangeTF, i);    //--- Get close
               if (breakoutHigh && closePrice > rangeHigh) confirmCount++; //--- Check high
               if (breakoutLow && closePrice < rangeLow) confirmCount++; //--- Check low
            }
            if (confirmCount >= ConfirmBars) confirmed = true;     //--- Set confirmed
         }
      }
      if (confirmed && UseBreakoutFilter) {                        //--- Check confirmed and filter
         // Additional filter logic if needed, but for now assume confirmed
      }
      if (confirmed) {                                             //--- Check confirmed
         double sl = 0.0, tp = 0.0;                                //--- Init SL TP
         if (breakoutHigh && ActivePositions(POSITION_TYPE_BUY) < MaxPositionsDir && !tradedLong) { //--- Check long entry
            if (SLTP_Approach == Dynamic_Method) {                  //--- Check dynamic
               double rangeSize = rangeHigh - rangeLow;             //--- Calc range size
               sl = NormalizeDouble(rangeLow, _Digits);             //--- Set SL
               tp = NormalizeDouble(currAsk + rangeSize * RR_Ratio, _Digits); //--- Set TP
            } else {                                                //--- Static
               sl = NormalizeDouble(currAsk - SL_Points * _Point, _Digits); //--- Set SL
               tp = NormalizeDouble(currAsk + (SL_Points * _Point) * RR_Ratio, _Digits); //--- Set TP
            }
            if (obj_Trade.Buy(TradeVolume, _Symbol, currAsk, sl, tp, "ORB Long Breakout")) { //--- Open buy
               if (obj_Trade.ResultRetcode() == TRADE_RETCODE_DONE) { //--- Check success
                  Print("Long Breakout: Entry at ", DoubleToString(currAsk, _Digits), " SL at ", DoubleToString(sl, _Digits), " TP at ", DoubleToString(tp, _Digits)); //--- Log entry
                  DrawEntryArrow(currentTime, currBid, true);        //--- Draw arrow
                  tradedLong = true;                                 //--- Set long traded
               }
            }
         } else if (breakoutLow && ActivePositions(POSITION_TYPE_SELL) < MaxPositionsDir && !tradedShort) { //--- Check short entry
            if (SLTP_Approach == Dynamic_Method) {                  //--- Check dynamic
               double rangeSize = rangeHigh - rangeLow;             //--- Calc range size
               sl = NormalizeDouble(rangeHigh, _Digits);            //--- Set SL
               tp = NormalizeDouble(currBid - rangeSize * RR_Ratio, _Digits); //--- Set TP
            } else {                                                //--- Static
               sl = NormalizeDouble(currBid + SL_Points * _Point, _Digits); //--- Set SL
               tp = NormalizeDouble(currBid - (SL_Points * _Point) * RR_Ratio, _Digits); //--- Set TP
            }
            if (obj_Trade.Sell(TradeVolume, _Symbol, currBid, sl, tp, "ORB Short Breakout")) { //--- Open sell
               if (obj_Trade.ResultRetcode() == TRADE_RETCODE_DONE) { //--- Check success
                  Print("Short Breakout: Entry at ", DoubleToString(currBid, _Digits), " SL at ", DoubleToString(sl, _Digits), " TP at ", DoubleToString(tp, _Digits)); //--- Log entry
                  DrawEntryArrow(currentTime, currAsk, false);       //--- Draw arrow
                  tradedShort = true;                                //--- Set short traded
               }
            }
         }
      }
   }
   // Apply trailing stop if enabled
   if (TrailingType == Trailing_Points && PositionsTotal() > 0) { //--- Check trailing
      ApplyPointsTrailing();                                      //--- Apply trailing
   }
}

//+------------------------------------------------------------------+
//| Render Horizontal Level                                          |
//+------------------------------------------------------------------+
void RenderLevel(string objName, double levelVal, color levelClr, string levelDesc) {
   ObjectDelete(ChartID(), objName);                              //--- Delete object
   ObjectCreate(ChartID(), objName, OBJ_HLINE, 0, 0, levelVal);  //--- Create hline
   ObjectSetInteger(ChartID(), objName, OBJPROP_COLOR, levelClr); //--- Set color
   ObjectSetInteger(ChartID(), objName, OBJPROP_STYLE, STYLE_DOT); //--- Set style
   ObjectSetString(ChartID(), objName, OBJPROP_TOOLTIP, levelDesc); //--- Set tooltip
   ChartRedraw(ChartID());                                        //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Render Vertical Line                                             |
//+------------------------------------------------------------------+
void RenderVLine(string objName, datetime timeVal, color lineClr, string desc) {
   ObjectDelete(ChartID(), objName);                              //--- Delete object
   ObjectCreate(ChartID(), objName, OBJ_VLINE, 0, timeVal, 0);    //--- Create vline
   ObjectSetInteger(ChartID(), objName, OBJPROP_COLOR, lineClr);  //--- Set color
   ObjectSetInteger(ChartID(), objName, OBJPROP_STYLE, STYLE_DOT); //--- Set style
   ObjectSetInteger(ChartID(), objName, OBJPROP_WIDTH, 1);        //--- Set width
   ObjectSetInteger(ChartID(), objName, OBJPROP_BACK, true);      //--- Set back
   ObjectSetInteger(ChartID(), objName, OBJPROP_RAY, true);       //--- Set ray
   ObjectSetInteger(ChartID(), objName, OBJPROP_HIDDEN, true);    //--- Set hidden
   ObjectSetString(ChartID(), objName, OBJPROP_TOOLTIP, desc);    //--- Set tooltip
   ChartRedraw(ChartID());                                        //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Render Text Label                                                |
//+------------------------------------------------------------------+
void RenderText(string objName, datetime timeVal, double priceVal, string textStr, color textClr, int anchorVal) {
   ObjectDelete(ChartID(), objName);                              //--- Delete object
   ObjectCreate(ChartID(), objName, OBJ_TEXT, 0, timeVal, priceVal); //--- Create text
   ObjectSetString(ChartID(), objName, OBJPROP_TEXT, textStr);    //--- Set text
   ObjectSetInteger(ChartID(), objName, OBJPROP_COLOR, textClr);  //--- Set color
   ObjectSetInteger(ChartID(), objName, OBJPROP_ANCHOR, anchorVal); //--- Set anchor
   ObjectSetInteger(ChartID(), objName, OBJPROP_FONTSIZE, 10);    //--- Set fontsize
   ChartRedraw(ChartID());                                        //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Draw Entry Arrow                                                 |
//+------------------------------------------------------------------+
void DrawEntryArrow(datetime timeVal, double priceVal, bool isBuy) {
   string markerName = "EntryMarker_" + IntegerToString(timeVal); //--- Marker name
   ObjectCreate(ChartID(), markerName, OBJ_ARROW, 0, timeVal, priceVal); //--- Create arrow
   int arrowCode = isBuy ? 233 : 234;                             //--- Arrow code
   color arrowClr = isBuy ? clrBlue : clrRed;                     //--- Arrow color
   int anchor = isBuy ? ANCHOR_BOTTOM : ANCHOR_TOP;               //--- Anchor
   ObjectSetInteger(ChartID(), markerName, OBJPROP_ARROWCODE, arrowCode); //--- Set code
   ObjectSetInteger(ChartID(), markerName, OBJPROP_COLOR, arrowClr); //--- Set color
   ObjectSetInteger(ChartID(), markerName, OBJPROP_ANCHOR, anchor); //--- Set anchor
   ChartRedraw(ChartID());                                        //--- Redraw chart
}

//+------------------------------------------------------------------+
//| Count Active Positions by Type                                   |
//+------------------------------------------------------------------+
int ActivePositions(ENUM_POSITION_TYPE posType) {
   int total = 0;                                                 //--- Init total
   for (int pos = PositionsTotal() - 1; pos >= 0; pos--) {        //--- Iterate positions
      if (PositionGetSymbol(pos) == _Symbol && PositionGetInteger(POSITION_MAGIC) == UniqueID && PositionGetInteger(POSITION_TYPE) == posType) { //--- Check position
         total++;                                                    //--- Increment total
      }
   }
   return total;                                                  //--- Return total
}

//+------------------------------------------------------------------+
//| Apply Points Trailing Stop                                       |
//+------------------------------------------------------------------+
void ApplyPointsTrailing() {
   double point = _Point;                                         //--- Get point
   for (int i = PositionsTotal() - 1; i >= 0; i--) {              //--- Iterate positions
      if (PositionGetTicket(i) > 0) {                             //--- Check ticket
         if (PositionGetString(POSITION_SYMBOL) == _Symbol && PositionGetInteger(POSITION_MAGIC) == UniqueID) { //--- Check symbol magic
            double sl = PositionGetDouble(POSITION_SL);              //--- Get SL
            double tp = PositionGetDouble(POSITION_TP);              //--- Get TP
            double openPrice = PositionGetDouble(POSITION_PRICE_OPEN); //--- Get open
            ulong ticket = PositionGetInteger(POSITION_TICKET);      //--- Get ticket
            if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_BUY) { //--- Check buy
               double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_BID) - Trailing_Stop_Points * point, _Digits); //--- Calc new SL
               if (newSL > sl && SymbolInfoDouble(_Symbol, SYMBOL_BID) - openPrice > Min_Profit_To_Trail_Points * point) { //--- Check conditions
                  obj_Trade.PositionModify(ticket, newSL, tp);       //--- Modify position
               }
            } else if (PositionGetInteger(POSITION_TYPE) == POSITION_TYPE_SELL) { //--- Check sell
               double newSL = NormalizeDouble(SymbolInfoDouble(_Symbol, SYMBOL_ASK) + Trailing_Stop_Points * point, _Digits); //--- Calc new SL
               if (newSL < sl && openPrice - SymbolInfoDouble(_Symbol, SYMBOL_ASK) > Min_Profit_To_Trail_Points * point) { //--- Check conditions
                  obj_Trade.PositionModify(ticket, newSL, tp);       //--- Modify position
               }
            }
         }
      }
   }
}
//+------------------------------------------------------------------+