//+------------------------------------------------------------------+
//|                                                    HydraGrid.mq5 |
//|                                      Copyright 2025, HydraGrid   |
//+------------------------------------------------------------------+
#property copyright "Copyright 2025, HydraGrid"
#property link      ""
#property version   "1.00"
#property strict

#include <Trade\Trade.mqh>
#include <Trade\PositionInfo.mqh>

//+------------------------------------------------------------------+
//| GlobalVariable keys for persistence across EA restarts           |
//+------------------------------------------------------------------+
#define GV_PREFIX "HG_"

//+------------------------------------------------------------------+
//| Enums                                                            |
//+------------------------------------------------------------------+
enum ENUM_INITIAL_DIRECTION
{
   DIR_BUY  = 0,  // Buy
   DIR_SELL = 1   // Sell
};

enum ENUM_MAX_LEGS_ACTION
{
   ACTION_HEDGE     = 0,  // Hedge (lock exposure)
   ACTION_RESET     = 1,  // Reset Sequence (restart at initial lot)
   ACTION_CLOSE_ALL = 2   // Close All Positions
};

//+------------------------------------------------------------------+
//| Input Parameters                                                 |
//+------------------------------------------------------------------+
input group "========== 1. IDENTITY =========="
input ulong   InpMagicNumber    = 234567;        // Magic Number
input string  InpTradeComment   = "HydraGrid";   // Trade Comment

input group "========== 2. GRID PARAMETERS =========="
input double  InpStartLot       = 0.01;           // Starting Lot Size
input double  InpMultiplier     = 3.0;            // Lot Multiplier per Leg
input double  InpGridPips       = 5.0;            // Grid Spacing (pips against last leg)
input int     InpMaxLegs        = 6;              // Maximum Legs
input ENUM_INITIAL_DIRECTION InpFirstDir = DIR_BUY; // First Leg Direction

input group "========== 3. TAKE PROFIT =========="
input bool    InpUseTPPips      = true;           // Use TP Pips
input double  InpTPPips         = 5.0;            // TP Pips (in favor of last leg)
input bool    InpUseTPDollar    = false;          // Use TP Dollar
input double  InpTPDollar       = 10.0;           // TP Dollar Target ($)

input group "========== 4. STOP LOSS =========="
input bool    InpUseSLDollar    = true;           // Use Dollar Stop Loss
input double  InpSLDollar       = 500.0;          // Max Loss ($) - close all

input group "========== 5. MAX LEGS RECOVERY =========="
input ENUM_MAX_LEGS_ACTION InpMaxLegsAction = ACTION_HEDGE; // Action When Max Legs Reached
input bool    InpUseReset       = true;           // Enable Reset Sequence
input int     InpMaxResets      = 3;              // Max Resets (Reset mode only)
input bool    InpUseCloseAll    = false;          // Enable Close All at Max Legs
input ENUM_MAX_LEGS_ACTION InpPostResetAction = ACTION_HEDGE; // After Resets Exhausted

input group "========== 6. HEDGE SETTINGS =========="
input bool    InpUseHedge       = true;           // Enable Hedge
input double  InpHedgeSLPips    = 0;              // Hedge Position SL (pips), 0 = none

input group "========== 7. DISPLAY =========="
input bool    InpShowComment    = true;           // Show On-Chart Comment

//+------------------------------------------------------------------+
//| Structures                                                       |
//+------------------------------------------------------------------+
struct LegInfo
{
   int                legNumber;
   ulong              ticket;
   ENUM_POSITION_TYPE direction;
   double             openPrice;
   double             volume;
   datetime           openTime;
   double             floatingPL;
};

struct SequenceState
{
   bool               isActive;
   int                currentLegCount;
   int                legsThisSubSequence;
   int                nextLegNumber;
   ENUM_POSITION_TYPE nextDirection;
   double             nextLotSize;
   double             lastLegOpenPrice;
   ENUM_POSITION_TYPE lastLegDirection;
   datetime           lastLegTime;
   double             totalFloatingPL;
   double             totalBuyVolume;
   double             totalSellVolume;
   int                resetCount;
   bool               isHedged;
   ulong              hedgeTicket;
   bool               maxLegsReached;
};

