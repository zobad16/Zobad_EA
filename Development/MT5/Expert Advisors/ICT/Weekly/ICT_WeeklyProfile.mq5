//+------------------------------------------------------------------+
//|                                            ICT_WeeklyProfile.mq5 |
//|                                           Copyright 2025, Zobad. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, Zobad."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property description "ICT Weekly Profile EA - OSOK, 30 Pips Scalp, Silver Bullet"
#property strict

#include <Trade\Trade.mqh>

//=============================================================================
// ENUMERATIONS
//=============================================================================

// Trading mode
enum ENUM_TRADE_MODE
{
   MODE_AUTO,      // Automatic Trading
   MODE_MANUAL,    // Manual Confirmation Required
   MODE_VISUAL     // Visual Only (No Trading)
};

// Session start options
enum ENUM_SESSION_START
{
   SESSION_5PM,      // 5:00 PM ET (Forex)
   SESSION_6PM,      // 6:00 PM ET (Futures)
   SESSION_MIDNIGHT  // Midnight (00:00 NY)
};

// Trading model selection
enum ENUM_ICT_MODEL
{
   MODEL_OSOK,           // OSOK (50-75 pips)
   MODEL_30_PIPS,        // 30 Pips Scalp
   MODEL_SILVER_BULLET   // Silver Bullet
};

// Silver Bullet time windows
enum ENUM_SB_WINDOW
{
   SB_NONE,      // No Active Window
   SB_LONDON,    // London (3:00-4:00 AM EST)
   SB_NY_AM,     // NY AM (10:00-11:00 AM EST)
   SB_NY_PM      // NY PM (2:00-3:00 PM EST)
};

// Multi-model priority
enum ENUM_MODEL_PRIORITY
{
   PRIORITY_OSOK_FIRST,          // OSOK takes priority
   PRIORITY_30PIPS_FIRST,        // 30 Pips Scalp takes priority
   PRIORITY_SILVER_BULLET_FIRST, // Silver Bullet takes priority
   PRIORITY_FIRST_SIGNAL         // First signal wins
};

// Weekly bias
enum ENUM_WEEKLY_BIAS
{
   BIAS_BULLISH,   // Bullish - look for longs
   BIAS_BEARISH,   // Bearish - look for shorts
   BIAS_NEUTRAL    // Neutral - no clear direction
};

// Profile status
enum ENUM_PROFILE_STATUS
{
   STATUS_INACTIVE,      // Not yet applicable
   STATUS_POTENTIAL,     // Could be forming
   STATUS_ACTIVE,        // Currently forming
   STATUS_CONFIRMED,     // Confirmed for the week
   STATUS_INVALIDATED    // No longer valid
};

// Weekly profile types (12 profiles)
enum ENUM_WEEKLY_PROFILE
{
   PROFILE_NONE,             // No Profile Detected
   PROFILE_TUE_LOTW,         // Classic Tuesday Low of Week
   PROFILE_TUE_HOTW,         // Classic Tuesday High of Week
   PROFILE_WED_LOTW,         // Wednesday Low of Week
   PROFILE_WED_HOTW,         // Wednesday High of Week
   PROFILE_WED_BULL_REV,     // Wednesday Bullish Reversal
   PROFILE_WED_BEAR_REV,     // Wednesday Bearish Reversal
   PROFILE_THU_BULL_REV,     // Consolidation Thursday Bullish
   PROFILE_THU_BEAR_REV,     // Consolidation Thursday Bearish
   PROFILE_MWK_RALLY,        // Midweek Rally (Friday High)
   PROFILE_MWK_DECLINE,      // Midweek Decline (Friday Low)
   PROFILE_FRI_BULL_SD,      // Seek & Destroy Bullish Friday
   PROFILE_FRI_BEAR_SD       // Seek & Destroy Bearish Friday
};

// Kill zone type
enum ENUM_KILLZONE
{
   KZ_NONE,      // No Kill Zone
   KZ_ASIAN,     // Asian Session
   KZ_LONDON,    // London Session
   KZ_NY_AM,     // New York AM
   KZ_NY_LUNCH,  // NY Lunch (avoid)
   KZ_NY_PM      // New York PM
};

// PDA (Premium/Discount Array) types
enum ENUM_PDA_TYPE
{
   PDA_FVG = 0,              // Fair Value Gap
   PDA_ORDER_BLOCK = 1,      // Order Block
   PDA_BREAKER = 2,          // Breaker Block
   PDA_MITIGATION = 3,       // Mitigation Block
   PDA_REJECTION = 4,        // Rejection Block
   PDA_LIQUIDITY_VOID = 5,   // Liquidity Void
   PDA_VOLUME_IMBALANCE = 6  // Volume Imbalance
};

// HTF Bias determination method
enum ENUM_BIAS_METHOD
{
   BIAS_METHOD_SWING,        // Swing Structure (HH/HL, LL/LH)
   BIAS_METHOD_WEEKLY_CLOSE, // Previous Week Close
   BIAS_METHOD_COMBINED      // Combined (Swing + Close)
};

//=============================================================================
// 1. TRADING ENTRY TYPE (MOST IMPORTANT - TOP)
//=============================================================================
input group "═══ ENTRY TYPE ═══"
input ENUM_TRADE_MODE TradeMode = MODE_AUTO;           // Trading Mode
input ENUM_ICT_MODEL ActiveModel = MODEL_OSOK;         // Strategy Model
input bool TradeLongOnly = false;                       // Trade Long Only
input bool TradeShortOnly = false;                      // Trade Short Only
input bool RequireProfileAlignment = true;              // Only Trade When Profile Matches Bias

//=============================================================================
// 2. RISK MANAGEMENT (CONSOLIDATED - SIMPLE)
//=============================================================================
input group "═══ RISK MANAGEMENT ═══"
input double RiskPercent = 1.0;                         // Risk Per Trade (%)
input double FixedLotSize = 0.01;                       // Fixed Lot Size (if not using %)
input bool UseFixedLot = false;                         // Use Fixed Lot (true) or Risk % (false)
input int StopLossBuffer = 10;                          // SL Buffer Beyond Level (points)
input int MaxTradesPerDay = 1;                          // Max Trades Per Day
input int MaxTradesPerWeek = 3;                         // Max Trades Per Week

//=============================================================================
// 3. TAKE PROFIT / PARTIAL TP (UNIFIED FOR ALL MODELS)
//=============================================================================
input group "═══ TAKE PROFIT ═══"
input double TP1_Pips = 30;                             // First TP (pips) - Partial Close
input double TP2_Pips = 50;                             // Second TP (pips) - Final Target
input double TP3_Pips = 75;                             // Extended TP (pips) - Runner
input double PartialClose1_Percent = 50;                // % to Close at TP1
input double PartialClose2_Percent = 30;                // % to Close at TP2
input bool MoveToBreakeven = true;                      // Move SL to BE after TP1
input bool UseTrailingStop = false;                     // Trail Remaining Position
input int TrailingStopPips = 20;                        // Trailing Stop Distance (pips)

//=============================================================================
// 4. STRATEGY SETTINGS (MODEL-SPECIFIC)
//=============================================================================
input group "═══ OSOK SETTINGS (50-75 pips) ═══"
input bool OSOK_Enabled = true;                         // Enable OSOK Model
input bool OSOK_TradeMonday = true;                     // Trade Monday
input bool OSOK_TradeTuesday = true;                    // Trade Tuesday
input bool OSOK_TradeWednesday = true;                  // Trade Wednesday
input bool OSOK_TradeThursday = false;                  // Trade Thursday
input bool OSOK_TradeFriday = false;                    // Trade Friday

input group "═══ OSOK CONDITION TOGGLES ═══"
input bool OSOK_RequireWeeklyBias = true;               // Require Weekly Bias Determined
input bool OSOK_RequireMondayRange = true;              // Require Monday Range Formed
input bool OSOK_RequireKillZone = true;                 // Require Kill Zone Time
input bool OSOK_RequireLiquiditySweep = true;           // Require Liquidity Sweep
input bool OSOK_RequireMSS = true;                      // Require MSS/CHoCH Confirmed
input bool OSOK_RequireOTEZone = false;                 // Require Price in OTE Zone (optional)
input bool OSOK_RequireFVG = false;                     // Require FVG Present (optional)

input group "═══ OSOK ADVANCED FEATURES ═══"
input bool OSOK_EnableTurtleSoup = false;               // Enable Turtle Soup Entry (No MSS Required)
input int OSOK_TurtleSoupBars = 3;                      // Turtle Soup Reversal Bars
input bool OSOK_DetectPrevWeekSweep = true;             // Detect Previous Week H/L Sweep
input bool OSOK_DetectCurrentWeekSweep = false;         // Detect Current Week H/L Sweep

input group "═══ 30 PIPS SCALP SETTINGS ═══"
input bool Scalp30_Enabled = false;                     // Enable 30 Pips Scalp
input ENUM_TIMEFRAMES Scalp30_BiasTimeframe = PERIOD_D1;    // Bias Timeframe
input ENUM_TIMEFRAMES Scalp30_EntryTimeframe = PERIOD_M15;  // Entry Timeframe

input group "═══ SILVER BULLET SETTINGS ═══"
input bool SilverBullet_Enabled = false;                // Enable Silver Bullet
input bool SB_UseLondon = false;                        // London Window (3-4 AM EST)
input bool SB_UseNYAM = true;                           // NY AM Window (10-11 AM EST)
input bool SB_UseNYPM = false;                          // NY PM Window (2-3 PM EST)
input double SB_MinRange_Pips = 15;                     // Min Range to Liquidity (pips)
input bool SB_ShowTimeWindows = true;                   // Show Silver Bullet Time Windows on Chart
input color SB_WindowStartColor = clrYellow;            // Window Start Line Color
input color SB_WindowEndColor = clrOrange;              // Window End Line Color

//=============================================================================
// 5. TIMING & SESSIONS
//=============================================================================
input group "═══ SESSION TIMING ═══"
input ENUM_SESSION_START SessionStart = SESSION_5PM;    // Session Start Time
input int BrokerGMTOffset = 2;                          // Broker GMT Offset
input int LondonKZ_Start = 2;                           // London KZ Start (EST)
input int LondonKZ_End = 5;                             // London KZ End (EST)
input int NYKZ_Start = 8;                               // NY KZ Start (EST)
input int NYKZ_End = 11;                                // NY KZ End (EST)

//=============================================================================
// 6. DETECTION SETTINGS (FILTERS)
//=============================================================================
input group "═══ DETECTION FILTERS ═══"
input ENUM_TIMEFRAMES HTF_Bias = PERIOD_H4;             // Higher TF for Bias
input ENUM_TIMEFRAMES LTF_Entry = PERIOD_M5;            // Lower TF for Entry
input int SwingStrength = 3;                            // Swing Detection Strength
input double MinFVGSize_Points = 50;                    // Minimum FVG Size (points)
input int MinSweepWick_Points = 20;                     // Minimum Sweep Wick (points)
input double OTE_Start = 0.618;                         // OTE Start (Fib Level)
input double OTE_End = 0.79;                            // OTE End (Fib Level)

//=============================================================================
// 7. WEEKLY PROFILES DISPLAY
//=============================================================================
input group "═══ WEEKLY PROFILES ═══"
input bool ShowWeeklyProfiles = true;                   // Show Profile Dashboard
input bool MinimalWeeklyProfile = true;                 // Minimal Style (like AlgoCados TV)
input bool ShowPreviousWeeks = true;                    // Show Previous Weeks Levels
input int PreviousWeeksCount = 2;                       // Previous Weeks to Show (1-3)
input bool ShowPremiumDiscount = true;                  // Show Premium/Discount Zones
input bool ShowPOILines = true;                         // Show POI Lines (Daily H/L)
input bool ShowPOIBreachTime = true;                    // Show Breach Timestamps
input bool ShowSessionDividers = true;                  // Show Session Dividers
input bool ShowDailyOpens = true;                       // Show Daily Opens
input bool ExtendDailyOpens = true;                     // Extend Opens to Current Bar
input bool ShowWeekStartLine = true;                    // Show Week Start Vertical Line
input bool ShowMonthStartLine = true;                   // Show Month Start Vertical Line

//=============================================================================
// 7B. PDA MATRIX SETTINGS
//=============================================================================
input group "═══ PDA MATRIX ═══"
input bool   PDA_Enable              = true;            // Enable PDA Matrix
input int    PDA_LookbackDays        = 60;              // Lookback Period (days)
input ENUM_TIMEFRAMES PDA_Timeframe  = PERIOD_D1;       // Timeframe for PDA Detection

input group "═══ PDA TYPE TOGGLES ═══"
input bool   PDA_ShowFVG             = true;            // Show Fair Value Gaps
input bool   PDA_ShowOB              = true;            // Show Order Blocks
input bool   PDA_ShowBreaker         = true;            // Show Breaker Blocks
input bool   PDA_ShowMitigation      = true;            // Show Mitigation Blocks
input bool   PDA_ShowRejection       = true;            // Show Rejection Blocks
input bool   PDA_ShowLiquidityVoid   = true;            // Show Liquidity Voids
input bool   PDA_ShowVolumeImbalance = true;            // Show Volume Imbalances

input group "═══ PDA FILTERING ═══"
input ENUM_BIAS_METHOD BiasMethod    = BIAS_METHOD_COMBINED;  // HTF Bias Determination Method
input bool   PDA_FilterByHTFBias     = false;           // Filter: Show Only HTF-Aligned PDAs
input bool   PDA_FilterByDiscountPremium = true;        // Filter: Show Only Discount/Premium Zones
input bool   PDA_ShowMitigated       = false;           // Show Mitigated/Used Zones
input int    PDA_DisplayDays         = 20;              // Display Window (days) for unfilled zones
input int    PDA_MaxUnfilledPerType  = 10;              // Max Unfilled Zones Per PDA Type
input bool   PDA_BackfillOlder       = true;            // Backfill With Older Unfilled Zones
input double PDA_OverlapThreshold    = 0.7;             // Overlap % to Consider Duplicate (0.7=70%)
input bool   PDA_ShowDisplayWindowLines = true;         // Show Display Window Boundary Line
input color  PDA_DisplayWindowLineColor = clrDarkGray;  // Display Window Line Color

input group "═══ PDA NARRATIVE ═══"
input bool   PDA_ShowNarrativePanel    = true;          // Show PDA Entry Narrative Panel
input bool   PDA_SortByPriority        = true;          // Sort Zones by Priority (vs. Time)
input int    PDA_NarrativeTopZones     = 3;             // Number of Top Zones to Display

input group "═══ PDA BULLISH COLORS ═══"
input color  PDA_BullFVG_Color       = C'0,100,0';      // Bullish FVG (dark green)
input color  PDA_BullOB_Color        = C'0,128,0';      // Bullish OB (green)
input color  PDA_BullBreaker_Color   = C'50,205,50';    // Bullish Breaker (lime green)
input color  PDA_BullMitigation_Color= C'34,139,34';    // Bullish Mitigation (forest green)
input color  PDA_BullRejection_Color = C'0,255,127';    // Bullish Rejection (spring green)
input color  PDA_BullVoid_Color      = C'144,238,144';  // Bullish Liquidity Void (light green)
input color  PDA_BullVI_Color        = C'152,251,152';  // Bullish Volume Imbalance (pale green)

input group "═══ PDA BEARISH COLORS ═══"
input color  PDA_BearFVG_Color       = C'139,0,0';      // Bearish FVG (dark red)
input color  PDA_BearOB_Color        = C'178,34,34';    // Bearish OB (firebrick)
input color  PDA_BearBreaker_Color   = C'220,20,60';    // Bearish Breaker (crimson)
input color  PDA_BearMitigation_Color= C'205,92,92';    // Bearish Mitigation (indian red)
input color  PDA_BearRejection_Color = C'255,99,71';    // Bearish Rejection (tomato)
input color  PDA_BearVoid_Color      = C'255,160,122';  // Bearish Liquidity Void (light salmon)
input color  PDA_BearVI_Color        = C'250,128,114';  // Bearish Volume Imbalance (salmon)

input group "═══ PDA DISPLAY SETTINGS ═══"
input int    PDA_BorderWidth         = 1;               // Border Line Width
input bool   PDA_ExtendZones         = true;            // Extend Zones to Current Bar
input bool   PDA_ShowLabels          = true;            // Show PDA Type Labels

//=============================================================================
// 8. VISUAL COLORS & STYLES
//=============================================================================
input group "═══ COLORS ═══"
input color BullishColor = clrLime;                     // Bullish Elements
input color BearishColor = clrRed;                      // Bearish Elements
input color MondayColor = clrGray;                      // Monday Session
input color TuesdayColor = clrDodgerBlue;               // Tuesday Session
input color WednesdayColor = clrGold;                   // Wednesday Session
input color ThursdayColor = clrOrange;                  // Thursday Session
input color FridayColor = clrMagenta;                   // Friday Session
input color EquilibriumColor = clrWhite;                // Equilibrium Line
input color PremiumZoneColor = clrMaroon;               // Premium Zone
input color DiscountZoneColor = clrDarkGreen;           // Discount Zone
input color WeekStartColor = clrYellow;                 // Week Start Line
input color MonthStartColor = clrAqua;                  // Month Start Line

//=============================================================================
// 9. DASHBOARD & CHECKLIST
//=============================================================================
input group "═══ DASHBOARD ═══"
input bool ShowDashboard = true;                        // Show Dashboard
input bool ShowProfilesTable = true;                    // Show 12 Profiles Table
input bool ShowConditionsChecklist = true;              // Show Entry Conditions
input bool ShowAllModelConditions = false;              // Show All Models (or just active)
input bool ShowHTFNarrative = true;                     // Show HTF Narrative Panel
input bool ShowManualButtons = true;                    // Show Buy/Sell Buttons
input int DashboardX = 10;                              // Dashboard X Position
input int DashboardY = 30;                              // Dashboard Y Position
input int DashboardFontSize = 10;                       // Font Size
input color DashboardBgColor = C'20,20,30';             // Background Color

input group "═══ HTF NARRATIVE ═══"
input int HTFNarrative_Lookback = 20;                   // Bars for Swing Detection
input bool HTFNarrative_ShowLevels = true;              // Show PWH/PWL Levels
input color DashboardTextColor = clrWhite;              // Text Color
input color ConditionMetColor = clrLime;                // Condition Met (green)
input color ConditionPendingColor = clrGray;            // Condition Pending (gray)

// Modern Dashboard Colors (Card-based design)
input color DashCardBgColor = C'38,38,48';              // Card Background (lighter for visibility)
input color DashCardBorderColor = C'65,65,80';          // Card Border (more visible)
input color DashAccentBlue = C'59,130,246';             // Accent Blue
input color DashSuccessGreen = C'34,197,94';            // Success Green (softer)
input color DashDangerRed = C'239,68,68';               // Danger Red (softer)
input color DashWarningYellow = C'234,179,8';           // Warning Yellow
input color DashTextPrimary = C'248,250,252';           // Primary Text
input color DashTextSecondary = C'148,163,184';         // Secondary Text

//=============================================================================
// 10. NEWS FILTER & CALENDAR
//=============================================================================
input group "═══ NEWS CALENDAR ═══"
input bool EnableNewsFilter = true;                     // Enable News Integration
input bool ShowNewsOnChart = true;                      // Show News Events on Chart
input bool ShowNewsInDashboard = true;                  // Show News in Dashboard
input bool PauseBeforeHighImpact = true;                // Pause Trading Before High Impact
input int MinutesBeforeNews = 30;                       // Minutes to Pause Before News
input int MinutesAfterNews = 15;                        // Minutes to Pause After News
input bool FilterHighImpact = true;                     // Filter High Impact Events
input bool FilterMediumImpact = false;                  // Filter Medium Impact Events
input bool UseNewsForProfilePrediction = true;          // Use News to Predict Weekly Profile
input bool DisableNewsInBacktest = true;                // Disable News Filter in Backtesting

//=============================================================================
// 11. MULTI-MODEL SETTINGS
//=============================================================================
input group "═══ MULTI-MODEL ═══"
input bool EnableMultiModel = false;                    // Enable Multiple Models Simultaneously
input ENUM_MODEL_PRIORITY ModelPriority = PRIORITY_OSOK_FIRST;  // Model Priority if Conflict
input bool AllowConflictingSignals = false;             // Allow Opposite Signals (risky)

//=============================================================================
// 12. ALERTS
//=============================================================================
input group "═══ ALERTS ═══"
input bool AlertOnSetup = true;                         // Alert When Setup Forms
input bool AlertOnEntry = true;                         // Alert On Trade Entry
input bool AlertOnProfileChange = true;                 // Alert on Profile Change
input bool AlertOnPOIBreach = true;                     // Alert on POI Breach
input bool AlertOnUpcomingNews = true;                  // Alert Before High Impact News
input bool EnablePushNotification = true;               // Push Notifications
input bool EnableEmailAlert = false;                    // Email Alerts
input bool EnableSoundAlert = true;                     // Sound Alerts

//=============================================================================
// DATA STRUCTURES
//=============================================================================

// Daily session data
struct DailySession
{
   datetime date;
   datetime openTime;
   double   openPrice;
   double   high;
   double   low;
   double   close;
   datetime highTime;
   datetime lowTime;
   bool     highBroken;       // Was high taken out?
   bool     lowBroken;        // Was low taken out?
   datetime highBreakTime;    // When was high broken?
   datetime lowBreakTime;     // When was low broken?
   int      dayOfWeek;        // 0=Sun, 1=Mon, 2=Tue, 3=Wed, 4=Thu, 5=Fri
};

// Weekly tracking data
struct WeeklyData
{
   datetime weekStart;
   double   weekHigh;
   double   weekLow;
   double   equilibrium;      // (weekHigh + weekLow) / 2
   int      highDay;          // 0=Mon, 1=Tue, 2=Wed, 3=Thu, 4=Fri
   int      lowDay;
   datetime highTime;
   datetime lowTime;
   DailySession days[5];      // Mon, Tue, Wed, Thu, Fri
   // Previous week data
   double   pwh;              // Previous Week High
   double   pwl;              // Previous Week Low
   double   pwc;              // Previous Week Close
   double   pwEquilibrium;    // Previous Week Equilibrium
   double   pwRange;          // Previous Week Range
};

// Historical week data for displaying previous weeks levels
struct HistoricalWeekData
{
   datetime weekStart;       // Start of the week
   double   high;            // Week high
   double   low;             // Week low
   double   equilibrium;     // (high + low) / 2
   int      weeksAgo;        // 1 = last week, 2 = two weeks ago, etc.
   bool     isValid;         // Data successfully loaded
   DailySession days[5];     // Mon, Tue, Wed, Thu, Fri daily data
};

// Profile tracking for each of the 12 profiles
struct ProfileStatus
{
   ENUM_WEEKLY_PROFILE profile;
   ENUM_PROFILE_STATUS status;
   string              name;
   string              description;
   double              keyLevel;
   datetime            confirmTime;
   bool                isBullish;
};

// Entry condition for checklist
struct EntryCondition
{
   string   name;             // "Weekly Bias Determined"
   bool     isMet;            // true/false
   string   value;            // "BULLISH" or "1.0920"
   datetime metTime;          // When condition was met
};

// Model checklist tracking
struct ModelChecklist
{
   ENUM_ICT_MODEL model;
   string modelName;
   EntryCondition conditions[10];
   int totalConditions;
   int metConditions;
   bool isReady;
};

// OSOK Setup tracking
struct OSOKSetup
{
   bool     isValid;
   bool     isBuy;
   double   mondayHigh;
   double   mondayLow;
   bool     liquiditySwept;
   bool     sweepWasBullish;  // Was Monday low swept (bullish) or high (bearish)
   datetime sweepTime;
   double   sweepCandleHigh;  // High of candle that swept (for BOS detection)
   double   sweepCandleLow;   // Low of candle that swept (for BOS detection)
   bool     bosConfirmed;     // BOS detected
   datetime bosTime;          // When BOS occurred
   double   bosPrice;         // Price level of BOS
   bool     mssConfirmed;
   datetime mssTime;
   double   entryPrice;
   double   stopLoss;
   double   tp1;              // 50 pips
   double   tp2;              // 75 pips
   string   reason;
};

// 30 Pips Scalp Setup
struct Scalp30Setup
{
   bool     isValid;
   bool     isBuy;
   bool     swingBroken;           // D1 swing break detected
   double   swingBreakPrice;
   bool     counterSwingFormed;    // Counter-swing after break
   double   counterSwingPrice;
   int      thirdCandleIndex;      // Index of 3rd candle
   double   thirdCandleHigh;
   double   thirdCandleLow;
   bool     thirdCandleSwept;      // Liquidity sweep of 3rd candle
   double   oteHigh;               // OTE zone boundaries
   double   oteLow;
   bool     priceInOTE;
   bool     mssConfirmed;
   double   entryPrice;
   double   stopLoss;
   double   takeProfit;
};

// Silver Bullet Setup
struct SilverBulletSetup
{
   bool     isValid;
   bool     isBuy;
   bool     inWindow;              // Inside Silver Bullet time window
   ENUM_SB_WINDOW activeWindow;
   double   liquidityTarget;       // PDH, PDL, or session H/L
   string   liquidityType;         // "PDH", "PDL", "Session High", etc.
   bool     displacementOccurred;
   bool     htfFVGFormed;          // Higher TF FVG
   double   htfFVGHigh;
   double   htfFVGLow;
   bool     priceInFVG;            // Price traded into FVG
   bool     ltfFVGFormed;          // Lower TF FVG for entry
   double   rangeToLiquidity;      // Distance to target in pips
   bool     rangeValid;            // Range > min pips
   double   entryPrice;
   double   stopLoss;
   double   takeProfit;
};

// Order Block structure
struct OrderBlock
{
   bool     isValid;
   bool     isBullish;        // Bullish or Bearish OB
   double   high;             // OB zone high
   double   low;              // OB zone low
   datetime time;             // When OB formed
   bool     tested;           // Has price returned to OB?
   int      candleIndex;      // Bar index of OB candle
};

// News event structure
struct NewsEvent
{
   ulong    id;
   string   name;              // "Non-Farm Payrolls"
   string   currency;          // "USD"
   datetime time;              // Release time
   int      importance;        // 0=Low, 1=Med, 2=High
   int      dayOfWeek;         // 0=Sun, 1=Mon, ... 5=Fri
   double   forecast;          // Expected value
   double   previous;          // Previous value
   double   actual;            // Actual (after release)
   bool     isReleased;        // Has it been released?
};

// Weekly news schedule
struct WeeklyNewsSchedule
{
   NewsEvent events[20];       // Max 20 events this week
   int       eventCount;
   int       highImpactDays;   // Bitmask: Mon=1, Tue=2, Wed=4, Thu=8, Fri=16
   bool      hasNFP;           // NFP this week?
   bool      hasFOMC;          // FOMC this week?
   bool      hasCPI;           // CPI this week?
   ENUM_WEEKLY_PROFILE predictedProfile;  // Based on news
};

// FVG structure
struct FVG
{
   double   high;
   double   low;
   datetime time;
   int      barIndex;
   bool     isBullish;
   bool     isMitigated;
   datetime mitigatedTime;
};

// Swing point structure
struct SwingPoint
{
   double   price;
   datetime time;
   int      barIndex;
   bool     isHigh;           // true = swing high, false = swing low
   bool     isBroken;
};

// PDA Zone structure
struct PDAZone
{
   bool           isValid;
   ENUM_PDA_TYPE  type;
   bool           isBullish;
   double         priceHigh;
   double         priceLow;
   datetime       timeStart;
   datetime       timeEnd;
   bool           isMitigated;
   bool           isHTFAligned;    // Matches HTF bias
   bool           shouldDisplay;   // Selected for display after filtering
   string         objectName;      // For chart objects
   int            priority;        // Priority score for ranking (0-25)
};

// PDA Matrix container
struct PDAMatrix
{
   PDAZone  fvgZones[100];
   int      fvgCount;

   PDAZone  obZones[100];
   int      obCount;

   PDAZone  breakerZones[50];
   int      breakerCount;

   PDAZone  mitigationZones[50];
   int      mitigationCount;

   PDAZone  rejectionZones[50];
   int      rejectionCount;

   PDAZone  liquidityVoidZones[50];
   int      liquidityVoidCount;

   PDAZone  volumeImbalanceZones[100];
   int      viCount;
};

//=============================================================================
// GLOBAL VARIABLES
//=============================================================================

// Trade management
CTrade trade;
string EA_PREFIX = "ICT_WP_";
int MagicNumber = 202501;

// Weekly and daily tracking
WeeklyData g_weeklyData;
HistoricalWeekData g_historicalWeeks[3];  // Up to 3 previous weeks
ProfileStatus g_profiles[13];        // 12 profiles + NONE
ENUM_WEEKLY_BIAS g_weeklyBias = BIAS_NEUTRAL;
ENUM_WEEKLY_PROFILE g_activeProfile = PROFILE_NONE;

// Model setups
OSOKSetup g_osokSetup;
OrderBlock g_osokOB;          // OB for OSOK setup
Scalp30Setup g_scalp30Setup;
SilverBulletSetup g_sbSetup;

// Model checklists
ModelChecklist g_osokChecklist;
ModelChecklist g_scalp30Checklist;
ModelChecklist g_sbChecklist;

// News
WeeklyNewsSchedule g_newsSchedule;
bool g_newsAvailable = false;
datetime g_lastNewsCheck = 0;

// Session tracking
datetime g_lastSessionCheck = 0;
datetime g_currentSessionStart = 0;
int g_currentDayOfWeek = -1;
bool g_isNewSession = false;
bool g_isNewWeek = false;

// Trading state
int g_tradesToday = 0;
int g_tradesThisWeek = 0;
datetime g_lastTradeDate = 0;
bool g_tradingPaused = false;
string g_pauseReason = "";

// Symbol info
double g_point;
double g_pipValue;
int g_digits;
double g_tickSize;
double g_lotStep;
double g_minLot;
double g_maxLot;

// Dashboard object names
string g_dashboardObjects[];

// Dashboard position (for dragging)
int g_dashboardX = 10;
int g_dashboardY = 30;

// Chart change detection
string g_currentSymbol = "";
ENUM_TIMEFRAMES g_currentTimeframe = PERIOD_CURRENT;

// HTF Narrative data
struct HTFNarrative
{
   ENUM_WEEKLY_BIAS monthlyBias;
   ENUM_WEEKLY_BIAS weeklyBias;
   ENUM_WEEKLY_BIAS dailyBias;
   string           zone;              // "PREMIUM", "DISCOUNT", "EQUILIBRIUM"
   double           zonePercent;       // 0.0 to 1.0
   double           nearestBSL;        // Buy-side liquidity
   double           nearestSSL;        // Sell-side liquidity
   double           monthlyHigh;
   double           monthlyLow;
   datetime         lastUpdate;
};
HTFNarrative g_htfNarrative;
datetime g_lastHTFUpdate = 0;

// PDA Matrix
PDAMatrix g_pdaMatrix;
datetime g_lastPDAUpdate = 0;

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize symbol info
   g_point = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   g_digits = (int)SymbolInfoInteger(_Symbol, SYMBOL_DIGITS);
   g_tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);
   g_lotStep = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   g_minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   g_maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   // Calculate pip value based on symbol
   if(g_digits == 3 || g_digits == 5)
      g_pipValue = g_point * 10;
   else
      g_pipValue = g_point;

   // Initialize trade object
   trade.SetExpertMagicNumber(MagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_IOC);

   // Initialize dashboard position from input
   g_dashboardX = DashboardX;
   g_dashboardY = DashboardY;

   // Initialize chart tracking for change detection
   g_currentSymbol = _Symbol;
   g_currentTimeframe = (ENUM_TIMEFRAMES)Period();

   // Initialize profiles
   InitializeProfiles();

   // Initialize checklists
   InitializeChecklists();

   // Load weekly data (handles mid-week initialization)
   LoadWeeklyData();

   // Load news if enabled
   if(EnableNewsFilter && !MQLInfoInteger(MQL_TESTER))
      LoadWeeklyNews();

   // Create timer for periodic updates
   EventSetTimer(1);

   // Draw initial dashboard and chart elements
   if(ShowDashboard)
      DrawDashboard();

   DrawChartElements();

   // Initialize and scan PDA Matrix
   if(PDA_Enable)
   {
      ZeroMemory(g_pdaMatrix);
      ScanPDAMatrix();
   }

   Print("ICT Weekly Profile EA initialized successfully");
   Print("Active Model: ", EnumToString(ActiveModel));
   Print("Trade Mode: ", EnumToString(TradeMode));

   return(INIT_SUCCEEDED);
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   EventKillTimer();

   // Clean up PDA zones
   if(PDA_Enable)
      ClearPDAZones();

   DeleteAllObjects();
   Comment("");
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // Check for new session/week
   CheckSessionChange();

   // Check for new month (at midnight 00:00)
   static int g_lastMonth = 0;
   MqlDateTime currentDT;
   TimeToStruct(TimeCurrent(), currentDT);

   if(g_lastMonth != currentDT.mon)
   {
      // Month boundary crossed
      if(g_lastMonth != 0)  // Skip first initialization
      {
         Print("New month detected: ", currentDT.mon, "/", currentDT.year, " at 00:00");

         // Update monthly HTF levels
         GetMonthlyLevels();

         // Redraw month start lines
         DrawMonthStartLines();

         // Alert if enabled
         if(AlertOnProfileChange)
            Alert("ICT Weekly Profile: New month started - ", currentDT.mon, "/", currentDT.year);
      }

      g_lastMonth = currentDT.mon;
   }

   // Check for new daily bar to rescan PDA Matrix
   if(PDA_Enable)
   {
      datetime currentDayStart = iTime(_Symbol, PERIOD_D1, 0);
      if(currentDayStart != g_lastPDAUpdate)
      {
         ScanPDAMatrix();
         g_lastPDAUpdate = currentDayStart;
      }
   }

   // Update weekly data
   UpdateWeeklyData();

   // Update profile statuses
   UpdateProfileStatuses();

   // Check if trading is paused
   if(IsTradingPaused())
      return;

   // Only process on new bar to reduce CPU load
   static datetime lastBarTime = 0;
   datetime currentBarTime = iTime(_Symbol, PERIOD_CURRENT, 0);
   if(currentBarTime == lastBarTime)
      return;
   lastBarTime = currentBarTime;

   // Update model checklists
   UpdateAllChecklists();

   // Check for trade signals based on active model
   if(TradeMode != MODE_VISUAL)
   {
      CheckTradeSignals();
   }

   // Manage open trades
   ManageOpenTrades();

   // Update dashboard and chart elements
   if(ShowDashboard)
      DrawDashboard();

   // Draw chart visual elements
   DrawChartElements();
}

