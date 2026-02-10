//+------------------------------------------------------------------+
//|                                                          ICT.mq5 |
//|                              ICT 2022 Trading Model Expert Advisor|
//|                                           Copyright 2025, Zobad. |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Zobad."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "ICT 2022 Trading Model - Smart Money Concepts EA"
#property description "Features: FVG, Order Blocks, Market Structure, OTE"

#include <Trade/Trade.mqh>

//=============================================================================
// ENUMERATIONS
//=============================================================================
enum ENUM_MARKET_BIAS
{
   BIAS_BULLISH,    // Bullish
   BIAS_BEARISH,    // Bearish
   BIAS_NEUTRAL     // Neutral
};

enum ENUM_TRADE_MODE
{
   MODE_AUTO,       // Automatic Trading
   MODE_MANUAL,     // Manual (Alerts Only)
   MODE_VISUAL      // Visual Only (No Alerts)
};

enum ENUM_KILLZONE
{
   KZ_LONDON,       // London Only
   KZ_NEWYORK,      // New York Only
   KZ_BOTH,         // Both Sessions
   KZ_ANYTIME       // 24/7 Trading
};

enum ENUM_STRUCTURE
{
   STRUCTURE_BULLISH,   // Bullish Structure
   STRUCTURE_BEARISH,   // Bearish Structure
   STRUCTURE_RANGING    // Ranging/Consolidation
};

//=============================================================================
// TRADE SETTINGS (Top Priority - Most Frequently Adjusted)
//=============================================================================
input group "=== POSITION SIZING ==="
input double FixedLotSize = 0.01;           // Fixed Lot Size
input double RiskPercent = 1.0;             // Risk Per Trade (%)
input bool UseFixedLot = true;              // Use Fixed Lot (false = use Risk %)

input group "=== STOP LOSS & TAKE PROFIT ==="
input double MinRiskReward = 2.0;           // Minimum Risk:Reward Ratio
input int StopLossBuffer = 10;              // SL Buffer (points beyond OB/swing)
input bool UsePartialTP = true;             // Enable Partial Take Profit
input double PartialTPPercent = 50.0;       // Partial TP Size (%)
input double PartialTPRatio = 1.0;          // Partial TP at R:R
input bool MoveToBreakeven = true;          // Move SL to Breakeven after Partial TP
input bool UseTrailingStop = false;         // Enable Trailing Stop
input int TrailingStopPoints = 200;         // Trailing Stop Distance (points)

input group "=== TRADE LIMITS ==="
input int MaxTradesPerDay = 2;              // Max Trades Per Day
input int MaxOpenTrades = 1;                // Max Concurrent Open Trades
input double MaxDailyDrawdown = 3.0;        // Max Daily Drawdown (%)

//=============================================================================
// TRADING MODE & TIMING
//=============================================================================
input group "=== TRADING MODE ==="
input ENUM_TRADE_MODE TradeMode = MODE_AUTO;  // Trading Mode
input bool TradeLongOnly = false;             // Trade Long Only
input bool TradeShortOnly = false;            // Trade Short Only

input group "=== KILL ZONES (Time in EST) ==="
input ENUM_KILLZONE KillZone = KZ_BOTH;       // Active Kill Zone
input int LondonStartHour = 2;                // London Start Hour (EST)
input int LondonEndHour = 5;                  // London End Hour (EST)
input int NYStartHour = 8;                    // NY Start Hour (EST)
input int NYEndHour = 11;                     // NY End Hour (EST)
input int BrokerGMTOffset = 2;                // Broker GMT Offset

//=============================================================================
// CONFIGURATION SETTINGS (Less Frequently Changed)
//=============================================================================
input group "=== TIMEFRAME SETTINGS ==="
input ENUM_TIMEFRAMES HTF_Bias = PERIOD_H4;   // Higher TF for Bias
input ENUM_TIMEFRAMES LTF_Entry = PERIOD_M5;  // Lower TF for Entry

input group "=== FVG DETECTION ==="
input double MinFVGSizePoints = 50;           // Minimum FVG Size (points)
input bool RequireDisplacement = true;        // Require Displacement for FVG
input int MaxFVGAgeBars = 100;                // Max FVG Age (bars)

input group "=== ORDER BLOCK DETECTION ==="
input int SwingStrength = 3;                  // Swing Detection Strength
input int MaxOBAgeBars = 100;                 // Max Order Block Age (bars)
input bool RequireFVGConfirmation = true;     // OB Requires FVG Confirmation

input group "=== LIQUIDITY SETTINGS ==="
input bool UsePDHighLow = true;               // Use Previous Day High/Low
input bool UseSessionHighLow = true;          // Use Session High/Low
input int MinSweepWickPoints = 20;            // Min Sweep Wick Size (points)

input group "=== OTE ZONE ==="
input double OTE_Start = 0.618;               // OTE Start (Fib Level)
input double OTE_End = 0.79;                  // OTE End (Fib Level)

//=============================================================================
// VISUAL & ALERT SETTINGS (Bottom - Least Critical)
//=============================================================================
input group "=== VISUAL SETTINGS ==="
input bool CleanChartMode = true;             // Clean ICT Style (minimal lines only)
input bool OnlyShowBiasAligned = true;        // Only show elements aligned with HTF bias
input int MaxVisibleFVGs = 3;                 // Max FVGs to show on chart (0 = unlimited)
input bool DrawFVG = true;                    // Draw FVG
input bool DrawOrderBlocks = false;           // Draw Order Blocks
input bool DrawLiquidity = false;             // Draw Liquidity Swing Points
input bool DrawOTEZone = false;               // Draw OTE Zones
input bool DrawKillZones = true;              // Draw Kill Zone Vertical Lines
input bool DrawSweepMarkers = false;          // Draw Sweep Arrows
input color BullishColor = clrLime;           // Bullish Elements Color
input color BearishColor = clrRed;            // Bearish Elements Color
input color PDHighColor = clrGold;            // Previous Day High Color
input color PDLowColor = clrMagenta;          // Previous Day Low Color
input color LondonKZColor = clrDodgerBlue;    // London Kill Zone Color
input color NYKZColor = clrOrangeRed;         // New York Kill Zone Color
input color MSSColor = clrYellow;             // MSS/CHoCH Marker Color

input group "=== ALERTS ==="
input bool EnableAlerts = true;               // Enable MT5 Popup Alerts
input bool EnablePushNotification = true;     // Enable Push Notifications
input bool EnableEmailAlert = false;          // Enable Email Alerts
input bool EnableSoundAlert = true;           // Enable Sound Alerts
input string AlertSoundFile = "alert.wav";    // Alert Sound File

input group "=== DASHBOARD ==="
input bool ShowDashboard = true;              // Show Info Dashboard
input int DashboardX = 10;                    // Dashboard X Position
input int DashboardY = 30;                    // Dashboard Y Position
input color DashboardTextColor = clrWhite;    // Dashboard Text Color
input int DashboardFontSize = 10;             // Dashboard Font Size

//=============================================================================
// DATA STRUCTURES
//=============================================================================
struct SwingPoint
{
   datetime time;
   double   price;
   bool     isHigh;
   int      barIndex;
};

struct FairValueGap
{
   datetime time;
   double   high;
   double   low;
   bool     isBullish;
   bool     isMitigated;
   int      barIndex;
   string   objName;
};

struct OrderBlock
{
   datetime time;
   double   high;
   double   low;
   bool     isBullish;
   bool     isValid;
   bool     isMitigated;
   int      barIndex;
   string   objName;
};

struct LiquidityLevel
{
   double   price;
   datetime time;
   bool     isHigh;
   bool     isSwept;
   string   objName;
};

struct SessionData
{
   double   high;
   double   low;
   datetime startTime;
   datetime endTime;
   bool     isActive;
};

struct TradeSetup
{
   bool           isValid;
   bool           isBuy;
   double         entryPrice;
   double         stopLoss;
   double         takeProfit;
   double         riskReward;
   string         reason;
   datetime       signalTime;
};

//=============================================================================
// GLOBAL VARIABLES
//=============================================================================
CTrade Trade;

// Arrays for storing detected patterns
SwingPoint     SwingHighs[];
SwingPoint     SwingLows[];
FairValueGap   FVGs[];
OrderBlock     OrderBlocks[];
LiquidityLevel LiquidityLevels[];

// Session data
SessionData    LondonSession;
SessionData    NYSession;
double         PDHigh = 0;
double         PDLow = 0;
datetime       PDDate = 0;

// Market state
ENUM_MARKET_BIAS CurrentBias = BIAS_NEUTRAL;
ENUM_STRUCTURE   HTF_Structure = STRUCTURE_RANGING;
ENUM_STRUCTURE   LTF_Structure = STRUCTURE_RANGING;

// Trade management
int            TradesToday = 0;
datetime       LastTradeDate = 0;
double         DailyStartBalance = 0;
bool           LiquiditySweepDetected = false;
bool           LastSweepWasBullish = false;   // Track sweep direction (bullish = swept lows, bearish = swept highs)
bool           MSSDetected = false;
datetime       LastSweepTime = 0;
datetime       LastMSSTime = 0;
double         LastMSSPrice = 0;          // Price level where MSS/CHoCH occurred
double         LastSweepPrice = 0;        // Price level where sweep occurred
datetime       LastEntryTime = 0;         // Prevent duplicate entries on same signal

// New bar detection
int            prevBars = 0;
int            prevBarsHTF = 0;

// Object naming prefixes
#define PREFIX_FVG      "ICT_FVG_"
#define PREFIX_OB       "ICT_OB_"
#define PREFIX_LIQ      "ICT_LIQ_"
#define PREFIX_OTE      "ICT_OTE_"
#define PREFIX_DASH     "ICT_DASH_"
#define PREFIX_PDH      "ICT_PDH"
#define PREFIX_PDL      "ICT_PDL"
#define PREFIX_SESS     "ICT_SESS_"
#define PREFIX_KZ       "ICT_KZ_"
#define PREFIX_MSS      "ICT_MSS_"
#define PREFIX_SWEEP    "ICT_SWEEP_"

//=============================================================================
// INITIALIZATION
//=============================================================================
int OnInit()
{
   // Initialize trade object
   Trade.SetExpertMagicNumber(123456);
   Trade.SetDeviationInPoints(10);
   Trade.SetTypeFilling(ORDER_FILLING_IOC);

   // Initialize arrays
   ArrayResize(SwingHighs, 0);
   ArrayResize(SwingLows, 0);
   ArrayResize(FVGs, 0);
   ArrayResize(OrderBlocks, 0);
   ArrayResize(LiquidityLevels, 0);

   // Initialize session data
   ResetSessionData(LondonSession);
   ResetSessionData(NYSession);

   // Get previous day high/low
   UpdatePDHighLow();

   // Initialize daily tracking
   DailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   LastTradeDate = TimeCurrent();
   TradesToday = 0;

   // Set timer for periodic updates
   EventSetTimer(60);

   // Initial structure analysis
   HTF_Structure = GetMarketStructure(HTF_Bias);
   LTF_Structure = GetMarketStructure(LTF_Entry);
   UpdateBias();

   // Draw initial elements
   if(ShowDashboard) CreateDashboard();
   if(DrawLiquidity) DrawPDHighLowLines();
   DrawKillZoneLines();

   Print("ICT 2022 EA Initialized - Mode: ", EnumToString(TradeMode),
         " | Kill Zone: ", EnumToString(KillZone),
         " | HTF: ", EnumToString(HTF_Bias),
         " | LTF: ", EnumToString(LTF_Entry));

   return(INIT_SUCCEEDED);
}