//+------------------------------------------------------------------+
//| Global Variables                                                 |
//+------------------------------------------------------------------+
CTrade         trade;
CPositionInfo  position;
SequenceState  g_seq;
LegInfo        g_legs[];
double         g_pipValue;

//+------------------------------------------------------------------+
//| Normalize lot to symbol constraints                              |
//+------------------------------------------------------------------+
double NormalizeLot(double lots)
{
   double step   = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP);
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);
   lots = MathFloor(lots / step) * step;
   lots = MathMax(minLot, MathMin(maxLot, lots));
   return NormalizeDouble(lots, 2);
}

//+------------------------------------------------------------------+
//| Build GlobalVariable key with magic number suffix                |
//+------------------------------------------------------------------+
string GVKey(string key)
{
   return GV_PREFIX + key + "_" + IntegerToString(InpMagicNumber);
}

//+------------------------------------------------------------------+
//| Initialize sequence to clean state                               |
//+------------------------------------------------------------------+
void InitializeSequence()
{
   g_seq.isActive             = false;
   g_seq.currentLegCount      = 0;
   g_seq.legsThisSubSequence  = 0;
   g_seq.nextLegNumber        = 1;
   g_seq.nextDirection        = (InpFirstDir == DIR_BUY) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
   g_seq.nextLotSize          = InpStartLot;
   g_seq.lastLegOpenPrice     = 0;
   g_seq.lastLegDirection     = POSITION_TYPE_BUY;
   g_seq.lastLegTime          = 0;
   g_seq.totalFloatingPL      = 0;
   g_seq.totalBuyVolume       = 0;
   g_seq.totalSellVolume      = 0;
   g_seq.resetCount           = 0;
   g_seq.isHedged             = false;
   g_seq.hedgeTicket          = 0;
   g_seq.maxLegsReached       = false;
   ArrayResize(g_legs, 0);

   // Clear GlobalVariables
   GlobalVariableDel(GVKey("ResetCount"));
   GlobalVariableDel(GVKey("Hedged"));
}

//+------------------------------------------------------------------+
//| Check if trading is allowed                                      |
//+------------------------------------------------------------------+
bool IsTradeAllowed()
{
   if(!MQLInfoInteger(MQL_TRADE_ALLOWED))
   {
      Print("Expert Advisor trading is not allowed");
      return false;
   }
   if(!TerminalInfoInteger(TERMINAL_TRADE_ALLOWED))
   {
      Print("Trading is not allowed in the terminal");
      return false;
   }
   if(!AccountInfoInteger(ACCOUNT_TRADE_ALLOWED))
   {
      Print("Trading is not allowed for this account");
      return false;
   }
   if(!SymbolInfoInteger(_Symbol, SYMBOL_TRADE_MODE))
   {
      Print("Trading is not allowed for this symbol");
      return false;
   }
   return true;
}

//+------------------------------------------------------------------+
//| Validate input parameters                                        |
//+------------------------------------------------------------------+
bool ValidateInputs()
{
   double minLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN);
   double maxLot = SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MAX);

   if(InpStartLot <= 0 || InpStartLot < minLot || InpStartLot > maxLot)
   {
      PrintFormat("Error: StartLot (%.2f) must be between %.2f and %.2f", InpStartLot, minLot, maxLot);
      return false;
   }
   if(InpMultiplier <= 0)
   {
      Print("Error: Multiplier must be positive");
      return false;
   }
   if(InpGridPips <= 0)
   {
      Print("Error: Grid spacing must be positive");
      return false;
   }
   if(InpMaxLegs < 2)
   {
      Print("Error: Maximum legs must be at least 2");
      return false;
   }
   if(!InpUseTPPips && !InpUseTPDollar)
   {
      Print("Error: At least one TP method must be enabled");
      return false;
   }
   if(InpUseTPPips && InpTPPips <= 0)
   {
      Print("Error: TP pips must be positive when enabled");
      return false;
   }
   if(InpUseTPDollar && InpTPDollar <= 0)
   {
      Print("Error: TP dollar must be positive when enabled");
      return false;
   }
   if(InpUseSLDollar && InpSLDollar <= 0)
   {
      Print("Error: Dollar stop loss must be positive when enabled");
      return false;
   }
   if(InpMaxResets < 0)
   {
      Print("Error: Max resets cannot be negative");
      return false;
   }

   // Warn about maximum lot size at deepest leg
   double maxLeg = InpStartLot * MathPow(InpMultiplier, InpMaxLegs - 1);
   if(maxLeg > maxLot)
   {
      PrintFormat("WARNING: Max leg lot (%.2f) exceeds symbol max (%.2f). Legs will be capped.", maxLeg, maxLot);
   }

   return true;
}