//+------------------------------------------------------------------+
//| Timer function                                                   |
//+------------------------------------------------------------------+
void OnTimer()
{
   // Periodic news check (every 5 minutes)
   if(EnableNewsFilter && !MQLInfoInteger(MQL_TESTER))
   {
      if(TimeCurrent() - g_lastNewsCheck > 300)
      {
         LoadWeeklyNews();
         g_lastNewsCheck = TimeCurrent();
      }
   }

   // Update dashboard and chart elements
   if(ShowDashboard)
      DrawDashboard();

   DrawChartElements();
}

//+------------------------------------------------------------------+
//| ChartEvent function                                              |
//+------------------------------------------------------------------+
void OnChartEvent(const int id,
                  const long &lparam,
                  const double &dparam,
                  const string &sparam)
{
   // Handle dashboard dragging
   if(id == CHARTEVENT_OBJECT_DRAG)
   {
      if(sparam == EA_PREFIX + "DashBG")
      {
         // Get new position after drag
         g_dashboardX = (int)ObjectGetInteger(0, sparam, OBJPROP_XDISTANCE);
         g_dashboardY = (int)ObjectGetInteger(0, sparam, OBJPROP_YDISTANCE);

         // Redraw dashboard at new position
         DrawDashboard();
         ChartRedraw();
      }
   }

   // Handle button clicks
   if(id == CHARTEVENT_OBJECT_CLICK)
   {
      if(sparam == EA_PREFIX + "BtnBuy")
      {
         // Reset button state
         ObjectSetInteger(0, EA_PREFIX + "BtnBuy", OBJPROP_STATE, false);
         ChartRedraw();

         // Execute manual buy
         ExecuteManualEntry(true);
      }
      else if(sparam == EA_PREFIX + "BtnSell")
      {
         // Reset button state
         ObjectSetInteger(0, EA_PREFIX + "BtnSell", OBJPROP_STATE, false);
         ChartRedraw();

         // Execute manual sell
         ExecuteManualEntry(false);
      }
   }

   // Handle chart symbol/timeframe changes
   if(id == CHARTEVENT_CHART_CHANGE)
   {
      string newSymbol = _Symbol;
      ENUM_TIMEFRAMES newTF = (ENUM_TIMEFRAMES)Period();

      if(newSymbol != g_currentSymbol || newTF != g_currentTimeframe)
      {
         // Symbol or timeframe changed - full redraw needed
         g_currentSymbol = newSymbol;
         g_currentTimeframe = newTF;

         // Clear all chart objects
         DeleteAllObjects();

         // Reload weekly data for new symbol/timeframe
         LoadWeeklyData();

         // Redraw everything
         UpdateProfileStatuses();
         DrawChartElements();
         DrawDashboard();

         Print("Chart changed to ", newSymbol, " ", EnumToString(newTF), " - objects redrawn");
         ChartRedraw();
      }
   }
}

//=============================================================================
// TIME & SESSION MANAGEMENT FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Get current EST hour from broker time                            |
//+------------------------------------------------------------------+
int GetESTHour()
{
   datetime brokerTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(brokerTime, dt);

   // Convert broker time to EST
   int estHour = dt.hour - BrokerGMTOffset - 5;  // EST = GMT-5

   // Handle DST (simplified - assumes US DST)
   // DST: 2nd Sunday March to 1st Sunday November
   if(dt.mon >= 3 && dt.mon <= 11)
   {
      if(dt.mon > 3 && dt.mon < 11)
         estHour += 1;  // EDT = GMT-4
      else if(dt.mon == 3 && dt.day >= 8)
         estHour += 1;
      else if(dt.mon == 11 && dt.day < 7)
         estHour += 1;
   }

   // Normalize hour
   if(estHour < 0) estHour += 24;
   if(estHour >= 24) estHour -= 24;

   return estHour;
}

//+------------------------------------------------------------------+
//| Get current day of week (0=Mon to 4=Fri for trading days)        |
//+------------------------------------------------------------------+
int GetTradingDayOfWeek()
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   // MQL5: 0=Sunday, 1=Monday, ... 6=Saturday
   // We want: 0=Monday, 1=Tuesday, ... 4=Friday
   if(dt.day_of_week == 0) return -1;  // Sunday
   if(dt.day_of_week == 6) return -1;  // Saturday
   return dt.day_of_week - 1;
}

//+------------------------------------------------------------------+
//| Check for session change                                         |
//+------------------------------------------------------------------+
void CheckSessionChange()
{
   int currentDay = GetTradingDayOfWeek();
   int estHour = GetESTHour();

   // Determine session start hour based on setting
   int sessionStartHour = 17;  // Default 5PM ET
   if(SessionStart == SESSION_6PM) sessionStartHour = 18;
   else if(SessionStart == SESSION_MIDNIGHT) sessionStartHour = 0;

   // Check for new session
   g_isNewSession = false;
   if(currentDay != g_currentDayOfWeek)
   {
      // Check if it's past session start
      if(estHour >= sessionStartHour || (sessionStartHour > 12 && estHour < 12))
      {
         g_isNewSession = true;

         // Check for new week (Monday after session start)
         if(currentDay == 0 && g_currentDayOfWeek != 0)
         {
            g_isNewWeek = true;
            OnNewWeek();
         }

         g_currentDayOfWeek = currentDay;
         OnNewSession();
      }
   }
}

//+------------------------------------------------------------------+
//| Handle new session                                               |
//+------------------------------------------------------------------+
void OnNewSession()
{
   // Reset daily trade count
   g_tradesToday = 0;

   // Initialize new day's session data
   int dayIndex = g_currentDayOfWeek;
   if(dayIndex >= 0 && dayIndex < 5)
   {
      g_weeklyData.days[dayIndex].date = TimeCurrent();
      g_weeklyData.days[dayIndex].openTime = TimeCurrent();
      g_weeklyData.days[dayIndex].openPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
      g_weeklyData.days[dayIndex].high = g_weeklyData.days[dayIndex].openPrice;
      g_weeklyData.days[dayIndex].low = g_weeklyData.days[dayIndex].openPrice;
      g_weeklyData.days[dayIndex].highBroken = false;
      g_weeklyData.days[dayIndex].lowBroken = false;
      g_weeklyData.days[dayIndex].dayOfWeek = dayIndex + 1;  // 1=Mon, 2=Tue, etc.
   }

   if(AlertOnProfileChange)
      SendAlert("New session started: Day " + IntegerToString(dayIndex + 1));
}

//+------------------------------------------------------------------+
//| Handle new week                                                  |
//+------------------------------------------------------------------+
void OnNewWeek()
{
   // Save previous week data
   g_weeklyData.pwh = g_weeklyData.weekHigh;
   g_weeklyData.pwl = g_weeklyData.weekLow;
   g_weeklyData.pwc = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   g_weeklyData.pwEquilibrium = (g_weeklyData.pwh + g_weeklyData.pwl) / 2;
   g_weeklyData.pwRange = g_weeklyData.pwh - g_weeklyData.pwl;

   // Reset weekly data
   g_weeklyData.weekStart = TimeCurrent();
   g_weeklyData.weekHigh = 0;
   g_weeklyData.weekLow = DBL_MAX;
   g_weeklyData.highDay = -1;
   g_weeklyData.lowDay = -1;

   // Reset all daily sessions
   for(int i = 0; i < 5; i++)
   {
      ZeroMemory(g_weeklyData.days[i]);
   }

   // Reset profile statuses
   for(int i = 0; i < 13; i++)
   {
      g_profiles[i].status = STATUS_INACTIVE;
      g_profiles[i].keyLevel = 0;
      g_profiles[i].confirmTime = 0;
   }

   // Reset trade count
   g_tradesThisWeek = 0;

   // Reset model setups
   ZeroMemory(g_osokSetup);
   ZeroMemory(g_scalp30Setup);
   ZeroMemory(g_sbSetup);

   // Reload news
   if(EnableNewsFilter && !MQLInfoInteger(MQL_TESTER))
      LoadWeeklyNews();

   Print("New week started. PWH: ", g_weeklyData.pwh, " PWL: ", g_weeklyData.pwl);
}

//+------------------------------------------------------------------+
//| Check if in kill zone                                            |
//+------------------------------------------------------------------+
ENUM_KILLZONE GetCurrentKillZone()
{
   int estHour = GetESTHour();

   // Asian session: 8PM - 12AM EST
   if(estHour >= 20 || estHour < 0)
      return KZ_ASIAN;

   // London session
   if(estHour >= LondonKZ_Start && estHour < LondonKZ_End)
      return KZ_LONDON;

   // NY AM session
   if(estHour >= NYKZ_Start && estHour < NYKZ_End)
      return KZ_NY_AM;

   // NY Lunch (avoid)
   if(estHour >= 12 && estHour < 13)
      return KZ_NY_LUNCH;

   // NY PM session
   if(estHour >= 14 && estHour < 16)
      return KZ_NY_PM;

   return KZ_NONE;
}

//+------------------------------------------------------------------+
//| Check if in Silver Bullet window                                 |
//+------------------------------------------------------------------+
ENUM_SB_WINDOW GetSilverBulletWindow()
{
   int estHour = GetESTHour();
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);
   int estMinute = dt.min;

   // London: 3:00-4:00 AM EST
   if(SB_UseLondon && estHour == 3)
      return SB_LONDON;

   // NY AM: 10:00-11:00 AM EST
   if(SB_UseNYAM && estHour == 10)
      return SB_NY_AM;

   // NY PM: 2:00-3:00 PM EST
   if(SB_UseNYPM && estHour == 14)
      return SB_NY_PM;

   return SB_NONE;
}

//+------------------------------------------------------------------+
//| Check if trading is allowed on current day (OSOK)                |
//+------------------------------------------------------------------+
bool IsOSOKTradingDay()
{
   int day = GetTradingDayOfWeek();

   switch(day)
   {
      case 0: return OSOK_TradeMonday;
      case 1: return OSOK_TradeTuesday;
      case 2: return OSOK_TradeWednesday;
      case 3: return OSOK_TradeThursday;
      case 4: return OSOK_TradeFriday;
   }
   return false;
}

//=============================================================================
// WEEKLY DATA TRACKING FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Load weekly data on initialization                               |
//+------------------------------------------------------------------+
void LoadWeeklyData()
{
   // Get current day
   int currentDay = GetTradingDayOfWeek();
   g_currentDayOfWeek = currentDay;

   // Load previous week data from history
   LoadPreviousWeekData();

   // Load current week data up to now
   LoadCurrentWeekData();

   // Determine initial profile statuses
   UpdateProfileStatuses();
}

//+------------------------------------------------------------------+
//| Load previous week high/low/close                                |
//+------------------------------------------------------------------+
void LoadPreviousWeekData()
{
   // Find previous week's Monday
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   // Go back to find last week
   datetime weekStart = currentTime - (dt.day_of_week * 86400) - (7 * 86400);

   // Get weekly candle data
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_W1, weekStart, 1, rates) > 0)
   {
      g_weeklyData.pwh = rates[0].high;
      g_weeklyData.pwl = rates[0].low;
      g_weeklyData.pwc = rates[0].close;
      g_weeklyData.pwEquilibrium = (g_weeklyData.pwh + g_weeklyData.pwl) / 2;
      g_weeklyData.pwRange = g_weeklyData.pwh - g_weeklyData.pwl;
   }

   // Load historical weeks data
   LoadHistoricalWeeksData();
}

//+------------------------------------------------------------------+
//| Load historical weeks data (up to 3 previous weeks)              |
//+------------------------------------------------------------------+
void LoadHistoricalWeeksData()
{
   // Initialize all historical weeks as invalid
   for(int i = 0; i < 3; i++)
   {
      g_historicalWeeks[i].isValid = false;
      g_historicalWeeks[i].weeksAgo = i + 1;
      for(int d = 0; d < 5; d++)
      {
         ZeroMemory(g_historicalWeeks[i].days[d]);
      }
   }

   // Get number of weeks to load (clamped to 1-3)
   int weeksToLoad = MathMin(MathMax(PreviousWeeksCount, 1), 3);

   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   // Calculate current week's start
   int daysFromMonday = dt.day_of_week - 1;
   if(dt.day_of_week == 0) daysFromMonday = 6;  // Sunday
   datetime currentWeekStart = currentTime - (daysFromMonday * 86400);

   // Load each historical week
   for(int week = 0; week < weeksToLoad; week++)
   {
      // Calculate the week start (1 week ago, 2 weeks ago, etc.)
      datetime targetWeekStart = currentWeekStart - ((week + 1) * 7 * 86400);

      // Get weekly candle data using the weekly timeframe
      MqlRates weekRates[];
      if(CopyRates(_Symbol, PERIOD_W1, targetWeekStart, 1, weekRates) > 0)
      {
         g_historicalWeeks[week].weekStart = weekRates[0].time;
         g_historicalWeeks[week].high = weekRates[0].high;
         g_historicalWeeks[week].low = weekRates[0].low;
         g_historicalWeeks[week].equilibrium = (weekRates[0].high + weekRates[0].low) / 2;
         g_historicalWeeks[week].weeksAgo = week + 1;
         g_historicalWeeks[week].isValid = true;

         // Load daily data for each day of this historical week
         LoadHistoricalWeekDailyData(week, weekRates[0].time);
      }
   }
}

//+------------------------------------------------------------------+
//| Load daily data for a historical week                            |
//+------------------------------------------------------------------+
void LoadHistoricalWeekDailyData(int weekIndex, datetime weekStart)
{
   if(weekIndex < 0 || weekIndex >= 3) return;

   // Weekly candle starts on Sunday in MT5, so we need to find Monday
   // Add 1 day to get to Monday if weekStart is Sunday
   MqlDateTime weekDt;
   TimeToStruct(weekStart, weekDt);

   datetime mondayStart = weekStart;
   if(weekDt.day_of_week == 0)  // Sunday
      mondayStart = weekStart + 86400;  // Add 1 day to get Monday

   // Calculate Friday end time (Monday + 5 days)
   datetime fridayEnd = mondayStart + (5 * 86400);

   // Request candles FROM Friday going BACKWARD - CopyRates with datetime goes backward
   // This gets Fri, Thu, Wed, Tue, Mon and possibly previous week days
   MqlRates rates[];
   ArraySetAsSeries(rates, false);  // Oldest first
   int copied = CopyRates(_Symbol, PERIOD_D1, fridayEnd, 7, rates);

   if(copied <= 0) return;

   // Map each candle to correct day slot by actual day_of_week
   for(int i = 0; i < copied; i++)
   {
      MqlDateTime rateDt;
      TimeToStruct(rates[i].time, rateDt);

      // Map MQL5 day_of_week to our index (Mon=0, Tue=1, Wed=2, Thu=3, Fri=4)
      int dayIndex = rateDt.day_of_week - 1;
      if(dayIndex < 0 || dayIndex > 4) continue;  // Skip weekend

      // Verify candle is within this week's boundaries (>= Monday and < Saturday)
      if(rates[i].time < mondayStart) continue;
      if(rates[i].time >= mondayStart + (6 * 86400)) continue;

      // Store data in correct slot
      g_historicalWeeks[weekIndex].days[dayIndex].date = rates[i].time;
      g_historicalWeeks[weekIndex].days[dayIndex].openTime = rates[i].time;
      g_historicalWeeks[weekIndex].days[dayIndex].openPrice = rates[i].open;
      g_historicalWeeks[weekIndex].days[dayIndex].high = rates[i].high;
      g_historicalWeeks[weekIndex].days[dayIndex].low = rates[i].low;
      g_historicalWeeks[weekIndex].days[dayIndex].close = rates[i].close;
      g_historicalWeeks[weekIndex].days[dayIndex].dayOfWeek = rateDt.day_of_week;
      g_historicalWeeks[weekIndex].days[dayIndex].highBroken = false;
      g_historicalWeeks[weekIndex].days[dayIndex].lowBroken = false;
      g_historicalWeeks[weekIndex].days[dayIndex].highBreakTime = 0;
      g_historicalWeeks[weekIndex].days[dayIndex].lowBreakTime = 0;
   }

   // Second pass: Check if each day's high/low was raided by subsequent days
   for(int dayIndex = 0; dayIndex < 4; dayIndex++)  // Don't check Friday (no subsequent days)
   {
      if(g_historicalWeeks[weekIndex].days[dayIndex].high == 0) continue;

      double dayHigh = g_historicalWeeks[weekIndex].days[dayIndex].high;
      double dayLow = g_historicalWeeks[weekIndex].days[dayIndex].low;

      // Check subsequent days in the same week
      for(int checkDay = dayIndex + 1; checkDay < 5; checkDay++)
      {
         if(g_historicalWeeks[weekIndex].days[checkDay].high == 0) continue;

         // Check if high was raided (subsequent day traded above this day's high)
         if(!g_historicalWeeks[weekIndex].days[dayIndex].highBroken &&
            g_historicalWeeks[weekIndex].days[checkDay].high > dayHigh)
         {
            g_historicalWeeks[weekIndex].days[dayIndex].highBroken = true;
            g_historicalWeeks[weekIndex].days[dayIndex].highBreakTime = g_historicalWeeks[weekIndex].days[checkDay].openTime;
         }

         // Check if low was raided (subsequent day traded below this day's low)
         if(!g_historicalWeeks[weekIndex].days[dayIndex].lowBroken &&
            g_historicalWeeks[weekIndex].days[checkDay].low < dayLow)
         {
            g_historicalWeeks[weekIndex].days[dayIndex].lowBroken = true;
            g_historicalWeeks[weekIndex].days[dayIndex].lowBreakTime = g_historicalWeeks[weekIndex].days[checkDay].openTime;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Load current week data                                           |
//+------------------------------------------------------------------+
void LoadCurrentWeekData()
{
   // Find this week's Monday
   datetime currentTime = TimeCurrent();
   MqlDateTime dt;
   TimeToStruct(currentTime, dt);

   int daysFromMonday = dt.day_of_week - 1;
   if(dt.day_of_week == 0) daysFromMonday = 6;  // Sunday

   datetime weekStart = currentTime - (daysFromMonday * 86400);
   g_weeklyData.weekStart = weekStart;

   // Initialize week high/low
   g_weeklyData.weekHigh = 0;
   g_weeklyData.weekLow = DBL_MAX;

   // Load daily data for each day of the week
   for(int i = 0; i <= g_currentDayOfWeek && i < 5; i++)
   {
      LoadDailyData(i);
   }

   // Calculate equilibrium
   if(g_weeklyData.weekHigh > 0 && g_weeklyData.weekLow < DBL_MAX)
      g_weeklyData.equilibrium = (g_weeklyData.weekHigh + g_weeklyData.weekLow) / 2;
}

//+------------------------------------------------------------------+
//| Load daily data for a specific day                               |
//+------------------------------------------------------------------+
void LoadDailyData(int dayIndex)
{
   if(dayIndex < 0 || dayIndex >= 5) return;

   // Calculate day start time
   datetime weekStart = g_weeklyData.weekStart;
   datetime dayStart = weekStart + (dayIndex * 86400);

   // Get daily candle
   MqlRates rates[];
   if(CopyRates(_Symbol, PERIOD_D1, dayStart, 1, rates) > 0)
   {
      g_weeklyData.days[dayIndex].date = rates[0].time;
      g_weeklyData.days[dayIndex].openTime = rates[0].time;
      g_weeklyData.days[dayIndex].openPrice = rates[0].open;
      g_weeklyData.days[dayIndex].high = rates[0].high;
      g_weeklyData.days[dayIndex].low = rates[0].low;
      g_weeklyData.days[dayIndex].close = rates[0].close;
      g_weeklyData.days[dayIndex].dayOfWeek = dayIndex + 1;

      // Update weekly high/low
      if(rates[0].high > g_weeklyData.weekHigh)
      {
         g_weeklyData.weekHigh = rates[0].high;
         g_weeklyData.highDay = dayIndex;
         g_weeklyData.highTime = rates[0].time;
      }
      if(rates[0].low < g_weeklyData.weekLow)
      {
         g_weeklyData.weekLow = rates[0].low;
         g_weeklyData.lowDay = dayIndex;
         g_weeklyData.lowTime = rates[0].time;
      }
   }
}

//+------------------------------------------------------------------+
//| Update weekly data on each tick                                  |
//+------------------------------------------------------------------+
void UpdateWeeklyData()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int dayIndex = g_currentDayOfWeek;

   if(dayIndex < 0 || dayIndex >= 5) return;

   // Update current day's high/low
   if(bid > g_weeklyData.days[dayIndex].high || g_weeklyData.days[dayIndex].high == 0)
   {
      g_weeklyData.days[dayIndex].high = bid;
      g_weeklyData.days[dayIndex].highTime = TimeCurrent();
   }
   if(bid < g_weeklyData.days[dayIndex].low || g_weeklyData.days[dayIndex].low == 0)
   {
      g_weeklyData.days[dayIndex].low = bid;
      g_weeklyData.days[dayIndex].lowTime = TimeCurrent();
   }

   // Update weekly high/low
   if(bid > g_weeklyData.weekHigh)
   {
      g_weeklyData.weekHigh = bid;
      g_weeklyData.highDay = dayIndex;
      g_weeklyData.highTime = TimeCurrent();
   }
   if(bid < g_weeklyData.weekLow)
   {
      g_weeklyData.weekLow = bid;
      g_weeklyData.lowDay = dayIndex;
      g_weeklyData.lowTime = TimeCurrent();
   }

   // Update equilibrium
   g_weeklyData.equilibrium = (g_weeklyData.weekHigh + g_weeklyData.weekLow) / 2;

   // Check for POI breaches
   CheckPOIBreaches();
}

//+------------------------------------------------------------------+
//| Check for POI breaches                                           |
//+------------------------------------------------------------------+
void CheckPOIBreaches()
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   int currentDay = g_currentDayOfWeek;

   // Check previous days' highs and lows
   for(int i = 0; i < currentDay; i++)
   {
      // Check if high was broken
      if(!g_weeklyData.days[i].highBroken && bid > g_weeklyData.days[i].high)
      {
         g_weeklyData.days[i].highBroken = true;
         g_weeklyData.days[i].highBreakTime = TimeCurrent();

         if(AlertOnPOIBreach)
         {
            string dayName = GetDayName(i);
            SendAlert(dayName + " high breached at " + DoubleToString(bid, g_digits));
         }
      }

      // Check if low was broken
      if(!g_weeklyData.days[i].lowBroken && bid < g_weeklyData.days[i].low)
      {
         g_weeklyData.days[i].lowBroken = true;
         g_weeklyData.days[i].lowBreakTime = TimeCurrent();

         if(AlertOnPOIBreach)
         {
            string dayName = GetDayName(i);
            SendAlert(dayName + " low breached at " + DoubleToString(bid, g_digits));
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Get day name from index                                          |
//+------------------------------------------------------------------+
string GetDayName(int dayIndex)
{
   switch(dayIndex)
   {
      case 0: return "Monday";
      case 1: return "Tuesday";
      case 2: return "Wednesday";
      case 3: return "Thursday";
      case 4: return "Friday";
   }
   return "Unknown";
}

//=============================================================================
// PROFILE DETECTION FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Initialize profile structures                                    |
//+------------------------------------------------------------------+
void InitializeProfiles()
{
   // PROFILE_NONE
   g_profiles[0].profile = PROFILE_NONE;
   g_profiles[0].name = "None";
   g_profiles[0].isBullish = false;

   // PROFILE_TUE_LOTW - Classic Tuesday Low of Week
   g_profiles[1].profile = PROFILE_TUE_LOTW;
   g_profiles[1].name = "Tue LOTW";
   g_profiles[1].description = "Tuesday forms weekly low";
   g_profiles[1].isBullish = true;

   // PROFILE_TUE_HOTW - Classic Tuesday High of Week
   g_profiles[2].profile = PROFILE_TUE_HOTW;
   g_profiles[2].name = "Tue HOTW";
   g_profiles[2].description = "Tuesday forms weekly high";
   g_profiles[2].isBullish = false;

   // PROFILE_WED_LOTW
   g_profiles[3].profile = PROFILE_WED_LOTW;
   g_profiles[3].name = "Wed LOTW";
   g_profiles[3].description = "Wednesday forms weekly low";
   g_profiles[3].isBullish = true;

   // PROFILE_WED_HOTW
   g_profiles[4].profile = PROFILE_WED_HOTW;
   g_profiles[4].name = "Wed HOTW";
   g_profiles[4].description = "Wednesday forms weekly high";
   g_profiles[4].isBullish = false;

   // PROFILE_WED_BULL_REV
   g_profiles[5].profile = PROFILE_WED_BULL_REV;
   g_profiles[5].name = "Wed Bull Rev";
   g_profiles[5].description = "Wednesday bullish reversal";
   g_profiles[5].isBullish = true;

   // PROFILE_WED_BEAR_REV
   g_profiles[6].profile = PROFILE_WED_BEAR_REV;
   g_profiles[6].name = "Wed Bear Rev";
   g_profiles[6].description = "Wednesday bearish reversal";
   g_profiles[6].isBullish = false;

   // PROFILE_THU_BULL_REV
   g_profiles[7].profile = PROFILE_THU_BULL_REV;
   g_profiles[7].name = "Thu Bull Rev";
   g_profiles[7].description = "Thursday bullish reversal";
   g_profiles[7].isBullish = true;

   // PROFILE_THU_BEAR_REV
   g_profiles[8].profile = PROFILE_THU_BEAR_REV;
   g_profiles[8].name = "Thu Bear Rev";
   g_profiles[8].description = "Thursday bearish reversal";
   g_profiles[8].isBullish = false;

   // PROFILE_MWK_RALLY
   g_profiles[9].profile = PROFILE_MWK_RALLY;
   g_profiles[9].name = "MWK Rally";
   g_profiles[9].description = "Midweek rally to Friday high";
   g_profiles[9].isBullish = true;

   // PROFILE_MWK_DECLINE
   g_profiles[10].profile = PROFILE_MWK_DECLINE;
   g_profiles[10].name = "MWK Decline";
   g_profiles[10].description = "Midweek decline to Friday low";
   g_profiles[10].isBullish = false;

   // PROFILE_FRI_BULL_SD
   g_profiles[11].profile = PROFILE_FRI_BULL_SD;
   g_profiles[11].name = "Fri Bull S&D";
   g_profiles[11].description = "Seek & Destroy bullish Friday";
   g_profiles[11].isBullish = true;

   // PROFILE_FRI_BEAR_SD
   g_profiles[12].profile = PROFILE_FRI_BEAR_SD;
   g_profiles[12].name = "Fri Bear S&D";
   g_profiles[12].description = "Seek & Destroy bearish Friday";
   g_profiles[12].isBullish = false;

   // Initialize all statuses to inactive
   for(int i = 0; i < 13; i++)
   {
      g_profiles[i].status = STATUS_INACTIVE;
   }
}

//+------------------------------------------------------------------+
//| Update profile statuses based on current price action            |
//+------------------------------------------------------------------+
void UpdateProfileStatuses()
{
   int currentDay = g_currentDayOfWeek;
   if(currentDay < 0) return;

   // Reset all profiles to INACTIVE first
   for(int i = 1; i <= 12; i++)
   {
      g_profiles[i].status = STATUS_INACTIVE;
      g_profiles[i].keyLevel = 0;
   }

   // Get key levels
   double mondayHigh = g_weeklyData.days[0].high;
   double mondayLow = g_weeklyData.days[0].low;
   double tuesdayHigh = (currentDay >= 1) ? g_weeklyData.days[1].high : 0;
   double tuesdayLow = (currentDay >= 1) ? g_weeklyData.days[1].low : DBL_MAX;
   double wednesdayHigh = (currentDay >= 2) ? g_weeklyData.days[2].high : 0;
   double wednesdayLow = (currentDay >= 2) ? g_weeklyData.days[2].low : DBL_MAX;

   // Current week low/high tracking
   // IMPORTANT: lowDay/highDay can only be valid up to the current day
   int lowDay = g_weeklyData.lowDay;
   int highDay = g_weeklyData.highDay;

   // Sanity check - lowDay/highDay cannot be greater than currentDay
   if(lowDay > currentDay) lowDay = currentDay;
   if(highDay > currentDay) highDay = currentDay;

   // === TUESDAY PROFILES ===
   if(currentDay >= 1)
   {
      // Tue LOTW (Bullish) - Tuesday makes new low, holds as week low
      if(tuesdayLow < mondayLow)
      {
         if(lowDay == 1)  // Tuesday is still the week's low
         {
            g_profiles[1].status = STATUS_ACTIVE;
            g_profiles[1].keyLevel = tuesdayLow;
         }
         else
         {
            g_profiles[1].status = STATUS_INVALIDATED;  // A later day made lower low
         }
      }
      else
      {
         g_profiles[1].status = STATUS_INVALIDATED;  // Tuesday didn't make low below Monday
      }

      // Tue HOTW (Bearish) - Tuesday makes new high, holds as week high
      if(tuesdayHigh > mondayHigh)
      {
         if(highDay == 1)  // Tuesday is still the week's high
         {
            g_profiles[2].status = STATUS_ACTIVE;
            g_profiles[2].keyLevel = tuesdayHigh;
         }
         else
         {
            g_profiles[2].status = STATUS_INVALIDATED;  // A later day made higher high
         }
      }
      else
      {
         g_profiles[2].status = STATUS_INVALIDATED;  // Tuesday didn't make high above Monday
      }
   }

   // === WEDNESDAY PROFILES ===
   if(currentDay >= 2)
   {
      // Wed LOTW - Wednesday makes the week's low
      if(lowDay == 2)
      {
         g_profiles[3].status = STATUS_ACTIVE;
         g_profiles[3].keyLevel = wednesdayLow;
         // If Wed is the low, Tue LOTW is invalidated
         g_profiles[1].status = STATUS_INVALIDATED;
      }
      else if(currentDay == 2)
      {
         g_profiles[3].status = STATUS_POTENTIAL;  // Still Wednesday, could happen
      }
      else
      {
         g_profiles[3].status = STATUS_INVALIDATED;
      }

      // Wed HOTW - Wednesday makes the week's high
      if(highDay == 2)
      {
         g_profiles[4].status = STATUS_ACTIVE;
         g_profiles[4].keyLevel = wednesdayHigh;
         // If Wed is the high, Tue HOTW is invalidated
         g_profiles[2].status = STATUS_INVALIDATED;
      }
      else if(currentDay == 2)
      {
         g_profiles[4].status = STATUS_POTENTIAL;
      }
      else
      {
         g_profiles[4].status = STATUS_INVALIDATED;
      }

      // Wed Bull Rev (lowDay == 2 and bullish bias)
      if(lowDay == 2 && g_weeklyBias == BIAS_BULLISH)
      {
         g_profiles[5].status = STATUS_ACTIVE;
         g_profiles[5].keyLevel = wednesdayLow;
      }
      else if(currentDay == 2 && g_weeklyBias == BIAS_BULLISH)
      {
         g_profiles[5].status = STATUS_POTENTIAL;
      }
      else
      {
         g_profiles[5].status = STATUS_INVALIDATED;
      }

      // Wed Bear Rev (highDay == 2 and bearish bias)
      if(highDay == 2 && g_weeklyBias == BIAS_BEARISH)
      {
         g_profiles[6].status = STATUS_ACTIVE;
         g_profiles[6].keyLevel = wednesdayHigh;
      }
      else if(currentDay == 2 && g_weeklyBias == BIAS_BEARISH)
      {
         g_profiles[6].status = STATUS_POTENTIAL;
      }
      else
      {
         g_profiles[6].status = STATUS_INVALIDATED;
      }
   }

   // === THURSDAY PROFILES ===
   if(currentDay >= 3)
   {
      double thursdayHigh = g_weeklyData.days[3].high;
      double thursdayLow = g_weeklyData.days[3].low;

      // Thu Bull Rev (Thursday low holds)
      if(lowDay == 3)
      {
         g_profiles[7].status = STATUS_ACTIVE;
         g_profiles[7].keyLevel = thursdayLow;
      }
      else if(currentDay == 3)
      {
         g_profiles[7].status = STATUS_POTENTIAL;
      }
      else
      {
         g_profiles[7].status = STATUS_INVALIDATED;
      }

      // Thu Bear Rev (Thursday high holds)
      if(highDay == 3)
      {
         g_profiles[8].status = STATUS_ACTIVE;
         g_profiles[8].keyLevel = thursdayHigh;
      }
      else if(currentDay == 3)
      {
         g_profiles[8].status = STATUS_POTENTIAL;
      }
      else
      {
         g_profiles[8].status = STATUS_INVALIDATED;
      }
   }
   else
   {
      // Thursday hasn't arrived yet
      g_profiles[7].status = STATUS_INACTIVE;
      g_profiles[8].status = STATUS_INACTIVE;
   }

   // === FRIDAY PROFILES ===
   if(currentDay >= 4)
   {
      double fridayHigh = g_weeklyData.days[4].high;
      double fridayLow = g_weeklyData.days[4].low;

      // MWK Rally - Friday makes new weekly high
      if(highDay == 4)
      {
         g_profiles[9].status = STATUS_ACTIVE;
         g_profiles[9].keyLevel = fridayHigh;
      }
      else
      {
         g_profiles[9].status = STATUS_INVALIDATED;
      }

      // MWK Decline - Friday makes new weekly low
      if(lowDay == 4)
      {
         g_profiles[10].status = STATUS_ACTIVE;
         g_profiles[10].keyLevel = fridayLow;
      }
      else
      {
         g_profiles[10].status = STATUS_INVALIDATED;
      }

      // Seek & Destroy Bullish Friday
      g_profiles[11].status = STATUS_POTENTIAL;
      // Seek & Destroy Bearish Friday
      g_profiles[12].status = STATUS_POTENTIAL;
   }
   else
   {
      // Friday hasn't arrived yet
      g_profiles[9].status = STATUS_INACTIVE;
      g_profiles[10].status = STATUS_INACTIVE;
      g_profiles[11].status = STATUS_INACTIVE;
      g_profiles[12].status = STATUS_INACTIVE;
   }

   // Determine active profile
   DetermineActiveProfile();
}

//+------------------------------------------------------------------+
//| Determine the most likely active profile                         |
//+------------------------------------------------------------------+
void DetermineActiveProfile()
{
   g_activeProfile = PROFILE_NONE;

   // Find the first active profile
   for(int i = 1; i < 13; i++)
   {
      if(g_profiles[i].status == STATUS_ACTIVE)
      {
         g_activeProfile = g_profiles[i].profile;
         break;
      }
   }

   // If using news for prediction and no active profile, use predicted
   // BUT only if we're past Monday (day >= 1), since on Monday no profile can be active yet
   if(g_activeProfile == PROFILE_NONE && UseNewsForProfilePrediction && g_newsAvailable && g_currentDayOfWeek >= 1)
   {
      g_activeProfile = g_newsSchedule.predictedProfile;
   }
}

//=============================================================================
// CHECKLIST FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Initialize model checklists                                      |
//+------------------------------------------------------------------+
void InitializeChecklists()
{
   // OSOK Checklist
   g_osokChecklist.model = MODEL_OSOK;
   g_osokChecklist.modelName = "OSOK";
   g_osokChecklist.totalConditions = 5;  // Changed from 7 to 5 (conditions 6 & 7 not implemented yet)
   g_osokChecklist.conditions[0].name = "Weekly Bias Determined";
   g_osokChecklist.conditions[1].name = "Monday Range Formed";
   g_osokChecklist.conditions[2].name = "In Kill Zone";
   g_osokChecklist.conditions[3].name = "Liquidity Swept";
   g_osokChecklist.conditions[4].name = "MSS/CHoCH Confirmed";
   g_osokChecklist.conditions[5].name = "Price in OTE Zone";
   g_osokChecklist.conditions[6].name = "FVG Present";

   // 30 Pips Scalp Checklist
   g_scalp30Checklist.model = MODEL_30_PIPS;
   g_scalp30Checklist.modelName = "30 Pips Scalp";
   g_scalp30Checklist.totalConditions = 6;
   g_scalp30Checklist.conditions[0].name = "D1 Swing Break";
   g_scalp30Checklist.conditions[1].name = "Counter-Swing Formed";
   g_scalp30Checklist.conditions[2].name = "3rd Candle Identified";
   g_scalp30Checklist.conditions[3].name = "3rd Candle Liquidity Swept";
   g_scalp30Checklist.conditions[4].name = "Price at OTE of 3rd Candle";
   g_scalp30Checklist.conditions[5].name = "LTF MSS Confirmation";

   // Silver Bullet Checklist
   g_sbChecklist.model = MODEL_SILVER_BULLET;
   g_sbChecklist.modelName = "Silver Bullet";
   g_sbChecklist.totalConditions = 7;
   g_sbChecklist.conditions[0].name = "In Silver Bullet Window";
   g_sbChecklist.conditions[1].name = "Liquidity Pool Identified";
   g_sbChecklist.conditions[2].name = "Displacement Occurred";
   g_sbChecklist.conditions[3].name = "HTF FVG Formed";
   g_sbChecklist.conditions[4].name = "Price Traded into FVG";
   g_sbChecklist.conditions[5].name = "LTF FVG for Entry";
   g_sbChecklist.conditions[6].name = "Range > Min Pips";
}

//+------------------------------------------------------------------+
//| Update all model checklists                                      |
//+------------------------------------------------------------------+
void UpdateAllChecklists()
{
   UpdateOSOKChecklist();
   UpdateScalp30Checklist();
   UpdateSBChecklist();
}

//+------------------------------------------------------------------+
//| Update OSOK checklist                                            |
//+------------------------------------------------------------------+
void UpdateOSOKChecklist()
{
   g_osokChecklist.metConditions = 0;

   // Condition 1: Weekly Bias Determined
   if(!OSOK_RequireWeeklyBias)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[0].isMet = true;
      g_osokChecklist.conditions[0].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[0].isMet = (g_weeklyBias != BIAS_NEUTRAL);
      g_osokChecklist.conditions[0].value = EnumToString(g_weeklyBias);
      if(g_osokChecklist.conditions[0].isMet) g_osokChecklist.metConditions++;
   }

   // Condition 2: Monday Range Formed
   // Range is "formed" when:
   // - It's Tuesday+ and Monday data exists, OR
   // - It's Monday and we have a meaningful range (high != low, at least some pips developed)
   double mondayRange = g_weeklyData.days[0].high - g_weeklyData.days[0].low;
   bool hasMondayData = (g_weeklyData.days[0].openTime > 0 &&
                         g_weeklyData.days[0].high > 0 &&
                         g_weeklyData.days[0].high < DBL_MAX &&
                         g_weeklyData.days[0].low > 0 &&
                         g_weeklyData.days[0].low < DBL_MAX);
   bool mondayRangeFormed = false;

   if(g_currentDayOfWeek >= 1 && hasMondayData)
   {
      // After Monday, range is confirmed
      mondayRangeFormed = true;
   }
   else if(g_currentDayOfWeek == 0 && hasMondayData && mondayRange > 10 * _Point)
   {
      // On Monday, show "forming" with current range (need at least 1 pip)
      mondayRangeFormed = false;  // Not yet complete, but show progress
   }

   if(!OSOK_RequireMondayRange)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[1].isMet = true;
      g_osokChecklist.conditions[1].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[1].isMet = mondayRangeFormed;
      if(hasMondayData)
         g_osokChecklist.conditions[1].value = "H:" + DoubleToString(g_weeklyData.days[0].high, g_digits) +
                                                " L:" + DoubleToString(g_weeklyData.days[0].low, g_digits) +
                                                (g_currentDayOfWeek == 0 ? " (forming)" : "");
      else
         g_osokChecklist.conditions[1].value = "Waiting...";
      if(g_osokChecklist.conditions[1].isMet) g_osokChecklist.metConditions++;
   }

   // Condition 3: In Kill Zone
   if(!OSOK_RequireKillZone)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[2].isMet = true;
      g_osokChecklist.conditions[2].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      ENUM_KILLZONE kz = GetCurrentKillZone();
      g_osokChecklist.conditions[2].isMet = (kz == KZ_LONDON || kz == KZ_NY_AM);
      g_osokChecklist.conditions[2].value = EnumToString(kz);
      if(g_osokChecklist.conditions[2].isMet) g_osokChecklist.metConditions++;
   }

   // Condition 4: Liquidity Swept
   if(!OSOK_RequireLiquiditySweep)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[3].isMet = true;
      g_osokChecklist.conditions[3].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[3].isMet = g_osokSetup.liquiditySwept;
      if(g_osokSetup.liquiditySwept)
         g_osokChecklist.conditions[3].value = (g_osokSetup.sweepWasBullish ? "Monday Low" : "Monday High");
      else
         g_osokChecklist.conditions[3].value = "Waiting...";
      if(g_osokChecklist.conditions[3].isMet) g_osokChecklist.metConditions++;
   }

   // Condition 5: MSS/CHoCH Confirmed
   if(!OSOK_RequireMSS)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[4].isMet = true;
      g_osokChecklist.conditions[4].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[4].isMet = g_osokSetup.mssConfirmed;
      g_osokChecklist.conditions[4].value = g_osokSetup.mssConfirmed ? "Confirmed" : "Waiting...";
      if(g_osokChecklist.conditions[4].isMet) g_osokChecklist.metConditions++;
   }

   // Condition 6: Price in OTE Zone (placeholder - needs OTE calculation)
   if(!OSOK_RequireOTEZone)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[5].isMet = true;
      g_osokChecklist.conditions[5].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[5].isMet = false;
      g_osokChecklist.conditions[5].value = "N/A";
   }

   // Condition 7: FVG Present (placeholder)
   if(!OSOK_RequireFVG)
   {
      // Disabled - auto-pass
      g_osokChecklist.conditions[6].isMet = true;
      g_osokChecklist.conditions[6].value = "Disabled";
      g_osokChecklist.metConditions++;
   }
   else
   {
      g_osokChecklist.conditions[6].isMet = false;
      g_osokChecklist.conditions[6].value = "None detected";
   }

   // Check if ready
   g_osokChecklist.isReady = (g_osokChecklist.metConditions >= g_osokChecklist.totalConditions);
}