//=============================================================================
// DEINITIALIZATION
//=============================================================================
void OnDeinit(const int reason)
{
   EventKillTimer();
   DeleteAllObjects();
   Print("ICT 2022 EA Deinitialized - Reason: ", reason);
}

//=============================================================================
// MAIN TICK FUNCTION
//=============================================================================
void OnTick()
{
   // Check for new bar on LTF
   bool isNewBar = IsNewBar(_Period);
   bool isNewBarHTF = IsNewBar(HTF_Bias);

   // Update HTF analysis on new HTF bar
   if(isNewBarHTF)
   {
      HTF_Structure = GetMarketStructure(HTF_Bias);
      UpdateBias();
   }

   // Main logic on new bar only
   if(!isNewBar)
   {
      // Still manage open trades on every tick
      ManageOpenTrades();
      return;
   }

   // Reset daily counters if new day
   CheckNewDay();

   // Check if we're in a kill zone
   bool inKillZone = IsInKillZone();

   // Update session high/low
   if(UseSessionHighLow) UpdateSessionHighLow();

   // Update previous day high/low if needed
   if(UsePDHighLow) UpdatePDHighLow();

   // Detect market structure on LTF
   LTF_Structure = GetMarketStructure(LTF_Entry);

   // Detect swing points
   DetectSwingPoints();

   // Detect FVGs
   DetectFVGs();

   // Detect Order Blocks
   DetectOrderBlocks();

   // Check FVG/OB mitigation
   CheckMitigation();

   // Detect liquidity sweeps
   if(inKillZone || KillZone == KZ_ANYTIME)
   {
      DetectLiquiditySweeps();
   }

   // Look for trade setups (only in kill zones unless 24/7 mode)
   if(inKillZone || KillZone == KZ_ANYTIME)
   {
      TradeSetup setup = FindTradeSetup();

      if(setup.isValid)
      {
         ProcessTradeSetup(setup);
      }
   }

   // Update visual elements
   if(ShowDashboard) UpdateDashboard();

   // Clean up old objects
   CleanupOldObjects();
}

//=============================================================================
// TIMER FUNCTION
//=============================================================================
void OnTimer()
{
   // Periodic dashboard update
   if(ShowDashboard) UpdateDashboard();
}

//=============================================================================
// UTILITY FUNCTIONS - PRICE DATA ACCESS
//=============================================================================
double High(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return iHigh(_Symbol, tf, index);
}

double Low(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return iLow(_Symbol, tf, index);
}

double Open(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return iOpen(_Symbol, tf, index);
}

double Close(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return iClose(_Symbol, tf, index);
}

datetime Time(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return iTime(_Symbol, tf, index);
}

double Volume(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   return (double)iVolume(_Symbol, tf, index);
}

//=============================================================================
// UTILITY FUNCTIONS - NEW BAR DETECTION
//=============================================================================
bool IsNewBar(ENUM_TIMEFRAMES tf)
{
   static int barCounts[];
   static ENUM_TIMEFRAMES timeframes[];

   int bars = iBars(_Symbol, tf);

   // Find or add timeframe
   int idx = -1;
   for(int i = 0; i < ArraySize(timeframes); i++)
   {
      if(timeframes[i] == tf)
      {
         idx = i;
         break;
      }
   }

   if(idx == -1)
   {
      idx = ArraySize(timeframes);
      ArrayResize(timeframes, idx + 1);
      ArrayResize(barCounts, idx + 1);
      timeframes[idx] = tf;
      barCounts[idx] = bars;
      return true;
   }

   if(barCounts[idx] != bars)
   {
      barCounts[idx] = bars;
      return true;
   }

   return false;
}

//=============================================================================
// TIME MANAGEMENT FUNCTIONS
//=============================================================================
int GetESTHour()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   // Convert broker time to EST
   // Broker is at GMT+BrokerGMTOffset, EST is GMT-5
   // So EST = BrokerTime - BrokerGMTOffset - 5
   // Example: If broker is GMT+2 and it's 15:00 broker time
   // UTC = 15 - 2 = 13:00, EST = 13 - 5 = 8:00 AM EST
   int estHour = dt.hour - BrokerGMTOffset - 5;

   // Handle day wrap
   while(estHour < 0) estHour += 24;
   while(estHour >= 24) estHour -= 24;

   return estHour;
}

bool IsInKillZone()
{
   if(KillZone == KZ_ANYTIME) return true;

   int estHour = GetESTHour();

   bool inLondon = (estHour >= LondonStartHour && estHour < LondonEndHour);
   bool inNY = (estHour >= NYStartHour && estHour < NYEndHour);

   switch(KillZone)
   {
      case KZ_LONDON:  return inLondon;
      case KZ_NEWYORK: return inNY;
      case KZ_BOTH:    return inLondon || inNY;
      default:         return true;
   }
}

string GetCurrentKillZoneName()
{
   if(KillZone == KZ_ANYTIME) return "24/7";

   int estHour = GetESTHour();

   if(estHour >= LondonStartHour && estHour < LondonEndHour) return "London";
   if(estHour >= NYStartHour && estHour < NYEndHour) return "New York";

   return "Outside KZ";
}

//+------------------------------------------------------------------+
//| Get current EST time as formatted string                          |
//+------------------------------------------------------------------+
string GetCurrentESTTimeString()
{
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   // Convert to EST
   int estHour = dt.hour - BrokerGMTOffset - 5;
   int estMin = dt.min;

   // Handle day wrap
   while(estHour < 0) estHour += 24;
   while(estHour >= 24) estHour -= 24;

   // Format as HH:MM with AM/PM
   string ampm = (estHour >= 12) ? "PM" : "AM";
   int displayHour = estHour % 12;
   if(displayHour == 0) displayHour = 12;

   return StringFormat("%02d:%02d %s EST", displayHour, estMin, ampm);
}

//+------------------------------------------------------------------+
//| Calculate time remaining until next kill zone                      |
//+------------------------------------------------------------------+
string GetTimeToNextKillZone()
{
   if(KillZone == KZ_ANYTIME) return "Always Active";

   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   // Get current EST hour and minute
   int estHour = dt.hour - BrokerGMTOffset - 5;
   int estMin = dt.min;

   // Handle day wrap
   while(estHour < 0) estHour += 24;
   while(estHour >= 24) estHour -= 24;

   // Check if we're already in a kill zone
   bool inLondon = (estHour >= LondonStartHour && estHour < LondonEndHour);
   bool inNY = (estHour >= NYStartHour && estHour < NYEndHour);

   if((KillZone == KZ_LONDON && inLondon) ||
      (KillZone == KZ_NEWYORK && inNY) ||
      (KillZone == KZ_BOTH && (inLondon || inNY)))
   {
      // Calculate time remaining in current KZ
      int kzEndHour = inLondon ? LondonEndHour : NYEndHour;
      int hoursLeft = kzEndHour - estHour - 1;
      int minsLeft = 60 - estMin;
      if(minsLeft == 60) { minsLeft = 0; hoursLeft++; }

      string kzName = inLondon ? "London" : "NY";
      return StringFormat("%s ends in %dh %dm", kzName, hoursLeft, minsLeft);
   }

   // Calculate time to next kill zone
   int nextKZHour = 0;
   string nextKZName = "";

   // Determine which KZ is next based on settings and current time
   if(KillZone == KZ_LONDON)
   {
      nextKZHour = LondonStartHour;
      nextKZName = "London";
   }
   else if(KillZone == KZ_NEWYORK)
   {
      nextKZHour = NYStartHour;
      nextKZName = "NY";
   }
   else // KZ_BOTH - find the nearest upcoming KZ
   {
      // After NY ends, next is London
      if(estHour >= NYEndHour || estHour < LondonStartHour)
      {
         nextKZHour = LondonStartHour;
         nextKZName = "London";
      }
      // After London ends but before NY starts
      else if(estHour >= LondonEndHour && estHour < NYStartHour)
      {
         nextKZHour = NYStartHour;
         nextKZName = "NY";
      }
   }

   // Calculate hours and minutes until next KZ
   int hoursUntil = nextKZHour - estHour;
   int minsUntil = 60 - estMin;
   if(minsUntil == 60) { minsUntil = 0; }
   else { hoursUntil--; }

   // Handle wrap to next day
   if(hoursUntil < 0) hoursUntil += 24;

   return StringFormat("%s in %dh %dm", nextKZName, hoursUntil, minsUntil);
}

void ResetSessionData(SessionData &session)
{
   session.high = 0;
   session.low = DBL_MAX;
   session.startTime = 0;
   session.endTime = 0;
   session.isActive = false;
}

void UpdateSessionHighLow()
{
   string kzName = GetCurrentKillZoneName();

   if(kzName == "London" || kzName == "New York" || kzName == "24/7")
   {
      double h = High(1);
      double l = Low(1);

      bool isLondon = (kzName == "London");

      if(isLondon)
      {
         if(!LondonSession.isActive)
         {
            LondonSession.isActive = true;
            LondonSession.startTime = Time(1);
            LondonSession.high = h;
            LondonSession.low = l;
         }
         else
         {
            if(h > LondonSession.high) LondonSession.high = h;
            if(l < LondonSession.low) LondonSession.low = l;
         }

         // Draw session lines
         if(DrawLiquidity)
         {
            string prefix = PREFIX_SESS + kzName;
            DrawHorizontalLine(prefix + "_High", LondonSession.high, clrAqua, STYLE_DOT);
            DrawHorizontalLine(prefix + "_Low", LondonSession.low, clrAqua, STYLE_DOT);
         }
      }
      else // New York or 24/7
      {
         if(!NYSession.isActive)
         {
            NYSession.isActive = true;
            NYSession.startTime = Time(1);
            NYSession.high = h;
            NYSession.low = l;
         }
         else
         {
            if(h > NYSession.high) NYSession.high = h;
            if(l < NYSession.low) NYSession.low = l;
         }

         // Draw session lines
         if(DrawLiquidity)
         {
            string prefix = PREFIX_SESS + kzName;
            DrawHorizontalLine(prefix + "_High", NYSession.high, clrAqua, STYLE_DOT);
            DrawHorizontalLine(prefix + "_Low", NYSession.low, clrAqua, STYLE_DOT);
         }
      }
   }
   else
   {
      // Reset sessions when outside kill zones
      if(LondonSession.isActive) ResetSessionData(LondonSession);
      if(NYSession.isActive) ResetSessionData(NYSession);
   }
}

void UpdatePDHighLow()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   datetime todayStart = StructToTime(dt);

   // Only update once per day (but force update if values are invalid)
   if(PDDate == todayStart && PDHigh > 0 && PDLow > 0 && PDLow < PDHigh) return;

   // Get yesterday's daily bar (index 1 = yesterday on D1)
   // Make sure we have enough D1 bars
   int d1Bars = iBars(_Symbol, PERIOD_D1);
   if(d1Bars < 2)
   {
      Print("Not enough D1 bars: ", d1Bars);
      return;
   }

   // Use CopyHigh/CopyLow for more reliable data access
   double highArr[], lowArr[];
   if(CopyHigh(_Symbol, PERIOD_D1, 1, 1, highArr) <= 0 ||
      CopyLow(_Symbol, PERIOD_D1, 1, 1, lowArr) <= 0)
   {
      Print("Failed to copy D1 data for PDH/PDL");
      return;
   }

   PDHigh = highArr[0];
   PDLow = lowArr[0];
   PDDate = todayStart;

   // Validate the data
   if(PDHigh <= 0 || PDLow <= 0 || PDLow >= PDHigh)
   {
      Print("Invalid PDH/PDL data: PDH=", PDHigh, " PDL=", PDLow);
      return;
   }

   if(DrawLiquidity) DrawPDHighLowLines();

   Print("PDH: ", DoubleToString(PDHigh, _Digits), " | PDL: ", DoubleToString(PDLow, _Digits));
}

