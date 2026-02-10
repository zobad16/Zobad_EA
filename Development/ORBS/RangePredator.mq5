//+------------------------------------------------------------------+
//|                                                RangePredator.mq5 |
//|                                           Copyright 2025, Zobad. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Zobad."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "Initial Balance / Opening Range Trading EA"
#property description "Supports Breakout, Fade, and Hybrid modes"
#property strict

//+------------------------------------------------------------------+
//| INCLUDES                                                         |
//+------------------------------------------------------------------+
#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>
#include <Trade\OrderInfo.mqh>
#include <Trade\AccountInfo.mqh>
#include <Trade\SymbolInfo.mqh>

//+------------------------------------------------------------------+
//| ENUMERATIONS                                                     |
//+------------------------------------------------------------------+

//--- Entry Mode
enum ENUM_ENTRY_MODE
{
   MODE_BREAKOUT = 0,    // Breakout (ORB)
   MODE_FADE = 1,        // Fade (Reversal)
   MODE_HYBRID = 2       // Hybrid (Automatic)
};

//--- Entry Trigger
enum ENUM_ENTRY_TRIGGER
{
   TRIGGER_CANDLE_CLOSE = 0,  // On Candle Close
   TRIGGER_IMMEDIATE = 1       // Immediate on Break
};

//--- Confirmation Candle Type
enum ENUM_CONFIRM_CANDLE
{
   CONFIRM_NONE = 0,       // None
   CONFIRM_ENGULFING = 1,  // Engulfing
   CONFIRM_PINBAR = 2,     // Pin Bar
   CONFIRM_INSIDE = 3,     // Inside Bar
   CONFIRM_ANY = 4         // Any Reversal Pattern
};

//--- Lot Size Mode
enum ENUM_LOT_MODE
{
   LOT_FIXED = 0,          // Fixed Lot
   LOT_RISK_BALANCE = 1,   // Risk % of Balance
   LOT_RISK_EQUITY = 2,    // Risk % of Equity
   LOT_FIXED_MONEY = 3     // Fixed Money Risk
};

//--- Take Profit Mode
enum ENUM_TP_MODE
{
   TP_FIXED_PIPS = 0,      // Fixed Pips
   TP_ATR_MULTIPLE = 1,    // ATR Multiple
   TP_IB_MULTIPLE = 2,     // IB/Settlement Range Multiple
   TP_FIXED_MONEY = 3,     // Fixed Money Amount
   TP_RR_RATIO = 4,        // Risk:Reward Ratio
   TP_IB_MIDPOINT = 5,     // IB/Settlement Midpoint
   TP_IB_OPPOSITE = 6,     // Opposite IB/Settlement Level
   TP_NONE = 7             // No Take Profit
};

//--- Stop Loss Mode
enum ENUM_SL_MODE
{
   SL_FIXED_PIPS = 0,      // Fixed Pips
   SL_ATR_MULTIPLE = 1,    // ATR Multiple
   SL_IB_MULTIPLE = 2,     // IB/Settlement Range Multiple
   SL_FIXED_MONEY = 3,     // Fixed Money Amount
   SL_BEYOND_IB = 4,       // Beyond IB/Settlement Level + Buffer
   SL_BEYOND_CANDLE = 5,   // Beyond Breakout Candle
   SL_SWING = 6            // Swing High/Low
};

//--- Trailing Stop Mode (distance method)
enum ENUM_TRAIL_MODE
{
   TRAIL_NONE = 0,         // No Trailing
   TRAIL_FIXED_PIPS = 1,   // Fixed Pips Distance
   TRAIL_ATR = 2,          // ATR Based Distance
   TRAIL_PERCENT = 3,      // Percentage of Profit
   TRAIL_RR = 4            // R-Multiple Distance
};

//--- Trail Start Mode (when to start trailing)
enum ENUM_TRAIL_START_MODE
{
   TRAIL_START_PIPS = 0,   // Start After X Pips
   TRAIL_START_RR = 1      // Start After X R:R
};

//--- Trend Filter Method
enum ENUM_TREND_METHOD
{
   TREND_MA = 0,           // Single Moving Average
   TREND_MA_CROSS = 1,     // Two MA Crossover
   TREND_ADX = 2,          // ADX Trend Strength
   TREND_HTF = 3           // Higher Timeframe Bias
};

//--- Trend Filter Mode
enum ENUM_TREND_FILTER_MODE
{
   TREND_WITH = 0,         // Trade With Trend Only
   TREND_COUNTER = 1,      // Trade Counter Trend Only
   TREND_ANY = 2,          // Any Trend Direction
   TREND_BREAKOUT_FADE = 3 // Breakout With, Fade Against
};

//--- Session Filter
enum ENUM_SESSION_FILTER
{
   SESSION_ANY = 0,        // Any Session
   SESSION_LONDON = 1,     // London Only
   SESSION_NEWYORK = 2,    // New York Only
   SESSION_OVERLAP = 3,    // London + NY Overlap
   SESSION_CUSTOM = 4      // Custom Times
};

//--- Dashboard Position
enum ENUM_DASH_POSITION
{
   DASH_TOP_LEFT = 0,      // Top Left
   DASH_TOP_RIGHT = 1,     // Top Right
   DASH_BOTTOM_LEFT = 2,   // Bottom Left
   DASH_BOTTOM_RIGHT = 3   // Bottom Right
};

//--- Dashboard Size
enum ENUM_DASH_SIZE
{
   DASH_SMALL = 0,         // Small
   DASH_MEDIUM = 1,        // Medium
   DASH_LARGE = 2          // Large
};

//--- Line Style
enum ENUM_LINE_STYLE_TYPE
{
   LINE_SOLID = 0,         // Solid
   LINE_DASHED = 1,        // Dashed
   LINE_DOTTED = 2         // Dotted
};

//--- IB Status
enum ENUM_IB_STATUS
{
   IB_WAITING = 0,         // Waiting for IB Start
   IB_FORMING = 1,         // IB Forming
   IB_COMPLETE = 2,        // IB Complete
   IB_BROKEN_UP = 3,       // Broken Upward
   IB_BROKEN_DOWN = 4      // Broken Downward
};

//--- EA Status
enum ENUM_EA_STATUS
{
   EA_RUNNING = 0,         // Running
   EA_PAUSED = 1,          // Paused
   EA_STOPPED = 2          // Stopped
};

//--- Timezone Selection
enum ENUM_TIMEZONE
{
   TZ_SERVER = 0,          // Server Time
   TZ_LOCAL = 1,           // Local Time (Your PC)
   TZ_LONDON = 2,          // London (GMT/BST)
   TZ_NEWYORK = 3          // New York (EST/EDT)
};

//--- DST (Daylight Saving Time) Mode
enum ENUM_DST_MODE
{
   DST_AUTO = 0,           // Auto Detect
   DST_ON = 1,             // DST Active (Summer)
   DST_OFF = 2             // DST Inactive (Winter)
};

//--- News Impact Level Filter
enum ENUM_NEWS_IMPACT
{
   NEWS_HIGH_ONLY = 0,     // High Impact Only
   NEWS_MEDIUM_HIGH = 1,   // Medium + High Impact
   NEWS_ALL = 2            // All News Events
};

//--- News Filter Mode
enum ENUM_NEWS_MODE
{
   NEWS_MODE_CALENDAR = 0, // MQL5 Economic Calendar
   NEWS_MODE_MANUAL = 1    // Manual Time-Based (Fallback)
};

//--- Range Strategy Type
enum ENUM_RANGE_STRATEGY
{
   STRATEGY_IB = 0,            // Initial Balance
   STRATEGY_SETTLEMENT = 1     // Settlement Price
};

//--- Settlement Range Method
enum ENUM_SETTLEMENT_RANGE_METHOD
{
   SETTLE_RANGE_FIXED = 0,     // Fixed Pips
   SETTLE_RANGE_ATR = 1,       // ATR Multiple
   SETTLE_RANGE_CANDLES = 2    // X Minutes Candle Range
};

//--- Settlement Status
enum ENUM_SETTLEMENT_STATUS
{
   SETTLE_WAITING = 0,         // Waiting for Settlement Start
   SETTLE_COLLECTING = 1,      // Collecting Tick Data
   SETTLE_COMPLETE = 2,        // Settlement Complete
   SETTLE_BROKEN_UP = 3,       // Broken Upward
   SETTLE_BROKEN_DOWN = 4      // Broken Downward
};

//--- Settlement Data Source
enum ENUM_SETTLE_DATA_SOURCE
{
   SETTLE_SOURCE_TICKS = 0,    // Real Ticks (Live/Tick Backtest)
   SETTLE_SOURCE_M1 = 1        // M1 Bars (Standard Backtest)
};

//+------------------------------------------------------------------+
//| INPUT PARAMETERS                                                 |
//+------------------------------------------------------------------+

//--- 1. STRATEGY SETTINGS -------------------------------------------
input group "═══════════ 1. STRATEGY SETTINGS ═══════════"
input int               Magic = 123456;                    // Magic Number
input ENUM_RANGE_STRATEGY RangeStrategy = STRATEGY_IB;     // Range Strategy Type
input ENUM_ENTRY_MODE   EntryMode = MODE_BREAKOUT;         // Entry Mode
input ENUM_ENTRY_TRIGGER EntryTrigger = TRIGGER_CANDLE_CLOSE; // Entry Trigger
input string            TradeComment = "RangePredator";    // Trade Comment

//--- 2. INITIAL BALANCE SETTINGS ------------------------------------
input group "═══════════ 2. INITIAL BALANCE SETTINGS ═══════════"
input string            IBStartTime = "09:30";             // IB Start Time (HH:MM)
input int               IBDurationMinutes = 60;            // IB Duration (Minutes)
input ENUM_TIMEZONE     IBTimezone = TZ_NEWYORK;           // IB Time Zone

//--- 2b. SETTLEMENT SETTINGS -----------------------------------------
input group "═══════════ 2b. SETTLEMENT SETTINGS ═══════════"
input string            SettlementStartTime = "09:30";     // Settlement Start Time (HH:MM)
input int               SettlementDurationMinutes = 30;    // Tick Collection Duration (Minutes)
input ENUM_TIMEZONE     SettlementTimezone = TZ_NEWYORK;   // Settlement Time Zone
input ENUM_SETTLE_DATA_SOURCE SettlementDataSource = SETTLE_SOURCE_TICKS; // Data Source
input int               SettlementMinTicks = 50;           // Min Ticks for Valid Settlement

//--- Settlement Range Definition
input ENUM_SETTLEMENT_RANGE_METHOD SettlementRangeMethod = SETTLE_RANGE_ATR; // Range Method
input double            SettlementFixedPips = 20.0;        // Fixed Range (Pips from Settlement)
input double            SettlementATRMultiple = 1.0;       // ATR Multiple for Range
input int               SettlementCandleMinutes = 30;      // Candle Range Period (Minutes)

//--- Settlement Break Distance
input double            SettlementMinBreakPips = 0;        // Min Break Distance (Pips, 0=off)
input double            SettlementMaxBreakPips = 0;        // Max Break Distance (Pips, 0=off)

//--- Settlement Visuals
input bool              DrawSettlementLevels = true;       // Draw Settlement Levels
input color             SettlementPriceColor = clrGold;    // Settlement Price Color
input color             SettlementRangeColor = clrMediumOrchid; // Settlement Range Color

//--- 3. ENTRY MODE SETTINGS -----------------------------------------
input group "═══════════ 3. ENTRY MODE SETTINGS ═══════════"
//--- Breakout Settings
input double            MinBreakDistancePips = 0;          // Min Break Distance (Pips, 0=disabled)
input double            MaxBreakDistancePips = 0;          // Max Break Distance (Pips, 0=disabled)
input bool              UseATRBreakDistance = false;       // Use ATR for Break Distance
input double            MinBreakATRMultiple = 0.0;         // Min Break (ATR Multiple)
input double            MaxBreakATRMultiple = 0.0;         // Max Break (ATR Multiple)

//--- Fade Settings
input int               FadeConfirmCandles = 1;            // Fade: Candles Back Inside Before Entry
input bool              RequireRetestForBreakout = false;  // Require Retest of IB Level (Breakout)

//--- Hybrid Settings
input int               HybridHoldCandles = 3;             // Hybrid: Candles to Confirm Hold/Fail

//--- Confirmation Candle
input ENUM_CONFIRM_CANDLE ConfirmCandle = CONFIRM_NONE;    // Confirmation Candle Pattern

//--- 4. FILTERS - VOLATILITY ----------------------------------------
input group "═══════════ 4. FILTERS - VOLATILITY ═══════════"
input bool              UseVolatilityFilter = false;       // Enable Volatility Filter
input int               ATRPeriod = 14;                    // ATR Period
input ENUM_TIMEFRAMES   ATRTimeframe = PERIOD_D1;          // ATR Timeframe
input double            MinATRPips = 0;                    // Min ATR (Pips, 0=disabled)
input double            MaxATRPips = 0;                    // Max ATR (Pips, 0=disabled)
input double            MinIBRangePips = 0;                // Min IB Range (Pips, 0=disabled)
input double            MaxIBRangePips = 0;                // Max IB Range (Pips, 0=disabled)
input bool              UseATRForIBRange = false;          // Use ATR Multiple for IB Range
input double            MinIBRangeATR = 0.0;               // Min IB Range (ATR Multiple)
input double            MaxIBRangeATR = 0.0;               // Max IB Range (ATR Multiple)

//--- 5. FILTERS - TREND ---------------------------------------------
input group "═══════════ 5. FILTERS - TREND ═══════════"
input bool              UseTrendFilter = false;            // Enable Trend Filter
input ENUM_TREND_METHOD TrendMethod = TREND_MA;            // Trend Detection Method
input ENUM_TREND_FILTER_MODE TrendFilterMode = TREND_WITH; // Trend Filter Mode
input ENUM_TIMEFRAMES   TrendTimeframe = PERIOD_H1;        // Trend Timeframe
input int               MA1Period = 50;                    // MA Period (or Fast MA)
input int               MA2Period = 200;                   // Slow MA Period (for crossover)
input ENUM_MA_METHOD    MAMethod = MODE_EMA;               // MA Method
input int               ADXPeriod = 14;                    // ADX Period
input double            ADXThreshold = 25;                 // ADX Threshold (Min for Trend)

//--- 6. FILTERS - TIME ----------------------------------------------
input group "═══════════ 6. FILTERS - TIME ═══════════"
input bool              UseTimeFilter = true;              // Enable Time Filter
input ENUM_TIMEZONE     TradeTimezone = TZ_NEWYORK;        // Trading Time Zone
input string            TradingStartTime = "09:30";        // Trading Start Time (HH:MM)
input string            TradingEndTime = "16:00";          // Trading End Time (HH:MM)
input string            LastEntryTimeStr = "15:30";        // Last Entry Time (HH:MM)
input ENUM_SESSION_FILTER SessionFilter = SESSION_ANY;     // Session Filter
input string            CustomSessionStart = "08:00";      // Custom Session Start (HH:MM)
input string            CustomSessionEnd = "16:00";        // Custom Session End (HH:MM)

//--- Timezone Offset Configuration (for manual adjustment)
input group "═══════════ 6b. TIMEZONE OFFSETS ═══════════"
input ENUM_DST_MODE     DSTMode = DST_AUTO;                // DST Handling Mode
input int               ServerToGMTOffset = 0;             // Server to GMT Offset (Hours, if known)
input bool              AutoDetectServerOffset = true;     // Auto-Detect Server GMT Offset

//--- 7. FILTERS - DAYS ----------------------------------------------
input group "═══════════ 7. FILTERS - DAYS ═══════════"
input bool              TradeMonday = true;                // Trade Monday
input bool              TradeTuesday = true;               // Trade Tuesday
input bool              TradeWednesday = true;             // Trade Wednesday
input bool              TradeThursday = true;              // Trade Thursday
input bool              TradeFriday = true;                // Trade Friday
input bool              UseFridayEarlyClose = false;       // Use Friday Early Close
input string            FridayCloseTime = "12:00";         // Friday Close Time (HH:MM)

//--- 8. FILTERS - OTHER ---------------------------------------------
input group "═══════════ 8. FILTERS - OTHER ═══════════"
input bool              UseSpreadFilter = true;            // Enable Spread Filter
input double            MaxSpreadPips = 5.0;               // Max Spread (Pips)
input bool              UseNewsFilter = false;             // Enable News Filter
input ENUM_NEWS_MODE    NewsFilterMode = NEWS_MODE_CALENDAR; // News Filter Mode
input ENUM_NEWS_IMPACT  NewsImpactFilter = NEWS_HIGH_ONLY; // News Impact Level to Filter
input int               NewsMinutesBefore = 30;            // Minutes Before News Event
input int               NewsMinutesAfter = 30;             // Minutes After News Event
input bool              FilterUSDNews = true;              // Filter USD News Events
input bool              FilterEURNews = true;              // Filter EUR News Events
input bool              FilterGBPNews = true;              // Filter GBP News Events
input bool              FilterJPYNews = false;             // Filter JPY News Events
input bool              FilterSymbolNews = true;           // Auto-Filter Symbol Currency News

//--- 9. POSITION SIZING ---------------------------------------------
input group "═══════════ 9. POSITION SIZING ═══════════"
input ENUM_LOT_MODE     LotMode = LOT_RISK_BALANCE;        // Lot Size Mode
input double            FixedLotSize = 0.1;                // Fixed Lot Size
input double            RiskPercent = 1.0;                 // Risk Percent (%)
input double            FixedRiskMoney = 100.0;            // Fixed Risk Amount ($)
input double            MinLotSize = 0.01;                 // Minimum Lot Size
input double            MaxLotSize = 10.0;                 // Maximum Lot Size

//--- 10. TAKE PROFIT SETTINGS ---------------------------------------
input group "═══════════ 10. TAKE PROFIT SETTINGS ═══════════"
input ENUM_TP_MODE      TPMode = TP_RR_RATIO;              // Take Profit Mode
input double            TPFixedPips = 50.0;                // TP Fixed Pips
input double            TPATRMultiple = 2.0;               // TP ATR Multiple
input double            TPIBMultiple = 1.5;                // TP IB Range Multiple
input double            TPFixedMoney = 100.0;              // TP Fixed Money ($)
input double            TPRRRatio = 2.0;                   // TP Risk:Reward Ratio

//--- Multiple Take Profits
input bool              UseMultipleTPs = false;            // Use Multiple Take Profits
input double            TP1Percent = 50;                   // TP1: % of Position to Close
input double            TP1RRRatio = 1.0;                  // TP1: R:R Ratio
input double            TP2Percent = 30;                   // TP2: % of Position to Close
input double            TP2RRRatio = 2.0;                  // TP2: R:R Ratio
input double            TP3RRRatio = 3.0;                  // TP3: R:R Ratio (Remaining)

//--- 11. STOP LOSS SETTINGS -----------------------------------------
input group "═══════════ 11. STOP LOSS SETTINGS ═══════════"
input ENUM_SL_MODE      SLMode = SL_BEYOND_IB;             // Stop Loss Mode
input double            SLFixedPips = 30.0;                // SL Fixed Pips
input double            SLATRMultiple = 1.5;               // SL ATR Multiple
input double            SLIBMultiple = 0.5;                // SL IB Range Multiple
input double            SLFixedMoney = 50.0;               // SL Fixed Money ($)
input double            SLBufferPips = 5.0;                // SL Buffer (Pips beyond level)
input int               SwingLookback = 10;                // Swing High/Low Lookback Bars

//--- Breakeven
input bool              UseBreakeven = true;               // Enable Breakeven
input double            BreakevenTriggerPips = 20.0;       // Breakeven Trigger (Pips in Profit)
input double            BreakevenOffsetPips = 2.0;         // Breakeven Offset (Pips above entry)
input bool              BreakevenAfterTP1 = true;          // Move to BE After TP1 Hit

//--- Trailing Stop
input ENUM_TRAIL_MODE   TrailingMode = TRAIL_NONE;         // Trailing Stop Mode
input ENUM_TRAIL_START_MODE TrailStartMode = TRAIL_START_PIPS; // Trail Start Mode
input double            TrailingStartPips = 30.0;          // Start After X Pips (if Pips mode)
input double            TrailingStartRR = 1.0;             // Start After X R:R (if R:R mode)
input double            TrailingDistancePips = 20.0;       // Trail Distance: Pips
input double            TrailingDistanceRR = 0.5;          // Trail Distance: R-Multiple (e.g. 0.5R)
input double            TrailingStepPips = 5.0;            // Trailing Step (Min Move to Update)
input double            TrailingATRMultiple = 1.0;         // Trail Distance: ATR Multiple
input double            TrailingPercent = 50.0;            // Trail Distance: Lock % of Profit

//--- 12. TRADE MANAGEMENT -------------------------------------------
input group "═══════════ 12. TRADE MANAGEMENT ═══════════"
//--- Daily Controls
input int               MaxTradesPerDay = 3;               // Max Trades Per Day (0=unlimited)
input int               MaxLosingTradesPerDay = 2;         // Max Consecutive Losses (0=unlimited)
input bool              UseDailyProfitTarget = false;      // Use Daily Profit Target
input double            DailyProfitTarget = 500.0;         // Daily Profit Target ($)
input bool              DailyProfitAsPercent = false;      // Daily Target as % of Balance
input bool              UseDailyLossLimit = true;          // Use Daily Loss Limit
input double            DailyLossLimit = 200.0;            // Daily Loss Limit ($)
input bool              DailyLossAsPercent = false;        // Daily Loss as % of Balance
input string            DailyResetTime = "00:00";          // Daily Reset Time (HH:MM)

//--- Position Controls
input int               MaxOpenPositions = 1;              // Max Open Positions
input bool              OneTradePerIB = true;              // One Trade Per IB Session Only
input bool              AllowReEntry = false;              // Allow Re-Entry After Stop Out
input int               ReEntryMaxAttempts = 1;            // Max Re-Entry Attempts

//--- End of Day
input bool              CloseAllAtTime = false;            // Close All Positions at Time
input string            CloseAllTime = "17:00";            // Close All Time (HH:MM)
input bool              CloseOnFriday = true;              // Close All on Friday
input string            FridayCloseAllTime = "16:00";      // Friday Close Time (HH:MM)
input bool              DeletePendingAtTime = true;        // Delete Pending Orders at Close Time

//--- Drawdown Protection
input bool              UseMaxDrawdown = true;             // Enable Max Drawdown Protection
input double            MaxAccountDrawdownPercent = 10.0;  // Max Account Drawdown (%)
input double            MaxDailyDrawdownPercent = 5.0;     // Max Daily Drawdown (%)

//--- 13. DASHBOARD SETTINGS -----------------------------------------
input group "═══════════ 13. DASHBOARD SETTINGS ═══════════"
input bool              ShowDashboard = true;              // Show Dashboard
input ENUM_DASH_POSITION DashboardPosition = DASH_TOP_LEFT;// Dashboard Position
input ENUM_DASH_SIZE    DashboardSize = DASH_MEDIUM;       // Dashboard Size
input color             DashboardBgColor = clrBlack;       // Dashboard Background Color
input color             DashboardTextColor = clrWhite;     // Dashboard Text Color
input color             DashboardProfitColor = clrLime;    // Profit Color
input color             DashboardLossColor = clrRed;       // Loss Color
input int               DashboardTransparency = 200;       // Background Transparency (0-255)

//--- Manual Trading Buttons
input bool              ShowManualButtons = true;          // Show Manual Trading Buttons
input bool              UseEALotForManual = true;          // Use EA Calculated Lot for Manual
input double            ManualFixedLot = 0.1;              // Manual Trading Fixed Lot

//--- 14. ALERT SETTINGS ---------------------------------------------
input group "═══════════ 14. ALERT SETTINGS ═══════════"
input bool              AlertOnIBFormed = true;            // Alert: IB Formed
input bool              AlertOnBreakout = true;            // Alert: Breakout Occurred
input bool              AlertOnEntry = true;               // Alert: Trade Entry
input bool              AlertOnExit = true;                // Alert: Trade Exit
input bool              AlertOnDailyTarget = true;         // Alert: Daily Target Hit
input bool              AlertOnDailyLoss = true;           // Alert: Daily Loss Limit Hit
input bool              AlertOnDrawdown = true;            // Alert: Drawdown Limit Hit

//--- Alert Methods
input bool              UseSoundAlert = true;              // Enable Sound Alerts
input bool              UsePopupAlert = true;              // Enable Popup Alerts
input bool              UsePushNotification = false;       // Enable Push Notifications
input bool              UseEmailAlert = false;             // Enable Email Alerts
input string            AlertSoundFile = "alert.wav";      // Alert Sound File

//--- 15. VISUAL SETTINGS --------------------------------------------
input group "═══════════ 15. VISUAL SETTINGS ═══════════"
input bool              DrawIBLevels = true;               // Draw IB Levels on Chart
input color             IBHighColor = clrDodgerBlue;       // IB High Line Color
input color             IBLowColor = clrDodgerBlue;        // IB Low Line Color
input color             IBMidColor = clrGray;              // IB Midpoint Line Color
input ENUM_LINE_STYLE_TYPE IBLineStyle = LINE_SOLID;       // IB Line Style
input int               IBLineWidth = 2;                   // IB Line Width

input bool              DrawEntryExitLines = true;         // Draw Entry/SL/TP Lines
input color             EntryLineColor = clrYellow;        // Entry Line Color
input color             SLLineColor = clrRed;              // Stop Loss Line Color
input color             TPLineColor = clrLime;             // Take Profit Line Color

input bool              DrawTradeHistory = true;           // Draw Trade History Arrows
input color             BuyArrowColor = clrLime;           // Buy Arrow Color
input color             SellArrowColor = clrRed;           // Sell Arrow Color

input bool              HighlightIBPeriod = true;          // Highlight IB Formation Period
input color             IBHighlightColor = clrDarkSlateGray; // IB Highlight Color

input int               DeleteOldDrawingsAfterDays = 7;    // Delete Old Drawings After (Days)

//--- 16. LOGGING & DEBUG --------------------------------------------
input group "═══════════ 16. LOGGING & DEBUG ═══════════"
input bool              EnableFileLogging = false;         // Enable File Logging
input bool              LogTradesToCSV = true;             // Log Trades to CSV
input bool              LogDailySummary = true;            // Log Daily Summary
input string            LogFileName = "RangePredator";     // Log File Name (without extension)
input bool              EnableDebugMode = false;           // Enable Debug Mode (Verbose Logging)

//+------------------------------------------------------------------+
//| GLOBAL VARIABLES                                                 |
//+------------------------------------------------------------------+

//--- EA Name constant
const string   EAName = "RangePredator";

//--- Trade Objects
CTrade         trade;
CPositionInfo  positionInfo;
COrderInfo     orderInfo;
CAccountInfo   accountInfo;
CSymbolInfo    symbolInfo;

//--- IB Variables
double         IBHigh = 0;
double         IBLow = 0;
double         IBMidpoint = 0;
double         IBRange = 0;
datetime       IBStartDateTime = 0;
datetime       IBEndDateTime = 0;
ENUM_IB_STATUS IBStatus = IB_WAITING;
bool           IBBrokenUp = false;
bool           IBBrokenDown = false;

//--- Settlement Variables
double         SettlementPrice = 0;
double         SettlementHigh = 0;
double         SettlementLow = 0;
double         SettlementMidpoint = 0;
double         SettlementRange = 0;
datetime       SettlementStartDateTime = 0;
datetime       SettlementEndDateTime = 0;
ENUM_SETTLEMENT_STATUS SettlementStatus = SETTLE_WAITING;
bool           SettlementBrokenUp = false;
bool           SettlementBrokenDown = false;

//--- Settlement Tick Collection (running sums for efficiency)
double         SettlementTickSum = 0;
int            SettlementTickCount = 0;
datetime       LastSettlementTickTime = 0;
int            SettlementM1BarsProcessed = 0;

//--- Settlement Tracking
bool           SettlementBreakoutJustOccurred = false;
int            SettlementCandlesSinceBreak = 0;
bool           SettlementRetested = false;

//--- EA State Variables
ENUM_EA_STATUS EAStatus = EA_RUNNING;
bool           TradeAllowed = true;
int            TodayTradeCount = 0;
int            TodayTrades = 0;           // Alias for TodayTradeCount
int            TodayWins = 0;
int            TodayLosses = 0;
int            ConsecutiveLosses = 0;
double         TodayProfit = 0;
double         TodayHighBalance = 0;
double         TodayStartBalance = 0;
double         AccountHighBalance = 0;
datetime       LastTradeDate = 0;
datetime       LastEntryTime = 0;
int            ReEntryAttempts = 0;

//--- Signal Variables
int            SignalDirection = 0;  // 1 = Buy, -1 = Sell, 0 = None
double         SignalEntryPrice = 0;
double         SignalSL = 0;
double         SignalTP = 0;
datetime       BreakoutTime = 0;
int            CandlesSinceBreak = 0;
bool           BreakoutRetested = false;
bool           BreakoutJustOccurred = false;  // Flag for immediate entry on breakout
bool           CurrentTickIsNewBar = false;   // Set once per tick in OnTick()

//--- Indicator Handles
int            ATRHandle = INVALID_HANDLE;
int            MA1Handle = INVALID_HANDLE;
int            MA2Handle = INVALID_HANDLE;
int            ADXHandle = INVALID_HANDLE;

//--- Symbol Info
double         PointValue = 0;
double         PipValue = 0;
int            SymbolDigits = 0;
double         LotStep = 0;
double         MinLot = 0;
double         MaxLot = 0;
double         TickValue = 0;

//--- Dashboard Object Names
string         DashboardPrefix = "RPD_";

//--- Position Tracking (for R:R calculations, breakeven, trailing)
struct PositionTrackInfo
{
   ulong          ticket;           // Position ticket
   double         entryPrice;       // Original entry price
   double         originalSL;       // Original stop loss (never changes)
   double         slDistance;       // Original SL distance (for R:R calc)
   double         originalLots;     // Original position size
   int            direction;        // 1 = Buy, -1 = Sell
   datetime       entryTime;        // Time position was opened
   bool           breakevenHit;     // Breakeven has been triggered
};

PositionTrackInfo TrackedPositions[];  // Array to track all positions
int               TrackedPositionCount = 0;

//--- Multiple Take Profit Tracking (extends position tracking)
struct MultiTPInfo
{
   ulong          ticket;           // Position ticket
   double         entryPrice;       // Original entry price
   double         originalSL;       // Original stop loss
   double         slDistance;       // Distance from entry to SL (for R:R calc)
   double         originalLots;     // Original position size
   int            direction;        // 1 = Buy, -1 = Sell
   double         tp1Level;         // TP1 price level
   double         tp2Level;         // TP2 price level
   double         tp3Level;         // TP3 price level (final)
   double         tp1Lots;          // Lots to close at TP1
   double         tp2Lots;          // Lots to close at TP2
   double         tp3Lots;          // Lots remaining for TP3
   bool           tp1Hit;           // TP1 has been triggered
   bool           tp2Hit;           // TP2 has been triggered
   bool           beMovedAfterTP1;  // Breakeven moved after TP1
   datetime       entryTime;        // Time position was opened
};

MultiTPInfo    MultiTPPositions[];  // Array to track positions with multiple TPs
int            MultiTPCount = 0;    // Number of positions being tracked

//--- Logging
int            LogFileHandle = INVALID_HANDLE;
int            CSVFileHandle = INVALID_HANDLE;

//--- Timezone Variables
int            DetectedServerGMTOffset = 0;    // Auto-detected server offset from GMT
int            LondonGMTOffset = 0;            // London offset (0 or 1 for BST)
int            NewYorkGMTOffset = -5;          // NY offset (-5 or -4 for EDT)
bool           IsLondonDST = false;            // Is London in DST?
bool           IsNewYorkDST = false;           // Is New York in DST?
datetime       LastDSTCheck = 0;               // Last time DST was checked

//--- News Filter Variables
struct NewsEvent
{
   datetime    time;           // Event time (server time)
   string      currency;       // Currency affected (USD, EUR, GBP, etc.)
   string      name;           // Event name
   int         importance;     // 0=None, 1=Low, 2=Medium, 3=High
   ulong       eventId;        // Calendar event ID
};

NewsEvent      UpcomingNews[];              // Array of upcoming news events
datetime       LastNewsUpdate = 0;          // Last time news was updated
int            NewsUpdateIntervalSec = 3600; // Update news every hour
bool           NewsCalendarAvailable = false; // Is MQL5 calendar available?
string         SymbolBaseCurrency = "";      // Base currency of current symbol
string         SymbolQuoteCurrency = "";     // Quote currency of current symbol

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   //--- Initialize symbol info
   if(!symbolInfo.Name(_Symbol))
   {
      Print("Error initializing symbol info");
      return(INIT_FAILED);
   }

   //--- Set up symbol properties
   SymbolDigits = (int)symbolInfo.Digits();
   PointValue = symbolInfo.Point();
   LotStep = symbolInfo.LotsStep();
   MinLot = symbolInfo.LotsMin();
   MaxLot = symbolInfo.LotsMax();
   TickValue = symbolInfo.TickValue();

   //--- Calculate PipValue based on Contract Size (most reliable method)
   //--- Contract Size is the definitive indicator of instrument type:
   //---   Forex:       100,000 (standard lot = 100k units)
   //---   Index:       1       (1 contract = 1 unit of index)
   //---   Gold:        100     (100 oz per lot)
   //---   Oil:         1,000   (1000 barrels per lot)
   //---   Silver:      5,000   (5000 oz per lot)

   double tickSize = symbolInfo.TickSize();
   double contractSize = symbolInfo.ContractSize();
   double tickValueMoney = symbolInfo.TickValue();
   string instrumentType = "";

   if(contractSize >= 100000)
   {
      //--- FOREX: Contract = 100,000
      //--- Pip = 10 points for 5/3 digit brokers, 1 point for 4/2 digit
      if(SymbolDigits == 3 || SymbolDigits == 5)
         PipValue = PointValue * 10;
      else
         PipValue = PointValue;
      instrumentType = "FOREX";
   }
   else if(contractSize == 1)
   {
      //--- INDEX: Contract = 1 (NAS100, US30, DAX, etc.)
      //--- Traders think in whole index points, so 1 pip = 1.0
      PipValue = 1.0;
      instrumentType = "INDEX";
   }
   else if(contractSize == 100)
   {
      //--- GOLD: Contract = 100 oz
      //--- Traders think in $0.10 moves, so 1 pip = 0.1
      PipValue = 0.1;
      instrumentType = "GOLD";
   }
   else if(contractSize >= 1000 && contractSize < 100000)
   {
      //--- COMMODITIES: Oil (1000), Silver (5000), etc.
      //--- Use point-based (similar to forex logic)
      if(SymbolDigits == 3 || SymbolDigits == 5)
         PipValue = PointValue * 10;
      else
         PipValue = PointValue;
      instrumentType = "COMMODITY";
   }
   else
   {
      //--- OTHER: Crypto, stocks, etc.
      //--- Default to point = pip
      PipValue = PointValue;
      instrumentType = "OTHER";
   }

   //--- Calculate point value in account currency (for lot sizing)
   double pointsPerTick = (tickSize > 0) ? tickSize / PointValue : 1;
   double pointValueInMoney = (pointsPerTick > 0) ? tickValueMoney / pointsPerTick : 0;

   //--- Safety check
   if(PipValue <= 0)
   {
      PipValue = PointValue;
      Print("Warning: PipValue was invalid, defaulting to Point");
   }

   //--- Log instrument detection
   PrintFormat("Instrument: %s | Type: %s | Contract: %.0f | Digits: %d",
               _Symbol, instrumentType, contractSize, SymbolDigits);
   PrintFormat("Point: %.6f | Pip: %.6f | TickSize: %.6f",
               PointValue, PipValue, tickSize);
   PrintFormat("TickValue: %.4f %s | PointValue: %.4f %s per lot",
               tickValueMoney, AccountInfoString(ACCOUNT_CURRENCY),
               pointValueInMoney, AccountInfoString(ACCOUNT_CURRENCY));

   //--- Initialize trade object
   trade.SetExpertMagicNumber(Magic);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);
   trade.SetAsyncMode(false);

   //--- Validate and initialize Multiple TPs
   if(UseMultipleTPs)
   {
      //--- Validate percentages sum to <= 100%
      double totalPercent = TP1Percent + TP2Percent;
      if(totalPercent > 100)
      {
         Print("ERROR: TP1Percent + TP2Percent cannot exceed 100%");
         Print("  TP1: ", TP1Percent, "% + TP2: ", TP2Percent, "% = ", totalPercent, "%");
         return(INIT_PARAMETERS_INCORRECT);
      }

      //--- Validate R:R ratios are increasing
      if(TP2RRRatio <= TP1RRRatio)
      {
         Print("WARNING: TP2 R:R (", TP2RRRatio, ") should be greater than TP1 R:R (", TP1RRRatio, ")");
      }
      if(TP3RRRatio <= TP2RRRatio)
      {
         Print("WARNING: TP3 R:R (", TP3RRRatio, ") should be greater than TP2 R:R (", TP2RRRatio, ")");
      }

      //--- Initialize MultiTP tracking array
      ArrayResize(MultiTPPositions, 0);
      MultiTPCount = 0;

      PrintFormat("MultiTP Enabled: TP1=%.1fR (%.0f%%), TP2=%.1fR (%.0f%%), TP3=%.1fR (%.0f%%)",
                  TP1RRRatio, TP1Percent, TP2RRRatio, TP2Percent, TP3RRRatio, 100 - totalPercent);
   }

   //--- Initialize position tracking array (for R:R calculations, breakeven, trailing)
   ArrayResize(TrackedPositions, 0);
   TrackedPositionCount = 0;

   //--- Initialize indicator handles
   if(!InitializeIndicators())
   {
      Print("Error initializing indicators");
      return(INIT_FAILED);
   }

   //--- Initialize timezone settings
   InitializeTimezone();

   //--- Initialize news filter
   InitializeNewsFilter();

   //--- Initialize range strategy based on selection
   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      InitializeSettlement();
      Print("Range Strategy: SETTLEMENT (Tick-based VWAP)");
   }
   else
   {
      InitializeIB();
      Print("Range Strategy: INITIAL BALANCE (Time-based)");
   }
   LastTradeDate = TimeCurrent();

   //--- Initialize daily tracking
   TodayStartBalance = accountInfo.Balance();
   TodayHighBalance = TodayStartBalance;
   AccountHighBalance = TodayStartBalance;

   //--- Create dashboard
   if(ShowDashboard)
   {
      CreateDashboard();
   }

   //--- Create manual buttons
   if(ShowManualButtons)
   {
      CreateManualButtons();
   }

   //--- Set up timer for time-based checks
   EventSetTimer(1);

   //--- Initialize logging system
   InitializeLogging();

   //--- Print startup info
   PrintStartupInfo();

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   //--- Kill timer
   EventKillTimer();

   //--- Release indicator handles
   ReleaseIndicators();

   //--- Clean up chart objects
   CleanupChartObjects();

   //--- Remove Settlement lines if Settlement strategy was used
   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      RemoveSettlementLines();
   }

   //--- Clean up tracking arrays
   ArrayResize(TrackedPositions, 0);
   TrackedPositionCount = 0;
   ArrayResize(MultiTPPositions, 0);
   MultiTPCount = 0;

   //--- Close log files
   CloseLogFiles();

   Print("RangePredator EA deinitialized. Reason: ", reason);
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   //--- Refresh symbol info
   symbolInfo.RefreshRates();

   //--- Check if trading is allowed
   if(!IsTradeAllowed())
      return;

   //--- Set global new bar flag ONCE per tick (prevents multiple IsNewBar() calls from conflicting)
   CurrentTickIsNewBar = IsNewBar();

   //--- Update range levels based on selected strategy
   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      UpdateSettlementLevels();
   }
   else
   {
      UpdateIBLevels();
   }

   //--- Manage existing positions
   ManagePositions();

   //--- Unified signal processing based on entry mode and events
   ProcessEntrySignals();

   //--- Update dashboard
   if(ShowDashboard)
   {
      UpdateDashboard();
   }

   //--- Update visual elements
   UpdateVisualElements();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   //--- Update DST status periodically
   UpdateDSTStatus();

   //--- Check for timezone updates and daily resets based on strategy
   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      //--- Check for Settlement daily reset
      CheckSettlementDailyReset();
   }
   else
   {
      //--- Check for IB timezone updates (DST changes)
      CheckIBTimezoneUpdate();

      //--- Check for IB daily reset
      CheckIBDailyReset();
   }

   //--- Check for daily reset
   CheckDailyReset();

   //--- Check for end of day close
   CheckEndOfDayClose();

   //--- Check drawdown limits
   CheckDrawdownLimits();

   //--- Update news data periodically (calendar mode)
   if(UseNewsFilter && NewsFilterMode == NEWS_MODE_CALENDAR)
   {
      UpdateNewsData();
   }
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   //--- Handle button clicks
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      HandleButtonClick(sparam);
   }
}