//+------------------------------------------------------------------+
//| Update 30 Pips Scalp checklist                                   |
//+------------------------------------------------------------------+
void UpdateScalp30Checklist()
{
   g_scalp30Checklist.metConditions = 0;

   // Placeholder - implement actual checks
   for(int i = 0; i < g_scalp30Checklist.totalConditions; i++)
   {
      g_scalp30Checklist.conditions[i].isMet = false;
      g_scalp30Checklist.conditions[i].value = "Waiting...";
   }

   g_scalp30Checklist.isReady = false;
}

//+------------------------------------------------------------------+
//| Update Silver Bullet checklist                                   |
//+------------------------------------------------------------------+
void UpdateSBChecklist()
{
   g_sbChecklist.metConditions = 0;

   // Condition 1: In Silver Bullet Window
   ENUM_SB_WINDOW sbWindow = GetSilverBulletWindow();
   g_sbChecklist.conditions[0].isMet = (sbWindow != SB_NONE);
   g_sbChecklist.conditions[0].value = EnumToString(sbWindow);
   if(g_sbChecklist.conditions[0].isMet) g_sbChecklist.metConditions++;

   // Condition 2: Liquidity Pool Identified
   bool liquidityFound = (g_htfNarrative.nearestBSL > 0 || g_htfNarrative.nearestSSL > 0);
   g_sbChecklist.conditions[1].isMet = liquidityFound;
   g_sbChecklist.conditions[1].value = liquidityFound ? "Found" : "None";
   if(g_sbChecklist.conditions[1].isMet) g_sbChecklist.metConditions++;

   // Condition 3: Displacement Occurred (placeholder - needs complex implementation)
   bool displacement = false;  // TODO: Implement displacement detection
   g_sbChecklist.conditions[2].isMet = displacement;
   g_sbChecklist.conditions[2].value = displacement ? "Yes" : "No";
   if(g_sbChecklist.conditions[2].isMet) g_sbChecklist.metConditions++;

   // Condition 4: HTF FVG Formed (placeholder - needs FVG detection)
   bool htfFVG = false;  // TODO: Implement FVG detection
   g_sbChecklist.conditions[3].isMet = htfFVG;
   g_sbChecklist.conditions[3].value = htfFVG ? "Formed" : "None";
   if(g_sbChecklist.conditions[3].isMet) g_sbChecklist.metConditions++;

   // Condition 5: Price Traded into FVG (placeholder)
   bool inFVG = false;  // TODO: Implement FVG entry detection
   g_sbChecklist.conditions[4].isMet = inFVG;
   g_sbChecklist.conditions[4].value = inFVG ? "In FVG" : "Outside";
   if(g_sbChecklist.conditions[4].isMet) g_sbChecklist.metConditions++;

   // Condition 6: LTF FVG for Entry (placeholder)
   bool ltfFVG = false;  // TODO: Implement LTF FVG detection
   g_sbChecklist.conditions[5].isMet = ltfFVG;
   g_sbChecklist.conditions[5].value = ltfFVG ? "Available" : "None";
   if(g_sbChecklist.conditions[5].isMet) g_sbChecklist.metConditions++;

   // Condition 7: Range > Min Pips
   double currentRange = g_weeklyData.weekHigh - g_weeklyData.weekLow;
   double pipValue = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3) ? 0.0001 : 0.01;
   double minRange = 30 * pipValue;  // 30 pips minimum
   bool rangeOK = (currentRange >= minRange);
   g_sbChecklist.conditions[6].isMet = rangeOK;
   g_sbChecklist.conditions[6].value = DoubleToString(currentRange / pipValue, 1) + " pips";
   if(g_sbChecklist.conditions[6].isMet) g_sbChecklist.metConditions++;

   g_sbChecklist.isReady = false;
}

//=============================================================================
// NEWS CALENDAR FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Load weekly news from economic calendar                          |
//+------------------------------------------------------------------+
void LoadWeeklyNews()
{
   if(MQLInfoInteger(MQL_TESTER) && DisableNewsInBacktest)
   {
      g_newsAvailable = false;
      return;
   }

   // Reset news schedule
   g_newsSchedule.eventCount = 0;
   g_newsSchedule.highImpactDays = 0;
   g_newsSchedule.hasNFP = false;
   g_newsSchedule.hasFOMC = false;
   g_newsSchedule.hasCPI = false;

   // Get symbol currencies
   string baseCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_BASE);
   string quoteCurrency = SymbolInfoString(_Symbol, SYMBOL_CURRENCY_PROFIT);

   // Get calendar events for next 7 days
   MqlCalendarValue values[];
   datetime startTime = TimeCurrent();
   datetime endTime = startTime + 7 * 86400;

   int count = CalendarValueHistory(values, startTime, endTime, NULL, NULL);

   if(count <= 0)
   {
      g_newsAvailable = false;
      return;
   }

   // Filter high impact events for our currencies
   for(int i = 0; i < count && g_newsSchedule.eventCount < 20; i++)
   {
      MqlCalendarEvent event;
      if(!CalendarEventById(values[i].event_id, event))
         continue;

      MqlCalendarCountry country;
      if(!CalendarCountryById(event.country_id, country))
         continue;

      // Check if event is for our currencies
      if(country.currency != baseCurrency && country.currency != quoteCurrency)
         continue;

      // Check importance
      if(FilterHighImpact && event.importance != CALENDAR_IMPORTANCE_HIGH)
         continue;
      if(FilterMediumImpact && event.importance < CALENDAR_IMPORTANCE_MODERATE)
         continue;

      // Add to schedule
      int idx = g_newsSchedule.eventCount;
      g_newsSchedule.events[idx].id = values[i].event_id;
      g_newsSchedule.events[idx].name = event.name;
      g_newsSchedule.events[idx].currency = country.currency;
      g_newsSchedule.events[idx].time = values[i].time;
      g_newsSchedule.events[idx].importance = (int)event.importance;

      MqlDateTime dt;
      TimeToStruct(values[i].time, dt);
      g_newsSchedule.events[idx].dayOfWeek = dt.day_of_week;

      // Update day flags
      if(dt.day_of_week >= 1 && dt.day_of_week <= 5)
         g_newsSchedule.highImpactDays |= (1 << (dt.day_of_week - 1));

      // Check for key events
      string eventName = event.name;
      StringToLower(eventName);
      if(StringFind(eventName, "nonfarm") >= 0 || StringFind(eventName, "non-farm") >= 0)
         g_newsSchedule.hasNFP = true;
      if(StringFind(eventName, "fomc") >= 0 || StringFind(eventName, "federal") >= 0)
         g_newsSchedule.hasFOMC = true;
      if(StringFind(eventName, "cpi") >= 0 || StringFind(eventName, "inflation") >= 0)
         g_newsSchedule.hasCPI = true;

      g_newsSchedule.eventCount++;
   }

   g_newsAvailable = (g_newsSchedule.eventCount > 0);
   g_lastNewsCheck = TimeCurrent();

   // Predict weekly profile based on news
   PredictProfileFromNews();
}

//+------------------------------------------------------------------+
//| Predict weekly profile based on news schedule                    |
//+------------------------------------------------------------------+
void PredictProfileFromNews()
{
   g_newsSchedule.predictedProfile = PROFILE_NONE;

   if(!g_newsAvailable) return;

   // Thursday FOMC/Rate Decision -> Thu Reversal
   if(g_newsSchedule.hasFOMC && (g_newsSchedule.highImpactDays & 8) != 0)  // Thursday = bit 3
   {
      g_newsSchedule.predictedProfile = (g_weeklyBias == BIAS_BULLISH) ?
                                         PROFILE_THU_BULL_REV : PROFILE_THU_BEAR_REV;
      return;
   }

   // Friday NFP -> Seek & Destroy Friday
   if(g_newsSchedule.hasNFP && (g_newsSchedule.highImpactDays & 16) != 0)  // Friday = bit 4
   {
      g_newsSchedule.predictedProfile = (g_weeklyBias == BIAS_BULLISH) ?
                                         PROFILE_FRI_BULL_SD : PROFILE_FRI_BEAR_SD;
      return;
   }

   // Wednesday CPI -> Wed Reversal
   if(g_newsSchedule.hasCPI && (g_newsSchedule.highImpactDays & 4) != 0)  // Wednesday = bit 2
   {
      g_newsSchedule.predictedProfile = (g_weeklyBias == BIAS_BULLISH) ?
                                         PROFILE_WED_BULL_REV : PROFILE_WED_BEAR_REV;
      return;
   }

   // No major news -> Classic Tuesday
   g_newsSchedule.predictedProfile = (g_weeklyBias == BIAS_BULLISH) ?
                                      PROFILE_TUE_LOTW : PROFILE_TUE_HOTW;
}

//+------------------------------------------------------------------+
//| Check if currently in news pause window                          |
//+------------------------------------------------------------------+
bool IsNewsTime()
{
   if(!EnableNewsFilter || !PauseBeforeHighImpact || !g_newsAvailable)
      return false;

   datetime currentTime = TimeCurrent();

   for(int i = 0; i < g_newsSchedule.eventCount; i++)
   {
      datetime newsTime = g_newsSchedule.events[i].time;
      datetime pauseStart = newsTime - (MinutesBeforeNews * 60);
      datetime pauseEnd = newsTime + (MinutesAfterNews * 60);

      if(currentTime >= pauseStart && currentTime <= pauseEnd)
      {
         g_pauseReason = "News: " + g_newsSchedule.events[i].name;
         return true;
      }
   }

   return false;
}

//=============================================================================
// TRADING FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Check if trading is paused                                       |
//+------------------------------------------------------------------+
bool IsTradingPaused()
{
   g_tradingPaused = false;
   g_pauseReason = "";

   // Check trade limits
   if(g_tradesToday >= MaxTradesPerDay)
   {
      g_tradingPaused = true;
      g_pauseReason = "Max daily trades reached";
      return true;
   }

   if(g_tradesThisWeek >= MaxTradesPerWeek)
   {
      g_tradingPaused = true;
      g_pauseReason = "Max weekly trades reached";
      return true;
   }

   // Check news time
   if(IsNewsTime())
   {
      g_tradingPaused = true;
      return true;
   }

   // Check if visual only mode
   if(TradeMode == MODE_VISUAL)
   {
      g_tradingPaused = true;
      g_pauseReason = "Visual only mode";
      return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check for trade signals                                          |
//+------------------------------------------------------------------+
void CheckTradeSignals()
{
   // Check based on active model
   switch(ActiveModel)
   {
      case MODEL_OSOK:
         if(OSOK_Enabled) CheckOSOKSignal();
         break;
      case MODEL_30_PIPS:
         if(Scalp30_Enabled) CheckScalp30Signal();
         break;
      case MODEL_SILVER_BULLET:
         if(SilverBullet_Enabled) CheckSilverBulletSignal();
         break;
   }

   // Multi-model check
   if(EnableMultiModel)
   {
      if(OSOK_Enabled && ActiveModel != MODEL_OSOK) CheckOSOKSignal();
      if(Scalp30_Enabled && ActiveModel != MODEL_30_PIPS) CheckScalp30Signal();
      if(SilverBullet_Enabled && ActiveModel != MODEL_SILVER_BULLET) CheckSilverBulletSignal();
   }
}

//+------------------------------------------------------------------+
//| Check OSOK signal (placeholder - needs full implementation)      |
//+------------------------------------------------------------------+
void CheckOSOKSignal()
{
   if(!IsOSOKTradingDay()) return;
   if(GetCurrentKillZone() != KZ_LONDON && GetCurrentKillZone() != KZ_NY_AM) return;

   // Check if Monday range is available
   if(g_currentDayOfWeek < 1) return;

   // Validate Monday data before using
   if(g_weeklyData.days[0].openTime == 0) return;  // Monday data not loaded

   double mondayHigh = g_weeklyData.days[0].high;
   double mondayLow = g_weeklyData.days[0].low;
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Get current candle data for BOS detection
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 0, 1, rates) < 1) return;

   // Check for Weekly sweep (previous or current week)
   bool sweepDetected = false;
   double pipValue = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3) ? 0.0001 : 0.01;
   double buffer = 2 * pipValue;  // 2 pip buffer beyond level

   // Check previous week sweep
   if(OSOK_DetectPrevWeekSweep && g_historicalWeeks[0].isValid && !sweepDetected)
   {
      double prevWeekHigh = g_historicalWeeks[0].high;
      double prevWeekLow = g_historicalWeeks[0].low;

      // Bullish sweep (sweep previous week low)
      if(!g_osokSetup.liquiditySwept && bid <= prevWeekLow - buffer)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = true;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Previous week low swept at " + DoubleToString(prevWeekLow, g_digits));

         Print("OSOK: Previous week low swept at ", prevWeekLow);
         sweepDetected = true;
      }
      // Bearish sweep (sweep previous week high)
      else if(!g_osokSetup.liquiditySwept && bid >= prevWeekHigh + buffer)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = false;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Previous week high swept at " + DoubleToString(prevWeekHigh, g_digits));

         Print("OSOK: Previous week high swept at ", prevWeekHigh);
         sweepDetected = true;
      }
   }

   // Check current week sweep (if enabled and no previous week sweep yet)
   if(!sweepDetected && OSOK_DetectCurrentWeekSweep && g_currentDayOfWeek >= 1)
   {
      double currentWeekHigh = g_weeklyData.weekHigh;
      double currentWeekLow = g_weeklyData.weekLow;

      // Bullish sweep
      if(!g_osokSetup.liquiditySwept && bid <= currentWeekLow - buffer)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = true;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Current week low swept at " + DoubleToString(currentWeekLow, g_digits));

         Print("OSOK: Current week low swept at ", currentWeekLow);
         sweepDetected = true;
      }
      // Bearish sweep
      else if(!g_osokSetup.liquiditySwept && bid >= currentWeekHigh + buffer)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = false;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Current week high swept at " + DoubleToString(currentWeekHigh, g_digits));

         Print("OSOK: Current week high swept at ", currentWeekHigh);
         sweepDetected = true;
      }
   }

   // Fallback: Check for Monday low/high sweep (original logic)
   if(!sweepDetected)
   {
      // Check for Monday low sweep (bullish setup)
      if(!g_osokSetup.liquiditySwept && bid <= mondayLow)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = true;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Monday low swept - looking for bullish entry");
      }

      // Check for Monday high sweep (bearish setup)
      if(!g_osokSetup.liquiditySwept && bid >= mondayHigh)
      {
         g_osokSetup.liquiditySwept = true;
         g_osokSetup.sweepWasBullish = false;
         g_osokSetup.sweepTime = TimeCurrent();
         g_osokSetup.mondayHigh = mondayHigh;
         g_osokSetup.mondayLow = mondayLow;
         g_osokSetup.sweepCandleHigh = rates[0].high;
         g_osokSetup.sweepCandleLow = rates[0].low;

         if(AlertOnSetup)
            SendAlert("OSOK: Monday high swept - looking for bearish entry");
      }
   }

   // Check for BOS, Turtle Soup, and MSS after sweep
   if(g_osokSetup.liquiditySwept)
   {
      // Check for Turtle Soup first (faster entry, no MSS/BOS needed)
      if(OSOK_EnableTurtleSoup && !g_osokSetup.mssConfirmed)
      {
         DetectTurtleSoup();
      }

      // Check for BOS detection
      if(!g_osokSetup.bosConfirmed)
      {
         DetectBOSAfterSweep();
      }

      // Check for MSS detection (after BOS)
      if(g_osokSetup.bosConfirmed && !g_osokSetup.mssConfirmed)
      {
         DetectMSSAfterSweep();
      }

      // Check for Order Block after MSS
      if(g_osokSetup.mssConfirmed && !g_osokOB.isValid)
      {
         DetectOrderBlock(g_osokSetup.isBuy);  // Look for bullish OB if buy setup
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Break of Structure (BOS) after liquidity sweep            |
//| Bullish: First HH after Mon L sweep                              |
//| Bearish: First LL after Mon H sweep                              |
//+------------------------------------------------------------------+
bool DetectBOSAfterSweep()
{
   if(!g_osokSetup.liquiditySwept || g_osokSetup.bosConfirmed)
      return false;

   // Get last completed candle (M15 timeframe for precision)
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 0, 2, rates) < 2)
      return false;

   double lastCandleHigh = rates[1].high;
   double lastCandleLow = rates[1].low;
   double lastCandleClose = rates[1].close;

   // For bullish BOS (after sweeping Monday low)
   if(g_osokSetup.sweepWasBullish)
   {
      // BOS = Close above the high of the sweep candle
      if(lastCandleClose > g_osokSetup.sweepCandleHigh)
      {
         g_osokSetup.bosConfirmed = true;
         g_osokSetup.bosTime = rates[1].time;
         g_osokSetup.bosPrice = g_osokSetup.sweepCandleHigh;

         Print("OSOK: Bullish BOS confirmed - First HH at ", g_osokSetup.bosPrice);
         return true;
      }
   }
   // For bearish BOS (after sweeping Monday high)
   else
   {
      // BOS = Close below the low of the sweep candle
      if(lastCandleClose < g_osokSetup.sweepCandleLow)
      {
         g_osokSetup.bosConfirmed = true;
         g_osokSetup.bosTime = rates[1].time;
         g_osokSetup.bosPrice = g_osokSetup.sweepCandleLow;

         Print("OSOK: Bearish BOS confirmed - First LL at ", g_osokSetup.bosPrice);
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Market Structure Shift (MSS) after sweep                  |
//| Bullish MSS: Monday low swept → Price breaks above Monday HIGH   |
//| Bearish MSS: Monday high swept → Price breaks below Monday LOW   |
//+------------------------------------------------------------------+
bool DetectMSSAfterSweep()
{
   if(!g_osokSetup.liquiditySwept || g_osokSetup.mssConfirmed)
      return false;

   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);

   // Add buffer for confirmation (2-3 pips beyond level)
   double pipValue = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3) ? 0.0001 : 0.01;
   double buffer = 3 * pipValue;

   // For bullish MSS (after sweeping Monday low)
   if(g_osokSetup.sweepWasBullish)
   {
      // MSS = Break ABOVE Monday high (opposite extreme)
      if(ask > g_osokSetup.mondayHigh + buffer)
      {
         g_osokSetup.mssConfirmed = true;
         g_osokSetup.mssTime = TimeCurrent();
         g_osokSetup.isBuy = true;

         // Draw MSS marker at Monday high level
         DrawMSSMarker(g_osokSetup.mondayHigh, g_osokSetup.mssTime, true);

         Print("OSOK: Bullish MSS confirmed - Mon Low swept, now broke Mon High at ", g_osokSetup.mondayHigh);
         return true;
      }
   }
   // For bearish MSS (after sweeping Monday high)
   else
   {
      // MSS = Break BELOW Monday low (opposite extreme)
      if(bid < g_osokSetup.mondayLow - buffer)
      {
         g_osokSetup.mssConfirmed = true;
         g_osokSetup.mssTime = TimeCurrent();
         g_osokSetup.isBuy = false;

         // Draw MSS marker at Monday low level
         DrawMSSMarker(g_osokSetup.mondayLow, g_osokSetup.mssTime, false);

         Print("OSOK: Bearish MSS confirmed - Mon High swept, now broke Mon Low at ", g_osokSetup.mondayLow);
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Turtle Soup - Failed breakout reversal                    |
//+------------------------------------------------------------------+
bool DetectTurtleSoup()
{
   if(!OSOK_EnableTurtleSoup || !g_osokSetup.liquiditySwept)
      return false;

   if(g_osokSetup.mssConfirmed)  // Already confirmed via MSS, skip Turtle Soup
      return false;

   // Get last CLOSED candle
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   if(CopyRates(_Symbol, PERIOD_M15, 0, 2, rates) < 2)
      return false;

   double lastCandleClose = rates[1].close;

   // For bullish Turtle Soup (swept Monday low, now back inside)
   if(g_osokSetup.sweepWasBullish)
   {
      // Entry: Candle CLOSED back ABOVE Monday low
      if(lastCandleClose > g_osokSetup.mondayLow)
      {
         g_osokSetup.mssConfirmed = true;  // Treat as ready for entry
         g_osokSetup.mssTime = rates[1].time;
         g_osokSetup.isBuy = true;
         g_osokSetup.reason = "Turtle Soup - Bullish Rejection";

         Print("OSOK Turtle Soup: Mon Low swept, price closed back inside at ", lastCandleClose);
         return true;
      }
   }
   // For bearish Turtle Soup (swept Monday high, now back inside)
   else
   {
      // Entry: Candle CLOSED back BELOW Monday high
      if(lastCandleClose < g_osokSetup.mondayHigh)
      {
         g_osokSetup.mssConfirmed = true;
         g_osokSetup.mssTime = rates[1].time;
         g_osokSetup.isBuy = false;
         g_osokSetup.reason = "Turtle Soup - Bearish Rejection";

         Print("OSOK Turtle Soup: Mon High swept, price closed back inside at ", lastCandleClose);
         return true;
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Detect Order Block - Last opposite candle before impulsive move  |
//+------------------------------------------------------------------+
bool DetectOrderBlock(bool lookForBullishOB)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PERIOD_M15, 0, 50, rates);  // Last 50 candles
   if(copied < 50) return false;

   double pipValue = (SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 5 || SymbolInfoInteger(_Symbol, SYMBOL_DIGITS) == 3) ? 0.0001 : 0.01;

   // Look for last opposite color candle before strong move
   for(int i = 5; i < copied - 1; i++)  // Start from bar 5 to ensure move happened
   {
      bool isCandleBullish = (rates[i].close > rates[i].open);
      bool isCandleBearish = (rates[i].close < rates[i].open);

      if(lookForBullishOB && isCandleBearish)  // Last down candle before rally
      {
         // Check if next 3-5 candles moved up significantly
         double moveSize = 0;
         for(int j = i - 1; j >= i - 5 && j >= 0; j--)
         {
            moveSize += rates[j].high - rates[j].low;
         }

         // Require significant move (at least 20 pips)
         if(moveSize >= 20 * pipValue)
         {
            g_osokOB.isValid = true;
            g_osokOB.isBullish = true;
            g_osokOB.high = rates[i].high;
            g_osokOB.low = rates[i].low;
            g_osokOB.time = rates[i].time;
            g_osokOB.tested = false;
            g_osokOB.candleIndex = i;

            Print("Bullish OB detected at ", rates[i].time, " [", g_osokOB.low, " - ", g_osokOB.high, "]");

            // Draw the OB on the chart
            DrawOrderBlock();

            return true;
         }
      }
      else if(!lookForBullishOB && isCandleBullish)  // Last up candle before drop
      {
         // Check if next 3-5 candles moved down significantly
         double moveSize = 0;
         for(int j = i - 1; j >= i - 5 && j >= 0; j--)
         {
            moveSize += rates[j].high - rates[j].low;
         }

         if(moveSize >= 20 * pipValue)
         {
            g_osokOB.isValid = true;
            g_osokOB.isBullish = false;
            g_osokOB.high = rates[i].high;
            g_osokOB.low = rates[i].low;
            g_osokOB.time = rates[i].time;
            g_osokOB.tested = false;
            g_osokOB.candleIndex = i;

            Print("Bearish OB detected at ", rates[i].time, " [", g_osokOB.low, " - ", g_osokOB.high, "]");

            // Draw the OB on the chart
            DrawOrderBlock();

            return true;
         }
      }
   }

   return false;
}

//+------------------------------------------------------------------+
//| Draw Order Block zone as rectangle                               |
//+------------------------------------------------------------------+
void DrawOrderBlock()
{
   if(!g_osokOB.isValid) return;

   string objName = EA_PREFIX + "OB_" + TimeToString(g_osokOB.time);
   datetime endTime = g_osokOB.time + 14400;  // Extend 4 hours ahead

   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_RECTANGLE, 0, g_osokOB.time, g_osokOB.high, endTime, g_osokOB.low);

   color obColor = g_osokOB.isBullish ? clrGreen : clrRed;
   ObjectSetInteger(0, objName, OBJPROP_COLOR, obColor);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 1);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);
   ObjectSetInteger(0, objName, OBJPROP_FILL, true);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 3);

   // Add label
   string labelName = EA_PREFIX + "OB_Label_" + TimeToString(g_osokOB.time);
   if(ObjectFind(0, labelName) < 0)
      ObjectCreate(0, labelName, OBJ_TEXT, 0, g_osokOB.time, g_osokOB.high);

   ObjectSetString(0, labelName, OBJPROP_TEXT, " OB ");
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, obColor);
   ObjectSetDouble(0, labelName, OBJPROP_PRICE, g_osokOB.high + (10 * _Point));
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LOWER);
   ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Check 30 Pips Scalp signal (placeholder)                         |
//+------------------------------------------------------------------+
void CheckScalp30Signal()
{
   // Placeholder - needs implementation
}

//+------------------------------------------------------------------+
//| Check Silver Bullet signal (placeholder)                         |
//+------------------------------------------------------------------+
void CheckSilverBulletSignal()
{
   ENUM_SB_WINDOW window = GetSilverBulletWindow();
   if(window == SB_NONE) return;

   g_sbSetup.inWindow = true;
   g_sbSetup.activeWindow = window;

   // Placeholder - needs full implementation
}