void DrawPDHighLowLines()
{
   if(PDHigh > 0)
   {
      DrawHorizontalLine(PREFIX_PDH, PDHigh, PDHighColor, STYLE_DASH);
      // Add label for PDH
      string labelPDH = PREFIX_PDH + "_Label";
      if(ObjectFind(0, labelPDH) < 0)
      {
         ObjectCreate(0, labelPDH, OBJ_TEXT, 0, Time(0), PDHigh);
         ObjectSetString(0, labelPDH, OBJPROP_TEXT, "PDH");
         ObjectSetInteger(0, labelPDH, OBJPROP_COLOR, PDHighColor);
         ObjectSetInteger(0, labelPDH, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, labelPDH, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      }
      else
      {
         ObjectSetDouble(0, labelPDH, OBJPROP_PRICE, PDHigh);
         ObjectSetInteger(0, labelPDH, OBJPROP_TIME, Time(0));
      }
   }

   if(PDLow > 0)
   {
      DrawHorizontalLine(PREFIX_PDL, PDLow, PDLowColor, STYLE_DASH);
      // Add label for PDL
      string labelPDL = PREFIX_PDL + "_Label";
      if(ObjectFind(0, labelPDL) < 0)
      {
         ObjectCreate(0, labelPDL, OBJ_TEXT, 0, Time(0), PDLow);
         ObjectSetString(0, labelPDL, OBJPROP_TEXT, "PDL");
         ObjectSetInteger(0, labelPDL, OBJPROP_COLOR, PDLowColor);
         ObjectSetInteger(0, labelPDL, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, labelPDL, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      }
      else
      {
         ObjectSetDouble(0, labelPDL, OBJPROP_PRICE, PDLow);
         ObjectSetInteger(0, labelPDL, OBJPROP_TIME, Time(0));
      }
   }
}

//+------------------------------------------------------------------+
//| Draw vertical lines for kill zone boundaries                      |
//+------------------------------------------------------------------+
void DrawKillZoneLines()
{
   if(!DrawKillZones || KillZone == KZ_ANYTIME) return;

   // Get current broker time
   datetime serverTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   // Set to start of today (broker time)
   dt.hour = 0;
   dt.min = 0;
   dt.sec = 0;
   datetime todayStart = StructToTime(dt);

   // Calculate EST offset from broker time
   // Broker is at GMT+BrokerGMTOffset, EST is GMT-5
   // estHour = brokerHour - BrokerGMTOffset - 5
   // So brokerHour = estHour + BrokerGMTOffset + 5
   int offsetHours = BrokerGMTOffset + 5;

   // Draw London KZ lines (2-5 AM EST)
   if(KillZone == KZ_LONDON || KillZone == KZ_BOTH)
   {
      int londonStartBroker = LondonStartHour + offsetHours;
      int londonEndBroker = LondonEndHour + offsetHours;

      // Handle day wrap
      datetime londonStart = todayStart + londonStartBroker * 3600;
      datetime londonEnd = todayStart + londonEndBroker * 3600;

      // If the broker hour wrapped to next day, lines will be in the future - that's OK
      // If they wrapped to previous day, adjust
      if(londonStartBroker < 0)
      {
         londonStart = todayStart + (londonStartBroker + 24) * 3600 - 86400; // Previous day
      }
      if(londonEndBroker < 0)
      {
         londonEnd = todayStart + (londonEndBroker + 24) * 3600 - 86400;
      }

      DrawVerticalLine(PREFIX_KZ + "London_Start", londonStart, LondonKZColor, STYLE_DOT);
      DrawVerticalLine(PREFIX_KZ + "London_End", londonEnd, LondonKZColor, STYLE_DOT);
   }

   // Draw NY KZ lines (8-11 AM EST)
   if(KillZone == KZ_NEWYORK || KillZone == KZ_BOTH)
   {
      int nyStartBroker = NYStartHour + offsetHours;
      int nyEndBroker = NYEndHour + offsetHours;

      datetime nyStart = todayStart + nyStartBroker * 3600;
      datetime nyEnd = todayStart + nyEndBroker * 3600;

      // Handle day wrap for brokers with negative offsets
      if(nyStartBroker >= 24)
      {
         nyStart = todayStart + (nyStartBroker - 24) * 3600 + 86400; // Next day
      }
      if(nyEndBroker >= 24)
      {
         nyEnd = todayStart + (nyEndBroker - 24) * 3600 + 86400;
      }

      DrawVerticalLine(PREFIX_KZ + "NY_Start", nyStart, NYKZColor, STYLE_DOT);
      DrawVerticalLine(PREFIX_KZ + "NY_End", nyEnd, NYKZColor, STYLE_DOT);
   }
}

void CheckNewDay()
{
   MqlDateTime dtNow, dtLast;
   TimeToStruct(TimeCurrent(), dtNow);
   TimeToStruct(LastTradeDate, dtLast);

   if(dtNow.day != dtLast.day || dtNow.mon != dtLast.mon || dtNow.year != dtLast.year)
   {
      TradesToday = 0;
      DailyStartBalance = AccountInfoDouble(ACCOUNT_BALANCE);
      LastTradeDate = TimeCurrent();

      // Reset sessions
      ResetSessionData(LondonSession);
      ResetSessionData(NYSession);

      // Redraw kill zone lines for new day
      ObjectsDeleteAll(0, PREFIX_KZ);
      DrawKillZoneLines();

      Print("New trading day - Counters reset");
   }
}

//=============================================================================
// MARKET STRUCTURE FUNCTIONS
//=============================================================================

// Structure to hold swing point with time for proper sequencing
struct SwingPointData
{
   double   price;
   int      barIndex;
   datetime time;
};

ENUM_STRUCTURE GetMarketStructure(ENUM_TIMEFRAMES tf)
{
   int lookback = 50;

   // Find recent swing points with their bar indices
   // We need at least 4 swing points (2 highs, 2 lows) to determine structure
   SwingPointData swingHighs[4], swingLows[4];
   int shCount = 0, slCount = 0;

   // Iterate from most recent bar to older bars
   // Index 0 = most recent swing found, Index 1 = second most recent, etc.
   for(int i = SwingStrength; i < lookback && (shCount < 4 || slCount < 4); i++)
   {
      if(IsSwingHigh(i, tf) && shCount < 4)
      {
         swingHighs[shCount].price = High(i, tf);
         swingHighs[shCount].barIndex = i;
         swingHighs[shCount].time = Time(i, tf);
         shCount++;
      }
      if(IsSwingLow(i, tf) && slCount < 4)
      {
         swingLows[slCount].price = Low(i, tf);
         swingLows[slCount].barIndex = i;
         swingLows[slCount].time = Time(i, tf);
         slCount++;
      }
   }

   // Need at least 2 highs and 2 lows to determine structure
   if(shCount < 2 || slCount < 2) return STRUCTURE_RANGING;

   // swingHighs[0] = most recent swing high (smaller bar index = more recent)
   // swingHighs[1] = second most recent swing high
   // Compare: most recent vs second most recent

   // For BULLISH structure: Most recent high > Previous high AND Most recent low > Previous low
   // This means price is making HH + HL
   bool higherHigh = swingHighs[0].price > swingHighs[1].price;
   bool higherLow = swingLows[0].price > swingLows[1].price;

   // For BEARISH structure: Most recent high < Previous high AND Most recent low < Previous low
   // This means price is making LH + LL
   bool lowerHigh = swingHighs[0].price < swingHighs[1].price;
   bool lowerLow = swingLows[0].price < swingLows[1].price;

   // Additional validation: Ensure the sequence makes sense
   // For bullish: the higher low should come after the previous low was formed
   // For bearish: the lower high should come after the previous high was formed

   if(higherHigh && higherLow)
   {
      // Validate bullish sequence: Recent HL should be after (lower bar index) the previous H
      // This ensures we have: Previous High formed -> Pullback to Higher Low -> New Higher High
      if(swingLows[0].barIndex < swingHighs[1].barIndex)
      {
         return STRUCTURE_BULLISH;
      }
   }

   if(lowerHigh && lowerLow)
   {
      // Validate bearish sequence: Recent LH should be after (lower bar index) the previous L
      // This ensures we have: Previous Low formed -> Rally to Lower High -> New Lower Low
      if(swingHighs[0].barIndex < swingLows[1].barIndex)
      {
         return STRUCTURE_BEARISH;
      }
   }

   // If we have mixed signals (HH+LL or LH+HL) or invalid sequence, market is ranging/consolidating
   return STRUCTURE_RANGING;
}

bool IsSwingHigh(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   double high = High(index, tf);

   for(int i = 1; i <= SwingStrength; i++)
   {
      if(High(index - i, tf) >= high || High(index + i, tf) >= high)
         return false;
   }
   return true;
}

bool IsSwingLow(int index, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   double low = Low(index, tf);

   for(int i = 1; i <= SwingStrength; i++)
   {
      if(Low(index - i, tf) <= low || Low(index + i, tf) <= low)
         return false;
   }
   return true;
}

void DetectSwingPoints()
{
   // Check for new swing high
   if(IsSwingHigh(SwingStrength + 1))
   {
      SwingPoint sp;
      sp.time = Time(SwingStrength + 1);
      sp.price = High(SwingStrength + 1);
      sp.isHigh = true;
      sp.barIndex = SwingStrength + 1;

      // Check if already exists
      bool exists = false;
      for(int i = 0; i < ArraySize(SwingHighs); i++)
      {
         if(SwingHighs[i].time == sp.time) { exists = true; break; }
      }

      if(!exists)
      {
         int size = ArraySize(SwingHighs);
         ArrayResize(SwingHighs, size + 1);
         SwingHighs[size] = sp;

         // Add as liquidity level
         AddLiquidityLevel(sp.price, sp.time, true);
      }
   }

   // Check for new swing low
   if(IsSwingLow(SwingStrength + 1))
   {
      SwingPoint sp;
      sp.time = Time(SwingStrength + 1);
      sp.price = Low(SwingStrength + 1);
      sp.isHigh = false;
      sp.barIndex = SwingStrength + 1;

      bool exists = false;
      for(int i = 0; i < ArraySize(SwingLows); i++)
      {
         if(SwingLows[i].time == sp.time) { exists = true; break; }
      }

      if(!exists)
      {
         int size = ArraySize(SwingLows);
         ArrayResize(SwingLows, size + 1);
         SwingLows[size] = sp;

         // Add as liquidity level
         AddLiquidityLevel(sp.price, sp.time, false);
      }
   }
}

void UpdateBias()
{
   ENUM_MARKET_BIAS previousBias = CurrentBias;

   if(HTF_Structure == STRUCTURE_BULLISH)
      CurrentBias = BIAS_BULLISH;
   else if(HTF_Structure == STRUCTURE_BEARISH)
      CurrentBias = BIAS_BEARISH;
   else
      CurrentBias = BIAS_NEUTRAL;

   // Log bias changes and refresh visuals
   if(previousBias != CurrentBias)
   {
      string biasStr = (CurrentBias == BIAS_BULLISH) ? "BULLISH" :
                       (CurrentBias == BIAS_BEARISH) ? "BEARISH" : "NEUTRAL";
      Print("HTF Bias Changed to: ", biasStr, " on ", EnumToString(HTF_Bias));

      // Refresh FVG visuals to show only bias-aligned elements
      if(OnlyShowBiasAligned)
      {
         RefreshFVGVisuals();
      }
   }
}

bool DetectBOS(bool bullish, ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   // Break of Structure - price breaks previous swing in direction of trend
   // Find the swing points on the specified timeframe
   double prevSwingHigh = 0, prevPrevSwingHigh = 0;
   double prevSwingLow = DBL_MAX, prevPrevSwingLow = DBL_MAX;
   int highCount = 0, lowCount = 0;

   for(int i = SwingStrength; i < 50 && (highCount < 2 || lowCount < 2); i++)
   {
      if(IsSwingHigh(i, tf) && highCount < 2)
      {
         if(highCount == 0) prevSwingHigh = High(i, tf);
         else prevPrevSwingHigh = High(i, tf);
         highCount++;
      }
      if(IsSwingLow(i, tf) && lowCount < 2)
      {
         if(lowCount == 0) prevSwingLow = Low(i, tf);
         else prevPrevSwingLow = Low(i, tf);
         lowCount++;
      }
   }

   if(highCount < 2 || lowCount < 2) return false;

   double currentClose = Close(1, tf);

   if(bullish)
   {
      // Bullish BOS - close above the second most recent swing high (breaking structure)
      return currentClose > prevPrevSwingHigh;
   }
   else
   {
      // Bearish BOS - close below the second most recent swing low (breaking structure)
      return currentClose < prevPrevSwingLow;
   }
}

// Global variable to track the direction of the last detected CHoCH
bool LastCHoCHWasBullish = false;

bool DetectCHoCH(ENUM_TIMEFRAMES tf = PERIOD_CURRENT)
{
   // Change of Character (CHoCH) / Market Structure Shift (MSS)
   // This is when price breaks structure AGAINST the current trend
   // It signals a potential reversal

   // Get structure for the specified timeframe
   ENUM_STRUCTURE currentStructure = GetMarketStructure(tf);

   if(currentStructure == STRUCTURE_RANGING) return false;

   // Find the most recent swing point that would indicate CHoCH
   double recentSwingHigh = 0, recentSwingLow = DBL_MAX;
   int recentHighBar = -1, recentLowBar = -1;

   for(int i = SwingStrength; i < 30; i++)
   {
      if(IsSwingHigh(i, tf) && recentHighBar == -1)
      {
         recentSwingHigh = High(i, tf);
         recentHighBar = i;
      }
      if(IsSwingLow(i, tf) && recentLowBar == -1)
      {
         recentSwingLow = Low(i, tf);
         recentLowBar = i;
      }
      if(recentHighBar >= 0 && recentLowBar >= 0) break;
   }

   double currentClose = Close(1, tf);
   double currentLow = Low(1, tf);
   double currentHigh = High(1, tf);

   if(currentStructure == STRUCTURE_BULLISH)
   {
      // CHoCH from bullish to bearish:
      // Price closes below the most recent swing low
      // This breaks the bullish structure (was making higher lows, now made lower low)
      if(recentLowBar >= 0 && currentClose < recentSwingLow)
      {
         // Additional confirmation: the break should be impulsive (not just a wick)
         double breakSize = (recentSwingLow - currentClose) / _Point;
         if(breakSize >= MinFVGSizePoints * 0.3) // At least 30% of FVG size for valid break
         {
            LastCHoCHWasBullish = false; // CHoCH indicates bearish reversal
            LastMSSPrice = recentSwingLow; // The broken level is the MSS price
            return true;
         }
      }
   }
   else if(currentStructure == STRUCTURE_BEARISH)
   {
      // CHoCH from bearish to bullish:
      // Price closes above the most recent swing high
      // This breaks the bearish structure (was making lower highs, now made higher high)
      if(recentHighBar >= 0 && currentClose > recentSwingHigh)
      {
         // Additional confirmation: the break should be impulsive
         double breakSize = (currentClose - recentSwingHigh) / _Point;
         if(breakSize >= MinFVGSizePoints * 0.3)
         {
            LastCHoCHWasBullish = true; // CHoCH indicates bullish reversal
            LastMSSPrice = recentSwingHigh; // The broken level is the MSS price
            return true;
         }
      }
   }

   return false;
}

// Helper function to check if the CHoCH aligns with HTF bias
bool IsCHoCHAlignedWithBias()
{
   // For a valid ICT setup:
   // - If HTF bias is bullish, we want a bullish CHoCH on LTF (reversal from bearish to bullish)
   // - If HTF bias is bearish, we want a bearish CHoCH on LTF (reversal from bullish to bearish)
   if(CurrentBias == BIAS_BULLISH && LastCHoCHWasBullish) return true;
   if(CurrentBias == BIAS_BEARISH && !LastCHoCHWasBullish) return true;
   return false;
}

// Helper function to check if the sweep aligns with HTF bias
bool IsSweepAlignedWithBias()
{
   // ICT Concept: Sweep direction should align with intended trade direction
   // - Bullish sweep (swept lows) = looking for long entries (aligns with bullish bias)
   // - Bearish sweep (swept highs) = looking for short entries (aligns with bearish bias)
   if(CurrentBias == BIAS_BULLISH && LastSweepWasBullish) return true;
   if(CurrentBias == BIAS_BEARISH && !LastSweepWasBullish) return true;
   return false;
}

// Helper function to check if FVG direction aligns with sweep
bool IsFVGAlignedWithSweep(bool fvgIsBullish)
{
   // After a bullish sweep (took out lows), we want bullish FVG for long entry
   // After a bearish sweep (took out highs), we want bearish FVG for short entry
   if(LastSweepWasBullish && fvgIsBullish) return true;
   if(!LastSweepWasBullish && !fvgIsBullish) return true;
   return false;
}

//=============================================================================
// FVG DETECTION FUNCTIONS
//=============================================================================
void DetectFVGs()
{
   // Check for FVG at bar index 2 (completed 3-candle pattern)
   // Bar indices: 3 = oldest (candle 1), 2 = middle (candle 2), 1 = newest (candle 3)
   // We check at index 2 to ensure candle 3 is complete

   int candle1 = 3;  // Oldest candle in the pattern
   int candle2 = 2;  // Middle candle (displacement candle)
   int candle3 = 1;  // Newest candle in the pattern

   // =========================================================================
   // BULLISH FVG: Gap below the middle candle
   // Condition: Low of candle 3 > High of candle 1 (gap between them)
   // The middle candle should be bullish (upward displacement)
   // =========================================================================
   double c1High = High(candle1);
   double c3Low = Low(candle3);

   if(c3Low > c1High)
   {
      double gapSize = (c3Low - c1High) / _Point;

      if(gapSize >= MinFVGSizePoints)
      {
         // Check if displacement requirement met (middle candle should be bullish and strong)
         bool hasDisplacement = true;
         if(RequireDisplacement)
         {
            // Middle candle must be bullish for bullish FVG
            bool isBullishMiddle = Close(candle2) > Open(candle2);
            double bodySize = MathAbs(Close(candle2) - Open(candle2)) / _Point;
            hasDisplacement = isBullishMiddle && bodySize > MinFVGSizePoints * 0.5;
         }

         if(hasDisplacement)
         {
            // FVG zone: from top of candle 1 (c1High) to bottom of candle 3 (c3Low)
            AddFVG(Time(candle2), c3Low, c1High, true, candle2);
         }
      }
   }

   // =========================================================================
   // BEARISH FVG: Gap above the middle candle
   // Condition: High of candle 3 < Low of candle 1 (gap between them)
   // The middle candle should be bearish (downward displacement)
   // =========================================================================
   double c1Low = Low(candle1);
   double c3High = High(candle3);

   if(c3High < c1Low)
   {
      double gapSize = (c1Low - c3High) / _Point;

      if(gapSize >= MinFVGSizePoints)
      {
         bool hasDisplacement = true;
         if(RequireDisplacement)
         {
            // Middle candle must be bearish for bearish FVG
            bool isBearishMiddle = Close(candle2) < Open(candle2);
            double bodySize = MathAbs(Close(candle2) - Open(candle2)) / _Point;
            hasDisplacement = isBearishMiddle && bodySize > MinFVGSizePoints * 0.5;
         }

         if(hasDisplacement)
         {
            // FVG zone: from bottom of candle 1 (c1Low) to top of candle 3 (c3High)
            AddFVG(Time(candle2), c1Low, c3High, false, candle2);
         }
      }
   }
}

void AddFVG(datetime time, double high, double low, bool bullish, int barIndex)
{
   // Check if FVG already exists at this time
   for(int i = 0; i < ArraySize(FVGs); i++)
   {
      if(FVGs[i].time == time) return;
   }

   FairValueGap fvg;
   fvg.time = time;
   fvg.high = high;
   fvg.low = low;
   fvg.isBullish = bullish;
   fvg.isMitigated = false;
   fvg.barIndex = barIndex;
   fvg.objName = PREFIX_FVG + TimeToString(time);

   int size = ArraySize(FVGs);
   ArrayResize(FVGs, size + 1);
   FVGs[size] = fvg;

   // Refresh all FVG visuals to respect MaxVisibleFVGs limit and bias filtering
   RefreshFVGVisuals();

   Print("FVG Detected - ", (bullish ? "Bullish" : "Bearish"),
         " | High: ", high, " | Low: ", low);
}

void DrawFVGRectangle(FairValueGap &fvg)
{
   color clr = fvg.isBullish ? BullishColor : BearishColor;
   datetime time2 = Time(0) + PeriodSeconds() * 20; // Extend into future

   if(CleanChartMode)
   {
      // Clean ICT mode: Just draw one horizontal line at the FVG midpoint (CE)
      // This represents the "Consequent Encroachment" level where price often reacts
      string midLine = fvg.objName + "_Mid";
      double midPrice = (fvg.high + fvg.low) / 2;

      ObjectCreate(0, midLine, OBJ_TREND, 0, fvg.time, midPrice, time2, midPrice);
      ObjectSetInteger(0, midLine, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, midLine, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, midLine, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, midLine, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, midLine, OBJPROP_BACK, true);
   }
   else
   {
      // Standard mode: Filled rectangle
      ObjectCreate(0, fvg.objName, OBJ_RECTANGLE, 0, fvg.time, fvg.high, time2, fvg.low);
      ObjectSetInteger(0, fvg.objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, fvg.objName, OBJPROP_FILL, true);
      ObjectSetInteger(0, fvg.objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, fvg.objName, OBJPROP_WIDTH, 1);

      string label = fvg.objName + "_Label";
      ObjectCreate(0, label, OBJ_TEXT, 0, fvg.time, (fvg.high + fvg.low) / 2);
      ObjectSetString(0, label, OBJPROP_TEXT, fvg.isBullish ? "FVG+" : "FVG-");
      ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 8);
   }
}

//+------------------------------------------------------------------+
//| Refresh FVG visuals based on current bias                        |
//| Called when bias changes to show only aligned FVGs               |
//+------------------------------------------------------------------+
void RefreshFVGVisuals()
{
   // First, delete all existing FVG objects
   ObjectsDeleteAll(0, PREFIX_FVG);

   if(!DrawFVG) return;

   // Count how many FVGs we should display
   int displayCount = 0;
   int maxToShow = (MaxVisibleFVGs > 0) ? MaxVisibleFVGs : 999;

   // Go through FVGs from newest to oldest (array is ordered oldest first, so reverse)
   for(int i = ArraySize(FVGs) - 1; i >= 0 && displayCount < maxToShow; i--)
   {
      if(FVGs[i].isMitigated) continue;

      bool shouldDraw = true;
      if(OnlyShowBiasAligned)
      {
         // Only draw if FVG direction matches HTF bias
         if(CurrentBias == BIAS_BULLISH && !FVGs[i].isBullish) shouldDraw = false;
         if(CurrentBias == BIAS_BEARISH && FVGs[i].isBullish) shouldDraw = false;
         if(CurrentBias == BIAS_NEUTRAL) shouldDraw = false;
      }

      if(shouldDraw)
      {
         DrawFVGRectangle(FVGs[i]);
         displayCount++;
      }
   }
}

//=============================================================================
// ORDER BLOCK DETECTION FUNCTIONS
//=============================================================================
// ICT Order Block Definition:
// - Bullish OB: The LAST bearish (down) candle BEFORE an impulsive bullish move
// - Bearish OB: The LAST bullish (up) candle BEFORE an impulsive bearish move
// - The displacement move should create an FVG for valid OB
// - Bar index: higher = older, lower = more recent
// - So if OB is at index i, displacement should be at index i-1 (more recent)
//=============================================================================

void DetectOrderBlocks()
{
   // Look for order blocks - we need at least 2 bars of history
   // Check if there's a displacement move and mark the candle before it as OB

   for(int i = 2; i < 20; i++)
   {
      // =====================================================================
      // BULLISH ORDER BLOCK
      // Pattern: Bearish candle at [i] followed by bullish displacement at [i-1]
      // The bearish candle at [i] becomes the bullish OB (support zone)
      // =====================================================================
      if(IsBearishCandle(i) && IsBullishDisplacement(i-1))
      {
         // Additional validation: The displacement should break above the OB high
         bool validBreak = High(i-1) > High(i);

         // Verify with FVG if required
         bool hasFVG = !RequireFVGConfirmation || HasFVGNear(Time(i-1), true);

         if(validBreak && hasFVG)
         {
            AddOrderBlock(Time(i), High(i), Low(i), true, i);
         }
      }

      // =====================================================================
      // BEARISH ORDER BLOCK
      // Pattern: Bullish candle at [i] followed by bearish displacement at [i-1]
      // The bullish candle at [i] becomes the bearish OB (resistance zone)
      // =====================================================================
      if(IsBullishCandle(i) && IsBearishDisplacement(i-1))
      {
         // Additional validation: The displacement should break below the OB low
         bool validBreak = Low(i-1) < Low(i);

         // Verify with FVG if required
         bool hasFVG = !RequireFVGConfirmation || HasFVGNear(Time(i-1), false);

         if(validBreak && hasFVG)
         {
            AddOrderBlock(Time(i), High(i), Low(i), false, i);
         }
      }
   }
}

bool IsBullishCandle(int index)
{
   return Close(index) > Open(index);
}

bool IsBearishCandle(int index)
{
   return Close(index) < Open(index);
}

bool IsBullishDisplacement(int index)
{
   // Bullish displacement: Strong bullish candle with large body
   double bodySize = (Close(index) - Open(index)) / _Point;
   return IsBullishCandle(index) && bodySize > MinFVGSizePoints;
}

bool IsBearishDisplacement(int index)
{
   // Bearish displacement: Strong bearish candle with large body
   double bodySize = (Open(index) - Close(index)) / _Point;
   return IsBearishCandle(index) && bodySize > MinFVGSizePoints;
}

bool HasFVGNear(datetime time, bool bullish)
{
   for(int i = 0; i < ArraySize(FVGs); i++)
   {
      if(FVGs[i].isBullish == bullish)
      {
         long timeDiff = MathAbs((long)FVGs[i].time - (long)time);
         if(timeDiff < PeriodSeconds() * 5) return true;
      }
   }
   return false;
}

void AddOrderBlock(datetime time, double high, double low, bool bullish, int barIndex)
{
   // Check if OB already exists
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(OrderBlocks[i].time == time) return;
   }

   OrderBlock ob;
   ob.time = time;
   ob.high = high;
   ob.low = low;
   ob.isBullish = bullish;
   ob.isValid = true;
   ob.isMitigated = false;
   ob.barIndex = barIndex;
   ob.objName = PREFIX_OB + TimeToString(time);

   int size = ArraySize(OrderBlocks);
   ArrayResize(OrderBlocks, size + 1);
   OrderBlocks[size] = ob;

   if(DrawOrderBlocks)
   {
      DrawOBRectangle(ob);
   }

   Print("Order Block Detected - ", (bullish ? "Bullish" : "Bearish"),
         " | High: ", high, " | Low: ", low);
}