//+------------------------------------------------------------------+
//| Update floating P/L for all positions                            |
//+------------------------------------------------------------------+
void UpdateFloatingPL()
{
   g_seq.totalFloatingPL = 0;
   g_seq.totalBuyVolume  = 0;
   g_seq.totalSellVolume = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
         {
            double pl = position.Profit() + position.Swap();
            g_seq.totalFloatingPL += pl;

            if(position.PositionType() == POSITION_TYPE_BUY)
               g_seq.totalBuyVolume += position.Volume();
            else
               g_seq.totalSellVolume += position.Volume();

            // Update matching leg in g_legs[]
            ulong ticket = position.Ticket();
            for(int j = 0; j < ArraySize(g_legs); j++)
            {
               if(g_legs[j].ticket == ticket)
               {
                  g_legs[j].floatingPL = pl;
                  break;
               }
            }
         }
      }
   }
}

//+------------------------------------------------------------------+
//| Count positions belonging to this EA                             |
//+------------------------------------------------------------------+
int CountMyPositions()
{
   int count = 0;
   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
            count++;
      }
   }
   return count;
}

//+------------------------------------------------------------------+
//| Build comment string for a leg                                   |
//+------------------------------------------------------------------+
string BuildLegComment(int legNumber, ENUM_POSITION_TYPE dir)
{
   string dirStr = (dir == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   if(g_seq.resetCount > 0)
      return InpTradeComment + "_R" + IntegerToString(g_seq.resetCount) + "_L" + IntegerToString(legNumber) + "_" + dirStr;
   return InpTradeComment + "_L" + IntegerToString(legNumber) + "_" + dirStr;
}

//+------------------------------------------------------------------+
//| Open first leg of a new sequence                                 |
//+------------------------------------------------------------------+
bool OpenFirstLeg(MqlTick &tick)
{
   double lot = NormalizeLot(InpStartLot);
   string comment = BuildLegComment(1, g_seq.nextDirection);
   bool result = false;

   if(g_seq.nextDirection == POSITION_TYPE_BUY)
      result = trade.Buy(lot, _Symbol, 0, 0, 0, comment);
   else
      result = trade.Sell(lot, _Symbol, 0, 0, 0, comment);

   if(result)
   {
      int idx = ArraySize(g_legs);
      ArrayResize(g_legs, idx + 1);
      g_legs[idx].legNumber  = 1;
      g_legs[idx].ticket     = trade.ResultOrder();
      g_legs[idx].direction  = g_seq.nextDirection;
      g_legs[idx].openPrice  = trade.ResultPrice();
      g_legs[idx].volume     = lot;
      g_legs[idx].openTime   = TimeCurrent();
      g_legs[idx].floatingPL = 0;

      g_seq.isActive            = true;
      g_seq.currentLegCount     = 1;
      g_seq.legsThisSubSequence = 1;
      g_seq.nextLegNumber       = 2;
      g_seq.lastLegOpenPrice    = trade.ResultPrice();
      g_seq.lastLegDirection    = g_seq.nextDirection;
      g_seq.lastLegTime         = TimeCurrent();

      // Next leg is opposite direction with multiplied lot
      g_seq.nextDirection = (g_seq.lastLegDirection == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      g_seq.nextLotSize   = NormalizeLot(lot * InpMultiplier);

      PrintFormat("HydraGrid: Leg 1 opened - %s %.2f @ %.5f",
                  (g_legs[idx].direction == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                  lot, g_legs[idx].openPrice);
   }
   else
   {
      PrintFormat("HydraGrid: Error opening first leg: %d", GetLastError());
   }

   return result;
}

//+------------------------------------------------------------------+
//| Check if price moved GridPips against last leg                   |
//+------------------------------------------------------------------+
bool CheckNewLegCondition(MqlTick &tick)
{
   if(g_seq.lastLegOpenPrice == 0) return false;

   // Throttle: minimum 2 seconds between legs
   if(TimeCurrent() - g_seq.lastLegTime < 2) return false;

   double distancePips = 0;

   if(g_seq.lastLegDirection == POSITION_TYPE_BUY)
   {
      // BUY loses when price drops
      distancePips = (g_seq.lastLegOpenPrice - tick.bid) / g_pipValue;
   }
   else
   {
      // SELL loses when price rises
      distancePips = (tick.ask - g_seq.lastLegOpenPrice) / g_pipValue;
   }

   return (distancePips >= InpGridPips);
}

//+------------------------------------------------------------------+
//| Open next leg in the alternating sequence                        |
//+------------------------------------------------------------------+
bool OpenNextLeg(MqlTick &tick)
{
   double lot = NormalizeLot(g_seq.nextLotSize);
   ENUM_POSITION_TYPE dir = g_seq.nextDirection;
   int legNum = g_seq.nextLegNumber;
   string comment = BuildLegComment(legNum, dir);
   bool result = false;

   if(dir == POSITION_TYPE_BUY)
      result = trade.Buy(lot, _Symbol, 0, 0, 0, comment);
   else
      result = trade.Sell(lot, _Symbol, 0, 0, 0, comment);

   if(result)
   {
      int idx = ArraySize(g_legs);
      ArrayResize(g_legs, idx + 1);
      g_legs[idx].legNumber  = legNum;
      g_legs[idx].ticket     = trade.ResultOrder();
      g_legs[idx].direction  = dir;
      g_legs[idx].openPrice  = trade.ResultPrice();
      g_legs[idx].volume     = lot;
      g_legs[idx].openTime   = TimeCurrent();
      g_legs[idx].floatingPL = 0;

      g_seq.currentLegCount++;
      g_seq.legsThisSubSequence++;
      g_seq.nextLegNumber++;
      g_seq.lastLegOpenPrice = trade.ResultPrice();
      g_seq.lastLegDirection = dir;
      g_seq.lastLegTime      = TimeCurrent();

      // Next leg: opposite direction, multiplied lot
      g_seq.nextDirection = (dir == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
      g_seq.nextLotSize   = NormalizeLot(lot * InpMultiplier);

      PrintFormat("HydraGrid: Leg %d opened - %s %.2f @ %.5f | Basket P/L: $%.2f",
                  legNum, (dir == POSITION_TYPE_BUY) ? "BUY" : "SELL",
                  lot, g_legs[idx].openPrice, g_seq.totalFloatingPL);
   }
   else
   {
      PrintFormat("HydraGrid: Error opening leg %d: %d", legNum, GetLastError());
   }

   return result;
}

//+------------------------------------------------------------------+
//| Check if last leg moved TPPips in its favor                      |
//+------------------------------------------------------------------+
bool CheckTPCondition(MqlTick &tick)
{
   // If pip-based TP is enabled, check pip distance of last leg
   if(InpUseTPPips)
   {
      if(g_seq.lastLegOpenPrice == 0) return false;

      double favorPips = 0;

      if(g_seq.lastLegDirection == POSITION_TYPE_BUY)
         favorPips = (tick.bid - g_seq.lastLegOpenPrice) / g_pipValue;
      else
         favorPips = (g_seq.lastLegOpenPrice - tick.ask) / g_pipValue;

      if(favorPips >= InpTPPips)
         return true;
   }

   // If dollar-based TP is enabled, check basket P/L directly
   if(InpUseTPDollar)
   {
      if(g_seq.totalFloatingPL >= InpTPDollar)
         return true;
   }

   return false;
}

//+------------------------------------------------------------------+
//| Check if basket P/L meets TP target                              |
//+------------------------------------------------------------------+
bool CheckBasketTPHit()
{
   // If both TP types are enabled, pip condition already passed in CheckTPCondition
   // Now verify basket is in profit
   if(InpUseTPDollar && InpUseTPPips)
      return (g_seq.totalFloatingPL >= InpTPDollar);

   // If only dollar TP, it was already checked in CheckTPCondition
   if(InpUseTPDollar)
      return true; // already passed dollar check

   // If only pip TP, close when basket is positive (any profit)
   if(InpUseTPPips)
      return (g_seq.totalFloatingPL > 0);

   return false;
}

//+------------------------------------------------------------------+
//| Check dollar-based stop loss                                     |
//+------------------------------------------------------------------+
bool CheckDollarStopLoss()
{
   if(!InpUseSLDollar) return false;
   if(InpSLDollar <= 0) return false;
   return (g_seq.totalFloatingPL <= -InpSLDollar);
}

//+------------------------------------------------------------------+
//| Close all positions belonging to this EA                         |
//+------------------------------------------------------------------+
bool CloseAllPositions()
{
   int failed = 0;
   int closed = 0;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() == _Symbol && position.Magic() == InpMagicNumber)
         {
            if(trade.PositionClose(position.Ticket()))
            {
               closed++;
            }
            else
            {
               failed++;
               PrintFormat("HydraGrid: Failed to close ticket %d: %d", position.Ticket(), GetLastError());
            }
         }
      }
   }

   PrintFormat("HydraGrid: CloseAll - closed %d, failed %d | Final P/L: $%.2f",
               closed, failed, g_seq.totalFloatingPL);

   return (failed == 0);
}

//+------------------------------------------------------------------+
//| Place hedge position to neutralize net exposure                  |
//+------------------------------------------------------------------+
bool PlaceHedgePosition(MqlTick &tick)
{
   double netVolume = NormalizeDouble(g_seq.totalBuyVolume - g_seq.totalSellVolume, 2);

   if(MathAbs(netVolume) < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_MIN))
   {
      Print("HydraGrid: Net exposure too small to hedge");
      g_seq.isHedged = true;
      return true;
   }

   double hedgeLot = NormalizeLot(MathAbs(netVolume));
   string comment = InpTradeComment + "_HEDGE";
   bool result = false;

   if(netVolume > 0)
   {
      // Net long → hedge with SELL
      double sl = (InpHedgeSLPips > 0) ? tick.ask + InpHedgeSLPips * g_pipValue : 0;
      result = trade.Sell(hedgeLot, _Symbol, 0, sl, 0, comment);
   }
   else
   {
      // Net short → hedge with BUY
      double sl = (InpHedgeSLPips > 0) ? tick.bid - InpHedgeSLPips * g_pipValue : 0;
      result = trade.Buy(hedgeLot, _Symbol, 0, sl, 0, comment);
   }

   if(result)
   {
      g_seq.isHedged    = true;
      g_seq.hedgeTicket = trade.ResultOrder();
      GlobalVariableSet(GVKey("Hedged"), 1.0);

      PrintFormat("HydraGrid: Hedge placed - %s %.2f @ %.5f | Net was %.2f",
                  (netVolume > 0) ? "SELL" : "BUY", hedgeLot,
                  trade.ResultPrice(), netVolume);
   }
   else
   {
      PrintFormat("HydraGrid: Error placing hedge: %d", GetLastError());
   }

   return result;
}