//+------------------------------------------------------------------+
//| Manage open trades                                               |
//+------------------------------------------------------------------+
void ManageOpenTrades()
{
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      ulong ticket = PositionGetTicket(i);
      if(ticket == 0) continue;

      if(PositionGetInteger(POSITION_MAGIC) != MagicNumber) continue;
      if(PositionGetString(POSITION_SYMBOL) != _Symbol) continue;

      double openPrice = PositionGetDouble(POSITION_PRICE_OPEN);
      double currentPrice = PositionGetDouble(POSITION_PRICE_CURRENT);
      double stopLoss = PositionGetDouble(POSITION_SL);
      double takeProfit = PositionGetDouble(POSITION_TP);
      double profit = PositionGetDouble(POSITION_PROFIT);
      ENUM_POSITION_TYPE posType = (ENUM_POSITION_TYPE)PositionGetInteger(POSITION_TYPE);

      // Move to breakeven logic
      if(MoveToBreakeven)
      {
         double pipsProfit = 0;
         if(posType == POSITION_TYPE_BUY)
            pipsProfit = (currentPrice - openPrice) / g_pipValue;
         else
            pipsProfit = (openPrice - currentPrice) / g_pipValue;

         if(pipsProfit >= TP1_Pips && stopLoss != openPrice)
         {
            trade.PositionModify(ticket, openPrice, takeProfit);
         }
      }

      // Trailing stop logic
      if(UseTrailingStop)
      {
         double trailDistance = TrailingStopPips * g_pipValue;
         double newSL = 0;

         if(posType == POSITION_TYPE_BUY)
         {
            newSL = currentPrice - trailDistance;
            if(newSL > stopLoss && newSL > openPrice)
               trade.PositionModify(ticket, newSL, takeProfit);
         }
         else
         {
            newSL = currentPrice + trailDistance;
            if(newSL < stopLoss && newSL < openPrice)
               trade.PositionModify(ticket, newSL, takeProfit);
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Calculate lot size based on risk                                 |
//+------------------------------------------------------------------+
double CalculateLotSize(double stopLossPoints)
{
   if(UseFixedLot)
      return NormalizeLot(FixedLotSize);

   double accountBalance = AccountInfoDouble(ACCOUNT_BALANCE);
   double riskAmount = accountBalance * (RiskPercent / 100.0);
   double tickValue = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_VALUE);
   double tickSize = SymbolInfoDouble(_Symbol, SYMBOL_TRADE_TICK_SIZE);

   double lotSize = riskAmount / (stopLossPoints * tickValue / tickSize);

   return NormalizeLot(lotSize);
}

//+------------------------------------------------------------------+
//| Normalize lot size to broker requirements                        |
//+------------------------------------------------------------------+
double NormalizeLot(double lots)
{
   lots = MathMax(lots, g_minLot);
   lots = MathMin(lots, g_maxLot);
   lots = MathRound(lots / g_lotStep) * g_lotStep;
   return NormalizeDouble(lots, 2);
}

//=============================================================================
// VISUAL / DASHBOARD FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Get profile status symbol (single char for compact display)      |
//+------------------------------------------------------------------+
string GetProfileStatusSymbol(ENUM_PROFILE_STATUS status)
{
   switch(status)
   {
      case STATUS_INACTIVE:    return ".";
      case STATUS_POTENTIAL:   return "?";
      case STATUS_ACTIVE:      return "v";
      case STATUS_CONFIRMED:   return "+";
      case STATUS_INVALIDATED: return "x";
      default:                 return " ";
   }
}

//+------------------------------------------------------------------+
//| Get profile abbreviation for compact display                     |
//+------------------------------------------------------------------+
string GetProfileAbbreviation(string fullName)
{
   if(StringFind(fullName, "Tuesday Low") >= 0) return "TueLOTW";
   if(StringFind(fullName, "Tuesday High") >= 0) return "TueHOTW";
   if(StringFind(fullName, "Wednesday Low") >= 0) return "WedLOTW";
   if(StringFind(fullName, "Wednesday High") >= 0) return "WedHOTW";
   if(StringFind(fullName, "Wednesday Bullish") >= 0) return "WedBullRev";
   if(StringFind(fullName, "Wednesday Bearish") >= 0) return "WedBearRev";
   if(StringFind(fullName, "Thursday Bullish") >= 0) return "ThuBullRev";
   if(StringFind(fullName, "Thursday Bearish") >= 0) return "ThuBearRev";
   if(StringFind(fullName, "Rally") >= 0) return "MWKRally";
   if(StringFind(fullName, "Decline") >= 0) return "MWKDecline";
   if(StringFind(fullName, "Bullish Friday") >= 0) return "FriBullSD";
   if(StringFind(fullName, "Bearish Friday") >= 0) return "FriBearSD";
   if(StringFind(fullName, "Seek") >= 0 && StringFind(fullName, "Bull") >= 0) return "FriBullSD";
   if(StringFind(fullName, "Seek") >= 0 && StringFind(fullName, "Bear") >= 0) return "FriBearSD";
   return StringSubstr(fullName, 0, 10);
}

//+------------------------------------------------------------------+
//| Get color for a specific day of week                             |
//+------------------------------------------------------------------+
color GetDayColor(int day)
{
   switch(day)
   {
      case 0: return MondayColor;
      case 1: return TuesdayColor;
      case 2: return WednesdayColor;
      case 3: return ThursdayColor;
      case 4: return FridayColor;
      default: return DashboardTextColor;
   }
}

//+------------------------------------------------------------------+
//| Get color for bias                                               |
//+------------------------------------------------------------------+
color GetBiasColor(ENUM_WEEKLY_BIAS bias)
{
   switch(bias)
   {
      case BIAS_BULLISH:  return BullishColor;
      case BIAS_BEARISH:  return BearishColor;
      case BIAS_NEUTRAL:  return clrYellow;
      default:            return DashboardTextColor;
   }
}

//+------------------------------------------------------------------+
//| Convert bias enum to short string                                |
//+------------------------------------------------------------------+
string BiasToShortString(ENUM_WEEKLY_BIAS bias)
{
   switch(bias)
   {
      case BIAS_BULLISH:  return "BULL";
      case BIAS_BEARISH:  return "BEAR";
      case BIAS_NEUTRAL:  return "NEUT";
      default:            return "---";
   }
}

//+------------------------------------------------------------------+
//| Draw main dashboard (Modern Card-based Design)                   |
//+------------------------------------------------------------------+
void DrawDashboard()
{
   if(!ShowDashboard) return;

   // Update HTF bias FIRST so header shows correct value
   AnalyzeHTFNarrative();

   // Use dynamic position (for draggable dashboard)
   int x = g_dashboardX;
   int y = g_dashboardY;

   // Modern dashboard dimensions
   int dashWidth = 360;    // Wider for better spacing
   int cardPadding = 8;    // Padding inside cards
   int cardGap = 4;        // Gap between cards
   int contentX = x + cardPadding;

   // Font sizes for hierarchy
   int titleFontSize = DashboardFontSize + 2;
   int labelFontSize = DashboardFontSize - 1;
   int valueFontSize = DashboardFontSize;
   int lineHeight = DashboardFontSize + 6;
   int compactLineHeight = DashboardFontSize + 4;

   // Calculate total dashboard height
   int headerHeight = 42;
   int levelsHeight = 75;
   int profilesHeight = ShowProfilesTable ? 125 : 0;
   int conditionsHeight = ShowConditionsChecklist ? 145 : 0;
   int htfHeight = ShowHTFNarrative ? 80 : 0;
   int buttonsHeight = (ShowManualButtons && TradeMode != MODE_VISUAL) ? 55 : 0;

   int dashHeight = headerHeight + levelsHeight + profilesHeight + conditionsHeight + htfHeight + buttonsHeight;
   dashHeight += (cardGap * 6) + 10;  // Gaps + margins

   // Draw main background - SELECTABLE for dragging
   string bgName = EA_PREFIX + "DashBG";
   if(ObjectFind(0, bgName) < 0)
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
   ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, bgName, OBJPROP_XSIZE, dashWidth);
   ObjectSetInteger(0, bgName, OBJPROP_YSIZE, dashHeight);
   ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, DashboardBgColor);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
   ObjectSetInteger(0, bgName, OBJPROP_BORDER_COLOR, DashCardBorderColor);
   ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, bgName, OBJPROP_BACK, false);
   ObjectSetInteger(0, bgName, OBJPROP_SELECTABLE, true);
   ObjectSetInteger(0, bgName, OBJPROP_ZORDER, 9);  // Dashboard background

   int cardY = y + cardGap;
   int cardWidth = dashWidth - (cardGap * 2);

   //=================================================================
   // HEADER CARD - Title + Day/Model/Bias
   //=================================================================
   DrawCard("Header", x + cardGap, cardY, cardWidth, headerHeight, DashCardBgColor, DashCardBorderColor);

   // Title row
   CreateLabel("Title", contentX + 4, cardY + 6, "ICT WEEKLY PROFILE", DashTextPrimary, titleFontSize);

   // Day • Model • Bias on single line
   string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};
   string currentDayStr = (g_currentDayOfWeek >= 0 && g_currentDayOfWeek < 5) ? dayNames[g_currentDayOfWeek] : "WE";

   // Get model short name
   string modelShort = "OSOK";
   if(ActiveModel == MODEL_30_PIPS) modelShort = "30PIPS";
   else if(ActiveModel == MODEL_SILVER_BULLET) modelShort = "SB";

   // Get bias info
   color biasColor = (g_weeklyBias == BIAS_BULLISH) ? DashSuccessGreen :
                     (g_weeklyBias == BIAS_BEARISH) ? DashDangerRed : DashWarningYellow;
   string biasStr = (g_weeklyBias == BIAS_BULLISH) ? "BULL" :
                    (g_weeklyBias == BIAS_BEARISH) ? "BEAR" : "NEUT";

   // Combined info line: "Thu • SB • BULL"
   CreateLabel("DayInfo", contentX + 4, cardY + 24, currentDayStr, DashTextSecondary, labelFontSize);
   CreateLabel("Separator1", contentX + 35, cardY + 24, "•", DashTextSecondary, labelFontSize);
   CreateLabel("ModelInfo", contentX + 48, cardY + 24, modelShort, DashTextSecondary, labelFontSize);
   CreateLabel("Separator2", contentX + 90, cardY + 24, "•", DashTextSecondary, labelFontSize);
   CreateLabel("BiasInfo", contentX + 103, cardY + 24, biasStr, biasColor, labelFontSize);

   // Active profile (right side)
   string profileName = "---";
   color profileColor = DashTextSecondary;
   if(g_currentDayOfWeek == 0)
   {
      profileName = "Mon Range";
      profileColor = DashWarningYellow;
   }
   else if(g_activeProfile != PROFILE_NONE)
   {
      profileName = GetProfileAbbreviation(g_profiles[(int)g_activeProfile].name);
      profileColor = DashAccentBlue;
   }
   CreateLabel("ActiveProf", contentX + 180, cardY + 24, profileName, profileColor, labelFontSize);

   cardY += headerHeight + cardGap;

   //=================================================================
   // WEEKLY LEVELS CARD - WH, EQ, WL mini boxes + HOTW/LOTW
   //=================================================================
   DrawCard("Levels", x + cardGap, cardY, cardWidth, levelsHeight, DashCardBgColor, DashCardBorderColor);

   // Section title
   CreateLabel("LevelsTitle", contentX + 4, cardY + 5, "WEEKLY LEVELS", DashTextSecondary, labelFontSize);

   // Mini price boxes (3 columns)
   int boxWidth = 95;
   int boxHeight = 32;
   int boxY = cardY + 22;
   int boxGap = 8;

   // WH box (green tint) - more visible
   color whBoxColor = C'25,60,35';  // Darker green background for contrast
   DrawMiniPriceBox("WH", contentX + 4, boxY, boxWidth, boxHeight, "WH",
                    DoubleToString(g_weeklyData.weekHigh, g_digits), whBoxColor, DashSuccessGreen);

   // EQ box (gray) - more visible
   color eqBoxColor = C'50,50,60';  // Lighter gray for visibility
   DrawMiniPriceBox("EQ", contentX + 4 + boxWidth + boxGap, boxY, boxWidth, boxHeight, "EQ",
                    DoubleToString(g_weeklyData.equilibrium, g_digits), eqBoxColor, DashTextPrimary);

   // WL box (red tint) - more visible
   color wlBoxColor = C'60,25,35';  // Darker red background for contrast
   DrawMiniPriceBox("WL", contentX + 4 + (boxWidth + boxGap) * 2, boxY, boxWidth, boxHeight, "WL",
                    DoubleToString(g_weeklyData.weekLow, g_digits), wlBoxColor, DashDangerRed);

   // HOTW / LOTW row
   string fullDayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};
   string hotwDay = (g_weeklyData.highDay >= 0 && g_weeklyData.highDay < 5) ? fullDayNames[g_weeklyData.highDay] : "---";
   string lotwDay = (g_weeklyData.lowDay >= 0 && g_weeklyData.lowDay < 5) ? fullDayNames[g_weeklyData.lowDay] : "---";

   CreateLabel("HOTWLbl", contentX + 4, boxY + boxHeight + 6, "HOTW:", DashTextSecondary, labelFontSize);
   CreateLabel("HOTWVal", contentX + 50, boxY + boxHeight + 6, hotwDay, DashSuccessGreen, labelFontSize);
   CreateLabel("LOTWLbl", contentX + 150, boxY + boxHeight + 6, "LOTW:", DashTextSecondary, labelFontSize);
   CreateLabel("LOTWVal", contentX + 196, boxY + boxHeight + 6, lotwDay, DashDangerRed, labelFontSize);

   cardY += levelsHeight + cardGap;

   //=================================================================
   // PROFILES CARD (if enabled)
   //=================================================================
   if(ShowProfilesTable)
   {
      cardY = DrawProfileTableModern(x, cardY, cardWidth, contentX);
      cardY += cardGap;
   }

   //=================================================================
   // CONDITIONS CARD (if enabled)
   //=================================================================
   if(ShowConditionsChecklist)
   {
      cardY = DrawConditionsChecklistModern(x, cardY, cardWidth, contentX);
      cardY += cardGap;
   }

   //=================================================================
   // HTF NARRATIVE CARD (if enabled)
   //=================================================================
   if(ShowHTFNarrative)
   {
      cardY = DrawHTFNarrativePanelModern(x, cardY, cardWidth, contentX);
      cardY += cardGap;
   }

   //=================================================================
   // PDA NARRATIVE CARD (if enabled)
   //=================================================================
   if(PDA_ShowNarrativePanel && PDA_Enable)
   {
      cardY = DrawPDANarrativePanel(x, cardY, cardWidth, contentX);
      cardY += cardGap;
   }

   //=================================================================
   // TRADE BUTTONS + STATUS CARD
   //=================================================================
   if(ShowManualButtons && TradeMode != MODE_VISUAL)
   {
      int statusCardHeight = 55;
      DrawCard("Status", x + cardGap, cardY, cardWidth, statusCardHeight, DashCardBgColor, DashCardBorderColor);

      // Modern buttons
      int btnWidth = 80;
      int btnHeight = 28;
      int btnGap = 15;

      // BUY button
      CreateButton("BtnBuy", contentX + 10, cardY + 8, btnWidth, btnHeight, "BUY", DashSuccessGreen, DashTextPrimary);

      // SELL button
      CreateButton("BtnSell", contentX + 10 + btnWidth + btnGap, cardY + 8, btnWidth, btnHeight, "SELL", DashDangerRed, DashTextPrimary);

      // Status with dot indicator
      string status = g_tradingPaused ? "PAUSED" : "ACTIVE";
      color statusColor = g_tradingPaused ? DashDangerRed : DashSuccessGreen;
      DrawStatusDot("StatusDot", contentX + 10, cardY + 40, statusColor, 7);
      CreateLabel("StatusText", contentX + 22, cardY + 38, "Status: " + status, DashTextSecondary, DashboardFontSize - 1);
   }
   else
   {
      // Status only (no buttons)
      int statusCardHeight = 28;
      DrawCard("Status", x + cardGap, cardY, cardWidth, statusCardHeight, DashCardBgColor, DashCardBorderColor);

      string status = g_tradingPaused ? "PAUSED" : "ACTIVE";
      color statusColor = g_tradingPaused ? DashDangerRed : DashSuccessGreen;
      DrawStatusDot("StatusDot", contentX + 10, cardY + 8, statusColor, 7);
      CreateLabel("StatusText", contentX + 22, cardY + 6, "Status: " + status, DashTextSecondary, DashboardFontSize - 1);
   }
}

//+------------------------------------------------------------------+
//| Draw profile table                                               |
//+------------------------------------------------------------------+
int DrawProfileTable(int x, int y)
{
   int fontSize = DashboardFontSize;           // Compact font
   int lineHeight = fontSize + 3;              // Compact spacing
   int col1X = x + 10;                         // Left column
   int col2X = x + 190;                        // Right column

   CreateLabel("ProfileHeader", x + 10, y, "-------- 12 PROFILES --------", clrDimGray, fontSize);
   y += lineHeight + 2;

   // On Monday, show a note that profiles become active from Tuesday
   if(g_currentDayOfWeek == 0)
   {
      CreateLabel("ProfNote", x + 10, y, "(Profiles activate from Tue)", clrYellow, fontSize);
      y += lineHeight;
   }

   // Display profiles in 2 columns (6 per column)
   int startY = y;
   for(int i = 1; i <= 12; i++)
   {
      string statusSymbol = GetProfileStatusSymbol(g_profiles[i].status);
      color statusColor = DashboardTextColor;

      switch(g_profiles[i].status)
      {
         case STATUS_INACTIVE:    statusColor = ConditionPendingColor; break;
         case STATUS_POTENTIAL:   statusColor = clrYellow; break;
         case STATUS_ACTIVE:      statusColor = BullishColor; break;
         case STATUS_CONFIRMED:   statusColor = clrAqua; break;
         case STATUS_INVALIDATED: statusColor = BearishColor; break;
      }

      string abbrevName = GetProfileAbbreviation(g_profiles[i].name);
      string line = statusSymbol + " " + abbrevName;

      if(i <= 6)
      {
         // Left column (profiles 1-6)
         CreateLabel("Prof" + IntegerToString(i), col1X, startY + ((i-1) * lineHeight), line, statusColor, fontSize);
      }
      else
      {
         // Right column (profiles 7-12)
         CreateLabel("Prof" + IntegerToString(i), col2X, startY + ((i-7) * lineHeight), line, statusColor, fontSize);
      }
   }

   y = startY + (6 * lineHeight) + 4;
   return y;
}

//+------------------------------------------------------------------+
//| Draw conditions checklist                                        |
//+------------------------------------------------------------------+
int DrawConditionsChecklist(int x, int y)
{
   int fontSize = DashboardFontSize + 1;  // Larger font for checklist
   int lineHeight = fontSize + 8;         // More spacing

   // Get checklist data based on active model (no pointers - MQL5 structs don't support them)
   string modelName;
   int totalConditions;
   int metConditions;
   bool isReady;

   switch(ActiveModel)
   {
      case MODEL_OSOK:
         modelName = g_osokChecklist.modelName;
         totalConditions = g_osokChecklist.totalConditions;
         metConditions = g_osokChecklist.metConditions;
         isReady = g_osokChecklist.isReady;
         break;
      case MODEL_30_PIPS:
         modelName = g_scalp30Checklist.modelName;
         totalConditions = g_scalp30Checklist.totalConditions;
         metConditions = g_scalp30Checklist.metConditions;
         isReady = g_scalp30Checklist.isReady;
         break;
      case MODEL_SILVER_BULLET:
         modelName = g_sbChecklist.modelName;
         totalConditions = g_sbChecklist.totalConditions;
         metConditions = g_sbChecklist.metConditions;
         isReady = g_sbChecklist.isReady;
         break;
      default:
         return y;
   }

   // Header with full-width separator
   CreateLabel("CheckHeader", x + 15, y, "---------- " + modelName + " CONDITIONS ----------", DashboardTextColor, fontSize + 1);
   y += lineHeight + 2;

   // Draw conditions based on active model - FULL WIDTH
   for(int i = 0; i < totalConditions; i++)
   {
      string condName;
      string condValue;
      bool condMet;

      // Get condition data based on model
      switch(ActiveModel)
      {
         case MODEL_OSOK:
            condName = g_osokChecklist.conditions[i].name;
            condValue = g_osokChecklist.conditions[i].value;
            condMet = g_osokChecklist.conditions[i].isMet;
            break;
         case MODEL_30_PIPS:
            condName = g_scalp30Checklist.conditions[i].name;
            condValue = g_scalp30Checklist.conditions[i].value;
            condMet = g_scalp30Checklist.conditions[i].isMet;
            break;
         case MODEL_SILVER_BULLET:
            condName = g_sbChecklist.conditions[i].name;
            condValue = g_sbChecklist.conditions[i].value;
            condMet = g_sbChecklist.conditions[i].isMet;
            break;
         default:
            continue;
      }

      string checkMark = condMet ? "[v]" : "[ ]";
      color checkColor = condMet ? ConditionMetColor : ConditionPendingColor;

      // Full condition line with name
      string line = checkMark + "  " + condName;
      CreateLabel("Cond" + IntegerToString(i), x + 15, y, line, checkColor, fontSize);

      // Value on right side - positioned for compact 380px panel
      CreateLabel("CondVal" + IntegerToString(i), x + 220, y, condValue, checkColor, fontSize);

      y += lineHeight;
   }

   // Entry ready status - larger and more prominent
   y += 8;
   string readyStr = isReady ? ">>> ENTRY READY! <<<" : "[ " + IntegerToString(metConditions) + " / " + IntegerToString(totalConditions) + " conditions met ]";
   color readyColor = isReady ? BullishColor : clrYellow;
   CreateLabel("EntryReady", x + 15, y, readyStr, readyColor, fontSize + 2);
   y += lineHeight + 5;

   return y;
}

//+------------------------------------------------------------------+
//| Create text label                                                |
//+------------------------------------------------------------------+
void CreateLabel(string name, int x, int y, string text, color clr, int fontSize)
{
   string objName = EA_PREFIX + name;

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ArrayResize(g_dashboardObjects, ArraySize(g_dashboardObjects) + 1);
      g_dashboardObjects[ArraySize(g_dashboardObjects) - 1] = objName;
   }

   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetString(0, objName, OBJPROP_FONT, "Consolas");
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);   // Keep in front of chart
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 11);    // Labels above dashboard background
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Create clickable button                                          |
//+------------------------------------------------------------------+
void CreateButton(string name, int xPos, int yPos, int width, int height,
                  string text, color bgColor, color textColor)
{
   string objName = EA_PREFIX + name;

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_BUTTON, 0, 0, 0);
      ArrayResize(g_dashboardObjects, ArraySize(g_dashboardObjects) + 1);
      g_dashboardObjects[ArraySize(g_dashboardObjects) - 1] = objName;
   }

   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, xPos);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, yPos);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   ObjectSetString(0, objName, OBJPROP_TEXT, text);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, textColor);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, clrWhite);
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, 10);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 12);   // Buttons on top
   ObjectSetInteger(0, objName, OBJPROP_STATE, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw card background (modern dashboard style)                    |
//+------------------------------------------------------------------+
void DrawCard(string name, int x, int y, int width, int height, color bgColor, color borderColor)
{
   string objName = EA_PREFIX + "Card_" + name;

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      ArrayResize(g_dashboardObjects, ArraySize(g_dashboardObjects) + 1);
      g_dashboardObjects[ArraySize(g_dashboardObjects) - 1] = objName;
   }

   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetInteger(0, objName, OBJPROP_XSIZE, width);
   ObjectSetInteger(0, objName, OBJPROP_YSIZE, height);
   ObjectSetInteger(0, objName, OBJPROP_BGCOLOR, bgColor);
   ObjectSetInteger(0, objName, OBJPROP_BORDER_COLOR, borderColor);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 10);   // Cards above main background
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw mini price box (for WH, EQ, WL display)                     |
//+------------------------------------------------------------------+
void DrawMiniPriceBox(string name, int x, int y, int width, int height,
                       string label, string value, color boxColor, color textColor)
{
   // Draw box background
   DrawCard(name + "_Box", x, y, width, height, boxColor, boxColor);

   // Draw label (top)
   CreateLabel(name + "_Lbl", x + 5, y + 3, label, textColor, DashboardFontSize - 1);

   // Draw value (bottom, larger)
   CreateLabel(name + "_Val", x + 5, y + 15, value, textColor, DashboardFontSize);
}

//+------------------------------------------------------------------+
//| Draw status dot indicator                                        |
//+------------------------------------------------------------------+
void DrawStatusDot(string name, int x, int y, color dotColor, int fontSize = 8)
{
   string objName = EA_PREFIX + "Dot_" + name;

   if(ObjectFind(0, objName) < 0)
   {
      ObjectCreate(0, objName, OBJ_LABEL, 0, 0, 0);
      ArrayResize(g_dashboardObjects, ArraySize(g_dashboardObjects) + 1);
      g_dashboardObjects[ArraySize(g_dashboardObjects) - 1] = objName;
   }

   // Use bullet character ●
   ObjectSetInteger(0, objName, OBJPROP_XDISTANCE, x);
   ObjectSetInteger(0, objName, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, objName, OBJPROP_TEXT, "●");
   ObjectSetString(0, objName, OBJPROP_FONT, "Arial");
   ObjectSetInteger(0, objName, OBJPROP_FONTSIZE, fontSize);
   ObjectSetInteger(0, objName, OBJPROP_COLOR, dotColor);
   ObjectSetInteger(0, objName, OBJPROP_CORNER, CORNER_LEFT_UPPER);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 11);   // Status dots above cards
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw profile table - Modern card style with status dots          |
//+------------------------------------------------------------------+
int DrawProfileTableModern(int baseX, int cardY, int cardWidth, int contentX)
{
   int cardHeight = 125;
   int cardGap = 4;

   DrawCard("Profiles", baseX + cardGap, cardY, cardWidth, cardHeight, DashCardBgColor, DashCardBorderColor);

   int fontSize = DashboardFontSize - 1;
   int lineHeight = fontSize + 5;

   // Section title
   CreateLabel("ProfilesTitle", contentX + 4, cardY + 5, "PROFILES", DashTextSecondary, fontSize);

   // On Monday, show note
   if(g_currentDayOfWeek == 0)
   {
      CreateLabel("ProfNote", contentX + 80, cardY + 5, "(from Tue)", DashWarningYellow, fontSize - 1);
   }

   // 2-column layout - wider spacing for 360px dashboard
   int col1X = contentX + 4;
   int col2X = contentX + 175;  // Increased from 155 for better spacing
   int startY = cardY + 22;

   for(int i = 1; i <= 12; i++)
   {
      // Get status dot color
      color dotColor = DashTextSecondary;  // Default gray
      switch(g_profiles[i].status)
      {
         case STATUS_INACTIVE:    dotColor = DashTextSecondary; break;
         case STATUS_POTENTIAL:   dotColor = DashWarningYellow; break;
         case STATUS_ACTIVE:      dotColor = DashSuccessGreen; break;
         case STATUS_CONFIRMED:   dotColor = DashAccentBlue; break;
         case STATUS_INVALIDATED: dotColor = DashDangerRed; break;
      }

      string abbrevName = GetProfileAbbreviation(g_profiles[i].name);
      int colX = (i <= 6) ? col1X : col2X;
      int rowIndex = (i <= 6) ? (i - 1) : (i - 7);
      int yPos = startY + (rowIndex * lineHeight);

      // Draw dot + profile name - larger dots (8 instead of 6)
      DrawStatusDot("Prof" + IntegerToString(i) + "Dot", colX, yPos + 1, dotColor, 8);
      CreateLabel("Prof" + IntegerToString(i) + "Name", colX + 14, yPos, abbrevName, DashTextPrimary, fontSize);
   }

   return cardY + cardHeight;
}

//+------------------------------------------------------------------+
//| Draw conditions checklist - Modern card style with dots          |
//+------------------------------------------------------------------+
int DrawConditionsChecklistModern(int baseX, int cardY, int cardWidth, int contentX)
{
   int cardHeight = 145;
   int cardGap = 4;

   DrawCard("Conditions", baseX + cardGap, cardY, cardWidth, cardHeight, DashCardBgColor, DashCardBorderColor);

   int fontSize = DashboardFontSize - 1;
   int lineHeight = fontSize + 6;

   // Get model data
   string modelName;
   int totalConditions;
   int metConditions;
   bool isReady;

   switch(ActiveModel)
   {
      case MODEL_OSOK:
         modelName = "OSOK";
         totalConditions = g_osokChecklist.totalConditions;
         metConditions = g_osokChecklist.metConditions;
         isReady = g_osokChecklist.isReady;
         break;
      case MODEL_30_PIPS:
         modelName = "30 PIPS";
         totalConditions = g_scalp30Checklist.totalConditions;
         metConditions = g_scalp30Checklist.metConditions;
         isReady = g_scalp30Checklist.isReady;
         break;
      case MODEL_SILVER_BULLET:
         modelName = "SILVER BULLET";
         totalConditions = g_sbChecklist.totalConditions;
         metConditions = g_sbChecklist.metConditions;
         isReady = g_sbChecklist.isReady;
         break;
      default:
         return cardY + cardHeight;
   }

   // Section title
   CreateLabel("CondTitle", contentX + 4, cardY + 5, modelName + " CONDITIONS", DashTextSecondary, fontSize);

   int startY = cardY + 22;

   // Draw conditions
   for(int i = 0; i < totalConditions && i < 7; i++)
   {
      string condName;
      string condValue;
      bool condMet;

      switch(ActiveModel)
      {
         case MODEL_OSOK:
            condName = g_osokChecklist.conditions[i].name;
            condValue = g_osokChecklist.conditions[i].value;
            condMet = g_osokChecklist.conditions[i].isMet;
            break;
         case MODEL_30_PIPS:
            condName = g_scalp30Checklist.conditions[i].name;
            condValue = g_scalp30Checklist.conditions[i].value;
            condMet = g_scalp30Checklist.conditions[i].isMet;
            break;
         case MODEL_SILVER_BULLET:
            condName = g_sbChecklist.conditions[i].name;
            condValue = g_sbChecklist.conditions[i].value;
            condMet = g_sbChecklist.conditions[i].isMet;
            break;
         default:
            continue;
      }

      color dotColor = condMet ? DashSuccessGreen : DashTextSecondary;
      int yPos = startY + (i * lineHeight);

      // Dot + condition name - larger dots (8 instead of 6)
      DrawStatusDot("Cond" + IntegerToString(i) + "Dot", contentX + 4, yPos + 1, dotColor, 8);
      CreateLabel("Cond" + IntegerToString(i) + "Name", contentX + 18, yPos, condName, dotColor, fontSize);

      // Value on right (truncated if needed)
      string shortVal = StringLen(condValue) > 12 ? StringSubstr(condValue, 0, 10) + ".." : condValue;
      CreateLabel("Cond" + IntegerToString(i) + "Val", contentX + 200, yPos, shortVal, dotColor, fontSize - 1);
   }

   // Progress badge at bottom - centered in card
   int badgeY = cardY + cardHeight - 22;
   color badgeColor = isReady ? DashSuccessGreen : DashWarningYellow;
   string badgeText = isReady ? "READY" : IntegerToString(metConditions) + "/" + IntegerToString(totalConditions);

   // Badge background - centered (cardWidth ~344, badge 100px, so center offset ~122)
   int badgeWidth = 100;
   int badgeX = contentX + 122;  // Centered position
   DrawCard("CondBadge", badgeX, badgeY, badgeWidth, 18, badgeColor, badgeColor);
   CreateLabel("CondBadgeText", badgeX + 35, badgeY + 3, badgeText, DashTextPrimary, fontSize);

   return cardY + cardHeight;
}

//+------------------------------------------------------------------+
//| Draw HTF Narrative panel - Modern card style                     |
//+------------------------------------------------------------------+
int DrawHTFNarrativePanelModern(int baseX, int cardY, int cardWidth, int contentX)
{
   int cardHeight = 80;
   int cardGap = 4;

   DrawCard("HTF", baseX + cardGap, cardY, cardWidth, cardHeight, DashCardBgColor, DashCardBorderColor);

   int fontSize = DashboardFontSize - 1;
   int lineHeight = fontSize + 5;

   // Update HTF analysis
   AnalyzeHTFNarrative();

   // Section title
   CreateLabel("HTFTitle", contentX + 4, cardY + 5, "HTF NARRATIVE", DashTextSecondary, fontSize);

   // Bias row with dots
   int biasY = cardY + 22;
   string mnBiasStr = BiasToShortString(g_htfNarrative.monthlyBias);
   string wkBiasStr = BiasToShortString(g_htfNarrative.weeklyBias);
   string d1BiasStr = BiasToShortString(g_htfNarrative.dailyBias);

   color mnColor = GetBiasColor(g_htfNarrative.monthlyBias);
   color wkColor = GetBiasColor(g_htfNarrative.weeklyBias);
   color d1Color = GetBiasColor(g_htfNarrative.dailyBias);

   // MN - larger dot (10)
   CreateLabel("HTF_MN_Lbl", contentX + 4, biasY, "MN", DashTextSecondary, fontSize - 1);
   DrawStatusDot("HTF_MN_Dot", contentX + 28, biasY + 1, mnColor, 10);
   CreateLabel("HTF_MN_Val", contentX + 44, biasY, mnBiasStr, mnColor, fontSize);

   // WK - increased spacing for 360px width
   CreateLabel("HTF_WK_Lbl", contentX + 115, biasY, "WK", DashTextSecondary, fontSize - 1);
   DrawStatusDot("HTF_WK_Dot", contentX + 139, biasY + 1, wkColor, 10);
   CreateLabel("HTF_WK_Val", contentX + 155, biasY, wkBiasStr, wkColor, fontSize);

   // D1 - increased spacing for 360px width
   CreateLabel("HTF_D1_Lbl", contentX + 226, biasY, "D1", DashTextSecondary, fontSize - 1);
   DrawStatusDot("HTF_D1_Dot", contentX + 250, biasY + 1, d1Color, 10);
   CreateLabel("HTF_D1_Val", contentX + 266, biasY, d1BiasStr, d1Color, fontSize);

   // Zone display
   int zoneY = biasY + lineHeight;
   color zoneColor = DashTextPrimary;
   if(g_htfNarrative.zone == "PREMIUM") zoneColor = DashDangerRed;
   else if(g_htfNarrative.zone == "DISCOUNT") zoneColor = DashSuccessGreen;

   CreateLabel("HTF_Zone_Lbl", contentX + 4, zoneY, "Zone:", DashTextSecondary, fontSize);
   CreateLabel("HTF_Zone_Val", contentX + 45, zoneY, g_htfNarrative.zone, zoneColor, fontSize);

   // Liquidity levels - spread for 360px width
   int liqY = zoneY + lineHeight;
   CreateLabel("HTF_BSL_Lbl", contentX + 4, liqY, "BSL:", DashTextSecondary, fontSize);
   CreateLabel("HTF_BSL_Val", contentX + 38, liqY, DoubleToString(g_htfNarrative.nearestBSL, g_digits), DashSuccessGreen, fontSize);
   CreateLabel("HTF_SSL_Lbl", contentX + 175, liqY, "SSL:", DashTextSecondary, fontSize);
   CreateLabel("HTF_SSL_Val", contentX + 209, liqY, DoubleToString(g_htfNarrative.nearestSSL, g_digits), DashDangerRed, fontSize);

   return cardY + cardHeight;
}

//+------------------------------------------------------------------+
//| Find best zone for a specific trade direction                     |
//+------------------------------------------------------------------+
bool FindBestZoneForDirection(bool forTrendTrade, PDAZone &bestZone, int &confidence)
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double eq = g_weeklyData.equilibrium;
   bool found = false;
   confidence = 0;

   // Determine what type of zone we need based on bias and trade direction
   // WITH-TREND (forTrendTrade=true):
   //   BULL bias -> LONG  -> Bullish zones in Discount (below EQ)
   //   BEAR bias -> SHORT -> Bearish zones in Premium (above EQ)
   // COUNTER-TREND (forTrendTrade=false):
   //   BULL bias -> SHORT -> Bearish zones in Premium (above EQ)
   //   BEAR bias -> LONG  -> Bullish zones in Discount (below EQ)

   bool needBullishZone = false;
   bool needInDiscount = false;

   if(forTrendTrade)
   {
      // With-trend trades
      if(g_weeklyBias == BIAS_BULLISH)
      {
         needBullishZone = true;   // LONG needs bullish zone
         needInDiscount = true;    // Entry at discount
      }
      else if(g_weeklyBias == BIAS_BEARISH)
      {
         needBullishZone = false;  // SHORT needs bearish zone
         needInDiscount = false;   // Entry at premium
      }
      else
      {
         return false;  // No bias = no recommendation
      }
   }
   else
   {
      // Counter-trend trades
      if(g_weeklyBias == BIAS_BULLISH)
      {
         needBullishZone = false;  // Counter SHORT needs bearish zone
         needInDiscount = false;   // Entry at premium
      }
      else if(g_weeklyBias == BIAS_BEARISH)
      {
         needBullishZone = true;   // Counter LONG needs bullish zone
         needInDiscount = true;    // Entry at discount
      }
      else
      {
         return false;  // No bias = no recommendation
      }
   }

   // Helper macro to check if zone qualifies for this trade direction
   // IMPORTANT: Do NOT check shouldDisplay here - that controls chart visibility only
   // We need to search ALL valid zones for recommendations (including counter-trend zones)
   // Zone must match: direction (bull/bear) AND location (discount/premium)
   #define ZONE_QUALIFIES(zone) \
      (zone.isValid && !zone.isMitigated && \
       zone.isBullish == needBullishZone && \
       (((zone.priceLow + zone.priceHigh) / 2 < eq) == needInDiscount))

   // Scan all zone types - only consider zones that qualify
   for(int i = 0; i < g_pdaMatrix.fvgCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.fvgZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.fvgZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.fvgZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.obCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.obZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.obZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.obZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.breakerCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.breakerZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.breakerZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.breakerZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.mitigationCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.mitigationZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.mitigationZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.mitigationZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.rejectionCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.rejectionZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.rejectionZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.rejectionZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.liquidityVoidCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.liquidityVoidZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.liquidityVoidZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.liquidityVoidZones[i]; found = true; }
      }

   for(int i = 0; i < g_pdaMatrix.viCount; i++)
      if(ZONE_QUALIFIES(g_pdaMatrix.volumeImbalanceZones[i]))
      {
         int conf = CalculatePDAConfidence(g_pdaMatrix.volumeImbalanceZones[i], currentPrice, eq, forTrendTrade);
         if(conf > confidence) { confidence = conf; bestZone = g_pdaMatrix.volumeImbalanceZones[i]; found = true; }
      }

   #undef ZONE_QUALIFIES

   return found;
}