void DrawOBRectangle(OrderBlock &ob)
{
   color clr = ob.isBullish ? BullishColor : BearishColor;
   datetime time2 = Time(0) + PeriodSeconds() * 30;

   if(CleanChartMode)
   {
      // Clean mode: Just draw the key level (top of bullish OB, bottom of bearish OB)
      // This is the "mitigation level" where price needs to return
      double keyLevel = ob.isBullish ? ob.high : ob.low;
      string levelLine = ob.objName + "_Level";

      ObjectCreate(0, levelLine, OBJ_TREND, 0, ob.time, keyLevel, time2, keyLevel);
      ObjectSetInteger(0, levelLine, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, levelLine, OBJPROP_STYLE, STYLE_SOLID);
      ObjectSetInteger(0, levelLine, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, levelLine, OBJPROP_RAY_RIGHT, false);
      ObjectSetInteger(0, levelLine, OBJPROP_BACK, true);

      // Small label
      string label = ob.objName + "_Label";
      ObjectCreate(0, label, OBJ_TEXT, 0, ob.time, keyLevel);
      ObjectSetString(0, label, OBJPROP_TEXT, "OB");
      ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 7);
      ObjectSetInteger(0, label, OBJPROP_ANCHOR, ob.isBullish ? ANCHOR_LOWER : ANCHOR_UPPER);
   }
   else
   {
      // Standard mode: Filled rectangle
      ObjectCreate(0, ob.objName, OBJ_RECTANGLE, 0, ob.time, ob.high, time2, ob.low);
      ObjectSetInteger(0, ob.objName, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, ob.objName, OBJPROP_FILL, true);
      ObjectSetInteger(0, ob.objName, OBJPROP_BACK, true);
      ObjectSetInteger(0, ob.objName, OBJPROP_WIDTH, 2);

      string label = ob.objName + "_Label";
      ObjectCreate(0, label, OBJ_TEXT, 0, ob.time, (ob.high + ob.low) / 2);
      ObjectSetString(0, label, OBJPROP_TEXT, ob.isBullish ? "OB+" : "OB-");
      ObjectSetInteger(0, label, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, label, OBJPROP_FONTSIZE, 9);
      ObjectSetInteger(0, label, OBJPROP_ANCHOR, ANCHOR_LEFT);
   }
}