//+------------------------------------------------------------------+
//| Reset sequence (keep positions, restart at initial lot)          |
//+------------------------------------------------------------------+
void ResetSequence()
{
   g_seq.resetCount++;
   g_seq.maxLegsReached       = false;
   g_seq.legsThisSubSequence  = 0;
   g_seq.nextLotSize          = InpStartLot;
   // nextDirection already set (opposite of last leg)

   GlobalVariableSet(GVKey("ResetCount"), (double)g_seq.resetCount);

   PrintFormat("HydraGrid: Sequence RESET #%d of %d. Restarting at lot %.2f",
               g_seq.resetCount, InpMaxResets, InpStartLot);
}

//+------------------------------------------------------------------+
//| Handle max legs reached                                          |
//+------------------------------------------------------------------+
void HandleMaxLegs(MqlTick &tick)
{
   switch(InpMaxLegsAction)
   {
      case ACTION_HEDGE:
         if(InpUseHedge)
            PlaceHedgePosition(tick);
         else
            Print("HydraGrid: Max legs reached. Hedge disabled — holding positions.");
         break;

      case ACTION_RESET:
         if(InpUseReset && g_seq.resetCount < InpMaxResets)
         {
            ResetSequence();
         }
         else
         {
            PrintFormat("HydraGrid: %s. Executing fallback.",
                        !InpUseReset ? "Reset disabled" : "All resets exhausted");
            ExecuteFallback(tick, InpPostResetAction);
         }
         break;

      case ACTION_CLOSE_ALL:
         if(InpUseCloseAll)
         {
            CloseAllPositions();
            InitializeSequence();
         }
         else
            Print("HydraGrid: Max legs reached. Close All disabled — holding positions.");
         break;
   }
}