//+------------------------------------------------------------------+
//| Draw PDA Narrative Panel with entry recommendations               |
//+------------------------------------------------------------------+
int DrawPDANarrativePanel(int baseX, int cardY, int cardWidth, int contentX)
{
   if(!PDA_ShowNarrativePanel || !PDA_Enable) return cardY;

   int fontSize = DashboardFontSize - 1;
   int lineHeight = fontSize + 6;
   int cardGap = 4;

   // Check if price is inside any zones (for dynamic card height)
   PDAZone primaryZone;
   PDAZone secondaryZones[];
   bool hasPrimary = false;
   int secondaryCount = 0;
   int zonesFound = FindCurrentZones(primaryZone, hasPrimary, secondaryZones, secondaryCount);

   // Calculate card height dynamically based on content
   // Base: header + location + trend + counter + liquidity = 5 lines
   int baseLines = 5;
   int immediateLines = 0;
   if(zonesFound > 0)
   {
      immediateLines = 1; // Separator
      if(hasPrimary) immediateLines += 2; // Primary zone + context
      immediateLines += MathMin(secondaryCount, 2) * 2; // Secondary zones + context (max 2)
   }
   int cardHeight = lineHeight * (baseLines + immediateLines) + 12;

   // Draw card background
   DrawCard("PDA_Narrative", baseX + cardGap, cardY, cardWidth, cardHeight, DashCardBgColor, DashCardBorderColor);

   // Header: "PDA TARGETS"
   int headerY = cardY + 4;
   CreateLabel("PDA_Narrative_Header", contentX + 4, headerY, "PDA TARGETS", DashTextPrimary, fontSize);

   int currentY = headerY + lineHeight;

   // ========== LOCATION CONTEXT LINE (NEW) ==========
   string locationPct = IntegerToString((int)(g_htfNarrative.zonePercent * 100)) + "%";
   string locationLine = g_htfNarrative.zone + " " + locationPct + " | " + GetLocationContext();
   color locColor = (g_htfNarrative.zone == "PREMIUM") ? DashDangerRed :
                    (g_htfNarrative.zone == "DISCOUNT") ? DashSuccessGreen : DashTextSecondary;
   CreateLabel("PDA_Location", contentX + 4, currentY, locationLine, locColor, fontSize - 1);
   currentY += lineHeight;

   // ========== WITH-TREND RECOMMENDATION ==========
   PDAZone trendZone;
   int trendConf = 0;
   bool hasTrendZone = FindBestZoneForDirection(true, trendZone, trendConf);

   string trendDir = "";
   string trendZoneType = "";
   color trendColor = DashTextSecondary;

   if(g_weeklyBias == BIAS_BULLISH)
   {
      trendDir = "LONG";
      trendZoneType = "DISCOUNT";
      trendColor = DashSuccessGreen;
   }
   else if(g_weeklyBias == BIAS_BEARISH)
   {
      trendDir = "SHORT";
      trendZoneType = "PREMIUM";
      trendColor = DashDangerRed;
   }
   else
   {
      trendDir = "---";
      trendZoneType = "WAIT";
      trendColor = DashWarningYellow;
   }

   if(g_weeklyBias != BIAS_NEUTRAL && hasTrendZone)
   {
      string trendLabel = GetPDALabel(trendZone.type, trendZone.isBullish);
      double trendPrice = (trendZone.priceLow + trendZone.priceHigh) / 2;

      // Calculate distance to zone
      bool isAbove;
      int dist = (int)GetDistanceToZone(trendZone, isAbove);
      string distStr = isAbove ? "[" + IntegerToString(dist) + "v]" : "[" + IntegerToString(dist) + "^]";

      string trendLine = ">" + trendDir + " " + IntegerToString(trendConf) + "% " + trendLabel + " @ " + DoubleToString(trendPrice, g_digits) + " " + distStr;
      CreateLabel("PDA_Trend_Rec", contentX + 4, currentY, trendLine, trendColor, fontSize - 1);
   }
   else if(g_weeklyBias != BIAS_NEUTRAL)
   {
      CreateLabel("PDA_Trend_Rec", contentX + 4, currentY, ">" + trendDir + " - No " + trendZoneType + " zone", trendColor, fontSize - 1);
   }
   else
   {
      CreateLabel("PDA_Trend_Rec", contentX + 4, currentY, "> WAIT FOR CLEAR BIAS", DashWarningYellow, fontSize - 1);
   }

   currentY += lineHeight;

   // ========== COUNTER-TREND RECOMMENDATION ==========
   PDAZone counterZone;
   int counterConf = 0;
   bool hasCounterZone = FindBestZoneForDirection(false, counterZone, counterConf);

   string counterDir = "";
   string counterZoneType = "";
   color counterColor = DashTextSecondary;

   if(g_weeklyBias == BIAS_BULLISH)
   {
      counterDir = "SHORT";
      counterZoneType = "PREMIUM";
      counterColor = C'180,80,80';  // Muted red for counter-trend
   }
   else if(g_weeklyBias == BIAS_BEARISH)
   {
      counterDir = "LONG";
      counterZoneType = "DISCOUNT";
      counterColor = C'80,180,80';  // Muted green for counter-trend
   }

   if(g_weeklyBias != BIAS_NEUTRAL && hasCounterZone)
   {
      string counterLabel = GetPDALabel(counterZone.type, counterZone.isBullish);
      double counterPrice = (counterZone.priceLow + counterZone.priceHigh) / 2;

      // Calculate distance to zone
      bool isAbove;
      int dist = (int)GetDistanceToZone(counterZone, isAbove);
      string distStr = isAbove ? "[" + IntegerToString(dist) + "v]" : "[" + IntegerToString(dist) + "^]";

      string counterLine = "<" + counterDir + " " + IntegerToString(counterConf) + "% " + counterLabel + " @ " + DoubleToString(counterPrice, g_digits) + " " + distStr;
      CreateLabel("PDA_Counter_Rec", contentX + 4, currentY, counterLine, counterColor, fontSize - 1);
   }
   else if(g_weeklyBias != BIAS_NEUTRAL)
   {
      CreateLabel("PDA_Counter_Rec", contentX + 4, currentY, "<" + counterDir + " - No " + counterZoneType + " zone", counterColor, fontSize - 1);
   }
   else
   {
      CreateLabel("PDA_Counter_Rec", contentX + 4, currentY, "< Counter: N/A (no bias)", DashTextSecondary, fontSize - 1);
   }

   currentY += lineHeight;

   // ========== IMMEDIATE ENTRY ZONES (NEW) ==========
   if(zonesFound > 0)
   {
      // Separator line
      CreateLabel("PDA_Sep2", contentX + 4, currentY, "------------------------", DashCardBorderColor, fontSize - 2);
      currentY += lineHeight - 2;

      // PRIMARY zone (bias-aligned) - gets star marker
      if(hasPrimary)
      {
         string primaryLabel = GetPDALabel(primaryZone.type, primaryZone.isBullish);
         string primaryDir = primaryZone.isBullish ? "LONG" : "SHORT";
         string primaryLine = "* PRIMARY: IN " + primaryLabel + " *";
         color primaryColor = primaryZone.isBullish ? DashSuccessGreen : DashDangerRed;

         CreateLabel("PDA_Primary", contentX + 4, currentY, primaryLine, primaryColor, fontSize);
         currentY += lineHeight;

         string primaryCtx = "  > " + primaryDir + " entry (bias-aligned)";
         CreateLabel("PDA_PrimaryCtx", contentX + 4, currentY, primaryCtx, DashTextSecondary, fontSize - 1);
         currentY += lineHeight;
      }

      // SECONDARY zones (counter-trend) - max 2
      for(int i = 0; i < secondaryCount && i < 2; i++)
      {
         string secLabel = GetPDALabel(secondaryZones[i].type, secondaryZones[i].isBullish);
         string secDir = secondaryZones[i].isBullish ? "LONG" : "SHORT";
         string secLine = "* ALSO IN: " + secLabel;
         color secColor = secondaryZones[i].isBullish ? C'80,180,80' : C'180,80,80';  // Muted colors

         CreateLabel("PDA_Secondary" + IntegerToString(i), contentX + 4, currentY, secLine, secColor, fontSize - 1);
         currentY += lineHeight;

         string secCtx = "  > " + secDir + " entry (counter-trend)";
         CreateLabel("PDA_SecCtx" + IntegerToString(i), contentX + 4, currentY, secCtx, DashTextSecondary, fontSize - 2);
         currentY += lineHeight;
      }
   }

   // ========== LIQUIDITY STATUS LINE ==========
   string liqStatus = IsLiquidityRaided() ? "* Liquidity Raided" : "o Awaiting Raid";
   color liqColor = IsLiquidityRaided() ? DashSuccessGreen : DashTextSecondary;
   CreateLabel("PDA_Liquidity_Status", contentX + 4, currentY, liqStatus, liqColor, fontSize - 1);

   // Show which liquidity
   if(g_osokSetup.liquiditySwept)
   {
      string sweepInfo = g_osokSetup.sweepWasBullish ? " (Mon Low)" : " (Mon High)";
      CreateLabel("PDA_Liquidity_Detail", contentX + 130, currentY, sweepInfo, liqColor, fontSize - 1);
   }

   return cardY + cardHeight;
}

//+------------------------------------------------------------------+
//| Draw manual entry buttons (legacy - kept for compatibility)      |
//+------------------------------------------------------------------+
int DrawManualButtons(int x, int y)
{
   int btnWidth = 70;
   int btnHeight = 25;
   int spacing = 15;

   // BUY button - green
   CreateButton("BtnBuy", x + 10, y, btnWidth, btnHeight, "BUY", clrDarkGreen, clrWhite);

   // SELL button - red
   CreateButton("BtnSell", x + 10 + btnWidth + spacing, y, btnWidth, btnHeight, "SELL", clrDarkRed, clrWhite);

   y += btnHeight + 8;
   return y;
}

//+------------------------------------------------------------------+
//| Execute manual trade entry                                       |
//+------------------------------------------------------------------+
void ExecuteManualEntry(bool isBuy)
{
   // Check if trading is allowed
   if(TradeMode == MODE_VISUAL)
   {
      Print("Manual entry disabled in Visual Only mode");
      return;
   }

   // Check trade limits
   if(g_tradesToday >= MaxTradesPerDay)
   {
      Print("Manual entry blocked: Max trades per day reached");
      return;
   }
   if(g_tradesThisWeek >= MaxTradesPerWeek)
   {
      Print("Manual entry blocked: Max trades per week reached");
      return;
   }

   // Check direction filters
   if(isBuy && TradeShortOnly)
   {
      Print("Manual BUY blocked: Short Only mode active");
      return;
   }
   if(!isBuy && TradeLongOnly)
   {
      Print("Manual SELL blocked: Long Only mode active");
      return;
   }

   // Get current price
   double ask = SymbolInfoDouble(_Symbol, SYMBOL_ASK);
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double entryPrice = isBuy ? ask : bid;

   // Calculate stop loss based on ATR or fixed pips
   double atrValue = GetATRValue(14);
   double stopDistance = MathMax(atrValue * 1.5, 20 * g_pipValue);
   double stopLoss = isBuy ? (entryPrice - stopDistance) : (entryPrice + stopDistance);

   // Calculate take profits
   double tp1Distance = TP1_Pips * g_pipValue;
   double tp2Distance = TP2_Pips * g_pipValue;
   double tp2 = isBuy ? (entryPrice + tp2Distance) : (entryPrice - tp2Distance);

   // Calculate lot size
   double stopPoints = MathAbs(entryPrice - stopLoss) / g_point;
   double lotSize = CalculateLotSize(stopPoints);

   // Place trade
   string comment = "ICT_WP_Manual_" + (isBuy ? "BUY" : "SELL");

   bool result = false;
   if(isBuy)
      result = trade.Buy(lotSize, _Symbol, ask, stopLoss, tp2, comment);
   else
      result = trade.Sell(lotSize, _Symbol, bid, stopLoss, tp2, comment);

   if(result)
   {
      g_tradesToday++;
      g_tradesThisWeek++;
      g_lastTradeDate = TimeCurrent();

      if(AlertOnEntry)
         SendAlert("Manual " + (isBuy ? "BUY" : "SELL") + " executed at " + DoubleToString(entryPrice, g_digits));

      Print("Manual ", (isBuy ? "BUY" : "SELL"), " executed: ", lotSize, " lots at ", entryPrice);
   }
   else
   {
      Print("Manual entry failed: ", trade.ResultRetcode(), " - ", trade.ResultRetcodeDescription());
   }
}

//+------------------------------------------------------------------+
//| Get ATR value for SL calculation                                 |
//+------------------------------------------------------------------+
double GetATRValue(int period)
{
   double atr[];
   ArraySetAsSeries(atr, true);

   int handle = iATR(_Symbol, PERIOD_H1, period);
   if(handle == INVALID_HANDLE) return 50 * g_pipValue;

   if(CopyBuffer(handle, 0, 0, 1, atr) > 0)
   {
      IndicatorRelease(handle);
      return atr[0];
   }

   IndicatorRelease(handle);
   return 50 * g_pipValue;
}

//+------------------------------------------------------------------+
//| Draw HTF Narrative Panel                                         |
//+------------------------------------------------------------------+
int DrawHTFNarrativePanel(int x, int y)
{
   int fontSize = DashboardFontSize;
   int lineHeight = fontSize + 3;

   // Update HTF analysis (caches internally)
   AnalyzeHTFNarrative();

   // Header
   CreateLabel("HTFHeader", x + 10, y, "-------- HTF NARRATIVE --------", clrDimGray, fontSize);
   y += lineHeight + 2;

   // Bias line: MN | WK | D1
   string mnBiasStr = BiasToShortString(g_htfNarrative.monthlyBias);
   string wkBiasStr = BiasToShortString(g_htfNarrative.weeklyBias);
   string d1BiasStr = BiasToShortString(g_htfNarrative.dailyBias);

   color mnColor = GetBiasColor(g_htfNarrative.monthlyBias);
   color wkColor = GetBiasColor(g_htfNarrative.weeklyBias);
   color d1Color = GetBiasColor(g_htfNarrative.dailyBias);

   // Draw bias indicators
   CreateLabel("HTF_MN", x + 10, y, "MN:", DashboardTextColor, fontSize);
   CreateLabel("HTF_MN_Val", x + 40, y, mnBiasStr, mnColor, fontSize);
   CreateLabel("HTF_WK", x + 110, y, "WK:", DashboardTextColor, fontSize);
   CreateLabel("HTF_WK_Val", x + 140, y, wkBiasStr, wkColor, fontSize);
   CreateLabel("HTF_D1", x + 210, y, "D1:", DashboardTextColor, fontSize);
   CreateLabel("HTF_D1_Val", x + 240, y, d1BiasStr, d1Color, fontSize);
   y += lineHeight;

   // Zone display
   color zoneColor = clrWhite;
   if(g_htfNarrative.zone == "PREMIUM") zoneColor = BearishColor;
   else if(g_htfNarrative.zone == "DISCOUNT") zoneColor = BullishColor;

   string zoneStr = "Zone: " + g_htfNarrative.zone;
   if(g_htfNarrative.zone != "---")
   {
      string aboveBelow = (g_htfNarrative.zonePercent > 0.5) ? " (above EQ)" : " (below EQ)";
      zoneStr += aboveBelow;
   }
   CreateLabel("HTF_Zone", x + 10, y, zoneStr, zoneColor, fontSize);
   y += lineHeight;

   // Liquidity draw targets
   string bslStr = "BSL: " + DoubleToString(g_htfNarrative.nearestBSL, g_digits);
   string sslStr = "SSL: " + DoubleToString(g_htfNarrative.nearestSSL, g_digits);
   CreateLabel("HTF_BSL", x + 10, y, bslStr, BullishColor, fontSize);
   CreateLabel("HTF_SSL", x + 190, y, sslStr, BearishColor, fontSize);
   y += lineHeight;

   // PWH/PWL levels (if enabled)
   if(HTFNarrative_ShowLevels)
   {
      string pwhStr = "PWH: " + DoubleToString(g_weeklyData.pwh, g_digits);
      string pwlStr = "PWL: " + DoubleToString(g_weeklyData.pwl, g_digits);
      CreateLabel("HTF_PWH", x + 10, y, pwhStr, DashboardTextColor, fontSize);
      CreateLabel("HTF_PWL", x + 190, y, pwlStr, DashboardTextColor, fontSize);
      y += lineHeight;
   }

   y += 4;
   return y;
}

//+------------------------------------------------------------------+
//| Analyze Higher Timeframe Narrative                               |
//+------------------------------------------------------------------+
void AnalyzeHTFNarrative()
{
   // Only update on new H1 bar for efficiency
   static datetime lastH1Bar = 0;
   datetime currentH1Bar = iTime(_Symbol, PERIOD_H1, 0);
   if(currentH1Bar == lastH1Bar && g_lastHTFUpdate > 0) return;
   lastH1Bar = currentH1Bar;

   // === MONTHLY BIAS ===
   g_htfNarrative.monthlyBias = AnalyzeTimeframeBias(PERIOD_MN1, HTFNarrative_Lookback);

   // === WEEKLY BIAS ===
   g_htfNarrative.weeklyBias = AnalyzeTimeframeBias(PERIOD_W1, HTFNarrative_Lookback);

   // === DAILY BIAS ===
   g_htfNarrative.dailyBias = AnalyzeTimeframeBias(PERIOD_D1, HTFNarrative_Lookback);

   // === PREMIUM/DISCOUNT ZONE ===
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double weeklyRange = g_weeklyData.weekHigh - g_weeklyData.weekLow;

   if(weeklyRange > 0)
   {
      g_htfNarrative.zonePercent = (currentPrice - g_weeklyData.weekLow) / weeklyRange;

      if(g_htfNarrative.zonePercent > 0.618)
         g_htfNarrative.zone = "PREMIUM";
      else if(g_htfNarrative.zonePercent < 0.382)
         g_htfNarrative.zone = "DISCOUNT";
      else
         g_htfNarrative.zone = "EQUILIBRIUM";
   }
   else
   {
      g_htfNarrative.zone = "---";
      g_htfNarrative.zonePercent = 0.5;
   }

   // === LIQUIDITY TARGETS ===
   FindNearestLiquidity();

   // === MONTHLY LEVELS ===
   GetMonthlyLevels();

   // === UPDATE GLOBAL WEEKLY BIAS ===
   UpdateWeeklyBias();

   g_lastHTFUpdate = TimeCurrent();
   g_htfNarrative.lastUpdate = TimeCurrent();
}

//+------------------------------------------------------------------+
//| Analyze bias for a specific timeframe                            |
//+------------------------------------------------------------------+
ENUM_WEEKLY_BIAS AnalyzeTimeframeBias(ENUM_TIMEFRAMES tf, int lookback)
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   int barsNeeded = lookback + 10;  // Extra bars for swing detection
   if(CopyRates(_Symbol, tf, 0, barsNeeded, rates) < barsNeeded)
      return BIAS_NEUTRAL;

   // Find swing highs and lows using a more relaxed approach
   // Store multiple swings to get better structure picture
   double swingHighs[4] = {0, 0, 0, 0};
   double swingLows[4] = {0, 0, 0, 0};
   int highCount = 0, lowCount = 0;
   int swingStrength = MathMax(SwingStrength, 2);

   // Scan from recent to older (rates[0] is current bar)
   for(int i = swingStrength; i < lookback && (highCount < 4 || lowCount < 4); i++)
   {
      // Check for swing high - use < instead of <= for more swings
      bool isSwingHigh = true;
      for(int j = 1; j <= swingStrength; j++)
      {
         if(rates[i].high < rates[i-j].high || rates[i].high < rates[i+j].high)
         {
            isSwingHigh = false;
            break;
         }
      }
      if(isSwingHigh && highCount < 4)
      {
         swingHighs[highCount++] = rates[i].high;
      }

      // Check for swing low - use > instead of >= for more swings
      bool isSwingLow = true;
      for(int j = 1; j <= swingStrength; j++)
      {
         if(rates[i].low > rates[i-j].low || rates[i].low > rates[i+j].low)
         {
            isSwingLow = false;
            break;
         }
      }
      if(isSwingLow && lowCount < 4)
      {
         swingLows[lowCount++] = rates[i].low;
      }
   }

   // If not enough swings found, use simple highest/lowest approach
   if(highCount < 2 || lowCount < 2)
   {
      // Find highest high and lowest low in first half vs second half
      double firstHalfHigh = 0, secondHalfHigh = 0;
      double firstHalfLow = DBL_MAX, secondHalfLow = DBL_MAX;
      int midpoint = lookback / 2;

      for(int i = 0; i < midpoint; i++)
      {
         if(rates[i].high > firstHalfHigh) firstHalfHigh = rates[i].high;
         if(rates[i].low < firstHalfLow) firstHalfLow = rates[i].low;
      }
      for(int i = midpoint; i < lookback; i++)
      {
         if(rates[i].high > secondHalfHigh) secondHalfHigh = rates[i].high;
         if(rates[i].low < secondHalfLow) secondHalfLow = rates[i].low;
      }

      // Recent half (firstHalf) higher than older half = bullish
      if(firstHalfHigh > secondHalfHigh && firstHalfLow > secondHalfLow)
         return BIAS_BULLISH;
      else if(firstHalfHigh < secondHalfHigh && firstHalfLow < secondHalfLow)
         return BIAS_BEARISH;
      else
         return BIAS_NEUTRAL;
   }

   // swingHighs[0] = most recent swing high, swingHighs[1] = previous swing high
   // Determine bias based on swing structure (relaxed - only need ONE condition)
   bool higherHigh = swingHighs[0] > swingHighs[1];
   bool lowerHigh = swingHighs[0] < swingHighs[1];
   bool higherLow = swingLows[0] > swingLows[1];
   bool lowerLow = swingLows[0] < swingLows[1];

   // BULLISH: Higher high OR higher low (relaxed from AND)
   if(higherHigh && higherLow)
      return BIAS_BULLISH;
   else if(lowerLow && lowerHigh)
      return BIAS_BEARISH;
   // Partial structure - still indicates bias
   else if(higherHigh || higherLow)
      return BIAS_BULLISH;
   else if(lowerLow || lowerHigh)
      return BIAS_BEARISH;
   else
      return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Get weekly bias based on previous week close (ICT method)        |
//+------------------------------------------------------------------+
ENUM_WEEKLY_BIAS GetWeeklyCloseBias()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double pwClose = g_weeklyData.pwc;  // Previous week close

   // Debug: Log once per H1 bar
   static datetime lastDebugBar = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_H1, 0);
   if(currentBar != lastDebugBar)
   {
      lastDebugBar = currentBar;
      double buffer = _Point * 50;
      double diffPips = (currentPrice - pwClose) / (_Point * 10);  // Convert to pips
      string biasResult = "NEUTRAL";
      if(pwClose == 0)
         biasResult = "NEUTRAL (PWC=0!)";
      else if(currentPrice > pwClose + buffer)
         biasResult = "BULLISH";
      else if(currentPrice < pwClose - buffer)
         biasResult = "BEARISH";

      Print("=== WEEKLY CLOSE BIAS DEBUG ===");
      Print("  Current Price: ", DoubleToString(currentPrice, _Digits));
      Print("  PWC (Prev Week Close): ", DoubleToString(pwClose, _Digits));
      Print("  Difference: ", DoubleToString(diffPips, 1), " pips");
      Print("  Buffer: ", DoubleToString(buffer / _Point, 0), " points (", DoubleToString(buffer / (_Point * 10), 1), " pips)");
      Print("  Result: ", biasResult);
      Print("  PWH: ", DoubleToString(g_weeklyData.pwh, _Digits), " | PWL: ", DoubleToString(g_weeklyData.pwl, _Digits));
   }

   if(pwClose == 0) return BIAS_NEUTRAL;

   // Add a small buffer to prevent flickering around the close
   double buffer = _Point * 50;  // 5 pip buffer

   if(currentPrice > pwClose + buffer)
      return BIAS_BULLISH;
   else if(currentPrice < pwClose - buffer)
      return BIAS_BEARISH;

   return BIAS_NEUTRAL;
}

//+------------------------------------------------------------------+
//| Update g_weeklyBias based on selected bias method                |
//+------------------------------------------------------------------+
void UpdateWeeklyBias()
{
   // Debug: Log bias method and HTF values once per H1 bar
   static datetime lastBiasDebug = 0;
   datetime currentBar = iTime(_Symbol, PERIOD_H1, 0);
   if(currentBar != lastBiasDebug)
   {
      lastBiasDebug = currentBar;
      Print("=== UPDATE WEEKLY BIAS DEBUG ===");
      Print("  BiasMethod: ", EnumToString(BiasMethod));
      Print("  g_htfNarrative.weeklyBias: ", EnumToString(g_htfNarrative.weeklyBias));
      Print("  g_htfNarrative.monthlyBias: ", EnumToString(g_htfNarrative.monthlyBias));
      Print("  Current g_weeklyBias: ", EnumToString(g_weeklyBias));
   }

   switch(BiasMethod)
   {
      case BIAS_METHOD_SWING:
         g_weeklyBias = g_htfNarrative.weeklyBias;
         break;

      case BIAS_METHOD_WEEKLY_CLOSE:
         g_weeklyBias = GetWeeklyCloseBias();
         break;

      case BIAS_METHOD_COMBINED:
         // Priority: Weekly swing > Weekly close > Monthly swing
         if(g_htfNarrative.weeklyBias != BIAS_NEUTRAL)
         {
            g_weeklyBias = g_htfNarrative.weeklyBias;
         }
         else
         {
            // Try weekly close comparison
            ENUM_WEEKLY_BIAS closeBias = GetWeeklyCloseBias();
            if(closeBias != BIAS_NEUTRAL)
            {
               g_weeklyBias = closeBias;
            }
            else
            {
               // Fall back to Monthly bias
               g_weeklyBias = g_htfNarrative.monthlyBias;
            }
         }
         break;
   }
}

//+------------------------------------------------------------------+
//| Find nearest liquidity pools (BSL/SSL)                           |
//+------------------------------------------------------------------+
void FindNearestLiquidity()
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Initialize with PWH/PWL as default targets
   g_htfNarrative.nearestBSL = g_weeklyData.pwh;
   g_htfNarrative.nearestSSL = g_weeklyData.pwl;

   // Get D1 swing points for more precise liquidity
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   if(CopyRates(_Symbol, PERIOD_D1, 0, 30, rates) < 30) return;

   double closestBSL = DBL_MAX;
   double closestSSL = 0;

   for(int i = SwingStrength; i < 30 - SwingStrength; i++)
   {
      // Swing high = BSL (buy-side liquidity)
      bool isSwingHigh = true;
      for(int j = 1; j <= SwingStrength; j++)
      {
         if(rates[i].high <= rates[i-j].high || rates[i].high <= rates[i+j].high)
         {
            isSwingHigh = false;
            break;
         }
      }
      if(isSwingHigh && rates[i].high > currentPrice)
      {
         if(rates[i].high < closestBSL)
            closestBSL = rates[i].high;
      }

      // Swing low = SSL (sell-side liquidity)
      bool isSwingLow = true;
      for(int j = 1; j <= SwingStrength; j++)
      {
         if(rates[i].low >= rates[i-j].low || rates[i].low >= rates[i+j].low)
         {
            isSwingLow = false;
            break;
         }
      }
      if(isSwingLow && rates[i].low < currentPrice)
      {
         if(rates[i].low > closestSSL)
            closestSSL = rates[i].low;
      }
   }

   // Use found levels if valid, otherwise keep PWH/PWL
   if(closestBSL < DBL_MAX)
      g_htfNarrative.nearestBSL = closestBSL;
   if(closestSSL > 0)
      g_htfNarrative.nearestSSL = closestSSL;
}

//+------------------------------------------------------------------+
//| Get monthly high/low levels                                      |
//+------------------------------------------------------------------+
void GetMonthlyLevels()
{
   MqlRates rates[];
   ArraySetAsSeries(rates, true);

   // Get previous month's data
   if(CopyRates(_Symbol, PERIOD_MN1, 1, 1, rates) > 0)
   {
      g_htfNarrative.monthlyHigh = rates[0].high;
      g_htfNarrative.monthlyLow = rates[0].low;
   }
}

//+------------------------------------------------------------------+
//| Draw all chart visual elements                                   |
//+------------------------------------------------------------------+
void DrawChartElements()
{
   // Draw week/month start lines first (background)
   if(ShowWeekStartLine)
      DrawWeekStartLines();

   if(ShowMonthStartLine)
      DrawMonthStartLines();

   if(ShowSessionDividers)
      DrawSessionDividers();

   // Draw Silver Bullet time windows
   if(SilverBullet_Enabled && SB_ShowTimeWindows)
      DrawSilverBulletWindows();

   if(ShowDailyOpens)
      DrawDailyOpens();

   if(ShowPOILines)
      DrawPOILines();

   if(ShowPremiumDiscount)
      DrawPremiumDiscountZones();

   // Draw weekly high/low/equilibrium
   DrawWeeklyLevels();
}

//+------------------------------------------------------------------+
//| Draw week start vertical lines with labels                       |
//+------------------------------------------------------------------+
void DrawWeekStartLines()
{
   int weeksToShow = MathMin(MathMax(PreviousWeeksCount, 1), 3) + 1;  // +1 for current week
   string monthNames[] = {"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"};

   // Current week
   if(g_weeklyData.weekStart > 0)
   {
      string objName = EA_PREFIX + "WeekStart_0";
      DrawVerticalLine(objName, g_weeklyData.weekStart, WeekStartColor, STYLE_DASH, 1);

      // Label with date
      MqlDateTime dt;
      TimeToStruct(g_weeklyData.weekStart, dt);
      string labelText = "Week " + monthNames[dt.mon] + " " + IntegerToString(dt.day);

      string labelName = EA_PREFIX + "WeekStartLabel_0";
      if(ObjectFind(0, labelName) < 0)
         ObjectCreate(0, labelName, OBJ_TEXT, 0, g_weeklyData.weekStart, 0);

      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, WeekStartColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);  // Draw as background
      // Position at top of chart
      double chartHigh = ChartGetDouble(0, CHART_PRICE_MAX);
      ObjectSetDouble(0, labelName, OBJPROP_PRICE, chartHigh);
      ObjectSetInteger(0, labelName, OBJPROP_TIME, g_weeklyData.weekStart);
   }

   // Previous weeks
   for(int week = 0; week < weeksToShow - 1 && week < 3; week++)
   {
      if(!g_historicalWeeks[week].isValid) continue;

      // Use Monday's open time for the week start line (more accurate than weekly candle)
      datetime weekLineTime = g_historicalWeeks[week].weekStart;

      // If Monday data exists, use that time instead
      if(g_historicalWeeks[week].days[0].openTime > 0)
         weekLineTime = g_historicalWeeks[week].days[0].openTime;

      string objName = EA_PREFIX + "WeekStart_" + IntegerToString(week + 1);
      DrawVerticalLine(objName, weekLineTime, WeekStartColor, STYLE_DASH, 1);

      // Label with date
      MqlDateTime dt;
      TimeToStruct(weekLineTime, dt);
      string labelText = "-" + IntegerToString(week + 1) + "W " + monthNames[dt.mon] + " " + IntegerToString(dt.day);

      string labelName = EA_PREFIX + "WeekStartLabel_" + IntegerToString(week + 1);
      if(ObjectFind(0, labelName) < 0)
         ObjectCreate(0, labelName, OBJ_TEXT, 0, weekLineTime, 0);

      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, WeekStartColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);  // Draw as background
      double chartHigh = ChartGetDouble(0, CHART_PRICE_MAX);
      ObjectSetDouble(0, labelName, OBJPROP_PRICE, chartHigh);
      ObjectSetInteger(0, labelName, OBJPROP_TIME, weekLineTime);
   }
}