//=============================================================================
// LIQUIDITY FUNCTIONS
//=============================================================================
void AddLiquidityLevel(double price, datetime time, bool isHigh)
{
   // Check if level already exists
   for(int i = 0; i < ArraySize(LiquidityLevels); i++)
   {
      if(MathAbs(LiquidityLevels[i].price - price) < _Point * 10) return;
   }

   LiquidityLevel liq;
   liq.price = price;
   liq.time = time;
   liq.isHigh = isHigh;
   liq.isSwept = false;
   liq.objName = PREFIX_LIQ + TimeToString(time);

   int size = ArraySize(LiquidityLevels);
   ArrayResize(LiquidityLevels, size + 1);
   LiquidityLevels[size] = liq;

   if(DrawLiquidity)
   {
      color clr = isHigh ? PDHighColor : PDLowColor;
      DrawHorizontalLine(liq.objName, price, clr, STYLE_DOT);
   }
}

void DetectLiquiditySweeps()
{
   double currentHigh = High(1);
   double currentLow = Low(1);
   double currentClose = Close(1);
   bool sweepDetectedThisBar = false;
   bool isBullishSweep = false;  // Bullish sweep = swept lows (looking for buys)
   string sweepDirection = "";
   double sweepPrice = 0;  // Price level that was swept

   // Check PDH/PDL sweeps
   if(UsePDHighLow && PDHigh > 0 && PDLow > 0)
   {
      // Bearish sweep of PDH (price wicks above then closes below)
      // This takes out buy-side liquidity, indicating potential bearish move
      if(currentHigh > PDHigh && currentClose < PDHigh)
      {
         double wickSize = (currentHigh - PDHigh) / _Point;
         if(wickSize >= MinSweepWickPoints)
         {
            sweepDetectedThisBar = true;
            isBullishSweep = false;  // Swept highs = bearish signal
            sweepDirection = "PDH (Bearish)";
            sweepPrice = PDHigh;
         }
      }

      // Bullish sweep of PDL (price wicks below then closes above)
      // This takes out sell-side liquidity, indicating potential bullish move
      if(currentLow < PDLow && currentClose > PDLow)
      {
         double wickSize = (PDLow - currentLow) / _Point;
         if(wickSize >= MinSweepWickPoints)
         {
            sweepDetectedThisBar = true;
            isBullishSweep = true;  // Swept lows = bullish signal
            sweepDirection = "PDL (Bullish)";
            sweepPrice = PDLow;
         }
      }
   }

   // Check session high/low sweeps
   if(UseSessionHighLow)
   {
      if(LondonSession.isActive && LondonSession.high > 0)
      {
         if(currentHigh > LondonSession.high && currentClose < LondonSession.high)
         {
            double wickSize = (currentHigh - LondonSession.high) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               sweepDetectedThisBar = true;
               isBullishSweep = false;
               sweepDirection = "London High (Bearish)";
               sweepPrice = LondonSession.high;
            }
         }
         if(currentLow < LondonSession.low && currentClose > LondonSession.low)
         {
            double wickSize = (LondonSession.low - currentLow) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               sweepDetectedThisBar = true;
               isBullishSweep = true;
               sweepDirection = "London Low (Bullish)";
               sweepPrice = LondonSession.low;
            }
         }
      }

      if(NYSession.isActive && NYSession.high > 0)
      {
         if(currentHigh > NYSession.high && currentClose < NYSession.high)
         {
            double wickSize = (currentHigh - NYSession.high) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               sweepDetectedThisBar = true;
               isBullishSweep = false;
               sweepDirection = "NY High (Bearish)";
               sweepPrice = NYSession.high;
            }
         }
         if(currentLow < NYSession.low && currentClose > NYSession.low)
         {
            double wickSize = (NYSession.low - currentLow) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               sweepDetectedThisBar = true;
               isBullishSweep = true;
               sweepDirection = "NY Low (Bullish)";
               sweepPrice = NYSession.low;
            }
         }
      }
   }

   // Check swing point sweeps
   for(int i = ArraySize(LiquidityLevels) - 1; i >= 0; i--)
   {
      if(LiquidityLevels[i].isSwept) continue;

      double level = LiquidityLevels[i].price;

      if(LiquidityLevels[i].isHigh)
      {
         // Check sweep of high (bearish signal)
         if(currentHigh > level && currentClose < level)
         {
            double wickSize = (currentHigh - level) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               LiquidityLevels[i].isSwept = true;
               sweepDetectedThisBar = true;
               isBullishSweep = false;
               sweepDirection = "Swing High (Bearish)";
               sweepPrice = level;
            }
         }
      }
      else
      {
         // Check sweep of low (bullish signal)
         if(currentLow < level && currentClose > level)
         {
            double wickSize = (level - currentLow) / _Point;
            if(wickSize >= MinSweepWickPoints)
            {
               LiquidityLevels[i].isSwept = true;
               sweepDetectedThisBar = true;
               isBullishSweep = true;
               sweepDirection = "Swing Low (Bullish)";
               sweepPrice = level;
            }
         }
      }
   }

   // Update global sweep state and draw marker
   if(sweepDetectedThisBar)
   {
      LiquiditySweepDetected = true;
      LastSweepWasBullish = isBullishSweep;
      LastSweepTime = TimeCurrent();
      LastSweepPrice = sweepPrice;
      SendAlert("Liquidity Sweep: " + sweepDirection);
      Print("Liquidity Sweep Detected: ", sweepDirection, " at ", TimeToString(LastSweepTime));

      // Draw sweep marker on chart (only if enabled)
      if(DrawSweepMarkers)
      {
         DrawSweepMarker(Time(1), sweepPrice, isBullishSweep, sweepDirection);
      }
   }
}