//+------------------------------------------------------------------+
//| Execute fallback action with toggle guards                       |
//+------------------------------------------------------------------+
void ExecuteFallback(MqlTick &tick, ENUM_MAX_LEGS_ACTION action)
{
   switch(action)
   {
      case ACTION_HEDGE:
         if(InpUseHedge)
            PlaceHedgePosition(tick);
         else
            Print("HydraGrid: Fallback hedge disabled — holding positions.");
         break;
      case ACTION_CLOSE_ALL:
         if(InpUseCloseAll)
         {
            CloseAllPositions();
            InitializeSequence();
         }
         else
            Print("HydraGrid: Fallback close all disabled — holding positions.");
         break;
      case ACTION_RESET:
         Print("HydraGrid: Fallback cannot be Reset. Holding positions.");
         break;
   }
}

//+------------------------------------------------------------------+
//| Recover state from open positions after EA restart               |
//+------------------------------------------------------------------+
void RecoverStateFromPositions()
{
   // Temporary arrays for sorting
   ulong    tickets[];
   double   prices[];
   double   volumes[];
   int      legNums[];
   int      dirs[];     // 0 = BUY, 1 = SELL
   datetime times[];
   int      count = 0;
   bool     foundHedge = false;

   for(int i = PositionsTotal() - 1; i >= 0; i--)
   {
      if(position.SelectByIndex(i))
      {
         if(position.Symbol() != _Symbol || position.Magic() != InpMagicNumber)
            continue;

         string comment = position.Comment();

         // Check if this is a hedge position
         if(StringFind(comment, "_HEDGE") >= 0)
         {
            foundHedge = true;
            g_seq.hedgeTicket = position.Ticket();
            continue;
         }

         // Parse leg number from comment: "HydraGrid_L{N}_BUY" or "HydraGrid_R{R}_L{N}_SELL"
         int legNum = 0;
         int lPos = StringFind(comment, "_L");
         if(lPos >= 0)
         {
            string afterL = StringSubstr(comment, lPos + 2);
            int underscorePos = StringFind(afterL, "_");
            if(underscorePos > 0)
            {
               string numStr = StringSubstr(afterL, 0, underscorePos);
               legNum = (int)StringToInteger(numStr);
            }
         }

         if(legNum <= 0) legNum = count + 1; // fallback

         int idx = count;
         count++;
         ArrayResize(tickets, count);
         ArrayResize(prices, count);
         ArrayResize(volumes, count);
         ArrayResize(legNums, count);
         ArrayResize(dirs, count);
         ArrayResize(times, count);

         tickets[idx]  = position.Ticket();
         prices[idx]   = position.PriceOpen();
         volumes[idx]  = position.Volume();
         legNums[idx]  = legNum;
         dirs[idx]     = (position.PositionType() == POSITION_TYPE_BUY) ? 0 : 1;
         times[idx]    = position.Time();
      }
   }

   if(count == 0)
   {
      if(foundHedge)
      {
         g_seq.isHedged = true;
         g_seq.isActive = true;
         Print("HydraGrid: Recovery - found hedge only, no grid legs");
      }
      return;
   }

   // Sort by open time (simple bubble sort)
   for(int i = 0; i < count - 1; i++)
   {
      for(int j = 0; j < count - i - 1; j++)
      {
         if(times[j] > times[j + 1])
         {
            // Swap all arrays
            ulong    tmpTicket  = tickets[j];  tickets[j]  = tickets[j+1];  tickets[j+1]  = tmpTicket;
            double   tmpPrice   = prices[j];   prices[j]   = prices[j+1];   prices[j+1]   = tmpPrice;
            double   tmpVol     = volumes[j];  volumes[j]   = volumes[j+1];  volumes[j+1]  = tmpVol;
            int      tmpLeg     = legNums[j];  legNums[j]  = legNums[j+1];  legNums[j+1]  = tmpLeg;
            int      tmpDir     = dirs[j];     dirs[j]     = dirs[j+1];     dirs[j+1]     = tmpDir;
            datetime tmpTime    = times[j];    times[j]    = times[j+1];    times[j+1]    = tmpTime;
         }
      }
   }

   // Rebuild g_legs[]
   ArrayResize(g_legs, count);
   for(int i = 0; i < count; i++)
   {
      g_legs[i].legNumber  = legNums[i];
      g_legs[i].ticket     = tickets[i];
      g_legs[i].direction  = (dirs[i] == 0) ? POSITION_TYPE_BUY : POSITION_TYPE_SELL;
      g_legs[i].openPrice  = prices[i];
      g_legs[i].volume     = volumes[i];
      g_legs[i].openTime   = times[i];
      g_legs[i].floatingPL = 0;
   }

   // Set sequence state from the latest leg
   int lastIdx = count - 1;
   g_seq.isActive             = true;
   g_seq.currentLegCount      = count;
   g_seq.nextLegNumber        = legNums[lastIdx] + 1;
   g_seq.lastLegOpenPrice     = prices[lastIdx];
   g_seq.lastLegDirection     = g_legs[lastIdx].direction;
   g_seq.lastLegTime          = times[lastIdx];
   g_seq.nextDirection        = (g_seq.lastLegDirection == POSITION_TYPE_BUY) ? POSITION_TYPE_SELL : POSITION_TYPE_BUY;
   g_seq.nextLotSize          = NormalizeLot(volumes[lastIdx] * InpMultiplier);
   g_seq.isHedged             = foundHedge;

   // Recover reset count from GlobalVariable
   if(GlobalVariableCheck(GVKey("ResetCount")))
   {
      g_seq.resetCount = (int)GlobalVariableGet(GVKey("ResetCount"));
   }

   // Estimate legsThisSubSequence (approximate — count legs opened after last reset)
   // Without perfect tracking, use total count as conservative estimate
   g_seq.legsThisSubSequence = count;
   if(g_seq.resetCount > 0)
   {
      // Try to count only legs from the current sub-sequence by checking lot sizes
      // If a leg has lot == InpStartLot, it's likely the start of a reset sub-sequence
      int subCount = 0;
      for(int i = count - 1; i >= 0; i--)
      {
         subCount++;
         if(MathAbs(volumes[i] - InpStartLot) < SymbolInfoDouble(_Symbol, SYMBOL_VOLUME_STEP))
            break;
      }
      g_seq.legsThisSubSequence = subCount;
   }

   g_seq.maxLegsReached = (g_seq.legsThisSubSequence >= InpMaxLegs);

   PrintFormat("HydraGrid: Recovered %d legs, reset count %d, hedged: %s, last leg: %s @ %.5f",
               count, g_seq.resetCount,
               g_seq.isHedged ? "YES" : "NO",
               (g_seq.lastLegDirection == POSITION_TYPE_BUY) ? "BUY" : "SELL",
               g_seq.lastLegOpenPrice);
}