//+------------------------------------------------------------------+
//| Draw month start vertical lines with labels                      |
//+------------------------------------------------------------------+
void DrawMonthStartLines()
{
   string monthNames[] = {"", "January", "February", "March", "April", "May", "June",
                          "July", "August", "September", "October", "November", "December"};

   // Find month boundaries within the visible range (current + previous weeks)
   datetime earliestTime = 0;
   int weeksToShow = MathMin(MathMax(PreviousWeeksCount, 1), 3);

   // Find earliest week start
   for(int week = weeksToShow - 1; week >= 0; week--)
   {
      if(g_historicalWeeks[week].isValid && g_historicalWeeks[week].weekStart > 0)
      {
         earliestTime = g_historicalWeeks[week].weekStart;
         break;
      }
   }
   if(earliestTime == 0) earliestTime = g_weeklyData.weekStart;

   datetime latestTime = TimeCurrent();

   // Get the months in the range
   MqlDateTime dtStart, dtEnd;
   TimeToStruct(earliestTime, dtStart);
   TimeToStruct(latestTime, dtEnd);

   // Draw month start for each month in range
   int monthsDrawn = 0;
   for(int year = dtStart.year; year <= dtEnd.year && monthsDrawn < 4; year++)
   {
      int startMonth = (year == dtStart.year) ? dtStart.mon : 1;
      int endMonth = (year == dtEnd.year) ? dtEnd.mon : 12;

      for(int month = startMonth; month <= endMonth && monthsDrawn < 4; month++)
      {
         // Create datetime for first day of month
         MqlDateTime monthStart;
         monthStart.year = year;
         monthStart.mon = month;
         monthStart.day = 1;
         monthStart.hour = 0;
         monthStart.min = 0;
         monthStart.sec = 0;

         datetime monthStartTime = StructToTime(monthStart);

         // Only draw if within our range
         if(monthStartTime >= earliestTime && monthStartTime <= latestTime)
         {
            string objName = EA_PREFIX + "MonthStart_" + IntegerToString(year) + "_" + IntegerToString(month);
            DrawVerticalLine(objName, monthStartTime, MonthStartColor, STYLE_SOLID, 2);

            // Label
            string labelText = monthNames[month] + " " + IntegerToString(year);
            string labelName = EA_PREFIX + "MonthStartLabel_" + IntegerToString(year) + "_" + IntegerToString(month);

            if(ObjectFind(0, labelName) < 0)
               ObjectCreate(0, labelName, OBJ_TEXT, 0, monthStartTime, 0);

            ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
            ObjectSetInteger(0, labelName, OBJPROP_COLOR, MonthStartColor);
            ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
            ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
            ObjectSetInteger(0, labelName, OBJPROP_BACK, true);  // Draw as background
            double chartHigh = ChartGetDouble(0, CHART_PRICE_MAX);
            ObjectSetDouble(0, labelName, OBJPROP_PRICE, chartHigh - (50 * g_point));
            ObjectSetInteger(0, labelName, OBJPROP_TIME, monthStartTime);

            monthsDrawn++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw MSS marker with label                                       |
//+------------------------------------------------------------------+
void DrawMSSMarker(double price, datetime time, bool isBullish)
{
   string objName = EA_PREFIX + "MSS_" + TimeToString(time, TIME_DATE|TIME_MINUTES);

   // Draw horizontal line at MSS level
   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_TREND, 0, time, price, time + 3600, price);

   ObjectSetInteger(0, objName, OBJPROP_COLOR, isBullish ? clrLime : clrRed);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_RAY_RIGHT, true);
   ObjectSetInteger(0, objName, OBJPROP_BACK, false);
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 5);

   // Draw label box above/below the line
   string labelName = EA_PREFIX + "MSS_Label_" + TimeToString(time, TIME_DATE|TIME_MINUTES);

   if(ObjectFind(0, labelName) < 0)
      ObjectCreate(0, labelName, OBJ_TEXT, 0, time, price);

   double labelOffset = isBullish ? (50 * _Point) : (-50 * _Point);
   ObjectSetDouble(0, labelName, OBJPROP_PRICE, price + labelOffset);
   ObjectSetString(0, labelName, OBJPROP_TEXT, " ▬▬▬▬ MSS ▬▬▬▬ ");
   ObjectSetString(0, labelName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, labelName, OBJPROP_COLOR, isBullish ? clrLime : clrRed);
   ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, isBullish ? ANCHOR_LOWER : ANCHOR_UPPER);
   ObjectSetInteger(0, labelName, OBJPROP_BACK, false);
   ObjectSetInteger(0, labelName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw Silver Bullet time window vertical lines                    |
//+------------------------------------------------------------------+
void DrawSilverBulletWindows()
{
   if(!SB_ShowTimeWindows || !SilverBullet_Enabled) return;

   ENUM_SB_WINDOW currentWindow = GetSilverBulletWindow();

   // If currently IN a window, don't draw upcoming windows
   if(currentWindow != SB_NONE)
      return;

   // Find next upcoming window
   int estHour = GetESTHour();
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   datetime nextWindowStart = 0;
   datetime nextWindowEnd = 0;
   string windowName = "";

   // Check windows in chronological order
   if(SB_UseLondon && estHour < 3)
   {
      // Next window is London (3-4 AM)
      nextWindowStart = GetNextSBWindowTime(3, 0);
      nextWindowEnd = GetNextSBWindowTime(4, 0);
      windowName = "London";
   }
   else if(SB_UseNYAM && estHour < 10)
   {
      // Next window is NY AM (10-11 AM)
      nextWindowStart = GetNextSBWindowTime(10, 0);
      nextWindowEnd = GetNextSBWindowTime(11, 0);
      windowName = "NY_AM";
   }
   else if(SB_UseNYPM && estHour < 14)
   {
      // Next window is NY PM (2-3 PM)
      nextWindowStart = GetNextSBWindowTime(14, 0);
      nextWindowEnd = GetNextSBWindowTime(15, 0);
      windowName = "NY_PM";
   }
   else
   {
      // After all windows today - show tomorrow's first window
      if(SB_UseLondon)
      {
         nextWindowStart = GetNextSBWindowTime(3, 0, true);  // Tomorrow
         nextWindowEnd = GetNextSBWindowTime(4, 0, true);
         windowName = "London_Next";
      }
      else if(SB_UseNYAM)
      {
         nextWindowStart = GetNextSBWindowTime(10, 0, true);
         nextWindowEnd = GetNextSBWindowTime(11, 0, true);
         windowName = "NY_AM_Next";
      }
      else if(SB_UseNYPM)
      {
         nextWindowStart = GetNextSBWindowTime(14, 0, true);
         nextWindowEnd = GetNextSBWindowTime(15, 0, true);
         windowName = "NY_PM_Next";
      }
   }

   if(nextWindowStart > 0)
   {
      // Draw start line
      string startObjName = EA_PREFIX + "SB_Window_Start_" + windowName;
      DrawSBWindowLine(startObjName, nextWindowStart, SB_WindowStartColor, " SB Start ", true);

      // Draw end line
      string endObjName = EA_PREFIX + "SB_Window_End_" + windowName;
      DrawSBWindowLine(endObjName, nextWindowEnd, SB_WindowEndColor, " SB End ", false);
   }
}

//+------------------------------------------------------------------+
//| Helper: Get next SB window time in broker time                   |
//+------------------------------------------------------------------+
datetime GetNextSBWindowTime(int estHour, int estMinute, bool tomorrow = false)
{
   MqlDateTime dt;
   TimeToStruct(TimeCurrent(), dt);

   if(tomorrow)
   {
      dt.day += 1;
      // Handle month rollover
      if(dt.day > 31)
      {
         dt.day = 1;
         dt.mon += 1;
         if(dt.mon > 12)
         {
            dt.mon = 1;
            dt.year += 1;
         }
      }
   }

   dt.hour = estHour;
   dt.min = estMinute;
   dt.sec = 0;

   // Convert EST to broker time
   datetime estTime = StructToTime(dt);
   datetime brokerTime = estTime + (BrokerGMTOffset * 3600) + (5 * 3600);  // EST is GMT-5

   return brokerTime;
}

//+------------------------------------------------------------------+
//| Helper: Draw single SB window vertical line                      |
//+------------------------------------------------------------------+
void DrawSBWindowLine(string objName, datetime time, color lineColor, string labelText, bool isStart)
{
   // Delete old window lines (cleanup)
   if(ObjectFind(0, objName) >= 0)
      ObjectDelete(0, objName);

   // Draw vertical line
   if(ObjectFind(0, objName) < 0)
      ObjectCreate(0, objName, OBJ_VLINE, 0, time, 0);

   ObjectSetInteger(0, objName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, objName, OBJPROP_STYLE, STYLE_DASHDOT);
   ObjectSetInteger(0, objName, OBJPROP_WIDTH, 2);
   ObjectSetInteger(0, objName, OBJPROP_BACK, true);  // Behind price
   ObjectSetInteger(0, objName, OBJPROP_SELECTABLE, false);
   ObjectSetInteger(0, objName, OBJPROP_ZORDER, 2);

   // Draw label at top of chart
   string labelObjName = objName + "_Label";

   if(ObjectFind(0, labelObjName) < 0)
      ObjectCreate(0, labelObjName, OBJ_TEXT, 0, time, 0);

   double chartHigh = ChartGetDouble(0, CHART_PRICE_MAX);
   double chartLow = ChartGetDouble(0, CHART_PRICE_MIN);
   double priceRange = chartHigh - chartLow;
   double labelPrice = chartHigh - (priceRange * 0.05);  // 5% from top

   ObjectSetDouble(0, labelObjName, OBJPROP_PRICE, labelPrice);
   ObjectSetString(0, labelObjName, OBJPROP_TEXT, labelText);
   ObjectSetString(0, labelObjName, OBJPROP_FONT, "Arial Bold");
   ObjectSetInteger(0, labelObjName, OBJPROP_FONTSIZE, 9);
   ObjectSetInteger(0, labelObjName, OBJPROP_COLOR, lineColor);
   ObjectSetInteger(0, labelObjName, OBJPROP_ANCHOR, ANCHOR_UPPER);
   ObjectSetInteger(0, labelObjName, OBJPROP_BACK, true);  // Draw as background
   ObjectSetInteger(0, labelObjName, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Draw session dividers (vertical lines)                           |
//+------------------------------------------------------------------+
void DrawSessionDividers()
{
   // In minimal mode, skip session dividers - cleaner look
   if(MinimalWeeklyProfile) return;

   // Draw dividers for each day of the current week
   for(int day = 0; day <= g_currentDayOfWeek && day < 5; day++)
   {
      if(g_weeklyData.days[day].openTime == 0) continue;

      string objName = EA_PREFIX + "SessionDiv_" + IntegerToString(day);
      datetime divTime = g_weeklyData.days[day].openTime;

      // Get day color
      color dayColor;
      switch(day)
      {
         case 0: dayColor = MondayColor; break;
         case 1: dayColor = TuesdayColor; break;
         case 2: dayColor = WednesdayColor; break;
         case 3: dayColor = ThursdayColor; break;
         case 4: dayColor = FridayColor; break;
         default: dayColor = clrGray;
      }

      DrawVerticalLine(objName, divTime, dayColor, STYLE_DOT, 1);

      // Add day label
      string labelName = EA_PREFIX + "DayLabel_" + IntegerToString(day);
      string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};

      if(ObjectFind(0, labelName) < 0)
         ObjectCreate(0, labelName, OBJ_TEXT, 0, divTime, g_weeklyData.weekHigh + (50 * g_point));

      ObjectSetString(0, labelName, OBJPROP_TEXT, dayNames[day]);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, dayColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetString(0, labelName, OBJPROP_FONT, "Arial");
      ObjectSetDouble(0, labelName, OBJPROP_PRICE, g_weeklyData.weekHigh + (100 * g_point));
      ObjectSetInteger(0, labelName, OBJPROP_TIME, divTime);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);  // Draw as background
   }
}

//+------------------------------------------------------------------+
//| Draw daily open lines                                            |
//+------------------------------------------------------------------+
void DrawDailyOpens()
{
   // In minimal mode, skip daily opens - cleaner look like AlgoCados
   if(MinimalWeeklyProfile) return;

   datetime extendTime = ExtendDailyOpens ? TimeCurrent() : 0;

   for(int day = 0; day <= g_currentDayOfWeek && day < 5; day++)
   {
      if(g_weeklyData.days[day].openPrice == 0) continue;

      string objName = EA_PREFIX + "DailyOpen_" + IntegerToString(day);
      double openPrice = g_weeklyData.days[day].openPrice;
      datetime startTime = g_weeklyData.days[day].openTime;
      datetime endTime = extendTime;

      // If not extending, end at next day's open
      if(!ExtendDailyOpens && day < g_currentDayOfWeek)
         endTime = g_weeklyData.days[day + 1].openTime;
      else if(!ExtendDailyOpens)
         endTime = TimeCurrent();

      // Get day color
      color dayColor;
      switch(day)
      {
         case 0: dayColor = MondayColor; break;
         case 1: dayColor = TuesdayColor; break;
         case 2: dayColor = WednesdayColor; break;
         case 3: dayColor = ThursdayColor; break;
         case 4: dayColor = FridayColor; break;
         default: dayColor = clrGray;
      }

      DrawTrendLine(objName, startTime, openPrice, endTime, openPrice, dayColor, STYLE_DASH, 1);

      // Add price label
      string labelName = EA_PREFIX + "OpenLabel_" + IntegerToString(day);
      string dayNames[] = {"Mon Open", "Tue Open", "Wed Open", "Thu Open", "Fri Open"};

      if(ObjectFind(0, labelName) < 0)
         ObjectCreate(0, labelName, OBJ_TEXT, 0, startTime, openPrice);

      ObjectSetString(0, labelName, OBJPROP_TEXT, dayNames[day] + " " + DoubleToString(openPrice, g_digits));
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, dayColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 7);
      ObjectSetDouble(0, labelName, OBJPROP_PRICE, openPrice);
      ObjectSetInteger(0, labelName, OBJPROP_TIME, startTime);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);  // Draw as background
   }
}

//+------------------------------------------------------------------+
//| Draw POI lines (daily highs and lows)                            |
//+------------------------------------------------------------------+
void DrawPOILines()
{
   if(MinimalWeeklyProfile)
      DrawPOILinesMinimal();
   else
      DrawPOILinesStandard();
}

//+------------------------------------------------------------------+
//| Draw POI lines - Minimal style (like AlgoCados)                  |
//+------------------------------------------------------------------+
void DrawPOILinesMinimal()
{
   datetime extendTime = TimeCurrent();
   string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};

   // Draw previous days' POI lines (including current day)
   for(int day = 0; day <= g_currentDayOfWeek && day < 5; day++)
   {
      if(g_weeklyData.days[day].high == 0) continue;

      double highPrice = g_weeklyData.days[day].high;
      double lowPrice = g_weeklyData.days[day].low;
      datetime dayStart = g_weeklyData.days[day].openTime;
      bool highBroken = g_weeklyData.days[day].highBroken;
      bool lowBroken = g_weeklyData.days[day].lowBroken;

      // HIGH LINE - Blue for untouched, gray for raided
      string highName = EA_PREFIX + "POI_High_" + IntegerToString(day);
      color highColor = highBroken ? clrGray : clrDodgerBlue;

      DrawTrendLine(highName, dayStart, highPrice, extendTime, highPrice, highColor, STYLE_SOLID, 1);

      // HIGH LABEL - "Mon H • Raided Tue" or "Mon H • Protected"
      string highLabelName = EA_PREFIX + "POI_HighLabel_" + IntegerToString(day);
      string highLabel = dayNames[day] + " H";

      if(highBroken)
      {
         string breakDay = GetDayNameFromDatetime(g_weeklyData.days[day].highBreakTime);
         highLabel += " • Raided " + breakDay;
      }
      else
      {
         highLabel += " • Protected";
      }

      if(ObjectFind(0, highLabelName) < 0)
         ObjectCreate(0, highLabelName, OBJ_TEXT, 0, dayStart, highPrice);

      ObjectSetString(0, highLabelName, OBJPROP_TEXT, highLabel);
      ObjectSetInteger(0, highLabelName, OBJPROP_COLOR, highColor);
      ObjectSetInteger(0, highLabelName, OBJPROP_FONTSIZE, 8);
      ObjectSetDouble(0, highLabelName, OBJPROP_PRICE, highPrice);
      ObjectSetInteger(0, highLabelName, OBJPROP_TIME, dayStart);
      ObjectSetInteger(0, highLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, highLabelName, OBJPROP_BACK, true);  // Draw as background

      // LOW LINE - Red for untouched, gray for raided
      string lowName = EA_PREFIX + "POI_Low_" + IntegerToString(day);
      color lowColor = lowBroken ? clrGray : clrRed;

      DrawTrendLine(lowName, dayStart, lowPrice, extendTime, lowPrice, lowColor, STYLE_SOLID, 1);

      // LOW LABEL - "Mon L • Raided Tue" or "Mon L • Protected"
      string lowLabelName = EA_PREFIX + "POI_LowLabel_" + IntegerToString(day);
      string lowLabel = dayNames[day] + " L";

      if(lowBroken)
      {
         string breakDay = GetDayNameFromDatetime(g_weeklyData.days[day].lowBreakTime);
         lowLabel += " • Raided " + breakDay;
      }
      else
      {
         lowLabel += " • Protected";
      }

      if(ObjectFind(0, lowLabelName) < 0)
         ObjectCreate(0, lowLabelName, OBJ_TEXT, 0, dayStart, lowPrice);

      ObjectSetString(0, lowLabelName, OBJPROP_TEXT, lowLabel);
      ObjectSetInteger(0, lowLabelName, OBJPROP_COLOR, lowColor);
      ObjectSetInteger(0, lowLabelName, OBJPROP_FONTSIZE, 8);
      ObjectSetDouble(0, lowLabelName, OBJPROP_PRICE, lowPrice);
      ObjectSetInteger(0, lowLabelName, OBJPROP_TIME, dayStart);
      ObjectSetInteger(0, lowLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, lowLabelName, OBJPROP_BACK, true);  // Draw as background
   }

   // Draw CURRENT day's forming range (dashed lines to show it's developing)
   if(g_currentDayOfWeek >= 0 && g_currentDayOfWeek < 5)
   {
      int today = g_currentDayOfWeek;
      if(g_weeklyData.days[today].high > 0 && g_weeklyData.days[today].low > 0 && g_weeklyData.days[today].low < DBL_MAX)
      {
         double todayHigh = g_weeklyData.days[today].high;
         double todayLow = g_weeklyData.days[today].low;
         datetime todayStart = g_weeklyData.days[today].openTime;
         if(todayStart == 0) todayStart = TimeCurrent() - 3600;  // Fallback: 1 hour ago

         // TODAY HIGH LINE - Cyan dashed (forming)
         string todayHighName = EA_PREFIX + "POI_TodayHigh";
         DrawTrendLine(todayHighName, todayStart, todayHigh, extendTime, todayHigh, clrCyan, STYLE_DASH, 1);

         // TODAY HIGH LABEL
         string todayHighLabel = dayNames[today] + " H • Forming";
         string todayHighLabelName = EA_PREFIX + "POI_TodayHighLabel";
         if(ObjectFind(0, todayHighLabelName) < 0)
            ObjectCreate(0, todayHighLabelName, OBJ_TEXT, 0, todayStart, todayHigh);

         ObjectSetString(0, todayHighLabelName, OBJPROP_TEXT, todayHighLabel);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_FONTSIZE, 8);
         ObjectSetDouble(0, todayHighLabelName, OBJPROP_PRICE, todayHigh);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_TIME, todayStart);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);

         // TODAY LOW LINE - Orange dashed (forming)
         string todayLowName = EA_PREFIX + "POI_TodayLow";
         DrawTrendLine(todayLowName, todayStart, todayLow, extendTime, todayLow, clrOrange, STYLE_DASH, 1);

         // TODAY LOW LABEL
         string todayLowLabel = dayNames[today] + " L • Forming";
         string todayLowLabelName = EA_PREFIX + "POI_TodayLowLabel";
         if(ObjectFind(0, todayLowLabelName) < 0)
            ObjectCreate(0, todayLowLabelName, OBJ_TEXT, 0, todayStart, todayLow);

         ObjectSetString(0, todayLowLabelName, OBJPROP_TEXT, todayLowLabel);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_FONTSIZE, 8);
         ObjectSetDouble(0, todayLowLabelName, OBJPROP_PRICE, todayLow);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_TIME, todayStart);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      }
   }

   // Draw previous weeks' POI lines if enabled
   if(ShowPreviousWeeks)
   {
      DrawPreviousWeeksPOILinesMinimal();
   }
}