//=============================================================================
// MITIGATION CHECK
//=============================================================================
// ICT Mitigation Concept:
// - FVG is "mitigated" when price returns and FILLS the gap (trades through it)
// - For Bullish FVG: Price must close BELOW the FVG low (completely filled)
// - For Bearish FVG: Price must close ABOVE the FVG high (completely filled)
// - Partial fill (touching) is actually the ENTRY opportunity, not mitigation
// - Order Block is mitigated when price trades through the entire zone
//=============================================================================

void CheckMitigation()
{
   double currentLow = Low(1);
   double currentHigh = High(1);
   double currentClose = Close(1);

   // Check FVG mitigation
   for(int i = 0; i < ArraySize(FVGs); i++)
   {
      if(FVGs[i].isMitigated) continue;

      if(FVGs[i].isBullish)
      {
         // Bullish FVG mitigated when price CLOSES below the FVG low
         // This means price has completely traded through the gap
         // Note: FVG high = top of gap (c3Low), FVG low = bottom of gap (c1High)
         if(currentClose < FVGs[i].low)
         {
            FVGs[i].isMitigated = true;
            ObjectSetInteger(0, FVGs[i].objName, OBJPROP_COLOR, clrGray);
         }
      }
      else
      {
         // Bearish FVG mitigated when price CLOSES above the FVG high
         // This means price has completely traded through the gap
         if(currentClose > FVGs[i].high)
         {
            FVGs[i].isMitigated = true;
            ObjectSetInteger(0, FVGs[i].objName, OBJPROP_COLOR, clrGray);
         }
      }
   }

   // Check Order Block mitigation
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(OrderBlocks[i].isMitigated) continue;

      if(OrderBlocks[i].isBullish)
      {
         // Bullish OB mitigated when price closes below OB low
         // This invalidates the demand zone
         if(currentClose < OrderBlocks[i].low)
         {
            OrderBlocks[i].isMitigated = true;
            ObjectSetInteger(0, OrderBlocks[i].objName, OBJPROP_COLOR, clrGray);
         }
      }
      else
      {
         // Bearish OB mitigated when price closes above OB high
         // This invalidates the supply zone
         if(currentClose > OrderBlocks[i].high)
         {
            OrderBlocks[i].isMitigated = true;
            ObjectSetInteger(0, OrderBlocks[i].objName, OBJPROP_COLOR, clrGray);
         }
      }
   }
}

//=============================================================================
// TRADE SETUP DETECTION - ICT 2022 MODEL SEQUENCE
//=============================================================================
// ICT 2022 Entry Sequence:
// 1. Confirm daily bias from HTF
// 2. Wait for kill zone (London/NY open)
// 3. Mark session high/low + PDH/PDL
// 4. Wait for liquidity sweep (take out high/low)
// 5. Look for MSS/CHoCH with displacement + FVG
// 6. Wait for price to retrace to FVG within OTE zone
// 7. Execute trade at FVG with OB confluence
//=============================================================================

TradeSetup FindTradeSetup()
{
   TradeSetup setup;
   setup.isValid = false;
   setup.reason = "";

   // Check trade limits
   if(TradesToday >= MaxTradesPerDay)
   {
      setup.reason = "Max trades per day reached";
      return setup;
   }

   if(CountOpenTrades() >= MaxOpenTrades)
   {
      setup.reason = "Max open trades reached";
      return setup;
   }

   // Check daily drawdown
   double currentBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double drawdown = (DailyStartBalance - currentBalance) / DailyStartBalance * 100;
   if(drawdown >= MaxDailyDrawdown)
   {
      setup.reason = "Max daily drawdown reached";
      return setup;
   }

   // Step 1: Check HTF Bias
   if(CurrentBias == BIAS_NEUTRAL)
   {
      setup.reason = "No clear HTF bias";
      return setup;
   }

   // Step 4: Check if liquidity sweep occurred recently (within last 20 bars of LTF)
   // AND the sweep direction aligns with our HTF bias
   bool recentSweep = (LastSweepTime > 0 && TimeCurrent() - LastSweepTime < PeriodSeconds(LTF_Entry) * 20);
   bool sweepAligned = recentSweep && IsSweepAlignedWithBias();

   // Step 5: Check for MSS/CHoCH after the sweep on LTF
   // CHoCH should occur on LTF and ideally after a sweep
   bool chochDetected = DetectCHoCH(LTF_Entry);
   if(chochDetected)
   {
      // Only count CHoCH if it's aligned with HTF bias
      // For bullish HTF bias: CHoCH should be bullish (reversal from bearish to bullish on LTF)
      // For bearish HTF bias: CHoCH should be bearish (reversal from bullish to bearish on LTF)
      if(IsCHoCHAlignedWithBias())
      {
         MSSDetected = true;
         LastMSSTime = TimeCurrent();
         string direction = LastCHoCHWasBullish ? "BULLISH" : "BEARISH";
         Print("MSS/CHoCH Detected (", direction, ") on ", EnumToString(LTF_Entry), " at ", TimeToString(LastMSSTime));

         // Draw MSS marker on chart
         DrawMSSMarker(Time(1), LastMSSPrice, LastCHoCHWasBullish);
      }
   }

   // MSS must be recent (within last 10 bars of LTF) AND aligned with bias
   bool recentMSS = (LastMSSTime > 0 && TimeCurrent() - LastMSSTime < PeriodSeconds(LTF_Entry) * 10 && IsCHoCHAlignedWithBias());

   // Step 6 & 7: Look for entry in FVG
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Find valid FVG for entry
   for(int i = ArraySize(FVGs) - 1; i >= 0; i--)
   {
      if(FVGs[i].isMitigated) continue;

      FairValueGap fvg = FVGs[i];

      // FVG must be recent - use time-based check instead of stale barIndex
      // FVG created after last sweep OR within last 15 bars (time-based)
      bool recentFVG = (LastSweepTime > 0 && fvg.time >= LastSweepTime) ||
                       (TimeCurrent() - fvg.time < PeriodSeconds(LTF_Entry) * 15);

      // Check if current price is at or entering FVG (retracement)
      bool priceAtFVG = (currentPrice >= fvg.low && currentPrice <= fvg.high);

      if(!priceAtFVG) continue;

      // Check alignment with bias
      bool biasAligned = false;
      if(fvg.isBullish && CurrentBias == BIAS_BULLISH && !TradeShortOnly) biasAligned = true;
      if(!fvg.isBullish && CurrentBias == BIAS_BEARISH && !TradeLongOnly) biasAligned = true;

      if(!biasAligned) continue;

      // Check if FVG aligns with sweep direction (critical ICT concept)
      bool fvgSweepAligned = IsFVGAlignedWithSweep(fvg.isBullish);

      // Check for OTE zone
      bool inOTEZone = IsInOTEZone(fvg.isBullish);

      // Find confirming Order Block
      bool hasOBConfluence = HasOrderBlockConfluence(fvg);

      // Prevent duplicate entry on same FVG
      if(fvg.time <= LastEntryTime) continue;

      // =====================================================================
      // MANDATORY REQUIREMENTS (ICT 2022 Model)
      // =====================================================================
      // 1. Sweep MUST be aligned - this is the cornerstone of ICT
      //    Without proper sweep alignment, we do NOT enter
      if(!sweepAligned || !fvgSweepAligned)
      {
         continue;  // Skip this FVG if sweep is not aligned
      }

      // 2. MSS/CHoCH must be detected after the sweep
      if(!recentMSS)
      {
         continue;  // Skip if no recent MSS/CHoCH
      }

      // Build confluence score for additional factors
      int confluenceScore = 0;
      string confluenceReason = "";

      // Base requirements met: Bias + Sweep + MSS (these are mandatory)
      confluenceScore = 3;
      confluenceReason = "Bias+Sweep+MSS";

      // Additional confluence factors (nice to have)
      if(inOTEZone)       { confluenceScore += 1; confluenceReason += "+OTE"; }
      if(hasOBConfluence) { confluenceScore += 1; confluenceReason += "+OB"; }
      if(recentFVG)       { confluenceScore += 1; confluenceReason += "+FVG"; }

      // With mandatory requirements met, we have at least 3 confluence
      // Additional factors increase confidence
      if(confluenceScore >= 3)
      {
         setup.isValid = true;
         setup.isBuy = fvg.isBullish;
         setup.entryPrice = currentPrice;

         // Calculate SL and TP
         if(setup.isBuy)
         {
            // SL below FVG low - this is the invalidation level
            setup.stopLoss = fvg.low - StopLossBuffer * _Point;

            // If OB confluence exists, we can optionally use the OB low
            // But only if OB low is HIGHER than FVG low (tighter SL)
            // Using a lower OB low would give a wider SL, not tighter
            if(hasOBConfluence)
            {
               double obLow = GetConfluenceOBLow(fvg);
               // For a TIGHTER SL on buy, OB low should be higher than FVG low
               if(obLow > 0 && obLow > fvg.low)
               {
                  setup.stopLoss = obLow - StopLossBuffer * _Point;
               }
            }

            double risk = setup.entryPrice - setup.stopLoss;
            if(risk <= 0) continue;  // Invalid setup if no risk
            setup.takeProfit = setup.entryPrice + (risk * MinRiskReward);
         }
         else
         {
            // SL above FVG high - this is the invalidation level
            setup.stopLoss = fvg.high + StopLossBuffer * _Point;

            // If OB confluence exists, we can optionally use the OB high
            // But only if OB high is LOWER than FVG high (tighter SL)
            if(hasOBConfluence)
            {
               double obHigh = GetConfluenceOBHigh(fvg);
               // For a TIGHTER SL on sell, OB high should be lower than FVG high
               if(obHigh > 0 && obHigh < fvg.high)
               {
                  setup.stopLoss = obHigh + StopLossBuffer * _Point;
               }
            }

            double risk = setup.stopLoss - setup.entryPrice;
            if(risk <= 0) continue;  // Invalid setup if no risk
            setup.takeProfit = setup.entryPrice - (risk * MinRiskReward);
         }

         setup.riskReward = MinRiskReward;
         setup.signalTime = TimeCurrent();
         setup.reason = confluenceReason;

         break;
      }
   }

   return setup;
}