//+------------------------------------------------------------------+
//| Update on-chart comment display                                  |
//+------------------------------------------------------------------+
void UpdateChartComment()
{
   if(!InpShowComment) return;

   string dirStr = (g_seq.lastLegDirection == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string nextDirStr = (g_seq.nextDirection == POSITION_TYPE_BUY) ? "BUY" : "SELL";
   string status = "IDLE";

   if(g_seq.isHedged)         status = "HEDGED";
   else if(g_seq.maxLegsReached) status = "MAX LEGS";
   else if(g_seq.isActive)    status = "ACTIVE";

   double triggerPrice = 0;
   double tpPrice = 0;
   if(g_seq.lastLegOpenPrice > 0)
   {
      if(g_seq.lastLegDirection == POSITION_TYPE_BUY)
      {
         triggerPrice = g_seq.lastLegOpenPrice - InpGridPips * g_pipValue;
         tpPrice      = g_seq.lastLegOpenPrice + InpTPPips * g_pipValue;
      }
      else
      {
         triggerPrice = g_seq.lastLegOpenPrice + InpGridPips * g_pipValue;
         tpPrice      = g_seq.lastLegOpenPrice - InpTPPips * g_pipValue;
      }
   }

   string text = "";
   text += "━━━━━━━ HydraGrid v1.0 ━━━━━━━\n";
   text += "Status: " + status + "\n";
   text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
   text += StringFormat("Legs: %d (sub: %d/%d)\n", g_seq.currentLegCount, g_seq.legsThisSubSequence, InpMaxLegs);
   text += StringFormat("Last Leg: %s @ %.5f\n", dirStr, g_seq.lastLegOpenPrice);
   text += StringFormat("Next Leg: %s %.2f lots\n", nextDirStr, g_seq.nextLotSize);
   text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
   text += StringFormat("Next Leg Trigger: %.5f\n", triggerPrice);
   text += StringFormat("TP Trigger:       %.5f\n", tpPrice);
   text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
   text += StringFormat("Basket P/L: $%.2f\n", g_seq.totalFloatingPL);
   text += StringFormat("Net Volume: %.2f (B:%.2f S:%.2f)\n",
                        g_seq.totalBuyVolume - g_seq.totalSellVolume,
                        g_seq.totalBuyVolume, g_seq.totalSellVolume);
   text += StringFormat("Resets: %d / %d\n", g_seq.resetCount, InpMaxResets);
   text += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";

   Comment(text);
}

//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
{
   // Initialize trading settings
   trade.SetExpertMagicNumber(InpMagicNumber);
   trade.SetDeviationInPoints(10);
   trade.SetTypeFilling(ORDER_FILLING_FOK);

   // Validate inputs
   if(!ValidateInputs())
      return INIT_PARAMETERS_INCORRECT;

   // Cache pip value
   g_pipValue = SymbolInfoDouble(_Symbol, SYMBOL_POINT) * 10;

   // Initialize clean state
   InitializeSequence();

   // Try to recover state from existing positions
   RecoverStateFromPositions();

   PrintFormat("HydraGrid: Initialized | Pip value: %.5f | Start lot: %.2f | Multiplier: %.1f | Grid: %.1f pips | Max legs: %d",
               g_pipValue, InpStartLot, InpMultiplier, InpGridPips, InpMaxLegs);

   return INIT_SUCCEEDED;
}

//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
{
   // 1. Gate check
   if(!IsTradeAllowed()) return;

   // 2. Get current tick
   MqlTick tick;
   if(!SymbolInfoTick(_Symbol, tick)) return;

   // 3. Update all floating P/L
   UpdateFloatingPL();

   // 4. Check $ stop loss FIRST (highest priority)
   if(g_seq.isActive && CheckDollarStopLoss())
   {
      PrintFormat("HydraGrid: DOLLAR STOP LOSS HIT! P/L: $%.2f | Limit: -$%.2f",
                  g_seq.totalFloatingPL, InpSLDollar);
      CloseAllPositions();
      InitializeSequence();
      return;
   }

   // 5. If hedged, do nothing (locked)
   if(g_seq.isHedged)
   {
      if(InpShowComment) UpdateChartComment();
      return;
   }

   // 6. If no sequence active, open first leg
   if(!g_seq.isActive)
   {
      OpenFirstLeg(tick);
      if(InpShowComment) UpdateChartComment();
      return;
   }

   // 7. If max legs reached, handle recovery
   if(g_seq.maxLegsReached)
   {
      HandleMaxLegs(tick);
      if(InpShowComment) UpdateChartComment();
      return;
   }

   // 8. Check TP condition: has last leg moved TPPips in its favor?
   if(CheckTPCondition(tick))
   {
      if(CheckBasketTPHit())
      {
         PrintFormat("HydraGrid: TAKE PROFIT HIT! Basket P/L: $%.2f", g_seq.totalFloatingPL);
         CloseAllPositions();
         InitializeSequence();
         if(InpShowComment) UpdateChartComment();
         return;
      }
   }

   // 9. Check if price moved GridPips against last leg → open new leg
   if(CheckNewLegCondition(tick))
   {
      if(g_seq.legsThisSubSequence >= InpMaxLegs)
      {
         g_seq.maxLegsReached = true;
         PrintFormat("HydraGrid: MAX LEGS REACHED (%d). Triggering recovery action.", InpMaxLegs);
         HandleMaxLegs(tick);
      }
      else
      {
         OpenNextLeg(tick);
      }
   }

   // 10. Update chart display
   if(InpShowComment) UpdateChartComment();
}

//+------------------------------------------------------------------+
//| Expert deinitialization function                                  |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
{
   Comment("");
   PrintFormat("HydraGrid: Removed (reason: %d) | Legs: %d | Basket P/L: $%.2f | Resets: %d",
               reason, g_seq.currentLegCount, g_seq.totalFloatingPL, g_seq.resetCount);
}
//+------------------------------------------------------------------+