//+------------------------------------------------------------------+
//| Draw previous weeks' POI lines - Minimal style                   |
//| Same style as current week: "Mon H • Protected" or "Mon H • Raided Tue" |
//+------------------------------------------------------------------+
void DrawPreviousWeeksPOILinesMinimal()
{
   string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};

   int weeksToShow = MathMin(MathMax(PreviousWeeksCount, 1), 3);

   // Draw each previous week
   for(int week = 0; week < weeksToShow; week++)
   {
      if(!g_historicalWeeks[week].isValid) continue;

      int weekNum = g_historicalWeeks[week].weeksAgo;
      string weekPrefix = "-" + IntegerToString(weekNum) + "W ";

      // Calculate week end time (use Friday's time or Monday + 5 days)
      datetime weekEndTime;
      if(g_historicalWeeks[week].days[4].openTime > 0)  // Friday exists
         weekEndTime = g_historicalWeeks[week].days[4].openTime + 86400;  // End of Friday
      else if(g_historicalWeeks[week].days[0].openTime > 0)  // Monday exists
         weekEndTime = g_historicalWeeks[week].days[0].openTime + (5 * 86400);
      else
         weekEndTime = g_historicalWeeks[week].weekStart + (6 * 86400);

      // Draw each day's high/low for this week
      for(int day = 0; day < 5; day++)
      {
         if(g_historicalWeeks[week].days[day].high == 0) continue;

         double highPrice = g_historicalWeeks[week].days[day].high;
         double lowPrice = g_historicalWeeks[week].days[day].low;
         datetime dayStart = g_historicalWeeks[week].days[day].openTime;
         bool highBroken = g_historicalWeeks[week].days[day].highBroken;
         bool lowBroken = g_historicalWeeks[week].days[day].lowBroken;

         // Line extends to the end of that week
         datetime lineEndTime = weekEndTime;

         // HIGH LINE - Blue for protected, gray for raided (same as current week)
         string highName = EA_PREFIX + "PrevW" + IntegerToString(weekNum) + "_POI_High_" + IntegerToString(day);
         color highColor = highBroken ? clrGray : clrDodgerBlue;
         DrawTrendLine(highName, dayStart, highPrice, lineEndTime, highPrice, highColor, STYLE_SOLID, 1);

         // HIGH LABEL - Same format as current week
         string highLabelName = EA_PREFIX + "PrevW" + IntegerToString(weekNum) + "_POI_HighLabel_" + IntegerToString(day);
         string highLabel = weekPrefix + dayNames[day] + " H";

         if(highBroken && ShowPOIBreachTime)
         {
            string breakDay = GetDayNameFromDatetime(g_historicalWeeks[week].days[day].highBreakTime);
            highLabel += " • Raided " + breakDay;
         }
         else
         {
            highLabel += " • Protected";
         }

         if(ObjectFind(0, highLabelName) < 0)
            ObjectCreate(0, highLabelName, OBJ_TEXT, 0, dayStart, highPrice);

         ObjectSetString(0, highLabelName, OBJPROP_TEXT, highLabel);
         ObjectSetInteger(0, highLabelName, OBJPROP_COLOR, highColor);
         ObjectSetInteger(0, highLabelName, OBJPROP_FONTSIZE, 8);
         ObjectSetDouble(0, highLabelName, OBJPROP_PRICE, highPrice);
         ObjectSetInteger(0, highLabelName, OBJPROP_TIME, dayStart);
         ObjectSetInteger(0, highLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
         ObjectSetInteger(0, highLabelName, OBJPROP_BACK, true);  // Draw as background

         // LOW LINE - Red for protected, gray for raided (same as current week)
         string lowName = EA_PREFIX + "PrevW" + IntegerToString(weekNum) + "_POI_Low_" + IntegerToString(day);
         color lowColor = lowBroken ? clrGray : clrRed;
         DrawTrendLine(lowName, dayStart, lowPrice, lineEndTime, lowPrice, lowColor, STYLE_SOLID, 1);

         // LOW LABEL - Same format as current week
         string lowLabelName = EA_PREFIX + "PrevW" + IntegerToString(weekNum) + "_POI_LowLabel_" + IntegerToString(day);
         string lowLabel = weekPrefix + dayNames[day] + " L";

         if(lowBroken && ShowPOIBreachTime)
         {
            string breakDay = GetDayNameFromDatetime(g_historicalWeeks[week].days[day].lowBreakTime);
            lowLabel += " • Raided " + breakDay;
         }
         else
         {
            lowLabel += " • Protected";
         }

         if(ObjectFind(0, lowLabelName) < 0)
            ObjectCreate(0, lowLabelName, OBJ_TEXT, 0, dayStart, lowPrice);

         ObjectSetString(0, lowLabelName, OBJPROP_TEXT, lowLabel);
         ObjectSetInteger(0, lowLabelName, OBJPROP_COLOR, lowColor);
         ObjectSetInteger(0, lowLabelName, OBJPROP_FONTSIZE, 8);
         ObjectSetDouble(0, lowLabelName, OBJPROP_PRICE, lowPrice);
         ObjectSetInteger(0, lowLabelName, OBJPROP_TIME, dayStart);
         ObjectSetInteger(0, lowLabelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
         ObjectSetInteger(0, lowLabelName, OBJPROP_BACK, true);  // Draw as background
      }
   }
}

//+------------------------------------------------------------------+
//| Get day name from datetime                                       |
//+------------------------------------------------------------------+
string GetDayNameFromDatetime(datetime time)
{
   MqlDateTime dt;
   TimeToStruct(time, dt);
   string days[] = {"Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"};
   return days[dt.day_of_week];
}

//+------------------------------------------------------------------+
//| Draw POI lines - Standard style (filled zones)                   |
//+------------------------------------------------------------------+
void DrawPOILinesStandard()
{
   datetime extendTime = TimeCurrent();

   for(int day = 0; day <= g_currentDayOfWeek && day < 5; day++)
   {
      // Skip if no data
      if(g_weeklyData.days[day].high == 0) continue;

      // Draw high (Buyside liquidity)
      string highName = EA_PREFIX + "POI_High_" + IntegerToString(day);
      double highPrice = g_weeklyData.days[day].high;
      datetime highTime = g_weeklyData.days[day].highTime;

      color highColor = g_weeklyData.days[day].highBroken ? clrDarkGray : BullishColor;
      ENUM_LINE_STYLE highStyle = g_weeklyData.days[day].highBroken ? STYLE_DOT : STYLE_SOLID;

      DrawTrendLine(highName, highTime, highPrice, extendTime, highPrice, highColor, highStyle, 1);

      // High label with breach info
      string highLabelName = EA_PREFIX + "POI_HighLabel_" + IntegerToString(day);
      string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};
      string highLabel = dayNames[day] + " High";

      if(g_weeklyData.days[day].highBroken && ShowPOIBreachTime)
      {
         MqlDateTime dt;
         TimeToStruct(g_weeklyData.days[day].highBreakTime, dt);
         highLabel += " [X " + IntegerToString(dt.hour) + ":" + IntegerToString(dt.min, 2) + "]";
      }

      if(ObjectFind(0, highLabelName) < 0)
         ObjectCreate(0, highLabelName, OBJ_TEXT, 0, highTime, highPrice);

      ObjectSetString(0, highLabelName, OBJPROP_TEXT, highLabel);
      ObjectSetInteger(0, highLabelName, OBJPROP_COLOR, highColor);
      ObjectSetInteger(0, highLabelName, OBJPROP_FONTSIZE, 7);
      ObjectSetDouble(0, highLabelName, OBJPROP_PRICE, highPrice + (10 * g_point));
      ObjectSetInteger(0, highLabelName, OBJPROP_TIME, highTime);

      // Draw low (Sellside liquidity)
      string lowName = EA_PREFIX + "POI_Low_" + IntegerToString(day);
      double lowPrice = g_weeklyData.days[day].low;
      datetime lowTime = g_weeklyData.days[day].lowTime;

      color lowColor = g_weeklyData.days[day].lowBroken ? clrDarkGray : BearishColor;
      ENUM_LINE_STYLE lowStyle = g_weeklyData.days[day].lowBroken ? STYLE_DOT : STYLE_SOLID;

      DrawTrendLine(lowName, lowTime, lowPrice, extendTime, lowPrice, lowColor, lowStyle, 1);

      // Low label with breach info
      string lowLabelName = EA_PREFIX + "POI_LowLabel_" + IntegerToString(day);
      string lowLabel = dayNames[day] + " Low";

      if(g_weeklyData.days[day].lowBroken && ShowPOIBreachTime)
      {
         MqlDateTime dt;
         TimeToStruct(g_weeklyData.days[day].lowBreakTime, dt);
         lowLabel += " [X " + IntegerToString(dt.hour) + ":" + IntegerToString(dt.min, 2) + "]";
      }

      if(ObjectFind(0, lowLabelName) < 0)
         ObjectCreate(0, lowLabelName, OBJ_TEXT, 0, lowTime, lowPrice);

      ObjectSetString(0, lowLabelName, OBJPROP_TEXT, lowLabel);
      ObjectSetInteger(0, lowLabelName, OBJPROP_COLOR, lowColor);
      ObjectSetInteger(0, lowLabelName, OBJPROP_FONTSIZE, 7);
      ObjectSetDouble(0, lowLabelName, OBJPROP_PRICE, lowPrice - (10 * g_point));
      ObjectSetInteger(0, lowLabelName, OBJPROP_TIME, lowTime);
   }

   // Draw CURRENT day's forming range (dashed lines to show it's developing)
   if(g_currentDayOfWeek >= 0 && g_currentDayOfWeek < 5)
   {
      int today = g_currentDayOfWeek;
      if(g_weeklyData.days[today].high > 0 && g_weeklyData.days[today].low > 0 && g_weeklyData.days[today].low < DBL_MAX)
      {
         string dayNames[] = {"Mon", "Tue", "Wed", "Thu", "Fri"};
         double todayHigh = g_weeklyData.days[today].high;
         double todayLow = g_weeklyData.days[today].low;
         datetime todayStart = g_weeklyData.days[today].openTime;
         if(todayStart == 0) todayStart = TimeCurrent() - 3600;

         // TODAY HIGH LINE - Cyan dashed (forming)
         string todayHighName = EA_PREFIX + "POI_TodayHigh";
         DrawTrendLine(todayHighName, todayStart, todayHigh, extendTime, todayHigh, clrCyan, STYLE_DASH, 1);

         // TODAY HIGH LABEL
         string todayHighLabel = dayNames[today] + " H (Forming)";
         string todayHighLabelName = EA_PREFIX + "POI_TodayHighLabel";
         if(ObjectFind(0, todayHighLabelName) < 0)
            ObjectCreate(0, todayHighLabelName, OBJ_TEXT, 0, todayStart, todayHigh);

         ObjectSetString(0, todayHighLabelName, OBJPROP_TEXT, todayHighLabel);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, todayHighLabelName, OBJPROP_PRICE, todayHigh + (10 * g_point));
         ObjectSetInteger(0, todayHighLabelName, OBJPROP_TIME, todayStart);

         // TODAY LOW LINE - Orange dashed (forming)
         string todayLowName = EA_PREFIX + "POI_TodayLow";
         DrawTrendLine(todayLowName, todayStart, todayLow, extendTime, todayLow, clrOrange, STYLE_DASH, 1);

         // TODAY LOW LABEL
         string todayLowLabel = dayNames[today] + " L (Forming)";
         string todayLowLabelName = EA_PREFIX + "POI_TodayLowLabel";
         if(ObjectFind(0, todayLowLabelName) < 0)
            ObjectCreate(0, todayLowLabelName, OBJ_TEXT, 0, todayStart, todayLow);

         ObjectSetString(0, todayLowLabelName, OBJPROP_TEXT, todayLowLabel);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, todayLowLabelName, OBJPROP_PRICE, todayLow - (10 * g_point));
         ObjectSetInteger(0, todayLowLabelName, OBJPROP_TIME, todayStart);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw Premium/Discount zones                                      |
//+------------------------------------------------------------------+
void DrawPremiumDiscountZones()
{
   if(g_weeklyData.weekHigh == 0 || g_weeklyData.weekLow == DBL_MAX) return;

   // In minimal mode, skip the filled zones entirely
   if(MinimalWeeklyProfile) return;

   double equilibrium = g_weeklyData.equilibrium;
   double weekHigh = g_weeklyData.weekHigh;
   double weekLow = g_weeklyData.weekLow;
   datetime startTime = g_weeklyData.weekStart;
   datetime endTime = TimeCurrent() + (2 * 86400);  // Extend 2 days ahead

   // Premium Zone (above equilibrium)
   string premiumName = EA_PREFIX + "PremiumZone";
   if(ObjectFind(0, premiumName) < 0)
      ObjectCreate(0, premiumName, OBJ_RECTANGLE, 0, startTime, equilibrium, endTime, weekHigh);

   ObjectSetInteger(0, premiumName, OBJPROP_TIME, 0, startTime);
   ObjectSetDouble(0, premiumName, OBJPROP_PRICE, 0, equilibrium);
   ObjectSetInteger(0, premiumName, OBJPROP_TIME, 1, endTime);
   ObjectSetDouble(0, premiumName, OBJPROP_PRICE, 1, weekHigh);
   ObjectSetInteger(0, premiumName, OBJPROP_COLOR, PremiumZoneColor);
   ObjectSetInteger(0, premiumName, OBJPROP_FILL, true);
   ObjectSetInteger(0, premiumName, OBJPROP_BACK, true);
   ObjectSetInteger(0, premiumName, OBJPROP_WIDTH, 1);

   // Discount Zone (below equilibrium)
   string discountName = EA_PREFIX + "DiscountZone";
   if(ObjectFind(0, discountName) < 0)
      ObjectCreate(0, discountName, OBJ_RECTANGLE, 0, startTime, weekLow, endTime, equilibrium);

   ObjectSetInteger(0, discountName, OBJPROP_TIME, 0, startTime);
   ObjectSetDouble(0, discountName, OBJPROP_PRICE, 0, weekLow);
   ObjectSetInteger(0, discountName, OBJPROP_TIME, 1, endTime);
   ObjectSetDouble(0, discountName, OBJPROP_PRICE, 1, equilibrium);
   ObjectSetInteger(0, discountName, OBJPROP_COLOR, DiscountZoneColor);
   ObjectSetInteger(0, discountName, OBJPROP_FILL, true);
   ObjectSetInteger(0, discountName, OBJPROP_BACK, true);
   ObjectSetInteger(0, discountName, OBJPROP_WIDTH, 1);

   // Premium label
   string premiumLabel = EA_PREFIX + "PremiumLabel";
   if(ObjectFind(0, premiumLabel) < 0)
      ObjectCreate(0, premiumLabel, OBJ_TEXT, 0, endTime, (equilibrium + weekHigh) / 2);

   ObjectSetString(0, premiumLabel, OBJPROP_TEXT, "PREMIUM");
   ObjectSetInteger(0, premiumLabel, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, premiumLabel, OBJPROP_FONTSIZE, 8);
   ObjectSetDouble(0, premiumLabel, OBJPROP_PRICE, (equilibrium + weekHigh) / 2);
   ObjectSetInteger(0, premiumLabel, OBJPROP_TIME, endTime - 86400);

   // Discount label
   string discountLabel = EA_PREFIX + "DiscountLabel";
   if(ObjectFind(0, discountLabel) < 0)
      ObjectCreate(0, discountLabel, OBJ_TEXT, 0, endTime, (equilibrium + weekLow) / 2);

   ObjectSetString(0, discountLabel, OBJPROP_TEXT, "DISCOUNT");
   ObjectSetInteger(0, discountLabel, OBJPROP_COLOR, clrWhite);
   ObjectSetInteger(0, discountLabel, OBJPROP_FONTSIZE, 8);
   ObjectSetDouble(0, discountLabel, OBJPROP_PRICE, (equilibrium + weekLow) / 2);
   ObjectSetInteger(0, discountLabel, OBJPROP_TIME, endTime - 86400);
}

//+------------------------------------------------------------------+
//| Draw weekly levels (high, low, equilibrium)                      |
//+------------------------------------------------------------------+
void DrawWeeklyLevels()
{
   if(g_weeklyData.weekHigh == 0 || g_weeklyData.weekLow == DBL_MAX) return;

   // In minimal mode, skip the week high/low lines - POI lines already show daily H/L
   if(MinimalWeeklyProfile)
   {
      DrawWeeklyLevelsMinimal();
      return;
   }

   datetime startTime = g_weeklyData.weekStart;
   datetime endTime = TimeCurrent() + (2 * 86400);

   // Week High
   string weekHighName = EA_PREFIX + "WeekHigh";
   DrawTrendLine(weekHighName, startTime, g_weeklyData.weekHigh, endTime, g_weeklyData.weekHigh,
                 BullishColor, STYLE_SOLID, 2);

   // Week High label
   string weekHighLabel = EA_PREFIX + "WeekHighLabel";
   if(ObjectFind(0, weekHighLabel) < 0)
      ObjectCreate(0, weekHighLabel, OBJ_TEXT, 0, endTime, g_weeklyData.weekHigh);

   ObjectSetString(0, weekHighLabel, OBJPROP_TEXT, "Week High " + DoubleToString(g_weeklyData.weekHigh, g_digits));
   ObjectSetInteger(0, weekHighLabel, OBJPROP_COLOR, BullishColor);
   ObjectSetInteger(0, weekHighLabel, OBJPROP_FONTSIZE, 8);
   ObjectSetDouble(0, weekHighLabel, OBJPROP_PRICE, g_weeklyData.weekHigh);
   ObjectSetInteger(0, weekHighLabel, OBJPROP_TIME, endTime);

   // Week Low
   string weekLowName = EA_PREFIX + "WeekLow";
   DrawTrendLine(weekLowName, startTime, g_weeklyData.weekLow, endTime, g_weeklyData.weekLow,
                 BearishColor, STYLE_SOLID, 2);

   // Week Low label
   string weekLowLabel = EA_PREFIX + "WeekLowLabel";
   if(ObjectFind(0, weekLowLabel) < 0)
      ObjectCreate(0, weekLowLabel, OBJ_TEXT, 0, endTime, g_weeklyData.weekLow);

   ObjectSetString(0, weekLowLabel, OBJPROP_TEXT, "Week Low " + DoubleToString(g_weeklyData.weekLow, g_digits));
   ObjectSetInteger(0, weekLowLabel, OBJPROP_COLOR, BearishColor);
   ObjectSetInteger(0, weekLowLabel, OBJPROP_FONTSIZE, 8);
   ObjectSetDouble(0, weekLowLabel, OBJPROP_PRICE, g_weeklyData.weekLow);
   ObjectSetInteger(0, weekLowLabel, OBJPROP_TIME, endTime);

   // Equilibrium
   string eqName = EA_PREFIX + "Equilibrium";
   DrawTrendLine(eqName, startTime, g_weeklyData.equilibrium, endTime, g_weeklyData.equilibrium,
                 EquilibriumColor, STYLE_DASHDOT, 1);

   // Equilibrium label
   string eqLabel = EA_PREFIX + "EquilibriumLabel";
   if(ObjectFind(0, eqLabel) < 0)
      ObjectCreate(0, eqLabel, OBJ_TEXT, 0, endTime, g_weeklyData.equilibrium);

   ObjectSetString(0, eqLabel, OBJPROP_TEXT, "EQ " + DoubleToString(g_weeklyData.equilibrium, g_digits));
   ObjectSetInteger(0, eqLabel, OBJPROP_COLOR, EquilibriumColor);
   ObjectSetInteger(0, eqLabel, OBJPROP_FONTSIZE, 8);
   ObjectSetDouble(0, eqLabel, OBJPROP_PRICE, g_weeklyData.equilibrium);
   ObjectSetInteger(0, eqLabel, OBJPROP_TIME, endTime);

   // Previous Week High (PWH)
   if(g_weeklyData.pwh > 0)
   {
      string pwhName = EA_PREFIX + "PWH";
      DrawTrendLine(pwhName, startTime, g_weeklyData.pwh, endTime, g_weeklyData.pwh,
                    clrDodgerBlue, STYLE_DOT, 1);

      string pwhLabel = EA_PREFIX + "PWHLabel";
      if(ObjectFind(0, pwhLabel) < 0)
         ObjectCreate(0, pwhLabel, OBJ_TEXT, 0, startTime, g_weeklyData.pwh);

      ObjectSetString(0, pwhLabel, OBJPROP_TEXT, "PWH " + DoubleToString(g_weeklyData.pwh, g_digits));
      ObjectSetInteger(0, pwhLabel, OBJPROP_COLOR, clrDodgerBlue);
      ObjectSetInteger(0, pwhLabel, OBJPROP_FONTSIZE, 7);
      ObjectSetDouble(0, pwhLabel, OBJPROP_PRICE, g_weeklyData.pwh);
      ObjectSetInteger(0, pwhLabel, OBJPROP_TIME, startTime);
   }

   // Previous Week Low (PWL)
   if(g_weeklyData.pwl > 0 && g_weeklyData.pwl < DBL_MAX)
   {
      string pwlName = EA_PREFIX + "PWL";
      DrawTrendLine(pwlName, startTime, g_weeklyData.pwl, endTime, g_weeklyData.pwl,
                    clrOrangeRed, STYLE_DOT, 1);

      string pwlLabel = EA_PREFIX + "PWLLabel";
      if(ObjectFind(0, pwlLabel) < 0)
         ObjectCreate(0, pwlLabel, OBJ_TEXT, 0, startTime, g_weeklyData.pwl);

      ObjectSetString(0, pwlLabel, OBJPROP_TEXT, "PWL " + DoubleToString(g_weeklyData.pwl, g_digits));
      ObjectSetInteger(0, pwlLabel, OBJPROP_COLOR, clrOrangeRed);
      ObjectSetInteger(0, pwlLabel, OBJPROP_FONTSIZE, 7);
      ObjectSetDouble(0, pwlLabel, OBJPROP_PRICE, g_weeklyData.pwl);
      ObjectSetInteger(0, pwlLabel, OBJPROP_TIME, startTime);
   }
   // Note: Previous weeks' daily POI lines are drawn by DrawPreviousWeeksPOILinesMinimal()
}

//+------------------------------------------------------------------+
//| Draw historical weeks levels (2-3 weeks ago) - DEPRECATED        |
//| Kept for reference, functionality moved to POI lines             |
//+------------------------------------------------------------------+
void DrawHistoricalWeeksLevels()
{
   datetime startTime = g_weeklyData.weekStart;
   datetime endTime = TimeCurrent() + (2 * 86400);

   // Color array for different weeks (progressively faded)
   color weekHighColors[] = {clrCornflowerBlue, clrSteelBlue, clrSlateGray};
   color weekLowColors[] = {clrCoral, clrIndianRed, clrRosyBrown};

   int weeksToShow = MathMin(MathMax(PreviousWeeksCount, 1), 3);

   // Start from index 1 (skip week 1 which is already shown as PWH/PWL)
   for(int i = 1; i < weeksToShow; i++)
   {
      if(!g_historicalWeeks[i].isValid) continue;

      int weekNum = g_historicalWeeks[i].weeksAgo;
      string weekSuffix = "W" + IntegerToString(weekNum);

      // Week High - draw from current week start so it's visible
      if(g_historicalWeeks[i].high > 0)
      {
         string highName = EA_PREFIX + "HistWH_" + weekSuffix;
         DrawTrendLine(highName, startTime, g_historicalWeeks[i].high, endTime, g_historicalWeeks[i].high,
                       weekHighColors[i], STYLE_DOT, 1);

         string highLabel = EA_PREFIX + "HistWHLabel_" + weekSuffix;
         if(ObjectFind(0, highLabel) < 0)
            ObjectCreate(0, highLabel, OBJ_TEXT, 0, startTime, g_historicalWeeks[i].high);

         ObjectSetString(0, highLabel, OBJPROP_TEXT, "-" + IntegerToString(weekNum) + "WH " + DoubleToString(g_historicalWeeks[i].high, g_digits));
         ObjectSetInteger(0, highLabel, OBJPROP_COLOR, weekHighColors[i]);
         ObjectSetInteger(0, highLabel, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, highLabel, OBJPROP_PRICE, g_historicalWeeks[i].high);
         ObjectSetInteger(0, highLabel, OBJPROP_TIME, startTime);
      }

      // Week Low - draw from current week start so it's visible
      if(g_historicalWeeks[i].low > 0 && g_historicalWeeks[i].low < DBL_MAX)
      {
         string lowName = EA_PREFIX + "HistWL_" + weekSuffix;
         DrawTrendLine(lowName, startTime, g_historicalWeeks[i].low, endTime, g_historicalWeeks[i].low,
                       weekLowColors[i], STYLE_DOT, 1);

         string lowLabel = EA_PREFIX + "HistWLLabel_" + weekSuffix;
         if(ObjectFind(0, lowLabel) < 0)
            ObjectCreate(0, lowLabel, OBJ_TEXT, 0, startTime, g_historicalWeeks[i].low);

         ObjectSetString(0, lowLabel, OBJPROP_TEXT, "-" + IntegerToString(weekNum) + "WL " + DoubleToString(g_historicalWeeks[i].low, g_digits));
         ObjectSetInteger(0, lowLabel, OBJPROP_COLOR, weekLowColors[i]);
         ObjectSetInteger(0, lowLabel, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, lowLabel, OBJPROP_PRICE, g_historicalWeeks[i].low);
         ObjectSetInteger(0, lowLabel, OBJPROP_TIME, startTime);
      }
   }
}

//+------------------------------------------------------------------+
//| Draw weekly levels - Minimal style (just PWH/PWL)                |
//+------------------------------------------------------------------+
void DrawWeeklyLevelsMinimal()
{
   datetime startTime = g_weeklyData.weekStart;
   datetime endTime = TimeCurrent() + (2 * 86400);

   // Previous Week High (PWH) - dashed purple line like AlgoCados
   if(g_weeklyData.pwh > 0)
   {
      string pwhName = EA_PREFIX + "PWH";
      DrawTrendLine(pwhName, startTime, g_weeklyData.pwh, endTime, g_weeklyData.pwh,
                    clrMediumPurple, STYLE_DASH, 1);

      string pwhLabel = EA_PREFIX + "PWHLabel";
      if(ObjectFind(0, pwhLabel) < 0)
         ObjectCreate(0, pwhLabel, OBJ_TEXT, 0, startTime, g_weeklyData.pwh);

      ObjectSetString(0, pwhLabel, OBJPROP_TEXT, "PWH • Protected");
      ObjectSetInteger(0, pwhLabel, OBJPROP_COLOR, clrMediumPurple);
      ObjectSetInteger(0, pwhLabel, OBJPROP_FONTSIZE, 8);
      ObjectSetDouble(0, pwhLabel, OBJPROP_PRICE, g_weeklyData.pwh);
      ObjectSetInteger(0, pwhLabel, OBJPROP_TIME, startTime);
      ObjectSetInteger(0, pwhLabel, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
   }

   // Previous Week Low (PWL) - dashed purple line like AlgoCados
   if(g_weeklyData.pwl > 0 && g_weeklyData.pwl < DBL_MAX)
   {
      string pwlName = EA_PREFIX + "PWL";
      DrawTrendLine(pwlName, startTime, g_weeklyData.pwl, endTime, g_weeklyData.pwl,
                    clrMediumPurple, STYLE_DASH, 1);

      string pwlLabel = EA_PREFIX + "PWLLabel";
      if(ObjectFind(0, pwlLabel) < 0)
         ObjectCreate(0, pwlLabel, OBJ_TEXT, 0, startTime, g_weeklyData.pwl);

      ObjectSetString(0, pwlLabel, OBJPROP_TEXT, "PWL • Protected");
      ObjectSetInteger(0, pwlLabel, OBJPROP_COLOR, clrMediumPurple);
      ObjectSetInteger(0, pwlLabel, OBJPROP_FONTSIZE, 8);
      ObjectSetDouble(0, pwlLabel, OBJPROP_PRICE, g_weeklyData.pwl);
      ObjectSetInteger(0, pwlLabel, OBJPROP_TIME, startTime);
      ObjectSetInteger(0, pwlLabel, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
   }
   // Note: Previous weeks' daily POI lines are drawn by DrawPreviousWeeksPOILinesMinimal()
}

//+------------------------------------------------------------------+
//| Draw historical weeks levels - Minimal style                     |
//+------------------------------------------------------------------+
void DrawHistoricalWeeksLevelsMinimal()
{
   datetime startTime = g_weeklyData.weekStart;
   datetime endTime = TimeCurrent() + (2 * 86400);

   // Progressively faded purple colors for older weeks
   color weekColors[] = {clrMediumPurple, clrSlateBlue, clrDarkSlateBlue};

   int weeksToShow = MathMin(MathMax(PreviousWeeksCount, 1), 3);

   // Start from index 1 (skip week 1 which is already shown as PWH/PWL)
   for(int i = 1; i < weeksToShow; i++)
   {
      if(!g_historicalWeeks[i].isValid) continue;

      int weekNum = g_historicalWeeks[i].weeksAgo;
      string weekSuffix = "W" + IntegerToString(weekNum);

      // Week High - draw from current week start so it's visible
      if(g_historicalWeeks[i].high > 0)
      {
         string highName = EA_PREFIX + "HistWH_" + weekSuffix;
         DrawTrendLine(highName, startTime, g_historicalWeeks[i].high, endTime, g_historicalWeeks[i].high,
                       weekColors[i], STYLE_DOT, 1);

         string highLabel = EA_PREFIX + "HistWHLabel_" + weekSuffix;
         if(ObjectFind(0, highLabel) < 0)
            ObjectCreate(0, highLabel, OBJ_TEXT, 0, startTime, g_historicalWeeks[i].high);

         ObjectSetString(0, highLabel, OBJPROP_TEXT, "-" + IntegerToString(weekNum) + "WH");
         ObjectSetInteger(0, highLabel, OBJPROP_COLOR, weekColors[i]);
         ObjectSetInteger(0, highLabel, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, highLabel, OBJPROP_PRICE, g_historicalWeeks[i].high);
         ObjectSetInteger(0, highLabel, OBJPROP_TIME, startTime);
         ObjectSetInteger(0, highLabel, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      }

      // Week Low - draw from current week start so it's visible
      if(g_historicalWeeks[i].low > 0 && g_historicalWeeks[i].low < DBL_MAX)
      {
         string lowName = EA_PREFIX + "HistWL_" + weekSuffix;
         DrawTrendLine(lowName, startTime, g_historicalWeeks[i].low, endTime, g_historicalWeeks[i].low,
                       weekColors[i], STYLE_DOT, 1);

         string lowLabel = EA_PREFIX + "HistWLLabel_" + weekSuffix;
         if(ObjectFind(0, lowLabel) < 0)
            ObjectCreate(0, lowLabel, OBJ_TEXT, 0, startTime, g_historicalWeeks[i].low);

         ObjectSetString(0, lowLabel, OBJPROP_TEXT, "-" + IntegerToString(weekNum) + "WL");
         ObjectSetInteger(0, lowLabel, OBJPROP_COLOR, weekColors[i]);
         ObjectSetInteger(0, lowLabel, OBJPROP_FONTSIZE, 7);
         ObjectSetDouble(0, lowLabel, OBJPROP_PRICE, g_historicalWeeks[i].low);
         ObjectSetInteger(0, lowLabel, OBJPROP_TIME, startTime);
         ObjectSetInteger(0, lowLabel, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      }
   }
}

//+------------------------------------------------------------------+
//| Helper: Draw vertical line                                       |
//+------------------------------------------------------------------+
void DrawVerticalLine(string name, datetime time, color clr, ENUM_LINE_STYLE style, int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_VLINE, 0, time, 0);

   ObjectSetInteger(0, name, OBJPROP_TIME, time);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Helper: Draw trend line (horizontal line with time range)        |
//+------------------------------------------------------------------+
void DrawTrendLine(string name, datetime time1, double price1, datetime time2, double price2,
                   color clr, ENUM_LINE_STYLE style, int width)
{
   if(ObjectFind(0, name) < 0)
      ObjectCreate(0, name, OBJ_TREND, 0, time1, price1, time2, price2);

   ObjectSetInteger(0, name, OBJPROP_TIME, 0, time1);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price1);
   ObjectSetInteger(0, name, OBJPROP_TIME, 1, time2);
   ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price2);
   ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
   ObjectSetInteger(0, name, OBJPROP_STYLE, style);
   ObjectSetInteger(0, name, OBJPROP_WIDTH, width);
   ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, name, OBJPROP_BACK, true);   // Draw as background so dashboard stays on top
   ObjectSetInteger(0, name, OBJPROP_SELECTABLE, false);
}

//+------------------------------------------------------------------+
//| Delete all EA objects                                            |
//+------------------------------------------------------------------+
void DeleteAllObjects()
{
   for(int i = ArraySize(g_dashboardObjects) - 1; i >= 0; i--)
   {
      ObjectDelete(0, g_dashboardObjects[i]);
   }
   ArrayResize(g_dashboardObjects, 0);

   // Also delete by prefix
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, EA_PREFIX) == 0)
         ObjectDelete(0, name);
   }
}

//=============================================================================
// ALERT FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Send alert through configured channels                           |
//+------------------------------------------------------------------+
void SendAlert(string message)
{
   string fullMessage = "ICT Weekly Profile: " + message;

   if(EnableSoundAlert)
      Alert(fullMessage);

   if(EnablePushNotification)
      SendNotification(fullMessage);

   if(EnableEmailAlert)
      SendMail("ICT Weekly Profile Alert", fullMessage);

   Print(fullMessage);
}

//=============================================================================
// PDA MATRIX FUNCTIONS
//=============================================================================

//+------------------------------------------------------------------+
//| Get average candle range for last N bars                         |
//+------------------------------------------------------------------+
double PDA_GetAverageRange(const MqlRates &rates[], int startIndex, int count)
{
   double sum = 0;
   int validBars = 0;
   int size = ArraySize(rates);

   for(int i = startIndex; i < startIndex + count && i < size; i++)
   {
      sum += rates[i].high - rates[i].low;
      validBars++;
   }

   return (validBars > 0) ? sum / validBars : 0;
}

//+------------------------------------------------------------------+
//| Get average candle body for last N bars                          |
//+------------------------------------------------------------------+
double PDA_GetAverageBody(const MqlRates &rates[], int startIndex, int count)
{
   double sum = 0;
   int validBars = 0;
   int size = ArraySize(rates);

   for(int i = startIndex; i < startIndex + count && i < size; i++)
   {
      sum += MathAbs(rates[i].close - rates[i].open);
      validBars++;
   }

   return (validBars > 0) ? sum / validBars : 0;
}

//+------------------------------------------------------------------+
//| Get swing high within N bars from startIndex                     |
//+------------------------------------------------------------------+
double PDA_GetSwingHigh(const MqlRates &rates[], int startIndex, int lookback)
{
   double highest = 0;
   int size = ArraySize(rates);

   for(int i = startIndex; i < startIndex + lookback && i < size; i++)
   {
      if(rates[i].high > highest)
         highest = rates[i].high;
   }

   return highest;
}

//+------------------------------------------------------------------+
//| Get swing low within N bars from startIndex                      |
//+------------------------------------------------------------------+
double PDA_GetSwingLow(const MqlRates &rates[], int startIndex, int lookback)
{
   double lowest = DBL_MAX;
   int size = ArraySize(rates);

   for(int i = startIndex; i < startIndex + lookback && i < size; i++)
   {
      if(rates[i].low < lowest)
         lowest = rates[i].low;
   }

   return (lowest == DBL_MAX) ? 0 : lowest;
}

//+------------------------------------------------------------------+
//| Find bar index by datetime                                       |
//+------------------------------------------------------------------+
int PDA_FindBarIndex(const MqlRates &rates[], int count, datetime targetTime)
{
   for(int i = 0; i < count; i++)
   {
      if(rates[i].time == targetTime)
         return i;
   }
   return -1;
}

//+------------------------------------------------------------------+
//| Check if PDA is aligned with HTF bias                            |
//+------------------------------------------------------------------+
bool PDA_IsAlignedWithHTF(bool isBullish)
{
   // If bias is NEUTRAL, allow ALL PDAs (don't filter)
   if(g_weeklyBias == BIAS_NEUTRAL)
      return true;

   // Bullish bias = only bullish PDAs
   if(g_weeklyBias == BIAS_BULLISH && isBullish)
      return true;

   // Bearish bias = only bearish PDAs
   if(g_weeklyBias == BIAS_BEARISH && !isBullish)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Check if zone is in valid discount/premium area for current bias  |
//+------------------------------------------------------------------+
bool PDA_IsInValidZone(bool isBullish, double zoneLow, double zoneHigh)
{
   double equilibrium = g_weeklyData.equilibrium;
   if(equilibrium <= 0) return true;  // No valid EQ, show all

   // Use zone midpoint for comparison
   double zoneMid = (zoneLow + zoneHigh) / 2;

   // BULLISH bias: Only show bullish PDAs BELOW equilibrium (discount entry)
   if(g_weeklyBias == BIAS_BULLISH)
   {
      if(isBullish && zoneMid < equilibrium)
         return true;   // Bullish zone in discount - VALID
      return false;     // Either bearish zone, or bullish zone in premium - SKIP
   }

   // BEARISH bias: Only show bearish PDAs ABOVE equilibrium (premium entry)
   if(g_weeklyBias == BIAS_BEARISH)
   {
      if(!isBullish && zoneMid > equilibrium)
         return true;   // Bearish zone in premium - VALID
      return false;     // Either bullish zone, or bearish zone in discount - SKIP
   }

   // NEUTRAL bias: Show all zones
   return true;
}

//+------------------------------------------------------------------+
//| Check if price has mitigated a zone (type-specific logic)        |
//+------------------------------------------------------------------+
bool PDA_IsMitigated(double zoneHigh, double zoneLow, const MqlRates &rates[], int fromIndex, ENUM_PDA_TYPE type)
{
   for(int i = fromIndex - 1; i >= 0; i--)
   {
      if(type == PDA_REJECTION)
      {
         // Rejection: Only mitigated if candle BODY traverses the zone (not just wick)
         double bodyHigh = MathMax(rates[i].open, rates[i].close);
         double bodyLow = MathMin(rates[i].open, rates[i].close);
         // Body must cross through the zone
         if(bodyLow <= zoneLow && bodyHigh >= zoneHigh)
            return true;
      }
      else if(type == PDA_LIQUIDITY_VOID)
      {
         // Void: Mitigated if price completely fills it (full traverse)
         if(rates[i].low <= zoneLow && rates[i].high >= zoneHigh)
            return true;
      }
      else
      {
         // FVG, OB, Breaker, Mitigation, VI: Any touch = mitigated
         if(rates[i].low <= zoneHigh && rates[i].high >= zoneLow)
            return true;
      }
   }
   return false;
}

//+------------------------------------------------------------------+
//| Get PDA color based on type and bias                             |
//+------------------------------------------------------------------+
color GetPDAColor(ENUM_PDA_TYPE type, bool isBullish)
{
   if(isBullish)
   {
      switch(type)
      {
         case PDA_FVG:              return PDA_BullFVG_Color;
         case PDA_ORDER_BLOCK:      return PDA_BullOB_Color;
         case PDA_BREAKER:          return PDA_BullBreaker_Color;
         case PDA_MITIGATION:       return PDA_BullMitigation_Color;
         case PDA_REJECTION:        return PDA_BullRejection_Color;
         case PDA_LIQUIDITY_VOID:   return PDA_BullVoid_Color;
         case PDA_VOLUME_IMBALANCE: return PDA_BullVI_Color;
      }
   }
   else
   {
      switch(type)
      {
         case PDA_FVG:              return PDA_BearFVG_Color;
         case PDA_ORDER_BLOCK:      return PDA_BearOB_Color;
         case PDA_BREAKER:          return PDA_BearBreaker_Color;
         case PDA_MITIGATION:       return PDA_BearMitigation_Color;
         case PDA_REJECTION:        return PDA_BearRejection_Color;
         case PDA_LIQUIDITY_VOID:   return PDA_BearVoid_Color;
         case PDA_VOLUME_IMBALANCE: return PDA_BearVI_Color;
      }
   }
   return clrGray;
}

//+------------------------------------------------------------------+
//| Get PDA label text                                               |
//+------------------------------------------------------------------+
string GetPDALabel(ENUM_PDA_TYPE type, bool isBullish)
{
   string bias = isBullish ? "Bull " : "Bear ";
   switch(type)
   {
      case PDA_FVG:              return bias + "FVG";
      case PDA_ORDER_BLOCK:      return bias + "OB";
      case PDA_BREAKER:          return bias + "Breaker";
      case PDA_MITIGATION:       return bias + "Mitigation";
      case PDA_REJECTION:        return bias + "Rejection";
      case PDA_LIQUIDITY_VOID:   return bias + "Void";
      case PDA_VOLUME_IMBALANCE: return bias + "VI";
   }
   return "PDA";
}

//+------------------------------------------------------------------+
//| Get PDA type priority score (ICT hierarchy)                       |
//+------------------------------------------------------------------+
int GetPDATypePriority(ENUM_PDA_TYPE type)
{
   switch(type)
   {
      case PDA_ORDER_BLOCK:      return 10;  // Highest - Institutional footprint
      case PDA_BREAKER:          return 8;   // Failed structure = trapped traders
      case PDA_FVG:              return 7;   // Imbalance price wants to fill
      case PDA_LIQUIDITY_VOID:   return 6;   // Must be filled
      case PDA_MITIGATION:       return 4;   // Origin of move
      case PDA_REJECTION:        return 3;   // Wick area, needs confluence
      case PDA_VOLUME_IMBALANCE: return 2;   // Confluence only
      default:                   return 1;
   }
}

//+------------------------------------------------------------------+
//| Check if liquidity has been raided (PWH/PWL or Monday H/L)        |
//+------------------------------------------------------------------+
bool IsLiquidityRaided()
{
   // Check if OSOK detected a Monday liquidity sweep
   if(g_osokSetup.liquiditySwept)
      return true;

   // Check if PWH was raided (price went above it)
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   if(g_weeklyData.pwh > 0 && bid > g_weeklyData.pwh)
      return true;

   // Check if PWL was raided (price went below it)
   if(g_weeklyData.pwl > 0 && g_weeklyData.pwl < DBL_MAX && bid < g_weeklyData.pwl)
      return true;

   return false;
}

//+------------------------------------------------------------------+
//| Get pip distance from current price to zone midpoint              |
//+------------------------------------------------------------------+
double GetDistanceToZone(PDAZone &zone, bool &isAbove)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double zoneMid = (zone.priceLow + zone.priceHigh) / 2;
   double distance = MathAbs(bid - zoneMid);

   isAbove = (bid > zoneMid);

   // Convert to pips
   double pipSize = SymbolInfoDouble(_Symbol, SYMBOL_POINT);
   if(_Digits == 3 || _Digits == 5) pipSize *= 10;

   return (pipSize > 0) ? distance / pipSize : 0;
}

//+------------------------------------------------------------------+
//| Get actionable context based on current location + bias           |
//+------------------------------------------------------------------+
string GetLocationContext()
{
   string context = "";

   if(g_weeklyBias == BIAS_BULLISH)
   {
      if(g_htfNarrative.zone == "PREMIUM")
         context = "Wait for pullback OR counter-SHORT";
      else if(g_htfNarrative.zone == "DISCOUNT")
         context = "LONG opportunity - look for entry";
      else
         context = "Near EQ - prepare for LONG";
   }
   else if(g_weeklyBias == BIAS_BEARISH)
   {
      if(g_htfNarrative.zone == "PREMIUM")
         context = "SHORT opportunity - look for entry";
      else if(g_htfNarrative.zone == "DISCOUNT")
         context = "Wait for rally OR counter-LONG";
      else
         context = "Near EQ - prepare for SHORT";
   }
   else
   {
      context = "No clear bias - wait";
   }

   return context;
}

//+------------------------------------------------------------------+
//| Find all PDA zones that price is currently inside                 |
//| Returns: Total count of zones found                               |
//| Outputs: primaryZone (bias-aligned), secondaryZones (counter)     |
//+------------------------------------------------------------------+
int FindCurrentZones(PDAZone &primaryZone, bool &hasPrimary,
                     PDAZone &secondaryZones[], int &secondaryCount)
{
   double bid = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   hasPrimary = false;
   secondaryCount = 0;
   ArrayResize(secondaryZones, 10);

   int primaryPriority = -1;
   int totalFound = 0;

   // Determine what's "primary" based on bias
   // BULL bias: bullish zones are primary, BEAR bias: bearish zones are primary
   bool primaryIsBullish = (g_weeklyBias == BIAS_BULLISH);

   // Check FVG zones
   for(int i = 0; i < g_pdaMatrix.fvgCount; i++)
   {
      if(g_pdaMatrix.fvgZones[i].isValid && !g_pdaMatrix.fvgZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.fvgZones[i].priceLow && bid <= g_pdaMatrix.fvgZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.fvgZones[i].type);
            if(g_pdaMatrix.fvgZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.fvgZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.fvgZones[i];
            }
         }
      }
   }

   // Check OB zones
   for(int i = 0; i < g_pdaMatrix.obCount; i++)
   {
      if(g_pdaMatrix.obZones[i].isValid && !g_pdaMatrix.obZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.obZones[i].priceLow && bid <= g_pdaMatrix.obZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.obZones[i].type);
            if(g_pdaMatrix.obZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.obZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.obZones[i];
            }
         }
      }
   }

   // Check Breaker zones
   for(int i = 0; i < g_pdaMatrix.breakerCount; i++)
   {
      if(g_pdaMatrix.breakerZones[i].isValid && !g_pdaMatrix.breakerZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.breakerZones[i].priceLow && bid <= g_pdaMatrix.breakerZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.breakerZones[i].type);
            if(g_pdaMatrix.breakerZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.breakerZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.breakerZones[i];
            }
         }
      }
   }

   // Check Rejection zones
   for(int i = 0; i < g_pdaMatrix.rejectionCount; i++)
   {
      if(g_pdaMatrix.rejectionZones[i].isValid && !g_pdaMatrix.rejectionZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.rejectionZones[i].priceLow && bid <= g_pdaMatrix.rejectionZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.rejectionZones[i].type);
            if(g_pdaMatrix.rejectionZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.rejectionZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.rejectionZones[i];
            }
         }
      }
   }

   // Check Liquidity Void zones
   for(int i = 0; i < g_pdaMatrix.liquidityVoidCount; i++)
   {
      if(g_pdaMatrix.liquidityVoidZones[i].isValid && !g_pdaMatrix.liquidityVoidZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.liquidityVoidZones[i].priceLow && bid <= g_pdaMatrix.liquidityVoidZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.liquidityVoidZones[i].type);
            if(g_pdaMatrix.liquidityVoidZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.liquidityVoidZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.liquidityVoidZones[i];
            }
         }
      }
   }

   // Check Volume Imbalance zones
   for(int i = 0; i < g_pdaMatrix.viCount; i++)
   {
      if(g_pdaMatrix.volumeImbalanceZones[i].isValid && !g_pdaMatrix.volumeImbalanceZones[i].isMitigated)
      {
         if(bid >= g_pdaMatrix.volumeImbalanceZones[i].priceLow && bid <= g_pdaMatrix.volumeImbalanceZones[i].priceHigh)
         {
            totalFound++;
            int priority = GetPDATypePriority(g_pdaMatrix.volumeImbalanceZones[i].type);
            if(g_pdaMatrix.volumeImbalanceZones[i].isBullish == primaryIsBullish)
            {
               if(priority > primaryPriority)
               {
                  primaryZone = g_pdaMatrix.volumeImbalanceZones[i];
                  primaryPriority = priority;
                  hasPrimary = true;
               }
            }
            else if(secondaryCount < 10)
            {
               secondaryZones[secondaryCount++] = g_pdaMatrix.volumeImbalanceZones[i];
            }
         }
      }
   }

   return totalFound;
}

//+------------------------------------------------------------------+
//| Calculate confidence score for a PDA zone (0-100%)                |
//+------------------------------------------------------------------+
int CalculatePDAConfidence(PDAZone &zone, double currentPrice, double equilibrium, bool forTrendTrade)
{
   int score = 0;

   // === PDA Type Strength (0-40 points) ===
   // OB=40, Breaker=32, FVG=28, Void=24, Mit=16, Rej=12, VI=8
   switch(zone.type)
   {
      case PDA_ORDER_BLOCK:      score += 40; break;
      case PDA_BREAKER:          score += 32; break;
      case PDA_FVG:              score += 28; break;
      case PDA_LIQUIDITY_VOID:   score += 24; break;
      case PDA_MITIGATION:       score += 16; break;
      case PDA_REJECTION:        score += 12; break;
      case PDA_VOLUME_IMBALANCE: score += 8;  break;
      default:                   score += 5;  break;
   }

   // === HTF Aligned (+20 points) ===
   if(zone.isHTFAligned)
      score += 20;

   // === Liquidity Raided (+20 points) ===
   if(IsLiquidityRaided())
      score += 20;

   // === In Correct Zone for Trade Direction (+15 points) ===
   double zoneMid = (zone.priceLow + zone.priceHigh) / 2;
   bool isInDiscount = zoneMid < equilibrium;

   if(forTrendTrade)
   {
      // For trend trade: BULL wants discount bullish zone, BEAR wants premium bearish zone
      if(g_weeklyBias == BIAS_BULLISH && zone.isBullish && isInDiscount)
         score += 15;
      else if(g_weeklyBias == BIAS_BEARISH && !zone.isBullish && !isInDiscount)
         score += 15;
   }
   else
   {
      // For counter-trend: BULL wants premium bearish zone, BEAR wants discount bullish zone
      if(g_weeklyBias == BIAS_BULLISH && !zone.isBullish && !isInDiscount)
         score += 15;
      else if(g_weeklyBias == BIAS_BEARISH && zone.isBullish && isInDiscount)
         score += 15;
   }

   // === Fresh Zone (+5 points) ===
   if(!zone.isMitigated)
      score += 5;

   return score;  // Max: 40+20+20+15+5 = 100
}

//+------------------------------------------------------------------+
//| Calculate priority score for a PDA zone (legacy for sorting)      |
//+------------------------------------------------------------------+
int CalculatePDAPriority(PDAZone &zone, double currentPrice, double equilibrium)
{
   // Use confidence score divided by 4 for backward compatibility (max ~25)
   return CalculatePDAConfidence(zone, currentPrice, equilibrium, true) / 4;
}