// Helper function to get OB low for confluence
double GetConfluenceOBLow(FairValueGap &fvg)
{
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(OrderBlocks[i].isMitigated) continue;
      if(OrderBlocks[i].isBullish != fvg.isBullish) continue;

      bool overlaps = !(OrderBlocks[i].high < fvg.low || OrderBlocks[i].low > fvg.high);
      if(overlaps) return OrderBlocks[i].low;
   }
   return 0;
}

// Helper function to get OB high for confluence
double GetConfluenceOBHigh(FairValueGap &fvg)
{
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(OrderBlocks[i].isMitigated) continue;
      if(OrderBlocks[i].isBullish != fvg.isBullish) continue;

      bool overlaps = !(OrderBlocks[i].high < fvg.low || OrderBlocks[i].low > fvg.high);
      if(overlaps) return OrderBlocks[i].high;
   }
   return 0;
}

bool IsInOTEZone(bool bullish)
{
   // Find the most recent impulse move to calculate OTE
   // For bullish setup: Find recent swing low followed by swing high (the impulse up)
   // For bearish setup: Find recent swing high followed by swing low (the impulse down)

   double impulseHigh = 0, impulseLow = DBL_MAX;
   int highBar = -1, lowBar = -1;

   // Find the two most recent swing points
   for(int i = SwingStrength; i < 50; i++)
   {
      if(IsSwingHigh(i, LTF_Entry) && highBar == -1)
      {
         impulseHigh = High(i, LTF_Entry);
         highBar = i;
      }
      if(IsSwingLow(i, LTF_Entry) && lowBar == -1)
      {
         impulseLow = Low(i, LTF_Entry);
         lowBar = i;
      }
      if(highBar >= 0 && lowBar >= 0) break;
   }

   if(highBar < 0 || lowBar < 0 || impulseHigh <= impulseLow) return false;

   double range = impulseHigh - impulseLow;
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   if(bullish)
   {
      // For bullish OTE: Price should retrace into 61.8% - 79% of the move up
      // The impulse should be: Low formed first (higher bar index), then High (lower bar index)
      if(lowBar > highBar) // Correct sequence for bullish: low -> high
      {
         // OTE zone is calculated from the HIGH, retracing down
         double oteTop = impulseHigh - (range * OTE_Start);    // 61.8% retracement level
         double oteBottom = impulseHigh - (range * OTE_End);   // 79% retracement level

         // Price should be between 61.8% and 79% retracement
         return (currentPrice <= oteTop && currentPrice >= oteBottom);
      }
   }
   else
   {
      // For bearish OTE: Price should retrace into 61.8% - 79% of the move down
      // The impulse should be: High formed first (higher bar index), then Low (lower bar index)
      if(highBar > lowBar) // Correct sequence for bearish: high -> low
      {
         // OTE zone is calculated from the LOW, retracing up
         double oteBottom = impulseLow + (range * OTE_Start);  // 61.8% retracement level
         double oteTop = impulseLow + (range * OTE_End);       // 79% retracement level

         // Price should be between 61.8% and 79% retracement
         return (currentPrice >= oteBottom && currentPrice <= oteTop);
      }
   }

   return false;
}

bool HasOrderBlockConfluence(FairValueGap &fvg)
{
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(OrderBlocks[i].isMitigated) continue;
      if(OrderBlocks[i].isBullish != fvg.isBullish) continue;

      // Check if OB overlaps with FVG
      bool overlaps = !(OrderBlocks[i].high < fvg.low || OrderBlocks[i].low > fvg.high);
      if(overlaps) return true;
   }
   return false;
}

//=============================================================================
// TRADE EXECUTION
//=============================================================================
void ProcessTradeSetup(TradeSetup &setup)
{
   if(TradeMode == MODE_VISUAL)
   {
      // Visual only - just draw OTE zone
      if(DrawOTEZone) DrawOTEZoneRectangle(setup);
      return;
   }

   if(TradeMode == MODE_MANUAL)
   {
      // Send alert only
      string msg = StringFormat("ICT Setup: %s | Entry: %.5f | SL: %.5f | TP: %.5f | RR: %.1f | %s",
                                setup.isBuy ? "BUY" : "SELL",
                                setup.entryPrice, setup.stopLoss, setup.takeProfit,
                                setup.riskReward, setup.reason);
      SendAlert(msg);
      if(DrawOTEZone) DrawOTEZoneRectangle(setup);
      return;
   }

   // Auto mode - execute trade
   double lotSize = CalculateLotSize(setup);

   bool success = false;
   if(setup.isBuy)
   {
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      success = Trade.Buy(lotSize, _Symbol, ask, setup.stopLoss, setup.takeProfit, "ICT 2022");
   }
   else
   {
      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      success = Trade.Sell(lotSize, _Symbol, bid, setup.stopLoss, setup.takeProfit, "ICT 2022");
   }

   if(success)
   {
      TradesToday++;
      LastEntryTime = setup.signalTime;  // Prevent duplicate entries

      // Reset sweep and MSS flags after entry
      LiquiditySweepDetected = false;
      MSSDetected = false;

      string msg = StringFormat("Trade Executed: %s %.2f lots | Entry: %.5f | SL: %.5f | TP: %.5f | %s",
                                setup.isBuy ? "BUY" : "SELL", lotSize,
                                setup.entryPrice, setup.stopLoss, setup.takeProfit, setup.reason);
      SendAlert(msg);
      Print(msg);
   }
   else
   {
      Print("Trade execution failed: ", Trade.ResultComment());
   }
}

double CalculateLotSize(TradeSetup &setup)
{
   if(UseFixedLot) return FixedLotSize;

   // Calculate risk amount in account currency
   double riskAmount = AccountInfoDouble(ACCOUNT_BALANCE) * (RiskPercent / 100);

   // Calculate SL distance in price
   double slDistance = MathAbs(setup.entryPrice - setup.stopLoss);

   // Get symbol specifications
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   double contractSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_CONTRACT_SIZE);

   if(tickValue == 0 || tickSize == 0 || contractSize == 0) return FixedLotSize;

   // Calculate value per lot for the SL distance
   // Value per pip = tickValue * (pip size / tick size)
   // For forex: pip = 0.0001 or 0.01, tick = 0.00001 or 0.001
   double valuePerTickPerLot = tickValue;
   double ticksInSL = slDistance / tickSize;
   double riskPerLot = ticksInSL * valuePerTickPerLot;

   if(riskPerLot == 0) return FixedLotSize;

   double lotSize = riskAmount / riskPerLot;

   // Normalize lot size
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

   lotSize = MathFloor(lotSize / lotStep) * lotStep;  // Round down to be safe
   lotSize = MathMax(minLot, MathMin(maxLot, lotSize));

   return lotSize;
}

void DrawOTEZoneRectangle(TradeSetup &setup)
{
   string name = PREFIX_OTE + TimeToString(setup.signalTime);
   datetime time1 = Time(10);
   datetime time2 = Time(0) + PeriodSeconds() * 5;

   // Draw entry zone
   ObjectCreate(0, name, OBJ_RECTANGLE, 0, time1, setup.entryPrice + 50*_Point, time2, setup.entryPrice - 50*_Point);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_FILL, true);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);

   // Draw SL line
   string slName = name + "_SL";
   DrawHorizontalLine(slName, setup.stopLoss, clrRed, STYLE_SOLID);

   // Draw TP line
   string tpName = name + "_TP";
   DrawHorizontalLine(tpName, setup.takeProfit, clrGreen, STYLE_SOLID);
}

//=============================================================================
// TRADE MANAGEMENT
//=============================================================================
void ManageOpenTrades()
{
   if(!UsePartialTP && !UseTrailingStop && !MoveToBreakeven) return;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;
      if(PositionGetInteger(POSITION_MAGIC) != 123456) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentSL = PositionGetDouble(POSITION_SL);
      double currentTP = PositionGetDouble(POSITION_TP);
      long positionType = PositionGetInteger(POSITION_TYPE);  // Fixed: was double, should be long
      double volume = PositionGetDouble(POSITION_VOLUME);

      double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
      double spread = ask - bid;
      double currentPrice = (positionType == POSITION_TYPE_BUY) ? bid : ask;

      double risk = MathAbs(openPrice - currentSL);
      double profit = (positionType == POSITION_TYPE_BUY) ?
                      (currentPrice - openPrice) : (openPrice - currentPrice);
      double rr = (risk > 0) ? profit / risk : 0;

      // Partial TP
      if(UsePartialTP && rr >= PartialTPRatio)
      {
         // Check if we already moved to breakeven (meaning partial was already taken)
         // Use a tolerance check instead of exact equality
         bool alreadyAtBreakeven = false;
         if(positionType == POSITION_TYPE_BUY)
         {
            alreadyAtBreakeven = (currentSL >= openPrice - spread);
         }
         else
         {
            alreadyAtBreakeven = (currentSL <= openPrice + spread);
         }

         if(!alreadyAtBreakeven)
         {
            double partialVolume = volume * (PartialTPPercent / 100);
            double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
            double lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);

            // Round partial volume to lot step
            partialVolume = MathFloor(partialVolume / lotStep) * lotStep;
            partialVolume = MathMax(minLot, partialVolume);

            // Only close partial if remaining volume is at least minLot
            double remainingVolume = volume - partialVolume;
            if(partialVolume >= minLot && remainingVolume >= minLot)
            {
               if(Trade.PositionClosePartial(ticket, partialVolume))
               {
                  // Move to breakeven with spread buffer
                  if(MoveToBreakeven)
                  {
                     double breakevenBuffer = spread + StopLossBuffer * _Point;
                     double newSL = (positionType == POSITION_TYPE_BUY) ?
                                    openPrice + breakevenBuffer :
                                    openPrice - breakevenBuffer;
                     Trade.PositionModify(ticket, newSL, currentTP);
                     Print("Partial TP taken, moved to breakeven");
                  }
               }
            }
         }
      }

      // Trailing stop
      if(UseTrailingStop && profit > TrailingStopPoints * _Point)
      {
         double trailPrice = (positionType == POSITION_TYPE_BUY) ?
                             currentPrice - TrailingStopPoints * _Point :
                             currentPrice + TrailingStopPoints * _Point;

         bool shouldTrail = (positionType == POSITION_TYPE_BUY) ?
                            trailPrice > currentSL :
                            trailPrice < currentSL;

         if(shouldTrail)
         {
            Trade.PositionModify(ticket, trailPrice, currentTP);
         }
      }
   }
}

int CountOpenTrades()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(!PositionSelectByTicket(ticket)) continue;

      if(PositionGetString(POSITION_SYMBOL) == _Symbol &&
         PositionGetInteger(POSITION_MAGIC) == 123456)
      {
         count++;
      }
   }
   return count;
}

//=============================================================================
// ALERT FUNCTIONS
//=============================================================================
void SendAlert(string message)
{
   if(TradeMode == MODE_VISUAL) return;

   string fullMsg = "ICT 2022 [" + _Symbol + "]: " + message;

   if(EnableAlerts)
   {
      Alert(fullMsg);
   }

   if(EnablePushNotification)
   {
      SendNotification(fullMsg);
   }

   if(EnableEmailAlert)
   {
      SendMail("ICT 2022 Alert", fullMsg);
   }

   if(EnableSoundAlert)
   {
      PlaySound(AlertSoundFile);
   }
}