//+------------------------------------------------------------------+
//| Initialize indicator handles                                     |
//+------------------------------------------------------------------+
bool InitializeIndicators()
{
   //--- ATR for volatility filter
   ATRHandle = iATR(_Symbol, ATRTimeframe, ATRPeriod);
   if(ATRHandle == INVALID_HANDLE)
   {
      Print("Error creating ATR indicator handle");
      return false;
   }

   //--- Trend indicators
   if(UseTrendFilter)
   {
      //--- Moving Average(s)
      if(TrendMethod == TREND_MA || TrendMethod == TREND_MA_CROSS)
      {
         MA1Handle = iMA(_Symbol, TrendTimeframe, MA1Period, 0, MAMethod, PRICE_CLOSE);
         if(MA1Handle == INVALID_HANDLE)
         {
            Print("Error creating MA1 indicator handle");
            return false;
         }

         if(TrendMethod == TREND_MA_CROSS)
         {
            MA2Handle = iMA(_Symbol, TrendTimeframe, MA2Period, 0, MAMethod, PRICE_CLOSE);
            if(MA2Handle == INVALID_HANDLE)
            {
               Print("Error creating MA2 indicator handle");
               return false;
            }
         }
      }

      //--- ADX
      if(TrendMethod == TREND_ADX)
      {
         ADXHandle = iADX(_Symbol, TrendTimeframe, ADXPeriod);
         if(ADXHandle == INVALID_HANDLE)
         {
            Print("Error creating ADX indicator handle");
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Release indicator handles                                        |
//+------------------------------------------------------------------+
void ReleaseIndicators()
{
   if(ATRHandle != INVALID_HANDLE)
      IndicatorRelease(ATRHandle);
   if(MA1Handle != INVALID_HANDLE)
      IndicatorRelease(MA1Handle);
   if(MA2Handle != INVALID_HANDLE)
      IndicatorRelease(MA2Handle);
   if(ADXHandle != INVALID_HANDLE)
      IndicatorRelease(ADXHandle);
}

//+------------------------------------------------------------------+
//| TIMEZONE HELPER FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize timezone settings on startup                          |
//+------------------------------------------------------------------+
void InitializeTimezone()
{
   //--- Detect server GMT offset if auto-detect is enabled
   if(AutoDetectServerOffset)
   {
      DetectedServerGMTOffset = DetectServerGMTOffset();
   }
   else
   {
      DetectedServerGMTOffset = ServerToGMTOffset;
   }

   //--- Update DST status
   UpdateDSTStatus();

   Print("Timezone initialized:");
   Print("  Server GMT Offset: ", DetectedServerGMTOffset, " hours");
   Print("  London GMT Offset: ", LondonGMTOffset, " hours (DST: ", IsLondonDST, ")");
   Print("  New York GMT Offset: ", NewYorkGMTOffset, " hours (DST: ", IsNewYorkDST, ")");
}

//+------------------------------------------------------------------+
//| Detect server GMT offset by comparing server time to GMT         |
//+------------------------------------------------------------------+
int DetectServerGMTOffset()
{
   //--- Method 1: Use TimeGMT() if available (MQL5)
   datetime serverTime = TimeCurrent();
   datetime gmtTime = TimeGMT();

   //--- Calculate difference in hours
   int diffSeconds = (int)(serverTime - gmtTime);
   int diffHours = diffSeconds / 3600;

   //--- Round to nearest hour (handle slight time differences)
   if(MathAbs(diffSeconds % 3600) > 1800)
   {
      diffHours += (diffSeconds > 0) ? 1 : -1;
   }

   return diffHours;
}

//+------------------------------------------------------------------+
//| Update DST status for London and New York                        |
//+------------------------------------------------------------------+
void UpdateDSTStatus()
{
   datetime currentTime = TimeCurrent();

   //--- Only check once per hour to save resources
   if(currentTime - LastDSTCheck < 3600 && LastDSTCheck > 0)
      return;

   LastDSTCheck = currentTime;

   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   //--- Check DST mode
   if(DSTMode == DST_ON)
   {
      IsLondonDST = true;
      IsNewYorkDST = true;
   }
   else if(DSTMode == DST_OFF)
   {
      IsLondonDST = false;
      IsNewYorkDST = false;
   }
   else // DST_AUTO
   {
      //--- Auto-detect DST based on date
      IsLondonDST = IsLondonInDST(dt);
      IsNewYorkDST = IsNewYorkInDST(dt);
   }

   //--- Update GMT offsets based on DST
   LondonGMTOffset = IsLondonDST ? 1 : 0;      // GMT+0 or GMT+1 (BST)
   NewYorkGMTOffset = IsNewYorkDST ? -4 : -5;  // EST (GMT-5) or EDT (GMT-4)
}

//+------------------------------------------------------------------+
//| Check if London is in DST (last Sunday March - last Sunday Oct)  |
//+------------------------------------------------------------------+
bool IsLondonInDST(MqlDateTime &dt)
{
   //--- DST starts: Last Sunday of March at 01:00 UTC
   //--- DST ends: Last Sunday of October at 02:00 UTC

   int month = dt.mon;
   int day = dt.day;
   int dayOfWeek = dt.day_of_week; // 0 = Sunday

   //--- November to February: No DST
   if(month < 3 || month > 10)
      return false;

   //--- April to September: DST active
   if(month > 3 && month < 10)
      return true;

   //--- March: Check if past last Sunday
   if(month == 3)
   {
      int lastSunday = GetLastSundayOfMonth(dt.year, 3);
      return (day > lastSunday) || (day == lastSunday && dt.hour >= 1);
   }

   //--- October: Check if before last Sunday
   if(month == 10)
   {
      int lastSunday = GetLastSundayOfMonth(dt.year, 10);
      return (day < lastSunday) || (day == lastSunday && dt.hour < 2);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if New York is in DST (2nd Sunday March - 1st Sunday Nov)  |
//+------------------------------------------------------------------+
bool IsNewYorkInDST(MqlDateTime &dt)
{
   //--- DST starts: Second Sunday of March at 02:00 local
   //--- DST ends: First Sunday of November at 02:00 local

   int month = dt.mon;
   int day = dt.day;

   //--- December to February: No DST
   if(month < 3 || month > 11)
      return false;

   //--- April to October: DST active
   if(month > 3 && month < 11)
      return true;

   //--- March: Check if past second Sunday
   if(month == 3)
   {
      int secondSunday = GetNthSundayOfMonth(dt.year, 3, 2);
      return (day > secondSunday) || (day == secondSunday && dt.hour >= 2);
   }

   //--- November: Check if before first Sunday
   if(month == 11)
   {
      int firstSunday = GetNthSundayOfMonth(dt.year, 11, 1);
      return (day < firstSunday) || (day == firstSunday && dt.hour < 2);
   }

   return false;
}

//+------------------------------------------------------------------+
//| Get the last Sunday of a given month                             |
//+------------------------------------------------------------------+
int GetLastSundayOfMonth(int year, int month)
{
   //--- Get last day of month
   int lastDay = 31;
   if(month == 4 || month == 6 || month == 9 || month == 11)
      lastDay = 30;
   else if(month == 2)
      lastDay = ((year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)) ? 29 : 28;

   //--- Find day of week for last day
   MqlDateTime tempDt;
   tempDt.year = year;
   tempDt.mon = month;
   tempDt.day = lastDay;
   tempDt.hour = 12;
   tempDt.min = 0;
   tempDt.sec = 0;

   datetime tempTime = StructToTime(tempDt);
   TimeToStruct(tempTime, tempDt);

   //--- Calculate last Sunday
   int dayOfWeek = tempDt.day_of_week; // 0 = Sunday
   return lastDay - dayOfWeek;
}

//+------------------------------------------------------------------+
//| Get the Nth Sunday of a given month                              |
//+------------------------------------------------------------------+
int GetNthSundayOfMonth(int year, int month, int n)
{
   //--- Find day of week for first day of month
   MqlDateTime tempDt;
   tempDt.year = year;
   tempDt.mon = month;
   tempDt.day = 1;
   tempDt.hour = 12;
   tempDt.min = 0;
   tempDt.sec = 0;

   datetime tempTime = StructToTime(tempDt);
   TimeToStruct(tempTime, tempDt);

   int dayOfWeek = tempDt.day_of_week; // 0 = Sunday

   //--- Calculate first Sunday
   int firstSunday = (dayOfWeek == 0) ? 1 : (8 - dayOfWeek);

   //--- Calculate Nth Sunday
   return firstSunday + (n - 1) * 7;
}

//+------------------------------------------------------------------+
//| Convert time from specified timezone to server time              |
//+------------------------------------------------------------------+
datetime ConvertToServerTime(int hour, int minute, ENUM_TIMEZONE fromTimezone)
{
   //--- Update DST status
   UpdateDSTStatus();

   //--- Get current date
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   //--- Calculate GMT time first
   int gmtHour = hour;
   int gmtMinute = minute;

   switch(fromTimezone)
   {
      case TZ_SERVER:
         //--- Already server time, no conversion needed
         dt.hour = hour;
         dt.min = minute;
         dt.sec = 0;
         return StructToTime(dt);

      case TZ_LOCAL:
         //--- Convert local to GMT, then GMT to server
         {
            datetime localDt = TimeLocal();
            datetime gmtDt = TimeGMT();
            int localToGMT = (int)(gmtDt - localDt) / 3600;
            gmtHour = hour + localToGMT;
         }
         break;

      case TZ_LONDON:
         //--- London to GMT
         gmtHour = hour - LondonGMTOffset;
         break;

      case TZ_NEWYORK:
         //--- New York to GMT
         gmtHour = hour - NewYorkGMTOffset;
         break;
   }

   //--- Convert GMT to server time
   gmtHour = gmtHour + DetectedServerGMTOffset;

   //--- Handle day overflow/underflow
   while(gmtHour >= 24)
   {
      gmtHour -= 24;
      dt.day++;
   }
   while(gmtHour < 0)
   {
      gmtHour += 24;
      dt.day--;
   }

   dt.hour = gmtHour;
   dt.min = gmtMinute;
   dt.sec = 0;

   return StructToTime(dt);
}

//+------------------------------------------------------------------+
//| Convert server time to specified timezone                        |
//+------------------------------------------------------------------+
void ConvertFromServerTime(datetime serverTime, ENUM_TIMEZONE toTimezone, int &outHour, int &outMinute)
{
   //--- Update DST status
   UpdateDSTStatus();

   MqlDateTime dt;
   TimeToStruct(serverTime, dt);

   int hour = dt.hour;
   int minute = dt.min;

   switch(toTimezone)
   {
      case TZ_SERVER:
         //--- Already server time
         break;

      case TZ_LOCAL:
         //--- Server to local
         {
            datetime serverNow = TimeCurrent();
            datetime localNow = TimeLocal();
            int serverToLocal = (int)(localNow - serverNow) / 3600;
            hour = hour + serverToLocal;
         }
         break;

      case TZ_LONDON:
         //--- Server to GMT, then GMT to London
         hour = hour - DetectedServerGMTOffset + LondonGMTOffset;
         break;

      case TZ_NEWYORK:
         //--- Server to GMT, then GMT to New York
         hour = hour - DetectedServerGMTOffset + NewYorkGMTOffset;
         break;
   }

   //--- Handle day overflow/underflow
   while(hour >= 24) hour -= 24;
   while(hour < 0) hour += 24;

   outHour = hour;
   outMinute = minute;
}

//+------------------------------------------------------------------+
//| Get current time in specified timezone                           |
//+------------------------------------------------------------------+
void GetCurrentTimeInZone(ENUM_TIMEZONE timezone, int &outHour, int &outMinute, int &outSecond)
{
   ConvertFromServerTime(TimeCurrent(), timezone, outHour, outMinute);

   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   outSecond = dt.sec;
}

//+------------------------------------------------------------------+
//| Parse time string "HH:MM" and extract hour/minute                |
//+------------------------------------------------------------------+
void ParseTimeString(string timeStr, int &hour, int &minute)
{
   //--- Parse "HH:MM" format
   int colonPos = StringFind(timeStr, ":");
   if(colonPos < 0)
   {
      Print("Invalid time format: ", timeStr, ". Expected HH:MM");
      hour = 0;
      minute = 0;
      return;
   }

   hour = (int)StringToInteger(StringSubstr(timeStr, 0, colonPos));
   minute = (int)StringToInteger(StringSubstr(timeStr, colonPos + 1));

   //--- Validate
   if(hour < 0 || hour > 23 || minute < 0 || minute > 59)
   {
      Print("Invalid time values: ", timeStr);
      hour = 0;
      minute = 0;
   }
}

//+------------------------------------------------------------------+
//| Parse time string "HH:MM" and convert to server time             |
//+------------------------------------------------------------------+
datetime ParseTimeStringToServer(string timeStr, ENUM_TIMEZONE fromTimezone)
{
   int hour, minute;
   ParseTimeString(timeStr, hour, minute);

   if(hour == 0 && minute == 0 && StringFind(timeStr, "00:00") < 0)
      return 0; // Invalid time

   return ConvertToServerTime(hour, minute, fromTimezone);
}

//+------------------------------------------------------------------+
//| Check if current time is within a time range (in specified TZ)   |
//+------------------------------------------------------------------+
bool IsWithinTimeRange(string startTimeStr, string endTimeStr, ENUM_TIMEZONE timezone)
{
   int currentHour, currentMinute, currentSecond;
   GetCurrentTimeInZone(timezone, currentHour, currentMinute, currentSecond);

   //--- Parse start time
   int colonPos = StringFind(startTimeStr, ":");
   int startHour = (int)StringToInteger(StringSubstr(startTimeStr, 0, colonPos));
   int startMinute = (int)StringToInteger(StringSubstr(startTimeStr, colonPos + 1));

   //--- Parse end time
   colonPos = StringFind(endTimeStr, ":");
   int endHour = (int)StringToInteger(StringSubstr(endTimeStr, 0, colonPos));
   int endMinute = (int)StringToInteger(StringSubstr(endTimeStr, colonPos + 1));

   //--- Convert to minutes for easier comparison
   int currentMins = currentHour * 60 + currentMinute;
   int startMins = startHour * 60 + startMinute;
   int endMins = endHour * 60 + endMinute;

   //--- Handle overnight ranges (e.g., 22:00 - 06:00)
   if(endMins < startMins)
   {
      return (currentMins >= startMins || currentMins < endMins);
   }
   else
   {
      return (currentMins >= startMins && currentMins < endMins);
   }
}

//+------------------------------------------------------------------+
//| Get timezone name for display                                    |
//+------------------------------------------------------------------+
string GetTimezoneName(ENUM_TIMEZONE timezone)
{
   switch(timezone)
   {
      case TZ_SERVER:   return "Server";
      case TZ_LOCAL:    return "Local";
      case TZ_LONDON:   return IsLondonDST ? "London (BST)" : "London (GMT)";
      case TZ_NEWYORK:  return IsNewYorkDST ? "New York (EDT)" : "New York (EST)";
      default:          return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Format time for display in specified timezone                    |
//+------------------------------------------------------------------+
string FormatTimeInZone(datetime serverTime, ENUM_TIMEZONE timezone)
{
   int hour, minute;
   ConvertFromServerTime(serverTime, timezone, hour, minute);
   return StringFormat("%02d:%02d", hour, minute);
}

//+------------------------------------------------------------------+
//| STOP LOSS & TAKE PROFIT CALCULATION FUNCTIONS                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Get current ATR value                                            |
//+------------------------------------------------------------------+
double GetATRValue()
{
   double atrBuffer[];
   ArraySetAsSeries(atrBuffer, true);

   if(CopyBuffer(ATRHandle, 0, 0, 1, atrBuffer) <= 0)
   {
      Print("Error copying ATR buffer: ", GetLastError());
      return 0;
   }

   return atrBuffer[0];
}

//+------------------------------------------------------------------+
//| Convert pips to price distance                                   |
//+------------------------------------------------------------------+
double PipsToPrice(double pips)
{
   return pips * PipValue;
}

//+------------------------------------------------------------------+
//| Convert price distance to pips                                   |
//+------------------------------------------------------------------+
double PriceToPips(double priceDistance)
{
   if(PipValue == 0) return 0;
   return priceDistance / PipValue;
}

//+------------------------------------------------------------------+
//| Find swing high within lookback period                           |
//+------------------------------------------------------------------+
double FindSwingHigh(int lookback, int startBar = 1)
{
   double highestHigh = 0;

   for(int i = startBar; i <= startBar + lookback; i++)
   {
      double high = iHigh(_Symbol, PERIOD_CURRENT, i);
      if(high > highestHigh || highestHigh == 0)
         highestHigh = high;
   }

   return highestHigh;
}

//+------------------------------------------------------------------+
//| Find swing low within lookback period                            |
//+------------------------------------------------------------------+
double FindSwingLow(int lookback, int startBar = 1)
{
   double lowestLow = 0;

   for(int i = startBar; i <= startBar + lookback; i++)
   {
      double low = iLow(_Symbol, PERIOD_CURRENT, i);
      if(low < lowestLow || lowestLow == 0)
         lowestLow = low;
   }

   return lowestLow;
}

//+------------------------------------------------------------------+
//| Get breakout candle high (for SL calculation)                    |
//+------------------------------------------------------------------+
double GetBreakoutCandleHigh(int barsBack = 1)
{
   return iHigh(_Symbol, PERIOD_CURRENT, barsBack);
}

//+------------------------------------------------------------------+
//| Get breakout candle low (for SL calculation)                     |
//+------------------------------------------------------------------+
double GetBreakoutCandleLow(int barsBack = 1)
{
   return iLow(_Symbol, PERIOD_CURRENT, barsBack);
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss for a BUY trade                              |
//+------------------------------------------------------------------+
double CalculateBuySL(double entryPrice, double &slDistance)
{
   double sl = 0;
   double atr = GetATRValue();

   switch(SLMode)
   {
      case SL_FIXED_PIPS:
         slDistance = PipsToPrice(SLFixedPips);
         sl = entryPrice - slDistance;
         break;

      case SL_ATR_MULTIPLE:
         slDistance = atr * SLATRMultiple;
         sl = entryPrice - slDistance;
         break;

      case SL_IB_MULTIPLE:
         {
            //--- Use Settlement or IB range based on strategy
            double rangeValue = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementRange : IBRange;
            if(rangeValue > 0)
            {
               slDistance = rangeValue * SLIBMultiple;
               sl = entryPrice - slDistance;
            }
            else
            {
               //--- Fallback to fixed pips if range not set
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice - slDistance;
            }
         }
         break;

      case SL_FIXED_MONEY:
         {
            //--- Calculate SL distance based on fixed money risk
            //--- This requires lot size, so we return a placeholder
            //--- Actual calculation done in position sizing
            double tickValue = symbolInfo.TickValue();
            double lotSize = FixedLotSize; // Will be recalculated
            if(tickValue > 0 && lotSize > 0)
            {
               double ticksForRisk = SLFixedMoney / (tickValue * lotSize);
               slDistance = ticksForRisk * symbolInfo.TickSize();
               sl = entryPrice - slDistance;
            }
            else
            {
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice - slDistance;
            }
         }
         break;

      case SL_BEYOND_IB:
         //--- SL below IB/Settlement Low + buffer
         {
            double lowLevel = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementLow : IBLow;
            if(lowLevel > 0)
            {
               sl = lowLevel - PipsToPrice(SLBufferPips);
               slDistance = entryPrice - sl;
            }
            else
            {
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice - slDistance;
            }
         }
         break;

      case SL_BEYOND_CANDLE:
         {
            //--- SL below the breakout candle low + buffer
            double candleLow = GetBreakoutCandleLow(1);
            sl = candleLow - PipsToPrice(SLBufferPips);
            slDistance = entryPrice - sl;
         }
         break;

      case SL_SWING:
         {
            //--- SL below recent swing low + buffer
            double swingLow = FindSwingLow(SwingLookback);
            sl = swingLow - PipsToPrice(SLBufferPips);
            slDistance = entryPrice - sl;
         }
         break;

      default:
         slDistance = PipsToPrice(SLFixedPips);
         sl = entryPrice - slDistance;
         break;
   }

   //--- Normalize to symbol digits
   sl = NormalizeDouble(sl, SymbolDigits);
   slDistance = NormalizeDouble(slDistance, SymbolDigits);

   return sl;
}

//+------------------------------------------------------------------+
//| Calculate Stop Loss for a SELL trade                             |
//+------------------------------------------------------------------+
double CalculateSellSL(double entryPrice, double &slDistance)
{
   double sl = 0;
   double atr = GetATRValue();

   switch(SLMode)
   {
      case SL_FIXED_PIPS:
         slDistance = PipsToPrice(SLFixedPips);
         sl = entryPrice + slDistance;
         break;

      case SL_ATR_MULTIPLE:
         slDistance = atr * SLATRMultiple;
         sl = entryPrice + slDistance;
         break;

      case SL_IB_MULTIPLE:
         {
            //--- Use Settlement or IB range based on strategy
            double rangeValue = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementRange : IBRange;
            if(rangeValue > 0)
            {
               slDistance = rangeValue * SLIBMultiple;
               sl = entryPrice + slDistance;
            }
            else
            {
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice + slDistance;
            }
         }
         break;

      case SL_FIXED_MONEY:
         {
            double tickValue = symbolInfo.TickValue();
            double lotSize = FixedLotSize;
            if(tickValue > 0 && lotSize > 0)
            {
               double ticksForRisk = SLFixedMoney / (tickValue * lotSize);
               slDistance = ticksForRisk * symbolInfo.TickSize();
               sl = entryPrice + slDistance;
            }
            else
            {
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice + slDistance;
            }
         }
         break;

      case SL_BEYOND_IB:
         //--- SL above IB/Settlement High + buffer
         {
            double highLevel = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementHigh : IBHigh;
            if(highLevel > 0)
            {
               sl = highLevel + PipsToPrice(SLBufferPips);
               slDistance = sl - entryPrice;
            }
            else
            {
               slDistance = PipsToPrice(SLFixedPips);
               sl = entryPrice + slDistance;
            }
         }
         break;

      case SL_BEYOND_CANDLE:
         {
            //--- SL above the breakout candle high + buffer
            double candleHigh = GetBreakoutCandleHigh(1);
            sl = candleHigh + PipsToPrice(SLBufferPips);
            slDistance = sl - entryPrice;
         }
         break;

      case SL_SWING:
         {
            //--- SL above recent swing high + buffer
            double swingHigh = FindSwingHigh(SwingLookback);
            sl = swingHigh + PipsToPrice(SLBufferPips);
            slDistance = sl - entryPrice;
         }
         break;

      default:
         slDistance = PipsToPrice(SLFixedPips);
         sl = entryPrice + slDistance;
         break;
   }

   //--- Normalize to symbol digits
   sl = NormalizeDouble(sl, SymbolDigits);
   slDistance = NormalizeDouble(slDistance, SymbolDigits);

   return sl;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit for a BUY trade                            |
//+------------------------------------------------------------------+
double CalculateBuyTP(double entryPrice, double slDistance, double &tpDistance)
{
   double tp = 0;
   double atr = GetATRValue();

   switch(TPMode)
   {
      case TP_FIXED_PIPS:
         tpDistance = PipsToPrice(TPFixedPips);
         tp = entryPrice + tpDistance;
         break;

      case TP_ATR_MULTIPLE:
         tpDistance = atr * TPATRMultiple;
         tp = entryPrice + tpDistance;
         break;

      case TP_IB_MULTIPLE:
         {
            //--- Use Settlement or IB range based on strategy
            double rangeValue = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementRange : IBRange;
            if(rangeValue > 0)
            {
               tpDistance = rangeValue * TPIBMultiple;
               tp = entryPrice + tpDistance;
            }
            else
            {
               tpDistance = PipsToPrice(TPFixedPips);
               tp = entryPrice + tpDistance;
            }
         }
         break;

      case TP_FIXED_MONEY:
         {
            double tickValue = symbolInfo.TickValue();
            double lotSize = FixedLotSize;
            if(tickValue > 0 && lotSize > 0)
            {
               double ticksForProfit = TPFixedMoney / (tickValue * lotSize);
               tpDistance = ticksForProfit * symbolInfo.TickSize();
               tp = entryPrice + tpDistance;
            }
            else
            {
               tpDistance = PipsToPrice(TPFixedPips);
               tp = entryPrice + tpDistance;
            }
         }
         break;

      case TP_RR_RATIO:
         //--- TP based on Risk:Reward ratio
         tpDistance = slDistance * TPRRRatio;
         tp = entryPrice + tpDistance;
         break;

      case TP_IB_MIDPOINT:
         //--- TP at IB/Settlement midpoint (for fade trades)
         {
            double midpoint = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementMidpoint : IBMidpoint;
            if(midpoint > 0)
            {
               tp = midpoint;
               tpDistance = tp - entryPrice;
               //--- If entry is below midpoint, this doesn't make sense for a buy
               if(tpDistance <= 0)
               {
                  tpDistance = slDistance * TPRRRatio;
                  tp = entryPrice + tpDistance;
               }
            }
            else
            {
               tpDistance = slDistance * TPRRRatio;
               tp = entryPrice + tpDistance;
            }
         }
         break;

      case TP_IB_OPPOSITE:
         //--- TP at opposite IB/Settlement level (High for buy)
         {
            double highLevel = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementHigh : IBHigh;
            if(highLevel > 0)
            {
               tp = highLevel;
               tpDistance = tp - entryPrice;
               //--- If entry is at or above High, use R:R
               if(tpDistance <= 0)
               {
                  tpDistance = slDistance * TPRRRatio;
                  tp = entryPrice + tpDistance;
               }
            }
            else
            {
               tpDistance = slDistance * TPRRRatio;
               tp = entryPrice + tpDistance;
            }
         }
         break;

      case TP_NONE:
         tp = 0;
         tpDistance = 0;
         break;

      default:
         tpDistance = slDistance * TPRRRatio;
         tp = entryPrice + tpDistance;
         break;
   }

   //--- Normalize to symbol digits
   if(tp > 0)
      tp = NormalizeDouble(tp, SymbolDigits);
   tpDistance = NormalizeDouble(tpDistance, SymbolDigits);

   return tp;
}

//+------------------------------------------------------------------+
//| Calculate Take Profit for a SELL trade                           |
//+------------------------------------------------------------------+
double CalculateSellTP(double entryPrice, double slDistance, double &tpDistance)
{
   double tp = 0;
   double atr = GetATRValue();

   switch(TPMode)
   {
      case TP_FIXED_PIPS:
         tpDistance = PipsToPrice(TPFixedPips);
         tp = entryPrice - tpDistance;
         break;

      case TP_ATR_MULTIPLE:
         tpDistance = atr * TPATRMultiple;
         tp = entryPrice - tpDistance;
         break;

      case TP_IB_MULTIPLE:
         {
            //--- Use Settlement or IB range based on strategy
            double rangeValue = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementRange : IBRange;
            if(rangeValue > 0)
            {
               tpDistance = rangeValue * TPIBMultiple;
               tp = entryPrice - tpDistance;
            }
            else
            {
               tpDistance = PipsToPrice(TPFixedPips);
               tp = entryPrice - tpDistance;
            }
         }
         break;

      case TP_FIXED_MONEY:
         {
            double tickValue = symbolInfo.TickValue();
            double lotSize = FixedLotSize;
            if(tickValue > 0 && lotSize > 0)
            {
               double ticksForProfit = TPFixedMoney / (tickValue * lotSize);
               tpDistance = ticksForProfit * symbolInfo.TickSize();
               tp = entryPrice - tpDistance;
            }
            else
            {
               tpDistance = PipsToPrice(TPFixedPips);
               tp = entryPrice - tpDistance;
            }
         }
         break;

      case TP_RR_RATIO:
         tpDistance = slDistance * TPRRRatio;
         tp = entryPrice - tpDistance;
         break;

      case TP_IB_MIDPOINT:
         //--- TP at IB/Settlement midpoint (for fade trades)
         {
            double midpoint = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementMidpoint : IBMidpoint;
            if(midpoint > 0)
            {
               tp = midpoint;
               tpDistance = entryPrice - tp;
               //--- If entry is above midpoint, this doesn't make sense for a sell
               if(tpDistance <= 0)
               {
                  tpDistance = slDistance * TPRRRatio;
                  tp = entryPrice - tpDistance;
               }
            }
            else
            {
               tpDistance = slDistance * TPRRRatio;
               tp = entryPrice - tpDistance;
            }
         }
         break;

      case TP_IB_OPPOSITE:
         //--- TP at opposite IB/Settlement level (Low for sell)
         {
            double lowLevel = (RangeStrategy == STRATEGY_SETTLEMENT) ? SettlementLow : IBLow;
            if(lowLevel > 0)
            {
               tp = lowLevel;
               tpDistance = entryPrice - tp;
               //--- If entry is at or below Low, use R:R
               if(tpDistance <= 0)
               {
                  tpDistance = slDistance * TPRRRatio;
                  tp = entryPrice - tpDistance;
               }
            }
            else
            {
               tpDistance = slDistance * TPRRRatio;
               tp = entryPrice - tpDistance;
            }
         }
         break;

      case TP_NONE:
         tp = 0;
         tpDistance = 0;
         break;

      default:
         tpDistance = slDistance * TPRRRatio;
         tp = entryPrice - tpDistance;
         break;
   }

   //--- Normalize to symbol digits
   if(tp > 0)
      tp = NormalizeDouble(tp, SymbolDigits);
   tpDistance = NormalizeDouble(tpDistance, SymbolDigits);

   return tp;
}

//+------------------------------------------------------------------+
//| Calculate multiple TP levels for BUY trade                       |
//+------------------------------------------------------------------+
void CalculateBuyMultipleTPs(double entryPrice, double slDistance,
                              double &tp1, double &tp2, double &tp3)
{
   if(!UseMultipleTPs)
   {
      double tpDist;
      tp1 = CalculateBuyTP(entryPrice, slDistance, tpDist);
      tp2 = 0;
      tp3 = 0;
      return;
   }

   //--- Calculate TP levels based on R:R ratios
   tp1 = NormalizeDouble(entryPrice + (slDistance * TP1RRRatio), SymbolDigits);
   tp2 = NormalizeDouble(entryPrice + (slDistance * TP2RRRatio), SymbolDigits);
   tp3 = NormalizeDouble(entryPrice + (slDistance * TP3RRRatio), SymbolDigits);
}

//+------------------------------------------------------------------+
//| Calculate multiple TP levels for SELL trade                      |
//+------------------------------------------------------------------+
void CalculateSellMultipleTPs(double entryPrice, double slDistance,
                               double &tp1, double &tp2, double &tp3)
{
   if(!UseMultipleTPs)
   {
      double tpDist;
      tp1 = CalculateSellTP(entryPrice, slDistance, tpDist);
      tp2 = 0;
      tp3 = 0;
      return;
   }

   //--- Calculate TP levels based on R:R ratios
   tp1 = NormalizeDouble(entryPrice - (slDistance * TP1RRRatio), SymbolDigits);
   tp2 = NormalizeDouble(entryPrice - (slDistance * TP2RRRatio), SymbolDigits);
   tp3 = NormalizeDouble(entryPrice - (slDistance * TP3RRRatio), SymbolDigits);
}

//+------------------------------------------------------------------+
//| Calculate lot sizes for multiple TPs                             |
//+------------------------------------------------------------------+
void CalculateMultipleTPLots(double totalLots, double &lot1, double &lot2, double &lot3)
{
   if(!UseMultipleTPs)
   {
      lot1 = totalLots;
      lot2 = 0;
      lot3 = 0;
      return;
   }

   //--- Calculate lots for each TP based on percentages
   lot1 = NormalizeDouble(totalLots * (TP1Percent / 100.0), 2);
   lot2 = NormalizeDouble(totalLots * (TP2Percent / 100.0), 2);
   lot3 = totalLots - lot1 - lot2; // Remaining

   //--- Ensure minimum lot sizes
   double minLot = symbolInfo.LotsMin();
   double lotStep = symbolInfo.LotsStep();

   //--- Normalize to lot step
   lot1 = MathFloor(lot1 / lotStep) * lotStep;
   lot2 = MathFloor(lot2 / lotStep) * lotStep;
   lot3 = MathFloor(lot3 / lotStep) * lotStep;

   //--- Ensure minimums
   if(lot1 < minLot && lot1 > 0) lot1 = minLot;
   if(lot2 < minLot && lot2 > 0) lot2 = minLot;
   if(lot3 < minLot && lot3 > 0) lot3 = minLot;

   //--- If total exceeds, adjust
   double total = lot1 + lot2 + lot3;
   if(total > totalLots)
   {
      //--- Reduce lot3 first
      lot3 = totalLots - lot1 - lot2;
      if(lot3 < 0) lot3 = 0;
   }
}

//+------------------------------------------------------------------+
//| Check and apply breakeven                                        |
//+------------------------------------------------------------------+
bool CheckAndApplyBreakeven(ulong ticket)
{
   if(!UseBreakeven)
      return false;

   if(!positionInfo.SelectByTicket(ticket))
      return false;

   double entryPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double currentPrice = positionInfo.PriceCurrent();
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();

   //--- Check if already at breakeven (avoid redundant modifications)
   int trackIndex = FindTrackedPositionIndex(ticket);

   //--- Auto-register untracked positions (for positions opened before EA loaded)
   if(trackIndex < 0 && currentSL > 0)
   {
      int direction = (posType == POSITION_TYPE_BUY) ? 1 : -1;
      RegisterPositionForTracking(ticket, entryPrice, currentSL, direction, positionInfo.Volume());
      trackIndex = FindTrackedPositionIndex(ticket);
   }

   //--- Skip if breakeven already hit
   if(trackIndex >= 0 && TrackedPositions[trackIndex].breakevenHit)
      return false;

   double breakevenTrigger = PipsToPrice(BreakevenTriggerPips);
   double breakevenOffset = PipsToPrice(BreakevenOffsetPips);
   double newSL = 0;

   if(posType == POSITION_TYPE_BUY)
   {
      //--- Check if price has moved enough in profit
      if(currentPrice - entryPrice >= breakevenTrigger)
      {
         newSL = entryPrice + breakevenOffset;

         //--- Only move SL if new SL is better than current
         if(currentSL < newSL || currentSL == 0)
         {
            newSL = NormalizeDouble(newSL, SymbolDigits);
            if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
            {
               //--- Mark breakeven as hit to preserve original SL for R:R
               MarkBreakevenHit(ticket);

               if(EnableDebugMode)
                  Print("Breakeven applied for BUY position #", ticket, " New SL: ", newSL);
               return true;
            }
         }
      }
   }
   else if(posType == POSITION_TYPE_SELL)
   {
      //--- Check if price has moved enough in profit
      if(entryPrice - currentPrice >= breakevenTrigger)
      {
         newSL = entryPrice - breakevenOffset;

         //--- Only move SL if new SL is better than current
         if(currentSL > newSL || currentSL == 0)
         {
            newSL = NormalizeDouble(newSL, SymbolDigits);
            if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
            {
               //--- Mark breakeven as hit to preserve original SL for R:R
               MarkBreakevenHit(ticket);

               if(EnableDebugMode)
                  Print("Breakeven applied for SELL position #", ticket, " New SL: ", newSL);
               return true;
            }
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Register a position for tracking (called on trade open)          |
//+------------------------------------------------------------------+
void RegisterPositionForTracking(ulong ticket, double entry, double sl, int direction, double lots)
{
   if(ticket == 0 || sl == 0)
      return;

   //--- Check if already registered
   for(int i = 0; i < TrackedPositionCount; i++)
   {
      if(TrackedPositions[i].ticket == ticket)
         return;
   }

   //--- Resize array and add new position
   ArrayResize(TrackedPositions, TrackedPositionCount + 1);

   TrackedPositions[TrackedPositionCount].ticket = ticket;
   TrackedPositions[TrackedPositionCount].entryPrice = entry;
   TrackedPositions[TrackedPositionCount].originalSL = sl;
   TrackedPositions[TrackedPositionCount].slDistance = MathAbs(entry - sl);
   TrackedPositions[TrackedPositionCount].originalLots = lots;
   TrackedPositions[TrackedPositionCount].direction = direction;
   TrackedPositions[TrackedPositionCount].entryTime = TimeCurrent();
   TrackedPositions[TrackedPositionCount].breakevenHit = false;

   TrackedPositionCount++;

   if(EnableDebugMode)
      PrintFormat("Position #%d registered for tracking | Entry: %.5f | Original SL: %.5f | Risk: %.1f pips",
                  ticket, entry, sl, MathAbs(entry - sl) / PipValue);
}

//+------------------------------------------------------------------+
//| Find tracked position index by ticket                             |
//+------------------------------------------------------------------+
int FindTrackedPositionIndex(ulong ticket)
{
   for(int i = 0; i < TrackedPositionCount; i++)
   {
      if(TrackedPositions[i].ticket == ticket)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Remove position from tracking                                     |
//+------------------------------------------------------------------+
void RemoveFromPositionTracking(ulong ticket)
{
   int index = FindTrackedPositionIndex(ticket);
   if(index < 0)
      return;

   //--- Shift array elements
   for(int i = index; i < TrackedPositionCount - 1; i++)
   {
      TrackedPositions[i] = TrackedPositions[i + 1];
   }

   TrackedPositionCount--;
   ArrayResize(TrackedPositions, TrackedPositionCount);
}

//+------------------------------------------------------------------+
//| Clean up tracking for closed positions                            |
//+------------------------------------------------------------------+
void CleanupPositionTracking()
{
   for(int i = TrackedPositionCount - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByTicket(TrackedPositions[i].ticket))
      {
         RemoveFromPositionTracking(TrackedPositions[i].ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Mark position as breakeven hit                                    |
//+------------------------------------------------------------------+
void MarkBreakevenHit(ulong ticket)
{
   int index = FindTrackedPositionIndex(ticket);
   if(index >= 0)
   {
      TrackedPositions[index].breakevenHit = true;
   }
}

//+------------------------------------------------------------------+
//| Get ORIGINAL SL distance for R:R calculations                     |
//| This returns the original risk, not current SL distance           |
//+------------------------------------------------------------------+
double GetOriginalSLDistance(ulong ticket)
{
   //--- First check position tracking array
   int index = FindTrackedPositionIndex(ticket);
   if(index >= 0)
      return TrackedPositions[index].slDistance;

   //--- Then check MultiTP tracking array
   int mtpIndex = FindMultiTPIndex(ticket);
   if(mtpIndex >= 0)
      return MultiTPPositions[mtpIndex].slDistance;

   //--- Fallback: try to calculate from current position (may be wrong if BE was hit)
   if(!positionInfo.SelectByTicket(ticket))
      return 0;

   double entryPrice = positionInfo.PriceOpen();
   double sl = positionInfo.StopLoss();

   if(sl == 0)
      return 0;

   return MathAbs(entryPrice - sl);
}

//+------------------------------------------------------------------+
//| Get original SL price for a position                              |
//+------------------------------------------------------------------+
double GetOriginalSL(ulong ticket)
{
   int index = FindTrackedPositionIndex(ticket);
   if(index >= 0)
      return TrackedPositions[index].originalSL;

   int mtpIndex = FindMultiTPIndex(ticket);
   if(mtpIndex >= 0)
      return MultiTPPositions[mtpIndex].originalSL;

   //--- Fallback to current SL
   if(positionInfo.SelectByTicket(ticket))
      return positionInfo.StopLoss();

   return 0;
}

//+------------------------------------------------------------------+
//| Legacy function - for backwards compatibility                     |
//+------------------------------------------------------------------+
double GetPositionSLDistance(ulong ticket)
{
   return GetOriginalSLDistance(ticket);
}

//+------------------------------------------------------------------+
//| Check and apply trailing stop                                    |
//+------------------------------------------------------------------+
bool CheckAndApplyTrailingStop(ulong ticket)
{
   if(TrailingMode == TRAIL_NONE)
      return false;

   if(!positionInfo.SelectByTicket(ticket))
      return false;

   double entryPrice = positionInfo.PriceOpen();
   double currentSL = positionInfo.StopLoss();
   double currentPrice = positionInfo.PriceCurrent();
   ENUM_POSITION_TYPE posType = positionInfo.PositionType();

   //--- Get ORIGINAL SL distance for R:R calculations (not current SL which may be at breakeven)
   double slDistance = GetOriginalSLDistance(ticket);

   //--- If not tracked, try to register now (for positions opened before EA loaded)
   if(slDistance <= 0)
   {
      //--- Try to use current SL as fallback (only valid if BE not hit yet)
      slDistance = MathAbs(entryPrice - currentSL);

      if(slDistance > 0)
      {
         //--- Register for future tracking
         int direction = (posType == POSITION_TYPE_BUY) ? 1 : -1;
         RegisterPositionForTracking(ticket, entryPrice, currentSL, direction, positionInfo.Volume());
      }
   }

   //--- Still no SL distance? Cannot calculate R:R
   if(slDistance <= 0 && (TrailStartMode == TRAIL_START_RR || TrailingMode == TRAIL_RR))
   {
      if(EnableDebugMode)
         Print("Trailing: Cannot calculate R:R - no original SL distance available");
      return false;
   }

   //--- Calculate trailing start threshold
   double trailingStart = 0;
   switch(TrailStartMode)
   {
      case TRAIL_START_PIPS:
         trailingStart = PipsToPrice(TrailingStartPips);
         break;

      case TRAIL_START_RR:
         trailingStart = slDistance * TrailingStartRR;
         break;
   }

   //--- Calculate current profit distance
   double profitDistance = 0;
   if(posType == POSITION_TYPE_BUY)
      profitDistance = currentPrice - entryPrice;
   else
      profitDistance = entryPrice - currentPrice;

   //--- Check if trailing should start
   if(profitDistance < trailingStart)
      return false;

   //--- Calculate trailing distance based on mode
   double trailingDistance = 0;
   switch(TrailingMode)
   {
      case TRAIL_FIXED_PIPS:
         trailingDistance = PipsToPrice(TrailingDistancePips);
         break;

      case TRAIL_ATR:
         trailingDistance = GetATRValue() * TrailingATRMultiple;
         break;

      case TRAIL_PERCENT:
         //--- Lock a percentage of the current profit
         if(profitDistance > 0)
            trailingDistance = profitDistance * (1.0 - TrailingPercent / 100.0);
         else
            return false;
         break;

      case TRAIL_RR:
         //--- Trail by R-multiple (e.g., 0.5R behind price)
         trailingDistance = slDistance * TrailingDistanceRR;
         break;

      default:
         return false;
   }

   //--- Calculate new SL
   double newSL = 0;
   double trailingStep = PipsToPrice(TrailingStepPips);

   if(posType == POSITION_TYPE_BUY)
   {
      newSL = currentPrice - trailingDistance;

      //--- Ensure SL is not below entry (always protect capital)
      if(newSL < entryPrice)
         newSL = entryPrice;

      //--- Only move SL if it's better than current and meets step requirement
      if(currentSL == 0 || (newSL > currentSL + trailingStep))
      {
         newSL = NormalizeDouble(newSL, SymbolDigits);

         if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
         {
            if(EnableDebugMode)
            {
               //--- Calculate current R locked (avoid divide by zero)
               double rLocked = (slDistance > 0) ? (newSL - entryPrice) / slDistance : 0;
               PrintFormat("Trailing BUY #%d: SL %.5f -> %.5f (%.2fR locked) | Price: %.5f | Mode: %s",
                           ticket, currentSL, newSL, rLocked, currentPrice,
                           EnumToString(TrailingMode));
            }
            return true;
         }
      }
   }
   else // SELL
   {
      newSL = currentPrice + trailingDistance;

      //--- Ensure SL is not above entry (always protect capital)
      if(newSL > entryPrice)
         newSL = entryPrice;

      //--- Only move SL if it's better than current and meets step requirement
      if(currentSL == 0 || (newSL < currentSL - trailingStep))
      {
         newSL = NormalizeDouble(newSL, SymbolDigits);

         if(trade.PositionModify(ticket, newSL, positionInfo.TakeProfit()))
         {
            if(EnableDebugMode)
            {
               //--- Calculate current R locked (avoid divide by zero)
               double rLocked = (slDistance > 0) ? (entryPrice - newSL) / slDistance : 0;
               PrintFormat("Trailing SELL #%d: SL %.5f -> %.5f (%.2fR locked) | Price: %.5f | Mode: %s",
                           ticket, currentSL, newSL, rLocked, currentPrice,
                           EnumToString(TrailingMode));
            }
            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Validate SL/TP levels against broker requirements               |
//+------------------------------------------------------------------+
bool ValidateSLTP(double entryPrice, double sl, double tp, ENUM_ORDER_TYPE orderType)
{
   double stopLevel = symbolInfo.StopsLevel() * symbolInfo.Point();
   double freezeLevel = symbolInfo.FreezeLevel() * symbolInfo.Point();

   //--- Minimum distance check
   if(stopLevel > 0)
   {
      if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
      {
         //--- For buy orders: SL must be below entry, TP must be above entry
         if(sl > 0 && entryPrice - sl < stopLevel)
         {
            Print("SL too close to entry. Min distance: ", stopLevel / symbolInfo.Point(), " points");
            return false;
         }
         if(tp > 0 && tp - entryPrice < stopLevel)
         {
            Print("TP too close to entry. Min distance: ", stopLevel / symbolInfo.Point(), " points");
            return false;
         }
      }
      else
      {
         //--- For sell orders: SL must be above entry, TP must be below entry
         if(sl > 0 && sl - entryPrice < stopLevel)
         {
            Print("SL too close to entry. Min distance: ", stopLevel / symbolInfo.Point(), " points");
            return false;
         }
         if(tp > 0 && entryPrice - tp < stopLevel)
         {
            Print("TP too close to entry. Min distance: ", stopLevel / symbolInfo.Point(), " points");
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Adjust SL/TP to meet broker minimum requirements                 |
//+------------------------------------------------------------------+
void AdjustSLTPToMinimum(double entryPrice, double &sl, double &tp, ENUM_ORDER_TYPE orderType)
{
   double stopLevel = symbolInfo.StopsLevel() * symbolInfo.Point();
   double minDist = stopLevel + (10 * symbolInfo.Point()); // Add small buffer

   if(orderType == ORDER_TYPE_BUY || orderType == ORDER_TYPE_BUY_LIMIT || orderType == ORDER_TYPE_BUY_STOP)
   {
      if(sl > 0 && entryPrice - sl < minDist)
         sl = NormalizeDouble(entryPrice - minDist, SymbolDigits);
      if(tp > 0 && tp - entryPrice < minDist)
         tp = NormalizeDouble(entryPrice + minDist, SymbolDigits);
   }
   else
   {
      if(sl > 0 && sl - entryPrice < minDist)
         sl = NormalizeDouble(entryPrice + minDist, SymbolDigits);
      if(tp > 0 && entryPrice - tp < minDist)
         tp = NormalizeDouble(entryPrice - minDist, SymbolDigits);
   }
}

//+------------------------------------------------------------------+
//| Calculate risk in money based on SL distance                     |
//+------------------------------------------------------------------+
double CalculateRiskMoney(double lotSize, double slDistance)
{
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();

   if(tickSize == 0) return 0;

   double ticks = slDistance / tickSize;
   return ticks * tickValue * lotSize;
}

//+------------------------------------------------------------------+
//| Get R:R ratio for display                                        |
//+------------------------------------------------------------------+
double GetRiskRewardRatio(double slDistance, double tpDistance)
{
   if(slDistance == 0) return 0;
   return tpDistance / slDistance;
}

//+------------------------------------------------------------------+
//| POSITION SIZING FUNCTIONS                                        |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Calculate lot size based on selected mode                        |
//+------------------------------------------------------------------+
double CalculateLotSize(double slDistance)
{
   double lotSize = 0;

   switch(LotMode)
   {
      case LOT_FIXED:
         lotSize = FixedLotSize;
         break;

      case LOT_RISK_BALANCE:
         lotSize = CalculateLotFromRiskPercent(slDistance, accountInfo.Balance());
         break;

      case LOT_RISK_EQUITY:
         lotSize = CalculateLotFromRiskPercent(slDistance, accountInfo.Equity());
         break;

      case LOT_FIXED_MONEY:
         lotSize = CalculateLotFromFixedMoney(slDistance, FixedRiskMoney);
         break;

      default:
         lotSize = FixedLotSize;
         break;
   }

   //--- Apply lot constraints
   lotSize = NormalizeLotSize(lotSize);

   //--- Validate margin
   if(!CheckMarginForLot(lotSize))
   {
      Print("Insufficient margin for lot size: ", lotSize);
      //--- Try to find maximum affordable lot
      lotSize = GetMaxAffordableLot();
      lotSize = NormalizeLotSize(lotSize);
   }

   return lotSize;
}

//+------------------------------------------------------------------+
//| Calculate lot size from risk percentage                          |
//+------------------------------------------------------------------+
double CalculateLotFromRiskPercent(double slDistance, double accountValue)
{
   if(slDistance <= 0 || accountValue <= 0)
   {
      Print("Invalid SL distance or account value for lot calculation");
      return MinLotSize;
   }

   //--- Calculate risk amount in account currency
   double riskAmount = accountValue * (RiskPercent / 100.0);

   //--- Calculate lot size
   return CalculateLotFromFixedMoney(slDistance, riskAmount);
}

//+------------------------------------------------------------------+
//| Calculate lot size from fixed money risk                         |
//+------------------------------------------------------------------+
double CalculateLotFromFixedMoney(double slDistance, double riskMoney)
{
   if(slDistance <= 0 || riskMoney <= 0)
   {
      Print("Invalid SL distance or risk money for lot calculation");
      return MinLotSize;
   }

   //--- Get tick value and size
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();

   if(tickValue <= 0 || tickSize <= 0)
   {
      Print("Invalid tick value or size");
      return MinLotSize;
   }

   //--- Calculate number of ticks in SL distance
   double ticks = slDistance / tickSize;

   if(ticks <= 0)
   {
      Print("Invalid ticks calculation");
      return MinLotSize;
   }

   //--- Calculate lot size: riskMoney = ticks * tickValue * lots
   //--- Therefore: lots = riskMoney / (ticks * tickValue)
   double lotSize = riskMoney / (ticks * tickValue);

   return lotSize;
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker requirements                        |
//+------------------------------------------------------------------+
double NormalizeLotSize(double lotSize)
{
   //--- Get broker constraints
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();

   //--- Apply user constraints (may be more restrictive)
   if(MinLotSize > minLot)
      minLot = MinLotSize;
   if(MaxLotSize < maxLot && MaxLotSize > 0)
      maxLot = MaxLotSize;

   //--- Round to lot step
   lotSize = MathFloor(lotSize / lotStep) * lotStep;

   //--- Apply min/max constraints
   if(lotSize < minLot)
      lotSize = minLot;
   if(lotSize > maxLot)
      lotSize = maxLot;

   //--- Normalize to 2 decimal places (standard lot precision)
   lotSize = NormalizeDouble(lotSize, 2);

   return lotSize;
}

//+------------------------------------------------------------------+
//| Check if there's enough margin for the lot size                  |
//+------------------------------------------------------------------+
bool CheckMarginForLot(double lotSize)
{
   if(lotSize <= 0)
      return false;

   double marginRequired = 0;
   double price = symbolInfo.Ask(); // Use Ask for buy, Bid would be for sell

   //--- Calculate required margin
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, lotSize, price, marginRequired))
   {
      Print("Error calculating margin: ", GetLastError());
      return false;
   }

   //--- Get free margin
   double freeMargin = accountInfo.FreeMargin();

   //--- Add safety buffer (require 20% more free margin than needed)
   double safetyBuffer = 1.2;

   return (freeMargin >= marginRequired * safetyBuffer);
}

//+------------------------------------------------------------------+
//| Get maximum affordable lot size based on free margin             |
//+------------------------------------------------------------------+
double GetMaxAffordableLot()
{
   double freeMargin = accountInfo.FreeMargin();
   double price = symbolInfo.Ask();
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();
   double lotStep = symbolInfo.LotsStep();

   //--- Binary search for maximum lot
   double lowLot = minLot;
   double highLot = maxLot;
   double testLot = minLot;
   double marginRequired = 0;

   //--- Safety buffer
   double usableMargin = freeMargin * 0.8; // Use only 80% of free margin

   while(highLot - lowLot > lotStep)
   {
      testLot = NormalizeDouble((lowLot + highLot) / 2.0, 2);
      testLot = MathFloor(testLot / lotStep) * lotStep;

      if(OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, testLot, price, marginRequired))
      {
         if(marginRequired <= usableMargin)
            lowLot = testLot;
         else
            highLot = testLot;
      }
      else
      {
         highLot = testLot;
      }
   }

   return lowLot;
}

//+------------------------------------------------------------------+
//| Calculate money at risk for given lot and SL                     |
//+------------------------------------------------------------------+
double CalculateMoneyAtRisk(double lotSize, double slDistance)
{
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();

   if(tickSize <= 0)
      return 0;

   double ticks = slDistance / tickSize;
   return ticks * tickValue * lotSize;
}

//+------------------------------------------------------------------+
//| Calculate risk percentage of account for given lot and SL        |
//+------------------------------------------------------------------+
double CalculateRiskPercentage(double lotSize, double slDistance, bool useEquity = false)
{
   double accountValue = useEquity ? accountInfo.Equity() : accountInfo.Balance();

   if(accountValue <= 0)
      return 0;

   double moneyAtRisk = CalculateMoneyAtRisk(lotSize, slDistance);
   return (moneyAtRisk / accountValue) * 100.0;
}

//+------------------------------------------------------------------+
//| Get potential profit for given lot and TP                        |
//+------------------------------------------------------------------+
double CalculatePotentialProfit(double lotSize, double tpDistance)
{
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();

   if(tickSize <= 0)
      return 0;

   double ticks = tpDistance / tickSize;
   return ticks * tickValue * lotSize;
}

//+------------------------------------------------------------------+
//| Validate lot size meets all requirements                         |
//+------------------------------------------------------------------+
bool ValidateLotSize(double lotSize, string &errorMsg)
{
   //--- Check minimum lot
   if(lotSize < symbolInfo.LotsMin())
   {
      errorMsg = StringFormat("Lot size %.2f is below minimum %.2f", lotSize, symbolInfo.LotsMin());
      return false;
   }

   //--- Check maximum lot
   if(lotSize > symbolInfo.LotsMax())
   {
      errorMsg = StringFormat("Lot size %.2f exceeds maximum %.2f", lotSize, symbolInfo.LotsMax());
      return false;
   }

   //--- Check user minimum
   if(lotSize < MinLotSize)
   {
      errorMsg = StringFormat("Lot size %.2f is below user minimum %.2f", lotSize, MinLotSize);
      return false;
   }

   //--- Check user maximum
   if(MaxLotSize > 0 && lotSize > MaxLotSize)
   {
      errorMsg = StringFormat("Lot size %.2f exceeds user maximum %.2f", lotSize, MaxLotSize);
      return false;
   }

   //--- Check margin
   if(!CheckMarginForLot(lotSize))
   {
      errorMsg = "Insufficient margin for lot size";
      return false;
   }

   errorMsg = "";
   return true;
}

//+------------------------------------------------------------------+
//| Get lot size for manual trading buttons                          |
//+------------------------------------------------------------------+
double GetManualTradeLotSize(double slDistance)
{
   if(UseEALotForManual)
   {
      return CalculateLotSize(slDistance);
   }
   else
   {
      return NormalizeLotSize(ManualFixedLot);
   }
}

//+------------------------------------------------------------------+
//| Calculate position value in account currency                     |
//+------------------------------------------------------------------+
double CalculatePositionValue(double lotSize)
{
   double contractSize = symbolInfo.ContractSize();
   double price = symbolInfo.Ask();

   return lotSize * contractSize * price;
}

//+------------------------------------------------------------------+
//| Get margin requirement for a trade                               |
//+------------------------------------------------------------------+
double GetMarginRequired(double lotSize, ENUM_ORDER_TYPE orderType)
{
   double marginRequired = 0;
   double price = (orderType == ORDER_TYPE_BUY) ? symbolInfo.Ask() : symbolInfo.Bid();

   if(!OrderCalcMargin(orderType, _Symbol, lotSize, price, marginRequired))
   {
      Print("Error calculating margin: ", GetLastError());
      return 0;
   }

   return marginRequired;
}

//+------------------------------------------------------------------+
//| Calculate lot size with dynamic SL (for SL_FIXED_MONEY mode)     |
//+------------------------------------------------------------------+
void CalculateLotAndSLForFixedMoney(double entryPrice, bool isBuy,
                                     double &outLotSize, double &outSL, double &outSLDistance)
{
   //--- This is for SL_FIXED_MONEY mode where we want to risk exact amount
   //--- We need to iterate to find the right lot/SL combination

   if(SLMode != SL_FIXED_MONEY)
   {
      //--- Normal calculation
      if(isBuy)
         outSL = CalculateBuySL(entryPrice, outSLDistance);
      else
         outSL = CalculateSellSL(entryPrice, outSLDistance);

      outLotSize = CalculateLotSize(outSLDistance);
      return;
   }

   //--- For fixed money SL, calculate lot first, then SL distance
   double tickValue = symbolInfo.TickValue();
   double tickSize = symbolInfo.TickSize();

   //--- Start with a reasonable lot size and iterate
   outLotSize = NormalizeLotSize(FixedLotSize);

   if(tickValue > 0 && tickSize > 0 && outLotSize > 0)
   {
      //--- Calculate SL distance for fixed money risk
      double ticksForRisk = SLFixedMoney / (tickValue * outLotSize);
      outSLDistance = ticksForRisk * tickSize;

      //--- Calculate SL price
      if(isBuy)
         outSL = entryPrice - outSLDistance;
      else
         outSL = entryPrice + outSLDistance;

      //--- Normalize
      outSL = NormalizeDouble(outSL, SymbolDigits);
      outSLDistance = NormalizeDouble(outSLDistance, SymbolDigits);
   }
   else
   {
      //--- Fallback
      outSLDistance = PipsToPrice(SLFixedPips);
      if(isBuy)
         outSL = entryPrice - outSLDistance;
      else
         outSL = entryPrice + outSLDistance;
      outLotSize = CalculateLotSize(outSLDistance);
   }
}

//+------------------------------------------------------------------+
//| Get formatted lot size string for display                        |
//+------------------------------------------------------------------+
string FormatLotSize(double lotSize)
{
   return StringFormat("%.2f", lotSize);
}

//+------------------------------------------------------------------+
//| Get formatted money string for display                           |
//+------------------------------------------------------------------+
string FormatMoney(double amount)
{
   string currency = accountInfo.Currency();
   return StringFormat("%.2f %s", amount, currency);
}

//+------------------------------------------------------------------+
//| Get formatted risk info string for display                       |
//+------------------------------------------------------------------+
string GetRiskInfoString(double lotSize, double slDistance)
{
   double riskMoney = CalculateMoneyAtRisk(lotSize, slDistance);
   double riskPercent = CalculateRiskPercentage(lotSize, slDistance);

   return StringFormat("%.2f lots | Risk: %.2f %s (%.2f%%)",
                       lotSize, riskMoney, accountInfo.Currency(), riskPercent);
}

//+------------------------------------------------------------------+
//| Check if account has sufficient balance for trading              |
//+------------------------------------------------------------------+
bool HasSufficientBalance()
{
   double balance = accountInfo.Balance();
   double freeMargin = accountInfo.FreeMargin();
   double minLot = symbolInfo.LotsMin();

   //--- Check if we can afford at least minimum lot
   double marginForMinLot = 0;
   if(!OrderCalcMargin(ORDER_TYPE_BUY, _Symbol, minLot, symbolInfo.Ask(), marginForMinLot))
      return false;

   return (freeMargin > marginForMinLot * 1.5); // 50% buffer
}

//+------------------------------------------------------------------+
//| Calculate lot size for partial close                             |
//+------------------------------------------------------------------+
double CalculatePartialCloseLot(double currentLot, double percentToClose)
{
   double partialLot = currentLot * (percentToClose / 100.0);

   //--- Normalize to lot step
   double lotStep = symbolInfo.LotsStep();
   partialLot = MathFloor(partialLot / lotStep) * lotStep;

   //--- Check minimum
   if(partialLot < symbolInfo.LotsMin())
   {
      //--- If partial is too small, either close all or nothing
      return 0;
   }

   return partialLot;
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                    FILTER FUNCTIONS                              |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Master Filter Check - Calls all individual filters               |
//+------------------------------------------------------------------+
bool CheckAllFilters()
{
   //--- Check each filter in order of computation cost (cheapest first)
   //--- Static flag to prevent log spam (only log once per blocking filter)
   static string lastFilterBlocked = "";
   string currentFilter = "";
   bool blocked = false;

   //--- 1. Day Filter (cheapest - just day of week)
   if(!CheckDayFilter())
   {
      currentFilter = "Day Filter";
      blocked = true;
   }
   //--- 2. Spread Filter (cheap - just spread check)
   else if(!CheckSpreadFilter())
   {
      currentFilter = "Spread Filter";
      blocked = true;
   }
   //--- 3. Time Filter (needs timezone conversion)
   else if(!CheckTimeFilter())
   {
      currentFilter = "Time Filter";
      blocked = true;
   }
   //--- 4. Session Filter
   else if(!CheckSessionFilter())
   {
      currentFilter = "Session Filter";
      blocked = true;
   }
   //--- 5. Volatility Filter (needs ATR calculation)
   else if(!CheckVolatilityFilter())
   {
      currentFilter = "Volatility Filter";
      blocked = true;
   }
   //--- 6. Trend Filter (needs MA/ADX calculations)
   else if(!CheckTrendFilter())
   {
      currentFilter = "Trend Filter";
      blocked = true;
   }
   //--- 7. News Filter
   else if(!CheckNewsFilter())
   {
      currentFilter = "News Filter";
      blocked = true;
   }

   //--- If blocked, log only when blocking filter changes
   if(blocked)
   {
      if(EnableDebugMode && currentFilter != lastFilterBlocked)
      {
         Print("Filter BLOCKED: ", currentFilter);
         lastFilterBlocked = currentFilter;
      }
      return false;
   }

   //--- All filters passed - log transition from blocked to unblocked
   if(lastFilterBlocked != "" && EnableDebugMode)
   {
      Print("All filters PASSED");
   }
   lastFilterBlocked = "";

   //--- All filters passed
   return true;
}

//+------------------------------------------------------------------+
//| Check if filters allow entry in specific direction               |
//+------------------------------------------------------------------+
bool CheckFiltersForDirection(int direction)
{
   //--- First check all standard filters
   if(!CheckAllFilters())
      return false;

   //--- Then check trend direction if using trend filter with direction
   if(UseTrendFilter && TrendFilterMode != TREND_ANY)
   {
      int trendDir = GetTrendDirection();

      if(TrendFilterMode == TREND_WITH)
      {
         //--- Trade with trend: Buy in uptrend, Sell in downtrend
         if(direction > 0 && trendDir < 0) return false;  // No buy in downtrend
         if(direction < 0 && trendDir > 0) return false;  // No sell in uptrend
      }
      else if(TrendFilterMode == TREND_COUNTER)
      {
         //--- Trade counter trend: Buy in downtrend, Sell in uptrend
         if(direction > 0 && trendDir > 0) return false;  // No buy in uptrend
         if(direction < 0 && trendDir < 0) return false;  // No sell in downtrend
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| VOLATILITY FILTER                                                |
//+------------------------------------------------------------------+
bool CheckVolatilityFilter()
{
   //--- Check if volatility filter is disabled
   if(!UseVolatilityFilter)
      return true;

   //--- Get ATR value
   double atr = GetATRValue();
   if(atr <= 0)
   {
      Print("Warning: Could not get ATR value");
      return true; // Allow trading if ATR unavailable
   }

   double atrPips = atr / PipValue;

   //--- Check ATR range (in pips)
   if(MinATRPips > 0 && atrPips < MinATRPips)
   {
      if(EnableDebugMode) PrintFormat("ATR too low: %.2f pips < Min %.2f pips", atrPips, MinATRPips);
      return false;
   }

   if(MaxATRPips > 0 && atrPips > MaxATRPips)
   {
      if(EnableDebugMode) PrintFormat("ATR too high: %.2f pips > Max %.2f pips", atrPips, MaxATRPips);
      return false;
   }

   //--- Check IB Range (only if IB is complete)
   if(IBStatus == IB_COMPLETE || IBStatus == IB_BROKEN_UP || IBStatus == IB_BROKEN_DOWN)
   {
      double ibRange = IBHigh - IBLow;
      double ibRangePips = ibRange / PipValue;

      //--- Check IB range in pips
      if(MinIBRangePips > 0 && ibRangePips < MinIBRangePips)
      {
         if(EnableDebugMode) PrintFormat("IB Range too small: %.2f pips < Min %.2f pips", ibRangePips, MinIBRangePips);
         return false;
      }

      if(MaxIBRangePips > 0 && ibRangePips > MaxIBRangePips)
      {
         if(EnableDebugMode) PrintFormat("IB Range too large: %.2f pips > Max %.2f pips", ibRangePips, MaxIBRangePips);
         return false;
      }

      //--- Check IB range as ATR multiple
      if(UseATRForIBRange && atr > 0)
      {
         double ibRangeATR = ibRange / atr;

         if(MinIBRangeATR > 0 && ibRangeATR < MinIBRangeATR)
         {
            if(EnableDebugMode) PrintFormat("IB Range too small: %.2f ATR < Min %.2f ATR", ibRangeATR, MinIBRangeATR);
            return false;
         }

         if(MaxIBRangeATR > 0 && ibRangeATR > MaxIBRangeATR)
         {
            if(EnableDebugMode) PrintFormat("IB Range too large: %.2f ATR > Max %.2f ATR", ibRangeATR, MaxIBRangeATR);
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| TREND FILTER                                                     |
//+------------------------------------------------------------------+
bool CheckTrendFilter()
{
   //--- Check if trend filter is disabled
   if(!UseTrendFilter)
      return true;

   //--- Get trend direction
   int trendDir = GetTrendDirection();

   //--- For TREND_ANY mode, we just need a confirmed trend
   if(TrendFilterMode == TREND_ANY)
   {
      return (trendDir != 0);  // Any trend direction is acceptable
   }

   //--- For other modes, trend checking happens in CheckFiltersForDirection()
   //--- Here we just ensure we can get trend data
   return true;
}

//+------------------------------------------------------------------+
//| Get Trend Direction: 1=Up, -1=Down, 0=No trend/Range             |
//+------------------------------------------------------------------+
int GetTrendDirection()
{
   switch(TrendMethod)
   {
      case TREND_MA:
         return GetMATrendDirection();

      case TREND_MA_CROSS:
         return GetMACrossoverDirection();

      case TREND_ADX:
         return GetADXTrendDirection();

      case TREND_HTF:
         return GetHTFTrendDirection();

      default:
         return 0;
   }
}

//+------------------------------------------------------------------+
//| Get trend direction from single MA                               |
//+------------------------------------------------------------------+
int GetMATrendDirection()
{
   if(MA1Handle == INVALID_HANDLE)
      return 0;

   double maBuffer[];
   ArraySetAsSeries(maBuffer, true);

   if(CopyBuffer(MA1Handle, 0, 0, 2, maBuffer) < 2)
      return 0;

   double currentPrice = symbolInfo.Bid();
   double maValue = maBuffer[0];
   double maPrevValue = maBuffer[1];

   //--- Price above rising MA = Uptrend
   if(currentPrice > maValue && maValue > maPrevValue)
      return 1;

   //--- Price below falling MA = Downtrend
   if(currentPrice < maValue && maValue < maPrevValue)
      return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| Get trend direction from MA crossover                            |
//+------------------------------------------------------------------+
int GetMACrossoverDirection()
{
   if(MA1Handle == INVALID_HANDLE || MA2Handle == INVALID_HANDLE)
      return 0;

   double fastMA[], slowMA[];
   ArraySetAsSeries(fastMA, true);
   ArraySetAsSeries(slowMA, true);

   if(CopyBuffer(MA1Handle, 0, 0, 1, fastMA) < 1)
      return 0;
   if(CopyBuffer(MA2Handle, 0, 0, 1, slowMA) < 1)
      return 0;

   //--- Fast MA above Slow MA = Uptrend
   if(fastMA[0] > slowMA[0])
      return 1;

   //--- Fast MA below Slow MA = Downtrend
   if(fastMA[0] < slowMA[0])
      return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| Get trend direction from ADX                                     |
//+------------------------------------------------------------------+
int GetADXTrendDirection()
{
   if(ADXHandle == INVALID_HANDLE)
      return 0;

   double adxBuffer[], plusDI[], minusDI[];
   ArraySetAsSeries(adxBuffer, true);
   ArraySetAsSeries(plusDI, true);
   ArraySetAsSeries(minusDI, true);

   //--- ADX buffer 0 = main ADX, buffer 1 = +DI, buffer 2 = -DI
   if(CopyBuffer(ADXHandle, 0, 0, 1, adxBuffer) < 1)
      return 0;
   if(CopyBuffer(ADXHandle, 1, 0, 1, plusDI) < 1)
      return 0;
   if(CopyBuffer(ADXHandle, 2, 0, 1, minusDI) < 1)
      return 0;

   //--- Check if ADX is above threshold (trending)
   if(adxBuffer[0] < ADXThreshold)
      return 0;  // No trend - ranging market

   //--- +DI > -DI = Uptrend
   if(plusDI[0] > minusDI[0])
      return 1;

   //--- -DI > +DI = Downtrend
   if(minusDI[0] > plusDI[0])
      return -1;

   return 0;
}

//+------------------------------------------------------------------+
//| Get trend from Higher Timeframe                                  |
//+------------------------------------------------------------------+
int GetHTFTrendDirection()
{
   //--- Use MA on higher timeframe
   int htfMAHandle = iMA(_Symbol, TrendTimeframe, MA1Period, 0, MAMethod, PRICE_CLOSE);

   if(htfMAHandle == INVALID_HANDLE)
      return 0;

   double maBuffer[];
   ArraySetAsSeries(maBuffer, true);

   if(CopyBuffer(htfMAHandle, 0, 0, 2, maBuffer) < 2)
   {
      IndicatorRelease(htfMAHandle);
      return 0;
   }

   //--- Get current price on HTF
   double htfClose[];
   ArraySetAsSeries(htfClose, true);
   if(CopyClose(_Symbol, TrendTimeframe, 0, 1, htfClose) < 1)
   {
      IndicatorRelease(htfMAHandle);
      return 0;
   }

   int direction = 0;

   //--- Price above rising MA = Uptrend
   if(htfClose[0] > maBuffer[0] && maBuffer[0] > maBuffer[1])
      direction = 1;
   //--- Price below falling MA = Downtrend
   else if(htfClose[0] < maBuffer[0] && maBuffer[0] < maBuffer[1])
      direction = -1;

   IndicatorRelease(htfMAHandle);
   return direction;
}

//+------------------------------------------------------------------+
//| TIME FILTER - Trading Hours Check                                |
//+------------------------------------------------------------------+
bool CheckTimeFilter()
{
   //--- Check if time filter is disabled
   if(!UseTimeFilter)
      return true;

   //--- Static flag to prevent spam
   static bool loggedPastEntry = false;
   static datetime lastLogDate = 0;
   datetime today = TimeCurrent() - (TimeCurrent() % 86400);

   //--- Reset flag on new day
   if(today != lastLogDate)
   {
      loggedPastEntry = false;
      lastLogDate = today;
   }

   //--- Check if within trading time range
   if(!IsWithinTimeRange(TradingStartTime, TradingEndTime, TradeTimezone))
   {
      return false;
   }

   //--- Check last entry time (no new entries after this time)
   if(!IsBeforeTime(LastEntryTimeStr, TradeTimezone))
   {
      if(EnableDebugMode && !loggedPastEntry)
      {
         Print("Past last entry time");
         loggedPastEntry = true;
      }
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if current time is before specified time                   |
//+------------------------------------------------------------------+
bool IsBeforeTime(string timeStr, ENUM_TIMEZONE timezone)
{
   int targetHour, targetMinute;
   ParseTimeString(timeStr, targetHour, targetMinute);

   //--- Get current time in target timezone
   int currentHour, currentMinute;
   ConvertFromServerTime(TimeCurrent(), timezone, currentHour, currentMinute);

   int currentMinutes = currentHour * 60 + currentMinute;
   int targetMinutes = targetHour * 60 + targetMinute;

   return (currentMinutes < targetMinutes);
}

//+------------------------------------------------------------------+
//| SESSION FILTER - Trading Session Check                           |
//+------------------------------------------------------------------+
bool CheckSessionFilter()
{
   //--- Check if session filter is any
   if(SessionFilter == SESSION_ANY)
      return true;

   switch(SessionFilter)
   {
      case SESSION_LONDON:
         return IsLondonSession();

      case SESSION_NEWYORK:
         return IsNewYorkSession();

      case SESSION_OVERLAP:
         return IsLondonNYOverlap();

      case SESSION_CUSTOM:
         return IsWithinTimeRange(CustomSessionStart, CustomSessionEnd, TradeTimezone);

      default:
         return true;
   }
}

//+------------------------------------------------------------------+
//| Check if currently in London session                             |
//+------------------------------------------------------------------+
bool IsLondonSession()
{
   //--- London session: 08:00 - 16:30 London time
   return IsWithinTimeRange("08:00", "16:30", TZ_LONDON);
}

//+------------------------------------------------------------------+
//| Check if currently in New York session                           |
//+------------------------------------------------------------------+
bool IsNewYorkSession()
{
   //--- NY session: 09:30 - 16:00 NY time
   return IsWithinTimeRange("09:30", "16:00", TZ_NEWYORK);
}

//+------------------------------------------------------------------+
//| Check if currently in London/NY overlap                          |
//+------------------------------------------------------------------+
bool IsLondonNYOverlap()
{
   //--- Overlap: NY opens at 09:30 until London closes at 16:30
   //--- In NY time: 09:30 - 11:30 (roughly)
   //--- We check both sessions are active
   return (IsLondonSession() && IsNewYorkSession());
}

//+------------------------------------------------------------------+
//| DAY FILTER - Day of Week Check                                   |
//+------------------------------------------------------------------+
bool CheckDayFilter()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   //--- Check day of week
   switch(dt.day_of_week)
   {
      case 0: // Sunday
         return false;  // Markets closed

      case 1: // Monday
         if(!TradeMonday) return false;
         break;

      case 2: // Tuesday
         if(!TradeTuesday) return false;
         break;

      case 3: // Wednesday
         if(!TradeWednesday) return false;
         break;

      case 4: // Thursday
         if(!TradeThursday) return false;
         break;

      case 5: // Friday
         if(!TradeFriday) return false;
         //--- Check Friday early close
         if(UseFridayEarlyClose)
         {
            if(!IsBeforeTime(FridayCloseTime, TradeTimezone))
            {
               if(EnableDebugMode) Print("Friday early close - trading stopped");
               return false;
            }
         }
         break;

      case 6: // Saturday
         return false;  // Markets closed
   }

   return true;
}

//+------------------------------------------------------------------+
//| Get current day of week name                                     |
//+------------------------------------------------------------------+
string GetDayOfWeekName(int dayOfWeek)
{
   switch(dayOfWeek)
   {
      case 0: return "Sunday";
      case 1: return "Monday";
      case 2: return "Tuesday";
      case 3: return "Wednesday";
      case 4: return "Thursday";
      case 5: return "Friday";
      case 6: return "Saturday";
      default: return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| SPREAD FILTER - Maximum Spread Check                             |
//+------------------------------------------------------------------+
bool CheckSpreadFilter()
{
   //--- Check if spread filter is disabled
   if(!UseSpreadFilter)
      return true;

   //--- Get current spread in pips
   double spreadPoints = symbolInfo.Spread();
   double spreadPips = spreadPoints * PointValue / PipValue;

   if(spreadPips > MaxSpreadPips)
   {
      if(EnableDebugMode) PrintFormat("Spread too high: %.2f pips > Max %.2f pips", spreadPips, MaxSpreadPips);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Get current spread in pips                                       |
//+------------------------------------------------------------------+
double GetSpreadPips()
{
   symbolInfo.RefreshRates();
   double spreadPoints = symbolInfo.Spread();
   return spreadPoints * PointValue / PipValue;
}

//+------------------------------------------------------------------+
//| NEWS FILTER - Economic Calendar Based                            |
//+------------------------------------------------------------------+
bool CheckNewsFilter()
{
   //--- Check if news filter is disabled
   if(!UseNewsFilter)
      return true;

   //--- Use appropriate filter mode
   if(NewsFilterMode == NEWS_MODE_CALENDAR)
   {
      return CheckNewsFilterCalendar();
   }
   else
   {
      return CheckNewsFilterManual();
   }
}

//+------------------------------------------------------------------+
//| Check news using MQL5 Economic Calendar                          |
//+------------------------------------------------------------------+
bool CheckNewsFilterCalendar()
{
   //--- Update news data if needed
   UpdateNewsData();

   //--- If calendar not available, fall back to manual mode
   if(!NewsCalendarAvailable)
   {
      if(EnableDebugMode) Print("Calendar unavailable, using manual news filter");
      return CheckNewsFilterManual();
   }

   //--- Check if any upcoming news is within our blackout window
   datetime currentTime = TimeCurrent();
   datetime blackoutStart = currentTime - NewsMinutesAfter * 60;
   datetime blackoutEnd = currentTime + NewsMinutesBefore * 60;

   for(int i = 0; i < ArraySize(UpcomingNews); i++)
   {
      //--- Check if news event is within blackout window
      if(UpcomingNews[i].time >= blackoutStart && UpcomingNews[i].time <= blackoutEnd)
      {
         //--- Check impact level
         if(ShouldFilterNewsEvent(UpcomingNews[i]))
         {
            if(EnableDebugMode)
            {
               PrintFormat("News Filter BLOCKED: %s (%s) at %s | Impact: %d",
                           UpcomingNews[i].name, UpcomingNews[i].currency,
                           TimeToString(UpcomingNews[i].time, TIME_MINUTES),
                           UpcomingNews[i].importance);
            }
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if a specific news event should be filtered                |
//+------------------------------------------------------------------+
bool ShouldFilterNewsEvent(const NewsEvent &event)
{
   //--- Check impact level filter
   switch(NewsImpactFilter)
   {
      case NEWS_HIGH_ONLY:
         if(event.importance < 3) return false;  // Only filter High impact (3)
         break;

      case NEWS_MEDIUM_HIGH:
         if(event.importance < 2) return false;  // Filter Medium (2) and High (3)
         break;

      case NEWS_ALL:
         // Filter all events
         break;
   }

   //--- Check currency filter
   if(!ShouldFilterCurrency(event.currency))
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Check if a currency should be filtered                           |
//+------------------------------------------------------------------+
bool ShouldFilterCurrency(string currency)
{
   //--- Auto-filter symbol currencies
   if(FilterSymbolNews)
   {
      if(currency == SymbolBaseCurrency || currency == SymbolQuoteCurrency)
         return true;
   }

   //--- Check individual currency filters
   if(FilterUSDNews && currency == "USD") return true;
   if(FilterEURNews && currency == "EUR") return true;
   if(FilterGBPNews && currency == "GBP") return true;
   if(FilterJPYNews && currency == "JPY") return true;

   return false;
}

//+------------------------------------------------------------------+
//| Update news data from MQL5 Economic Calendar                     |
//+------------------------------------------------------------------+
void UpdateNewsData()
{
   datetime currentTime = TimeCurrent();

   //--- Check if update is needed
   if(currentTime - LastNewsUpdate < NewsUpdateIntervalSec && ArraySize(UpcomingNews) > 0)
      return;

   //--- Clear old data
   ArrayFree(UpcomingNews);

   //--- Try to load from MQL5 Calendar
   if(!LoadNewsFromCalendar())
   {
      NewsCalendarAvailable = false;
      if(EnableDebugMode) Print("MQL5 Calendar not available or no data");
   }
   else
   {
      NewsCalendarAvailable = true;
   }

   LastNewsUpdate = currentTime;
}

//+------------------------------------------------------------------+
//| Load news events from MQL5 Economic Calendar                     |
//+------------------------------------------------------------------+
bool LoadNewsFromCalendar()
{
   //--- Define time range: 1 hour before to 24 hours ahead
   datetime fromTime = TimeCurrent() - 3600;     // 1 hour ago
   datetime toTime = TimeCurrent() + 86400;      // 24 hours ahead

   //--- Get calendar values
   MqlCalendarValue values[];
   int count = CalendarValueHistory(values, fromTime, toTime);

   if(count <= 0)
   {
      int error = GetLastError();
      if(error != 0 && EnableDebugMode)
         PrintFormat("CalendarValueHistory error: %d", error);
      return false;
   }

   //--- Process events
   int newsCount = 0;
   ArrayResize(UpcomingNews, count);

   for(int i = 0; i < count; i++)
   {
      //--- Get event details
      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id, event))
         continue;

      //--- Get country details for currency
      MqlCalendarCountry country;
      if(!CalendarCountryById(event.country_id, country))
         continue;

      //--- Check if this is a relevant currency
      string currency = country.currency;
      if(!ShouldFilterCurrency(currency))
         continue;

      //--- Check importance level
      int importance = (int)event.importance;

      //--- Skip if below our filter threshold
      bool shouldInclude = false;
      switch(NewsImpactFilter)
      {
         case NEWS_HIGH_ONLY:
            shouldInclude = (importance >= 3);
            break;
         case NEWS_MEDIUM_HIGH:
            shouldInclude = (importance >= 2);
            break;
         case NEWS_ALL:
            shouldInclude = true;
            break;
      }

      if(!shouldInclude)
         continue;

      //--- Add to our news array
      UpcomingNews[newsCount].time = values[i].time;
      UpcomingNews[newsCount].currency = currency;
      UpcomingNews[newsCount].name = event.name;
      UpcomingNews[newsCount].importance = importance;
      UpcomingNews[newsCount].eventId = values[i].event_id;
      newsCount++;
   }

   //--- Resize to actual count
   ArrayResize(UpcomingNews, newsCount);

   if(EnableDebugMode && newsCount > 0)
   {
      PrintFormat("Loaded %d relevant news events from calendar", newsCount);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Initialize news filter - extract symbol currencies               |
//+------------------------------------------------------------------+
void InitializeNewsFilter()
{
   //--- Extract base and quote currencies from symbol
   string symbol = _Symbol;

   //--- Handle common forex pairs (6 characters)
   if(StringLen(symbol) >= 6)
   {
      SymbolBaseCurrency = StringSubstr(symbol, 0, 3);
      SymbolQuoteCurrency = StringSubstr(symbol, 3, 3);
   }

   //--- Try to get from symbol properties
   string baseCurr = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string quoteCurr = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

   if(StringLen(baseCurr) > 0)
      SymbolBaseCurrency = baseCurr;
   if(StringLen(quoteCurr) > 0)
      SymbolQuoteCurrency = quoteCurr;

   if(EnableDebugMode)
   {
      PrintFormat("News Filter: Symbol currencies - Base: %s, Quote: %s",
                  SymbolBaseCurrency, SymbolQuoteCurrency);
   }

   //--- Try to load initial news data
   if(UseNewsFilter && NewsFilterMode == NEWS_MODE_CALENDAR)
   {
      UpdateNewsData();
   }
}

//+------------------------------------------------------------------+
//| Manual news filter (fallback) - Time-based blocking              |
//+------------------------------------------------------------------+
bool CheckNewsFilterManual()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   //--- Get current time in New York timezone
   int nyHour, nyMinute;
   ConvertFromServerTime(TimeCurrent(), TZ_NEWYORK, nyHour, nyMinute);

   //--- Common US news release times (NY time)
   //--- 08:30 - Employment, GDP, CPI, Retail Sales
   //--- 10:00 - ISM, Consumer Confidence
   //--- 14:00 - FOMC decisions

   if(FilterUSDNews)
   {
      //--- Check proximity to 08:30 NY
      if(IsNearNewsTime(nyHour, nyMinute, 8, 30, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential US news time: 08:30 NY");
         return false;
      }

      //--- Check proximity to 10:00 NY
      if(IsNearNewsTime(nyHour, nyMinute, 10, 0, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential US news time: 10:00 NY");
         return false;
      }

      //--- Check proximity to 14:00 NY (FOMC days)
      if(IsNearNewsTime(nyHour, nyMinute, 14, 0, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential FOMC time: 14:00 NY");
         return false;
      }
   }

   //--- Get current time in London timezone for UK news
   int londonHour, londonMinute;
   ConvertFromServerTime(TimeCurrent(), TZ_LONDON, londonHour, londonMinute);

   if(FilterGBPNews)
   {
      //--- Common UK news release times (London time)
      //--- 07:00 - UK GDP, Employment
      //--- 09:30 - UK economic data
      //--- 12:00 - BOE decisions

      if(IsNearNewsTime(londonHour, londonMinute, 7, 0, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential UK news time: 07:00 London");
         return false;
      }

      if(IsNearNewsTime(londonHour, londonMinute, 9, 30, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential UK news time: 09:30 London");
         return false;
      }

      if(IsNearNewsTime(londonHour, londonMinute, 12, 0, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential BOE time: 12:00 London");
         return false;
      }
   }

   //--- EUR news times (Frankfurt/ECB)
   if(FilterEURNews)
   {
      //--- 10:00 London (11:00 Frankfurt) - ECB meetings, EU data
      if(IsNearNewsTime(londonHour, londonMinute, 10, 0, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential EUR news time: 10:00 London");
         return false;
      }

      //--- 12:45 London - ECB rate decisions
      if(IsNearNewsTime(londonHour, londonMinute, 12, 45, NewsMinutesBefore, NewsMinutesAfter))
      {
         if(EnableDebugMode) Print("Near potential ECB decision time: 12:45 London");
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if current time is near a specific news time               |
//+------------------------------------------------------------------+
bool IsNearNewsTime(int currentHour, int currentMinute,
                    int newsHour, int newsMinute,
                    int minutesBefore, int minutesAfter)
{
   int currentMinutes = currentHour * 60 + currentMinute;
   int newsMinutes = newsHour * 60 + newsMinute;

   int timeDiff = currentMinutes - newsMinutes;

   //--- Check if within the news blackout window
   return (timeDiff >= -minutesBefore && timeDiff <= minutesAfter);
}

//+------------------------------------------------------------------+
//| Get upcoming news info for dashboard                             |
//+------------------------------------------------------------------+
string GetNextNewsEventInfo()
{
   if(!UseNewsFilter)
      return "News Filter: OFF";

   if(NewsFilterMode == NEWS_MODE_MANUAL)
      return "News Filter: Manual Mode";

   if(!NewsCalendarAvailable)
      return "News Filter: Calendar N/A";

   datetime currentTime = TimeCurrent();
   datetime nearestTime = 0;
   string nearestEvent = "";
   string nearestCurrency = "";
   int nearestImpact = 0;

   for(int i = 0; i < ArraySize(UpcomingNews); i++)
   {
      if(UpcomingNews[i].time > currentTime)
      {
         if(nearestTime == 0 || UpcomingNews[i].time < nearestTime)
         {
            nearestTime = UpcomingNews[i].time;
            nearestEvent = UpcomingNews[i].name;
            nearestCurrency = UpcomingNews[i].currency;
            nearestImpact = UpcomingNews[i].importance;
         }
      }
   }

   if(nearestTime == 0)
      return "News: No upcoming events";

   int minutesUntil = (int)((nearestTime - currentTime) / 60);
   string impactStr = (nearestImpact == 3) ? "HIGH" : (nearestImpact == 2) ? "MED" : "LOW";

   if(minutesUntil <= 60)
   {
      return StringFormat("News: %s %s (%s) in %d min",
                          nearestCurrency, impactStr, nearestEvent, minutesUntil);
   }
   else
   {
      int hoursUntil = minutesUntil / 60;
      return StringFormat("News: %s %s in %dh %dm",
                          nearestCurrency, impactStr, hoursUntil, minutesUntil % 60);
   }
}

//+------------------------------------------------------------------+
//| Get filter status string for dashboard                           |
//+------------------------------------------------------------------+
string GetFilterStatusString()
{
   string status = "";

   //--- Day Filter
   status += CheckDayFilter() ? "Day:OK " : "Day:BLOCKED ";

   //--- Spread Filter
   status += CheckSpreadFilter() ? "Spread:OK " : "Spread:HIGH ";

   //--- Time Filter
   status += CheckTimeFilter() ? "Time:OK " : "Time:OUT ";

   //--- Session Filter
   status += CheckSessionFilter() ? "Session:OK " : "Session:OUT ";

   //--- Volatility Filter
   status += CheckVolatilityFilter() ? "Vol:OK " : "Vol:BLOCKED ";

   //--- Trend Filter
   if(UseTrendFilter)
   {
      int trend = GetTrendDirection();
      status += (trend > 0) ? "Trend:UP " : (trend < 0) ? "Trend:DOWN " : "Trend:RANGE ";
   }
   else
   {
      status += "Trend:OFF ";
   }

   return status;
}

//+------------------------------------------------------------------+
//| Get detailed filter info for logging                             |
//+------------------------------------------------------------------+
string GetDetailedFilterInfo()
{
   string info = "\n===== FILTER STATUS =====\n";

   //--- Day Info
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   info += StringFormat("Day: %s - %s\n", GetDayOfWeekName(dt.day_of_week),
                        CheckDayFilter() ? "ALLOWED" : "BLOCKED");

   //--- Spread Info
   double spreadPips = GetSpreadPips();
   info += StringFormat("Spread: %.2f pips (Max: %.2f) - %s\n",
                        spreadPips, MaxSpreadPips,
                        CheckSpreadFilter() ? "OK" : "HIGH");

   //--- Time Info
   int hour, minute;
   ConvertFromServerTime(TimeCurrent(), TradeTimezone, hour, minute);
   info += StringFormat("Time: %02d:%02d %s (Window: %s-%s) - %s\n",
                        hour, minute, EnumToString(TradeTimezone),
                        TradingStartTime, TradingEndTime,
                        CheckTimeFilter() ? "IN RANGE" : "OUT OF RANGE");

   //--- Session Info
   info += StringFormat("Session: %s - %s\n",
                        EnumToString(SessionFilter),
                        CheckSessionFilter() ? "ACTIVE" : "INACTIVE");

   //--- Volatility Info
   double atr = GetATRValue();
   double atrPips = atr / PipValue;
   info += StringFormat("ATR: %.2f pips (Min: %.2f, Max: %.2f) - %s\n",
                        atrPips, MinATRPips, MaxATRPips,
                        CheckVolatilityFilter() ? "OK" : "BLOCKED");

   if(IBStatus >= IB_COMPLETE)
   {
      double ibRangePips = (IBHigh - IBLow) / PipValue;
      info += StringFormat("IB Range: %.2f pips (Min: %.2f, Max: %.2f)\n",
                           ibRangePips, MinIBRangePips, MaxIBRangePips);
   }

   //--- Trend Info
   if(UseTrendFilter)
   {
      int trend = GetTrendDirection();
      string trendStr = (trend > 0) ? "UPTREND" : (trend < 0) ? "DOWNTREND" : "RANGING";
      info += StringFormat("Trend: %s (Method: %s, Mode: %s)\n",
                           trendStr, EnumToString(TrendMethod), EnumToString(TrendFilterMode));
   }
   else
   {
      info += "Trend Filter: DISABLED\n";
   }

   //--- News Info
   if(UseNewsFilter)
   {
      string newsStatus = CheckNewsFilter() ? "CLEAR" : "BLOCKED - NEWS NEARBY";
      info += StringFormat("News Filter: %s (Mode: %s)\n", newsStatus,
                           NewsFilterMode == NEWS_MODE_CALENDAR ? "Calendar" : "Manual");
      info += GetNextNewsEventInfo() + "\n";
   }
   else
   {
      info += "News Filter: DISABLED\n";
   }

   info += "========================\n";

   return info;
}

//+------------------------------------------------------------------+
//| Check if all filters pass for entry                              |
//+------------------------------------------------------------------+
bool CanEnterTrade(int direction)
{
   //--- Check basic trade allowed conditions
   if(!IsTradeAllowed())
      return false;

   //--- Check all filters including directional trend
   if(!CheckFiltersForDirection(direction))
      return false;

   return true;
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                 IB DETECTION & MANAGEMENT                        |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize IB for new trading day                                |
//+------------------------------------------------------------------+
void InitializeIB()
{
   //--- Reset IB variables
   IBHigh = 0;
   IBLow = 0;
   IBMidpoint = 0;
   IBRange = 0;
   IBStartDateTime = 0;
   IBEndDateTime = 0;
   IBStatus = IB_WAITING;
   IBBrokenUp = false;
   IBBrokenDown = false;

   //--- Reset signal variables
   SignalDirection = 0;
   SignalEntryPrice = 0;
   SignalSL = 0;
   SignalTP = 0;
   BreakoutTime = 0;
   CandlesSinceBreak = 0;
   BreakoutRetested = false;
   BreakoutJustOccurred = false;

   //--- Calculate IB start and end times for today
   CalculateIBTimes();

   if(EnableDebugMode)
   {
      PrintFormat("IB Initialized - Start: %s, End: %s",
                  TimeToString(IBStartDateTime, TIME_DATE|TIME_MINUTES),
                  TimeToString(IBEndDateTime, TIME_DATE|TIME_MINUTES));
   }
}

//+------------------------------------------------------------------+
//| Calculate IB start and end times based on timezone               |
//+------------------------------------------------------------------+
void CalculateIBTimes()
{
   //--- Parse IB start time
   int ibHour, ibMinute;
   ParseTimeString(IBStartTime, ibHour, ibMinute);

   //--- Convert IB start time to server time
   datetime serverIBStart = ConvertToServerTime(ibHour, ibMinute, IBTimezone);

   //--- Get today's date in server time
   MqlDateTime serverDT;
   TimeToStruct(TimeCurrent(), serverDT);

   //--- Construct IB start datetime for today
   MqlDateTime ibStartDT;
   TimeToStruct(serverIBStart, ibStartDT);

   //--- Use today's date with IB start time
   ibStartDT.year = serverDT.year;
   ibStartDT.mon = serverDT.mon;
   ibStartDT.day = serverDT.day;

   IBStartDateTime = StructToTime(ibStartDT);

   //--- Calculate IB end time
   IBEndDateTime = IBStartDateTime + IBDurationMinutes * 60;

   //--- Handle case where we're past today's IB end time
   //--- Check if we need to look at tomorrow's IB
   if(TimeCurrent() > IBEndDateTime + 3600) // 1 hour after IB end
   {
      //--- Move to next trading day
      IBStartDateTime += 86400; // Add 24 hours
      IBEndDateTime += 86400;

      //--- Skip weekends
      TimeToStruct(IBStartDateTime, ibStartDT);
      while(ibStartDT.day_of_week == 0 || ibStartDT.day_of_week == 6)
      {
         IBStartDateTime += 86400;
         IBEndDateTime += 86400;
         TimeToStruct(IBStartDateTime, ibStartDT);
      }
   }
}

//+------------------------------------------------------------------+
//| Update IB Levels - Called on each tick/bar                       |
//+------------------------------------------------------------------+
void UpdateIBLevels()
{
   datetime currentTime = TimeCurrent();

   //--- Check IB status and update accordingly
   switch(IBStatus)
   {
      case IB_WAITING:
         CheckIBStart(currentTime);
         break;

      case IB_FORMING:
         UpdateIBFormation(currentTime);
         break;

      case IB_COMPLETE:
         CheckIBBreakout();
         break;

      case IB_BROKEN_UP:
      case IB_BROKEN_DOWN:
         //--- IB already broken, monitor for additional signals
         UpdateBreakoutTracking();
         break;
   }
}

//+------------------------------------------------------------------+
//| Check if IB formation should start                               |
//+------------------------------------------------------------------+
void CheckIBStart(datetime currentTime)
{
   //--- Check if we've reached IB start time
   if(currentTime >= IBStartDateTime && currentTime < IBEndDateTime)
   {
      //--- Start IB formation
      IBStatus = IB_FORMING;

      //--- Initialize with current bar's high/low
      int currentBar = 0;
      IBHigh = iHigh(_Symbol, PERIOD_CURRENT, currentBar);
      IBLow = iLow(_Symbol, PERIOD_CURRENT, currentBar);

      //--- Also check if IB started on previous bars
      UpdateIBFromHistory();

      if(EnableDebugMode)
      {
         PrintFormat("IB Formation STARTED at %s | Initial H: %.5f L: %.5f",
                     TimeToString(currentTime, TIME_MINUTES), IBHigh, IBLow);
      }
   }
}

//+------------------------------------------------------------------+
//| Update IB formation with historical bars                         |
//+------------------------------------------------------------------+
void UpdateIBFromHistory()
{
   //--- Find bars within IB period
   int barsToCheck = Bars(_Symbol, PERIOD_CURRENT);

   for(int i = 0; i < MathMin(barsToCheck, 100); i++)
   {
      datetime barTime = iTime(_Symbol, PERIOD_CURRENT, i);

      //--- Skip bars after IB period
      if(barTime >= IBEndDateTime)
         continue;

      //--- Skip bars before IB start
      if(barTime < IBStartDateTime)
         break;

      //--- Bar is within IB period - update high/low
      double barHigh = iHigh(_Symbol, PERIOD_CURRENT, i);
      double barLow = iLow(_Symbol, PERIOD_CURRENT, i);

      if(barHigh > IBHigh || IBHigh == 0)
         IBHigh = barHigh;

      if(barLow < IBLow || IBLow == 0)
         IBLow = barLow;
   }

   //--- Update derived values
   UpdateIBDerivedValues();
}

//+------------------------------------------------------------------+
//| Update IB during formation period                                |
//+------------------------------------------------------------------+
void UpdateIBFormation(datetime currentTime)
{
   //--- Check if IB period has ended
   if(currentTime >= IBEndDateTime)
   {
      //--- IB formation complete
      CompleteIBFormation();
      return;
   }

   //--- Update IB high/low with current price
   double currentHigh = iHigh(_Symbol, PERIOD_CURRENT, 0);
   double currentLow = iLow(_Symbol, PERIOD_CURRENT, 0);

   bool updated = false;

   if(currentHigh > IBHigh)
   {
      IBHigh = currentHigh;
      updated = true;
   }

   if(currentLow < IBLow || IBLow == 0)
   {
      IBLow = currentLow;
      updated = true;
   }

   if(updated)
   {
      UpdateIBDerivedValues();

      if(EnableDebugMode)
      {
         PrintFormat("IB Updated - H: %.5f L: %.5f Range: %.1f pips",
                     IBHigh, IBLow, IBRange / PipValue);
      }
   }
}

//+------------------------------------------------------------------+
//| Complete IB Formation                                            |
//+------------------------------------------------------------------+
void CompleteIBFormation()
{
   //--- Ensure we have valid IB levels
   if(IBHigh <= 0 || IBLow <= 0 || IBHigh <= IBLow)
   {
      Print("Error: Invalid IB levels - H: ", IBHigh, " L: ", IBLow);
      //--- Reset and wait for next IB
      InitializeIB();
      return;
   }

   //--- Update derived values
   UpdateIBDerivedValues();

   //--- Set status to complete
   IBStatus = IB_COMPLETE;

   Print("═══════════════════════════════════════════════════════════════");
   PrintFormat("IB COMPLETE - High: %.5f | Low: %.5f | Range: %.1f pips",
               IBHigh, IBLow, IBRange / PipValue);
   PrintFormat("IB Period: %s to %s",
               TimeToString(IBStartDateTime, TIME_DATE|TIME_MINUTES),
               TimeToString(IBEndDateTime, TIME_DATE|TIME_MINUTES));
   Print("═══════════════════════════════════════════════════════════════");

   //--- Draw IB levels on chart
   DrawIBLines();

   //--- Send IB Formed alert
   AlertIBFormed();
}

//+------------------------------------------------------------------+
//| Update IB derived values (midpoint, range)                       |
//+------------------------------------------------------------------+
void UpdateIBDerivedValues()
{
   IBRange = IBHigh - IBLow;
   IBMidpoint = IBLow + (IBRange / 2.0);
}

//+------------------------------------------------------------------+
//| Check for IB breakout                                            |
//+------------------------------------------------------------------+
void CheckIBBreakout()
{
   //--- Get current price
   double bid = symbolInfo.Bid();
   double ask = symbolInfo.Ask();

   //--- Check for breakout based on trigger type
   if(EntryTrigger == TRIGGER_IMMEDIATE)
   {
      //--- Check immediate price breakout
      if(ask > IBHigh && !IBBrokenUp)
      {
         RegisterBreakout(1, ask);
      }
      else if(bid < IBLow && !IBBrokenDown)
      {
         RegisterBreakout(-1, bid);
      }
   }
   else // TRIGGER_CANDLE_CLOSE
   {
      //--- Check candle close breakout (only on new bar)
      if(CurrentTickIsNewBar)
      {
         double prevClose = iClose(_Symbol, PERIOD_CURRENT, 1);

         if(prevClose > IBHigh && !IBBrokenUp)
         {
            RegisterBreakout(1, prevClose);
         }
         else if(prevClose < IBLow && !IBBrokenDown)
         {
            RegisterBreakout(-1, prevClose);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Register a breakout event                                        |
//+------------------------------------------------------------------+
void RegisterBreakout(int direction, double breakPrice)
{
   BreakoutTime = TimeCurrent();
   CandlesSinceBreak = 0;
   BreakoutRetested = false;

   if(direction > 0)
   {
      IBStatus = IB_BROKEN_UP;
      IBBrokenUp = true;

      PrintFormat("▲ IB BROKEN UPWARD at %.5f | Time: %s",
                  breakPrice, TimeToString(BreakoutTime, TIME_MINUTES));
   }
   else
   {
      IBStatus = IB_BROKEN_DOWN;
      IBBrokenDown = true;

      PrintFormat("▼ IB BROKEN DOWNWARD at %.5f | Time: %s",
                  breakPrice, TimeToString(BreakoutTime, TIME_MINUTES));
   }

   //--- Send Breakout alert
   AlertBreakout(direction, breakPrice);

   //--- Draw breakout marker
   DrawBreakoutMarker(direction, breakPrice);

   //--- Set flag for immediate entry processing in OnTick
   BreakoutJustOccurred = true;
}

//+------------------------------------------------------------------+
//| Update breakout tracking                                         |
//+------------------------------------------------------------------+
void UpdateBreakoutTracking()
{
   //--- Count candles since breakout
   if(CurrentTickIsNewBar)
   {
      CandlesSinceBreak++;
   }

   //--- Check for retest if required
   if(RequireRetestForBreakout && !BreakoutRetested)
   {
      CheckForRetest();
   }

   //--- Check if price came back inside IB (for Fade mode)
   if(EntryMode == MODE_FADE || EntryMode == MODE_HYBRID)
   {
      CheckForFadeSignal();
   }
}

//+------------------------------------------------------------------+
//| Check for retest of IB level                                     |
//+------------------------------------------------------------------+
void CheckForRetest()
{
   double bid = symbolInfo.Bid();

   if(IBStatus == IB_BROKEN_UP)
   {
      //--- Check if price came back to touch/near IB high
      if(bid <= IBHigh + (SLBufferPips * PipValue))
      {
         BreakoutRetested = true;
         if(EnableDebugMode) Print("Retest of IB High detected");
      }
   }
   else if(IBStatus == IB_BROKEN_DOWN)
   {
      //--- Check if price came back to touch/near IB low
      if(bid >= IBLow - (SLBufferPips * PipValue))
      {
         BreakoutRetested = true;
         if(EnableDebugMode) Print("Retest of IB Low detected");
      }
   }
}

//+------------------------------------------------------------------+
//| Check for fade (reversal) signal                                 |
//+------------------------------------------------------------------+
void CheckForFadeSignal()
{
   double bid = symbolInfo.Bid();

   //--- For fade, we want price to break out and then come back inside
   if(IBStatus == IB_BROKEN_UP && bid < IBHigh)
   {
      //--- Price broke up but came back inside - potential short fade
      if(EnableDebugMode) Print("Fade signal: Price back inside IB after upward break");
   }
   else if(IBStatus == IB_BROKEN_DOWN && bid > IBLow)
   {
      //--- Price broke down but came back inside - potential long fade
      if(EnableDebugMode) Print("Fade signal: Price back inside IB after downward break");
   }
}

//+------------------------------------------------------------------+
//| Check if price is inside IB range                                |
//+------------------------------------------------------------------+
bool IsPriceInsideIB()
{
   double bid = symbolInfo.Bid();
   return (bid >= IBLow && bid <= IBHigh);
}

//+------------------------------------------------------------------+
//| Check if price is above IB                                       |
//+------------------------------------------------------------------+
bool IsPriceAboveIB()
{
   return (symbolInfo.Bid() > IBHigh);
}

//+------------------------------------------------------------------+
//| Check if price is below IB                                       |
//+------------------------------------------------------------------+
bool IsPriceBelowIB()
{
   return (symbolInfo.Bid() < IBLow);
}

//+------------------------------------------------------------------+
//| Get breakout distance in pips                                    |
//+------------------------------------------------------------------+
double GetBreakoutDistancePips()
{
   double bid = symbolInfo.Bid();
   double distance = 0;

   if(IBStatus == IB_BROKEN_UP)
   {
      distance = bid - IBHigh;
   }
   else if(IBStatus == IB_BROKEN_DOWN)
   {
      distance = IBLow - bid;
   }

   return distance / PipValue;
}

//+------------------------------------------------------------------+
//| Check if breakout distance is valid                              |
//+------------------------------------------------------------------+
bool IsBreakoutDistanceValid()
{
   double distancePips = GetBreakoutDistancePips();

   //--- Check minimum distance
   if(MinBreakDistancePips > 0 && distancePips < MinBreakDistancePips)
   {
      if(EnableDebugMode) PrintFormat("Breakout distance too small: %.2f pips < Min %.2f",
                                 distancePips, MinBreakDistancePips);
      return false;
   }

   //--- Check maximum distance
   if(MaxBreakDistancePips > 0 && distancePips > MaxBreakDistancePips)
   {
      if(EnableDebugMode) PrintFormat("Breakout distance too large: %.2f pips > Max %.2f",
                                 distancePips, MaxBreakDistancePips);
      return false;
   }

   //--- Check ATR-based distance if enabled
   if(UseATRBreakDistance)
   {
      double atr = GetATRValue();
      if(atr > 0)
      {
         double distanceATR = (distancePips * PipValue) / atr;

         if(MinBreakATRMultiple > 0 && distanceATR < MinBreakATRMultiple)
         {
            if(EnableDebugMode) PrintFormat("Breakout distance too small: %.2f ATR < Min %.2f",
                                       distanceATR, MinBreakATRMultiple);
            return false;
         }

         if(MaxBreakATRMultiple > 0 && distanceATR > MaxBreakATRMultiple)
         {
            if(EnableDebugMode) PrintFormat("Breakout distance too large: %.2f ATR > Max %.2f",
                                       distanceATR, MaxBreakATRMultiple);
            return false;
         }
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if IB is ready for trading                                 |
//+------------------------------------------------------------------+
bool IsIBReadyForTrading()
{
   //--- IB must be complete or broken
   if(IBStatus < IB_COMPLETE)
      return false;

   //--- Validate IB range
   if(IBRange <= 0)
      return false;

   //--- Check IB range against volatility filter
   if(UseVolatilityFilter && !CheckVolatilityFilter())
      return false;

   return true;
}

//+------------------------------------------------------------------+
//|                     SETTLEMENT FUNCTIONS                         |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize Settlement for new trading day                         |
//+------------------------------------------------------------------+
void InitializeSettlement()
{
   //--- Reset Settlement variables
   SettlementPrice = 0;
   SettlementHigh = 0;
   SettlementLow = 0;
   SettlementMidpoint = 0;
   SettlementRange = 0;
   SettlementStartDateTime = 0;
   SettlementEndDateTime = 0;
   SettlementStatus = SETTLE_WAITING;
   SettlementBrokenUp = false;
   SettlementBrokenDown = false;

   //--- Reset tick collection
   SettlementTickSum = 0;
   SettlementTickCount = 0;
   LastSettlementTickTime = 0;
   SettlementM1BarsProcessed = 0;

   //--- Reset tracking variables
   SettlementBreakoutJustOccurred = false;
   SettlementCandlesSinceBreak = 0;
   SettlementRetested = false;

   //--- Calculate Settlement start and end times for today
   CalculateSettlementTimes();

   if(EnableDebugMode)
   {
      PrintFormat("Settlement Initialized - Start: %s, End: %s",
                  TimeToString(SettlementStartDateTime, TIME_DATE|TIME_MINUTES),
                  TimeToString(SettlementEndDateTime, TIME_DATE|TIME_MINUTES));
   }
}

//+------------------------------------------------------------------+
//| Calculate Settlement start and end times based on timezone        |
//+------------------------------------------------------------------+
void CalculateSettlementTimes()
{
   //--- Parse Settlement start time
   int settleHour, settleMinute;
   ParseTimeString(SettlementStartTime, settleHour, settleMinute);

   //--- Convert Settlement start time to server time
   datetime serverSettleStart = ConvertToServerTime(settleHour, settleMinute, SettlementTimezone);

   //--- Get today's date in server time
   MqlDateTime serverDT;
   TimeToStruct(TimeCurrent(), serverDT);

   //--- Construct Settlement start datetime for today
   MqlDateTime settleStartDT;
   TimeToStruct(serverSettleStart, settleStartDT);

   //--- Use today's date with Settlement start time
   settleStartDT.year = serverDT.year;
   settleStartDT.mon = serverDT.mon;
   settleStartDT.day = serverDT.day;

   SettlementStartDateTime = StructToTime(settleStartDT);

   //--- Calculate Settlement end time
   SettlementEndDateTime = SettlementStartDateTime + SettlementDurationMinutes * 60;

   //--- Handle case where we're past today's Settlement end time
   if(TimeCurrent() > SettlementEndDateTime + 3600) // 1 hour after Settlement end
   {
      //--- Move to next trading day
      SettlementStartDateTime += 86400; // Add 24 hours
      SettlementEndDateTime += 86400;

      //--- Skip weekends
      TimeToStruct(SettlementStartDateTime, settleStartDT);
      while(settleStartDT.day_of_week == 0 || settleStartDT.day_of_week == 6)
      {
         SettlementStartDateTime += 86400;
         SettlementEndDateTime += 86400;
         TimeToStruct(SettlementStartDateTime, settleStartDT);
      }
   }
}

//+------------------------------------------------------------------+
//| Update Settlement Levels - Called on each tick                    |
//+------------------------------------------------------------------+
void UpdateSettlementLevels()
{
   datetime currentTime = TimeCurrent();

   //--- Check Settlement status and update accordingly
   switch(SettlementStatus)
   {
      case SETTLE_WAITING:
         CheckSettlementStart(currentTime);
         break;

      case SETTLE_COLLECTING:
         CollectSettlementData();
         CheckSettlementComplete(currentTime);
         break;

      case SETTLE_COMPLETE:
         CheckSettlementBreakout();
         break;

      case SETTLE_BROKEN_UP:
      case SETTLE_BROKEN_DOWN:
         //--- Settlement already broken, monitor for additional signals
         UpdateSettlementBreakoutTracking();
         break;
   }
}

//+------------------------------------------------------------------+
//| Check if Settlement collection should start                       |
//+------------------------------------------------------------------+
void CheckSettlementStart(datetime currentTime)
{
   //--- Check if we've reached Settlement start time
   if(currentTime >= SettlementStartDateTime && currentTime < SettlementEndDateTime)
   {
      //--- Start Settlement collection
      SettlementStatus = SETTLE_COLLECTING;

      //--- Reset collection variables
      SettlementTickSum = 0;
      SettlementTickCount = 0;
      SettlementM1BarsProcessed = 0;

      if(EnableDebugMode)
      {
         PrintFormat("Settlement Collection STARTED at %s",
                     TimeToString(currentTime, TIME_MINUTES));
      }

      //--- If using M1 data source, collect historical M1 bars
      if(SettlementDataSource == SETTLE_SOURCE_M1)
      {
         CollectSettlementFromM1History();
      }
   }
}

//+------------------------------------------------------------------+
//| Collect Settlement data (tick or M1 bar)                          |
//+------------------------------------------------------------------+
void CollectSettlementData()
{
   if(SettlementDataSource == SETTLE_SOURCE_TICKS)
   {
      CollectSettlementTick();
   }
   else
   {
      CollectSettlementFromM1();
   }
}

//+------------------------------------------------------------------+
//| Collect tick data for Settlement calculation                      |
//+------------------------------------------------------------------+
void CollectSettlementTick()
{
   datetime currentTime = TimeCurrent();

   //--- Prevent duplicate ticks within same second
   if(currentTime == LastSettlementTickTime)
      return;
   LastSettlementTickTime = currentTime;

   //--- Get current price (use bid for consistency)
   double price = symbolInfo.Bid();

   //--- Add to running sum for simple average
   SettlementTickSum += price;
   SettlementTickCount++;
}

//+------------------------------------------------------------------+
//| Collect M1 bar data for Settlement calculation (backtest mode)    |
//+------------------------------------------------------------------+
void CollectSettlementFromM1()
{
   //--- Get the number of M1 bars since collection started
   int barsAvailable = Bars(_Symbol, PERIOD_M1, SettlementStartDateTime, TimeCurrent());

   //--- Only process new bars
   if(barsAvailable <= SettlementM1BarsProcessed)
      return;

   //--- Process new M1 bars
   for(int i = SettlementM1BarsProcessed; i < barsAvailable; i++)
   {
      int barShift = barsAvailable - 1 - i;
      double closePrice = iClose(_Symbol, PERIOD_M1, barShift);

      if(closePrice > 0)
      {
         SettlementTickSum += closePrice;
         SettlementTickCount++;
      }
   }

   SettlementM1BarsProcessed = barsAvailable;
}

//+------------------------------------------------------------------+
//| Collect M1 history at start of collection period                  |
//+------------------------------------------------------------------+
void CollectSettlementFromM1History()
{
   //--- Get M1 bars within settlement period that already exist
   int barsAvailable = Bars(_Symbol, PERIOD_M1, SettlementStartDateTime, TimeCurrent());

   if(barsAvailable <= 0)
      return;

   //--- Process all available M1 bars
   for(int i = 0; i < barsAvailable; i++)
   {
      int barShift = barsAvailable - 1 - i;
      double closePrice = iClose(_Symbol, PERIOD_M1, barShift);

      if(closePrice > 0)
      {
         SettlementTickSum += closePrice;
         SettlementTickCount++;
      }
   }

   SettlementM1BarsProcessed = barsAvailable;

   if(EnableDebugMode)
   {
      PrintFormat("Settlement: Collected %d M1 bars from history", barsAvailable);
   }
}

//+------------------------------------------------------------------+
//| Check if Settlement collection is complete                        |
//+------------------------------------------------------------------+
void CheckSettlementComplete(datetime currentTime)
{
   //--- Check if collection period has ended
   if(currentTime >= SettlementEndDateTime)
   {
      //--- Calculate Settlement price
      SettlementPrice = CalculateSettlementPrice();

      if(SettlementPrice <= 0)
      {
         PrintFormat("Warning: Settlement calculation failed (Ticks: %d, Min Required: %d)",
                     SettlementTickCount, SettlementMinTicks);
         return;
      }

      //--- Calculate Settlement range boundaries
      CalculateSettlementRange();

      //--- Set status to complete
      SettlementStatus = SETTLE_COMPLETE;

      //--- Draw Settlement levels
      if(DrawSettlementLevels)
      {
         DrawSettlementLines();
      }

      PrintFormat("Settlement COMPLETE: Price=%.5f, High=%.5f, Low=%.5f, Range=%.1f pips (Ticks: %d)",
                  SettlementPrice, SettlementHigh, SettlementLow,
                  SettlementRange / PipValue, SettlementTickCount);
   }
}

//+------------------------------------------------------------------+
//| Calculate Settlement price from collected data                    |
//+------------------------------------------------------------------+
double CalculateSettlementPrice()
{
   //--- Check minimum tick requirement
   if(SettlementTickCount < SettlementMinTicks)
   {
      if(EnableDebugMode)
      {
         PrintFormat("Settlement: Insufficient data - %d ticks (min: %d)",
                     SettlementTickCount, SettlementMinTicks);
      }
      return 0;
   }

   //--- Calculate simple average
   double avgPrice = SettlementTickSum / SettlementTickCount;

   //--- Normalize to symbol digits
   return NormalizeDouble(avgPrice, SymbolDigits);
}

//+------------------------------------------------------------------+
//| Calculate Settlement range boundaries                             |
//+------------------------------------------------------------------+
void CalculateSettlementRange()
{
   double rangeDistance = 0;

   switch(SettlementRangeMethod)
   {
      case SETTLE_RANGE_FIXED:
         //--- Fixed pips from Settlement price
         rangeDistance = SettlementFixedPips * PipValue;
         SettlementHigh = SettlementPrice + rangeDistance;
         SettlementLow = SettlementPrice - rangeDistance;
         break;

      case SETTLE_RANGE_ATR:
         //--- ATR-based range
         {
            double atr = GetATRValue();
            if(atr > 0)
            {
               rangeDistance = atr * SettlementATRMultiple;
               SettlementHigh = SettlementPrice + rangeDistance;
               SettlementLow = SettlementPrice - rangeDistance;
            }
            else
            {
               //--- Fallback to fixed pips if ATR not available
               rangeDistance = SettlementFixedPips * PipValue;
               SettlementHigh = SettlementPrice + rangeDistance;
               SettlementLow = SettlementPrice - rangeDistance;
               if(EnableDebugMode) Print("Settlement: ATR not available, using fixed pips fallback");
            }
         }
         break;

      case SETTLE_RANGE_CANDLES:
         //--- X minutes candle range (high-low of period)
         CalculateSettlementCandleRange();
         break;
   }

   //--- Calculate derived values
   SettlementMidpoint = SettlementPrice;  // Midpoint is the settlement price itself
   SettlementRange = SettlementHigh - SettlementLow;

   //--- Normalize values
   SettlementHigh = NormalizeDouble(SettlementHigh, SymbolDigits);
   SettlementLow = NormalizeDouble(SettlementLow, SymbolDigits);
   SettlementRange = NormalizeDouble(SettlementRange, SymbolDigits);
}

//+------------------------------------------------------------------+
//| Calculate Settlement range from X minutes of candle data          |
//+------------------------------------------------------------------+
void CalculateSettlementCandleRange()
{
   //--- Calculate how many M1 bars to look back
   int barsToCheck = SettlementCandleMinutes;

   //--- Get high and low of the period
   double periodHigh = 0;
   double periodLow = DBL_MAX;

   for(int i = 0; i < barsToCheck; i++)
   {
      double high = iHigh(_Symbol, PERIOD_M1, i);
      double low = iLow(_Symbol, PERIOD_M1, i);

      if(high > periodHigh) periodHigh = high;
      if(low < periodLow && low > 0) periodLow = low;
   }

   if(periodHigh > 0 && periodLow < DBL_MAX)
   {
      SettlementHigh = periodHigh;
      SettlementLow = periodLow;
   }
   else
   {
      //--- Fallback: use fixed pips if candle data not available
      double rangeDistance = SettlementFixedPips * PipValue;
      SettlementHigh = SettlementPrice + rangeDistance;
      SettlementLow = SettlementPrice - rangeDistance;
      if(EnableDebugMode) Print("Settlement: Candle range not available, using fixed pips fallback");
   }
}

//+------------------------------------------------------------------+
//| Check for Settlement range breakout                               |
//+------------------------------------------------------------------+
void CheckSettlementBreakout()
{
   double bid = symbolInfo.Bid();
   double ask = symbolInfo.Ask();

   bool breakoutUp = false;
   bool breakoutDown = false;

   //--- Check breakout based on entry trigger
   if(EntryTrigger == TRIGGER_IMMEDIATE)
   {
      //--- Immediate trigger: check current price
      breakoutUp = (ask > SettlementHigh);
      breakoutDown = (bid < SettlementLow);
   }
   else // TRIGGER_CANDLE_CLOSE
   {
      //--- Candle close trigger: check last closed bar
      if(CurrentTickIsNewBar)
      {
         double lastClose = iClose(_Symbol, PERIOD_CURRENT, 1);
         breakoutUp = (lastClose > SettlementHigh);
         breakoutDown = (lastClose < SettlementLow);
      }
   }

   //--- Update Settlement status on breakout
   if(breakoutUp && !SettlementBrokenUp)
   {
      SettlementStatus = SETTLE_BROKEN_UP;
      SettlementBrokenUp = true;
      SettlementBreakoutJustOccurred = true;
      SettlementCandlesSinceBreak = 0;

      PrintFormat("Settlement BROKEN UP at %.5f (High: %.5f)", bid, SettlementHigh);
   }
   else if(breakoutDown && !SettlementBrokenDown)
   {
      SettlementStatus = SETTLE_BROKEN_DOWN;
      SettlementBrokenDown = true;
      SettlementBreakoutJustOccurred = true;
      SettlementCandlesSinceBreak = 0;

      PrintFormat("Settlement BROKEN DOWN at %.5f (Low: %.5f)", bid, SettlementLow);
   }
}

//+------------------------------------------------------------------+
//| Update Settlement breakout tracking                               |
//+------------------------------------------------------------------+
void UpdateSettlementBreakoutTracking()
{
   //--- Count candles since breakout
   if(CurrentTickIsNewBar)
   {
      SettlementCandlesSinceBreak++;
   }

   //--- Check for retest if required
   if(RequireRetestForBreakout && !SettlementRetested)
   {
      CheckSettlementRetest();
   }

   //--- Check if price came back inside Settlement (for Fade mode)
   if(EntryMode == MODE_FADE || EntryMode == MODE_HYBRID)
   {
      CheckSettlementFadeCondition();
   }
}

//+------------------------------------------------------------------+
//| Check for retest of Settlement level                              |
//+------------------------------------------------------------------+
void CheckSettlementRetest()
{
   double bid = symbolInfo.Bid();

   if(SettlementStatus == SETTLE_BROKEN_UP)
   {
      //--- Check if price came back to touch/near Settlement high
      if(bid <= SettlementHigh + (SLBufferPips * PipValue))
      {
         SettlementRetested = true;
         if(EnableDebugMode) Print("Retest of Settlement High detected");
      }
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN)
   {
      //--- Check if price came back to touch/near Settlement low
      if(bid >= SettlementLow - (SLBufferPips * PipValue))
      {
         SettlementRetested = true;
         if(EnableDebugMode) Print("Retest of Settlement Low detected");
      }
   }
}

//+------------------------------------------------------------------+
//| Check for Settlement fade (reversal) condition                    |
//+------------------------------------------------------------------+
void CheckSettlementFadeCondition()
{
   double bid = symbolInfo.Bid();

   //--- For fade, we want price to break out and then come back inside
   if(SettlementStatus == SETTLE_BROKEN_UP && bid < SettlementHigh)
   {
      if(EnableDebugMode) Print("Settlement Fade: Price back inside after upward break");
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN && bid > SettlementLow)
   {
      if(EnableDebugMode) Print("Settlement Fade: Price back inside after downward break");
   }
}

//+------------------------------------------------------------------+
//| Check if price is inside Settlement range                         |
//+------------------------------------------------------------------+
bool IsPriceInsideSettlement()
{
   double bid = symbolInfo.Bid();
   return (bid >= SettlementLow && bid <= SettlementHigh);
}

//+------------------------------------------------------------------+
//| Check if price is above Settlement range                          |
//+------------------------------------------------------------------+
bool IsPriceAboveSettlement()
{
   return (symbolInfo.Bid() > SettlementHigh);
}

//+------------------------------------------------------------------+
//| Check if price is below Settlement range                          |
//+------------------------------------------------------------------+
bool IsPriceBelowSettlement()
{
   return (symbolInfo.Bid() < SettlementLow);
}

//+------------------------------------------------------------------+
//| Get Settlement breakout distance in pips                          |
//+------------------------------------------------------------------+
double GetSettlementBreakoutDistancePips()
{
   double bid = symbolInfo.Bid();
   double distance = 0;

   if(SettlementStatus == SETTLE_BROKEN_UP)
   {
      distance = bid - SettlementHigh;
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN)
   {
      distance = SettlementLow - bid;
   }

   return distance / PipValue;
}

//+------------------------------------------------------------------+
//| Check if Settlement breakout distance is valid                    |
//+------------------------------------------------------------------+
bool IsSettlementBreakoutDistanceValid()
{
   double distancePips = GetSettlementBreakoutDistancePips();

   //--- Check minimum distance
   if(SettlementMinBreakPips > 0 && distancePips < SettlementMinBreakPips)
   {
      if(EnableDebugMode) PrintFormat("Settlement breakout distance too small: %.2f pips < Min %.2f",
                                 distancePips, SettlementMinBreakPips);
      return false;
   }

   //--- Check maximum distance
   if(SettlementMaxBreakPips > 0 && distancePips > SettlementMaxBreakPips)
   {
      if(EnableDebugMode) PrintFormat("Settlement breakout distance too large: %.2f pips > Max %.2f",
                                 distancePips, SettlementMaxBreakPips);
      return false;
   }

   return true;
}

//+------------------------------------------------------------------+
//| Check if Settlement is ready for trading                          |
//+------------------------------------------------------------------+
bool IsSettlementReadyForTrading()
{
   //--- Settlement must be complete or broken
   if(SettlementStatus < SETTLE_COMPLETE)
      return false;

   //--- Validate Settlement range
   if(SettlementRange <= 0)
      return false;

   //--- Check Settlement range against volatility filter
   if(UseVolatilityFilter && !CheckVolatilityFilter())
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Check if range is ready for trading (unified for IB/Settlement)   |
//+------------------------------------------------------------------+
bool IsRangeReadyForTrading()
{
   if(RangeStrategy == STRATEGY_SETTLEMENT)
      return IsSettlementReadyForTrading();
   else
      return IsIBReadyForTrading();
}

//+------------------------------------------------------------------+
//| Get Settlement status string for dashboard                        |
//+------------------------------------------------------------------+
string GetSettlementStatusString()
{
   switch(SettlementStatus)
   {
      case SETTLE_WAITING:     return "Waiting";
      case SETTLE_COLLECTING:  return StringFormat("Collecting (%d)", SettlementTickCount);
      case SETTLE_COMPLETE:    return StringFormat("Complete @ %.5f", SettlementPrice);
      case SETTLE_BROKEN_UP:   return "Broken UP";
      case SETTLE_BROKEN_DOWN: return "Broken DOWN";
   }
   return "Unknown";
}

//+------------------------------------------------------------------+
//| Draw Settlement lines on chart                                    |
//+------------------------------------------------------------------+
void DrawSettlementLines()
{
   if(!DrawSettlementLevels)
      return;

   //--- Delete existing lines first
   RemoveSettlementLines();

   //--- Draw Settlement Price line
   string priceName = DashboardPrefix + "SettlementPrice";
   ObjectCreate(0, priceName, OBJ_HLINE, 0, 0, SettlementPrice);
   ObjectSetInteger(0, priceName, OBJPROP_COLOR, SettlementPriceColor);
   ObjectSetInteger(0, priceName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, priceName, OBJPROP_WIDTH, 2);
   ObjectSetString(0, priceName, OBJPROP_TEXT, "Settlement");
   ObjectSetInteger(0, priceName, OBJPROP_BACK, true);

   //--- Draw Settlement High line
   string highName = DashboardPrefix + "SettlementHigh";
   ObjectCreate(0, highName, OBJ_HLINE, 0, 0, SettlementHigh);
   ObjectSetInteger(0, highName, OBJPROP_COLOR, SettlementRangeColor);
   ObjectSetInteger(0, highName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, highName, OBJPROP_WIDTH, 1);
   ObjectSetString(0, highName, OBJPROP_TEXT, "Settle High");
   ObjectSetInteger(0, highName, OBJPROP_BACK, true);

   //--- Draw Settlement Low line
   string lowName = DashboardPrefix + "SettlementLow";
   ObjectCreate(0, lowName, OBJ_HLINE, 0, 0, SettlementLow);
   ObjectSetInteger(0, lowName, OBJPROP_COLOR, SettlementRangeColor);
   ObjectSetInteger(0, lowName, OBJPROP_STYLE, STYLE_DASH);
   ObjectSetInteger(0, lowName, OBJPROP_WIDTH, 1);
   ObjectSetString(0, lowName, OBJPROP_TEXT, "Settle Low");
   ObjectSetInteger(0, lowName, OBJPROP_BACK, true);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Remove Settlement lines from chart                                |
//+------------------------------------------------------------------+
void RemoveSettlementLines()
{
   ObjectDelete(0, DashboardPrefix + "SettlementPrice");
   ObjectDelete(0, DashboardPrefix + "SettlementHigh");
   ObjectDelete(0, DashboardPrefix + "SettlementLow");
}

//+------------------------------------------------------------------+
//| Check for Settlement daily reset                                  |
//+------------------------------------------------------------------+
void CheckSettlementDailyReset()
{
   static datetime lastResetDate = 0;

   MqlDateTime currentDT;
   TimeToStruct(TimeCurrent(), currentDT);
   datetime todayDate = StringToTime(StringFormat("%04d.%02d.%02d 00:00",
                                     currentDT.year, currentDT.mon, currentDT.day));

   if(todayDate != lastResetDate)
   {
      //--- New day detected, reinitialize Settlement
      InitializeSettlement();
      lastResetDate = todayDate;

      if(EnableDebugMode)
      {
         Print("Settlement daily reset performed");
      }
   }
}

//+------------------------------------------------------------------+
//| Get short timezone name for display                              |
//+------------------------------------------------------------------+
string GetTimezoneShortName(ENUM_TIMEZONE timezone)
{
   switch(timezone)
   {
      case TZ_SERVER:   return "SRV";
      case TZ_LOCAL:    return "LOC";
      case TZ_LONDON:   return "LDN";
      case TZ_NEWYORK:  return "NY";
      default:          return "??";
   }
}

//+------------------------------------------------------------------+
//| Format seconds to MM:SS or HH:MM:SS string                       |
//+------------------------------------------------------------------+
string FormatTimeRemaining(int totalSeconds)
{
   if(totalSeconds < 0)
      return "00:00";

   int hours = totalSeconds / 3600;
   int minutes = (totalSeconds % 3600) / 60;
   int seconds = totalSeconds % 60;

   if(hours > 0)
      return StringFormat("%02d:%02d:%02d", hours, minutes, seconds);
   else
      return StringFormat("%02d:%02d", minutes, seconds);
}

//+------------------------------------------------------------------+
//| Get IB status string for display                                 |
//+------------------------------------------------------------------+
string GetIBStatusString()
{
   switch(IBStatus)
   {
      case IB_WAITING:
         return StringFormat("Waiting (%s %s)",
                             IBStartTime, GetTimezoneShortName(IBTimezone));

      case IB_FORMING:
         return StringFormat("Forming H:%.5f L:%.5f",
                             IBHigh, IBLow);

      case IB_COMPLETE:
         return StringFormat("Complete H:%.5f L:%.5f (%.1f pips)",
                             IBHigh, IBLow, IBRange / PipValue);

      case IB_BROKEN_UP:
         return StringFormat("BROKEN UP ▲ at %.5f (+%.1f pips)",
                             IBHigh, GetBreakoutDistancePips());

      case IB_BROKEN_DOWN:
         return StringFormat("BROKEN DOWN ▼ at %.5f (-%.1f pips)",
                             IBLow, GetBreakoutDistancePips());

      default:
         return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get IB time remaining string for display                         |
//+------------------------------------------------------------------+
string GetIBRemainingString()
{
   datetime now = TimeCurrent();
   int remaining = 0;

   switch(IBStatus)
   {
      case IB_WAITING:
         remaining = (int)(IBStartDateTime - now);
         if(remaining < 0) remaining = 0;
         return StringFormat("Starts in: %s", FormatTimeRemaining(remaining));

      case IB_FORMING:
         remaining = (int)(IBEndDateTime - now);
         if(remaining < 0) remaining = 0;
         return StringFormat("Ends in: %s", FormatTimeRemaining(remaining));

      case IB_COMPLETE:
      case IB_BROKEN_UP:
      case IB_BROKEN_DOWN:
         return StringFormat("Range: %.1f pips", IBRange / PipValue);

      default:
         return "";
   }
}

//+------------------------------------------------------------------+
//| Get detailed IB info for logging                                 |
//+------------------------------------------------------------------+
string GetDetailedIBInfo()
{
   string info = "\n===== IB STATUS =====\n";

   info += StringFormat("Status: %s\n", EnumToString(IBStatus));
   info += StringFormat("IB Period: %s to %s (%s)\n",
                        TimeToString(IBStartDateTime, TIME_DATE|TIME_MINUTES),
                        TimeToString(IBEndDateTime, TIME_MINUTES),
                        EnumToString(IBTimezone));

   if(IBStatus >= IB_FORMING)
   {
      info += StringFormat("High: %.5f\n", IBHigh);
      info += StringFormat("Low: %.5f\n", IBLow);
      info += StringFormat("Midpoint: %.5f\n", IBMidpoint);
      info += StringFormat("Range: %.5f (%.1f pips)\n", IBRange, IBRange / PipValue);
   }

   if(IBStatus >= IB_BROKEN_UP || IBStatus >= IB_BROKEN_DOWN)
   {
      info += StringFormat("Breakout Time: %s\n", TimeToString(BreakoutTime, TIME_MINUTES));
      info += StringFormat("Candles Since Break: %d\n", CandlesSinceBreak);
      info += StringFormat("Retest: %s\n", BreakoutRetested ? "Yes" : "No");
      info += StringFormat("Breakout Distance: %.1f pips\n", GetBreakoutDistancePips());
   }

   info += "=====================\n";

   return info;
}

//+------------------------------------------------------------------+
//| Draw IB lines on chart                                           |
//+------------------------------------------------------------------+
void DrawIBLines()
{
   if(!DrawIBLevels)
      return;

   string prefix = DashboardPrefix + "IB_";

   //--- Get line style
   ENUM_LINE_STYLE lineStyle;
   switch(IBLineStyle)
   {
      case LINE_DASHED: lineStyle = STYLE_DASH; break;
      case LINE_DOTTED: lineStyle = STYLE_DOT; break;
      default: lineStyle = STYLE_SOLID; break;
   }

   //--- Draw IB High line
   string highName = prefix + "High";
   if(ObjectFind(0, highName) < 0)
      ObjectCreate(0, highName, OBJ_HLINE, 0, 0, IBHigh);
   else
      ObjectSetDouble(0, highName, OBJPROP_PRICE, IBHigh);

   ObjectSetInteger(0, highName, OBJPROP_COLOR, IBHighColor);
   ObjectSetInteger(0, highName, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, highName, OBJPROP_WIDTH, IBLineWidth);
   ObjectSetString(0, highName, OBJPROP_TEXT, "IB High");
   ObjectSetInteger(0, highName, OBJPROP_SELECTABLE, false);

   //--- Draw IB Low line
   string lowName = prefix + "Low";
   if(ObjectFind(0, lowName) < 0)
      ObjectCreate(0, lowName, OBJ_HLINE, 0, 0, IBLow);
   else
      ObjectSetDouble(0, lowName, OBJPROP_PRICE, IBLow);

   ObjectSetInteger(0, lowName, OBJPROP_COLOR, IBLowColor);
   ObjectSetInteger(0, lowName, OBJPROP_STYLE, lineStyle);
   ObjectSetInteger(0, lowName, OBJPROP_WIDTH, IBLineWidth);
   ObjectSetString(0, lowName, OBJPROP_TEXT, "IB Low");
   ObjectSetInteger(0, lowName, OBJPROP_SELECTABLE, false);

   //--- Draw IB Midpoint line
   string midName = prefix + "Mid";
   if(ObjectFind(0, midName) < 0)
      ObjectCreate(0, midName, OBJ_HLINE, 0, 0, IBMidpoint);
   else
      ObjectSetDouble(0, midName, OBJPROP_PRICE, IBMidpoint);

   ObjectSetInteger(0, midName, OBJPROP_COLOR, IBMidColor);
   ObjectSetInteger(0, midName, OBJPROP_STYLE, STYLE_DOT);
   ObjectSetInteger(0, midName, OBJPROP_WIDTH, 1);
   ObjectSetString(0, midName, OBJPROP_TEXT, "IB Mid");
   ObjectSetInteger(0, midName, OBJPROP_SELECTABLE, false);

   //--- Highlight IB period if enabled
   if(HighlightIBPeriod)
   {
      DrawIBHighlight();
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Draw IB period highlight rectangle                               |
//+------------------------------------------------------------------+
void DrawIBHighlight()
{
   string rectName = DashboardPrefix + "IB_Rect";

   if(ObjectFind(0, rectName) < 0)
      ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                   IBStartDateTime, IBHigh,
                   IBEndDateTime, IBLow);
   else
   {
      ObjectSetInteger(0, rectName, OBJPROP_TIME, 0, IBStartDateTime);
      ObjectSetDouble(0, rectName, OBJPROP_PRICE, 0, IBHigh);
      ObjectSetInteger(0, rectName, OBJPROP_TIME, 1, IBEndDateTime);
      ObjectSetDouble(0, rectName, OBJPROP_PRICE, 1, IBLow);
   }

   ObjectSetInteger(0, rectName, OBJPROP_COLOR, IBHighlightColor);
   ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, rectName, OBJPROP_FILL, true);
   ObjectSetInteger(0, rectName, OBJPROP_BACK, true);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Remove IB lines from chart                                       |
//+------------------------------------------------------------------+
void RemoveIBLines()
{
   string prefix = DashboardPrefix + "IB_";
   ObjectsDeleteAll(0, prefix);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                    PHASE 9: VISUAL ELEMENTS                      |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Draw entry/SL/TP lines for active position                       |
//+------------------------------------------------------------------+
void DrawTradeLines(double entryPrice, double slPrice, double tpPrice, int direction)
{
   if(!DrawEntryExitLines)
      return;

   string prefix = DashboardPrefix + "Trade_";
   datetime startTime = TimeCurrent();
   datetime endTime = startTime + PeriodSeconds(PERIOD_D1); // Extend 1 day forward

   //--- Draw Entry Line
   string entryName = prefix + "Entry";
   CreatePriceLine(entryName, entryPrice, EntryLineColor, STYLE_SOLID, 2,
                   "Entry: " + DoubleToString(entryPrice, (int)symbolInfo.Digits()));

   //--- Draw Stop Loss Line
   string slName = prefix + "SL";
   double slPips = MathAbs(entryPrice - slPrice) / symbolInfo.Point() / 10;
   CreatePriceLine(slName, slPrice, SLLineColor, STYLE_DASH, 1,
                   StringFormat("SL: %.5f (%.1f pips)", slPrice, slPips));

   //--- Draw Take Profit Line
   if(tpPrice > 0)
   {
      string tpName = prefix + "TP";
      double tpPips = MathAbs(tpPrice - entryPrice) / symbolInfo.Point() / 10;
      CreatePriceLine(tpName, tpPrice, TPLineColor, STYLE_DASH, 1,
                      StringFormat("TP: %.5f (%.1f pips)", tpPrice, tpPips));
   }

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create a price line (trend line style)                           |
//+------------------------------------------------------------------+
void CreatePriceLine(string name, double price, color lineColor,
                     ENUM_LINE_STYLE style, int width, string tooltip)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_HLINE, 0, 0, price);
   else
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Remove entry/exit lines                                          |
//+------------------------------------------------------------------+
void RemoveEntryExitLines()
{
   string prefix = DashboardPrefix + "Trade_";
   ObjectsDeleteAll(0, prefix);
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update entry/exit lines for active position                      |
//+------------------------------------------------------------------+
void UpdateEntryExitLines()
{
   if(!DrawEntryExitLines)
      return;

   //--- Check if we have an open position
   bool hasPosition = false;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i))
         continue;

      if(positionInfo.Symbol() != _Symbol || positionInfo.Magic() != Magic)
         continue;

      hasPosition = true;

      double entryPrice = positionInfo.PriceOpen();
      double slPrice = positionInfo.StopLoss();
      double tpPrice = positionInfo.TakeProfit();
      int direction = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;

      DrawTradeLines(entryPrice, slPrice, tpPrice, direction);
      break; // Only draw for first position found
   }

   //--- Remove lines if no position
   if(!hasPosition)
   {
      RemoveEntryExitLines();
   }
}

//+------------------------------------------------------------------+
//| Draw trade history arrow                                         |
//+------------------------------------------------------------------+
void DrawTradeArrow(datetime time, double price, int direction, string tooltip, bool isEntry)
{
   if(!DrawTradeHistory)
      return;

   string prefix = DashboardPrefix + "Arrow_";
   string name = prefix + TimeToString(time, TIME_DATE|TIME_MINUTES) + "_" +
                 (isEntry ? "E" : "X") + "_" + IntegerToString(direction);

   //--- Determine arrow code
   int arrowCode;
   color arrowColor;

   if(isEntry)
   {
      if(direction > 0)
      {
         arrowCode = 233;  // Up arrow (buy entry)
         arrowColor = BuyArrowColor;
      }
      else
      {
         arrowCode = 234;  // Down arrow (sell entry)
         arrowColor = SellArrowColor;
      }
   }
   else // Exit
   {
      if(direction > 0)
      {
         arrowCode = 251;  // Cross mark (buy exit)
         arrowColor = BuyArrowColor;
      }
      else
      {
         arrowCode = 251;  // Cross mark (sell exit)
         arrowColor = SellArrowColor;
      }
   }

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   else
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, time);
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }

   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, arrowCode);
   ObjectSetInteger(0, name, OBJPROP_COLOR, arrowColor);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 2);
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
   if(isEntry)
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, direction > 0 ? ANCHOR_TOP : ANCHOR_BOTTOM);
   else
      ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Draw buy entry arrow                                             |
//+------------------------------------------------------------------+
void DrawBuyEntry(datetime time, double price, double lots, double sl, double tp)
{
   string tooltip = StringFormat("BUY Entry\nPrice: %.5f\nLots: %.2f\nSL: %.5f\nTP: %.5f",
                                 price, lots, sl, tp);
   DrawTradeArrow(time, price, 1, tooltip, true);
}

//+------------------------------------------------------------------+
//| Draw sell entry arrow                                            |
//+------------------------------------------------------------------+
void DrawSellEntry(datetime time, double price, double lots, double sl, double tp)
{
   string tooltip = StringFormat("SELL Entry\nPrice: %.5f\nLots: %.2f\nSL: %.5f\nTP: %.5f",
                                 price, lots, sl, tp);
   DrawTradeArrow(time, price, -1, tooltip, true);
}

//+------------------------------------------------------------------+
//| Draw trade exit arrow                                            |
//+------------------------------------------------------------------+
void DrawTradeExit(datetime time, double price, int direction, double profit, string reason)
{
   string tooltip = StringFormat("%s Exit\nPrice: %.5f\nP/L: %.2f %s\nReason: %s",
                                 direction > 0 ? "BUY" : "SELL",
                                 price, profit,
                                 AccountInfoString(ACCOUNT_CURRENCY),
                                 reason);
   DrawTradeArrow(time, price, direction, tooltip, false);
}

//+------------------------------------------------------------------+
//| Draw IB extension lines (project IB levels forward)              |
//+------------------------------------------------------------------+
void DrawIBExtensions()
{
   if(!DrawIBLevels || IBStatus < IB_COMPLETE)
      return;

   string prefix = DashboardPrefix + "IBExt_";
   datetime startTime = IBEndDateTime;
   datetime endTime = startTime + PeriodSeconds(PERIOD_D1); // Extend 1 day forward

   //--- Draw High extension
   string highExtName = prefix + "High";
   CreateTrendLine(highExtName, startTime, IBHigh, endTime, IBHigh,
                   IBHighColor, STYLE_DOT, 1, "IB High Extension");

   //--- Draw Low extension
   string lowExtName = prefix + "Low";
   CreateTrendLine(lowExtName, startTime, IBLow, endTime, IBLow,
                   IBLowColor, STYLE_DOT, 1, "IB Low Extension");

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create a trend line                                              |
//+------------------------------------------------------------------+
void CreateTrendLine(string name, datetime time1, double price1,
                     datetime time2, double price2,
                     color lineColor, ENUM_LINE_STYLE style, int width, string tooltip)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);
   else
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
   }

   ObjectSetInteger(0, name, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, true); // Extend to right
   ObjectSetString(0, name, OBJPROP_TOOLTIP, tooltip);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, false);
}

//+------------------------------------------------------------------+
//| Draw breakout marker                                             |
//+------------------------------------------------------------------+
void DrawBreakoutMarker(int direction, double price)
{
   if(!DrawIBLevels)
      return;

   string prefix = DashboardPrefix + "Breakout_";
   string name = prefix + TimeToString(TimeCurrent(), TIME_DATE);

   datetime time = TimeCurrent();

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_ARROW, 0, time, price);
   else
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, time);
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }

   //--- Use star symbol for breakout
   ObjectSetInteger(0, name, OBJPROP_ARROWCODE, 159); // Star symbol
   ObjectSetInteger(0, name, OBJPROP_COLOR, direction > 0 ? clrLime : clrRed);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 3);
   ObjectSetString(0, name, OBJPROP_TOOLTIP,
                   StringFormat("%s Breakout at %.5f",
                               direction > 0 ? "BULLISH" : "BEARISH", price));
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, direction > 0 ? ANCHOR_BOTTOM : ANCHOR_TOP);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Clean up old drawings                                            |
//+------------------------------------------------------------------+
void CleanupOldDrawings()
{
   if(DeleteOldDrawingsAfterDays <= 0)
      return;

   datetime cutoffTime = TimeCurrent() - (DeleteOldDrawingsAfterDays * PeriodSeconds(PERIOD_D1));
   string prefix = DashboardPrefix + "Arrow_";

   int totalObjects = ObjectsTotal(0, 0, -1);

   for(int i = totalObjects - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i, 0, -1);

      //--- Only clean up arrow objects
      if(StringFind(name, prefix) != 0)
         continue;

      //--- Check object time
      datetime objTime = (datetime)ObjectGetInteger(0, name, OBJPROP_TIME);

      if(objTime > 0 && objTime < cutoffTime)
      {
         ObjectDelete(0, name);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw price label on IB level                                     |
//+------------------------------------------------------------------+
void DrawIBPriceLabel(string name, double price, string text, color labelColor)
{
   datetime time = TimeCurrent();

   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TEXT, 0, time, price);
   else
   {
      ObjectSetInteger(0, name, OBJPROP_TIME, time);
      ObjectSetDouble(0, name, OBJPROP_PRICE, price);
   }

   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetInteger(0, name, OBJPROP_COLOR, labelColor);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw all IB price labels                                         |
//+------------------------------------------------------------------+
void DrawIBPriceLabels()
{
   if(!DrawIBLevels || IBStatus < IB_COMPLETE)
      return;

   string prefix = DashboardPrefix + "IBLbl_";

   //--- Draw High label
   DrawIBPriceLabel(prefix + "High", IBHigh + (10 * symbolInfo.Point()),
                    StringFormat("IB High: %.5f", IBHigh), IBHighColor);

   //--- Draw Low label
   DrawIBPriceLabel(prefix + "Low", IBLow - (10 * symbolInfo.Point()),
                    StringFormat("IB Low: %.5f", IBLow), IBLowColor);

   //--- Draw Range label
   double rangePips = IBRange / symbolInfo.Point() / 10;
   DrawIBPriceLabel(prefix + "Range", IBMidpoint,
                    StringFormat("Range: %.1f pips", rangePips), IBMidColor);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update all visual elements                                       |
//+------------------------------------------------------------------+
void UpdateVisualElements()
{
   //--- Update entry/exit lines for active position
   UpdateEntryExitLines();

   //--- Draw IB extensions if IB is complete
   if(IBStatus >= IB_COMPLETE)
   {
      DrawIBExtensions();
      DrawIBPriceLabels();
   }

   //--- Periodic cleanup of old drawings
   static datetime lastCleanupTime = 0;
   if(TimeCurrent() - lastCleanupTime > PeriodSeconds(PERIOD_H1))
   {
      CleanupOldDrawings();
      lastCleanupTime = TimeCurrent();
   }
}

//+------------------------------------------------------------------+
//| Remove all visual elements                                       |
//+------------------------------------------------------------------+
void RemoveAllVisualElements()
{
   RemoveIBLines();
   RemoveEntryExitLines();
   ObjectsDeleteAll(0, DashboardPrefix + "IBExt_");
   ObjectsDeleteAll(0, DashboardPrefix + "IBLbl_");
   ObjectsDeleteAll(0, DashboardPrefix + "Arrow_");
   ObjectsDeleteAll(0, DashboardPrefix + "Breakout_");
   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Check if we should reset IB for new day                          |
//+------------------------------------------------------------------+
void CheckIBDailyReset()
{
   //--- Get current date
   MqlDateTime currentDT;
   TimeToStruct(TimeCurrent(), currentDT);

   //--- Get last trade date
   MqlDateTime lastDT;
   TimeToStruct(LastTradeDate, lastDT);

   //--- Check if it's a new trading day
   if(currentDT.day != lastDT.day ||
      currentDT.mon != lastDT.mon ||
      currentDT.year != lastDT.year)
   {
      //--- Check if we're past reset time for today
      if(TimeCurrent() > IBStartDateTime - 300) // 5 minutes before IB start
      {
         if(EnableDebugMode) Print("New trading day detected - resetting IB");

         //--- Reset all daily counters
         ResetDailyCounters();

         //--- Reset IB for new day
         InitializeIB();
         LastTradeDate = TimeCurrent();
      }
   }
}

//+------------------------------------------------------------------+
//| Check if IB needs recalculation after timezone change            |
//+------------------------------------------------------------------+
void CheckIBTimezoneUpdate()
{
   //--- Recalculate IB times if DST status changed
   static bool lastLondonDST = false;
   static bool lastNYDST = false;

   if(lastLondonDST != IsLondonDST || lastNYDST != IsNewYorkDST)
   {
      lastLondonDST = IsLondonDST;
      lastNYDST = IsNewYorkDST;

      //--- Recalculate times if IB not yet formed
      if(IBStatus <= IB_WAITING)
      {
         CalculateIBTimes();
         if(EnableDebugMode) Print("IB times recalculated due to DST change");
      }
   }
}

//+------------------------------------------------------------------+
//| Validate IB levels                                               |
//+------------------------------------------------------------------+
bool ValidateIBLevels()
{
   if(IBHigh <= 0 || IBLow <= 0)
   {
      Print("Error: Invalid IB levels (zero or negative)");
      return false;
   }

   if(IBHigh <= IBLow)
   {
      Print("Error: IB High <= IB Low");
      return false;
   }

   double rangePips = IBRange / PipValue;

   //--- Check for abnormally small range (might indicate data issue)
   if(rangePips < 1.0)
   {
      Print("Warning: IB Range abnormally small: ", rangePips, " pips");
      return false;
   }

   //--- Check for abnormally large range
   double atr = GetATRValue();
   if(atr > 0 && IBRange > atr * 5)
   {
      Print("Warning: IB Range abnormally large: ", rangePips, " pips (>5x ATR)");
      // Still allow, but log warning
   }

   return true;
}

//+------------------------------------------------------------------+
//| IsNewBar - Check if new bar has formed                           |
//+------------------------------------------------------------------+
bool IsNewBar()
{
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);

   if(currentBarTime != lastBarTime)
   {
      lastBarTime = currentBarTime;
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                 ENTRY SIGNAL LOGIC                               |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Unified entry signal processing - called once per tick          |
//| Determines whether to check signals based on mode and events    |
//| Uses global CurrentTickIsNewBar flag set in OnTick()            |
//+------------------------------------------------------------------+
void ProcessEntrySignals()
{
   //--- Determine if we should check for signals this tick
   bool shouldCheckSignals = false;
   string triggerReason = "";

   //--- Get the appropriate breakout flag and status based on strategy
   bool breakoutJustOccurred = (RangeStrategy == STRATEGY_SETTLEMENT) ?
                                SettlementBreakoutJustOccurred : BreakoutJustOccurred;
   bool rangeBroken = (RangeStrategy == STRATEGY_SETTLEMENT) ?
                       (SettlementStatus == SETTLE_BROKEN_UP || SettlementStatus == SETTLE_BROKEN_DOWN) :
                       (IBStatus == IB_BROKEN_UP || IBStatus == IB_BROKEN_DOWN);

   switch(EntryMode)
   {
      case MODE_BREAKOUT:
         //--- Breakout mode: Check on breakout event OR new bar (for retest/confirmation)
         if(breakoutJustOccurred)
         {
            shouldCheckSignals = true;
            triggerReason = "Breakout Event";
         }
         else if(CurrentTickIsNewBar && rangeBroken)
         {
            //--- Also check on new bars if waiting for confirmation/retest
            if(RequireRetestForBreakout || ConfirmCandle != CONFIRM_NONE)
            {
               shouldCheckSignals = true;
               triggerReason = "New Bar (Confirmation)";
            }
         }
         break;

      case MODE_FADE:
         //--- Fade mode: Only check on new bars (needs candle confirmation)
         if(CurrentTickIsNewBar && rangeBroken)
         {
            shouldCheckSignals = true;
            triggerReason = "New Bar (Fade)";
         }
         break;

      case MODE_HYBRID:
         //--- Hybrid mode: Check on breakout for initial trade, new bar for fade
         if(breakoutJustOccurred)
         {
            shouldCheckSignals = true;
            triggerReason = "Breakout Event (Hybrid)";
         }
         else if(CurrentTickIsNewBar && rangeBroken)
         {
            shouldCheckSignals = true;
            triggerReason = "New Bar (Hybrid)";
         }
         break;
   }

   //--- Clear the breakout flag after processing (for both strategies)
   BreakoutJustOccurred = false;
   SettlementBreakoutJustOccurred = false;

   //--- Exit if no signal check needed
   if(!shouldCheckSignals)
      return;

   //--- Debug logging
   if(EnableDebugMode)
      PrintFormat(">>> Signal check triggered: %s [%s]", triggerReason,
                  RangeStrategy == STRATEGY_SETTLEMENT ? "Settlement" : "IB");

   //--- Check preconditions with debug output (use unified function)
   if(!IsRangeReadyForTrading())
   {
      if(EnableDebugMode) Print(">>> BLOCKED by IsRangeReadyForTrading()");
      return;
   }

   if(!CanOpenNewTrade())
   {
      // CanOpenNewTrade already has its own logging
      return;
   }

   if(!CheckAllFilters())
   {
      // CheckAllFilters already has its own logging
      return;
   }

   //--- Generate signal based on entry mode and range strategy
   int signal = 0;

   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      //--- Settlement strategy signal generation
      switch(EntryMode)
      {
         case MODE_BREAKOUT:
            signal = CheckSettlementBreakoutSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckSettlementBreakoutSignal returned 0");
            break;

         case MODE_FADE:
            signal = CheckSettlementFadeSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckSettlementFadeSignal returned 0");
            break;

         case MODE_HYBRID:
            signal = CheckSettlementHybridSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckSettlementHybridSignal returned 0");
            break;
      }
   }
   else
   {
      //--- IB strategy signal generation (original logic)
      switch(EntryMode)
      {
         case MODE_BREAKOUT:
            signal = CheckBreakoutSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckBreakoutSignal returned 0");
            break;

         case MODE_FADE:
            signal = CheckFadeSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckFadeSignal returned 0");
            break;

         case MODE_HYBRID:
            signal = CheckHybridSignal();
            if(EnableDebugMode && signal == 0) Print(">>> CheckHybridSignal returned 0");
            break;
      }
   }

   //--- Execute trade if we have a valid signal
   if(signal != 0)
   {
      if(EnableDebugMode)
         PrintFormat(">>> SIGNAL: %s | Mode: %s | Strategy: %s",
                     signal > 0 ? "BUY" : "SELL",
                     EnumToString(EntryMode),
                     RangeStrategy == STRATEGY_SETTLEMENT ? "Settlement" : "IB");

      //--- Final directional filter check
      if(!CheckFiltersForDirection(signal))
      {
         if(EnableDebugMode) Print("Signal rejected by directional filter");
         return;
      }

      //--- Execute the trade
      ExecuteSignal(signal);
   }
}

//+------------------------------------------------------------------+
//| Check if we can open a new trade                                 |
//+------------------------------------------------------------------+
bool CanOpenNewTrade()
{
   //--- Static tracking for log spam prevention
   static string lastBlockReason = "";
   string currentReason = "";

   //--- Check EA status
   if(EAStatus != EA_RUNNING)
   {
      currentReason = "EA not running";
      if(EnableDebugMode && currentReason != lastBlockReason) Print(currentReason);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check trade allowed flag
   if(!TradeAllowed)
   {
      currentReason = "Trading not allowed";
      if(EnableDebugMode && currentReason != lastBlockReason) Print(currentReason);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check max trades per day
   if(MaxTradesPerDay > 0 && TodayTradeCount >= MaxTradesPerDay)
   {
      currentReason = "Max trades per day reached";
      if(EnableDebugMode && currentReason != lastBlockReason) PrintFormat("%s: %d", currentReason, TodayTradeCount);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check max consecutive losses
   if(MaxLosingTradesPerDay > 0 && ConsecutiveLosses >= MaxLosingTradesPerDay)
   {
      currentReason = "Max consecutive losses reached";
      if(EnableDebugMode && currentReason != lastBlockReason) PrintFormat("%s: %d", currentReason, ConsecutiveLosses);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check max open positions
   int currentPositions = CountOpenPositions();
   if(MaxOpenPositions > 0 && currentPositions >= MaxOpenPositions)
   {
      currentReason = "Max open positions reached";
      if(EnableDebugMode && currentReason != lastBlockReason) PrintFormat("%s: %d", currentReason, currentPositions);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check one trade per IB
   if(OneTradePerIB && HasTradedThisIB())
   {
      currentReason = "Already traded this IB session";
      if(EnableDebugMode && currentReason != lastBlockReason) Print(currentReason);
      lastBlockReason = currentReason;
      return false;
   }

   //--- Check re-entry attempts
   if(!AllowReEntry && HasBeenStoppedOutThisIB())
   {
      currentReason = "Re-entry not allowed after stop out";
      if(EnableDebugMode && currentReason != lastBlockReason) Print(currentReason);
      lastBlockReason = currentReason;
      return false;
   }

   if(AllowReEntry && ReEntryAttempts >= ReEntryMaxAttempts)
   {
      currentReason = "Max re-entry attempts reached";
      if(EnableDebugMode && currentReason != lastBlockReason) PrintFormat("%s: %d", currentReason, ReEntryAttempts);
      lastBlockReason = currentReason;
      return false;
   }

   //--- All checks passed, reset block reason
   lastBlockReason = "";
   return true;
}

//+------------------------------------------------------------------+
//| Count open positions for this EA                                 |
//+------------------------------------------------------------------+
int CountOpenPositions()
{
   int count = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == Magic)
         {
            count++;
         }
      }
   }

   return count;
}

//+------------------------------------------------------------------+
//| Check if we've traded this IB session                            |
//+------------------------------------------------------------------+
bool HasTradedThisIB()
{
   //--- Check if last entry was during current IB period
   if(LastEntryTime >= IBStartDateTime)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check if we've been stopped out this IB                          |
//+------------------------------------------------------------------+
bool HasBeenStoppedOutThisIB()
{
   //--- This would check trade history for stop-out during current IB
   //--- For now, use re-entry attempts counter
   return (ReEntryAttempts > 0);
}

//+------------------------------------------------------------------+
//| BREAKOUT SIGNAL LOGIC                                            |
//+------------------------------------------------------------------+
int CheckBreakoutSignal()
{
   //--- Need IB to be broken
   if(IBStatus != IB_BROKEN_UP && IBStatus != IB_BROKEN_DOWN)
      return 0;

   //--- Check breakout distance is valid
   if(!IsBreakoutDistanceValid())
      return 0;

   //--- Check if retest is required
   if(RequireRetestForBreakout && !BreakoutRetested)
   {
      if(EnableDebugMode) Print("Waiting for retest");
      return 0;
   }

   //--- Check confirmation candle if required
   if(ConfirmCandle != CONFIRM_NONE)
   {
      if(!CheckConfirmationCandle(IBStatus == IB_BROKEN_UP ? 1 : -1))
      {
         if(EnableDebugMode) Print("Waiting for confirmation candle");
         return 0;
      }
   }

   //--- Generate signal based on breakout direction
   if(IBStatus == IB_BROKEN_UP)
   {
      return 1;  // Buy signal
   }
   else if(IBStatus == IB_BROKEN_DOWN)
   {
      return -1; // Sell signal
   }

   return 0;
}

//+------------------------------------------------------------------+
//| FADE (REVERSAL) SIGNAL LOGIC                                     |
//+------------------------------------------------------------------+
int CheckFadeSignal()
{
   //--- Need IB to be broken first
   if(IBStatus != IB_BROKEN_UP && IBStatus != IB_BROKEN_DOWN)
      return 0;

   double bid = symbolInfo.Bid();

   //--- Fade signal: Price broke out but came back inside IB
   if(IBStatus == IB_BROKEN_UP)
   {
      //--- Price broke up but came back inside - SHORT fade
      if(bid < IBHigh && bid > IBLow)
      {
         //--- Check for confirmation candles back inside
         if(FadeConfirmCandles > 0)
         {
            if(!CheckFadeConfirmation(-1))
               return 0;
         }

         //--- Check confirmation candle pattern
         if(ConfirmCandle != CONFIRM_NONE)
         {
            if(!CheckConfirmationCandle(-1))
               return 0;
         }

         return -1; // Sell signal (fade the upward break)
      }
   }
   else if(IBStatus == IB_BROKEN_DOWN)
   {
      //--- Price broke down but came back inside - LONG fade
      if(bid > IBLow && bid < IBHigh)
      {
         //--- Check for confirmation candles back inside
         if(FadeConfirmCandles > 0)
         {
            if(!CheckFadeConfirmation(1))
               return 0;
         }

         //--- Check confirmation candle pattern
         if(ConfirmCandle != CONFIRM_NONE)
         {
            if(!CheckConfirmationCandle(1))
               return 0;
         }

         return 1; // Buy signal (fade the downward break)
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Check fade confirmation (candles back inside IB)                 |
//+------------------------------------------------------------------+
bool CheckFadeConfirmation(int direction)
{
   int candlesInside = 0;

   //--- Count candles that have closed back inside IB
   for(int i = 1; i <= FadeConfirmCandles + 2; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      if(closePrice > IBLow && closePrice < IBHigh)
      {
         candlesInside++;
      }
      else
      {
         break; // Break on first candle outside
      }

      if(candlesInside >= FadeConfirmCandles)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| HYBRID SIGNAL LOGIC                                              |
//+------------------------------------------------------------------+
int CheckHybridSignal()
{
   //--- Hybrid mode: Determine if breakout is holding or failing

   //--- Need IB to be broken
   if(IBStatus != IB_BROKEN_UP && IBStatus != IB_BROKEN_DOWN)
      return 0;

   //--- Wait for enough candles to evaluate
   if(CandlesSinceBreak < HybridHoldCandles)
      return 0;

   double bid = symbolInfo.Bid();

   if(IBStatus == IB_BROKEN_UP)
   {
      //--- Check if breakout is holding (price still above IB)
      if(bid > IBHigh)
      {
         //--- Breakout holding - trade breakout direction
         if(IsBreakoutHolding(1))
         {
            if(EnableDebugMode) Print("Hybrid: Breakout holding - BUY");
            return 1;
         }
      }
      else if(bid < IBHigh && bid > IBLow)
      {
         //--- Breakout failing - trade fade direction
         if(IsBreakoutFailing(1))
         {
            if(EnableDebugMode) Print("Hybrid: Breakout failing - SELL (fade)");
            return -1;
         }
      }
   }
   else if(IBStatus == IB_BROKEN_DOWN)
   {
      //--- Check if breakout is holding (price still below IB)
      if(bid < IBLow)
      {
         //--- Breakout holding - trade breakout direction
         if(IsBreakoutHolding(-1))
         {
            if(EnableDebugMode) Print("Hybrid: Breakout holding - SELL");
            return -1;
         }
      }
      else if(bid > IBLow && bid < IBHigh)
      {
         //--- Breakout failing - trade fade direction
         if(IsBreakoutFailing(-1))
         {
            if(EnableDebugMode) Print("Hybrid: Breakout failing - BUY (fade)");
            return 1;
         }
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Check if breakout is holding                                     |
//+------------------------------------------------------------------+
bool IsBreakoutHolding(int direction)
{
   //--- Check recent candles to confirm breakout strength

   int holdingCandles = 0;

   for(int i = 1; i <= HybridHoldCandles; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      if(direction > 0) // Upward breakout
      {
         if(closePrice > IBHigh)
            holdingCandles++;
      }
      else // Downward breakout
      {
         if(closePrice < IBLow)
            holdingCandles++;
      }
   }

   //--- Breakout holding if majority of candles stayed outside IB
   return (holdingCandles >= (HybridHoldCandles * 2 / 3));
}

//+------------------------------------------------------------------+
//| Check if breakout is failing                                     |
//+------------------------------------------------------------------+
bool IsBreakoutFailing(int direction)
{
   //--- Check if price is rejecting and coming back inside

   int failingCandles = 0;

   for(int i = 1; i <= HybridHoldCandles; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      //--- Count candles closing inside IB
      if(closePrice > IBLow && closePrice < IBHigh)
         failingCandles++;
   }

   //--- Breakout failing if majority of candles are back inside
   return (failingCandles >= (HybridHoldCandles * 2 / 3));
}

//+------------------------------------------------------------------+
//| Check confirmation candle pattern                                |
//+------------------------------------------------------------------+
bool CheckConfirmationCandle(int direction)
{
   switch(ConfirmCandle)
   {
      case CONFIRM_ENGULFING:
         return IsEngulfingPattern(direction);

      case CONFIRM_PINBAR:
         return IsPinBarPattern(direction);

      case CONFIRM_INSIDE:
         return IsInsideBarBreakout(direction);

      case CONFIRM_ANY:
         return (IsEngulfingPattern(direction) ||
                 IsPinBarPattern(direction) ||
                 IsInsideBarBreakout(direction));

      default:
         return true;
   }
}

//+------------------------------------------------------------------+
//| Check for engulfing pattern                                      |
//+------------------------------------------------------------------+
bool IsEngulfingPattern(int direction)
{
   //--- Get last two bars
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double open2 = iOpen(_Symbol, PERIOD_CURRENT, 2);
   double close2 = iClose(_Symbol, PERIOD_CURRENT, 2);

   if(direction > 0) // Bullish engulfing
   {
      //--- Previous bar bearish, current bar bullish and engulfs
      bool prevBearish = close2 < open2;
      bool currBullish = close1 > open1;
      bool engulfs = close1 > open2 && open1 < close2;

      return (prevBearish && currBullish && engulfs);
   }
   else // Bearish engulfing
   {
      //--- Previous bar bullish, current bar bearish and engulfs
      bool prevBullish = close2 > open2;
      bool currBearish = close1 < open1;
      bool engulfs = close1 < open2 && open1 > close2;

      return (prevBullish && currBearish && engulfs);
   }
}

//+------------------------------------------------------------------+
//| Check for pin bar pattern                                        |
//+------------------------------------------------------------------+
bool IsPinBarPattern(int direction)
{
   //--- Get last bar data
   double open1 = iOpen(_Symbol, PERIOD_CURRENT, 1);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);

   double body = MathAbs(close1 - open1);
   double range = high1 - low1;

   if(range == 0) return false;

   double upperWick = high1 - MathMax(open1, close1);
   double lowerWick = MathMin(open1, close1) - low1;

   //--- Pin bar: small body, one wick at least 2x the body
   bool smallBody = body < range * 0.35;

   if(direction > 0) // Bullish pin bar (hammer)
   {
      //--- Long lower wick, small upper wick
      return (smallBody && lowerWick > body * 2 && upperWick < body);
   }
   else // Bearish pin bar (shooting star)
   {
      //--- Long upper wick, small lower wick
      return (smallBody && upperWick > body * 2 && lowerWick < body);
   }
}

//+------------------------------------------------------------------+
//| Check for inside bar breakout                                    |
//+------------------------------------------------------------------+
bool IsInsideBarBreakout(int direction)
{
   //--- Get bar data
   double high1 = iHigh(_Symbol, PERIOD_CURRENT, 1);
   double low1 = iLow(_Symbol, PERIOD_CURRENT, 1);
   double high2 = iHigh(_Symbol, PERIOD_CURRENT, 2);
   double low2 = iLow(_Symbol, PERIOD_CURRENT, 2);
   double close1 = iClose(_Symbol, PERIOD_CURRENT, 1);

   //--- Bar 2 is mother bar, bar 1 should have been inside
   bool wasInside = (high1 < high2 && low1 > low2);

   if(!wasInside) return false;

   //--- Now check if current price broke the inside bar
   double bid = symbolInfo.Bid();

   if(direction > 0)
   {
      return (bid > high1 || close1 > high2);
   }
   else
   {
      return (bid < low1 || close1 < low2);
   }
}

//+------------------------------------------------------------------+
//|                   SETTLEMENT SIGNAL FUNCTIONS                    |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| SETTLEMENT BREAKOUT SIGNAL LOGIC                                 |
//+------------------------------------------------------------------+
int CheckSettlementBreakoutSignal()
{
   //--- Need Settlement to be broken
   if(SettlementStatus != SETTLE_BROKEN_UP && SettlementStatus != SETTLE_BROKEN_DOWN)
      return 0;

   //--- Check breakout distance is valid
   if(!IsSettlementBreakoutDistanceValid())
      return 0;

   //--- Check if retest is required
   if(RequireRetestForBreakout && !SettlementRetested)
   {
      if(EnableDebugMode) Print("Settlement: Waiting for retest");
      return 0;
   }

   //--- Check confirmation candle if required
   if(ConfirmCandle != CONFIRM_NONE)
   {
      if(!CheckConfirmationCandle(SettlementStatus == SETTLE_BROKEN_UP ? 1 : -1))
      {
         if(EnableDebugMode) Print("Settlement: Waiting for confirmation candle");
         return 0;
      }
   }

   //--- Generate signal based on breakout direction
   if(SettlementStatus == SETTLE_BROKEN_UP)
   {
      return 1;  // Buy signal
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN)
   {
      return -1; // Sell signal
   }

   return 0;
}

//+------------------------------------------------------------------+
//| SETTLEMENT FADE (REVERSAL) SIGNAL LOGIC                          |
//+------------------------------------------------------------------+
int CheckSettlementFadeSignal()
{
   //--- Need Settlement to be broken first
   if(SettlementStatus != SETTLE_BROKEN_UP && SettlementStatus != SETTLE_BROKEN_DOWN)
      return 0;

   double bid = symbolInfo.Bid();

   //--- Fade signal: Price broke out but came back inside Settlement range
   if(SettlementStatus == SETTLE_BROKEN_UP)
   {
      //--- Price broke up but came back inside - SHORT fade
      if(bid < SettlementHigh && bid > SettlementLow)
      {
         //--- Check for confirmation candles back inside
         if(FadeConfirmCandles > 0)
         {
            if(!CheckSettlementFadeConfirmation(-1))
               return 0;
         }

         //--- Check confirmation candle pattern
         if(ConfirmCandle != CONFIRM_NONE)
         {
            if(!CheckConfirmationCandle(-1))
               return 0;
         }

         return -1; // Sell signal (fade the upward break)
      }
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN)
   {
      //--- Price broke down but came back inside - LONG fade
      if(bid > SettlementLow && bid < SettlementHigh)
      {
         //--- Check for confirmation candles back inside
         if(FadeConfirmCandles > 0)
         {
            if(!CheckSettlementFadeConfirmation(1))
               return 0;
         }

         //--- Check confirmation candle pattern
         if(ConfirmCandle != CONFIRM_NONE)
         {
            if(!CheckConfirmationCandle(1))
               return 0;
         }

         return 1; // Buy signal (fade the downward break)
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Check Settlement fade confirmation (candles back inside)          |
//+------------------------------------------------------------------+
bool CheckSettlementFadeConfirmation(int direction)
{
   int candlesInside = 0;

   //--- Count candles that have closed back inside Settlement range
   for(int i = 1; i <= FadeConfirmCandles + 2; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      if(closePrice > SettlementLow && closePrice < SettlementHigh)
      {
         candlesInside++;
      }
      else
      {
         break; // Break on first candle outside
      }

      if(candlesInside >= FadeConfirmCandles)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| SETTLEMENT HYBRID SIGNAL LOGIC                                   |
//+------------------------------------------------------------------+
int CheckSettlementHybridSignal()
{
   //--- Hybrid mode: Determine if breakout is holding or failing

   //--- Need Settlement to be broken
   if(SettlementStatus != SETTLE_BROKEN_UP && SettlementStatus != SETTLE_BROKEN_DOWN)
      return 0;

   //--- Wait for enough candles to evaluate
   if(SettlementCandlesSinceBreak < HybridHoldCandles)
      return 0;

   double bid = symbolInfo.Bid();

   if(SettlementStatus == SETTLE_BROKEN_UP)
   {
      //--- Check if breakout is holding (price still above Settlement)
      if(bid > SettlementHigh)
      {
         //--- Breakout holding - trade breakout direction
         if(IsSettlementBreakoutHolding(1))
         {
            if(EnableDebugMode) Print("Settlement Hybrid: Breakout holding - BUY");
            return 1;
         }
      }
      else if(bid < SettlementHigh && bid > SettlementLow)
      {
         //--- Breakout failing - trade fade direction
         if(IsSettlementBreakoutFailing(1))
         {
            if(EnableDebugMode) Print("Settlement Hybrid: Breakout failing - SELL (fade)");
            return -1;
         }
      }
   }
   else if(SettlementStatus == SETTLE_BROKEN_DOWN)
   {
      //--- Check if breakout is holding (price still below Settlement)
      if(bid < SettlementLow)
      {
         //--- Breakout holding - trade breakout direction
         if(IsSettlementBreakoutHolding(-1))
         {
            if(EnableDebugMode) Print("Settlement Hybrid: Breakout holding - SELL");
            return -1;
         }
      }
      else if(bid > SettlementLow && bid < SettlementHigh)
      {
         //--- Breakout failing - trade fade direction
         if(IsSettlementBreakoutFailing(-1))
         {
            if(EnableDebugMode) Print("Settlement Hybrid: Breakout failing - BUY (fade)");
            return 1;
         }
      }
   }

   return 0;
}

//+------------------------------------------------------------------+
//| Check if Settlement breakout is holding                           |
//+------------------------------------------------------------------+
bool IsSettlementBreakoutHolding(int direction)
{
   //--- Check recent candles to confirm breakout strength
   int holdingCandles = 0;

   for(int i = 1; i <= HybridHoldCandles; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      if(direction > 0) // Upward breakout
      {
         if(closePrice > SettlementHigh)
            holdingCandles++;
      }
      else // Downward breakout
      {
         if(closePrice < SettlementLow)
            holdingCandles++;
      }
   }

   //--- Breakout holding if majority of candles stayed outside Settlement
   return (holdingCandles >= (HybridHoldCandles * 2 / 3));
}

//+------------------------------------------------------------------+
//| Check if Settlement breakout is failing                           |
//+------------------------------------------------------------------+
bool IsSettlementBreakoutFailing(int direction)
{
   //--- Check if price is rejecting and coming back inside
   int failingCandles = 0;

   for(int i = 1; i <= HybridHoldCandles; i++)
   {
      double closePrice = iClose(_Symbol, PERIOD_CURRENT, i);

      //--- Count candles closing inside Settlement range
      if(closePrice > SettlementLow && closePrice < SettlementHigh)
         failingCandles++;
   }

   //--- Breakout failing if majority of candles are back inside
   return (failingCandles >= (HybridHoldCandles * 2 / 3));
}

//+------------------------------------------------------------------+
//| Execute trade signal                                             |
//+------------------------------------------------------------------+
void ExecuteSignal(int direction)
{
   //--- Calculate entry price
   double entryPrice;
   if(direction > 0)
      entryPrice = symbolInfo.Ask();
   else
      entryPrice = symbolInfo.Bid();

   //--- Calculate SL
   double slDistance = 0;
   double slPrice;
   if(direction > 0)
      slPrice = CalculateBuySL(entryPrice, slDistance);
   else
      slPrice = CalculateSellSL(entryPrice, slDistance);

   //--- Validate SL distance
   if(slDistance <= 0)
   {
      Print("Error: Invalid SL distance");
      return;
   }

   //--- Calculate lot size
   double lotSize = CalculateLotSize(slDistance);
   if(lotSize <= 0)
   {
      Print("Error: Invalid lot size calculated");
      return;
   }

   //--- Calculate TP
   double tpDistance = 0;
   double tpPrice;

   if(UseMultipleTPs)
   {
      //--- When using MultiTP, set broker TP to TP3 level (final target)
      tpDistance = slDistance * TP3RRRatio;
      if(direction > 0)
         tpPrice = NormalizeDouble(entryPrice + tpDistance, SymbolDigits);
      else
         tpPrice = NormalizeDouble(entryPrice - tpDistance, SymbolDigits);
   }
   else
   {
      //--- Standard single TP calculation
      if(direction > 0)
         tpPrice = CalculateBuyTP(entryPrice, slDistance, tpDistance);
      else
         tpPrice = CalculateSellTP(entryPrice, slDistance, tpDistance);
   }

   //--- Validate stops against broker limits
   if(!ValidateStopsDistance(entryPrice, slPrice, tpPrice, direction))
   {
      Print("Error: Stops too close to entry price");
      return;
   }

   //--- Build trade comment
   string comment = StringFormat("%s_%s", TradeComment, EnumToString(EntryMode));

   //--- Execute the trade
   bool result = false;

   if(direction > 0)
   {
      result = trade.Buy(lotSize, _Symbol, entryPrice, slPrice, tpPrice, comment);
   }
   else
   {
      result = trade.Sell(lotSize, _Symbol, entryPrice, slPrice, tpPrice, comment);
   }

   //--- Handle result
   if(result)
   {
      ulong ticket = trade.ResultOrder();

      Print("═══════════════════════════════════════════════════════════════");
      PrintFormat("TRADE OPENED: %s | Ticket: %d", direction > 0 ? "BUY" : "SELL", ticket);
      PrintFormat("Entry: %.5f | SL: %.5f | TP: %.5f", entryPrice, slPrice, tpPrice);
      PrintFormat("Lot: %.2f | Risk: %s", lotSize, GetRiskInfoString(lotSize, slDistance));

      if(UseMultipleTPs)
      {
         double tp1Lvl = (direction > 0) ? entryPrice + (slDistance * TP1RRRatio) : entryPrice - (slDistance * TP1RRRatio);
         double tp2Lvl = (direction > 0) ? entryPrice + (slDistance * TP2RRRatio) : entryPrice - (slDistance * TP2RRRatio);
         PrintFormat("MultiTP: TP1=%.5f (%.0f%%) | TP2=%.5f (%.0f%%) | TP3=%.5f (%.0f%%)",
                     tp1Lvl, TP1Percent, tp2Lvl, TP2Percent, tpPrice, 100.0 - TP1Percent - TP2Percent);
      }

      Print("═══════════════════════════════════════════════════════════════");

      //--- Update tracking variables
      LastEntryTime = TimeCurrent();
      TodayTradeCount++;
      SignalDirection = direction;
      SignalEntryPrice = entryPrice;
      SignalSL = slPrice;
      SignalTP = tpPrice;

      //--- Register position for tracking (R:R calculations, trailing, etc.)
      RegisterPositionForTracking(ticket, entryPrice, slPrice, direction, lotSize);

      //--- Store for multiple TPs if enabled
      if(UseMultipleTPs)
      {
         StoreTradeForMultipleTPs(ticket, entryPrice, slPrice, slDistance, direction);
      }

      //--- Send Trade Entry alert
      AlertTradeEntry(direction, entryPrice, slPrice, tpPrice, lotSize);

      //--- Draw trade entry arrow
      if(direction > 0)
         DrawBuyEntry(TimeCurrent(), entryPrice, lotSize, slPrice, tpPrice);
      else
         DrawSellEntry(TimeCurrent(), entryPrice, lotSize, slPrice, tpPrice);
   }
   else
   {
      PrintFormat("Trade FAILED: %s | Error: %d - %s",
                  direction > 0 ? "BUY" : "SELL",
                  trade.ResultRetcode(),
                  trade.ResultRetcodeDescription());

      //--- Send Error alert
      AlertError(StringFormat("Trade execution failed: %s", trade.ResultRetcodeDescription()),
                 (int)trade.ResultRetcode());
   }
}

//+------------------------------------------------------------------+
//| Validate stops distance from entry                               |
//+------------------------------------------------------------------+
bool ValidateStopsDistance(double entryPrice, double slPrice, double tpPrice, int direction)
{
   //--- Get broker's minimum stops level
   int stopsLevel = (int)SymbolInfoInteger(_Symbol, SYMBOL_TRADE_STOPS_LEVEL);
   double minDistance = stopsLevel * PointValue;

   //--- Add buffer
   minDistance = MathMax(minDistance, 5 * PipValue); // At least 5 pips

   //--- Check SL distance
   double slDistance = MathAbs(entryPrice - slPrice);
   if(slDistance < minDistance)
   {
      PrintFormat("SL too close: %.5f < min %.5f", slDistance, minDistance);
      return false;
   }

   //--- Check TP distance (if TP is set)
   if(tpPrice > 0)
   {
      double tpDist = MathAbs(tpPrice - entryPrice);
      if(tpDist < minDistance)
      {
         PrintFormat("TP too close: %.5f < min %.5f", tpDist, minDistance);
         return false;
      }
   }

   return true;
}

//+------------------------------------------------------------------+
//| Register a new position for Multiple TP tracking                  |
//+------------------------------------------------------------------+
void RegisterPositionForMultiTP(ulong ticket, double entry, double sl, double slDistance, int direction, double lots)
{
   //--- Validate inputs
   if(ticket == 0 || slDistance <= 0 || lots <= 0)
      return;

   //--- Check if already registered
   for(int i = 0; i < MultiTPCount; i++)
   {
      if(MultiTPPositions[i].ticket == ticket)
         return; // Already tracked
   }

   //--- Resize array
   ArrayResize(MultiTPPositions, MultiTPCount + 1);

   //--- Calculate TP levels
   double tp1Distance = slDistance * TP1RRRatio;
   double tp2Distance = slDistance * TP2RRRatio;
   double tp3Distance = slDistance * TP3RRRatio;

   //--- Calculate lot distribution based on percentages
   double tp3Percent = 100.0 - TP1Percent - TP2Percent;
   if(tp3Percent < 0) tp3Percent = 0;

   double tp1Lots = NormalizeLots(lots * (TP1Percent / 100.0));
   double tp2Lots = NormalizeLots(lots * (TP2Percent / 100.0));
   double tp3Lots = NormalizeLots(lots - tp1Lots - tp2Lots);

   //--- Ensure we have at least minimum lot for remaining
   if(tp3Lots < MinLot && tp3Lots > 0)
   {
      //--- Adjust TP2 lots to ensure TP3 has at least min lot
      if(tp2Lots > MinLot)
      {
         tp2Lots = NormalizeLots(tp2Lots - (MinLot - tp3Lots));
         tp3Lots = MinLot;
      }
   }

   //--- Store the position info
   MultiTPPositions[MultiTPCount].ticket = ticket;
   MultiTPPositions[MultiTPCount].entryPrice = entry;
   MultiTPPositions[MultiTPCount].originalSL = sl;
   MultiTPPositions[MultiTPCount].slDistance = slDistance;
   MultiTPPositions[MultiTPCount].originalLots = lots;
   MultiTPPositions[MultiTPCount].direction = direction;
   MultiTPPositions[MultiTPCount].entryTime = TimeCurrent();

   //--- Set TP levels
   if(direction > 0) // BUY
   {
      MultiTPPositions[MultiTPCount].tp1Level = NormalizeDouble(entry + tp1Distance, SymbolDigits);
      MultiTPPositions[MultiTPCount].tp2Level = NormalizeDouble(entry + tp2Distance, SymbolDigits);
      MultiTPPositions[MultiTPCount].tp3Level = NormalizeDouble(entry + tp3Distance, SymbolDigits);
   }
   else // SELL
   {
      MultiTPPositions[MultiTPCount].tp1Level = NormalizeDouble(entry - tp1Distance, SymbolDigits);
      MultiTPPositions[MultiTPCount].tp2Level = NormalizeDouble(entry - tp2Distance, SymbolDigits);
      MultiTPPositions[MultiTPCount].tp3Level = NormalizeDouble(entry - tp3Distance, SymbolDigits);
   }

   //--- Set lot allocations
   MultiTPPositions[MultiTPCount].tp1Lots = tp1Lots;
   MultiTPPositions[MultiTPCount].tp2Lots = tp2Lots;
   MultiTPPositions[MultiTPCount].tp3Lots = tp3Lots;

   //--- Initialize flags
   MultiTPPositions[MultiTPCount].tp1Hit = false;
   MultiTPPositions[MultiTPCount].tp2Hit = false;
   MultiTPPositions[MultiTPCount].beMovedAfterTP1 = false;

   MultiTPCount++;

   //--- Log registration
   if(EnableDebugMode)
   {
      PrintFormat("═══ MultiTP Registered: Ticket #%d ═══", ticket);
      PrintFormat("  Entry: %.5f | SL: %.5f | Direction: %s",
                  entry, sl, direction > 0 ? "BUY" : "SELL");
      PrintFormat("  TP1: %.5f (%.1f%% = %.2f lots) @ %.1fR",
                  MultiTPPositions[MultiTPCount-1].tp1Level, TP1Percent, tp1Lots, TP1RRRatio);
      PrintFormat("  TP2: %.5f (%.1f%% = %.2f lots) @ %.1fR",
                  MultiTPPositions[MultiTPCount-1].tp2Level, TP2Percent, tp2Lots, TP2RRRatio);
      PrintFormat("  TP3: %.5f (%.1f%% = %.2f lots) @ %.1fR",
                  MultiTPPositions[MultiTPCount-1].tp3Level, tp3Percent, tp3Lots, TP3RRRatio);
   }
}

//+------------------------------------------------------------------+
//| Normalize lots to valid lot size                                  |
//+------------------------------------------------------------------+
double NormalizeLots(double lots)
{
   double step = symbolInfo.LotsStep();
   double minLot = symbolInfo.LotsMin();
   double maxLot = symbolInfo.LotsMax();

   lots = MathFloor(lots / step) * step;
   lots = MathMax(lots, 0);
   lots = MathMin(lots, maxLot);

   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Find MultiTP index by ticket                                      |
//+------------------------------------------------------------------+
int FindMultiTPIndex(ulong ticket)
{
   for(int i = 0; i < MultiTPCount; i++)
   {
      if(MultiTPPositions[i].ticket == ticket)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Remove position from MultiTP tracking                             |
//+------------------------------------------------------------------+
void RemoveFromMultiTPTracking(ulong ticket)
{
   int index = FindMultiTPIndex(ticket);
   if(index < 0)
      return;

   //--- Shift array elements
   for(int i = index; i < MultiTPCount - 1; i++)
   {
      MultiTPPositions[i] = MultiTPPositions[i + 1];
   }

   MultiTPCount--;
   ArrayResize(MultiTPPositions, MultiTPCount);

   if(EnableDebugMode)
      PrintFormat("MultiTP: Removed ticket #%d from tracking", ticket);
}

//+------------------------------------------------------------------+
//| Clean up closed positions from MultiTP tracking                   |
//+------------------------------------------------------------------+
void CleanupMultiTPTracking()
{
   for(int i = MultiTPCount - 1; i >= 0; i--)
   {
      //--- Check if position still exists
      if(!positionInfo.SelectByTicket(MultiTPPositions[i].ticket))
      {
         //--- Position closed, remove from tracking
         RemoveFromMultiTPTracking(MultiTPPositions[i].ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Legacy function - redirects to new implementation                 |
//+------------------------------------------------------------------+
void StoreTradeForMultipleTPs(ulong ticket, double entry, double sl, double slDistance, int direction)
{
   //--- Get current position lots
   double lots = 0;
   if(positionInfo.SelectByTicket(ticket))
   {
      lots = positionInfo.Volume();
   }

   //--- Use the new registration function
   RegisterPositionForMultiTP(ticket, entry, sl, slDistance, direction, lots);
}

//+------------------------------------------------------------------+
//| Get entry mode string for display                                |
//+------------------------------------------------------------------+
string GetEntryModeString()
{
   switch(EntryMode)
   {
      case MODE_BREAKOUT:
         return "Breakout (ORB)";
      case MODE_FADE:
         return "Fade (Reversal)";
      case MODE_HYBRID:
         return "Hybrid (Auto)";
      default:
         return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Get current signal status string                                 |
//+------------------------------------------------------------------+
string GetSignalStatusString()
{
   if(IBStatus < IB_COMPLETE)
      return "Waiting for IB";

   if(!CheckAllFilters())
      return "Filters blocking";

   if(!CanOpenNewTrade())
      return "Trade limits reached";

   int potentialSignal = 0;

   switch(EntryMode)
   {
      case MODE_BREAKOUT:
         if(IBStatus == IB_BROKEN_UP) potentialSignal = 1;
         else if(IBStatus == IB_BROKEN_DOWN) potentialSignal = -1;
         break;

      case MODE_FADE:
         if(IBStatus == IB_BROKEN_UP && IsPriceInsideIB()) potentialSignal = -1;
         else if(IBStatus == IB_BROKEN_DOWN && IsPriceInsideIB()) potentialSignal = 1;
         break;

      case MODE_HYBRID:
         if(CandlesSinceBreak >= HybridHoldCandles)
         {
            if(IBStatus >= IB_BROKEN_UP) potentialSignal = 1;
         }
         break;
   }

   if(potentialSignal > 0)
      return "BUY Signal Pending";
   else if(potentialSignal < 0)
      return "SELL Signal Pending";
   else
      return "Scanning...";
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                 TRADE MANAGEMENT & DAILY CONTROLS                |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   //--- Check EA status
   if(EAStatus != EA_RUNNING)
      return false;

   //--- Check if trade is allowed by terminal
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
      return false;

   //--- Check if trading is allowed for this EA
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
      return false;

   //--- Check if trade operations are allowed
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
      return false;

   //--- Check if expert trading is enabled
   if(!AccountInfoInteger(ACCOUNT_TRADE_EXPERT))
      return false;

   //--- Check trade allowed flag
   if(!TradeAllowed)
      return false;

   return true;
}

//+------------------------------------------------------------------+
//| Manage existing positions                                        |
//+------------------------------------------------------------------+
void ManagePositions()
{
   //--- Cleanup position tracking for closed positions
   if(TrackedPositionCount > 0)
   {
      CleanupPositionTracking();
   }

   //--- Cleanup MultiTP tracking for closed positions
   if(UseMultipleTPs && MultiTPCount > 0)
   {
      CleanupMultiTPTracking();
   }

   //--- Loop through all positions
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i))
         continue;

      //--- Check if this is our position
      if(positionInfo.Symbol() != _Symbol || positionInfo.Magic() != Magic)
         continue;

      ulong ticket = positionInfo.Ticket();

      //--- Apply breakeven if enabled
      if(UseBreakeven)
      {
         CheckAndApplyBreakeven(ticket);
      }

      //--- Apply trailing stop if enabled
      if(TrailingMode != TRAIL_NONE)
      {
         CheckAndApplyTrailingStop(ticket);
      }

      //--- Check multiple TPs if enabled
      if(UseMultipleTPs)
      {
         CheckAndApplyMultipleTPs(ticket);
      }
   }
}

//+------------------------------------------------------------------+
//| Check and apply multiple take profits                            |
//+------------------------------------------------------------------+
void CheckAndApplyMultipleTPs(ulong ticket)
{
   //--- Find the position in our tracking array
   int index = FindMultiTPIndex(ticket);

   //--- If not tracked, try to register it (for positions opened before EA loaded)
   if(index < 0)
   {
      if(!positionInfo.SelectByTicket(ticket))
         return;

      double entry = positionInfo.PriceOpen();
      double sl = positionInfo.StopLoss();
      double slDistance = MathAbs(entry - sl);
      int direction = (positionInfo.PositionType() == POSITION_TYPE_BUY) ? 1 : -1;
      double lots = positionInfo.Volume();

      if(slDistance > 0)
      {
         RegisterPositionForMultiTP(ticket, entry, sl, slDistance, direction, lots);
         index = FindMultiTPIndex(ticket);
      }

      if(index < 0)
         return;
   }

   //--- Get current position info
   if(!positionInfo.SelectByTicket(ticket))
   {
      //--- Position no longer exists, remove from tracking
      RemoveFromMultiTPTracking(ticket);
      return;
   }

   double currentPrice = positionInfo.PriceCurrent();
   double currentVolume = positionInfo.Volume();
   double currentSL = positionInfo.StopLoss();
   double entryPrice = MultiTPPositions[index].entryPrice;
   int direction = MultiTPPositions[index].direction;

   //--- Check TP1
   if(!MultiTPPositions[index].tp1Hit)
   {
      bool tp1Reached = false;

      if(direction > 0) // BUY
         tp1Reached = (currentPrice >= MultiTPPositions[index].tp1Level);
      else // SELL
         tp1Reached = (currentPrice <= MultiTPPositions[index].tp1Level);

      if(tp1Reached)
      {
         double closeVolume = MultiTPPositions[index].tp1Lots;

         //--- Validate close volume
         if(closeVolume > currentVolume)
            closeVolume = NormalizeLots(currentVolume * 0.5); // Close half if calculated is too much

         if(closeVolume >= MinLot && currentVolume > MinLot)
         {
            //--- Attempt partial close
            if(trade.PositionClosePartial(ticket, closeVolume))
            {
               MultiTPPositions[index].tp1Hit = true;

               Print("═══════════════════════════════════════════════════════════════");
               PrintFormat("TP1 HIT - Closed %.2f lots @ %.5f (%.1fR)",
                           closeVolume, currentPrice, TP1RRRatio);
               PrintFormat("  Remaining: %.2f lots | Entry: %.5f | Target was: %.5f",
                           currentVolume - closeVolume, entryPrice, MultiTPPositions[index].tp1Level);

               //--- Move to breakeven after TP1 if enabled
               if(BreakevenAfterTP1 && !MultiTPPositions[index].beMovedAfterTP1)
               {
                  double beOffset = BreakevenOffsetPips * PipValue;
                  double newSL;

                  if(direction > 0)
                     newSL = NormalizeDouble(entryPrice + beOffset, SymbolDigits);
                  else
                     newSL = NormalizeDouble(entryPrice - beOffset, SymbolDigits);

                  //--- Need to re-select position after partial close
                  Sleep(100);
                  if(positionInfo.SelectByTicket(ticket))
                  {
                     if(trade.PositionModify(ticket, newSL, MultiTPPositions[index].tp3Level))
                     {
                        MultiTPPositions[index].beMovedAfterTP1 = true;

                        //--- Mark breakeven as hit in position tracking to preserve original SL for R:R
                        MarkBreakevenHit(ticket);

                        PrintFormat("  SL moved to breakeven: %.5f | TP set to TP3: %.5f",
                                    newSL, MultiTPPositions[index].tp3Level);
                     }
                  }
               }
               Print("═══════════════════════════════════════════════════════════════");
            }
            else
            {
               if(EnableDebugMode)
                  PrintFormat("TP1 partial close failed: %d - %s",
                              trade.ResultRetcode(), trade.ResultRetcodeDescription());
            }
         }
      }
   }

   //--- Check TP2 (only after TP1 is hit)
   if(MultiTPPositions[index].tp1Hit && !MultiTPPositions[index].tp2Hit)
   {
      //--- Re-select position to get updated volume
      if(!positionInfo.SelectByTicket(ticket))
      {
         RemoveFromMultiTPTracking(ticket);
         return;
      }

      currentPrice = positionInfo.PriceCurrent();
      currentVolume = positionInfo.Volume();

      bool tp2Reached = false;

      if(direction > 0) // BUY
         tp2Reached = (currentPrice >= MultiTPPositions[index].tp2Level);
      else // SELL
         tp2Reached = (currentPrice <= MultiTPPositions[index].tp2Level);

      if(tp2Reached)
      {
         double closeVolume = MultiTPPositions[index].tp2Lots;

         //--- Validate close volume - ensure we leave some for TP3
         double remainAfterClose = currentVolume - closeVolume;
         if(remainAfterClose < MinLot && currentVolume > MinLot * 2)
         {
            closeVolume = NormalizeLots(currentVolume - MinLot);
         }

         if(closeVolume >= MinLot && currentVolume > MinLot)
         {
            if(trade.PositionClosePartial(ticket, closeVolume))
            {
               MultiTPPositions[index].tp2Hit = true;

               Print("═══════════════════════════════════════════════════════════════");
               PrintFormat("TP2 HIT - Closed %.2f lots @ %.5f (%.1fR)",
                           closeVolume, currentPrice, TP2RRRatio);
               PrintFormat("  Remaining: %.2f lots | TP3 target: %.5f (%.1fR)",
                           currentVolume - closeVolume, MultiTPPositions[index].tp3Level, TP3RRRatio);
               Print("═══════════════════════════════════════════════════════════════");
            }
            else
            {
               if(EnableDebugMode)
                  PrintFormat("TP2 partial close failed: %d - %s",
                              trade.ResultRetcode(), trade.ResultRetcodeDescription());
            }
         }
      }
   }

   //--- TP3 is handled by the broker's TP level (set after TP1 hit)
   //--- No additional action needed here - position will close automatically at TP3
}

//+------------------------------------------------------------------+
//| Check for daily reset                                            |
//+------------------------------------------------------------------+
void CheckDailyReset()
{
   //--- Get reset time in server time
   int resetHour, resetMinute;
   ParseTimeString(DailyResetTime, resetHour, resetMinute);

   //--- Get current time
   MqlDateTime currentDT;
   TimeToStruct(TimeCurrent(), currentDT);

   //--- Get last reset date
   MqlDateTime lastResetDT;
   TimeToStruct(LastTradeDate, lastResetDT);

   //--- Check if we need to reset (new day and past reset time)
   bool isNewDay = (currentDT.day != lastResetDT.day ||
                    currentDT.mon != lastResetDT.mon ||
                    currentDT.year != lastResetDT.year);

   bool pastResetTime = (currentDT.hour > resetHour ||
                         (currentDT.hour == resetHour && currentDT.min >= resetMinute));

   if(isNewDay && pastResetTime)
   {
      PerformDailyReset();
   }
}

//+------------------------------------------------------------------+
//| Reset daily counters - centralized function                       |
//+------------------------------------------------------------------+
void ResetDailyCounters()
{
   //--- Log previous day summary if we had trades
   if(EnableDebugMode && TodayTradeCount > 0)
   {
      PrintFormat("Daily counters reset: Trades=%d, Wins=%d, Losses=%d, ReEntry=%d",
                  TodayTradeCount, TodayWins, TodayLosses, ReEntryAttempts);
   }

   //--- Reset trade counters
   TodayTradeCount = 0;
   TodayWins = 0;
   TodayLosses = 0;
   ConsecutiveLosses = 0;
   TodayProfit = 0;
   ReEntryAttempts = 0;

   //--- Reset daily balance tracking
   TodayStartBalance = accountInfo.Balance();
   TodayHighBalance = TodayStartBalance;

   //--- Reset trade allowed flag (may have been disabled by limits)
   TradeAllowed = true;
   EAStatus = EA_RUNNING;

   //--- Reset last entry time for new IB session tracking
   LastEntryTime = 0;
}

//+------------------------------------------------------------------+
//| Perform daily reset                                              |
//+------------------------------------------------------------------+
void PerformDailyReset()
{
   Print("═══════════════════════════════════════════════════════════════");
   Print("DAILY RESET - Resetting counters for new trading day");

   //--- Log previous day summary
   if(TodayTradeCount > 0)
   {
      PrintFormat("Yesterday: Trades=%d, Wins=%d, Losses=%d, P/L=%.2f %s",
                  TodayTradeCount, TodayWins, TodayLosses, TodayProfit, accountInfo.Currency());
   }

   //--- Reset all daily counters
   ResetDailyCounters();

   //--- Update last reset date
   LastTradeDate = TimeCurrent();

   //--- Reset IB for new day
   InitializeIB();

   Print("New Day Start Balance: ", FormatMoney(TodayStartBalance));
   Print("═══════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Check end of day close conditions                                |
//+------------------------------------------------------------------+
void CheckEndOfDayClose()
{
   //--- Static flags to prevent repeated closing attempts
   static datetime lastFridayCloseDate = 0;
   static datetime lastEODCloseDate = 0;

   //--- Get current time info
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   datetime today = TimeCurrent() - (dt.hour * 3600 + dt.min * 60 + dt.sec);

   //--- Check Friday close (using TradeTimezone for proper conversion)
   if(dt.day_of_week == 5 && CloseOnFriday)
   {
      //--- Only process once per day
      if(lastFridayCloseDate == today)
         return;

      //--- Convert close time to server time using timezone
      int closeHour, closeMinute;
      ParseTimeString(FridayCloseAllTime, closeHour, closeMinute);
      datetime closeTime = ConvertToServerTime(closeHour, closeMinute, TradeTimezone);

      MqlDateTime closeDT;
      TimeToStruct(closeTime, closeDT);

      if(dt.hour > closeDT.hour || (dt.hour == closeDT.hour && dt.min >= closeDT.min))
      {
         //--- Mark as processed for today
         lastFridayCloseDate = today;

         int positionsClosed = CloseAllPositions("Friday EOD Close");
         if(DeletePendingAtTime)
            DeleteAllPendingOrders();

         if(positionsClosed > 0 || EnableDebugMode)
            PrintFormat("Friday EOD Close executed at %s (Server) / %s %s",
                        TimeToString(TimeCurrent(), TIME_MINUTES),
                        FridayCloseAllTime, EnumToString(TradeTimezone));
         return;
      }
   }

   //--- Check regular close time
   if(CloseAllAtTime)
   {
      //--- Only process once per day
      if(lastEODCloseDate == today)
         return;

      //--- Convert close time to server time
      int closeHour, closeMinute;
      ParseTimeString(CloseAllTime, closeHour, closeMinute);
      datetime closeTime = ConvertToServerTime(closeHour, closeMinute, TradeTimezone);

      MqlDateTime closeDT;
      TimeToStruct(closeTime, closeDT);

      if(dt.hour > closeDT.hour || (dt.hour == closeDT.hour && dt.min >= closeDT.min))
      {
         //--- Mark as processed for today
         lastEODCloseDate = today;

         int positionsClosed = CloseAllPositions("EOD Close");
         if(DeletePendingAtTime)
            DeleteAllPendingOrders();

         if(positionsClosed > 0 || EnableDebugMode)
            PrintFormat("EOD Close executed at %s", TimeToString(TimeCurrent(), TIME_MINUTES));
      }
   }
}

//+------------------------------------------------------------------+
//| Check drawdown limits                                            |
//+------------------------------------------------------------------+
void CheckDrawdownLimits()
{
   if(!UseMaxDrawdown)
      return;

   double currentBalance = accountInfo.Balance();
   double currentEquity = accountInfo.Equity();

   //--- Update high water marks
   if(currentBalance > TodayHighBalance)
      TodayHighBalance = currentBalance;

   if(currentBalance > AccountHighBalance)
      AccountHighBalance = currentBalance;

   //--- Calculate daily drawdown
   double dailyDrawdown = 0;
   if(TodayHighBalance > 0)
      dailyDrawdown = ((TodayHighBalance - currentEquity) / TodayHighBalance) * 100;

   //--- Calculate account drawdown
   double accountDrawdown = 0;
   if(AccountHighBalance > 0)
      accountDrawdown = ((AccountHighBalance - currentEquity) / AccountHighBalance) * 100;

   //--- Check daily drawdown limit
   if(MaxDailyDrawdownPercent > 0 && dailyDrawdown >= MaxDailyDrawdownPercent)
   {
      if(TradeAllowed) // Only alert once
      {
         Print("═══════════════════════════════════════════════════════════════");
         PrintFormat("⚠️ DAILY DRAWDOWN LIMIT HIT: %.2f%% >= %.2f%%", dailyDrawdown, MaxDailyDrawdownPercent);
         Print("Trading suspended for today");
         Print("═══════════════════════════════════════════════════════════════");

         TradeAllowed = false;
         EAStatus = EA_PAUSED;

         //--- Send Drawdown alert
         AlertDrawdownHit(dailyDrawdown);

         //--- Close all positions if drawdown hit
         CloseAllPositions("Daily Drawdown Limit");
      }
   }

   //--- Check account drawdown limit
   if(MaxAccountDrawdownPercent > 0 && accountDrawdown >= MaxAccountDrawdownPercent)
   {
      if(EAStatus != EA_STOPPED) // Only alert once
      {
         Print("═══════════════════════════════════════════════════════════════");
         PrintFormat("🛑 ACCOUNT DRAWDOWN LIMIT HIT: %.2f%% >= %.2f%%", accountDrawdown, MaxAccountDrawdownPercent);
         Print("EA STOPPED - Manual intervention required");
         Print("═══════════════════════════════════════════════════════════════");

         TradeAllowed = false;
         EAStatus = EA_STOPPED;

         //--- Send Drawdown alert
         AlertDrawdownHit(accountDrawdown);

         //--- Close all positions
         CloseAllPositions("Account Drawdown Limit");
      }
   }
}

//+------------------------------------------------------------------+
//| Check daily profit target                                        |
//+------------------------------------------------------------------+
void CheckDailyProfitTarget()
{
   if(!UseDailyProfitTarget)
      return;

   double target = DailyProfitTarget;

   //--- Convert to percentage if needed
   if(DailyProfitAsPercent)
      target = TodayStartBalance * (DailyProfitTarget / 100.0);

   //--- Calculate today's profit
   double todayPL = accountInfo.Balance() - TodayStartBalance;

   if(todayPL >= target)
   {
      if(TradeAllowed) // Only alert once
      {
         Print("═══════════════════════════════════════════════════════════════");
         PrintFormat("🎯 DAILY PROFIT TARGET HIT: %.2f %s", todayPL, accountInfo.Currency());
         Print("Trading suspended - Target achieved!");
         Print("═══════════════════════════════════════════════════════════════");

         TradeAllowed = false;
         TodayProfit = todayPL;

         //--- Send Daily Target alert
         AlertDailyTargetHit();
      }
   }
}

//+------------------------------------------------------------------+
//| Check daily loss limit                                           |
//+------------------------------------------------------------------+
void CheckDailyLossLimit()
{
   if(!UseDailyLossLimit)
      return;

   double limit = DailyLossLimit;

   //--- Convert to percentage if needed
   if(DailyLossAsPercent)
      limit = TodayStartBalance * (DailyLossLimit / 100.0);

   //--- Calculate today's loss
   double todayPL = accountInfo.Balance() - TodayStartBalance;

   if(todayPL <= -limit)
   {
      if(TradeAllowed) // Only alert once
      {
         Print("═══════════════════════════════════════════════════════════════");
         PrintFormat("⚠️ DAILY LOSS LIMIT HIT: %.2f %s", todayPL, accountInfo.Currency());
         Print("Trading suspended for today");
         Print("═══════════════════════════════════════════════════════════════");

         TradeAllowed = false;
         EAStatus = EA_PAUSED;
         TodayProfit = todayPL;

         //--- Send Daily Loss alert
         AlertDailyLossHit();

         //--- Close all positions
         CloseAllPositions("Daily Loss Limit");
      }
   }
}

//+------------------------------------------------------------------+
//| Close all positions for this EA                                  |
//+------------------------------------------------------------------+
int CloseAllPositions(string reason)
{
   int closedCount = 0;
   int positionsToClose = 0;

   //--- First count how many positions we have to close
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i))
         continue;
      if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == Magic)
         positionsToClose++;
   }

   //--- Only print if we have positions to close
   if(positionsToClose > 0)
      Print("Closing all positions - Reason: ", reason);

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(!positionInfo.SelectByIndex(i))
         continue;

      if(positionInfo.Symbol() != _Symbol || positionInfo.Magic() != Magic)
         continue;

      ulong ticket = positionInfo.Ticket();

      if(trade.PositionClose(ticket))
      {
         PrintFormat("Position %d closed", ticket);
         closedCount++;
      }
      else
      {
         PrintFormat("Failed to close position %d: %s", ticket, trade.ResultRetcodeDescription());
      }
   }

   return closedCount;
}

//+------------------------------------------------------------------+
//| Delete all pending orders for this EA                            |
//+------------------------------------------------------------------+
void DeleteAllPendingOrders()
{
   Print("Deleting all pending orders");

   for(int i = OrdersTotal() - 1; i >= 0; i--)
   {
      if(!orderInfo.SelectByIndex(i))
         continue;

      if(orderInfo.Symbol() != _Symbol || orderInfo.Magic() != Magic)
         continue;

      ulong ticket = orderInfo.Ticket();

      if(trade.OrderDelete(ticket))
      {
         PrintFormat("Order %d deleted", ticket);
      }
      else
      {
         PrintFormat("Failed to delete order %d: %s", ticket, trade.ResultRetcodeDescription());
      }
   }
}

//+------------------------------------------------------------------+
//| Update trade statistics after position close                     |
//+------------------------------------------------------------------+
void UpdateTradeStatistics(double profit)
{
   TodayProfit += profit;

   if(profit >= 0)
   {
      TodayWins++;
      ConsecutiveLosses = 0;
   }
   else
   {
      TodayLosses++;
      ConsecutiveLosses++;
      ReEntryAttempts++;
   }

   //--- Check if we've hit daily limits
   CheckDailyProfitTarget();
   CheckDailyLossLimit();
}

//+------------------------------------------------------------------+
//| Get trade management status string                               |
//+------------------------------------------------------------------+
string GetTradeManagementStatus()
{
   string status = "";

   //--- EA Status
   switch(EAStatus)
   {
      case EA_RUNNING: status += "EA: Running"; break;
      case EA_PAUSED: status += "EA: PAUSED"; break;
      case EA_STOPPED: status += "EA: STOPPED"; break;
   }

   //--- Today's stats
   status += StringFormat(" | Today: %d trades (%dW/%dL)",
                          TodayTradeCount, TodayWins, TodayLosses);

   //--- Today's P/L
   double todayPL = accountInfo.Balance() - TodayStartBalance;
   status += StringFormat(" | P/L: %.2f %s", todayPL, accountInfo.Currency());

   return status;
}

//+------------------------------------------------------------------+
//| Get detailed trade management info                               |
//+------------------------------------------------------------------+
string GetDetailedTradeManagementInfo()
{
   string info = "\n===== TRADE MANAGEMENT =====\n";

   //--- EA Status
   info += StringFormat("EA Status: %s\n", EnumToString(EAStatus));
   info += StringFormat("Trade Allowed: %s\n", TradeAllowed ? "Yes" : "No");

   //--- Daily Stats
   info += "\nToday's Statistics:\n";
   info += StringFormat("  Trades: %d (Wins: %d, Losses: %d)\n", TodayTradeCount, TodayWins, TodayLosses);
   info += StringFormat("  Consecutive Losses: %d\n", ConsecutiveLosses);
   info += StringFormat("  Re-entry Attempts: %d\n", ReEntryAttempts);

   //--- Balance Info
   double todayPL = accountInfo.Balance() - TodayStartBalance;
   double todayPLPercent = (TodayStartBalance > 0) ? (todayPL / TodayStartBalance) * 100 : 0;
   info += "\nBalance:\n";
   info += StringFormat("  Start: %s\n", FormatMoney(TodayStartBalance));
   info += StringFormat("  Current: %s\n", FormatMoney(accountInfo.Balance()));
   info += StringFormat("  P/L: %s (%.2f%%)\n", FormatMoney(todayPL), todayPLPercent);
   info += StringFormat("  High: %s\n", FormatMoney(TodayHighBalance));

   //--- Drawdown
   double dailyDD = 0;
   if(TodayHighBalance > 0)
      dailyDD = ((TodayHighBalance - accountInfo.Equity()) / TodayHighBalance) * 100;

   double accountDD = 0;
   if(AccountHighBalance > 0)
      accountDD = ((AccountHighBalance - accountInfo.Equity()) / AccountHighBalance) * 100;

   info += "\nDrawdown:\n";
   info += StringFormat("  Daily: %.2f%% (Max: %.2f%%)\n", dailyDD, MaxDailyDrawdownPercent);
   info += StringFormat("  Account: %.2f%% (Max: %.2f%%)\n", accountDD, MaxAccountDrawdownPercent);

   //--- Limits
   info += "\nLimits:\n";
   info += StringFormat("  Max Trades/Day: %d (Used: %d)\n", MaxTradesPerDay, TodayTradeCount);
   info += StringFormat("  Max Consec. Losses: %d (Current: %d)\n", MaxLosingTradesPerDay, ConsecutiveLosses);

   info += "============================\n";

   return info;
}

//+------------------------------------------------------------------+
//| Handle trade transaction events                                  |
//+------------------------------------------------------------------+
void OnTradeTransaction(const MqlTradeTransaction& trans,
                        const MqlTradeRequest& request,
                        const MqlTradeResult& result)
{
   //--- Check for deal added (position closed)
   if(trans.type == TRADE_TRANSACTION_DEAL_ADD)
   {
      //--- Get deal info
      if(HistoryDealSelect(trans.deal))
      {
         //--- Check if this is our deal
         if(HistoryDealGetInteger(trans.deal, DEAL_MAGIC) == Magic &&
            HistoryDealGetString(trans.deal, DEAL_SYMBOL) == _Symbol)
         {
            ENUM_DEAL_ENTRY dealEntry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(trans.deal, DEAL_ENTRY);

            //--- Position was closed
            if(dealEntry == DEAL_ENTRY_OUT || dealEntry == DEAL_ENTRY_INOUT)
            {
               double profit = HistoryDealGetDouble(trans.deal, DEAL_PROFIT);
               double commission = HistoryDealGetDouble(trans.deal, DEAL_COMMISSION);
               double swap = HistoryDealGetDouble(trans.deal, DEAL_SWAP);
               double totalProfit = profit + commission + swap;
               double exitPrice = HistoryDealGetDouble(trans.deal, DEAL_PRICE);

               UpdateTradeStatistics(totalProfit);

               PrintFormat("Trade closed - Profit: %.2f (%.2f + %.2f comm + %.2f swap)",
                           totalProfit, profit, commission, swap);

               //--- Determine exit reason
               string exitReason = "Manual/Unknown";
               ENUM_DEAL_REASON dealReason = (ENUM_DEAL_REASON)HistoryDealGetInteger(trans.deal, DEAL_REASON);
               switch(dealReason)
               {
                  case DEAL_REASON_SL:       exitReason = "Stop Loss"; break;
                  case DEAL_REASON_TP:       exitReason = "Take Profit"; break;
                  case DEAL_REASON_SO:       exitReason = "Stop Out"; break;
                  case DEAL_REASON_CLIENT:   exitReason = "Manual Close"; break;
                  case DEAL_REASON_EXPERT:   exitReason = "EA Close"; break;
                  default:                   exitReason = "Other"; break;
               }

               //--- Find entry price from history
               double entryPrice = 0;
               ulong positionId = HistoryDealGetInteger(trans.deal, DEAL_POSITION_ID);
               if(HistorySelectByPosition(positionId))
               {
                  int totalDeals = HistoryDealsTotal();
                  for(int i = 0; i < totalDeals; i++)
                  {
                     ulong dealTicket = HistoryDealGetTicket(i);
                     if(dealTicket > 0)
                     {
                        ENUM_DEAL_ENTRY entry = (ENUM_DEAL_ENTRY)HistoryDealGetInteger(dealTicket, DEAL_ENTRY);
                        if(entry == DEAL_ENTRY_IN)
                        {
                           entryPrice = HistoryDealGetDouble(dealTicket, DEAL_PRICE);
                           break;
                        }
                     }
                  }
               }

               //--- Send Trade Exit alert
               AlertTradeExit(exitReason, totalProfit, entryPrice, exitPrice);

               //--- Draw trade exit arrow
               ENUM_DEAL_TYPE dealType = (ENUM_DEAL_TYPE)HistoryDealGetInteger(trans.deal, DEAL_TYPE);
               int exitDirection = (dealType == DEAL_TYPE_SELL) ? 1 : -1; // Opposite of deal type
               DrawTradeExit(TimeCurrent(), exitPrice, exitDirection, totalProfit, exitReason);
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                 DASHBOARD & MANUAL BUTTONS                       |
//|                                                                  |
//+------------------------------------------------------------------+

//--- Dashboard Layout Constants
#define DASH_PADDING        5
#define DASH_LINE_HEIGHT    18
#define DASH_HEADER_HEIGHT  25

//--- Button Names
#define BTN_BUY             "RPD_BTN_BUY"
#define BTN_SELL            "RPD_BTN_SELL"
#define BTN_CLOSE_ALL       "RPD_BTN_CLOSE"
#define BTN_PAUSE           "RPD_BTN_PAUSE"

//+------------------------------------------------------------------+
//| Create the dashboard panel                                       |
//+------------------------------------------------------------------+
void CreateDashboard()
{
   if(!ShowDashboard)
      return;

   //--- Calculate dashboard dimensions based on size setting
   int dashWidth, dashHeight, fontSize;
   GetDashboardDimensions(dashWidth, dashHeight, fontSize);

   //--- Calculate position based on corner setting
   int xPos, yPos;
   GetDashboardPosition(dashWidth, dashHeight, xPos, yPos);

   //--- Create background rectangle
   string bgName = DashboardPrefix + "BG";
   CreateRectLabel(bgName, xPos, yPos, dashWidth, dashHeight, DashboardBgColor, DashboardTransparency);

   //--- Create header
   string headerName = DashboardPrefix + "Header";
   CreateLabel(headerName, xPos + DASH_PADDING, yPos + DASH_PADDING,
               "RangePredator EA v1.00", fontSize + 2, clrGold, true);

   //--- Create time display (NY and London) - below header with spacing
   int timeYOffset = DASH_PADDING + fontSize + 12;
   CreateLabel(DashboardPrefix + "LblNYTime", xPos + DASH_PADDING, yPos + timeYOffset,
               "NY:      --:--:--", fontSize, clrDeepSkyBlue, false);
   timeYOffset += DASH_LINE_HEIGHT;
   CreateLabel(DashboardPrefix + "LblLondonTime", xPos + DASH_PADDING, yPos + timeYOffset,
               "London:  --:--:--", fontSize, clrDeepSkyBlue, false);

   //--- Create separator line (with spacing after time)
   int sepYOffset = timeYOffset + DASH_LINE_HEIGHT + 5;
   string sepName = DashboardPrefix + "Sep1";
   CreateHLine(sepName, xPos + DASH_PADDING, yPos + sepYOffset,
               dashWidth - (DASH_PADDING * 2), DashboardTextColor);

   //--- Create status labels (will be updated in UpdateDashboard)
   int yOffset = sepYOffset + 10;

   CreateLabel(DashboardPrefix + "LblSymbol", xPos + DASH_PADDING, yPos + yOffset,
               "Symbol: " + _Symbol, fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblMode", xPos + DASH_PADDING, yPos + yOffset,
               "Mode: " + GetEntryModeString(), fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblIBStatus", xPos + DASH_PADDING, yPos + yOffset,
               "IB: Waiting...", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblIBRemaining", xPos + DASH_PADDING + 10, yPos + yOffset,
               "Remaining: --:--:--", fontSize, clrYellow, false);
   yOffset += DASH_LINE_HEIGHT + 5;

   CreateLabel(DashboardPrefix + "LblSignal", xPos + DASH_PADDING, yPos + yOffset,
               "Signal: None", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   //--- Separator
   yOffset += 8;
   CreateHLine(DashboardPrefix + "Sep2", xPos + DASH_PADDING, yPos + yOffset,
               dashWidth - (DASH_PADDING * 2), DashboardTextColor);
   yOffset += 10;

   CreateLabel(DashboardPrefix + "LblSpread", xPos + DASH_PADDING, yPos + yOffset,
               "Spread: 0.0 pips", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblATR", xPos + DASH_PADDING, yPos + yOffset,
               "ATR: 0.0 pips", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblFilters", xPos + DASH_PADDING, yPos + yOffset,
               "Filters: Checking...", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   //--- Separator
   yOffset += 5;
   CreateHLine(DashboardPrefix + "Sep3", xPos + DASH_PADDING, yPos + yOffset,
               dashWidth - (DASH_PADDING * 2), DashboardTextColor);
   yOffset += 10;

   CreateLabel(DashboardPrefix + "LblTrades", xPos + DASH_PADDING, yPos + yOffset,
               "Trades: 0/0 (0W/0L)", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblPL", xPos + DASH_PADDING, yPos + yOffset,
               "P/L: $0.00", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblEquity", xPos + DASH_PADDING, yPos + yOffset,
               "Equity: $0.00", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblDrawdown", xPos + DASH_PADDING, yPos + yOffset,
               "DD: 0.00%", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   //--- Separator
   yOffset += 5;
   CreateHLine(DashboardPrefix + "Sep4", xPos + DASH_PADDING, yPos + yOffset,
               dashWidth - (DASH_PADDING * 2), DashboardTextColor);
   yOffset += 10;

   CreateLabel(DashboardPrefix + "LblPosition", xPos + DASH_PADDING, yPos + yOffset,
               "Position: None", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   CreateLabel(DashboardPrefix + "LblPosProfit", xPos + DASH_PADDING, yPos + yOffset,
               "Pos P/L: $0.00", fontSize, DashboardTextColor, false);
   yOffset += DASH_LINE_HEIGHT;

   //--- Status line at bottom
   yOffset += 10;
   CreateLabel(DashboardPrefix + "LblStatus", xPos + DASH_PADDING, yPos + yOffset,
               "Status: Initializing...", fontSize, clrYellow, false);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Update dashboard with current values                             |
//+------------------------------------------------------------------+
void UpdateDashboard()
{
   if(!ShowDashboard)
      return;

   //--- Update NY and London Time Display
   datetime serverTime = TimeCurrent();
   MqlDateTime serverDT;
   TimeToStruct(serverTime, serverDT);

   //--- Calculate NY time (server time -> GMT -> NY)
   int nyHour = serverDT.hour - DetectedServerGMTOffset + NewYorkGMTOffset;
   int nyMin = serverDT.min;
   int nySec = serverDT.sec;
   //--- Handle day wrap
   if(nyHour < 0) nyHour += 24;
   if(nyHour >= 24) nyHour -= 24;

   //--- Calculate London time (server time -> GMT -> London)
   int ldnHour = serverDT.hour - DetectedServerGMTOffset + LondonGMTOffset;
   int ldnMin = serverDT.min;
   int ldnSec = serverDT.sec;
   //--- Handle day wrap
   if(ldnHour < 0) ldnHour += 24;
   if(ldnHour >= 24) ldnHour -= 24;

   UpdateLabel(DashboardPrefix + "LblNYTime",
               StringFormat("NY:      %02d:%02d:%02d", nyHour, nyMin, nySec), clrDeepSkyBlue);
   UpdateLabel(DashboardPrefix + "LblLondonTime",
               StringFormat("London:  %02d:%02d:%02d", ldnHour, ldnMin, ldnSec), clrDeepSkyBlue);

   //--- Update Range Status (IB or Settlement based on strategy)
   if(RangeStrategy == STRATEGY_SETTLEMENT)
   {
      //--- Settlement Status
      string settleStatus = GetSettlementStatusString();
      color settleColor = DashboardTextColor;
      if(SettlementStatus == SETTLE_BROKEN_UP) settleColor = DashboardProfitColor;
      else if(SettlementStatus == SETTLE_BROKEN_DOWN) settleColor = DashboardLossColor;
      else if(SettlementStatus == SETTLE_COMPLETE) settleColor = clrYellow;
      else if(SettlementStatus == SETTLE_COLLECTING) settleColor = clrOrange;

      UpdateLabel(DashboardPrefix + "LblIBStatus", "Settle: " + settleStatus, settleColor);

      //--- Settlement Range Info
      string settleRange = "";
      if(SettlementStatus >= SETTLE_COMPLETE)
         settleRange = StringFormat("Range: %.1f pips | H:%.5f L:%.5f",
                                    SettlementRange / PipValue, SettlementHigh, SettlementLow);
      else if(SettlementStatus == SETTLE_COLLECTING)
         settleRange = StringFormat("Ticks: %d", SettlementTickCount);
      else
         settleRange = StringFormat("Start: %s",
                       TimeToString(SettlementStartDateTime, TIME_MINUTES));

      UpdateLabel(DashboardPrefix + "LblIBRemaining", settleRange, DashboardTextColor);
   }
   else
   {
      //--- IB Status (original)
      string ibStatus = GetIBStatusString();
      color ibColor = DashboardTextColor;
      if(IBStatus == IB_BROKEN_UP) ibColor = DashboardProfitColor;
      else if(IBStatus == IB_BROKEN_DOWN) ibColor = DashboardLossColor;
      else if(IBStatus == IB_COMPLETE) ibColor = clrYellow;

      UpdateLabel(DashboardPrefix + "LblIBStatus", "IB: " + ibStatus, ibColor);

      //--- Update IB Time Remaining
      string ibRemaining = GetIBRemainingString();
      color ibRemColor = clrYellow;
      if(IBStatus == IB_COMPLETE || IBStatus == IB_BROKEN_UP || IBStatus == IB_BROKEN_DOWN)
         ibRemColor = DashboardTextColor;

      UpdateLabel(DashboardPrefix + "LblIBRemaining", ibRemaining, ibRemColor);
   }

   //--- Update Signal Status
   string signalStatus = GetSignalStatusString();
   color signalColor = DashboardTextColor;
   if(StringFind(signalStatus, "BUY") >= 0) signalColor = DashboardProfitColor;
   else if(StringFind(signalStatus, "SELL") >= 0) signalColor = DashboardLossColor;

   UpdateLabel(DashboardPrefix + "LblSignal", "Signal: " + signalStatus, signalColor);

   //--- Update Spread
   double spreadPips = GetSpreadPips();
   color spreadColor = (spreadPips <= MaxSpreadPips) ? DashboardTextColor : DashboardLossColor;
   UpdateLabel(DashboardPrefix + "LblSpread",
               StringFormat("Spread: %.1f pips", spreadPips), spreadColor);

   //--- Update ATR
   double atr = GetATRValue();
   double atrPips = atr / PipValue;
   UpdateLabel(DashboardPrefix + "LblATR",
               StringFormat("ATR: %.1f pips", atrPips), DashboardTextColor);

   //--- Update Filters
   bool filtersOK = CheckAllFilters();
   UpdateLabel(DashboardPrefix + "LblFilters",
               "Filters: " + (filtersOK ? "PASS" : "BLOCKED"),
               filtersOK ? DashboardProfitColor : DashboardLossColor);

   //--- Update Trades
   UpdateLabel(DashboardPrefix + "LblTrades",
               StringFormat("Trades: %d/%d (%dW/%dL)",
                            TodayTradeCount, MaxTradesPerDay, TodayWins, TodayLosses),
               DashboardTextColor);

   //--- Update P/L
   double todayPL = accountInfo.Balance() - TodayStartBalance;
   color plColor = (todayPL >= 0) ? DashboardProfitColor : DashboardLossColor;
   UpdateLabel(DashboardPrefix + "LblPL",
               StringFormat("P/L: %s", FormatMoney(todayPL)), plColor);

   //--- Update Equity
   UpdateLabel(DashboardPrefix + "LblEquity",
               StringFormat("Equity: %s", FormatMoney(accountInfo.Equity())),
               DashboardTextColor);

   //--- Update Drawdown
   double dailyDD = 0;
   if(TodayHighBalance > 0)
      dailyDD = ((TodayHighBalance - accountInfo.Equity()) / TodayHighBalance) * 100;
   color ddColor = (dailyDD < MaxDailyDrawdownPercent * 0.8) ? DashboardTextColor :
                   (dailyDD < MaxDailyDrawdownPercent) ? clrOrange : DashboardLossColor;
   UpdateLabel(DashboardPrefix + "LblDrawdown",
               StringFormat("DD: %.2f%% / %.2f%%", dailyDD, MaxDailyDrawdownPercent), ddColor);

   //--- Update Position Info
   int posCount = CountOpenPositions();
   if(posCount > 0)
   {
      double posProfit = GetTotalPositionProfit();
      color posPLColor = (posProfit >= 0) ? DashboardProfitColor : DashboardLossColor;

      UpdateLabel(DashboardPrefix + "LblPosition",
                  StringFormat("Position: %d open", posCount), DashboardTextColor);
      UpdateLabel(DashboardPrefix + "LblPosProfit",
                  StringFormat("Pos P/L: %s", FormatMoney(posProfit)), posPLColor);
   }
   else
   {
      UpdateLabel(DashboardPrefix + "LblPosition", "Position: None", DashboardTextColor);
      UpdateLabel(DashboardPrefix + "LblPosProfit", "Pos P/L: $0.00", DashboardTextColor);
   }

   //--- Update Status
   string status = "";
   color statusColor = clrYellow;

   if(EAStatus == EA_STOPPED)
   {
      status = "STOPPED - Manual intervention required";
      statusColor = DashboardLossColor;
   }
   else if(EAStatus == EA_PAUSED)
   {
      status = "PAUSED - Daily limit reached";
      statusColor = clrOrange;
   }
   else if(!TradeAllowed)
   {
      status = "Trading suspended";
      statusColor = clrOrange;
   }
   else if(!IsTradeAllowed())
   {
      status = "Trade not allowed";
      statusColor = DashboardLossColor;
   }
   else
   {
      status = "Running - " + EnumToString(IBStatus);
      statusColor = DashboardProfitColor;
   }

   UpdateLabel(DashboardPrefix + "LblStatus", "Status: " + status, statusColor);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Create manual trading buttons                                    |
//+------------------------------------------------------------------+
void CreateManualButtons()
{
   if(!ShowManualButtons)
      return;

   //--- Calculate dashboard dimensions to position buttons below it
   int dashWidth, dashHeight, fontSize;
   GetDashboardDimensions(dashWidth, dashHeight, fontSize);

   int xPos, yPos;
   GetDashboardPosition(dashWidth, dashHeight, xPos, yPos);

   //--- Position buttons below dashboard
   int btnY = yPos + dashHeight + 10;
   int btnWidth = (dashWidth - (DASH_PADDING * 3)) / 2;
   int btnHeight = 30;

   //--- Buy Button
   CreateButton(BTN_BUY, xPos + DASH_PADDING, btnY,
                btnWidth, btnHeight, "BUY", clrWhite, clrGreen);

   //--- Sell Button
   CreateButton(BTN_SELL, xPos + DASH_PADDING + btnWidth + DASH_PADDING, btnY,
                btnWidth, btnHeight, "SELL", clrWhite, clrRed);

   btnY += btnHeight + 5;

   //--- Close All Button
   CreateButton(BTN_CLOSE_ALL, xPos + DASH_PADDING, btnY,
                btnWidth, btnHeight, "CLOSE ALL", clrWhite, clrDarkOrange);

   //--- Pause/Resume Button
   CreateButton(BTN_PAUSE, xPos + DASH_PADDING + btnWidth + DASH_PADDING, btnY,
                btnWidth, btnHeight, "PAUSE EA", clrWhite, clrDarkGray);

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//| Handle button click events                                       |
//+------------------------------------------------------------------+
void HandleButtonClick(string sparam)
{
   if(sparam == BTN_BUY)
   {
      ExecuteManualTrade(1);
   }
   else if(sparam == BTN_SELL)
   {
      ExecuteManualTrade(-1);
   }
   else if(sparam == BTN_CLOSE_ALL)
   {
      CloseAllPositions("Manual Close All");
   }
   else if(sparam == BTN_PAUSE)
   {
      TogglePauseEA();
   }
}

//+------------------------------------------------------------------+
//| Execute manual trade                                             |
//+------------------------------------------------------------------+
void ExecuteManualTrade(int direction)
{
   //--- Get lot size
   double lotSize;
   if(UseEALotForManual)
   {
      //--- Calculate SL distance for lot calculation
      double entryPrice = (direction > 0) ? symbolInfo.Ask() : symbolInfo.Bid();
      double slDistance = 0;

      if(direction > 0)
         CalculateBuySL(entryPrice, slDistance);
      else
         CalculateSellSL(entryPrice, slDistance);

      if(slDistance > 0)
         lotSize = CalculateLotSize(slDistance);
      else
         lotSize = ManualFixedLot;
   }
   else
   {
      lotSize = ManualFixedLot;
   }

   //--- Normalize lot size
   lotSize = NormalizeLotSize(lotSize);

   if(lotSize <= 0)
   {
      Print("Manual trade failed: Invalid lot size");
      return;
   }

   //--- Execute trade
   bool result = false;
   string comment = TradeComment + "_Manual";

   if(direction > 0)
   {
      result = trade.Buy(lotSize, _Symbol, 0, 0, 0, comment);
   }
   else
   {
      result = trade.Sell(lotSize, _Symbol, 0, 0, 0, comment);
   }

   if(result)
   {
      PrintFormat("Manual %s executed: %.2f lots", direction > 0 ? "BUY" : "SELL", lotSize);
   }
   else
   {
      PrintFormat("Manual trade failed: %s", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Toggle EA pause state                                            |
//+------------------------------------------------------------------+
void TogglePauseEA()
{
   if(EAStatus == EA_RUNNING)
   {
      EAStatus = EA_PAUSED;
      TradeAllowed = false;
      UpdateButtonText(BTN_PAUSE, "RESUME EA");
      Print("EA PAUSED by user");
   }
   else if(EAStatus == EA_PAUSED)
   {
      EAStatus = EA_RUNNING;
      TradeAllowed = true;
      UpdateButtonText(BTN_PAUSE, "PAUSE EA");
      Print("EA RESUMED by user");
   }
   else
   {
      Print("Cannot toggle - EA is STOPPED");
   }
}

//+------------------------------------------------------------------+
//| Get total profit of open positions                               |
//+------------------------------------------------------------------+
double GetTotalPositionProfit()
{
   double totalProfit = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(positionInfo.SelectByIndex(i))
      {
         if(positionInfo.Symbol() == _Symbol && positionInfo.Magic() == Magic)
         {
            totalProfit += positionInfo.Profit() + positionInfo.Swap() + positionInfo.Commission();
         }
      }
   }

   return totalProfit;
}

//+------------------------------------------------------------------+
//| Get dashboard dimensions based on size setting                   |
//+------------------------------------------------------------------+
void GetDashboardDimensions(int &width, int &height, int &fontSize)
{
   switch(DashboardSize)
   {
      case DASH_SMALL:
         width = 180;
         height = 340;
         fontSize = 8;
         break;

      case DASH_LARGE:
         width = 280;
         height = 440;
         fontSize = 11;
         break;

      default: // DASH_MEDIUM
         width = 220;
         height = 380;
         fontSize = 9;
         break;
   }
}

//+------------------------------------------------------------------+
//| Get dashboard position based on corner setting                   |
//+------------------------------------------------------------------+
void GetDashboardPosition(int width, int height, int &xPos, int &yPos)
{
   int chartWidth = (int)ChartGetInteger(0, CHART_WIDTH_IN_PIXELS);
   int chartHeight = (int)ChartGetInteger(0, CHART_HEIGHT_IN_PIXELS);

   switch(DashboardPosition)
   {
      case DASH_TOP_RIGHT:
         xPos = chartWidth - width - 10;
         yPos = 30;
         break;

      case DASH_BOTTOM_LEFT:
         xPos = 10;
         yPos = chartHeight - height - 50;
         break;

      case DASH_BOTTOM_RIGHT:
         xPos = chartWidth - width - 10;
         yPos = chartHeight - height - 50;
         break;

      default: // DASH_TOP_LEFT
         xPos = 10;
         yPos = 30;
         break;
   }
}

//+------------------------------------------------------------------+
//| Create rectangle label (background)                              |
//+------------------------------------------------------------------+
void CreateRectLabel(string name, int x, int y, int width, int height, color bgColor, int transparency)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Create text label                                                |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, int fontSize, color textColor, bool bold)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, bold ? "Arial Bold" : "Arial");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Update label text and color                                      |
//+------------------------------------------------------------------+
void UpdateLabel(string name, string text, color textColor)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
      ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   }
}

//+------------------------------------------------------------------+
//| Create horizontal line (separator)                               |
//+------------------------------------------------------------------+
void CreateHLine(string name, int x, int y, int width, color lineColor)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_RECTANGLE_LABEL, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, 1);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, lineColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
}

//+------------------------------------------------------------------+
//| Create button                                                    |
//+------------------------------------------------------------------+
void CreateButton(string name, int x, int y, int width, int height, string text, color textColor, color bgColor)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_BUTTON, 0, 0, 0);

   ObjectSetInteger(0, name, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, name, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, name, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, name, OBJPROP_YSIZE, height);
   ObjectSetString(0, name, OBJPROP_TEXT, text);
   ObjectSetString(0, name, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, name, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, name, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, name, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, name, OBJPROP_BORDER_COLOR, clrGray);
   ObjectSetInteger(0, name, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, name, OBJPROP_BACK, false);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, name, OBJPROP_HIDDEN, true);
   ObjectSetInteger(0, name, OBJPROP_STATE, false);
}

//+------------------------------------------------------------------+
//| Update button text                                               |
//+------------------------------------------------------------------+
void UpdateButtonText(string name, string text)
{
   if(ObjectFind(0, name) >= 0)
   {
      ObjectSetString(0, name, OBJPROP_TEXT, text);
   }
}

//+------------------------------------------------------------------+
//| Clean up all chart objects                                       |
//+------------------------------------------------------------------+
void CleanupChartObjects()
{
   //--- Remove all objects with EA prefix
   ObjectsDeleteAll(0, DashboardPrefix);
   ObjectsDeleteAll(0, "RPD_BTN_");

   //--- Remove all visual elements
   RemoveAllVisualElements();

   ChartRedraw(0);
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                    PHASE 8: ALERTS & NOTIFICATIONS               |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Alert type enumeration                                           |
//+------------------------------------------------------------------+
enum ENUM_ALERT_TYPE
{
   ALERT_IB_FORMED,           // IB Formation Complete
   ALERT_BREAKOUT,            // Price Breakout
   ALERT_TRADE_ENTRY,         // Trade Entry
   ALERT_TRADE_EXIT,          // Trade Exit
   ALERT_DAILY_TARGET,        // Daily Profit Target Hit
   ALERT_DAILY_LOSS,          // Daily Loss Limit Hit
   ALERT_DRAWDOWN,            // Drawdown Limit Hit
   ALERT_RETEST,              // Price Retest of IB Level
   ALERT_FILTER_BLOCKED,      // Trade Blocked by Filter
   ALERT_ERROR                // Error Alert
};

//+------------------------------------------------------------------+
//| Send alert based on type and configured methods                  |
//+------------------------------------------------------------------+
void SendAlert(ENUM_ALERT_TYPE alertType, string message, string additionalInfo = "")
{
   // Check if this alert type is enabled
   if(!IsAlertTypeEnabled(alertType))
      return;

   // Build full alert message
   string fullMessage = BuildAlertMessage(alertType, message, additionalInfo);

   // Log to Experts tab
   Print("[ALERT] ", fullMessage);

   // Send via enabled methods
   if(UseSoundAlert)
      SendSoundAlert(alertType);

   if(UsePopupAlert)
      SendPopupAlert(alertType, fullMessage);

   if(UsePushNotification)
      SendPushAlert(fullMessage);

   if(UseEmailAlert)
      SendEmailAlert(alertType, fullMessage);
}

//+------------------------------------------------------------------+
//| Check if specific alert type is enabled                          |
//+------------------------------------------------------------------+
bool IsAlertTypeEnabled(ENUM_ALERT_TYPE alertType)
{
   switch(alertType)
   {
      case ALERT_IB_FORMED:      return AlertOnIBFormed;
      case ALERT_BREAKOUT:       return AlertOnBreakout;
      case ALERT_TRADE_ENTRY:    return AlertOnEntry;
      case ALERT_TRADE_EXIT:     return AlertOnExit;
      case ALERT_DAILY_TARGET:   return AlertOnDailyTarget;
      case ALERT_DAILY_LOSS:     return AlertOnDailyLoss;
      case ALERT_DRAWDOWN:       return AlertOnDrawdown;
      case ALERT_RETEST:         return AlertOnBreakout;  // Use breakout setting for retest
      case ALERT_FILTER_BLOCKED: return EnableDebugMode;   // Only in debug mode
      case ALERT_ERROR:          return true;              // Always show errors
      default:                   return false;
   }
}

//+------------------------------------------------------------------+
//| Build formatted alert message                                     |
//+------------------------------------------------------------------+
string BuildAlertMessage(ENUM_ALERT_TYPE alertType, string message, string additionalInfo)
{
   string prefix = GetAlertPrefix(alertType);
   string symbolStr = Symbol() + " " + GetTimeframeString(Period());
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_MINUTES);

   string fullMessage = StringFormat("%s | %s | %s | %s",
                                     prefix, symbolStr, timestamp, message);

   if(additionalInfo != "")
      fullMessage += " | " + additionalInfo;

   return fullMessage;
}

//+------------------------------------------------------------------+
//| Get alert type prefix                                            |
//+------------------------------------------------------------------+
string GetAlertPrefix(ENUM_ALERT_TYPE alertType)
{
   switch(alertType)
   {
      case ALERT_IB_FORMED:      return "IB FORMED";
      case ALERT_BREAKOUT:       return "BREAKOUT";
      case ALERT_TRADE_ENTRY:    return "ENTRY";
      case ALERT_TRADE_EXIT:     return "EXIT";
      case ALERT_DAILY_TARGET:   return "TARGET HIT";
      case ALERT_DAILY_LOSS:     return "LOSS LIMIT";
      case ALERT_DRAWDOWN:       return "DRAWDOWN";
      case ALERT_RETEST:         return "RETEST";
      case ALERT_FILTER_BLOCKED: return "BLOCKED";
      case ALERT_ERROR:          return "ERROR";
      default:                   return "ALERT";
   }
}

//+------------------------------------------------------------------+
//| Get timeframe string                                             |
//+------------------------------------------------------------------+
string GetTimeframeString(ENUM_TIMEFRAMES tf)
{
   switch(tf)
   {
      case PERIOD_M1:  return "M1";
      case PERIOD_M5:  return "M5";
      case PERIOD_M15: return "M15";
      case PERIOD_M30: return "M30";
      case PERIOD_H1:  return "H1";
      case PERIOD_H4:  return "H4";
      case PERIOD_D1:  return "D1";
      case PERIOD_W1:  return "W1";
      case PERIOD_MN1: return "MN1";
      default:         return EnumToString(tf);
   }
}

//+------------------------------------------------------------------+
//| Send sound alert                                                 |
//+------------------------------------------------------------------+
void SendSoundAlert(ENUM_ALERT_TYPE alertType)
{
   string soundFile = GetSoundFileForAlert(alertType);

   if(soundFile != "" && FileIsExist(soundFile, FILE_COMMON))
   {
      PlaySound(soundFile);
   }
   else if(AlertSoundFile != "" && FileIsExist(AlertSoundFile, FILE_COMMON))
   {
      PlaySound(AlertSoundFile);
   }
   else
   {
      // Use default system alert sound
      PlaySound("alert.wav");
   }
}

//+------------------------------------------------------------------+
//| Get specific sound file for alert type                           |
//+------------------------------------------------------------------+
string GetSoundFileForAlert(ENUM_ALERT_TYPE alertType)
{
   // You can customize different sounds for different alert types
   switch(alertType)
   {
      case ALERT_TRADE_ENTRY:    return "order_sent.wav";
      case ALERT_TRADE_EXIT:     return "order_close.wav";
      case ALERT_ERROR:          return "error.wav";
      case ALERT_DAILY_TARGET:   return "ok.wav";
      case ALERT_DAILY_LOSS:     return "stops.wav";
      case ALERT_DRAWDOWN:       return "stops.wav";
      default:                   return AlertSoundFile;
   }
}

//+------------------------------------------------------------------+
//| Send popup alert                                                 |
//+------------------------------------------------------------------+
void SendPopupAlert(ENUM_ALERT_TYPE alertType, string message)
{
   // MQL5 Alert() function shows a popup dialog
   Alert(EAName, " - ", message);
}

//+------------------------------------------------------------------+
//| Send push notification                                           |
//+------------------------------------------------------------------+
void SendPushAlert(string message)
{
   // Check if terminal allows push notifications
   if(!TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
   {
      if(EnableDebugMode)
         Print("[DEBUG] Push notifications not enabled in terminal settings");
      return;
   }

   // Truncate message if too long (push notifications have limit)
   string pushMessage = message;
   if(StringLen(pushMessage) > 255)
      pushMessage = StringSubstr(message, 0, 252) + "...";

   if(!SendNotification(pushMessage))
   {
      int error = GetLastError();
      if(EnableDebugMode)
         Print("[DEBUG] Push notification failed, error: ", error);
   }
}

//+------------------------------------------------------------------+
//| Send email alert                                                 |
//+------------------------------------------------------------------+
void SendEmailAlert(ENUM_ALERT_TYPE alertType, string message)
{
   // Check if email is configured
   if(!TerminalInfoInteger(TERMINAL_EMAIL_ENABLED))
   {
      if(EnableDebugMode)
         Print("[DEBUG] Email not configured in terminal settings");
      return;
   }

   string subject = StringFormat("%s Alert - %s - %s",
                                 EAName,
                                 GetAlertPrefix(alertType),
                                 Symbol());

   string body = StringFormat(
      "═══════════════════════════════════════════\n"
      "         %s TRADING ALERT\n"
      "═══════════════════════════════════════════\n\n"
      "Alert Type: %s\n"
      "Symbol: %s\n"
      "Timeframe: %s\n"
      "Server Time: %s\n"
      "Account: %s\n\n"
      "───────────────────────────────────────────\n"
      "MESSAGE:\n"
      "───────────────────────────────────────────\n"
      "%s\n\n"
      "───────────────────────────────────────────\n"
      "ACCOUNT STATUS:\n"
      "───────────────────────────────────────────\n"
      "Balance: %.2f %s\n"
      "Equity: %.2f %s\n"
      "Today's P/L: %.2f %s\n"
      "Open Positions: %d\n"
      "Today's Trades: %d\n\n"
      "═══════════════════════════════════════════\n"
      "This is an automated message from %s\n"
      "═══════════════════════════════════════════\n",
      EAName,
      GetAlertPrefix(alertType),
      Symbol(),
      GetTimeframeString(Period()),
      TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS),
      AccountInfoString(ACCOUNT_NAME),
      message,
      AccountInfoDouble(ACCOUNT_BALANCE),
      AccountInfoString(ACCOUNT_CURRENCY),
      AccountInfoDouble(ACCOUNT_EQUITY),
      AccountInfoString(ACCOUNT_CURRENCY),
      TodayProfit,
      AccountInfoString(ACCOUNT_CURRENCY),
      PositionsTotal(),
      TodayTrades,
      EAName
   );

   if(!SendMail(subject, body))
   {
      int error = GetLastError();
      if(EnableDebugMode)
         Print("[DEBUG] Email send failed, error: ", error);
   }
}

//+------------------------------------------------------------------+
//| Alert: IB Formed                                                 |
//+------------------------------------------------------------------+
void AlertIBFormed()
{
   string message = StringFormat(
      "Initial Balance Formed | High: %.5f | Low: %.5f | Range: %.1f pips",
      IBHigh, IBLow, (IBHigh - IBLow) / PipValue
   );

   string additionalInfo = StringFormat(
      "Mid: %.5f | ATR: %.5f",
      IBMidpoint, GetATRValue()
   );

   SendAlert(ALERT_IB_FORMED, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Breakout                                                  |
//+------------------------------------------------------------------+
void AlertBreakout(int direction, double breakPrice)
{
   string dirStr = (direction > 0) ? "BULLISH (Above High)" : "BEARISH (Below Low)";
   string levelStr = (direction > 0) ? DoubleToString(IBHigh, (int)symbolInfo.Digits())
                                      : DoubleToString(IBLow, (int)symbolInfo.Digits());

   string message = StringFormat(
      "%s Breakout | Break Price: %.5f | IB Level: %s",
      dirStr, breakPrice, levelStr
   );

   string additionalInfo = StringFormat(
      "IB Range: %.1f pips | Current Spread: %.1f",
      (IBHigh - IBLow) / PipValue,
      symbolInfo.Spread()
   );

   SendAlert(ALERT_BREAKOUT, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Trade Entry                                               |
//+------------------------------------------------------------------+
void AlertTradeEntry(int direction, double entryPrice, double sl, double tp, double lots)
{
   string dirStr = (direction > 0) ? "BUY" : "SELL";

   string message = StringFormat(
      "%s Entry | Price: %.5f | Lots: %.2f",
      dirStr, entryPrice, lots
   );

   double slPips = MathAbs(entryPrice - sl) / PipValue;
   double tpPips = MathAbs(tp - entryPrice) / PipValue;

   string additionalInfo = StringFormat(
      "SL: %.5f (%.1f pips) | TP: %.5f (%.1f pips) | Risk/Reward: 1:%.2f",
      sl, slPips, tp, tpPips, (tpPips > 0 && slPips > 0) ? tpPips/slPips : 0
   );

   SendAlert(ALERT_TRADE_ENTRY, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Trade Exit                                                |
//+------------------------------------------------------------------+
void AlertTradeExit(string exitReason, double profit, double entryPrice, double exitPrice)
{
   string profitStr = (profit >= 0) ? "+" : "";

   string message = StringFormat(
      "Position Closed | P/L: %s%.2f %s | Reason: %s",
      profitStr, profit, AccountInfoString(ACCOUNT_CURRENCY), exitReason
   );

   double pips = MathAbs(exitPrice - entryPrice) / PipValue;

   string additionalInfo = StringFormat(
      "Entry: %.5f | Exit: %.5f | Move: %.1f pips | Today's P/L: %.2f",
      entryPrice, exitPrice, pips, TodayProfit
   );

   SendAlert(ALERT_TRADE_EXIT, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Daily Profit Target Hit                                   |
//+------------------------------------------------------------------+
void AlertDailyTargetHit()
{
   string message = StringFormat(
      "Daily Profit Target Reached! | Profit: %.2f %s | Target: %.2f",
      TodayProfit, AccountInfoString(ACCOUNT_CURRENCY), DailyProfitTarget
   );

   string additionalInfo = StringFormat(
      "Trades Today: %d | Wins: %d | Losses: %d | Win Rate: %.1f%%",
      TodayTrades, TodayWins, TodayLosses,
      (TodayTrades > 0) ? (double)TodayWins / TodayTrades * 100 : 0
   );

   SendAlert(ALERT_DAILY_TARGET, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Daily Loss Limit Hit                                      |
//+------------------------------------------------------------------+
void AlertDailyLossHit()
{
   string message = StringFormat(
      "Daily Loss Limit Hit! | Loss: %.2f %s | Limit: %.2f",
      TodayProfit, AccountInfoString(ACCOUNT_CURRENCY), DailyLossLimit
   );

   string additionalInfo = StringFormat(
      "Trades Today: %d | Wins: %d | Losses: %d | Trading Halted",
      TodayTrades, TodayWins, TodayLosses
   );

   SendAlert(ALERT_DAILY_LOSS, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Drawdown Limit Hit                                        |
//+------------------------------------------------------------------+
void AlertDrawdownHit(double currentDrawdown)
{
   string message = StringFormat(
      "Drawdown Limit Reached! | Current DD: %.2f%% | Limit: %.2f%%",
      currentDrawdown, MaxDailyDrawdownPercent
   );

   string additionalInfo = StringFormat(
      "Equity: %.2f | Balance: %.2f | Floating P/L: %.2f",
      AccountInfoDouble(ACCOUNT_EQUITY),
      AccountInfoDouble(ACCOUNT_BALANCE),
      AccountInfoDouble(ACCOUNT_PROFIT)
   );

   SendAlert(ALERT_DRAWDOWN, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Retest Occurred                                           |
//+------------------------------------------------------------------+
void AlertRetest(int direction, double retestPrice)
{
   string levelStr = (direction > 0) ? "IB High" : "IB Low";
   double level = (direction > 0) ? IBHigh : IBLow;

   string message = StringFormat(
      "Price Retesting %s | Retest Price: %.5f | Level: %.5f",
      levelStr, retestPrice, level
   );

   string additionalInfo = StringFormat(
      "Distance from level: %.1f pips",
      MathAbs(retestPrice - level) / symbolInfo.Point() / 10
   );

   SendAlert(ALERT_RETEST, message, additionalInfo);
}

//+------------------------------------------------------------------+
//| Alert: Filter Blocked Trade                                      |
//+------------------------------------------------------------------+
void AlertFilterBlocked(string filterName, string reason)
{
   string message = StringFormat(
      "Trade Blocked by %s Filter | %s",
      filterName, reason
   );

   SendAlert(ALERT_FILTER_BLOCKED, message);
}

//+------------------------------------------------------------------+
//| Alert: Error                                                     |
//+------------------------------------------------------------------+
void AlertError(string errorMessage, int errorCode = 0)
{
   string message = errorMessage;

   if(errorCode != 0)
      message += StringFormat(" | Error Code: %d", errorCode);

   SendAlert(ALERT_ERROR, message);
}

//+------------------------------------------------------------------+
//| Quick alert for simple messages                                  |
//+------------------------------------------------------------------+
void QuickAlert(string message)
{
   if(UseSoundAlert)
      PlaySound(AlertSoundFile);

   if(UsePopupAlert)
      Alert(EAName, ": ", message);

   if(UsePushNotification)
   {
      string pushMsg = EAName + " | " + Symbol() + " | " + message;
      SendNotification(pushMsg);
   }

   Print("[ALERT] ", message);
}

//+------------------------------------------------------------------+
//| Test all alert methods (for debugging)                           |
//+------------------------------------------------------------------+
void TestAlerts()
{
   Print("═══════════════════════════════════════════");
   Print("Testing Alert System...");
   Print("═══════════════════════════════════════════");

   Print("Sound Alert Enabled: ", UseSoundAlert);
   Print("Popup Alert Enabled: ", UsePopupAlert);
   Print("Push Notification Enabled: ", UsePushNotification);
   Print("Email Alert Enabled: ", UseEmailAlert);
   Print("Terminal Notifications: ", TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED));
   Print("Terminal Email: ", TerminalInfoInteger(TERMINAL_EMAIL_ENABLED));

   // Test sound
   if(UseSoundAlert)
   {
      Print("Testing sound alert...");
      PlaySound("alert.wav");
   }

   // Test popup
   if(UsePopupAlert)
   {
      Print("Testing popup alert...");
      Alert(EAName, " - Test Alert - All systems operational!");
   }

   // Test push notification
   if(UsePushNotification && TerminalInfoInteger(TERMINAL_NOTIFICATIONS_ENABLED))
   {
      Print("Testing push notification...");
      SendNotification(EAName + " - Test notification from " + Symbol());
   }

   Print("═══════════════════════════════════════════");
   Print("Alert System Test Complete");
   Print("═══════════════════════════════════════════");
}

//+------------------------------------------------------------------+
//| Get alert statistics                                             |
//+------------------------------------------------------------------+
string GetAlertSettingsInfo()
{
   string info = "Alert Settings:\n";
   info += "Sound: " + (UseSoundAlert ? "ON" : "OFF") + "\n";
   info += "Popup: " + (UsePopupAlert ? "ON" : "OFF") + "\n";
   info += "Push: " + (UsePushNotification ? "ON" : "OFF") + "\n";
   info += "Email: " + (UseEmailAlert ? "ON" : "OFF") + "\n";
   info += "\nEnabled Triggers:\n";
   info += "IB Formed: " + (AlertOnIBFormed ? "YES" : "NO") + "\n";
   info += "Breakout: " + (AlertOnBreakout ? "YES" : "NO") + "\n";
   info += "Entry: " + (AlertOnEntry ? "YES" : "NO") + "\n";
   info += "Exit: " + (AlertOnExit ? "YES" : "NO") + "\n";
   info += "Daily Target: " + (AlertOnDailyTarget ? "YES" : "NO") + "\n";
   info += "Daily Loss: " + (AlertOnDailyLoss ? "YES" : "NO") + "\n";
   info += "Drawdown: " + (AlertOnDrawdown ? "YES" : "NO");

   return info;
}

//+------------------------------------------------------------------+
//|                                                                  |
//|                    PHASE 10: LOGGING & REPORTING                 |
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//| Initialize logging system                                        |
//+------------------------------------------------------------------+
void InitializeLogging()
{
   if(!EnableFileLogging && !LogTradesToCSV)
      return;

   //--- Create log file
   if(EnableFileLogging)
   {
      string logPath = StringFormat("%s_%s_%s.log",
                                    LogFileName,
                                    _Symbol,
                                    TimeToString(TimeCurrent(), TIME_DATE));
      StringReplace(logPath, ".", "_");
      StringReplace(logPath, ":", "-");

      LogFileHandle = FileOpen(logPath, FILE_WRITE|FILE_TXT|FILE_ANSI|FILE_SHARE_READ);

      if(LogFileHandle != INVALID_HANDLE)
      {
         WriteLogHeader();
         LogMessage("Logging system initialized");
      }
      else
      {
         Print("Warning: Could not create log file: ", logPath);
      }
   }

   //--- Create CSV trade log
   if(LogTradesToCSV)
   {
      string csvPath = StringFormat("%s_%s_Trades.csv", LogFileName, _Symbol);

      //--- Check if file exists to determine if we need header
      bool fileExists = FileIsExist(csvPath);

      CSVFileHandle = FileOpen(csvPath, FILE_READ|FILE_WRITE|FILE_CSV|FILE_ANSI|FILE_SHARE_READ, ',');

      if(CSVFileHandle != INVALID_HANDLE)
      {
         //--- Move to end of file to append
         FileSeek(CSVFileHandle, 0, SEEK_END);

         //--- Write header if new file
         if(!fileExists || FileSize(CSVFileHandle) == 0)
         {
            WriteCSVHeader();
         }
      }
      else
      {
         Print("Warning: Could not create CSV file: ", csvPath);
      }
   }
}

//+------------------------------------------------------------------+
//| Write log file header                                            |
//+------------------------------------------------------------------+
void WriteLogHeader()
{
   if(LogFileHandle == INVALID_HANDLE)
      return;

   FileWriteString(LogFileHandle, "═══════════════════════════════════════════════════════════════\n");
   FileWriteString(LogFileHandle, StringFormat("         %s Trading Log\n", EAName));
   FileWriteString(LogFileHandle, "═══════════════════════════════════════════════════════════════\n");
   FileWriteString(LogFileHandle, StringFormat("Symbol: %s\n", _Symbol));
   FileWriteString(LogFileHandle, StringFormat("Timeframe: %s\n", EnumToString(Period())));
   FileWriteString(LogFileHandle, StringFormat("Account: %s (%d)\n",
                   AccountInfoString(ACCOUNT_NAME),
                   AccountInfoInteger(ACCOUNT_LOGIN)));
   FileWriteString(LogFileHandle, StringFormat("Server: %s\n", AccountInfoString(ACCOUNT_SERVER)));
   FileWriteString(LogFileHandle, StringFormat("Balance: %.2f %s\n",
                   AccountInfoDouble(ACCOUNT_BALANCE),
                   AccountInfoString(ACCOUNT_CURRENCY)));
   FileWriteString(LogFileHandle, StringFormat("Entry Mode: %s\n", EnumToString(EntryMode)));
   FileWriteString(LogFileHandle, StringFormat("Start Time: %s\n",
                   TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS)));
   FileWriteString(LogFileHandle, "═══════════════════════════════════════════════════════════════\n\n");

   FileFlush(LogFileHandle);
}

//+------------------------------------------------------------------+
//| Write CSV header                                                 |
//+------------------------------------------------------------------+
void WriteCSVHeader()
{
   if(CSVFileHandle == INVALID_HANDLE)
      return;

   FileWrite(CSVFileHandle,
             "Date",
             "Time",
             "Symbol",
             "Type",
             "Direction",
             "Lots",
             "EntryPrice",
             "ExitPrice",
             "StopLoss",
             "TakeProfit",
             "Profit",
             "Commission",
             "Swap",
             "TotalPL",
             "Duration",
             "ExitReason",
             "IBHigh",
             "IBLow",
             "EntryMode",
             "Comment");

   FileFlush(CSVFileHandle);
}

//+------------------------------------------------------------------+
//| Log message to file                                              |
//+------------------------------------------------------------------+
void LogMessage(string message, bool printAlso = true)
{
   string timestamp = TimeToString(TimeCurrent(), TIME_DATE|TIME_SECONDS);
   string logLine = StringFormat("[%s] %s\n", timestamp, message);

   if(LogFileHandle != INVALID_HANDLE)
   {
      FileWriteString(LogFileHandle, logLine);
      FileFlush(LogFileHandle);
   }

   if(printAlso)
   {
      Print(message);
   }
}

//+------------------------------------------------------------------+
//| Log debug message (only in debug mode)                           |
//+------------------------------------------------------------------+
void LogDebug(string message)
{
   if(!EnableDebugMode)
      return;

   LogMessage("[DEBUG] " + message, true);
}

//+------------------------------------------------------------------+
//| Log trade to CSV file                                            |
//+------------------------------------------------------------------+
void LogTradeToCSV(ulong ticket, string direction, double lots,
                   double entryPrice, double exitPrice,
                   double sl, double tp,
                   double profit, double commission, double swap,
                   datetime entryTime, datetime exitTime,
                   string exitReason, string comment)
{
   if(CSVFileHandle == INVALID_HANDLE)
      return;

   //--- Calculate duration
   int durationSecs = (int)(exitTime - entryTime);
   string duration = StringFormat("%02d:%02d:%02d",
                                  durationSecs / 3600,
                                  (durationSecs % 3600) / 60,
                                  durationSecs % 60);

   double totalPL = profit + commission + swap;

   FileWrite(CSVFileHandle,
             TimeToString(exitTime, TIME_DATE),
             TimeToString(exitTime, TIME_MINUTES),
             _Symbol,
             "Close",
             direction,
             DoubleToString(lots, 2),
             DoubleToString(entryPrice, (int)symbolInfo.Digits()),
             DoubleToString(exitPrice, (int)symbolInfo.Digits()),
             DoubleToString(sl, (int)symbolInfo.Digits()),
             DoubleToString(tp, (int)symbolInfo.Digits()),
             DoubleToString(profit, 2),
             DoubleToString(commission, 2),
             DoubleToString(swap, 2),
             DoubleToString(totalPL, 2),
             duration,
             exitReason,
             DoubleToString(IBHigh, (int)symbolInfo.Digits()),
             DoubleToString(IBLow, (int)symbolInfo.Digits()),
             EnumToString(EntryMode),
             comment);

   FileFlush(CSVFileHandle);
}

//+------------------------------------------------------------------+
//| Write daily summary to log                                       |
//+------------------------------------------------------------------+
void WriteDailySummaryToLog()
{
   if(!LogDailySummary || LogFileHandle == INVALID_HANDLE)
      return;

   FileWriteString(LogFileHandle, "\n═══════════════════════════════════════════════════════════════\n");
   FileWriteString(LogFileHandle, StringFormat("         DAILY SUMMARY - %s\n",
                   TimeToString(TimeCurrent(), TIME_DATE)));
   FileWriteString(LogFileHandle, "═══════════════════════════════════════════════════════════════\n");

   FileWriteString(LogFileHandle, StringFormat("Total Trades: %d\n", TodayTrades));
   FileWriteString(LogFileHandle, StringFormat("Wins: %d (%.1f%%)\n",
                   TodayWins, TodayTrades > 0 ? (double)TodayWins/TodayTrades*100 : 0));
   FileWriteString(LogFileHandle, StringFormat("Losses: %d (%.1f%%)\n",
                   TodayLosses, TodayTrades > 0 ? (double)TodayLosses/TodayTrades*100 : 0));
   FileWriteString(LogFileHandle, StringFormat("Net P/L: %.2f %s\n",
                   TodayProfit, AccountInfoString(ACCOUNT_CURRENCY)));

   double balance = AccountInfoDouble(ACCOUNT_BALANCE);
   double startBalance = TodayStartBalance > 0 ? TodayStartBalance : balance;
   double pctReturn = ((balance - startBalance) / startBalance) * 100;

   FileWriteString(LogFileHandle, StringFormat("Return: %.2f%%\n", pctReturn));
   FileWriteString(LogFileHandle, StringFormat("End Balance: %.2f %s\n",
                   balance, AccountInfoString(ACCOUNT_CURRENCY)));

   FileWriteString(LogFileHandle, "═══════════════════════════════════════════════════════════════\n\n");

   FileFlush(LogFileHandle);
}

//+------------------------------------------------------------------+
//| Log IB formation                                                 |
//+------------------------------------------------------------------+
void LogIBFormation()
{
   if(LogFileHandle == INVALID_HANDLE)
      return;

   string msg = StringFormat("IB FORMED | High: %.5f | Low: %.5f | Range: %.1f pips | Mid: %.5f",
                             IBHigh, IBLow, IBRange / PipValue, IBMidpoint);
   LogMessage(msg);
}

//+------------------------------------------------------------------+
//| Log trade entry                                                  |
//+------------------------------------------------------------------+
void LogTradeEntry(int direction, double price, double lots, double sl, double tp)
{
   if(LogFileHandle == INVALID_HANDLE)
      return;

   string dirStr = direction > 0 ? "BUY" : "SELL";
   string msg = StringFormat("TRADE ENTRY | %s | Price: %.5f | Lots: %.2f | SL: %.5f | TP: %.5f",
                             dirStr, price, lots, sl, tp);
   LogMessage(msg);
}

//+------------------------------------------------------------------+
//| Close log files                                                  |
//+------------------------------------------------------------------+
void CloseLogFiles()
{
   //--- Write daily summary before closing
   if(LogFileHandle != INVALID_HANDLE && LogDailySummary)
   {
      WriteDailySummaryToLog();
   }

   //--- Close log file
   if(LogFileHandle != INVALID_HANDLE)
   {
      LogMessage("Logging session ended");
      FileClose(LogFileHandle);
      LogFileHandle = INVALID_HANDLE;
   }

   //--- Close CSV file
   if(CSVFileHandle != INVALID_HANDLE)
   {
      FileClose(CSVFileHandle);
      CSVFileHandle = INVALID_HANDLE;
   }
}

//+------------------------------------------------------------------+
//| Get EA statistics summary                                        |
//+------------------------------------------------------------------+
string GetEAStatisticsSummary()
{
   string summary = "";

   summary += "═══════════════════════════════════════════════════════════════\n";
   summary += StringFormat("         %s STATISTICS\n", EAName);
   summary += "═══════════════════════════════════════════════════════════════\n";
   summary += StringFormat("Symbol: %s | Timeframe: %s\n", _Symbol, EnumToString(Period()));
   summary += StringFormat("Entry Mode: %s\n", EnumToString(EntryMode));
   summary += "───────────────────────────────────────────────────────────────\n";
   summary += "TODAY'S PERFORMANCE:\n";
   summary += StringFormat("  Trades: %d | Wins: %d | Losses: %d\n", TodayTrades, TodayWins, TodayLosses);
   summary += StringFormat("  Win Rate: %.1f%%\n", TodayTrades > 0 ? (double)TodayWins/TodayTrades*100 : 0);
   summary += StringFormat("  Net P/L: %.2f %s\n", TodayProfit, AccountInfoString(ACCOUNT_CURRENCY));
   summary += "───────────────────────────────────────────────────────────────\n";
   summary += "CURRENT STATUS:\n";
   summary += StringFormat("  IB Status: %s\n", GetIBStatusString());
   summary += StringFormat("  EA Status: %s\n", GetEAStatusString());
   summary += StringFormat("  Trading Allowed: %s\n", TradeAllowed ? "Yes" : "No");
   summary += "───────────────────────────────────────────────────────────────\n";
   summary += "ACCOUNT INFO:\n";
   summary += StringFormat("  Balance: %.2f %s\n",
              AccountInfoDouble(ACCOUNT_BALANCE), AccountInfoString(ACCOUNT_CURRENCY));
   summary += StringFormat("  Equity: %.2f %s\n",
              AccountInfoDouble(ACCOUNT_EQUITY), AccountInfoString(ACCOUNT_CURRENCY));
   summary += StringFormat("  Open Positions: %d\n", PositionsTotal());
   summary += "═══════════════════════════════════════════════════════════════\n";

   return summary;
}

//+------------------------------------------------------------------+
//| Get EA status string                                             |
//+------------------------------------------------------------------+
string GetEAStatusString()
{
   switch(EAStatus)
   {
      case EA_RUNNING: return "Running";
      case EA_PAUSED:  return "Paused";
      case EA_STOPPED: return "Stopped";
      default:         return "Unknown";
   }
}

//+------------------------------------------------------------------+
//| Print EA startup information                                     |
//+------------------------------------------------------------------+
void PrintStartupInfo()
{
   Print("═══════════════════════════════════════════════════════════════");
   Print("          ", EAName, " v1.00 INITIALIZED");
   Print("═══════════════════════════════════════════════════════════════");
   Print("Symbol: ", _Symbol, " | Timeframe: ", EnumToString(Period()));
   Print("Entry Mode: ", GetEntryModeString());
   Print("IB Period: ", IBStartTime, " (", IBDurationMinutes, " min) - ", EnumToString(IBTimezone));
   Print("───────────────────────────────────────────────────────────────");
   Print("RISK SETTINGS:");
   PrintFormat("  Lot Mode: %s | Risk: %.2f%% | Fixed Lot: %.2f",
               EnumToString(LotMode), RiskPercent, FixedLotSize);
   PrintFormat("  Max Positions: %d | Max Daily Trades: %d", MaxOpenPositions, MaxTradesPerDay);
   PrintFormat("  Daily Drawdown Limit: %.1f%% | Account DD Limit: %.1f%%",
               MaxDailyDrawdownPercent, MaxAccountDrawdownPercent);
   Print("───────────────────────────────────────────────────────────────");
   Print("FILTERS:");
   PrintFormat("  Volatility: %s | Trend: %s | Time: %s",
               UseVolatilityFilter ? "ON" : "OFF",
               UseTrendFilter ? "ON" : "OFF",
               UseTimeFilter ? "ON" : "OFF");
   PrintFormat("  Session: %s | Spread: %s | News: %s",
               EnumToString(SessionFilter),
               UseSpreadFilter ? "ON" : "OFF",
               UseNewsFilter ? "ON" : "OFF");
   Print("───────────────────────────────────────────────────────────────");
   Print("ALERTS:");
   PrintFormat("  Sound: %s | Popup: %s | Push: %s | Email: %s",
               UseSoundAlert ? "ON" : "OFF",
               UsePopupAlert ? "ON" : "OFF",
               UsePushNotification ? "ON" : "OFF",
               UseEmailAlert ? "ON" : "OFF");
   Print("═══════════════════════════════════════════════════════════════");
}

//+------------------------------------------------------------------+