//+------------------------------------------------------------------+
//| Find top priority PDA zones for narrative display                 |
//+------------------------------------------------------------------+
void FindTopPriorityZones(PDAZone &topZones[], int &topCount)
{
   double currentPrice = SymbolInfoDouble(_Symbol, SYMBOL_BID);
   double eq = g_weeklyData.equilibrium;

   // Collect all valid, displayable zones
   PDAZone allZones[];
   int allCount = 0;
   ArrayResize(allZones, 200);

   // Add FVG zones
   for(int i = 0; i < g_pdaMatrix.fvgCount && allCount < 200; i++)
      if(g_pdaMatrix.fvgZones[i].shouldDisplay && g_pdaMatrix.fvgZones[i].isValid)
      {
         g_pdaMatrix.fvgZones[i].priority = CalculatePDAPriority(g_pdaMatrix.fvgZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.fvgZones[i];
      }

   // Add Order Block zones
   for(int i = 0; i < g_pdaMatrix.obCount && allCount < 200; i++)
      if(g_pdaMatrix.obZones[i].shouldDisplay && g_pdaMatrix.obZones[i].isValid)
      {
         g_pdaMatrix.obZones[i].priority = CalculatePDAPriority(g_pdaMatrix.obZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.obZones[i];
      }

   // Add Breaker zones
   for(int i = 0; i < g_pdaMatrix.breakerCount && allCount < 200; i++)
      if(g_pdaMatrix.breakerZones[i].shouldDisplay && g_pdaMatrix.breakerZones[i].isValid)
      {
         g_pdaMatrix.breakerZones[i].priority = CalculatePDAPriority(g_pdaMatrix.breakerZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.breakerZones[i];
      }

   // Add Mitigation zones
   for(int i = 0; i < g_pdaMatrix.mitigationCount && allCount < 200; i++)
      if(g_pdaMatrix.mitigationZones[i].shouldDisplay && g_pdaMatrix.mitigationZones[i].isValid)
      {
         g_pdaMatrix.mitigationZones[i].priority = CalculatePDAPriority(g_pdaMatrix.mitigationZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.mitigationZones[i];
      }

   // Add Rejection zones
   for(int i = 0; i < g_pdaMatrix.rejectionCount && allCount < 200; i++)
      if(g_pdaMatrix.rejectionZones[i].shouldDisplay && g_pdaMatrix.rejectionZones[i].isValid)
      {
         g_pdaMatrix.rejectionZones[i].priority = CalculatePDAPriority(g_pdaMatrix.rejectionZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.rejectionZones[i];
      }

   // Add Liquidity Void zones
   for(int i = 0; i < g_pdaMatrix.liquidityVoidCount && allCount < 200; i++)
      if(g_pdaMatrix.liquidityVoidZones[i].shouldDisplay && g_pdaMatrix.liquidityVoidZones[i].isValid)
      {
         g_pdaMatrix.liquidityVoidZones[i].priority = CalculatePDAPriority(g_pdaMatrix.liquidityVoidZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.liquidityVoidZones[i];
      }

   // Add Volume Imbalance zones
   for(int i = 0; i < g_pdaMatrix.viCount && allCount < 200; i++)
      if(g_pdaMatrix.volumeImbalanceZones[i].shouldDisplay && g_pdaMatrix.volumeImbalanceZones[i].isValid)
      {
         g_pdaMatrix.volumeImbalanceZones[i].priority = CalculatePDAPriority(g_pdaMatrix.volumeImbalanceZones[i], currentPrice, eq);
         allZones[allCount++] = g_pdaMatrix.volumeImbalanceZones[i];
      }

   // Sort by priority (descending) using bubble sort
   for(int i = 0; i < allCount - 1; i++)
      for(int j = 0; j < allCount - i - 1; j++)
         if(allZones[j].priority < allZones[j+1].priority)
         {
            PDAZone temp = allZones[j];
            allZones[j] = allZones[j+1];
            allZones[j+1] = temp;
         }

   // Return top N zones
   topCount = MathMin(allCount, PDA_NarrativeTopZones);
   ArrayResize(topZones, topCount);
   for(int i = 0; i < topCount; i++)
      topZones[i] = allZones[i];
}

//+------------------------------------------------------------------+
//| Draw a single PDA zone on chart                                  |
//+------------------------------------------------------------------+
void DrawPDAZone(PDAZone &zone)
{
   if(!zone.isValid) return;

   // Skip if not selected for display by zone filtering
   if(!zone.shouldDisplay) return;

   // Apply HTF filter if enabled
   if(PDA_FilterByHTFBias && !zone.isHTFAligned) return;

   // Skip if not in valid discount/premium zone for current bias
   if(PDA_FilterByDiscountPremium && !PDA_IsInValidZone(zone.isBullish, zone.priceLow, zone.priceHigh)) return;

   // Skip mitigated zones if setting disabled
   if(zone.isMitigated && !PDA_ShowMitigated) return;

   // Get color
   color zoneColor = GetPDAColor(zone.type, zone.isBullish);

   // Calculate end time
   datetime endTime = PDA_ExtendZones ? TimeCurrent() : zone.timeEnd;

   // Create unique object name
   zone.objectName = EA_PREFIX + "PDA_" + IntegerToString(zone.type) + "_" +
                     IntegerToString(zone.timeStart);

   // Draw filled rectangle
   string rectName = zone.objectName + "_rect";
   ObjectCreate(0, rectName, OBJ_RECTANGLE, 0,
                zone.timeStart, zone.priceHigh,
                endTime, zone.priceLow);
   ObjectSetInteger(0, rectName, OBJPROP_COLOR, zoneColor);
   ObjectSetInteger(0, rectName, OBJPROP_FILL, true);
   ObjectSetInteger(0, rectName, OBJPROP_BACK, true);  // Draw as background
   ObjectSetInteger(0, rectName, OBJPROP_WIDTH, PDA_BorderWidth);
   ObjectSetInteger(0, rectName, OBJPROP_STYLE, STYLE_SOLID);
   ObjectSetInteger(0, rectName, OBJPROP_SELECTABLE, false);

   // Draw top border line
   string topLine = zone.objectName + "_top";
   ObjectCreate(0, topLine, OBJ_TREND, 0,
                zone.timeStart, zone.priceHigh,
                endTime, zone.priceHigh);
   ObjectSetInteger(0, topLine, OBJPROP_COLOR, zoneColor);
   ObjectSetInteger(0, topLine, OBJPROP_WIDTH, PDA_BorderWidth);
   ObjectSetInteger(0, topLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, topLine, OBJPROP_BACK, true);

   // Draw bottom border line
   string bottomLine = zone.objectName + "_bottom";
   ObjectCreate(0, bottomLine, OBJ_TREND, 0,
                zone.timeStart, zone.priceLow,
                endTime, zone.priceLow);
   ObjectSetInteger(0, bottomLine, OBJPROP_COLOR, zoneColor);
   ObjectSetInteger(0, bottomLine, OBJPROP_WIDTH, PDA_BorderWidth);
   ObjectSetInteger(0, bottomLine, OBJPROP_RAY_RIGHT, false);
   ObjectSetInteger(0, bottomLine, OBJPROP_BACK, true);

   // Add label if enabled
   if(PDA_ShowLabels)
   {
      string labelName = zone.objectName + "_label";
      string labelText = GetPDALabel(zone.type, zone.isBullish);

      ObjectCreate(0, labelName, OBJ_TEXT, 0,
                   zone.timeStart, zone.priceHigh);
      ObjectSetString(0, labelName, OBJPROP_TEXT, labelText);
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, zoneColor);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_LOWER);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
//| Clear all PDA zone objects from chart                            |
//+------------------------------------------------------------------+
void ClearPDAZones()
{
   int total = ObjectsTotal(0);
   for(int i = total - 1; i >= 0; i--)
   {
      string name = ObjectName(0, i);
      if(StringFind(name, EA_PREFIX + "PDA_") == 0)
         ObjectDelete(0, name);
   }

   // Reset counts
   g_pdaMatrix.fvgCount = 0;
   g_pdaMatrix.obCount = 0;
   g_pdaMatrix.breakerCount = 0;
   g_pdaMatrix.mitigationCount = 0;
   g_pdaMatrix.rejectionCount = 0;
   g_pdaMatrix.liquidityVoidCount = 0;
   g_pdaMatrix.viCount = 0;
}

//+------------------------------------------------------------------+
//| Detect Fair Value Gaps (3-candle pattern)                        |
//+------------------------------------------------------------------+
void DetectFVGZones(const MqlRates &rates[], int count)
{
   for(int i = 2; i < count; i++)  // Need 3 candles: i (oldest), i-1 (middle), i-2 (newest)
   {
      // Bullish FVG: Candle[i] (oldest) high < Candle[i-2] (newest) low
      if(rates[i].high < rates[i-2].low)
      {
         if(g_pdaMatrix.fvgCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_FVG;
            zone.isBullish = true;
            zone.priceHigh = rates[i-2].low;    // Top of gap
            zone.priceLow = rates[i].high;       // Bottom of gap
            zone.timeStart = rates[i-1].time;    // Middle candle time
            zone.timeEnd = rates[i-2].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-2, PDA_FVG);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(true);

            g_pdaMatrix.fvgZones[g_pdaMatrix.fvgCount++] = zone;
         }
      }

      // Bearish FVG: Candle[i] (oldest) low > Candle[i-2] (newest) high
      if(rates[i].low > rates[i-2].high)
      {
         if(g_pdaMatrix.fvgCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_FVG;
            zone.isBullish = false;
            zone.priceHigh = rates[i].low;       // Top of gap
            zone.priceLow = rates[i-2].high;     // Bottom of gap
            zone.timeStart = rates[i-1].time;
            zone.timeEnd = rates[i-2].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-2, PDA_FVG);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(false);

            g_pdaMatrix.fvgZones[g_pdaMatrix.fvgCount++] = zone;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Order Blocks                                              |
//+------------------------------------------------------------------+
void DetectOrderBlocks(const MqlRates &rates[], int count)
{
   double avgRange = PDA_GetAverageRange(rates, 0, 20);

   for(int i = 1; i < count - 2; i++)
   {
      bool isBearishCandle = rates[i].close < rates[i].open;
      bool isBullishCandle = rates[i].close > rates[i].open;

      // Calculate displacement (move after this candle)
      double displacement = rates[i-1].close - rates[i].close;
      double displacementSize = MathAbs(displacement);

      // Check for structure break
      double swingHigh = PDA_GetSwingHigh(rates, i, 10);
      double swingLow = PDA_GetSwingLow(rates, i, 10);

      bool breaksStructure = (displacement > 0 && rates[i-1].high > swingHigh) ||
                             (displacement < 0 && rates[i-1].low < swingLow) ||
                             (displacementSize > avgRange * 2);

      // Bullish OB: Bearish candle followed by upward displacement
      if(isBearishCandle && displacement > 0 && breaksStructure)
      {
         if(g_pdaMatrix.obCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_ORDER_BLOCK;
            zone.isBullish = true;
            zone.priceHigh = rates[i].high;
            zone.priceLow = rates[i].low;
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i-1].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-1, PDA_ORDER_BLOCK);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(true);

            g_pdaMatrix.obZones[g_pdaMatrix.obCount++] = zone;
         }
      }

      // Bearish OB: Bullish candle followed by downward displacement
      if(isBullishCandle && displacement < 0 && breaksStructure)
      {
         if(g_pdaMatrix.obCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_ORDER_BLOCK;
            zone.isBullish = false;
            zone.priceHigh = rates[i].high;
            zone.priceLow = rates[i].low;
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i-1].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-1, PDA_ORDER_BLOCK);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(false);

            g_pdaMatrix.obZones[g_pdaMatrix.obCount++] = zone;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Volume Imbalances (gap between bodies)                    |
//+------------------------------------------------------------------+
void DetectVolumeImbalances(const MqlRates &rates[], int count)
{
   for(int i = 1; i < count; i++)  // Need 2 candles
   {
      // Current candle body (newer)
      double body1High = MathMax(rates[i-1].open, rates[i-1].close);
      double body1Low = MathMin(rates[i-1].open, rates[i-1].close);

      // Previous candle body (older)
      double body2High = MathMax(rates[i].open, rates[i].close);
      double body2Low = MathMin(rates[i].open, rates[i].close);

      // Bullish VI: Gap between bodies going up
      if(body2High < body1Low)
      {
         if(g_pdaMatrix.viCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_VOLUME_IMBALANCE;
            zone.isBullish = true;
            zone.priceHigh = body1Low;
            zone.priceLow = body2High;
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i-1].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-1, PDA_VOLUME_IMBALANCE);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(true);

            g_pdaMatrix.volumeImbalanceZones[g_pdaMatrix.viCount++] = zone;
         }
      }

      // Bearish VI: Gap between bodies going down
      if(body2Low > body1High)
      {
         if(g_pdaMatrix.viCount < 100)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_VOLUME_IMBALANCE;
            zone.isBullish = false;
            zone.priceHigh = body2Low;
            zone.priceLow = body1High;
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i-1].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i-1, PDA_VOLUME_IMBALANCE);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(false);

            g_pdaMatrix.volumeImbalanceZones[g_pdaMatrix.viCount++] = zone;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Rejection Blocks (wick > 60% of range)                    |
//+------------------------------------------------------------------+
void DetectRejectionBlocks(const MqlRates &rates[], int count)
{
   for(int i = 0; i < count; i++)
   {
      double range = rates[i].high - rates[i].low;
      if(range == 0) continue;

      double bodyHigh = MathMax(rates[i].open, rates[i].close);
      double bodyLow = MathMin(rates[i].open, rates[i].close);

      double upperWick = rates[i].high - bodyHigh;
      double lowerWick = bodyLow - rates[i].low;

      // Bullish Rejection: Long lower wick > 60%
      if(lowerWick / range > 0.6)
      {
         if(g_pdaMatrix.rejectionCount < 50)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_REJECTION;
            zone.isBullish = true;
            zone.priceHigh = bodyLow;          // Top of rejection zone
            zone.priceLow = rates[i].low;      // Bottom (wick low)
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i, PDA_REJECTION);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(true);

            g_pdaMatrix.rejectionZones[g_pdaMatrix.rejectionCount++] = zone;
         }
      }

      // Bearish Rejection: Long upper wick > 60%
      if(upperWick / range > 0.6)
      {
         if(g_pdaMatrix.rejectionCount < 50)
         {
            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_REJECTION;
            zone.isBullish = false;
            zone.priceHigh = rates[i].high;    // Top (wick high)
            zone.priceLow = bodyHigh;          // Bottom of rejection zone
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i, PDA_REJECTION);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(false);

            g_pdaMatrix.rejectionZones[g_pdaMatrix.rejectionCount++] = zone;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Liquidity Voids (large body, minimal wicks)               |
//+------------------------------------------------------------------+
void DetectLiquidityVoids(const MqlRates &rates[], int count)
{
   double avgBody = PDA_GetAverageBody(rates, 0, 20);

   for(int i = 0; i < count; i++)
   {
      double range = rates[i].high - rates[i].low;
      if(range == 0) continue;

      double body = MathAbs(rates[i].close - rates[i].open);
      double bodyRatio = body / range;

      // Liquidity Void: Body > 80% of range AND > 2x average body
      if(bodyRatio > 0.8 && body > avgBody * 2)
      {
         if(g_pdaMatrix.liquidityVoidCount < 50)
         {
            bool isBullish = rates[i].close > rates[i].open;
            double high = MathMax(rates[i].open, rates[i].close);
            double low = MathMin(rates[i].open, rates[i].close);

            PDAZone zone;
            zone.isValid = true;
            zone.type = PDA_LIQUIDITY_VOID;
            zone.isBullish = isBullish;
            zone.priceHigh = high;
            zone.priceLow = low;
            zone.timeStart = rates[i].time;
            zone.timeEnd = rates[i].time;
            zone.isMitigated = PDA_IsMitigated(zone.priceHigh, zone.priceLow, rates, i, PDA_LIQUIDITY_VOID);
            zone.isHTFAligned = PDA_IsAlignedWithHTF(isBullish);

            g_pdaMatrix.liquidityVoidZones[g_pdaMatrix.liquidityVoidCount++] = zone;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Breaker Blocks (failed OBs that get reclaimed)            |
//+------------------------------------------------------------------+
void DetectBreakerBlocks(const MqlRates &rates[], int count)
{
   // Iterate through detected Order Blocks
   for(int ob = 0; ob < g_pdaMatrix.obCount; ob++)
   {
      if(!g_pdaMatrix.obZones[ob].isValid) continue;

      // Find candle index of OB
      int obIndex = PDA_FindBarIndex(rates, count, g_pdaMatrix.obZones[ob].timeStart);
      if(obIndex < 0) continue;

      // Check if OB was swept then reclaimed
      bool swept = false;

      for(int i = obIndex - 1; i >= 0; i--)
      {
         if(g_pdaMatrix.obZones[ob].isBullish)
         {
            // Bullish OB: Check if swept above high, then dropped below low
            if(rates[i].high > g_pdaMatrix.obZones[ob].priceHigh) swept = true;
            if(swept && rates[i].close < g_pdaMatrix.obZones[ob].priceLow)
            {
               // Convert to Bearish Breaker
               if(g_pdaMatrix.breakerCount < 50)
               {
                  PDAZone breaker;
                  breaker.isValid = true;
                  breaker.type = PDA_BREAKER;
                  breaker.isBullish = false;  // Flipped!
                  breaker.priceHigh = g_pdaMatrix.obZones[ob].priceHigh;
                  breaker.priceLow = g_pdaMatrix.obZones[ob].priceLow;
                  breaker.timeStart = g_pdaMatrix.obZones[ob].timeStart;
                  breaker.timeEnd = rates[i].time;
                  breaker.isMitigated = PDA_IsMitigated(breaker.priceHigh, breaker.priceLow, rates, i, PDA_BREAKER);
                  breaker.isHTFAligned = PDA_IsAlignedWithHTF(false);

                  g_pdaMatrix.breakerZones[g_pdaMatrix.breakerCount++] = breaker;
                  g_pdaMatrix.obZones[ob].isValid = false;  // Invalidate original OB
               }
               break;
            }
         }
         else
         {
            // Bearish OB: Check if swept below low, then rallied above high
            if(rates[i].low < g_pdaMatrix.obZones[ob].priceLow) swept = true;
            if(swept && rates[i].close > g_pdaMatrix.obZones[ob].priceHigh)
            {
               // Convert to Bullish Breaker
               if(g_pdaMatrix.breakerCount < 50)
               {
                  PDAZone breaker;
                  breaker.isValid = true;
                  breaker.type = PDA_BREAKER;
                  breaker.isBullish = true;  // Flipped!
                  breaker.priceHigh = g_pdaMatrix.obZones[ob].priceHigh;
                  breaker.priceLow = g_pdaMatrix.obZones[ob].priceLow;
                  breaker.timeStart = g_pdaMatrix.obZones[ob].timeStart;
                  breaker.timeEnd = rates[i].time;
                  breaker.isMitigated = PDA_IsMitigated(breaker.priceHigh, breaker.priceLow, rates, i, PDA_BREAKER);
                  breaker.isHTFAligned = PDA_IsAlignedWithHTF(true);

                  g_pdaMatrix.breakerZones[g_pdaMatrix.breakerCount++] = breaker;
                  g_pdaMatrix.obZones[ob].isValid = false;
               }
               break;
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Detect Mitigation Blocks (origin of FVG moves)                   |
//+------------------------------------------------------------------+
void DetectMitigationBlocks(const MqlRates &rates[], int count)
{
   // Iterate through detected FVGs
   for(int fvg = 0; fvg < g_pdaMatrix.fvgCount; fvg++)
   {
      if(!g_pdaMatrix.fvgZones[fvg].isValid) continue;

      // Find the FVG's time index
      int fvgIndex = PDA_FindBarIndex(rates, count, g_pdaMatrix.fvgZones[fvg].timeStart);
      if(fvgIndex < 0 || fvgIndex + 3 >= count) continue;

      // Origin candle is 2-3 bars before FVG (the base before impulse)
      int originIndex = fvgIndex + 3;
      if(originIndex >= count) originIndex = count - 1;

      if(g_pdaMatrix.mitigationCount < 50)
      {
         PDAZone mitigation;
         mitigation.isValid = true;
         mitigation.type = PDA_MITIGATION;
         mitigation.isBullish = g_pdaMatrix.fvgZones[fvg].isBullish;
         mitigation.priceHigh = rates[originIndex].high;
         mitigation.priceLow = rates[originIndex].low;
         mitigation.timeStart = rates[originIndex].time;
         mitigation.timeEnd = g_pdaMatrix.fvgZones[fvg].timeStart;
         mitigation.isMitigated = PDA_IsMitigated(mitigation.priceHigh, mitigation.priceLow, rates, originIndex, PDA_MITIGATION);
         mitigation.isHTFAligned = PDA_IsAlignedWithHTF(g_pdaMatrix.fvgZones[fvg].isBullish);

         g_pdaMatrix.mitigationZones[g_pdaMatrix.mitigationCount++] = mitigation;
      }
   }
}

//+------------------------------------------------------------------+
//| Check if two zones overlap significantly                          |
//+------------------------------------------------------------------+
bool PDA_IsZoneOverlapping(PDAZone &zone1, PDAZone &zone2)
{
   // Must be same type and bias to be considered duplicate
   if(zone1.type != zone2.type || zone1.isBullish != zone2.isBullish)
      return false;

   // Calculate overlap
   double overlapHigh = MathMin(zone1.priceHigh, zone2.priceHigh);
   double overlapLow = MathMax(zone1.priceLow, zone2.priceLow);

   if(overlapHigh <= overlapLow) return false;  // No overlap

   double overlapSize = overlapHigh - overlapLow;
   double zone1Size = zone1.priceHigh - zone1.priceLow;
   double zone2Size = zone2.priceHigh - zone2.priceLow;
   double smallerSize = MathMin(zone1Size, zone2Size);

   if(smallerSize <= 0) return false;

   // If overlap is > threshold of smaller zone, consider overlapping
   return (overlapSize / smallerSize) > PDA_OverlapThreshold;
}

//+------------------------------------------------------------------+
//| Check if zone is within display window (days)                     |
//+------------------------------------------------------------------+
bool PDA_IsWithinDisplayWindow(datetime zoneTime)
{
   // Get the cutoff time based on trading days (bars), not calendar days
   datetime cutoffTime = iTime(_Symbol, PDA_Timeframe, PDA_DisplayDays);
   if(cutoffTime == 0) return true;  // Not enough data, show all

   return (zoneTime >= cutoffTime);
}

//+------------------------------------------------------------------+
//| Update mitigation status for a single zone type                   |
//+------------------------------------------------------------------+
void UpdateZoneMitigation(PDAZone &zones[], int count, const MqlRates &rates[], int rateCount)
{
   for(int i = 0; i < count; i++)
   {
      if(!zones[i].isValid) continue;
      if(zones[i].isMitigated) continue;  // Already marked as mitigated

      // Find zone start index in rates array
      int zoneIndex = PDA_FindBarIndex(rates, rateCount, zones[i].timeStart);
      if(zoneIndex < 0) continue;

      // Check if mitigated by bars AFTER zone creation
      zones[i].isMitigated = PDA_IsMitigated(zones[i].priceHigh, zones[i].priceLow, rates, zoneIndex, zones[i].type);
   }
}

//+------------------------------------------------------------------+
//| Update mitigation status for all PDA zones                        |
//+------------------------------------------------------------------+
void UpdatePDAMitigationStatus()
{
   // Get current rates to check mitigation
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PDA_Timeframe, 0, PDA_LookbackDays, rates);
   if(copied < 10) return;

   // Update each zone type
   UpdateZoneMitigation(g_pdaMatrix.fvgZones, g_pdaMatrix.fvgCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.obZones, g_pdaMatrix.obCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.breakerZones, g_pdaMatrix.breakerCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.mitigationZones, g_pdaMatrix.mitigationCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.rejectionZones, g_pdaMatrix.rejectionCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.liquidityVoidZones, g_pdaMatrix.liquidityVoidCount, rates, copied);
   UpdateZoneMitigation(g_pdaMatrix.volumeImbalanceZones, g_pdaMatrix.viCount, rates, copied);
}

//+------------------------------------------------------------------+
//| Select zones for display based on filtering rules                 |
//+------------------------------------------------------------------+
void SelectZonesForDisplay()
{
   // Process FVG zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.fvgZones, g_pdaMatrix.fvgCount);

   // Process Order Block zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.obZones, g_pdaMatrix.obCount);

   // Process Breaker zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.breakerZones, g_pdaMatrix.breakerCount);

   // Process Mitigation zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.mitigationZones, g_pdaMatrix.mitigationCount);

   // Process Rejection zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.rejectionZones, g_pdaMatrix.rejectionCount);

   // Process Liquidity Void zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.liquidityVoidZones, g_pdaMatrix.liquidityVoidCount);

   // Process Volume Imbalance zones
   PDA_SelectTypeForDisplay(g_pdaMatrix.volumeImbalanceZones, g_pdaMatrix.viCount);
}

//+------------------------------------------------------------------+
//| Select zones of a specific type for display                       |
//+------------------------------------------------------------------+
void PDA_SelectTypeForDisplay(PDAZone &zones[], int count)
{
   if(count <= 0) return;

   // Initialize all zones to not display
   for(int i = 0; i < count; i++)
      zones[i].shouldDisplay = false;

   // Sort zones by time (newest first) using simple bubble sort
   // (zones array is relatively small so this is acceptable)
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         if(zones[j].timeStart < zones[j+1].timeStart)
         {
            // Swap zones
            PDAZone temp = zones[j];
            zones[j] = zones[j+1];
            zones[j+1] = temp;
         }
      }
   }

   int displayCount = 0;

   // First pass: Select unfilled zones within display window
   for(int i = 0; i < count && displayCount < PDA_MaxUnfilledPerType; i++)
   {
      if(!zones[i].isValid) continue;

      // Skip mitigated zones unless showing mitigated
      if(zones[i].isMitigated && !PDA_ShowMitigated) continue;

      // Skip if not within display window
      if(!PDA_IsWithinDisplayWindow(zones[i].timeStart)) continue;

      // Skip if not in valid discount/premium zone for current bias
      if(PDA_FilterByDiscountPremium && !PDA_IsInValidZone(zones[i].isBullish, zones[i].priceLow, zones[i].priceHigh))
         continue;

      // Check for overlap with already-selected zones
      bool overlapsWithSelected = false;
      for(int j = 0; j < i; j++)
      {
         if(zones[j].shouldDisplay && PDA_IsZoneOverlapping(zones[i], zones[j]))
         {
            overlapsWithSelected = true;
            break;
         }
      }

      if(!overlapsWithSelected)
      {
         zones[i].shouldDisplay = true;
         displayCount++;
      }
      else
      {
         zones[i].shouldDisplay = false;
      }
   }

   // Second pass: Backfill with older unfilled zones if needed
   if(PDA_BackfillOlder && displayCount < PDA_MaxUnfilledPerType)
   {
      for(int i = 0; i < count && displayCount < PDA_MaxUnfilledPerType; i++)
      {
         if(!zones[i].isValid) continue;
         if(zones[i].shouldDisplay) continue;  // Already selected

         // Skip mitigated zones unless showing mitigated
         if(zones[i].isMitigated && !PDA_ShowMitigated) continue;

         // Older zones (outside display window) - backfill
         if(PDA_IsWithinDisplayWindow(zones[i].timeStart)) continue;

         // Skip if not in valid discount/premium zone for current bias
         if(PDA_FilterByDiscountPremium && !PDA_IsInValidZone(zones[i].isBullish, zones[i].priceLow, zones[i].priceHigh))
            continue;

         // Check for overlap with already-selected zones
         bool overlapsWithSelected = false;
         for(int j = 0; j < count; j++)
         {
            if(j == i) continue;
            if(zones[j].shouldDisplay && PDA_IsZoneOverlapping(zones[i], zones[j]))
            {
               overlapsWithSelected = true;
               break;
            }
         }

         if(!overlapsWithSelected)
         {
            zones[i].shouldDisplay = true;
            displayCount++;
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Draw PDA display window boundary lines (20, 40, 60 trading days) |
//+------------------------------------------------------------------+
void DrawPDADisplayWindowLines()
{
   if(!PDA_Enable || !PDA_ShowDisplayWindowLines) return;

   // Draw lines at 20, 40, 60 trading day intervals (daily bars, not calendar days)
   int intervals[3];
   intervals[0] = PDA_DisplayDays;           // 20 days
   intervals[1] = PDA_DisplayDays * 2;       // 40 days
   intervals[2] = PDA_LookbackDays;          // 60 days

   color colors[3];
   colors[0] = PDA_DisplayWindowLineColor;   // Primary (20D)
   colors[1] = clrDimGray;                   // Secondary (40D)
   colors[2] = clrDarkSlateGray;             // Tertiary (60D)

   double chartHigh = ChartGetDouble(0, CHART_PRICE_MAX);

   for(int idx = 0; idx < 3; idx++)
   {
      int days = intervals[idx];

      // Get the time of the bar N trading days ago (ignores weekends)
      datetime cutoffTime = iTime(_Symbol, PDA_Timeframe, days);
      if(cutoffTime == 0) continue;  // Not enough data

      // Draw dotted vertical line
      string lineName = EA_PREFIX + "PDA_DisplayWindow_Line_" + IntegerToString(days);
      ObjectDelete(0, lineName);
      ObjectCreate(0, lineName, OBJ_VLINE, 0, cutoffTime, 0);
      ObjectSetInteger(0, lineName, OBJPROP_COLOR, colors[idx]);
      ObjectSetInteger(0, lineName, OBJPROP_STYLE, STYLE_DOT);
      ObjectSetInteger(0, lineName, OBJPROP_WIDTH, 1);
      ObjectSetInteger(0, lineName, OBJPROP_BACK, true);
      ObjectSetInteger(0, lineName, OBJPROP_SELECTABLE, false);

      // Add label at top of chart
      string labelName = EA_PREFIX + "PDA_DisplayWindow_Label_" + IntegerToString(days);
      ObjectDelete(0, labelName);
      ObjectCreate(0, labelName, OBJ_TEXT, 0, cutoffTime, chartHigh);
      ObjectSetString(0, labelName, OBJPROP_TEXT, " " + IntegerToString(days) + "D");
      ObjectSetInteger(0, labelName, OBJPROP_COLOR, colors[idx]);
      ObjectSetInteger(0, labelName, OBJPROP_FONTSIZE, 8);
      ObjectSetInteger(0, labelName, OBJPROP_ANCHOR, ANCHOR_LEFT_UPPER);
      ObjectSetInteger(0, labelName, OBJPROP_BACK, true);
   }
}

//+------------------------------------------------------------------+
//| Draw all PDA zones on chart                                      |
//+------------------------------------------------------------------+
void DrawAllPDAZones()
{
   // Draw FVGs
   if(PDA_ShowFVG)
   {
      for(int i = 0; i < g_pdaMatrix.fvgCount; i++)
         DrawPDAZone(g_pdaMatrix.fvgZones[i]);
   }

   // Draw Order Blocks
   if(PDA_ShowOB)
   {
      for(int i = 0; i < g_pdaMatrix.obCount; i++)
         DrawPDAZone(g_pdaMatrix.obZones[i]);
   }

   // Draw Breakers
   if(PDA_ShowBreaker)
   {
      for(int i = 0; i < g_pdaMatrix.breakerCount; i++)
         DrawPDAZone(g_pdaMatrix.breakerZones[i]);
   }

   // Draw Mitigation Blocks
   if(PDA_ShowMitigation)
   {
      for(int i = 0; i < g_pdaMatrix.mitigationCount; i++)
         DrawPDAZone(g_pdaMatrix.mitigationZones[i]);
   }

   // Draw Rejection Blocks
   if(PDA_ShowRejection)
   {
      for(int i = 0; i < g_pdaMatrix.rejectionCount; i++)
         DrawPDAZone(g_pdaMatrix.rejectionZones[i]);
   }

   // Draw Liquidity Voids
   if(PDA_ShowLiquidityVoid)
   {
      for(int i = 0; i < g_pdaMatrix.liquidityVoidCount; i++)
         DrawPDAZone(g_pdaMatrix.liquidityVoidZones[i]);
   }

   // Draw Volume Imbalances
   if(PDA_ShowVolumeImbalance)
   {
      for(int i = 0; i < g_pdaMatrix.viCount; i++)
         DrawPDAZone(g_pdaMatrix.volumeImbalanceZones[i]);
   }
}

//+------------------------------------------------------------------+
//| Main PDA Matrix scanner                                          |
//+------------------------------------------------------------------+
void ScanPDAMatrix()
{
   if(!PDA_Enable) return;

   // Get daily rates for lookback period
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(_Symbol, PDA_Timeframe, 0, PDA_LookbackDays, rates);

   if(copied < 10)
   {
      Print("PDA Matrix: Insufficient data, only ", copied, " bars available");
      return;
   }

   // Clear previous zones
   ClearPDAZones();

   // Scan for each PDA type (order matters for dependencies!)
   // Independent detections first
   if(PDA_ShowFVG)             DetectFVGZones(rates, copied);
   if(PDA_ShowOB)              DetectOrderBlocks(rates, copied);
   if(PDA_ShowVolumeImbalance) DetectVolumeImbalances(rates, copied);
   if(PDA_ShowRejection)       DetectRejectionBlocks(rates, copied);
   if(PDA_ShowLiquidityVoid)   DetectLiquidityVoids(rates, copied);

   // Dependent detections (must run after their dependencies)
   if(PDA_ShowBreaker)         DetectBreakerBlocks(rates, copied);      // Depends on OB
   if(PDA_ShowMitigation)      DetectMitigationBlocks(rates, copied);   // Depends on FVG

   // Update mitigation status for all zones (check if price visited them)
   UpdatePDAMitigationStatus();

   // Apply smart zone selection (unfilled, non-overlapping, within display window)
   SelectZonesForDisplay();

   // Draw display window boundary line
   DrawPDADisplayWindowLines();

   // Draw all detected zones
   DrawAllPDAZones();

   // Print HTF bias for debugging
   string biasStr = "NEUTRAL";
   if(g_weeklyBias == BIAS_BULLISH) biasStr = "BULLISH";
   else if(g_weeklyBias == BIAS_BEARISH) biasStr = "BEARISH";

   Print("PDA Matrix scanned: FVG=", g_pdaMatrix.fvgCount,
         " OB=", g_pdaMatrix.obCount,
         " Breaker=", g_pdaMatrix.breakerCount,
         " Mitigation=", g_pdaMatrix.mitigationCount,
         " Rejection=", g_pdaMatrix.rejectionCount,
         " Void=", g_pdaMatrix.liquidityVoidCount,
         " VI=", g_pdaMatrix.viCount,
         " | HTF Bias: ", biasStr,
         " | HTF Filter: ", (PDA_FilterByHTFBias ? "ON" : "OFF"));
}

//+------------------------------------------------------------------+
//| Check for PDA mitigation on current price                        |
//+------------------------------------------------------------------+
void CheckPDAMitigation()
{
   if(!PDA_Enable) return;

   double currentBid = SymbolInfoDouble(_Symbol, SYMBOL_BID);

   // Check each zone type for mitigation
   // (This would update the isMitigated flag and optionally send alerts)
   // Implementation can be expanded based on requirements
}

//+------------------------------------------------------------------+