//=============================================================================
// DASHBOARD FUNCTIONS
//=============================================================================
void CreateDashboard()
{
   int y = DashboardY;
   int lineHeight = DashboardFontSize + 5;

   CreateLabel(PREFIX_DASH + "Title", "=== ICT 2022 Model ===", DashboardX, y, DashboardTextColor, DashboardFontSize + 2);
   y += lineHeight + 5;

   CreateLabel(PREFIX_DASH + "CurrentTime", "Time (EST): ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "NextKZ", "Next KZ: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "Mode", "Mode: " + EnumToString(TradeMode), DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "KillZone", "Kill Zone: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "Bias", "HTF Bias: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "Structure", "LTF Structure: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "Sweep", "Liquidity Sweep: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "MSS", "MSS/CHoCH: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "FVGCount", "Active FVGs: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "OBCount", "Active OBs: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "Trades", "Trades Today: ", DashboardX, y, DashboardTextColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "PDH", "PDH: ", DashboardX, y, PDHighColor, DashboardFontSize);
   y += lineHeight;

   CreateLabel(PREFIX_DASH + "PDL", "PDL: ", DashboardX, y, PDLowColor, DashboardFontSize);
}

void UpdateDashboard()
{
   // Update current time display
   ObjectSetString(0, PREFIX_DASH + "CurrentTime", OBJPROP_TEXT, "Time (EST): " + GetCurrentESTTimeString());
   ObjectSetInteger(0, PREFIX_DASH + "CurrentTime", OBJPROP_COLOR, clrCyan);

   // Update time to next kill zone
   string nextKZText = GetTimeToNextKillZone();
   bool inKZ = IsInKillZone();
   color nextKZColor = inKZ ? clrLime : clrYellow;  // Green if in KZ, yellow if waiting
   ObjectSetString(0, PREFIX_DASH + "NextKZ", OBJPROP_TEXT, "Next KZ: " + nextKZText);
   ObjectSetInteger(0, PREFIX_DASH + "NextKZ", OBJPROP_COLOR, nextKZColor);

   string kzStatus = GetCurrentKillZoneName();
   color kzColor = inKZ ? clrLime : clrGray;

   ObjectSetString(0, PREFIX_DASH + "KillZone", OBJPROP_TEXT, "Kill Zone: " + kzStatus + (inKZ ? " [ACTIVE]" : ""));
   ObjectSetInteger(0, PREFIX_DASH + "KillZone", OBJPROP_COLOR, kzColor);

   string biasText = (CurrentBias == BIAS_BULLISH) ? "BULLISH" : (CurrentBias == BIAS_BEARISH) ? "BEARISH" : "NEUTRAL";
   color biasColor = (CurrentBias == BIAS_BULLISH) ? clrLime : (CurrentBias == BIAS_BEARISH) ? clrRed : clrGray;
   ObjectSetString(0, PREFIX_DASH + "Bias", OBJPROP_TEXT, "HTF Bias: " + biasText);
   ObjectSetInteger(0, PREFIX_DASH + "Bias", OBJPROP_COLOR, biasColor);

   string structText = (LTF_Structure == STRUCTURE_BULLISH) ? "BULLISH" : (LTF_Structure == STRUCTURE_BEARISH) ? "BEARISH" : "RANGING";
   color structColor = (LTF_Structure == STRUCTURE_BULLISH) ? clrLime : (LTF_Structure == STRUCTURE_BEARISH) ? clrRed : clrGray;
   ObjectSetString(0, PREFIX_DASH + "Structure", OBJPROP_TEXT, "LTF Structure: " + structText);
   ObjectSetInteger(0, PREFIX_DASH + "Structure", OBJPROP_COLOR, structColor);

   // Sweep status
   bool recentSweep = (LastSweepTime > 0 && TimeCurrent() - LastSweepTime < PeriodSeconds() * 20);
   string sweepText = recentSweep ? "DETECTED" : "Waiting...";
   color sweepColor = recentSweep ? clrYellow : clrGray;
   ObjectSetString(0, PREFIX_DASH + "Sweep", OBJPROP_TEXT, "Liquidity Sweep: " + sweepText);
   ObjectSetInteger(0, PREFIX_DASH + "Sweep", OBJPROP_COLOR, sweepColor);

   // MSS status
   bool recentMSS = (LastMSSTime > 0 && TimeCurrent() - LastMSSTime < PeriodSeconds() * 10);
   string mssText = recentMSS ? "CONFIRMED" : "Waiting...";
   color mssColor = recentMSS ? clrLime : clrGray;
   ObjectSetString(0, PREFIX_DASH + "MSS", OBJPROP_TEXT, "MSS/CHoCH: " + mssText);
   ObjectSetInteger(0, PREFIX_DASH + "MSS", OBJPROP_COLOR, mssColor);

   int activeFVGs = CountActiveFVGs();
   int activeOBs = CountActiveOBs();

   ObjectSetString(0, PREFIX_DASH + "FVGCount", OBJPROP_TEXT, "Active FVGs: " + IntegerToString(activeFVGs));
   ObjectSetString(0, PREFIX_DASH + "OBCount", OBJPROP_TEXT, "Active OBs: " + IntegerToString(activeOBs));
   ObjectSetString(0, PREFIX_DASH + "Trades", OBJPROP_TEXT, "Trades Today: " + IntegerToString(TradesToday) + "/" + IntegerToString(MaxTradesPerDay));

   ObjectSetString(0, PREFIX_DASH + "PDH", OBJPROP_TEXT, "PDH: " + DoubleToString(PDHigh, _Digits));
   ObjectSetString(0, PREFIX_DASH + "PDL", OBJPROP_TEXT, "PDL: " + DoubleToString(PDLow, _Digits));

   ChartRedraw(0);
}

int CountActiveFVGs()
{
   int count = 0;
   for(int i = 0; i < ArraySize(FVGs); i++)
   {
      if(!FVGs[i].isMitigated) count++;
   }
   return count;
}

int CountActiveOBs()
{
   int count = 0;
   for(int i = 0; i < ArraySize(OrderBlocks); i++)
   {
      if(!OrderBlocks[i].isMitigated) count++;
   }
   return count;
}

//=============================================================================
// DRAWING UTILITY FUNCTIONS
//=============================================================================
void CreateLabel(string name, string text, int x, int y, color clr, int fontSize)
{
   ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
}

void DrawHorizontalLine(string name, double price, color clr, ENUM_LINE_STYLE style)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
      return;
   }

   ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
}

void DrawVerticalLine(string name, datetime time, color clr, ENUM_LINE_STYLE style)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, time);
      return;
   }

   ObjectCreate(0, name, OBJ_VLINE, 0, time, 0);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw MSS/CHoCH marker with short horizontal line and label        |
//| - Bullish MSS: price broke above swing high, label below line     |
//| - Bearish MSS: price broke below swing low, label above line      |
//+------------------------------------------------------------------+
void DrawMSSMarker(datetime time, double price, bool isBullish)
{
   string name = PREFIX_MSS + TimeToString(time);

   // Check if already exists
   if(ObjectFind(0, name) >= 0) return;

   // Calculate line endpoints (short line spanning ~5 bars)
   datetime time1 = time - PeriodSeconds() * 2;
   datetime time2 = time + PeriodSeconds() * 3;

   // Draw short horizontal line at the MSS level (the broken swing point)
   ObjectCreate(0, name, OBJ_TREND, 0, time1, price, time2, price);
   ObjectSetInteger(0, name, OBJPROP_COLOR, MSSColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);

   // Add label below line for bullish MSS, above line for bearish MSS
   string labelName = name + "_Label";
   string labelText = "MSS";
   // For bullish MSS (broke above), label goes below the line
   // For bearish MSS (broke below), label goes above the line
   double labelPrice = isBullish ? price - 30 * _Point : price + 30 * _Point;

   ObjectCreate(0, labelName, OBJ_TEXT, 0, time, labelPrice);
   ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, MSSColor);
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, isBullish ? ANCHOR_UPPER : ANCHOR_LOWER);
}

//+------------------------------------------------------------------+
//| Draw Liquidity Sweep marker - just a small arrow, no text         |
//+------------------------------------------------------------------+
void DrawSweepMarker(datetime time, double price, bool isBullish, string sweepType)
{
   string name = PREFIX_SWEEP + TimeToString(time);

   // Check if already exists
   if(ObjectFind(0, name) >= 0) return;

   // Draw small arrow at the sweep point (no text label)
   ENUM_OBJECT arrowType = isBullish ? OBJ_ARROW_UP : OBJ_ARROW_DOWN;
   double arrowPrice = isBullish ? price - 15 * _Point : price + 15 * _Point;

   ObjectCreate(0, name, arrowType, 0, time, arrowPrice);
   ObjectSetInteger(0, name, OBJPROP_COLOR, isBullish ? BullishColor : BearishColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
}

void DeleteAllObjects()
{
   ObjectsDeleteAll(0, PREFIX_FVG);
   ObjectsDeleteAll(0, PREFIX_OB);
   ObjectsDeleteAll(0, PREFIX_LIQ);
   ObjectsDeleteAll(0, PREFIX_OTE);
   ObjectsDeleteAll(0, PREFIX_DASH);
   ObjectsDeleteAll(0, PREFIX_PDH);
   ObjectsDeleteAll(0, PREFIX_PDL);
   ObjectsDeleteAll(0, PREFIX_SESS);
   ObjectsDeleteAll(0, PREFIX_KZ);
   ObjectsDeleteAll(0, PREFIX_MSS);
   ObjectsDeleteAll(0, PREFIX_SWEEP);
}

void CleanupOldObjects()
{
   int maxBars = MathMax(MaxFVGAgeBars, MaxOBAgeBars);
   datetime cutoffTime = Time(maxBars);
   bool fvgRemoved = false;

   // Clean old FVGs - just remove from array, RefreshFVGVisuals handles display
   for(int i = ArraySize(FVGs) - 1; i >= 0; i--)
   {
      if(FVGs[i].time < cutoffTime || FVGs[i].isMitigated)
      {
         ArrayRemove(FVGs, i, 1);
         fvgRemoved = true;
      }
   }

   // Refresh visuals if any FVGs were removed
   if(fvgRemoved)
   {
      RefreshFVGVisuals();
   }

   // Clean old Order Blocks
   for(int i = ArraySize(OrderBlocks) - 1; i >= 0; i--)
   {
      if(OrderBlocks[i].time < cutoffTime || OrderBlocks[i].isMitigated)
      {
         ObjectDelete(0, OrderBlocks[i].objName);
         ObjectDelete(0, OrderBlocks[i].objName + "_Label");
         ArrayRemove(OrderBlocks, i, 1);
      }
   }

   // Clean old liquidity levels
   for(int i = ArraySize(LiquidityLevels) - 1; i >= 0; i--)
   {
      if(LiquidityLevels[i].time < cutoffTime || LiquidityLevels[i].isSwept)
      {
         ObjectDelete(0, LiquidityLevels[i].objName);
         ArrayRemove(LiquidityLevels, i, 1);
      }
   }

   // Limit array sizes
   int maxSwings = 20;
   while(ArraySize(SwingHighs) > maxSwings) ArrayRemove(SwingHighs, 0, 1);
   while(ArraySize(SwingLows) > maxSwings) ArrayRemove(SwingLows, 0, 1);
}

//=============================================================================
// CHART EVENT HANDLER
//=============================================================================
void OnChartEvent(const int id, const long &lparam, const double &dparam, const string &sparam)
{
   // Handle chart events if needed
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      if(ShowDashboard) UpdateDashboard();
   }
}
//+------------------------------------------------------------------+
